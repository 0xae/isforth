
 defer realarm

 1 27 syscall <alarm>

\ ------------------------------------------------------------------------
\ the actual signal handler function

: (alarm) 
  realarm                   \ re init alarm signal
  99 >semaphore ;           \ throw semaphore 99 to all catchers thereof

\ ------------------------------------------------------------------------
\ lets create a signal handler that does the above

 ' (alarm) 14 signal alarm drop

\ ------------------------------------------------------------------------

: (realarm) 
  ['] alarm 14 <signal> 
  drop ;

' (realarm) is realarm

\ ------------------------------------------------------------------------

 0 var got-alarm

: my-alarm
  on> got-alarm
  ." alarm signal received" cr ;

\ ------------------------------------------------------------------------

: test
  99 ['] my-alarm +semaphore
  begin
    5 <alarm>               \ start a 5 second alarm clock 
    begin 
      ." no alarm" cr 
      1 seconds
      got-alarm
    until 
    off> got-alarm key?
  until
  99 ['] my-alarm -semaphore
  key drop ;

\ ========================================================================












