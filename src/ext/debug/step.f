\ step.f    - isforth debugger single stepping
\ ------------------------------------------------------------------------

  .( step.f )    \ ^:[\s]+[[:graph:]]+[\s]+

\ ------------------------------------------------------------------------

: (check-does)  ( xt --- f1 )
  dup c@ $e8 =              \ does cfa of next xt contain a call opcode ?
  ?:                        \ test if it is a call to a call to dodoes
    does?                   \ if so, this is a does> word
    xfalse ;                \ otherwise it aint

\ ------------------------------------------------------------------------
\ is nextxt to step a does> word ?

: check-does    ( --- f1 )
  app-ip@ (check-does) ;

\ ------------------------------------------------------------------------
\ single step one xt of application code

: (bug-step)    ( --- )
  on> c-ix                  \ force realign cursor to same loation as ip
  app-ip app-rp app-sp      \ pass applications ip, rp and sp to the

  bnext                     \ debuggres 'next' (in kernel exec.s)

  !> app-ip !> app-rp       \ save new values for all of the above
  !> app-sp ;

\ ------------------------------------------------------------------------

: (<<does)
  begin
    begin
      1- dup c@ $e8 =       \ scan back from does> to a 'call' opcode
    until
    dup colon?              \ keep going till we find 'call nest'
  until ;

\ ------------------------------------------------------------------------
\ given xt of a created does> word find cfa of the word that created it

: <<does    ( xt --- cfa )
  ?cfa (<<does) ;           \ get address of does> part of creating word

\ ------------------------------------------------------------------------

\ the parameter passed to this word is the address that the applications
\ ip will point to if the (bug-step) steps a coded definition. if the
\ step steps anythng else then ip will not equal a1 after the step.

