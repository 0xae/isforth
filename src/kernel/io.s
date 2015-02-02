;io.1      - isforth i/o words
;-------------------------------------------------------------------------

 _constant_ 'bs', bs, 8             ;a backspace
 _constant_ 'bl', bl_, 32           ;a space

 _variable_ '>in', toin, 0          ;current position within TIB
 _variable_ '#tib', numtib, 0       ;number of chars in TIB
 _variable_ 'span', span, 0         ;# characters expected by expect
 _variable_ '#out', numout, 0       ;# characters thus far emmited on line
 _variable_ '#line', numline, 0     ;how far down the screen we are
 _constant_ 'fdout', fdout, 1       ;defaults file descriptor for emit

;-------------------------------------------------------------------------
;these constants are patched by an extension to reflect actual dims

 _constant_ 'rows', rows, 25        ;default terminal size to 80 by 25
 _constant_ 'cols', cols, 80

;-------------------------------------------------------------------------
;output a character to stdout

;       ( c1 --- )

colon '(emit)', pemit
  dd spfetch                ;point to character to emit
  dd fdout, swap            ;normally stdout
  dd plit, 1                ;writing one character only to stdout
  dd sys_write, drop2       ;discard return value and character
  dd numout, incr
  dd exit

;-------------------------------------------------------------------------
;output charater c1 to where ever

code 'emit', emit
  call dodefer              ;allows revectoring of output for processing
  dd pemit                  ;by any word

;-------------------------------------------------------------------------
;pollfd for stdin.   we only want to know when data is available

; here 0 , 1 w, 0 w,

;       ( --- a1 )

qkfd:
  dd 0                      ;stdin file handle
  dw 1                      ;want to know when data is there to read
  dw 0                      ;returned events placed here

;-------------------------------------------------------------------------
;uses qkfd pollfd structure to poll standardin

;       ( --- f1 )

colon 'key?', keyq
  dd plit, 0                ;timeout in ms
  dd plit, 1                ;we only have one pollfd structure
  dd plit, qkfd             ;at this address
  dd sys_poll
; should do 3 and 0<> here
  dd plit, 1, equals        ;ok i know this is bad but - bleh
  dd exit

;i should realy examine the masks in qkfd above to see what realy occured
; - maybe later ill do that

;-------------------------------------------------------------------------
;wait for data to become available on stdin then read stdin

;       ( --- c1 )

colon '(key)', pkey
  dd plit, 0                ;create read buffer
  dd spfetch                ;point at it :)
  dd plit, 1, swap          ;read one character
  dd plit, 0                ;from stdin
  dd sys_read, qexit        ;return if there was no error
  dd intty, qexit           ;there was an error. if stdin is not on a tty
  dd bye                    ; i.e. we are running from a #! script
  dd exit                   ; then abort script

;-------------------------------------------------------------------------
;defered word to read 1 key (normally from stdin)

;       ( --- c1 )

code 'key', key
  call dodefer              ;allows revectoring input to come from
  dd pkey                   ;any word

;-------------------------------------------------------------------------
;output string of length n1 at a1

colon 'type', type
  dd bounds
  dd pqdo, .L1
.L0:
  dd i, cfetch, emit
  dd ploop, .L0
.L1:
  dd exit

;-------------------------------------------------------------------------
;emit a carriage return (or is it a new line :)

;       ( --- )

colon 'cr', cr
  dd plit, $0a, emit
  dd numline, dup, fetch
  dd oneplus, rows, min
  dd swap, store
  dd numout, off
  dd exit

;-------------------------------------------------------------------------
;emit a blank (a space character)

;       ( --- )

colon 'space', space
  dd plit, $20, emit        ;emit a space
  dd exit

;-------------------------------------------------------------------------
;display n1 spaces

;       ( n1 --- )

colon 'spaces', spaces
  dd plit, 0
  dd pqdo, .L1              ;from 0 to n1
.L0:                        ;do
  dd space
  dd ploop, .L0
.L1:
  dd exit

;-------------------------------------------------------------------------
;emit a backspace and adjust #out

