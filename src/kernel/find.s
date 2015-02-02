;find.s   - isforth dictionary searches
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
;chain words on compiler vocabulary

 _compiler_

;-------------------------------------------------------------------------
;calculate hash value (thread number) for counted string at a1

;       ( a1 --- thread )

  _noname_

_hash:
  mov ax, [ebx]             ;get count byte and first char of name
  and al, 01fh              ;mask out lex bits
  add ah, ah                ;double char 1
  cmp al, 1                 ;only 1 char in name ?
  je .L1
  add ah, [ebx+2]           ;add second char
  add ah, ah                ;and double again
.L1:
  add al, ah                ;add to length byte
  and eax, 03fh             ;64 threads per vocabulary
  mov ebx, eax
  shl ebx, 2                ;4 bytes per thread
  next

;-------------------------------------------------------------------------
;bogus hash always equates to thread zero

;this will disappear when i disappear rehash

;       ( a1 --- 0 )

nohash:
  xor ebx, ebx
  next

;-------------------------------------------------------------------------
;revectored to _hash by rehash

code 'hash', hash
  call dodefer              ;once the vocs have been properly hashed
  dd nohash                 ;this will be vectored to _hash

;-------------------------------------------------------------------------
;search one dictionary thread for specified word (at hhere)

;   ( thread --- cfa f1 | false )

;   f1: 1 if immediate, -1 otherwise

code '(find)', pfind
  or ebx, ebx               ;empty thread?
  jz .L5                    ;if so get out now

  push esi                  ;save forths ip, we need this register
  mov edi, [hp+5]           ;point to string to search for
  movzx ecx, byte [edi]     ;get string length
  inc edi                   ;point to string

.L0:                        ;main loop of search
  mov al, [ebx]             ;get count byte from dictionary entry
  and al, $1f               ;mask out lex bits
  cmp al, cl                ;lengths match ?
  je .L2

.L1:                        ;not a match
  mov ebx, [ebx-4]          ;scan back to next word in dictionary
  or ebx, ebx               ;end of chain?
  jne .L0
  pop esi                   ;restore ip
  next

.L2:                        ;length bytes match...
  push edi                  ;keep copy of string address
  push ecx                  ;and length

  mov esi, ebx              ;point esi at dictionary entry
  inc esi                   ;skip count byte

  cmp dword [qcaps+5], 0    ;ignore case ?
  jz .L3

  call .L6                  ;compare strings ignoring case
  jmp short .L4

.L3:
  repe cmpsb                ;compare strings

.L4:
  pop ecx                   ;retrieve length and address of string
  pop edi
  jne .L1                   ;was the above a match ?

  pop esi                   ;match found!
  push dword [ebx+ecx+1]    ;return cfa of word that matched

  movzx eax, byte [ebx]     ;get count byte of matched word
  mov ebx, 1                ;assume word is immediate
  test eax, $40             ;is it ?
  jne .L5
  neg ebx                   ;no

.L5:
  next

.L6:
  mov al, [esi]             ;get char of string 1
  mov ah, [edi]             ;get char of string 2
  and eax, $7f7f            ;mask chars $80 to $ff to $00 to $7f
  push ebx                  ;done eat ebx
  mov ebx, atbl             ;point to ascii uppercase xlat tbl
  xlat                      ;translate both chars to
  xchg ah, al
  xlat
  pop ebx
  cmp ah, al                ;are chars equal ?
  jne .L7
  inc esi
  inc edi
  dec ecx
  jne .L6
.L7:
  ret

;-------------------------------------------------------------------------
;search all vocabularies that are in context for word name at hhere

;    ( --- cfa f1 | false )

colon 'find', find
  dd context, numcontext    ;get address and depth of context stack
  dd dofor                  ; start of a for/nxt loop
.L0:
  dd dup, rfetch
  dd cellplusfetch          ;star4, plus, fetch
  dd hhere, hash            ;get hash of name to look for
  dd plus, fetch            ;index to thread[hash]

  dd pfind, qdup            ;get thread end word address and search thread
  dd doif, .L1              ;did we find it ?
  dd rdrop, rot, drop       ;yes: discard context stack address
  dd exit

.L1:
  dd dothen
  dd pnxt, .L0

  dd drop, false            ;word does not exist (or is out of context)
  dd exit

;-------------------------------------------------------------------------
;abort if f1 is true (used after a find :)

;       ( f1 --- )

colon '?missing', qmissing
  dd nott, qexit            ;is word specified defined?
  dd hhere, count           ;display name of unknown word
  dd space, type
  dd true, pabortq
  db 2,' ?'
  dd exit

;-------------------------------------------------------------------------
;parse input stream and see if word is defined anywhere in search order

colon 'defined', defined
  dd bl_, word_             ;parse space delimited string from input
  dd find                   ;search dictionary for a word of this name
  dd exit

;-------------------------------------------------------------------------
;find cfa of word specified in input stream

colon "'", tick             ;grrr i hate using double quotes!
  dd defined, zequals       ;is next word in input stream defined ?
  dd qmissing               ;if not then abort
  dd exit

;=========================================================================
