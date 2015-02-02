;reloc.1        - isforth head space relocation words
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------

rethread:
  push esi
  mov esi, [voclink+5]      ;point to first vocabulary
.L0:
  mov ecx, 64               ;number of threads in vocabulary
.L1:
  cmp edx, [esi]            ;is start of this thread the header we just 
  jne .L2                   ;  relocated?
  mov [esi], ebp            ;yes - point thread at headers new address
.L2:
  add esi, byte 4           ;point to next thread
  loop .L1
  mov esi, [esi]            ;link back to next vocabulary
  cmp esi, 0                ;no more vocabs ?
  jne .L0
  pop esi
  ret

;-------------------------------------------------------------------------

hreloc:
  mov eax, [esi]            ;get soruce link field
  cmp eax, 0                ;start of thread ?
  jz .L0
  mov eax, [eax-4]
.L0:
  stosd                     ;save link in destination
  mov [esi], edi            ;save where this header gets relocated to
  add esi, byte 4
  mov ebp, edi              ;and destination nfa too
  mov edx, esi              ;remember source nfa hdr we just relocated
  movzx ecx, byte [esi]
  mov eax, ecx
  and ecx, $1f
  inc ecx
  rep movsb                 ;relocate nfa
  and eax, $20              ;is this an alias ?
  jnz .L2
  mov eax, [esi]            ;get cfa of this word
  mov [eax-4], ebp          ;point cfa-4 at new header location
.L2:
  movsd                     ;relocate cfa pointer
  ret

;-------------------------------------------------------------------------
;relocate all headers to address edi

relocate:
  call hreloc               ;relocate one header
  call rethread             ;check all threads of all vocabs for relocated
  cmp edx, ebx              ;finished ?
  jne relocate    
  ret

;-------------------------------------------------------------------------
;relocate all headers to allocated head space

unpack:
  push ebp
  mov eax, [turnkeyd+5]     ;are there any headers to relocate ?
  or eax, eax
  jnz .L0

  mov esi, [dp+5]           ;get address of end of list space
  mov edi, [hp+5]           ;where to relocate to
  mov ebx, [lhead]          ;address of last header defined

  call relocate

  mov [lhead], ebp          ;save address of highest header in memory
  mov [hp+5], edi           ;correct h-here

.L0:
  pop ebp
  ret

;-------------------------------------------------------------------------
;relocate all headers to here. point here at end of packed headers

code 'pack', pack
  push ebx                  ;retain cached top of stack
  push esi                  ;and interprative pointer
  push ebp
  mov esi, [bhead+5]        ;point to start of head space
  mov edi, [dp+5]           ;point to reloc destination
; add edi, $3ff             ;align to page
; and edi, -$400
  mov ebx, [last+5]
  call relocate             ;relocate all headers
  mov [hp+5], edi
  mov [lhead], ebp
  pop ebp
  pop esi
  pop ebx
  next

;=========================================================================
