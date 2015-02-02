\ stackdsp.f    - isforth debugger stack contents display
\ ------------------------------------------------------------------------

  .( stackdsp.f )

\ ------------------------------------------------------------------------

 0 var swin                 \ which stack window we are updating
 0 var p0
 0 var p

\ ------------------------------------------------------------------------

: .stack        ( win sp0 sp --- )
  !> p !> p0 !> swin
  swin clw
  7 0 swin win-at
  p0 p - cell/ 8 min 0
  ?do
    swin win-cr
    p i []@
    0 <# 8 rep # #> bounds
    do
      i c@ swin dup win-cx@ 7 <>
      ?: wemit (wemit)
    loop
  loop ;

\ ------------------------------------------------------------------------

: .pstack       ( --- ) pwin sp0 app-sp .stack ;
: .rstack       ( --- ) rwin app-rp0 app-rp .stack ;

\ ========================================================================
