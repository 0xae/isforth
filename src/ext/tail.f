\ tail.f        - isforth command line tail processing
\ ------------------------------------------------------------------------

  .( loading tail.f ) cr

\ ------------------------------------------------------------------------
-headers
  <headers

\ this code should not be included in any turnkey applications. this is
\ the isforth development environments default arg processing code.
\
\ see args.f for details on how to produce something similar for your own
\ code

\ ------------------------------------------------------------------------

 0 var floading             \ defer fload till after default init

\ ------------------------------------------------------------------------
\ for shebanged forth script files

  headers>

: #!
  on> shebang               \ shebang line must contain a -sfload
  floading                  \ dont allow -fload in the #! line
  if
    ." Do not use -fload in the shebang line" cr
    ." Your shebang should use -sfload instead " cr cr
    0 <exit>
  then
  [compile] \ ;

\ ------------------------------------------------------------------------
\ exit now if isforth was executed via a shebanged forth source

 <headers

: ?shebang
  shebang not ?exit
  errno <exit> ;

\ ------------------------------------------------------------------------

: arg-missing?
  arg# argc =
  if
    cr ." Missing Argument"
    cr 0 <exit>
  then ;

\ ------------------------------------------------------------------------

: arg-help
  cr
  ."  -fload FILE               Interpret specified file" cr
  ."  #! isforth -sfload        Place at top of shebanged script" cr
  ."  -help                     Your reading it" cr cr 0 <exit> ;

\ do not use -fload on the shebang line in a script as this will cause the
\ default init chain to run before the script is executed.

\ ------------------------------------------------------------------------

: arg>tib
  #tib @ >r                 \ get current length of tib
  arg@ dup strlen           \ get filename string
  dup #tib +!               \ copy filename into tib
  tib r> + swap cmove
  bl tib #tib @ + c! #tib incr ;

\ ------------------------------------------------------------------------
\ execute an fload of specified file

here
  ," fload "

: do-sfload
  arg-missing?              \ fload expects a file name
  literal count dup #tib !  \ copy "fload " to tib
  tib swap cmove arg>tib

  begin                     \ keep interpreting this fload and
    interpret               \ refiling input until the fload ends and
    ['] refill >body @      \ the refill mechanism is restored to its
    ['] query =             \ default of query
  until ;                   \ interpret specified file

\ ------------------------------------------------------------------------

: do-fload
  arg# !> floading          \ remember current arg position
  argc !> arg# ;            \ halt processing of args till after default

\ ------------------------------------------------------------------------

args: dargs                 \ isforths default args list
  arg" -fload"              \ fload a file specified on the arg list
  arg" -sfload"             \ fload a shebanged script
  arg" -help"               \ display info on args
;args

\ ------------------------------------------------------------------------

: (doargs)
  off> shebang              \ assume not running from #! script
  dargs                     \ init for arg scan of this list
  begin
    #tib off >in off
    ?arg           \ is next arg in list known to us?
    case:
      0 opt arg-help        \ unknown arg
      1 opt do-fload        \ fload specified file
      2 opt do-sfload       \ fload a shebanged script
      3 opt arg-help        \ display useage info
    ;case
    arg# argc =
  until ;

\ ------------------------------------------------------------------------
\ this word patches itself into the hi priority default init chain

: doargs          ( ---- )
  defers pdefault
  argc                      \ dont try interpret null args
  if
    (doargs)                \ process args
    ?shebang                \ quit now if we just ran a #! script
  then ;                    \ otherwise....

\ ------------------------------------------------------------------------
\ this word patches itself into the low priority default init chain

\ -sfload will be handled prior to any initialization via default so
\ .hello and .status etc are not dumped to the display for script files.
\ also, when the script completes forth quits and init never gets run at
\ all.  this means that scripts cannot use some things that are not
\ initialized (like the text windowing stuff).
\
\ -fload just sets a flag which tells the following word to do the fload.
\ this word is not executed until everything else in the default init
\ chain has run so everything will have been initialized.

: do-floading
  defers ldefault
  floading ?dup             \ did do-args set this?
  if
    off> floading
    !> arg#
    do-sfload
  then ;

\ ------------------------------------------------------------------------

 behead
+headers
\ ========================================================================