;       ( --- )

colon '(bs)', pbs
  dd bs, emit               ;emit increments #out and we moved it <--
  dd plit, -2               ;so we must subtract 2 from it
  dd numout, plusstore
  dd exit

;-------------------------------------------------------------------------
;output n1 backspaces

;       ( n1 --- )

colon 'backspaces', backspaces
  dd numout, fetch          ;dont back up more than we have emitted on
  dd min                    ;this line
  dd plit, 0
  dd pqdo, .L1
.L0:
  dd pbs
  dd ploop,.L0
.L1:
  dd exit

;-------------------------------------------------------------------------
;output an inline string

;       ( --- )

colon '(.")', pdotq
  dd rto                    ;get address of string to display
  dd count                  ;get length of string
  dd dup2, plus, tor        ;set return address past end of string
  dd type                   ;display string
  dd exit

;-------------------------------------------------------------------------
;return address of scratchpad

;forth uses the memory at 80 bytes beyond where the dictionary
;pointer points as a scratchpad area.

;       ( --- a1 )

colon 'pad', pad
  dd here                   ;gt dictionary pointer address
  dd plit, 80, plus         ;add 80 to it
  dd exit

;-------------------------------------------------------------------------
;get address of terminal input buffer

;       ( --- a1 )

colon 'tib', tib
  dd ttib, fetch            ;fetch contents of 'tib variable
  dd exit                   ;dont you just love my comments?

;-------------------------------------------------------------------------
;process input of a backspace character

