\ getuid.f  - get user id of current process
\ ------------------------------------------------------------------------

 <headers

\ ------------------------------------------------------------------------

 0 201 syscall <getuid32>
 0 49  syscall <getuid>

\ ------------------------------------------------------------------------

 headers>

: getuid        ( --- uid | -1 )
  <getuid32>
  dup -1 <> ?exit
  drop <getuid> ;

\ ------------------------------------------------------------------------

 behead

\ ========================================================================
