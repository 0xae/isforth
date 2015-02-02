;memory.i       - isforth memory access words (fetch and store etc)
;-------------------------------------------------------------------------

  _variable_ '?caps', qcaps, 0  ;true makes find and comp case in-sensative

;-------------------------------------------------------------------------

  _constant_ 'cell', cell, 4

;-------------------------------------------------------------------------

code 'cell+', cellplus
  add ebx, byte 4
  next

;-------------------------------------------------------------------------

code 'cell-', cellminus
  sub ebx, byte 4
  next

;-------------------------------------------------------------------------

code 'cells', cells
  shl ebx, byte 2
  next

;-------------------------------------------------------------------------

code 'cell/', cellslash
  shr ebx, byte 2
  next

;-------------------------------------------------------------------------
;compute address of indexted cell in array

;       ( a1 ix --- a2 )

code '[]+', cellsplus
  pop eax                   ;get a1
  shl ebx, byte 2           ;convert ix to cell offset
  add ebx, eax              ;add address to offset
  next

;-------------------------------------------------------------------------
;fetch indexed cell of array

;       ( a1 ix --- n2 )

code '[]@', cellplusfetch
  pop eax                   ;get a1
  shl ebx, byte 2           ;convert index n1 into cell offset
  add ebx, eax              ;add address to offset
  mov ebx, [ebx]            ;fetch data
  next

;-------------------------------------------------------------------------
;store data at indexed cell of array

;       ( n1 a1 ix --- )

code '[]!', cellplusstore
  pop eax                   ;get address
  shl ebx, byte 2           ;convert index into cell offset
  add ebx, eax              ;add address to offset
  pop dword [ebx]           ;store n1 at address
  pop ebx                   ;pop new cached top of stack
  next

;-------------------------------------------------------------------------

;when you type bl word ... parse-word will scan the next token out of
;the input buffer up to the specified delimiting character (the blank) but
;it will also delimit on either a tab or an end of line.  In the case of
;delimiting on an end of line we have a minor issue we need to deal with..
;
;if the word we just parsed in is the \ line comment word then the next
;line of the sorce file will be treated as a comment (\ parses to the
;next eol which in this case is the end of the line immediatly following)

  _constant_ 'wchar', wchar, 0  ;actual char that word delimited on

;-------------------------------------------------------------------------
;fetch data from address (fetches 32 bits)

;       ( a1 --- n1 )

code '@', fetch
  mov ebx, dword [ebx]
  next

;-------------------------------------------------------------------------
;store data at adderss

;       ( n1 a1 --- )

code '!', store
  pop dword [ebx]
  pop ebx
  next

;-------------------------------------------------------------------------
;fetch character from address a1

;       ( a1 --- c1 )

code 'c@', cfetch
  movzx ebx, byte [ebx]     ;get character
  next

;-------------------------------------------------------------------------
;store character c1 at address a1

;       ( c1 a1 --- )

code 'c!', cstore
  pop eax                   ;get c1
  mov byte [ebx], al        ;store at a1
  pop ebx
  next

;-------------------------------------------------------------------------
;fetch word from address a1

;       ( a1 --- w1 )

code 'w@', wfetch
  movzx ebx, word [ebx]
  next

;-------------------------------------------------------------------------
;store word w1 at address a1

;       ( w1 a1 --- )

code 'w!', wstore
  pop eax
  mov [ebx], ax
  pop ebx
  next

;-------------------------------------------------------------------------
;swap contents of two memory cells

code 'juggle', juggle
  pop eax
  mov ecx, dword [eax]
  mov edx, dword [ebx]
  mov dword [ebx], ecx
  mov dword [eax], edx
  pop ebx
  next

;-------------------------------------------------------------------------
;convert a counted string to an address and count

;       ( a1 --- a2 n1 )

code 'count', count
  movzx ecx, byte [ebx]     ;get length byte from string
  inc ebx                   ;advance address past count byte
  push ebx                  ;return address and length
  mov ebx, ecx
  next

;-------------------------------------------------------------------------
; like count but fetches 32 bit item and advances address by 4

code 'dcount', dcount
  mov ecx, [ebx]
  add ebx, byte 4
  push ebx
  mov ebx, ecx
  next

;-------------------------------------------------------------------------
;move contents of address a1 to address a2

;           ( a1 a2 --- )

