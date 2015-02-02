\ args.f        - isforth command line args primatives
\ ------------------------------------------------------------------------

  .( loading args.f ) cr

\ ------------------------------------------------------------------------
\ user must initialize these in application code

  0 var arg#                \ number of next arg to process
  0 var arglist             \ list of known args (list of counted strings)
  0 var argscount           \ number of args in above list

\ ------------------------------------------------------------------------
\ get next arg from argp[] array

  <headers

: (arg@)        ( --- a1 )
  argp arg# []@ ;           \ get address of next arg

\ ------------------------------------------------------------------------
\ this is for your convenience when handling arg option strings etc

  headers>

: arg@          ( --- a1 )
  (arg@) incr> arg# ;

\ ------------------------------------------------------------------------

\ the following does not increment arg# unless it finds an arg it
\ recognizes from the supplied list.  this gives you the ability to
\ further process an unrecognized arg

: ?arg          ( --- n1 true | false )
  0                         \ prime result...
  (arg@)                    \ point to next asciiz arg from argp[] array
  arglist                   \ point to list of known (count string) args
  begin
    count 2dup + >r         \ get a1/n1 of arg option (save addr of next)
    pluck swap comp         \ is argp[arg#] same as arglist[n] ?
    if
      r> 2drop 1+           \ yes - return n
      incr> arg# exit
    then
    swap 1+ swap r>         \ increment n retrieve next arg list entry
    pluck argscount =       \ is n maxed ?
  until
  3drop false ;             \ yes - unknown arg

\ ------------------------------------------------------------------------
\ start creating an args list

  headers>

: args:         ( --- a1 0 )
  create here 0             \ create named args list compile 0 args count
  cell allot                \ count will be patched when list is complete
  does>
    dcount                  \ fetch args count
    !> argscount
    !> arglist
    off> arg# ;

\ ------------------------------------------------------------------------
\ add an arg to the list

: arg"          ( n1 --- n2 )
  1+                        \ bunp args count
  [compile] ," ;            \ compile arg string

\ ------------------------------------------------------------------------
\ complete args list

: ;args         ( a1 n1 --- )
  swap ! ;

\ ------------------------------------------------------------------------
\ application code must initialize for and process args as follows

\ args: my-args
\   arg" -1"
\   arg" -f"
\   arg" -h"
\ ;args
\
\ : do-my-args
\   my-args                 \ tell this extension what list were using
\   begin
\     ?arg                  \ get argslist index of next arg
\     case:
\       0 opt .useage       \ not in list
\       1 opt do-dash-one
\       2 opt do-dash-f
\       3 opt do-dot-help
\     ;case
\     arg# argscount =
\   until ;

\ if ?arg returns failure your code could call arg@ and further process
\ the offending arg.  if an arg expects an option string it is up to you
\ to handle it.  e.g. the -f above might want a filename to follow it in
\ the argp[] list.  you would call arg@ to get the file name.

\ ------------------------------------------------------------------------

  behead

\ ========================================================================
