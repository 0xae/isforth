\ debug.f       - isforth debugger extension  (about time!)
\ ------------------------------------------------------------------------

 .( debug.f )

\ ------------------------------------------------------------------------

\ while this debug extension is capable of being used to debug your
\ applications, it was NOT developed for this purpose.  In fact a debuging
\ forth code with a debugger of this type is HIGHLY frowned upon by the
\ purists and rightly so.  forth does not need this type of debugger at
\ all!

\ so why write it at all??

\ well this debuggers primary reason for existence is as a teaching aid
\ for the beginner wishing to understand how forth code executes
\ internally.  A full understanding of how a forth system works should be
\ important to anyone who wishes to become a good forth programmer.

\    Actually, I hold this statement to be true for ALL programming
\    languages.  I will never be a good C programmer and neither will
\    99.99999999999999% of the "professionals" using that language,
\    simply for being almost completely devoid of any understanding
\    of how the language actually works.

\ Q:  How many C programmers are there in the world?
\ A:  Billions (maybe more!)
\ Q:  How many of them can write a 100% from scratch C compiler?
\ A:  Maybe a few hundred of them (if that).

\ Q:  How many Forth programmers are there in the world?
\ A:  A few thousand (maybe less)
\ Q:  How many of them can write a 100% from scratch Forth compiler?
\ A:  Almost all of them (or they arent real forth programmers).
\     (not that most of them would actually want to create one)

\ ------------------------------------------------------------------------

  vocabulary bug bug definitions

\ ------------------------------------------------------------------------

\ this debug extension makes use of the term "execution unit" which i
\ have coined.  this is similar to the common forth term xt or
\ "execution token".

\ e.g.  when you write...
\
\    : foo .... ['] bar is bam ... ;

\ the "['] bar" is compiled as in two execution tokens. first is the xt
\ for ['] (which actually compiles the xt for (lit)) and the second is the
\ xt for bar.   the entire "['] bar" is considered one execution unit
\ because at run time the xt for bar is considered an operand of the xt
\ for ['].

\ another example...
\
\    ." this dot quote is one xu"

\ for a very isforthy example...

\  test-something
\  ?:
\    do-true
\    do-false

\ is an example of my ?: if/else/then construct.  the entire set of
\ three execution tokens "?: do-true do-false" is one complete xu

\ As you single step through the code you are debugging the current
\ interprative pointer position is shown as a red highlight covering the
\ next complete xu to be stepped.

\ ------------------------------------------------------------------------

   0 var bug-base           \ radix on entry into debugger
   0 var app-ip             \ address where debugger is debugging
   0 var in-debug           \ a flag for see (the decompiler)
   0 var memaddr            \ memory window address
   0 var app-rp             \ applications return stack pointer
   0 var app-sp             \ applications parameter stack pointer
   0 var bug-stacks         \ points to stacks buffer for debugger
   0 var app-rp0            \ apps rp address on entry into debug
   0 var halted             \ single stepping is halted (no further exec)
   0 var stepping           \ true if auto stepping
   0 var updating           \ true if updating display during auto step
   0 var stepto             \ address to stop stepping
   0 var break0
 $c8 var step-delay         \ delay in auto step with update
   0 var cmoved             \ flag. true if cursor moved
   0 var app-out            \ is applications output window visible?

\ ------------------------------------------------------------------------
\ evil forward references

  defer >bug-keys           \ initializes debuggers keyboard handler
  defer >app-keys           \ retores previous keyboard handler

\ ------------------------------------------------------------------------
\ save space for old key handler

  0 var old-actions         \ save for old key handler, restore on exit
  0 var old-key             \ where defered key points to for app

\ ------------------------------------------------------------------------
\ software stacks used by the debuger

  2048 stack seestack       \ debug see stack
  2048 stack stepstack      \ auto step stack

\ ------------------------------------------------------------------------
\ error messages. if these happen something is wrong with my code

  create s-full  ," Internal Error: Debug Stack Full"
  create s-empty ," Internal Error: Debug Stack Empty"

\ ------------------------------------------------------------------------

: bug-abort     ( a1  --- )
  >app-keys count type abort ;

\ ------------------------------------------------------------------------
\ abort if debug stack is full/empty

: ?full         ( f1 --- )  ?exit s-full bug-abort ;
: ?empty        ( f1 --- )  ?exit s-empty bug-abort ;

\ ------------------------------------------------------------------------
\ push current debug word onto see stack

\ this is used by bug-see to decompile the word currently being stepped
\ through,  this is the "see" stack.

: >see          ( cfa --- )  seestack [].push ?full ;

\ ------------------------------------------------------------------------
\ clean up stack, return false result

: xfalse        ( n1 --- false )  drop false ;

\ ------------------------------------------------------------------------

: app-ip@       ( --- xt ) app-ip @ ;
: app-ip++      ( --- )  cell +!> app-ip ;

\ ------------------------------------------------------------------------
\ for all non coded definitions the cfa is a call to somewhere.

  headers>

: ?cfa          ( cfa --- call-target )
  dup                       \ make copy of cfa
  >body swap 1+ @           \ get offset from cfa to call target
  + ;                       \ add offset of call target to cfa

\ ------------------------------------------------------------------------
\ does cfa reference one of the following?

  <headers

: colon?        ( cfa --- f1 )  ?cfa      ['] nest = ;
: defer?        ( cfa --- f1 )  ?cfa      ['] dodefer = ;
: does?         ( cfa --- f1 )  ?cfa ?cfa ['] dodoes = ;

\ -------------------------------------------------------------------------
\ what is the next xt to be stepped by application?

: check-:       ( --- f1 )     app-ip@ colon? ;
: check-rep     ( --- f1 )     app-ip@ ['] dorep = ;

\ ------------------------------------------------------------------------
\ returns true if address a1 is a breakpoint (not fully implemented yet)

: isbreak       ( a1 --- f1 )  break0 = ;

\ ------------------------------------------------------------------------
\ push/pop item to/from applications return/parameter stack

\ note auto grow staks might cause segfaults here where it would not
\ happen if running for real

\ these are not used to emulate >r r> r@ but are the debugers means
\ of accessing the applications stacks

: >app-rp       ( n1 --- ) [ cell negate ]# +!> app-rp app-rp ! ;
: app-rp>       ( --- n1 ) app-rp @ cell +!> app-rp ;
: app-rp@       ( --- n1 ) app-rp @ ;

: >app-sp       ( n1 --- ) [ cell negate ]# +!> app-sp app-sp ! ;
: app-sp>       ( --- n1 ) app-sp @ cell +!> app-sp ;
: app-sp@       ( --- n1 ) app-sp @ ;

\ ------------------------------------------------------------------------
\ put applications output window in the foreground

: show-out      ( --- )
  app-out
  if
    off> app-out
    outwin detach
  else
    on> app-out
    bug-screen outwin       \ attach aplication output window to screen
    attach
  then
  bug-screen .screen ;      \ redraw screen

\ ------------------------------------------------------------------------
\ flush keyboard buffer

: flush     ( --- )
  begin
    key?                    \ while there are still keys to read
  while
    (key) drop              \ read and discard them
  repeat ;

\ ========================================================================
