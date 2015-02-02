\ memdump.f     - isforth debugger memory dump
\ ------------------------------------------------------------------------

  .( memdump.f )

\ ------------------------------------------------------------------------

  8 var #mem                    \ number of bytes per dump line

\ ------------------------------------------------------------------------
\ display address of data being dumped

: .address      ( a1 --- )
  hex memwin swap               \ characters emitted to memory dump window
  0 <# bl dup hold hold         \ construct number string in reverse order
  ':' hold 8 rep # #> 
  wtype ;                       \ display it

\ ------------------------------------------------------------------------
\ display memory contents as hex bytes

: .hex          ( a1 --- )
  #mem bounds
  do
    memwin                      \ where were displaying to
    i c@ 0 <# bl hold # # #>    \ what were displaying
    wtype                       \ display it
  loop ;

\ ------------------------------------------------------------------------
\ show memory contents as ascii bytes

: .ascii
  bl memwin wemit
  #mem bounds
  do
    i c@ $7f and
    dup $20 < over $7f = or
    if drop '.' then
    memwin wemit
  loop ;
        
\ ------------------------------------------------------------------------

: .memory
  0 memwin win-height@ 
  memwin win-at
  memaddr
  memwin win-height@
  for  
    memwin win-cr
    dup .address 
    dup .hex
    dup .ascii
    8 + 
  nxt   
  drop ;

\ ------------------------------------------------------------------------

\ todo: add code to navigate though memory dump (make mem window focused)
\  also, pressing M when the stack is empty is displaying 
\  the environment address space

\ ========================================================================
