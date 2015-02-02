\ see.f         - isforth high level definition decompiler
\ ------------------------------------------------------------------------

  .( see )

\ ------------------------------------------------------------------------

  defer seecr               \ see does a cariage return... somewhere

\ ------------------------------------------------------------------------

  0 var eline               \ true if current line is empty
  0 var ?indent             \ request indent (done if line is not empty)
  0 var indent              \ ammount to indent by
  0 var end-of-:            \ address of exit at the ; (i think its here)
 -1 var []exec:             \ which cell of exec: debug would select
 -1 var []?:                \ which cell of ?: debug would select
  0 var ??:                 \ which xt of ?: are we on (helps indent)

\ ------------------------------------------------------------------------
\ array of 1024 valid execution unit addresses

  0 var []xu                \ pointer to execution unit array
  0 var #xu                 \ total number of items in array
  0 var c-ix                \ current cursor index within xu array
  0 var ip-index            \ current ip index within array
  0 var c-line              \ usually coincides with ip-line
  0 var mid-point           \ mid line of code window
  0 var top-line            \ seewin line # at the top of code win

\ ------------------------------------------------------------------------
\ various attributes

  $24 const cattr           \ attributes to display cursor with
  $13 const highlight       \ atrtribute for address where ip is
  $47 const normal          \ normal attrib
  $20 const brkattr         \ breakpoint attrib

   0 var attr               \ chosen attribute

\ ------------------------------------------------------------------------

: see-attr      ( color --- ) seewin win-color! ;

: >normal       ( --- )  normal see-attr ;
: >high         ( --- )  highlight see-attr ;
: >attr         ( --- )  attr see-attr ;

\ ------------------------------------------------------------------------
\ flush all entries from execution unit array

: clear-[]xu    ( --- )
  []xu 4096 erase           \ clear array
  off> #xu ;                \ clear count

\ ------------------------------------------------------------------------
\ add current decompilation address to array of xu addresses

: +xu           ( a1 --- )
  []xu #xu []!              \ this is used by the debug module
  incr> #xu ;

\ ------------------------------------------------------------------------
\ are we decompiling the xt where the debug ip is?

: ?ip           ( a1 --- a1 )
  dup app-ip <> ?exit       \ is this the address where ip is ?

  #xu 1- !> ip-index        \ remember index to where ip is in []xu
  highlight !> attr         \ set ip draw attributes

  \ align cursor with ip if cursor position was made invalid

  c-ix -1 <> ?exit          \ if cursor location is invalid...
  ip-index !> c-ix          \ alight cursor with ip
  seewin win-cy@            \ get see windows cursor y
  !> c-line ;               \ set debug cursor seewin line

\ ------------------------------------------------------------------------
\ currently decmpiling the xt under the debug cursor?

: ?cursor       ( a1 --- a1 )
  dup []xu c-ix []@         \ if decompile index same as cursor index
  <> ?exit cattr !> attr ;  \ set cursor highlight attributes

\ ------------------------------------------------------------------------
\ is current decompile xu a breakpoint

: ?brk      ( a1 --- a1 )
  dup isbreak 0= ?exit      \ if xu were about to draw is a breakpoint
  brkattr !> attr ;         \ set breakpoint attributes

\ ------------------------------------------------------------------------
\ highlight selected xt of exec: block

: []exec:?  ( a1 --- a1 )
  dup []exec: <> ?exit      \ is a1 the xt that exec: or ?: will select?
  on> []exec:               \ yes unselect it
  highlight !> attr ;       \ highlight this xt

\ ------------------------------------------------------------------------

: []?:?     ( a1 --- a1 )
  dup []?: <> ?exit on> []?:
  highlight !> attr ;

\ ------------------------------------------------------------------------
\ color attributes are only valid if decompiling for the debug module

: >bug-attrib   ( a1 --- a1 )
  in-debug not ?exit        \ dont set attribs if not in debug mode
  normal !> attr            \ assume normal attributes

  \ each the following line may override the above attrib setting.  the
  \ order is from lowest to hightst priority

  ?cursor ?brk ?ip []exec:? \ set attribs to display this xt with
  []?:? >attr ;

