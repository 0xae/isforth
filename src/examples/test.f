#! ../../isforth -sfload
\ ------------------------------------------------------------------------

\ this file shows how IsForth can be used to interpret scripts pased to it
\ via a shebang.
\
\ isforth will see a command line of '-sfload /path/to/script.f' because
\ the shebanged file is passed to us as an extra parameter.

\ ------------------------------------------------------------------------
\ the word tt will display a complete times table

: (tt) ( n1 --- ) 0 12 0 do over + dup 4 u.r loop cr 2drop ;
: tt cr cr 13 1 do i (tt) loop cr ;

\ ------------------------------------------------------------------------

tt                      \ after loading - run times table display

\ isforth automatically quits without saying bye when a script finishes


\ ========================================================================
