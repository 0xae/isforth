\ bkeys.f        - isforth debugger keyboard handling
\ ------------------------------------------------------------------------

  .( bkeys )

\ ------------------------------------------------------------------------
\ advance cursor to next xt in code window

: bug-down
  c-ix #xu 1- = ?exit       \ at end of definition?
  incr> c-ix update         \ update display
  on> cmoved ;              \ set flag: cursor has been moved

\ ------------------------------------------------------------------------
\ retreat cursor (can be placed above ip)

: bug-up
  c-ix 0= ?exit             \ cursor at start of definition?
  decr> c-ix update         \ update display and indicate cursor was moved
  on> cmoved ;

\ ------------------------------------------------------------------------
\ these will peek (nest) into nestable definitions

: bug-right ;
: bug-left ;
: bug-home ;

\ ------------------------------------------------------------------------
\ handle keys that return an escape sequence not a single character

: bug-actions
  case:
    key-down  opt bug-down
    key-home  opt bug-home
    key-left  opt bug-left
    key-right opt bug-right
    key-up    opt bug-up
    key-ent   opt do-enter
  ;case ;

\ ------------------------------------------------------------------------

: (>bug-keys)
  ['] key >body @ !> old-key
  ['] key-actions >body @ !> old-actions
  ['] bug-actions is key-actions
  ['] newkey is key ;

\ ------------------------------------------------------------------------

: (>app-keys)
  old-key is key
  old-actions is key-actions ;

\ ------------------------------------------------------------------------
\ resolve evil forward referenes

  ' (>bug-keys) is >bug-keys
  ' (>app-keys) is >app-keys

\ ========================================================================
