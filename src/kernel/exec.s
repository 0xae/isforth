;exec.1         - isforth execution and interpretation words
;-------------------------------------------------------------------------

;------------------------------------------------------------------------
;belongs in src/ext/struct.f

code '(db)', pbf
  pop eax
  add ebx, [eax]
  next

;-------------------------------------------------------------------------
;execute next word within a high level definition

;       ( --- )

code '_next', _next
  lodsd                     ;get address of word to execute from
  jmp eax                   ; current definition and execute it
  nop                       ;makes above exactly 4 bytes (patchable cell)

;-------------------------------------------------------------------------
;debuggers next..

  mov eax, $90e0ffad        ;restore next so debugger doesnt try to
  mov [_next], eax          ; debug itself

  push ebx                  ;save applications top of stack

  mov eax, esp              ;save applications esp
  mov esp, dword [sv]       ;restore debuggers esp

  pop ecx                   ;fetch debuggers rp
  pop edx                   ;fetch debuggers ip

  push eax                  ;push apps esp to debuggers pstack
  push ebp                  ;push apps rp to debuggers pstack
  mov ebx, esi              ;push apps ip to debuggers pstack

  mov esi, edx              ;set debuggers ip
  mov ebp, ecx              ;set debuggers rp

.L0:
  lodsd                     ;jump back into debugger
  jmp eax

;-------------------------------------------------------------------------

sv:    dd 0

;-------------------------------------------------------------------------
;debugger steps next xt of application code

code 'bnext', bnext      ; ( a1 a2 a3 --- )
  pop ecx                   ;fetch apps rp
  pop edx                   ;fetch apps ip

  push esi                  ;debug ip
  push ebp                  ;debug rp
  mov [sv], esp             ;debug sp

  mov esp, ebx              ;set application context
  mov ebp, ecx
  mov esi, edx
  pop ebx                   ;cache top of application stack in ebp

  mov eax, $90909090        ;obliterate code at _next with nops
  mov [_next], eax

  lodsd                     ;run apps next xt
  jmp eax

;-------------------------------------------------------------------------
;interpret does> part of a word (within word that defined it)

;       ( a1 a2 --- a1 )

;the above stack comment is actually incorrect because we are caching the
;top of stack item in ebx and a1 and a2 are actually on the stack itself

code 'dodoes', dodoes
  xchg ebp, esp             ;save current ip to return stack
  push esi
  xchg ebp, esp
  pop esi                   ;get address of word type interpreter
  xchg ebx, [esp]           ;put address of word body in ebx
  next

;-------------------------------------------------------------------------
;nest into a high level definition - called by : definition

;       ( a1 --- )

;the above stack comment is actually incorrect because we are caching the
;top of stack item in ebx and a1 is actually on the stack itself

code 'nest', nest
  xchg ebp, esp
  push esi
  xchg ebp, esp
  pop esi                   ;get new ip and interpret from here
  next

;-------------------------------------------------------------------------
;exit from current high level definition

;       ( --- )

code 'exit', exit
  mov esi, [ebp]            ;get return address from return stack into ip
  add ebp, byte 4
.L0:
  next

;-------------------------------------------------------------------------
;conditionally exit high level definition

;       ( f1 --- )

code '?exit', qexit
  or ebx, ebx               ;test f1
  pop ebx                   ;cache new tos (test result retained in psw)
  jz exit.L0                ;0 = false, non 0 = not false, -1 = true :)
  jmp exit

;-------------------------------------------------------------------------

;       ( --- )

code 'goto', goto
  lodsd
  mov esi, [ebp]            ;get return address from return stack into ip
  add ebp, byte 4
  jmp eax

;-------------------------------------------------------------------------
;kinda like a case blah blah blah but so much better

;vector to the n1th word in the list following exec:

;this word is an implied unnest from any word using it

;       ( n1 --- )

code 'exec:', execc
  mov eax,[esi+4*ebx]       ;get vector to n1th word following exec:
  pop ebx                   ;cache top of stack
  mov esi, [ebp]            ;unnest now - makes exec: an implied exit
  add ebp, byte 4           ; from any word using it
  jmp eax

;-------------------------------------------------------------------------
;alternate for if dotrue else dofalse then

;       ( f1 --- )

code '?:', qcolon
  sub ebx, byte 1           ;ebx 0= ?
  sbb ebx, ebx
  and ebx, byte 1           ;ebx was true/false ebx now = 0/1

  mov eax, [esi+4*ebx]      ;get vector to do-true or do-false
  pop ebx
  add esi, byte 8           ;point esi beyond vectors
  jmp eax                   ;execute true word or false word