code 'dmove', dmove
  pop eax                    ;get a1
  mov eax, [eax]             ;get contents thereof
  mov [ebx], eax             ;store it at a2
  pop ebx                    ;cache tos
  next

;-------------------------------------------------------------------------
;get length of asciiz string

;       ( a1 --- a1 n1 )

colon 'strlen', strlen
  dd plit, 0                ;resultant length
.L0:
  dd dobegin
  dd dup2, plus, cfetch
  dd qwhile, .L1
  dd oneplus
  dd dorepeat,.L0
.L1:
  dd exit

;-------------------------------------------------------------------------
;set bits of data at specified address

;       ( n1 a1 --- )

code 'cset', cset
  pop eax                   ;get mask
  or [ebx], eax
  pop ebx
  next

;-------------------------------------------------------------------------
;clear bits of data at specified address

;       ( n1 a1 --- )

code 'cclr', cclr
  pop eax                   ;get mask
  not eax                   ;invert it
  and [ebx], eax            ;mask out selected bits
  pop ebx
  next

;-------------------------------------------------------------------------
;set data at address to true

;       ( a1 --- )

code 'on', on
  mov dword [ebx], -1       ;store a true flag at address
  pop ebx
  next

;-------------------------------------------------------------------------
;set data at address to false

;       ( a1 --- )

code 'off', off
  mov dword [ebx], 0        ;store false flag at address
  pop ebx
  next

;-------------------------------------------------------------------------
;increment data at specified address

;       ( a1 --- )

code 'incr', incr
  inc dword [ebx]           ;increment value at that address
  pop ebx
  next

;-------------------------------------------------------------------------
;decrement data at specified address

;       ( a1 --- )

code 'decr', decr
  dec dword [ebx]           ;decrement data
  pop ebx
  next

;-------------------------------------------------------------------------
;decrement data at specified address but don't decrement throught zero

;       ( a1 --- )

code '0decr', zdecr
  mov eax, [ebx]            ;read current value
  jz .L0                    ;if it is already 0 then exit
  dec dword [ebx]           ;else decrement the data
.L0:
  pop ebx
  next

;-------------------------------------------------------------------------
;add n1 to data at a1

;       ( n1 a1 --- )

code '+!', plusstore
  pop eax                   ;get data
  add dword [ebx], eax      ;add data to address
  pop ebx
  next

;-------------------------------------------------------------------------
;add w1 to data at a1

;       ( w1 a1 --- )

code 'w+!', wplusstore
  pop eax                   ;get data
  add word [ebx], ax        ;add data to address
  pop ebx
  next

;-------------------------------------------------------------------------

;       ( src dst len --- )

code 'cmove', cmove_
  mov ecx, ebx              ;get # bytes to move
  pop edi                   ;get destination address
  mov edx, esi              ;save ip
  pop esi                   ;get source address
  shr ecx, 2
  rep movsd
  mov ecx, ebx
  and ecx, 3

  rep movsb

.L0:
  mov esi, edx              ;restore
  pop ebx
  next

;-------------------------------------------------------------------------
;as above but starting at end of buffers and moving downwards in mem

;       ( a1 a2 n1 --- )

code 'cmove>', cmoveto
  mov ecx, ebx              ;get byte count in ecx
  pop edi                   ;get destination address
  mov edx, esi              ;save ip
  pop esi                   ;get source address
  jecxz .L1

  add edi, ecx              ;point to end of source and destination
  add esi, ecx
  dec edi
  dec esi

  std                       ;moving backwards
  rep movsb                 ;move data
  cld                       ;restore default direction

.L1:
  mov esi, edx              ;restore ip
  pop ebx
  next

;-------------------------------------------------------------------------
;fill block of memory with character

;       ( a1 n1 c1 --- )

code 'fill', fill
  mov eax, ebx              ;get fill char
  pop ecx                   ;fill count
  pop edi                   ;fill address

.L0:
  jecxz .L1

  rep stosb

.L1:
  pop ebx
  next

;-------------------------------------------------------------------------
;fill block of memory with words

;       ( a1 n1 w1 --- )

code 'wfill', wfill
  mov eax, ebx              ;get fil data in ax
  pop ecx                   ;count
  pop edi
  jecxz fill.L1
  rep stosw
  pop ebx
  next

;-------------------------------------------------------------------------
;fill memory with double words (32 bits)

;       ( a1 n1 d1 --- )

