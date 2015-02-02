;math.1         - isforth basic math words
;-------------------------------------------------------------------------

  _variable_ 'base', base, 10  ;default radix is 10

;-------------------------------------------------------------------------
;add top two items on parameter stack

;       ( n1 n2 --- n3 )

code '+', plus
  pop eax                    ;get n2
  add ebx, eax               ;add it to n1
  next

;-------------------------------------------------------------------------
;subtract top item from second item

;       ( n1 n2 --- n3 )

code '-', minus
  sub [esp], ebx             ;thanks to rikusw for suggesting this def
  pop ebx
  next

;-------------------------------------------------------------------------
;compute absolute value of top item of parameter stack

;       ( n1 --- n1 | +n1 )

code 'abs', abs_
  mov eax, ebx               ;set ebx = sign of n1
  sar eax, byte 31           ;propogate sign bit if n1 throughout ebx
  xor ebx, eax               ;will invert n1 if n1 was negative
  sub ebx, eax               ;will subtract -1 if n1 was negative
  next                       ; i.e. it will add 1

;-------------------------------------------------------------------------
;shift left n1 by n2 bits

;       ( n1 n2 --- n3 )

code '<<', shll
  pop ecx                    ;get number to be shifted
  xchg ebx, ecx              ;get n1 in ebx n2 in ecx
  sal ebx, cl
  next

;-------------------------------------------------------------------------
;signed shift right n1 by n2 bits

;       ( n1 n2 --- n3 )

code '>>', shrr
  pop ecx
  xchg ebx, ecx
  sar ebx, cl
  next

;-------------------------------------------------------------------------
;unsigned shift right n1 by n2 bits

;       ( n1 n2 --- n3 )

code 'u>>', ushr
  pop ecx                    ;get number to be shifted
  xchg ebx, ecx              ;get n1 in ebx and n2 in ecx
  shr ebx, cl
  next

;-------------------------------------------------------------------------
;multiply top item of parameter stack by 2

;       ( n1 --- n2 )

code '2*', twostar
  add ebx, ebx
  next

;-------------------------------------------------------------------------
;divide top item of parameter stack by 2

;       ( n1 --- n2 )

code '2/', twoslash
  sar ebx, byte 1            ;divide by 2
  next

;-------------------------------------------------------------------------
;divide unsigned number at top of parameter stack by 2

;       ( n1 --- n2 )

code 'u2/', u2slash
  shr ebx, byte 1            ;divide it by 2 (unsigned)
  next

;-------------------------------------------------------------------------
;multiply top item of parameter stack by 4

;       ( n1 --- n2 )

code '4*', star4
  shl ebx, byte 2
  next

;-------------------------------------------------------------------------
;add 1 to top item of parameter stack

;       ( n1 --- n2 )

code '1+', oneplus
  inc ebx
  next

;-------------------------------------------------------------------------
;decrement top item of parameter stack

;       ( n1 --- n2 )

code '1-', oneminus
  dec ebx
  next

;-------------------------------------------------------------------------
; add 2 to top item of parameter stack

;       ( n1 --- n2 )

code '2+', twoplus
  add ebx, byte 2
  next

;-------------------------------------------------------------------------
;subtract 2 from top item of parameter stacl

;       ( n1 --- n2 )

code '2-', twominus
  sub ebx, byte 2
  next

;-------------------------------------------------------------------------

;       ( n1 --- n2 )

code '4+', plus4
  add ebx, byte 4
  next

;-------------------------------------------------------------------------

;       ( n1 --- n2 )

code '4-', minus4
  sub ebx, byte 4
  next

;-------------------------------------------------------------------------
;flip sign

;       ( n --- -n )

code 'negate', negate
  neg ebx
  next

;-------------------------------------------------------------------------
;conditionally flip sign

; : ?negate         ( n1 f1 --- n1 | -n1 )
;   0< not ?exit
;   negate ;


colon '?negate', qnegate
  dd zless                   ;is f1 negative?
  dd nott, qexit
  dd negate
  dd exit

;-------------------------------------------------------------------------
;add two double (64 bit) numbers

;       ( d1 d2 --- d3 )

code 'd+', dplus
  pop eax                    ;d2 = ebx:eax
  pop ecx                    ;d1 = ecx:[esp]
  add [esp], eax             ;add d2 low to d1 low
  adc ebx, ecx               ;add d2 high to d1 high
  next

;-------------------------------------------------------------------------
;subtract 64 bit numbers

;       ( d1 d2 --- d3 )

code 'd-', dminus
  pop eax                    ;d1 = ebx:eax
  pop ecx                    ;d2 = ecx:[esp]
  sub [esp], eax             ;subtract d2 low from d1 low
  sbb ecx, ebx               ;subtract d2 high from d1 high
  mov ebx, ecx               ;return result high in ebx
  next

;-------------------------------------------------------------------------
;negate a double number

;       ( d1 --- -d1 )

code 'dnegate', dnegate
.L1:
  pop eax                    ;get d1 low
  neg ebx                    ;negate n1 low and high
  neg eax
  sbb ebx, byte 0            ;did the neg mess with overflow or something?
  push eax
  next