\ ------------------------------------------------------------------------
\ output a cr within the see window

: bug-cr        ( --- )  seewin win-cr ;

\ ------------------------------------------------------------------------
\ emit character to see window

: (bug-emit)    ( c1 --- ) seewin wemit ;

\ ------------------------------------------------------------------------
\ emit a character to the see window

: bug-emit      ( c1 --- )
  seewin win-cx@            \ why am i clipping instead of wrapping?
  seewin win-width@ <       \ ****TODO**** wrap this not clip duh
  ?: (bug-emit) drop ;

\ ------------------------------------------------------------------------
\ output a normal attribute blank (space).  used as indent char

: .space        ( --- )  >normal space >attr ;

\ .space is just a space but when used in debug mode it will always be a
\ normal attribute blank.

\ ------------------------------------------------------------------------
\ indent to current level

: do-indent
  seecr                     \ an indent is an implied new line
  indent 1+ 2* rep .space   \ indent
  on> eline ;               \ current line is empty

\ ------------------------------------------------------------------------
\ indent has been requested... do it unless current line is empty

: (.indent)
  ?indent eline not and     \ dont indent an empty line
  ?: do-indent noop         \ otherwise go ahead
  off> ?indent ;            \ clear indent request

\ ------------------------------------------------------------------------

: .indent       ( --- )  on> ?indent (.indent) ;
: +indent       ( --- )  incr> indent .indent ;
: -indent       ( --- )  indent 0= ?exit decr> indent .indent ;

\ ------------------------------------------------------------------------

\ we have decompiled up to the end of some control structure (if/then etc)
\ and are about to indent to a new line.  if however the xt immediatly
\ following the control structure is the terminating exit then we must not
\ indent or else we will display the semicolon on a line by itself.

