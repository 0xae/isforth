\ bwindow.f      - isforth debugger windowing code
\ ------------------------------------------------------------------------

  .( bwindow.f )

\ ------------------------------------------------------------------------
\ windows need a screen to live in

  create bug-screen scr allot   \ allot space for screen structure
  bug-screen scr erase          \ erase it

\ ------------------------------------------------------------------------
\ allot space for bunches of window structures

  create backdrop win allot  backdrop win erase
  create codewin  win allot  codewin  win erase
  create pwin     win allot  pwin     win erase
  create rwin     win allot  rwin     win erase
  create memwin   win allot  memwin   win erase
  create infowin  win allot  infowin  win erase
  create outwin   win allot  outwin   win erase
  create seewin   win allot  seewin   win erase

\ ------------------------------------------------------------------------
\ create an array of windows

create win-list
]
  codewin pwin rwin memwin
  infowin backdrop outwin
  seewin
[

\ ------------------------------------------------------------------------
\ fetch the ix'th window from the list

: win-list@     ( ix --- win )
  win-list swap []@ ;

\ ------------------------------------------------------------------------

: kill-window   ( ix --- ix' )  1- dup win-list@ close-win ;
: alloc-window  ( ix --- ix' )  1- dup win-list@ walloc drop ;
: attach-window ( ix --- ix' )  1- bug-screen over win-list@ attach ;

\ ------------------------------------------------------------------------
\ deallocate all windows so we can reallocate on new window size

: kill-windows  ( --- )
  8 dup rep kill-window drop
  bug-screen close-screen ;

\ ------------------------------------------------------------------------
\ allocate buffers for windows, attach windows to screen

: alloc-windows  ( --- )  8 dup rep alloc-window drop ;
: attach-windows ( --- )  6 dup rep attach-window drop ;

\ ------------------------------------------------------------------------
\ initialize debug screen and windows

: bug-init-screen
  bug-screen buffer1@ ?exit \ dont initialize this twice

  cols rows 1-              \ create screen, backdrop window and
  2dup bug-screen (screen)  \ output windows
  2dup backdrop (window)    \ backdrop is dummy window, shows solid bgnd
       outwin (window)      \ outwin is where application emits to

  cols 2/ 4- rows 5 -       \ codewin shows decompilation of word
    codewin (window)        \ being debugged

  bug-screen salloc drop    \ allocate buffers for debug screem

  9 8 pwin (window)         \ create stack display windows for both
  9 8 rwin (window)         \ parameter stack and return stack

  codewin win-width@ dup
     4+   rows 16 - memwin (window)
     16 - 8         infowin (window)

  codewin win-width@ 200 seewin (window)

  alloc-windows
  attach-windows

  $43 backdrop tuck win-color! dup >fill clw
  $47 codewin  tuck win-color! dup clw >borders
  $47 pwin     tuck win-color! dup clw >borders
  $47 rwin     tuck win-color! dup clw >borders
  $47 memwin   tuck win-color! dup clw >borders
  $47 infowin  tuck win-color! dup clw >borders

  2 2 codewin winpos!
  0 0 outwin  winpos!

  codewin win-width@
    dup  4+  rows 11 - pwin winpos!
    dup 13 + rows 11 - rwin winpos!

    dup  4+        2   memwin winpos!
        24 + rows 11 - infowin winpos! ;

\ ------------------------------------------------------------------------
\ window change signal handler

: bug-winch
  kill-windows          \ deallocate all windows and screens
  bug-init-screen ;     \ reallocate and configure windows

\ ------------------------------------------------------------------------
\ add/remove handler for winch semaphore

: +bug-sem 0 ['] bug-winch +semaphore drop ;
: -bug-sem 0 ['] bug-winch -semaphore drop ;

\ ========================================================================