: (enter)        ( a1 --- )
  app-ip cell+
  (bug-step) app-ip <>
  if
    app-ip body> ?cfa
    ['] dodoes =
    if
      app-ip body> (<<does)
      >see exit
    then
    app-ip body>            \ push nested into word on the seestack
    >see                    \ deompile from here now
  then ;                    \ (see decompiles word at top of see stack)

\ ------------------------------------------------------------------------
\ set step to target address

: >step         ( a1 --- )
  stepto stepstack [].push  \ save old end address for auto stepping
  ?full !> stepto           \ set new address

  stepping ?exit            \ dont redo the following if already stepping

  on> stepping              \ tell main loop to start auto stepping
  off> updating ;           \ without updating the display (till done)

\ ------------------------------------------------------------------------
\ pop item off step stack

: step>         ( --- )
  stepstack [].pop          \ pop item
  ?empty !> stepto ;        \ abort or reset old step target

\ ------------------------------------------------------------------------

\ the following words emulate some 'special' application calls that can
\ not be executed at full speed or cannot be stepped into or require some
\ processing prior to doing so

\ ------------------------------------------------------------------------
\ application displays a number

: app-.         ( --- )
  app-ip++                  \ dot is difficult to step into or over
  outwin app-sp> s>d        \ because the debugger is constantly calling
  <# #s #> wtype ;          \ the number conversion words (not reentrant)

\ ------------------------------------------------------------------------
\ single step an exit from a colon definition

: app-exit      ( --- )
  app-rp app-rp0 = ?exit    \ cant exit out of definition we are debugging
  seestack [].drop ?empty   \ backup see point and run the exit
  (bug-step) ;

\ ------------------------------------------------------------------------
\ single step a conditional exit from a colon definition

: app-?exit     ( --- )
  app-sp>                   \ get top item of apps pstack
  ?:                        \ if its not zero
    app-exit                \ app exits to caller
    app-ip++ ;              \ advance aps ip past the ?exit

\ ------------------------------------------------------------------------
\ application steps an emit

\ this can be wrong, applications can revector emit to something other
\ than (emit).  this assumes (emit) and emulates it

: app-emit          ( --- )
  app-sp> outwin wemit      \ emit appliation char to debug output window
  app-ip++ ;                \ advance application ip past the emit

\ ------------------------------------------------------------------------
\ application steps a ."

: app-(.")          ( --- )
  app-ip cell+ count        \ fetch address and length of string to disp
  2dup + !> app-ip          \ advance applications ip past string
  outwin -rot wtype ;       \ write string to output window

\ ------------------------------------------------------------------------
\ application steps an abort"

: app-(abort")      ( --- )
  halted ?exit              \ if stepping is halted then dont step
  app-sp>                   \ get flag at top of applications pstack
  if                        \ if its true
    app-(.")                \ display abort string to output window
    on> halted              \ block all further single stepping
  else                      \ otherwise...
    app-ip cell+ count +    \ advance applications ip past abort string
    !> app-ip
  then ;

\ ------------------------------------------------------------------------
\ can not step past an abort

: app-abort     ( --- ) ;   \ ip does not advance past the xt

\ ------------------------------------------------------------------------
\ application emits a cr

: app-cr        ( --- )
  outwin win-cr             \ write a crlf to output window
  cell +!> app-ip ;         \ advance applications ip past cr xt

\ ------------------------------------------------------------------------
\ application requests keyboard input

: app-key
  app-ip++                  \ advance ip past key's xt
  >app-keys key             \ reset key handler to applicaitons handler
  >app-sp >bug-keys ;       \ push key we just read onto app pstack

\ ------------------------------------------------------------------------
\ xt is not a special case that needs emulating

: not-special   ( --- false )
  r>drop false ;

\ ------------------------------------------------------------------------

: app-leave     ( --- )
  app-rp> drop
  app-rp> drop
  app-rp> !> app-ip ;

\ ------------------------------------------------------------------------
\ is current xt a special case ? (emulted)

: special?      ( --- f1 )
  app-ip@                   \ get next xt to be steppped
  case:                     \ is it one of the following special cases
    ' exit      opt app-exit
    ' ?exit     opt app-?exit
    ' (emit)    opt app-emit
    ' emit      opt app-emit
    ' (.")      opt app-(.")
    ' (abort")  opt app-(abort")
    ' abort     opt app-abort
    ' quit      opt app-abort
    ' cr        opt app-cr
    ' key       opt app-key
    ' (key)     opt app-key
    ' .         opt app-.
    ' (leave)   opt app-leave
  dflt
    not-special
  ;case
  true on> c-ix ;          \ realign cursor to same loation as ip

\ ------------------------------------------------------------------------
\ step into a does> word

\ : (enter-does)  ( xt --- )  <<does >see (bug-step) ;
\ : enter-does    ( --- )     app-ip@ (enter-does) ;

\ ------------------------------------------------------------------------
\ xt is a deferred word but does it point to a colon definition

: isdefer       ( --- f1 )
  app-ip@ >body @           \ fetch vector of deferred word
  colon? ;                  \ is it vectored to a colon definition

\ ------------------------------------------------------------------------
\ does current xt point to a defered word thats vectored to a : def?

: check-defer:  ( --- f1 )
  app-ip@ defer?            \ get current xt, is it a defered word?
  ?:
    isdefer                 \
    false ;

\ ------------------------------------------------------------------------

: enter-?:       ( --- ) app-ip 3 cells + (enter) ;
: enter-case:    ( --- ) app-ip@ cell+ @  (enter) ;   \ *** wrong
: enter-:        ( --- ) app-ip cell+     (enter) ;

\ ------------------------------------------------------------------------

: (enter-exec:) ( --- )
  app-ip cell+              \ after stepping are we here?
  (bug-step) app-ip <>      \ single step the indexed xt
   if                       \ if not then we just stepped into a : def
    app-ip body> >see       \ push addr of def we are now in to see

    app-rp cell+ app-rp0 <> \ this modifies the way the exec: behaves
    if                      \ so as to make things easier to follow as
      app-rp> drop          \ you single step. exiting from a : def
      end-of-: >app-rp      \ called by exec: should exit up one level
    then                    \ from the ?:. this makes the exit from the
    exit                    \ called word exit to the end of the def
  then                      \ containing the exec: statement instead
  end-of-: !> app-ip ;

\ ------------------------------------------------------------------------
\ enter an xt within an exec: that references a does> word

: exec:does>    ( --- )
  end-of-:
  app-ip@ <<does >see
  (bug-step)
  app-rp> drop >app-rp ;

\ ------------------------------------------------------------------------
\ step into an exec: statement

: enter-exec:    ( --- )
  app-ip cell+              \ point to first xt after exec: xt
  app-sp> []+ !> app-ip     \ point ip at indexed xt within exec:
  check-does                \ does this xt point to a does> ?
  ?:
    exec:does>              \ yes enter exec: referencing a does> word
    (enter-exec:) ;         \ no enter normal exec:

\ ------------------------------------------------------------------------

: enter-execute ( --- )
\  app-sp@ (check-does)
\  if
\    app-sp@ (enter-does)
\    exit
\  then
  enter-: ;

\ ------------------------------------------------------------------------

: enter-defer   ( --- )
  app-ip@ >body @
\  (check-does)
\  ?:
\    enter-does
    enter-: ;

\ ------------------------------------------------------------------------
\ try step into a colon definition

: bug-enter
  special? ?exit            \ handle special cases

  \ does the current xt point to a colon def, a defered word, or a
  \ does> word?

  check-:       if enter-:       exit then
  \ check-does    if enter-does    exit then
  check-defer:  if enter-defer   exit then

  app-ip@

  \ is the current xt a ?:, an exec:, a case: or an execute ?

  case:
    ' ?:      opt enter-?:
    ' exec:   opt enter-exec:
    ' docase  opt enter-case:
    ' execute opt enter-execute
  dflt
    enter-:              \ simplest case, just step the xt
  ;case ;

\ ------------------------------------------------------------------------
\ step through all code till ip points to next xt

: step-over       ( --- )
  app-ip cell+ >step ;       \ set stop adddress for stepping operation

\ ------------------------------------------------------------------------
\ step through all code till ip points to next xt

: step-over       ( --- )
  app-ip cell+ >step ;       \ set stop adddress for stepping operation

\ ------------------------------------------------------------------------
\ step through all code till ip points to next xt

: step-over       ( --- )
  app-ip cell+ >step ;       \ set stop adddress for stepping operation

\ ------------------------------------------------------------------------
\ step over various word types

: step-:        ( --- ) step-over enter-: ;
: step-?:       ( --- ) app-ip 3 cells + >step enter-?: ;
: step-exec:    ( --- ) end-of-:         >step enter-exec: ;
: step-case:    ( --- ) app-ip   cell+ @ dup >step (enter) ;
: step-rep      ( --- ) app-ip 2 cells + dup >step (enter) ;

\ ------------------------------------------------------------------------
\ single step next application xt

: bug-step
  special? ?exit

  app-ip@ ['] dorep =       \ dorep is a colon definition but stepping
  if                        \ over it requires slightly different handling
    step-rep                \ step over a rep
  then

  check-:       if step-:      exit then
  check-defer:  if step-:      exit then

  app-ip@

  case:
    ' ?:      opt step-?:
    ' exec:   opt step-exec:
    ' case:   opt step-case:
    ' execute opt step-:
    ' dorep   opt step-rep
  dflt
    step-:
  ;case ;

\ ------------------------------------------------------------------------
\ initialize for auto stepping with updates

: step>here     ( --- )
  []xu c-ix []@             \ fetch address indexed by cursor
  !> break0                 \ set step stop address
  on> stepping              \ start stepping
  off> updating ;           \ do not update display as we auto step

\ ------------------------------------------------------------------------
\ initialize for auto stepping with no updates (fast)

: .step>here    ( --- )
  step>here
  on> updating ;

\ ========================================================================
