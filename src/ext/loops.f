\ loops.f       - isforth looping and branching compilation words
\ ------------------------------------------------------------------------

  .( loading loops.f ) cr

\ ------------------------------------------------------------------------

  compiler definitions

\ ------------------------------------------------------------------------
\ initialize a forward branch

: >mark         ( --- a1 )
  here                      \ remember address where branch takes place
  0 , ;                     \ fill in dummy branch vector

\ ------------------------------------------------------------------------
\ resolve a forward branch

: >resolve      ( a1 --- )
  here                      \ get address we are branching to
  swap ! ;                  \ store in branch vector we are branching from

\ ------------------------------------------------------------------------
\ initialize a backward branch

\ : <mark         ( --- a1 )
\    here ;                  \ remember address we are branching to

  ' here alias <mark

\ ------------------------------------------------------------------------
\ resolve a backward branch

\ : <resolve      ( a1 --- )
\  , ;                       \ store addres to branch to in branch vector

  ' , alias <resolve

\ ------------------------------------------------------------------------
\ compile a do loop into new definition

: do            ( --- a1 )
  compile (do)              \ compile (do) and a dummy loop exit point
  >mark ; immediate         \  to be back filled in later

\ ------------------------------------------------------------------------
\ compile a conditional do loop into new definition

: ?do           ( --- a1 )
  compile (?do)             \ compile (?do) and
  >mark ; immediate         \ dummy loop exit point

\ ------------------------------------------------------------------------
\ compile resolution of previously compile do or ?do loop

: loop          ( a1 --- )
  compile (loop)            \ compile (loop)
  dup cell+                 \ resolve address to loop back to
  <resolve
  >resolve ; immediate      \ resolve loop exit point at (do)/(?do)

\ ------------------------------------------------------------------------

: +loop         ( a1 --- )
  compile (+loop)           \ compile (+loop)
  dup cell+                 \ resolve address to loop back to
  <resolve
  >resolve ; immediate      \ resolve loop exit poing in (do)/(?do)

\ ------------------------------------------------------------------------
\ compile an early exit from a do loop

: leave         ( --- )
  compile (leave) ; immediate  \ compile (leave)

\ ------------------------------------------------------------------------
\ compile a conditional early exit from a do loop

: ?leave        ( --- )
  compile (?leave) ; immediate  \ compile (?leave)

\ ------------------------------------------------------------------------
\ compile an if statement

: if            ( --- a1 )
  compile doif              \ compile conditional branch
  >mark ; immediate         \ compile dummy branch target

\ ------------------------------------------------------------------------
\ compile else part of an if statement

: else          ( a1 --- a2 )
  compile doelse            \ unconditional branch at end of if part
  >mark                     \ to unknown end of else part
  swap >resolve ; immediate \ resolve if branch vector

\ ------------------------------------------------------------------------
\ resolve target for if/else

: then          ( a1 --- )
  compile dothen            \ compile dummy word for decompiler
  >resolve ; immediate      \ resolve if/else forward branch

\ ------------------------------------------------------------------------
\ compile the starting point of a begin loop

: begin         ( --- a1 )
  compile dobegin
  <mark ; immediate

\ ------------------------------------------------------------------------
\ compile infinite loop back to begin

: again
  compile doagain
  <resolve ; immediate

\ ------------------------------------------------------------------------
\ compile conditional branch back to begin

: until
  compile ?until
  <resolve ; immediate

\ ------------------------------------------------------------------------
\ compile while part of... begin test-here while still-true-part repeat

: while
  compile ?while
  >mark swap ; immediate

\ ------------------------------------------------------------------------
\ resolve begin while repeat loop

: repeat
  compile dorepeat
  <resolve
  >resolve ; immediate

\ ------------------------------------------------------------------------
\ added these just for you (bleh :)

: for       ( n1 --- )
  compile dofor
  <mark ; immediate

\ ------------------------------------------------------------------------

\ i would have called this 'next' but that word name already exists and is
\ kind of a special part of the internal forth virtual machine.  this limp
\ wristed name prevents confusion factor.

\ note - i disagree with chipchuck here...
\ if forth hid the compiler and the inner interpreter/threading from its
\ users then the following could be called next.  most (all?) other forths
\ call this next...

: nxt
  compile (nxt)             \ for/nxt loops are more efficient than do
  <resolve ; immediate      \ loops but rep loops are better imho... .. .

\ ------------------------------------------------------------------------
\ execute a rep loop compiled or interpreted

: (rep)         ( ... n1 xt -- )
  swap 
  for
    dup>r execute r>
  nxt
  drop ;

\ ------------------------------------------------------------------------
\ execute a compiled rep loop

: dorep         ( n1 --- )  
  param (rep) ;

\ ------------------------------------------------------------------------
\ compile or interpret a rep loop

: rep           (  | n1 --- )
  state @                   \ is forth in compile or interpret mode
  if
    compile dorep           \ compile rep loop
  else
    ' (rep)                 \ else get address of thing to repeat and
  then ; immediate          \ repeat it the specified number of times
  
\ note: the n1 in the stack comment is only there if the rep is being
\ executed in interpret mode.  if we are in compile mode n1 will have
\ already been compiled as a literal

\ ------------------------------------------------------------------------

  forth definitions

\ ========================================================================
