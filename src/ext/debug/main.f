\ main.f    - isforth debugger extension main include file
\ ------------------------------------------------------------------------

 .( main.f ) cr

\ ------------------------------------------------------------------------
\ breakpoint or stepto address reached

: broke         ( --- true )
  stepstack [].flush        \ clear auto step stack
  off> break0               \ clear break
  off> stepto ;             \ stop stepping

\ ------------------------------------------------------------------------
\ stop auto stepping

: stop-step     ( --- 0 )
  off> stepping             \ disable stepping
  off> updating             \ disable update during stepping
  broke app-out             \ clear step stack etc. is app window visible?
  if                        \ if so detach and display debug windows
    show-out
  then ;

\ ------------------------------------------------------------------------
\ has a breakpoint or the stepto address been reached?

: ?break        ( --- f1 )
  app-ip isbreak            \ is the current ip a breakpoint?
  if
    broke true exit         \ reset the break and stop stepping
  then

  app-ip stepto =           \ is it the current step to address?
  if
    step>                   \ pop item off of stepto stack
    stepto break0 or 0=     \ if either stepto or break0 are still set
    if                      \ then do not break
      broke true exit       \ otherwise break
    then
  then
  false ;

\ ------------------------------------------------------------------------
\ set mem watch address to address at top of applications parameter stack

\ if you set an illegal address you will seg(your)fault

: set-mem       ( --- )
  app-sp@ !> memaddr ;

\ ------------------------------------------------------------------------
\ if auto steppong do a delay?

: step-delay?
  updating step-delay 0<>   \ do not do auto step delay if updates are
  and not ?exit             \ disable dor if not auto stepping

  step-delay 0              \ otherwise do the delay
  ?do
    key? ?leave             \ but allow any keypress to abort the delay
    5 ms
  5 +loop ;

\ -----------------------------------------------------------------------
\ add value to current step delay

: (>delay)      ( n1 --- true )
  step-delay +              \ add n1 to current step delay
  0 max 1024 min            \ but clip reslut to window
  !> step-delay ;           \ set new delay

\ ------------------------------------------------------------------------

: delay++       ( --- )  8 (>delay) .delay ;
: delay--       ( --- ) -8 (>delay) .delay ;

\ ------------------------------------------------------------------------
\ while autp stepping should we update the display?

: ?update       ( --- )
  updating stepping xor ?exit
  update ;

\ ------------------------------------------------------------------------
\ main menu... handle keypress

: main-menu     ( c1 --- )
  case:
    $0a opt bug-enter       \ step into
    $20 opt bug-step        \ step over
    'h' opt step>here       \ step till ip = c-ix
    'H' opt .step>here      \ as above but with update
    'o' opt show-out        \ show apps output window (pauses)
    '=' opt delay++         \ increment or decrement auto step delay
    '-' opt delay--
    'm' opt set-mem         \ set memory view address (dangerous)
  ;case ;

\ ------------------------------------------------------------------------
\ auto stepping menu

: auto-menu     ( --- 0 )
  key                       \ this will not block, the key is there
  case:                     \ handle user keypress during auto step
    '=' opt delay++
    '-' opt delay--
    'o' opt show-out
    $1b opt stop-step
  ;case
  0 ;                       \ return null simulated key, does nothing

\ ------------------------------------------------------------------------
\ simulate user single stepping

: sim-key       ( --- sim-key )
  ?break not                \ have we hit a breakpoint?
  if
    step-delay?             \ if not do auto step delay
    $0a exit                \ simpulate a step into keypress
  then

  stop-step 0 ;             \ null keypress (does nothing)

\ ------------------------------------------------------------------------
\ should we simulate a single step keypress or was a key actually hit?

: sim-key?      ( --- key )
  key?                      \ was a real keypress hit?
  ?:
    auto-menu               \ process real keypress
    sim-key ;               \ simulate single step by user

\ ------------------------------------------------------------------------

: get-key       ( --- key )
  stepping                  \ if were auto stepping
  ?:
    sim-key?                \ get simpulated keypress
    key ;                   \ otherwise get keypress

\ ------------------------------------------------------------------------
\ debug main loop

: bug-main      ( --- )
  update                    \ display initial state of debug screen
  begin                     \ this is updated as required
    get-key dup $1b <>      \ while escape not pressed
  while
    main-menu ?update       \ process key and conditionally update
  repeat
  drop ;                    \ discard escape key

\ ------------------------------------------------------------------------
\ save application stack pointers. point them at debuggers stack buffers

: >bug          ( -- )
  sp@ !> app-sp             \ remember where applications stacks are
  bug-stacks 8192 + sp!
  r>drop r>                 \ pull return address off applications r stack
  rp@ !> app-rp             \ save applications rp
  bug-stacks 4092 + rp!     \ point rp to debuggers stack memory
  app-rp !> app-rp0         \ so we dont try exiting too far
  >r ;                      \ put return address of >bug on debug stack

\ ------------------------------------------------------------------------
\ restore application stack pointers

: <bug          ( --- )
  app-sp sp!
  app-rp0 rp! ;

\ ------------------------------------------------------------------------

: clear-variables
  seestack [].flush         \ flush decompilation stack
  stepstack [].flush
  off> c-ix                 \ cursor at start of xu array
  off> break0
  off> halted               \ not halted, stepping is allowed
  off> stepping
  off> updating             \ not updating
  off> stepto ;             \ no stepto target set

\ ------------------------------------------------------------------------

: (debug)       ( a1 --- )
  dup >see                  \ save 'see' address
  >body !> app-ip           \ set applications ip address
  +bug-sem >bug-keys

  curoff bug-main curon     \ run debug session

  >app-keys -bug-sem        \ restore applications key handler etc

  $07 >attrib clear         \ rest to default attribs
  rows 2- 0 at              \ put ursor at bottom left of display
  bug-base base ! ;         \ restore application radix

\ ------------------------------------------------------------------------
\ cannot step something that is not a colon definition

: not:          ( a1 --- )
  drop  ." Not A : Definition" ;

\ ------------------------------------------------------------------------
\ can only debug colon definiions

: ?debug        ( a1 --- )
  dup colon?                \ are we trying to debug a colon def?
  ?: (debug) not: ;

\ ------------------------------------------------------------------------
\ initializes debug stacks and see window

: bug-init
  bug-init-screen           \ initialize debug display
  base @ !> bug-base
  clear-variables
  here !> memaddr           \ set defult memory dump address

  bug-stacks 0=             \ allocate debug stacks if not already
  if                        \ allocated
    8192 allocate drop      \ parameter and return stacks
    !> bug-stacks           \ 4k each
  then

  codewin win-height@       \ calculate line index half way down code win
  dup 2/ swap 1 and +
  !> mid-point

  0 0 outwin win-at
  outwin clw                \ clear output window
  bug-screen scr-refresh    \ force update of entire display on reentry
  >bug ;                    \ save app stacks, use debug stacks etc

\ ------------------------------------------------------------------------

 headers>

: debug     ( --- )
  bug-init '                \ initialize debugger, get address to debug
  ?debug
  <bug ;

\ ------------------------------------------------------------------------

: [']debug          ( a1 --- )
  bug-init ?debug ;          \ debug from address a1

\ ========================================================================