;       ( #sofar --- 0 | #sofar-1 )

colon 'bsin', bsin
  dd dup
  dd zequals, qexit
  dd oneminus               ;decrement #sofar
  dd pbs, space, pbs        ;rub out 1 char left
  dd exit

;-------------------------------------------------------------------------

;       ( max adr #sofar char --- max adr max )

colon 'cr-in', crin
  dd duptor                 ;remember # recieved chars
  dd span, store            ;set # expected to # recieved
  dd over, rto              ;return #sofar = max
  dd zequals, qexit
  dd space, exit

; ------------------------------------------------------------------------

;        ( c1 --- )

colon '^char', ctrlchar
  dd dup
  dd plit, 0ah, equals
  dd doif, .L1
  dd drop, crin
  dd exit
.L1:
  dd dothen
  dd plit, 8, notequals, qexit
  dd bsin
  dd exit

;-------------------------------------------------------------------------

;       ( adr #sofar char --- adr #sofar )

colon 'norm-char', normchar
  dd dup3                   ; ( a1 n1 c1 a1 n1 c1 --- )
  dd emit                   ;echo c1
  dd plus, cstore           ;store c1 at (a1 + n1)
  dd oneplus                ;increment #sofar
  dd exit

;-------------------------------------------------------------------------
;input n1 chars max to buffer at a1

;       ( a1 n1 -- )

colon '(expect)', pexpect
  dd dup, span, store       ;store # chars to expect in span
  dd swap, plit, 0          ; ( len adr #sofar )
.L1:
  dd dobegin
  dd pluck                  ;get diff between expected and #sofar
  dd over, minus            ; ( len adr #sofar #left )
  dd qwhile, .L2            ;while #left != 0
  dd key, dup               ;read key
  dd bl_, less              ; < hex 20 ?
  dd qcolon
  dd ctrlchar, normchar
  dd dorepeat, .L1
.L2:
  dd drop3                  ;clear working parameters off stack
  dd exit

;-------------------------------------------------------------------------

code 'expect', expect
  call dodefer
  dd pexpect

;-------------------------------------------------------------------------
;input string of 256 chars max to tib

colon 'query', query
  dd tib, plit, 256
  dd expect                 ;get 256 chars to tib
  dd span, fetch            ;get actual # chars recieved
  dd numtib, store          ;put in #in
  dd toin, off              ;we have parsed zero so far
  dd exit

;-------------------------------------------------------------------------
;if f1 is true abort with a message

;       ( f1 --- )

; this forward references abort !!! argh!!

colon '(abort")', pabortq
  dd rto, count             ;get address of abort message
  dd rot                    ;get f1 back at top of stack
  dd doif, .L0              ;is f1 true ?
  dd type, cr, abort        ;yes display message and abort

.L0:
  dd dothen
  dd plus, tor              ;nope - add string length to string address
  dd exit                   ;and put it as our return address

;-------------------------------------------------------------------------
;default input source address and char count

;       ( --- a1 n1 )

colon '(source)', psource
  dd tib                    ;get address of terminal input buff
  dd numtib, fetch          ;get char count
  dd exit

;-------------------------------------------------------------------------
;unconventional but then... this is isforth :)

code 'source', source
  call dodefer              ;block files are an after-thought
  dd psource                ;this allows me to deal with them gracefully

;-------------------------------------------------------------------------
;return the right side of the string, starting at position n1

;       ( a1 n1 n2 --- a2 n3 )

;adds n2 to a1, subtracts n2 from n1

code '/string', sstring
  sub [esp], ebx
  add [esp+4], ebx
  pop ebx
  next

;-------------------------------------------------------------------------
;return # characters as yet unparsed in tib

;       ( --- n1 )

colon 'left', left
  dd numtib, fetch          ;number of chars in tib (total)
  dd toin, fetch            ;how far we have parsed
  dd minus                  ;calculate difference
  dd exit

;-------------------------------------------------------------------------
;defered word to refill input stream

code 'refill', refill
  call dodefer
  dd query

;-------------------------------------------------------------------------

colon '?refill', qrefill
  dd left, qexit
  dd refill                 ;refill input stream
  dd exit

;-------------------------------------------------------------------------
;parse a word from input, delimited by c1

;       ( c1 --- a1 n1 )

colon 'parse', parse
  dd tor
  dd source, toin, fetch
  dd sstring, over, swap
  dd rto
  dd scan_eol, tor
  dd over, minus, dup
  dd rto, znotequals, minus
  dd toin, plusstore
  dd exit

;-------------------------------------------------------------------------
;like parse but skips leading delimiters - used by word

;       ( c1 --- a1 n1 )

colon 'parse-word', parseword
  dd tor
  dd source, tuck
  dd toin, fetch, sstring
  dd rfetch, skip
  dd over, swap
  dd rto, scan_eol
  dd tor
  dd over, minus
  dd rot, rto
  dd dup, znotequals, plus
  dd minus
  dd toin, store
  dd exit

;-------------------------------------------------------------------------
;parse string from input. refills tib if empty

;       ( c1 --- )

colon 'word', word_
  dd qrefill
  dd parseword              ; ( a1 n1 --- )
  dd hhere, strstore        ;copy string to hhere
  dd exit

;-------------------------------------------------------------------------
;is character c1 a valid digit in the current base

;       ( c1 base --- n1 true | false )

code 'digit', digit
  pop edx                   ;get base

  sub bl, '0'               ;un askify character
  jb .L2                    ;oopts - not a valid digit in any base

  cmp bl, 9                 ;greater than 9 ?
  jle .L1
  cmp bl, 17                ;make sure its not ascii $3a through $40
  jb .L2
  sub bl, 7                 ;convert a,b,c,d etc into 10,11,12,13 etc

.L1:
  cmp bl, dl                ;valid digit in current base?
  jge .L2

  push ebx                  ;yes!!!
  mov ebx, -1
  next

.L2:
  xor ebx, ebx              ;not a valid digit
  next

;-------------------------------------------------------------------------
;see if string of length n1 at addres a1 is a valid number in base

;       ( a1 n1 base --- n1 true | false )

colon '(number)', pnumber
  dd dashrot, plit, 0       ; ( base result a1 n1 -- )
  dd dashrot
  dd bounds                 ; ( base result a1 a2 --- )
  dd pdo, .L3               ;for length of string a1 do
.L1:
  dd over, i, cfetch        ; ( base result base c --- )
  dd upc, digit, nott       ; ( base result [n1 t | f] ---)
  dd doif, .L2

  dd drop3, undo            ;oopts, not a number
  dd false
  dd exit

.L2:
  dd dothen
  dd swap                   ; ( base n1 result --- )
  dd pluck, star, plus
  dd ploop, .L1             ; ( base result --- )

.L3:
  dd nip                    ;discard base
  dd true
  dd exit

;-------------------------------------------------------------------------
;see if person is entering a negative number

;       ( a1 n1 --- f1 a1' n1' )

colon '?negative', qnegative
  dd over, cfetch
  dd plit, '-'
  dd equals, dashrot
  dd pluck
  dd doif, .L0
  dd plit, 1, sstring
.L0:
  dd dothen
  dd exit

;-------------------------------------------------------------------------

;       ( f1 a1 n1 base --- n2 true | false )

;e.g.       123
;          -456

colon '(num)', pnum
  dd pnumber                ;convert string at a1 to number if can
  dd dup                    ;was it a number ?
  dd doif, .L0
  dd tor, swap, qnegate     ;yes, negate it if f1 is true
  dd rto
.L0:
  dd dothen
  dd exit

;-------------------------------------------------------------------------

;       ( f1 a1 n1 c1 --- [n2 true | false] | f1 a1 n1 )

;e.g.       $65
;          -$48

colon '?$', qhex
  dd dup, plit, '$'         ;hex number specified?
  dd equals
  dd doif, .L0
  dd rto, drop2             ;yes - discard return address and the '$'
  dd plit, 1, sstring       ;skip the $ character
  dd plit, 16               ;base for (number) is 16
  dd pnum                   ;convert number
.L0:
  dd dothen
  dd exit

;-------------------------------------------------------------------------

;       ( f1 a1 n1 c1 --- [n2 true | false] | f1 a1 n1 )

;e.g.       %1101
;          -%1001

colon '?%', qbin
  dd dup, plit, '%'         ;binary number specified ?
  dd equals
  dd doif, .L0
  dd rto, drop2
  dd plit, 1, sstring
  dd plit, 2                ;yes, base is 2
  dd pnum
.L0:
  dd dothen
  dd exit

;-------------------------------------------------------------------------

;       ( f1 a1 n1 c1 --- [n2 true | false] | f1 a1 n1 )

;e.g.       \023
;          -\034

colon '?\', qoctal
  dd dup, plit, '\'         ;octal specified ? (ugh)
  dd equals                 ;allows c like \036 etc
  dd doif, .L0
  dd rto, drop2
  dd plit, 1, sstring
  dd plit, 8                ;yes, base is 8
  dd pnum
.L0:
  dd dothen
  dd exit

;-------------------------------------------------------------------------

;       ( f1 a1 n1 c1 --- [n2 true | false] | f1 a1 n1 )

;e.g.       'x'
;          -'y'

colon "?'", qchar
  dd plit, $27              ;char specified ?
  dd equals, nott, qexit

  dd rto, drop2             ;discard return address and n1
  dd dup, twoplus, cfetch   ;must have closing ` on char
  dd plit, $27              ;i.e. 'x' not the shitty looking 'x
  dd equals
  dd doif, .L1

  dd oneplus                ;yes, point at char
  dd cfetch
  dd swap, qnegate
  dd true
  dd exit

.L1:
  dd dothen
  dd drop2, false
  dd exit

;-------------------------------------------------------------------------
;convert string at a1 to a number in current base (if can)

;       ( a1 --- n1 true | false )

colon 'number', number
  dd count                  ; ( a1+1 n1 --- )
  dd qnegative              ;is first char of # a '-' ?
  dd over, cfetch           ;get next char of string...

  ;if any of the next 4 tests passes it is an implied exit from this word

  dd qhex                   ;is it a $number ?
  dd qbin                   ;is it a %number ?
  dd qoctal                 ;is it a \number ?
  dd qchar                  ;is it a 'x' number

  dd base, fetch            ;none of the above - use current base
  dd pnum                   ;and try convert number
  dd exit

;=========================================================================