: ??indent           ( a1 --- a1 )
  dup @ ['] exit =          \ are we at an exit ?
  indent 0= and             \ at the end of the definition?
  if
    .space exit             \ we just need a space before the ;
  then
  on> ?indent ;             \ just requests indent, does not perform it

\ ------------------------------------------------------------------------
\ about to draw with cursor beyond a soft max width?

: max-width     ( n1 --- f1 )
  in-debug                  \ are we in debug mode
  if
    seewin win-cx@ +        \ set soft max width to see window width
    seewin win-width@ 5 -   \ minus 5
  else
    #out @ + cols 10 -      \ else set it to console width minus 10
  then
  < not ;                   \ are we at or above this width?

\ ------------------------------------------------------------------------
\ type one character of string at address a1, advance address

: (seetype)     ( a1 --- a1' )
  count emit ;

\ ------------------------------------------------------------------------
\ debugger types a string...

: seetype       ( a1 n1 --- )
  dup max-width             \ are we above the soft max width?
  if                        \ if so then do a forced indent before
    .indent                 \ displaying the strong
  then
  rep (seetype) drop ;

\ ------------------------------------------------------------------------
\ see displays a number (always displayed in hex)

: see.          ( n1 --- )
  base @ >r hex             \ retain current radix, set hex
  0 (d.) r> base !          \ convert number to a string

  dup max-width
  ?: do-indent noop

  '$' emit seetype .space ; \ display the number and a blank

\ ------------------------------------------------------------------------
\ display string or single char (indent first if its requested)

: dtype         ( a1 n1 --- )  (.indent) seetype off> eline ;
: demit         ( c1 --- )     (.indent) emit off> eline ;

\ ------------------------------------------------------------------------
\ type a compiled string indenting if needed

: (d")          ( --- )
  r> count                  \ get address of string
  2dup + >r                 \ set return address to past end of string
  dtype ;                   \ type string

\ ------------------------------------------------------------------------
\ compile a decompiler string

 : d"            ( --- )
   compile (d") ," ; immediate

\ ------------------------------------------------------------------------

: .d            ( n1 --- )
  (.indent)                 \ do any requested indent if not on blank line
  see.                      \ display number
  off> eline ;              \ line is no longer empty for sure!

\ ------------------------------------------------------------------------
\ decompiling a headerless word. show its name as 'unknown'

: .noname       ( --- )
  d" ???" ;                 \ just dont define a word called ??? :)

\ ------------------------------------------------------------------------
\ display identity (name) of an xt given its name field address

: (.id)         ( nfa --- )
  count lexmask             \ convert nfa into string address and length
  dup max-width             \ indent if were at soft max width
  if
    .indent
  then
  seetype ;                 \ display name

\ ------------------------------------------------------------------------
\ display word name or show word as being headerless

  headers>

: .id           ( cfa --- )
  >name ?dup                \ go from cfa to nfa. test nfa for null
  ?: (.id) .noname          \ display nfa or unknown for headerless words
  .space ;

\ ------------------------------------------------------------------------
\ indent and show word name

  <headers

: >.id          ( cfa --- )
  (.indent) .id             \ conditionally indent, then show word name
  off> eline ;              \ line is no longer empty

\ ------------------------------------------------------------------------
\ get next xt from a colon definition, advance address

: $@+           ( a1 --- a2 xt )
  dup cell+                 \ advance address
  swap @ ;                  \ fetch xt

\ ------------------------------------------------------------------------
\ emit a quote char and a space

: .quote       ( --- )     \ cant call this ." :)
  '"' demit ;

\ ------------------------------------------------------------------------

: (.-")        ( a1 --- a2 )
  count 2dup                \ get address and lenght of string
  .quote bl demit           \ display string wrapped up in quotes
   dtype .quote
  + ??indent ;              \ advance to address a2 at end of string

\ ------------------------------------------------------------------------
\ decompile some string things found in a colon definition

: .-."        ( a1 --- a2 ) .indent '.' demit (.-") ;
: .-abort"    ( a1 --- a2 ) .indent d" abort" (.-") ;

\ -------------------------------------------------------------------------
\ decompile a literal

: .-lit       ( a1 --- a2 )
  $@+ dup elf0 here between \ is literal an address within list space?
  if
    dup >name               \ if so does it have a name ?
    head0 hhere between
    if                      \ if so then display ['] name
      .indent d" ['] " .id
      exit
    then
  then
  .d ;                      \ non of the above. just display value

\ -------------------------------------------------------------------------
\ display default vector of a case statement

  0 var opt-found

: ?.dflt        ( vector --- )
  ?dup 0= ?exit             \ is there a default vector set?
  -indent normal !> attr    \ if so undent to same depth as the "case: "

  >attr d" dflt " +indent   \ display "dflt" and re indent back up one

  opt-found 0=              \ if no non default option was found
  app-ip@ ['] docase = and  \ and ip is currently pointing at the case:
  ?: >high noop >.id ;      \ highligh default vector address

\ -------------------------------------------------------------------------
\ like .-lit for use in case: where were in interpret mode so its ' not [']

: .-opt       ( a1 --- a2 )
  $@+                       \ get compiled in option value

  dup elf0 here between     \ is option value an address within list space?
  if
    dup >name               \ if so does it have a name ?
    head0 hhere between
    if                      \ if so then display ' name
      .indent >normal d" ' "
      >attr .id exit
    then
  then
  >attr .d ;

\ -------------------------------------------------------------------------
\ displa one option and vector from body of a case statement

: (.-case)      ( body count --- )
  off> opt-found            \ if not found dflt will be highlighted later
  for
    .indent                 \ go to next line and indent to current depth

    dup @ app-sp@ =         \ option same as value at top of stack?
    if
      on> opt-found         \ yup, dont highlight dflt
      highlight             \ but highlight this case option
    else
      normal
    then
    !> attr

    .-opt d" opt " $@+ >.id
  nxt
  drop ;

\ -------------------------------------------------------------------------
\ decompile a complete case: statement

: .-case      ( a1 --- a2 )
  .indent d" case:"         \ move to new line - indent to current level
  normal !> attr +indent    \ bump indent level
  $@+ swap $@+ swap $@+     \ get exit point, default vector and count
  (.-case) ?.dflt
  normal !> attr
  -indent d" ;case"         \ undent and display termination of case:
  ??indent ;                \ go to new line unless at end of definition

\ ------------------------------------------------------------------------
\ discard next xt from word to decompile

: @+d           ( a1 --- a2 ) $@+ drop ;
: >i@d          ( a1 --- a2 ) +indent @+d ;

\ ------------------------------------------------------------------------
\ decompile if else then

: .-if        ( a1 --- a2 ) .indent d" if" >i@d ;
: .-else      ( a1 --- a2 ) -indent d" else" >i@d ;
: .-then      ( a1 --- a1 ) -indent d" then" ??indent ;

\ ------------------------------------------------------------------------
\ decompile a ?:  (more efficient if/else/then construct)

: .-?:        ( a1 --- a2 )
  .indent d" ?:" .space     \ display ?:
  ( +indent ) 1 !> ??:
  in-debug 0= ?exit         \ if not in debug mode dont worry about colors

  app-ip cell+ over =       \ is ip currently pointing at the ?: xt?
  if
    app-ip cell+ app-sp@    \ assume true case will be selected
    ?: noop cell+ !> []?:
  then ;

\ ------------------------------------------------------------------------
\ decompile do loops

: .-do        ( a1 --- a2 ) .indent d" do" >i@d ;
: .-?do       ( a1 --- a2 ) .indent d" ?do" >i@d ;
: .-loop      ( a1 --- a2 ) -indent d" loop" @+d ??indent ;
: .-+loop     ( a1 --- a2 ) -indent d" +loop"  @+d ??indent ;

\ ------------------------------------------------------------------------
\ decompile begin while repeat until again

: .-begin     ( a1 --- a1 ) .indent d" begin"  +indent ;
: .-while     ( a1 --- a2 ) -indent d" while"  >i@d ;
: .-repeat    ( a1 --- a2 ) -indent d" repeat"  @+d ??indent ;
: .-until     ( a1 --- a2 ) -indent d" until"   @+d ??indent ;
: .-again     ( a1 --- a2 ) -indent d" again"   @+d ??indent ;

\ also works with "begin while until else then" loops ftw!

\ ------------------------------------------------------------------------
\ decompile for/nxt

: .-for       ( a1 --- a2 ) .indent d" for" +indent ;
: .-nxt       ( a1 --- a2 ) -indent d" nxt" @+d ??indent ;

\ ------------------------------------------------------------------------
\ decompile !> +!> incr> decr> on> off>

: .%          ( a1 --- a2 )
   $@+ body> >.id ;

\ ------------------------------------------------------------------------
\ decompile operations that are performed on var's (or constants? :)

: .-!>        ( a1 --- a2 )  d" !> "    .% ;
: .-+!>       ( a1 --- a2 )  d" +!> "   .% ;
: .-incr>     ( a1 --- a2 )  d" incr> " .% ;
: .-decr>     ( a1 --- a2 )  d" decr> " .% ;
: .-on>       ( a1 --- a2 )  d" on> "   .% ;
: .-off>      ( a1 --- a2 )  d" off> "  .% ;

\ ------------------------------------------------------------------------
\ decompile a ;uses

: .-;uses
  d" ;uses " $@+ >.id ;

\ ------------------------------------------------------------------------
\ decompile a rep statement and its parameter (the word to be repeated)

: .-rep         ( --- )
  d" rep " $@+ .id ;

\ ------------------------------------------------------------------------
\ does ;code part point to dodoes?

: ?does>        ( a1 --- a2 )
  ['] dodoes
  over - 5 -                \ compute delta,  cfa a1 to compiled word
  over 1+ @ =               \ fetch address called by a1 and see if same
  if
    .indent d" does>"
    .indent >body           \ skip past the "call dodoes"
     exit
  then
  d" ;code "                \ this part is wrong but ill fix it when
  r>drop ;                  \ the disassembler is done

\ ------------------------------------------------------------------------
\ defered so disassembler can patch into it (some day)

  defer .-;code   ' ?does> is .-;code

\ ------------------------------------------------------------------------

: .-compile     ( a1 --- a2 )
  d" compile " $@+ >.id ;

\ ------------------------------------------------------------------------

: .-leave       ( a1 --- a1 )
  d" leave" .space ;

\ ------------------------------------------------------------------------

: (.xt)         ( a1 --- a2 )
  cell- $@+ >.id ;

\ ------------------------------------------------------------------------
\ display an exec: (only a special case when in debug mode)

: .-exec:       ( a1 --- a2 )
  in-debug                  \ not valid unless were in debug mode
  if
    dup app-sp@ cells +     \ get address of xt selected by exec:
    !> []exec:              \ remember this address so when it is
  then                      \ decompiled it can be highlighted
  (.xt) ;                   \ decompile the exec: xt itself

\ ------------------------------------------------------------------------

: ?indent-?:    ( --- )
  ??:
  case:
    0 opt exit
    1 opt +indent
    2 opt .indent
  ;case

  incr> ??: ??: 3 =
  if
    off> ??:
    -indent
  then ;

\ ------------------------------------------------------------------------
\ display xt from : def accounts for special cases

: .xt           ( a1 xt --- a2 false )
  ?indent-?:                \ if were processing a ?: handle indents now

  case:
    ' (lit)    opt .-lit    \ special cases...
    ' (.")     opt .-."
    ' (d")     opt .-."     \ *** see below
    ' (abort") opt .-abort"
    ' docase   opt .-case
    ' doif     opt .-if
    ' doelse   opt .-else
    ' dothen   opt .-then
    ' ?:       opt .-?:
    ' (do)     opt .-do
    ' (?do)    opt .-?do
    ' (loop)   opt .-loop
    ' (+loop)  opt .-+loop
    ' (leave)  opt .-leave
    ' dobegin  opt .-begin
    ' ?while   opt .-while
    ' dorepeat opt .-repeat
    ' ?until   opt .-until
    ' doagain  opt .-again
    ' %!>      opt .-!>
    ' %+!>     opt .-+!>
    ' %incr>   opt .-incr>
    ' %decr>   opt .-decr>
    ' %on>     opt .-on>
    ' %off>    opt .-off>
    ' compile  opt .-compile
    ' ;code    opt .-;code
    ' dofor    opt .-for
    ' (nxt)    opt .-nxt
    ' ;uses    opt .-;uses
    ' dorep    opt .-rep
    ' exec:    opt .-exec:
  dflt
    (.xt)                   \ defualt, not a special case
  ;case ;

\ *** (d") is defined within this decompiler. in order to allow this
\ decompiler to decompile certain definitions within itself that make use
\ of debug strings compiled with d" i have added this case here which will
\ decompile all (d") xt's as (.") xt's instead of crashing

\ the debugger is STILl not able to debug itself however so dont try
\  (probably never will)

\ ------------------------------------------------------------------------
\ is address a1 the end of the definition?

\ this definition is wrong.   ** see below

: end-of-:?     ( a1 --- a1 f1 )
  ['] exit over =           \ dont display an 'exit' unless its not
  indent 0= and ;           \ the one compiled by the ;

\ **
\
\  the above test cannot handle cases such as the following
\
\    : max  ( n1 n2 --- n1 | n2 )  2dup < if begin drop ;
\    : min  ( n1 n2 --- n1 | n2 )  2dup < until then nip ;

\ ------------------------------------------------------------------------
\ about to decompile an xt. test if its an immediate word

: .[compile]?       ( xt --- xt )
  dup >name                 \ get nfa of xt
  ?dup 0= ?exit             \ does it have a name?
  c@ $40 and                \ during compilation any immediate word
  if                        \ that is to be compiled instead of executed
    d" [compile] "          \ must be preceeded by [compile].
  then ;                    \ make the decompiler reflect this

\ doing this also lets the user know the word being decompiled has
\ immediate words compiled into it and thus can help them learn which
\ words are and are not immediate

\ ------------------------------------------------------------------------
\ decompile body of : definition

: (.-:)         ( body --- end-of-: )
  begin
    dup +xu                 \ save current execution unit address
    >bug-attrib             \ set debug attributes
    $@+                     \ fetch next xt
    end-of-:? not           \ while were not at the terminating exit
  while
    .[compile]?             \ conditionally display [compile] before xt
    .xt                     \ display name of this xt   *** see note
  repeat
  drop ;

\ *** .xt for will for certain words fetch extra data using $@+ that
\ the xt we are decompiling would also fetch at run time.  this means
\ the current decompile address after .xt completes will be pointing
\ to the next execution unit within the definition being decompiled

\ the +xu at the top of this definition stores the current decompile
\ address within the []xu array.  one xu can be many xt's. for examplem
\ the entire contents of a case statement is considerd ONE xu

\ this []xu array is not needed by the decompiler itself but is used by
\ the debugger as an aid to single stepping through code.

\ ------------------------------------------------------------------------
\ decompile a complete colon definition

: .-:           ( cfa --- )
  clear-[]xu                \ erase xu addresses array
  off> indent               \ reset indent level
  d" : " dup >.id           \ show the : and the word name
  .indent                   \ indent
  >body (.-:)               \ point to body of colon and decompile it
  cell- !> end-of-:         \ remember address of 'exit' xt
  d" ;" .space ;            \ show terminating semicolon

\ ------------------------------------------------------------------------

: .-defered   ( cfa --- )  dup >body @ d"  ' " >.id d"  is " >.id ;
: .-variable  ( cfa --- )  d"  variable " >.id ;
: .-constant  ( cfa --- )  .space dup >body @ see. d" constant " >.id ;

\ ------------------------------------------------------------------------

: (see)         ( cfa --- )
  dup ?cfa                  \ to what does cfa of word to decompile refer?

  \ todo  allow decompilation of a does> word by decompiling the word
  \ that created it.  the debug module alredy does this but not
  \ the decompiler itself

  case:                     \ if its not one of these we cant decompile it
    ' nest       opt .-:
    ' doconstant opt .-constant
    ' dovariable opt .-variable
    ' dodefer    opt .-defered
\   ' what-did   opt .i-miss?
\ dflt
\   disassemble :)
  ;case ;

\ ------------------------------------------------------------------------
\ copy viewable part of debugs see window into the code window

: .seewin
  seewin win-cy@            \ is bottom line of seewin above bottom line
  codewin win-height@ <     \ of codewin or the cursor above mid line?
  c-line mid-point < or
  if                        \ if so. put top line of see win on top line
    0                       \   of code win
  else
    codewin win-height@     \
    mid-point - c-line +
    seewin win-cy@ <
    if
      c-line mid-point -
    else
      seewin win-cy@
      codewin win-height@ - 1+
    then
  then

  seewin  win-width@ cells *
  seewin  win-buff@ +
  codewin win-buff@
  codewin win-height@
  codewin win-width@ cells *
  cmove ;

\ ------------------------------------------------------------------------
\ show word we just decompiled is immediate if it is immediate

: ?.immediate       ( cfa --- )
  >name ?dup 0= ?exit      \ see if decompiled word is immediate
  c@ $40 and
  if
    d"  immediate"
  then
  cr ;

\ ------------------------------------------------------------------------
\ initialie see for use by the debuger

: bug-see       ( a1 --- )
  base @ >r hex             \ debugger always shows numbers in hex
  ['] emit >body @ >r       \ save current emit vector

  ['] bug-cr is seecr       \ cr is done within the debug see window
  ['] bug-emit is emit      \ emits go to the debug see window

  on> in-debug              \ let see know its being used by debugger

  >normal seewin clw        \ clear see window to its default attribs
  on> eline                 \ current line is empty
  dup>r (see)               \ decompile....
  r> ?.immediate            \ show weather decompiled word is immediate
  .seewin                   \ write see window into debug window
  r> is emit r> radix ;     \ restore

\ ------------------------------------------------------------------------

  headers>                  \ this is the ONLY thing in here thats visible

: see           ( --- )
  ['] cr is seecr
  off> in-debug             \ we are not in the debuggr
  on> eline                 \ current line is empty however
  cr cr ' dup (see)         \ decompile word
  ?.immediate cr ;

\ ------------------------------------------------------------------------

: 'see          ( a1 --- )
  ['] cr is seecr
  off> in-debug on> eline
  cr cr dup (see)
  ?.immediate cr ;

\ ------------------------------------------------------------------------
\ allocate array of code line addresses

  <headers

: bug-alloc     ( --- )
  defers default            \ make this happen at start of world
  4096 allocate drop        \ is 4k big enough for ONE SINGLE DEFINITION?
  !> []xu ;                 \ if its not then "step away from the kbd!"

\ ========================================================================
