\ semaphore.f       - isforth software semaphore handling
\ ------------------------------------------------------------------------

  .( loading semaphore.f ) cr

\ ------------------------------------------------------------------------

  <headers

\ ------------------------------------------------------------------------

 0 var semaphores           \ array of 256 linked lists of handlers

\ ------------------------------------------------------------------------

: semalloc
  defers default
  [ 256 llist * ]# allocate
  drop !> semaphores ;

\ ------------------------------------------------------------------------

struct: semaphore
  lnode: sp.list
  1 dd sp.vector
;struct

\ -----------------------------------------------------------------------
\ allocate handler a1 for semaphore number n1

  headers>

: +semaphore        ( n1 a1 --- f1 )
  semaphore allocate 0=
  if
    2drop false exit
  then

  dup>r sp.vector !         \ set address of handler
  llist * semaphores +      \ add node to list of handlers for this
  r> swap >tail             \  semaphore number
  true ;

\ ------------------------------------------------------------------------
\ remove handler a1 for semaphore number n1

: -semaphore        ( n1 a1 --- f1 )
  swap llist * semaphores +
  head@

  begin
    2dup sp.vector @ <>
  while
    next@
    dup parent@ head@ over =
  until
    2drop false
  else
    nip <list drop
    true
  then ;

\ ------------------------------------------------------------------------

: >semaphore
  llist * semaphores + head@
  ?dup 0= ?exit

  begin
    dup sp.vector @ execute
    next@ ?dup 0=
  until ;

\ ------------------------------------------------------------------------

  behead

\ ========================================================================