;-------------------------------------------------------------------------
;compute absolute value of a double

;       ( d1 ---- 'd1 )

code 'dabs', dabs
  test ebx, ebx              ;is d1 high negative?
  js dnegate.L1              ;if so negate d1
  next

;-------------------------------------------------------------------------
;convert single to double (signed!)

;       ( n1 --- d1 )

code 's>d', stod
  push ebx                   ;push d1 low = n1
  add ebx, ebx               ;shift sign bit into carry
  sbb ebx, ebx               ;propogates sign of n1 throughout d1 high
  next

;-------------------------------------------------------------------------
;compare 2 double numbers

;       ( d1 d2 --- f1 )


colon 'd=', dequals
  dd dminus                  ;stubract d2 from d1
  dd orr                     ;or together high and low of result
  dd zequals                 ;result will only be 0 when d1 = d2
  dd exit

;-------------------------------------------------------------------------
;is double number negative?

;       ( d1 --- f1 )

code 'd0<', dzlezz
  add ebx, ebx               ;shift sign bit into carry
  sbb ebx, ebx               ;propogates sign of n1 throughout d1 high
  pop eax
  next

;-------------------------------------------------------------------------
;see if double d1 is less than double d2

;       ( d1 d2 --- f1 )

code 'd<', dless
  pop eax
  pop ecx
  cmp [esp], eax
  pop eax
  sbb ecx, ebx
  mov ebx, 0
  jge .L1
  dec ebx
.L1:
  next

;-------------------------------------------------------------------------

;         ( d1 d2 --- f1 )

colon 'd>', dgreater
  dd swap2
  dd dless
  dd exit

;-------------------------------------------------------------------------

; :       ( d1 d2 --- f1 )

colon 'd<>', dnotequals
  dd dequals
  dd nott
  dd exit

;-------------------------------------------------------------------------
;unsigned mixes multiply

;       ( n1 n2 --- d1 )

code 'um*', umstar
  pop eax                    ;get n2
  mul ebx                    ;multiply
  push edx                   ;return 64 bit result
  mov ebx, eax
  next

;-------------------------------------------------------------------------
;multiply n1 by n2

;       ( n1 n2 --- n3 )

code '*', star
  pop eax                    ;get n1
  mul ebx                    ;multiply
  mov ebx, eax               ;return result
  next

;-------------------------------------------------------------------------

code 'm*', mstar
  pop eax
  imul ebx
  push eax
  mov ebx, edx
  next

;-------------------------------------------------------------------------

;       ( ud un --- uremainder uquotient)

code 'um/mod', umsmod
  pop edx
  pop eax
  div ebx
  push edx
  mov ebx, eax
  next

;-------------------------------------------------------------------------
;signed version of above

;       ( d1 n1 -- rem quot )

code 'sm/rem', smmod
  pop edx
  pop eax
  idiv ebx
  push edx
  mov ebx, eax
  next

;-------------------------------------------------------------------------

colon 'mu/mod', musmod
  dd tor, plit, 0
  dd rfetch, umsmod
  dd rto, swap, tor
  dd umsmod, rto
  dd exit

;-------------------------------------------------------------------------

;       ( d# n1 --- rem quot)

code 'm/mod', mmod
  pop edx
  mov eax, edx
  xor eax, ebx
  jns .L1

  pop eax
  idiv ebx
  test edx, edx
  je .L2
  add edx, ebx
  dec eax
  jmp short .L2
.L1:
  pop eax
  idiv ebx

.L2:
  push edx
  mov ebx, eax
  next

;-------------------------------------------------------------------------
;floored division and remainder.

;       ( num den --- rem quot )

code '/mod', smod
  pop ecx
  mov eax, ecx
  xor eax, ebx
  jns .L1

  mov eax, ecx
  xor ecx, edx
  cdq
  idiv ebx
  test edx, edx
  je .L2

  add edx, ebx
  dec eax
  jmp short .L2

.L1:
  mov eax, ecx
  mov edx, edx
  cdq
  idiv ebx

.L2:
  push edx
  mov ebx, eax
  next

;-------------------------------------------------------------------------

colon '/', slash
  dd smod, nip
  dd exit

;-------------------------------------------------------------------------

colon 'mod', mod
  dd smod, drop
  dd exit

;-------------------------------------------------------------------------

code '*/mod', ssmod
  pop ecx
  pop eax
  imul ecx
  mov ecx, edx
  xor ecx, ebx
  jns .L1

  idiv ebx
  test edx, edx
  je short .L2
  add edx, ebx
  dec eax
  jmp short .L2
.L1:
  idiv ebx
.L2:
  mov ebx, eax
  push edx
  next

;-------------------------------------------------------------------------

colon '*/', sslash
  dd ssmod, nip
  dd exit

;-------------------------------------------------------------------------
;maybe this dont belong in the kernel but its useful outside it :)

code 'bswap', b_Swap
  xchg bh, bl
  ror ebx, 16
  xchg bh, bl
  next

;=========================================================================