;-------------------------------------------------------------------------
;execution time code for all constant (and var) definitions.

;       ( a1 --- n1 )

;the above stack comment is actually incorrect because we are caching the
;top of stack item in ebx and a1 is actually on the stack itself

code 'doconstant', doconstant
  xchg ebx, [esp]           ;flush cached tos, get a1
  mov ebx, [ebx]            ;get value of constant (or var) from body
  next

;-------------------------------------------------------------------------
;execution time code for all variable definitions

;       ( a1 --- a1 )

;the above stack comment is actually incorrect because we are caching the
;top of stack item in ebx and a1 is actually on the stack itself

code 'dovariable', dovariable
  xchg ebx, [esp]           ;flush tos cache, cache a1
  next

;-------------------------------------------------------------------------
;cfa of defered word calls here

;       ( a1 --- )

;the above stack comment is actually incorrect because we are caching the
;top of stack item in ebx and a1 is actually on the stack itself

code 'dodefer', dodefer
  pop eax                   ;get defered word execution vector
  jmp [eax]                 ;execute defered word

;-------------------------------------------------------------------------
;no operation

;this word is usually used to neuter defered words. (' noop is foo)
;i also use it to put a breakpoints in : defs in gdb :)

;       ( --- )

code 'noop', noop           ;no operation
  next

;-------------------------------------------------------------------------
;a patchable noop - usually used to do multi tasking

;       ( --- )

code 'pause', pause_
  call dodefer
  dd noop

;-------------------------------------------------------------------------
;collect inline literal from within : definition

;       ( --- n1 )

code '(lit)', plit
  lodsd                     ;collect literal n1
  push ebx                  ;save cached top of stack
  mov ebx, eax              ;put n1 at top of stack
  next

;-------------------------------------------------------------------------
;execute word whose code address is at top of stack

;       ( a1 --- )

code 'execute', execute
  xchg ebx, [esp]           ;put a1 on stack, cach new top of stack in ebx
  ret                       ;jmp to address a1

;-------------------------------------------------------------------------
;store n1 in var whose address is compiled into definition

;also the run time for is

;       ( n1 --- )

code '%!>', zstoreto
  lodsd                     ;get address of word to modify
  mov [eax], ebx            ;store tos in body of word
  pop ebx
  next

;-------------------------------------------------------------------------
;zero var whose address is compiled into current definition

;       ( --- )

code '%off>', zoffto
  lodsd                     ;get address of var to zero
  mov dword [eax], 0        ;zero it
  next

;-------------------------------------------------------------------------
;set var whose address is compiled into current definition to true

;       ( --- )

code '%on>', zonto
  lodsd                     ;get address of var
  mov dword [eax], -1       ;set value to true
  next

;-------------------------------------------------------------------------
;increment var whose address is compiled into current definition

;       ( --- )

code '%incr>', zincrto
  lodsd                     ;get address of var
  inc dword [eax]           ;increment that address
  next

;-------------------------------------------------------------------------
;decrement var whose address is conpiled into current definition

;       ( --- )

code '%decr>', zdecrto
  lodsd                     ;get address of var
  dec dword [eax]           ;decrement that address
  next

;-------------------------------------------------------------------------
;add n1 to var whose address is compiled into current definition

;       ( n1 --- )

code '%+!>', zplusstoreto
  lodsd                     ;get address of var
  add dword [eax], ebx      ;add n1 to var
  pop ebx
  next

;-------------------------------------------------------------------------
;user apps can change default inner loop

code 'quit', quit
  call dodefer              ;in c this is called main()
  dd pquit

;   ' my-main is quit
;   turnkey app-filename

;-------------------------------------------------------------------------
;user apps can change default abort action

code 'abort', abort
  call dodefer
  dd pabort

;-------------------------------------------------------------------------
;default execution vector for a defered word

;       ( --- )

colon 'crash', crash
  dd true, pabortq
  db 30, 'Un-Initialized Executon Vector'
  dd exit

;-------------------------------------------------------------------------
;quit isforth back to shell

;       ( --- )

colon 'bye', bye
  dd atexit                 ;run the exit chain
  dd cr, cr, pdotq          ;exit nicely
  db 10,'Au Revoir!'
  dd cr, cr
  dd errno, sys_exit
  dd exit

;=========================================================================