code 'dfill', dfill
  mov eax, ebx
  pop ecx
  pop edi
  jecxz fill.L1
  rep stosd
  pop ebx
  next

;-------------------------------------------------------------------------
;fill block of memory with spaces

;       ( a1 n1 --- )

code 'blank', blank
  mov al,' '
.L0:
  mov ecx, ebx
  pop edi
  jmp short fill.L0

;-------------------------------------------------------------------------
;fill block of memory with nulls

;       ( a1 n1 --- )

code 'erase', erase
  xor al,al
  jmp short blank.L0

;-------------------------------------------------------------------------
;ascii upper case translation table

atbl:
  db  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15
  db 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
  db '!"#$%&', "'"
  db '()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`ABCDEFG'
  db 'HIJKLMNOPQRSTUVWXYZ{|}~', 127

;-------------------------------------------------------------------------
;convert a single character to upper case.

;       ( c1 --- c2 )

code 'upc', upc
  mov eax, atbl
  and ebx, 07fh
  xchg eax, ebx
  xlatb
  mov ebx, eax
  next

;-------------------------------------------------------------------------
;convert a string to upper case. (isforth uses all lower case!!!)

;       ( a1 n1 --- )

;anyone who codes in all upper case (or mixed case) is one beer short
;of a six pack (make mine a jd :)

;code 'upper', upper
; pop ecx                    ;get address of string
; test ebx, ebx              ;string of length zero ?
; jz .L2
;
; xchg ebx, ecx              ;length in ecx
; mov edi, ebx               ;address in edi
; mov ebx, atbl
;.L1:
; mov al, [edi]              ;get one char
; and al, 07fh
; xlatb
; mov [edi], al              ;store upper cased char back in string
; inc edi
; dec ecx
; jne .L1
;
;.L2:
; pop ebx
; next

;ill add that back if anyone realy wants it
;but i think it belongs in : def realy

;-------------------------------------------------------------------------
;compare 2 strings. returns -1 if they match, 0 if not.

;       ( a1 a2 n1 --- f1 )

;todo - fix this to return -1 0 or 1 depending on result

code '(comp)', pcomp
  mov ecx, ebx              ;get string length
  pop edi                   ;get addresses of strings
  pop edx
  jecxz .L2                 ;n1 is zero? skip this..
  xchg edx, esi
  repz cmpsb                ;comp strings
  jz .L1                    ;ecx=0
  xor ecx, ecx
  dec ecx                   ;ecx=-1
.L1:
  not ecx                   ;flip
  mov esi, edx
.L2:
  mov ebx, ecx
  next

;-------------------------------------------------------------------------
;case insensative string compare

; ive not tested/debugged this, ill do that later (or you can :)

;       ( a1 a2 n1 --- f1 )

code '(ncomp)', pncomp
  mov ecx, ebx
  pop edi
  pop edx
  xchg edx, esi
  jecxz .L2
  mov ebx, atbl
.L0:
  mov ah, [esi]
  mov al, [edi]
  inc esi
  inc edi
  and ax, 07f7fh
  xlat
  xchg ah, al
  xlat
  xchg ah,al
  cmp ah, al
  jne .L1
  dec ecx
  jnz .L0
  je .L2
.L1:
  mov ecx, -1
  jl .L2
  mov ecx, 1
.L2:
  mov ebx, ecx
  mov esi, edx
  next

;-------------------------------------------------------------------------
;do case (in)sensative compare of 2 strings

;       ( a1 a2 n1 --- f1 )

colon 'comp', comp
  dd qcaps, fetch
  dd qcolon
  dd pncomp, pcomp
  dd exit

;-------------------------------------------------------------------------
;skip leading characters equal to c1 within a string

;       ( a1 n1 c1 --- a2 n2 )

code 'skip', skip
  pop ecx                   ;get length
  jecxz .L1

  pop edi
  mov eax, ebx              ;get c1 in al

  rep scasb                 ;scan string till no match
  jz .L0                    ;run out of string ?

  inc ecx                   ;jump back into string
  dec edi

.L0:
  push edi                  ;return a2

.L1:
  mov ebx, ecx              ;return n2
  next

;-------------------------------------------------------------------------
;scan string for character c1

;       ( a1 n1 c1 --- a2 n2 )

;       a2 = address where c1 was found (end of string if not found)
;       n2 = length from a2 to end of string

