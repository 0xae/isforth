;logic.1        - Isforth boolean logic etc
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
;bool constants

;       ( --- f1 )

  _constant_ 'true', true, -1
  _constant_ 'false', false, 0

;-------------------------------------------------------------------------
;logically 'and' top two stack items together

;       ( n1 n2 --- n3 )

code 'and', andd
  pop eax                   ;get n2
  and ebx, eax              ;and them together
  next

;-------------------------------------------------------------------------
;logically or top two items of stack

;       ( n1 n2 --- n3)

code 'or', orr
  pop eax                   ;get n2
  or ebx, eax               ;or them togeher
  next

;-------------------------------------------------------------------------
;logically exsclusive or top two items of parameter stack

;       ( n1 n2 --- n3 )

code 'xor', xorr
  pop eax                   ;get n2
  xor ebx, eax              ;xor them
  next

;-------------------------------------------------------------------------
;get 1's compliment of top stack item

;       ( n1 --- n2 )

code 'not', nott
  not ebx
  next

;-------------------------------------------------------------------------
;see if top item of stack is a zero (return true if it is)

;       ( n1 --- f1 )

code '0=', zequals
  sub ebx, byte 1           ;subtract 1 from n1 (carry if n1 was 0 )
  sbb ebx, ebx              ;subtract n1 from n1 (-1 if ther was a carry)
  next

;-------------------------------------------------------------------------
;compare top two items of parameter stack for equality

;       ( n1 n2 --- f1 )

code '=', equals
  pop eax                   ;get n1 and n2
  sub ebx, eax              ;subtract n1 from n2
  jmp zequals

;-------------------------------------------------------------------------
;return true if n1 is negative

;       ( n1 ---  f1 )

code '0<', zless
  sar ebx, byte 31          ;propogate sign bit throughout n1
  next

;-------------------------------------------------------------------------
;see if n1 is greater than 0

;       ( n1 --- f1 )

code '0>', zgreater
  neg ebx                   ;negate n1
  jmp short zless           ;and get sign

;-------------------------------------------------------------------------
;return true if n1 is posative

;       ( n1 --- f1 )

code '0<>', znotequals
  neg ebx                   ;erm this confuses me a little
  sbb ebx, ebx              ;did the above do something with overflow ?
  next

;-------------------------------------------------------------------------
;see if n1 is unequal to n2

;       ( n1 n2 --- f1 )

code '<>', notequals
  pop eax                   ;get n1 and n2
  sub ebx, eax              ;get difference
  neg ebx                   ;convert to a true or false
  sbb ebx, ebx
  next

;-------------------------------------------------------------------------
;see if unsigned n2 is less than unsigned n1

;       ( n1 n2 --- f1 )

code 'u<', uless
  pop eax                   ;get n1
.L0:
  sub eax, ebx              ;get difference
  sbb eax, eax              ;return true if n2 < n1
  mov ebx, eax
  next

;-------------------------------------------------------------------------
;see if unsigned n2 is greater than unsigned n1

;       ( n1 n2 --- f1 )

code 'u>', ugreater
  pop eax                   ;get n2 and n1 in oposite order from above
  xchg eax, ebx
  jmp uless.L0              ;use above code !!!

;-------------------------------------------------------------------------
;see if n2 is less than n1

;       ( n1 n2 --- f1 )

code '<', less
  pop eax                   ;get n1
  cmp eax, ebx              ;is n1 less than n2 ?
  mov ebx, -1
  jl .L1
  xor ebx, ebx              ;no
.L1:
  next

;-------------------------------------------------------------------------
;see if n2 is greater than n1

;       ( n1 n2 --- f1 )

code '>', greater
  pop eax
  cmp eax, ebx
  mov ebx, -1
  jg .L1
  xor ebx, ebx
.L1:
  next

;-------------------------------------------------------------------------
;return the smallest of 2 unsigned values

;       ( n1 n2 --- n1 | n2 )

code 'umin', umin
  pop eax                   ;get n2
  cmp eax, ebx              ;which is smaller
  ja .L0
  mov ebx, eax
.L0:
  next

;-------------------------------------------------------------------------
;return the smallest of 2 signed values

;       ( n1 n2 --- n1 | n2 )

code 'min', min
  pop eax                   ;get n1 and n2
  cmp eax, ebx              ;which is smaller
  jg .L1                    ;n2 is smaller
  mov ebx, eax              ;n1 is smaller
.L1:
  next

;-------------------------------------------------------------------------
;return the larger of 2 unsigned values

;       ( n1 n2 --- n1 | n2 )

code 'umax', umax
  pop eax                   ;get n1 nad n2
  cmp eax, ebx              ;compare them
  jna .L1                   ;n2 is bigger
  mov ebx, eax              ;n1 is bigger
.L1:
  next

;-------------------------------------------------------------------------
;return the larger of two signed values

;       ( n1 n2 --- n1 | n2 )

code 'max', max
  pop eax                   ;get n1 nad n2
  cmp eax, ebx              ;compare them
  jl .L1                    ;n2 is bigger
  mov ebx, eax              ;n1 is bigger
.L1:
  next

;-------------------------------------------------------------------------
;return n1 or zero if n1 is negative

;       ( n1 --- n1 | 0 )

code '0max', zmax
  xor eax, eax
  cmp ebx, eax              ;is n1 > 0 ?
  jg .L1
  mov ebx, eax
.L1:
  next

;-------------------------------------------------------------------------
;see if n1 is within upper and lower limits (not inclusive)

;       ( n1 n2 n3 --- f1 )

code 'within', within
  mov eax, ebx              ;get upper limit
  pop ecx                   ;get lower limit
  pop edx                   ;get n1
  xor ebx, ebx              ;assume false
  cmp edx, eax              ;is n1 below upper limit?
  jge .L0
  cmp edx, ecx              ;is n1 above lower limit?
  jl .L0
  dec ebx                   ;yes we are in limits
.L0:
  next

;-------------------------------------------------------------------------
;see if n1 is between upper and lower limits inclusive

;       ( n1 n2 n3 --- f1 )

code 'between', between
  mov eax, ebx              ;get upper limit
  pop ecx                   ;get lower limit
  pop edx                   ;get n1
  xor ebx, ebx              ;assume false
  cmp edx, eax              ;is n1 less that or equal to uper limit?
  jg .L0
  cmp edx, ecx              ;is n1 greater than or equal to lower limit?
  jl .L0
  dec ebx                   ;we are within limits, eax = true
.L0:
  next

;-------------------------------------------------------------------------
;return true if n1 equals either n2 or n3

; : either      ( n1 n2 n3 --- f1 )
;   -rot over =
;   -rot = | ;

colon 'either', either
  dd dashrot, over, equals
  dd dashrot, equals, orr
  dd exit

;-------------------------------------------------------------------------
;return true if n1 is not equal to eithe n2 or n3

; : neither
;   -rot over <>
;   -rot <> & ;

;       ( n1 n2 n3 --- f1 )

colon 'neither', neither
  dd dashrot, over, notequals
  dd dashrot, notequals, andd
  dd exit

;=========================================================================
