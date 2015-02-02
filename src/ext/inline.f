\ inline.f      - isforth macro colon definition creation.
\ ------------------------------------------------------------------------

  .( loading inline.f ) cr

\ ------------------------------------------------------------------------

\ an example of what i consider to be some realy realy bad ans style forth
\
\ : foo
\     postpone this postpone that
\     postpone the-other ; immediate
\
\ whats bad here is all the 'postpone' crap which adds huge ammounts of
\ bullshit visual clutter.
\
\ the purpose of all this postponing is to have foo compile stuff inline.
\ everything thats postponed above is compiled into the definition
\ being created at the time foo is referenced.
\
\ the definition for foo could be : foo this that the-other ; and we
\ would be compiling a call to foo wherever it was invoked but sometimes
\ when speed is required it is advantageous to compile code inline yet
\ for the sake of readabiity you still want to "factor it out".
\
\ there are however some limitations to what you can do using the above
\ cluttered method.  you cant very easilly have foo above compile a loop
\ or a branch or a ." blah" etc inside the target.
\
\ this file gives you a way to dispense with the visuall clutter and with
\ some of the restrictions (see below).
\
\ these words will create a colon definition that will inject its own code
\ into the definition currently being defined and the macro itself does
\ not take up any space on in the target.
\
\ e.g.

\ m: foo this that the-other ;m
\ : bar .... foo .... ;
\
\ m: blah if ." true" else ." false" then 100 0 do i . loop ;m
\
\ : fud ..... blah ..... ;

\ NOTE:  any macro containing an exit within its definitin will cause an
\ exit to be executed within the word referencing it.  the exit is not
\ "optimized" into a branch to the exit point of the macro but it could
\ be...

\ the difficulty would be when this "exit" was in the middle of some
\ control structure within the macro itself such as an if statement or
\ a loop of some kind.  when the macro was created the exit would have
\ been compiled as a single xt.  converting this to a branch would
\ mean turning it into 2 xt's throwing off the branch vectors of the
\ control structure.

\ the processing required to handle these situations would technically
\ turn this "user" optimization into a compiler optimiation and i am
\ diametrically opposed to this.

\ ------------------------------------------------------------------------

  vocabulary i-voc compiler definitions

\ ------------------------------------------------------------------------

\ it would be entirely possible to make all defined macros permanatly
\ available by creating a save-macros and load-macros facility.  it would
\ also still be possible to flush all macros created by a given module
\ where use of said macros would be unwise outside of the module that
\ defined them.  this last would be accomplished with a mechanism similar
\ to forget.
\
\ this would allow the creation of useful macros that were available
\ system wide but which would still be discarded once their use was
\ no longer required (turnkeying for example).

\ ------------------------------------------------------------------------

  <headers

  0 var i-buf               \ buffer to compile macros to
  0 var i-hhere             \ inline header pointer
  0 var i-here              \ inline list pointer
  0 var i-current           \ real current vocabulary

  ' i-voc     >body const 'i-voc
  ' i-here    >body const 'i-here
  ' i-hhere   >body const 'i-hhere
  ' i-current >body const 'i-current

  'i-voc !> i-current

\ ------------------------------------------------------------------------

  0 var was-branch          \ true if last token was a branch
  0 var m-start             \ start address of current macro definition
  0 var m-new               \ address macro is being inlined to
  0 var m-exit              \ exit point of macro

\ ------------------------------------------------------------------------
\ toggle inline mode

: toggle
  dp 'i-here juggle
  hp 'i-hhere juggle
  current 'i-current juggle ;

\ ------------------------------------------------------------------------
\ switch between compiling normally or compiling into macro buffers

: inline> toggle i-voc ;    \ switch to inline mode. add i-voc to context
: <inline toggle ;          \ toggle to non inline mode. keep i-voc

\ ------------------------------------------------------------------------
\ discard all macro code and headers and zero inline vocabulary

  headers>

: purge-macros
  i-buf !> i-here           \ reset macro here
  'i-voc 256 erase          \ erase all threads in i-voc
  i-voc previous ;          \ remove i-voc from context

\ ------------------------------------------------------------------------

: (is-quote)    ( token --- token f1 )
  dup ['] (.") ['] (abort")
  either ;

\ ------------------------------------------------------------------------
\ is current token a (.") or a (abort")

: is-quote?     ( a1 token --- a1 token false | a2 true )
  (is-quote) dup 0= ?exit   \ return false if token not a quote
  >r ,                      \ save true for exit and compile the " token
  count -1 /string          \ get string length and address
  2dup s, + r> ;            \ compile string, advance addr, return true

\ ------------------------------------------------------------------------
\ words that have a branch vector compiled after them

\ it is assumed that a branch vector is absolute, not relative
\ - this is a true assumption in isforth -

create branches
]
  (nxt)   (do)    (?do)  doif     doelse (loop)
  (+loop) dobegin ?while dorepeat doagain ?until
[ 12 const #branches

\ ------------------------------------------------------------------------
\ is the current token a branching type word?

: is-branch?    ( token --- f1 )
  branches #branches pluck  \ search above table for specified token
  dscan nip 0= not
  !> was-branch ;           \ indicate next xt is the branch vector

\ ------------------------------------------------------------------------
\ expand a token from a macro into its target definition

: ((m:))        ( a1 token --- a2 )
  is-quote? ?exit           \ handle " token if it is one, exit if it was
  was-branch                \ was the previous token a branch?
  if
    off> was-branch         \ clear flag
    m-start - m-new +       \ relocate branch vector
  else
    is-branch?              \ is the current token a branch?
  then
  , ;                       \ compile token, advance address

\ ------------------------------------------------------------------------

: (m:)
  dcount !> m-exit          \ fetch the compiled exit point of macro
  dup !> m-start            \ point to body of macro
  here !> m-new             \ fetch address to inline macro to

  begin
    dup m-exit <>           \ reached end of macro?
  while
    dcount ((m:))           \ no - fetch and process next token
  repeat
  drop ;                    \ yes - clean up

\ ------------------------------------------------------------------------
\ start a macro colon definition

  headers>

: m:
  inline>                   \ initialize macro compilation
  create immediate          \ create new word and make it immediate
  >mark                     \ compile dummy macro exit point
  ]                         \ switch into compile mode
  does> (m:) ;              \ patch macros cfa

\ ------------------------------------------------------------------------
\ complete definition of a macro colon definition

\ ;inline ??

: ;m
  >resolve                  \ compile exit point of macro
  [compile] [               \ switch out of compile mode
  <inline ; immediate

\ there is no exit compiled onto the end of a macro : definition

\ ------------------------------------------------------------------------

: (inline-init)
  32768 @map ?exit
  dup !> i-buf
  dup !> i-here
  16384 + !> i-hhere
  purge-macros ;  (inline-init)

\ ------------------------------------------------------------------------
\ is 8k of macros and 8k of macro headers enough?

  <headers

: inline-init
  defers default
  (inline-init) ;

\ ------------------------------------------------------------------------

  behead forth definitions

\ ========================================================================