;i think n2 is a totally useless value to return. it would be much more
;usefull if this returned the length of the a2 string instead. it would
;simplify parse no end. - mental note - make this return sane values ?
;this would break code that expects n2 to be standard... (who cares?)

code 'scan', scan
  pop ecx                   ;get length of string in ecx (n1)
  jecxz .L2                 ;null string ?
  pop edi                   ;address of string in edi (a1)
  mov eax, ebx              ;get item to search for in eax (c1)
  repnz scasb               ;search string for char
  jnz .L1                   ;run out of string ? or find item ?
  inc ecx                   ;point back at located item
  dec edi
.L1:
  push edi                  ;return a2
.L2:
  mov ebx, ecx              ;return n2
  next

;------------------------------------------------------------------------
;scan memory for 16 bit item n2

;       ( a1 n1 w1 --- a2 n2 )

code 'wscan', wscan
  pop ecx                   ;get length of buffer to search (n1)
  jecxz .L2                 ;null string ?
  pop edi                   ;get address of memory to search (a1)
  mov eax, ebx              ;get item to search for in eax (w1)
  repnz scasw               ;search...
  jnz .L1
  inc ecx
  sub edi, byte 2
.L1:
  push edi
.L2:
  mov ebx, ecx
  next

;-------------------------------------------------------------------------
;scan memory for 32 bit item

;       ( a1 n1 n2 --- a2 n2 )

code 'dscan', dscan
  pop ecx                   ;get length of buffer to search (n1)
  jecxz .L2                 ;null string ?
  pop edi                   ;get addess of memory to search (a1)
  mov eax, ebx              ;get item to search for in eax (n2)
  repnz scasd               ;search...
  jnz .L1
  inc ecx
  sub edi, byte 4
.L1:
  push edi
.L2:
  mov ebx, ecx
  next

;-------------------------------------------------------------------------
;as above but also delimits on eol

;this word is used by parse-word now instead of the above so that we can
;consider an entire memory mapped source file to be our terminal input
;buffer.

;       ( a1 n1 c1 --- a2 n2 )

code 'scan-eol', scan_eol
  pop ecx                   ;get length of string to scan
  jecxz .L3                 ;empty string ?
  pop edi                   ;no, get address of string

.L0:
  mov al, [edi]             ;get next byte of string

  cmp al, $0a               ;end of line ?
  je .L2
  cmp al, $0d
  je .L2

  cmp al, bl                ;not eol, same as char c1 ?
  je .L2

  cmp bl, $20               ;if were scanning for blanks then
  jne .L1                   ;also delimit on the evil tab
  cmp al, 9                 ;the evil tab is a blank too
  je .L2                    ;DONT USE TABS!

.L1:
  inc edi
  dec ecx
  jnz .L0                   ;ran out of string?

  xor al, al                ;we didnt delimit, we ran out of string

.L2:
  push edi

.L3:
  mov [wchar+5], al         ;remember char that we delimited on

  mov ebx, ecx
  next

;-------------------------------------------------------------------------
;convert string from counted to asciiz - useful for os calls

;       ( a1 n1 --- a1 )

colon 's>z', s2z
  dd over, plus, plit, 0
  dd swap, cstore
  dd exit

;-------------------------------------------------------------------------
;store string a1 of length n1 at address a2 as a counted string

;       ( a1 n1 a2 -- )

colon '$!', strstore
  dd dup2, cstore, oneplus
  dd swap, cmove_
  dd exit

;-------------------------------------------------------------------------
;tag counted string a1 onto end of counted string a2

;combined length should not be more than 255 bytes.
; this is not checked

;     ( a1 n1 a2 --- )

colon '$+', strplus
  dd duptor                 ;remember address of destination string
  dd count, duptor, plus    ;save current length, get address of end
  dd dashrot, tor
  dd swap, rfetch, cmove_
  dd rto2, plus
  dd rto, cstore, exit

;-------------------------------------------------------------------------
;scan for terminatig zero byte

;       ( a1 --- a2 )

code 'scanz', scanz         ;bug fix modifications by stephen ma
  xor eax,eax               ;we're looking for binary zero.
  mov edi,ebx               ;edi = string address
  lea ecx,[eax-1]           ;ecx = -1 (effectively infinite byte count)
  repne scasb               ;scan for zero byte.
  lea ebx,[edi-1]           ;return the address of the null byte.
  next

;=========================================================================
