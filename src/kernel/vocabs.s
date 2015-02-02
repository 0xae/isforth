;vocabs.s     - isforth vocabulary creating words etc
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
;make nasm chain words on root vocabulary

  _root_

;-------------------------------------------------------------------------
;remembers most recently defined vocabulary

  _variable_ 'voclink', voclink, root+5

;-------------------------------------------------------------------------

  _constant_ '#threads', numthread, 64
  _variable_ 'current', current, forth+5
  _constant_ 'context', context, context0+5
  _constant_ '#context', numcontext, 3
  _constant_ 'contexts', contexts, 0

;-------------------------------------------------------------------------
;the context stack - the search order

;enough space to have 16 vocabularies in the search order
;i.e. overkill

code 'context0', context0
  call dovariable
  dd root+5
  dd compiler+5
  dd forth+5                ;top of context stack
  dd 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0

;-------------------------------------------------------------------------

code 'constack', cstack
  call dovariable
  dd 0, 0, 0
  dd 0, 0, 0
  dd 0, 0, 0
  dd 0, 0, 0
  dd 0, 0, 0

;-------------------------------------------------------------------------
;run time for vocabularies

;push specified vocabulary onto context stack or rotate it out to top
;if its already in there

;       ( a1 --- )

code 'dovoc', dovoc
  mov edi, [context+5]      ;get address of current context stack
  mov ecx, [numcontext+5]   ;get context stack depth
  pop eax

  repnz scasd               ;is vocabulary already in context?
  jne .L1
  jecxz .L2

;already in context - rotate it out to top of stack

  sub edi, byte 4           ;point back at found vocab

.L0:
  mov edx, [edi+4]          ;shift each voc down 1 pos in stack
  mov [edi], edx
  add edi, byte 4
  dec ecx
  jne .L0
  mov [edi], eax            ;put vocab a1 at top of context stack
  next

.L1:
  inc dword [numcontext+5]  ;no - increment depth
  stosd                     ;add vocabulary to context
.L2:
  next

;-------------------------------------------------------------------------
;create a new vocabulary

colon 'vocabulary', vocabulary
  dd current, fetch         ;remember where definitions are being linked
  dd plit, root+5           ;all vocabs created into root
  dd current, store
  dd create, suses, dovoc   ;create header, make voc use dovoc
  dd here, dup              ;create vocabulary thread array
  dd plit, 256, dup
  dd allot, erase
  dd voclink, fetch, comma  ;link new voc to previous one
  dd voclink, store         ;remember most recent vocabulary
  dd current, store         ;restore current
  dd exit

;-------------------------------------------------------------------------
;make all new definitions go into first vocab in search order

colon 'definitions', definitions
  dd context, numcontext    ;get address of top of context stack
  dd oneminus, cells, plus  ;point to top item of context stack
  dd current, dmove         ;like context @ current ! but different
  dd exit

;-------------------------------------------------------------------------
;drop top item of context stack

code 'previous', previous
  mov edi, [context+5]
  mov eax, [numcontext+5]
  dec dword [numcontext+5]
  shl eax, 2
  add edi, eax
  xor eax, eax
  mov [edi], eax
  next

;-------------------------------------------------------------------------
;this definition will disappear when im metacompiling
;all the rehash words will...

code 'rehash', rehash
  call dodefer
  dd _rehash

;-------------------------------------------------------------------------

code 'forth', forth
  call dovoc
  dd forth_link
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0
  dd 0                      ;null link

;-------------------------------------------------------------------------

code 'compiler', compiler
  call dovoc
  dd comp_link, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd forth+5                 ;link to forth vocabulary

;-------------------------------------------------------------------------

code 'root', root
  call dovoc
  dd vlink, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd 0, 0, 0, 0, 0, 0, 0, 0
  dd compiler+5              ;link to compiler vocabulary

;-------------------------------------------------------------------------

lhead:
 dd vlink

;-------------------------------------------------------------------------
;link header at esi into vocabulary at edi

link:
  mov bh, [esi]             ;get nfa hash
  and bh, 01fh
  mov bl, [esi+1]
  add bl, bl
  cmp bh, 1
  je .L1
  add bl, [esi+2]           ;add second char to total
  add bl, bl                ;*2

.L1:
  add bl, bh                ;add nfa length to hash
  and ebx, 03fh             ;there are 64 threads per vocabulary

  shl ebx, 2                ;and 4 bytes per thread entry
  add ebx, edi              ;point ebx at thread to link into

  mov eax, [ebx]            ;get header currently at end of this thread
  mov [ebx], esi            ;put new header at end of this thread
  mov [esi-4], eax          ;link new end to old end
  ret

;-------------------------------------------------------------------------
;hashify one vocabulary pointed to by edi

hashvoc:
  xor ecx, ecx              ;number of words in thread 0
  mov esi, [edi]            ;point esi at end of vocabularies thread 0

;nasm chained all words onto the first thread.

.L0:
  push esi                  ;save address of header to rehash
  inc ecx                   ;keep count
  mov esi, [esi-4]          ;scan back to previous word in thread
  or esi, esi               ;found the end of the chain ?
  jnz .L0

;reached end of thread zero. nfa's of all words in this thread are now
;on the stack and ecx it the total thereof

.L1:
  mov dword [edi], 0        ;erase first chain of vocabulary
.L2:
  pop esi                   ;get nfa of header to hash
  call link                 ;link it to one of the threads
  dec ecx                   ;count down
  jne .L2                   ;and...
  ret

;-------------------------------------------------------------------------

_rehash:
  mov eax, noop             ;neuter this word so it can never be run
  mov dword [rehash+5], eax ; again
  mov eax, _hash            ;make create and find actually do hashing
  mov dword [hash+5], eax

  push esi                  ;save ip
  push ebx                  ;save top of parameter stack
  mov edi, dword [voclink+5] ;edi points to first vocabulary to rehash

.L0:
  call hashvoc              ;hashify one vocabulary
  mov edi, dword [edi+256]  ;get address of next vocabulary
  or edi, edi               ;end of vocabulary chain ?
  jnz .L0

  pop ebx                   ;yes... restore top of stack and ip
  pop esi
  next

;=========================================================================















