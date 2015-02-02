\ info.f    - isforth debuggr info window display
\ ------------------------------------------------------------------------

  .( info.f )

\ ------------------------------------------------------------------------

\ these words display useful information about the item currently
\ pointed to by the interprative pointer.  they will display the contents
\ of a variable, where a deferred word is vectored to etc etc.

\ ------------------------------------------------------------------------

: .delay        ( --- )
  infowin win-cr
  infowin win" Step Delay Set To: "
  infowin step-delay s>d <# #s #> wtype ;

\ ------------------------------------------------------------------------
\ display name of item were shoing info for

: .xt-id        ( a1 --- )
  >name ?dup                \ is word headerless?
  if
    count lexmask           \ no, display it in infowin
    infowin -rot wtype
  else
    infowin win" ???"       \ word is headerless
  then ;

\ ------------------------------------------------------------------------
\ display contents of variable under ip

: .variable     ( a1 --- )
  dup .xt-id >body @        \ display nfa of item being pointed to
  infowin win"  = "
  0 <# 8 rep # '$' hold #>
  infowin -rot wtype        \ display string within info window
  infowin win-cr ;

\ ------------------------------------------------------------------------
\ display contents of defered word under ip

: .defered
  infowin win" ' "          \ display tick
  dup >body @               \ fetch cfa of word vectored to by deferred
  dup ['] newkey =          \ dont show debuggers key handler if this
  if                        \ is the key handler we are decompiling
    drop old-key            \ show applications key handler
  then
  .xt-id                    \ show word name vectored to by deferred word
  infowin win"  is "
  .xt-id                    \ show name of deferred word itself
  infowin win-cr ;

\ ------------------------------------------------------------------------
\ display contents of item under ip

: .info
  app-ip@ dup ?cfa
  case:
    ' doconstant opt .variable
    ' dovariable opt .variable
    ' dodefer    opt .defered
  dflt
    drop
  ;case
  off> cmoved ;

\ ------------------------------------------------------------------------
\ update debug display

: update
  seestack []@ ?empty       \ this should never be empty here
  bug-see                   \ decompile current definition

  .memory                   \ update memory window
  .pstack                   \ update stacks display
  .rstack

  cmoved   ?: noop .info    \ show info about word under cursor?
  stepping ?: noop flush
  bug-screen .screen        \ redraw the screen

  \ debug info at top left so i can see when  stuff is fscking up
  \ remove this kthxbai
   exit
  sc 0 0 at
  stepstack [].sp@ . space
  seestack  [].sp@ . space
  bug-stacks 8192 + sp@ - cell/ . space
  rc ;

\ ========================================================================
