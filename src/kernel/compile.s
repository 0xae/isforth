;compile.1      - isforth creating and compilation words
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------

 _variable_ 'dp', dp, _end          ;dictionary pointer - dont tuch
 _variable_ 'hp', hp, 0             ;head space pointer - dont touch

 _variable_ 'state', state, 0       ;0 = interpret, -1 = compile
 _variable_ 'last', last, 0         ;nfa of most recently defined word
 _variable_ 'thread', thread, 0     ;name hash of most recently defined

 _variable_ 'floads', floads, 0     ;number of nested floads (max = 5)
 _variable_ 'ok?', qok, -1          ;display ok messages in quit ?

;-------------------------------------------------------------------------
;return next free dictionary address

;       ( --- a1 )

code 'here', here
  push ebx                  ;flush top of stack cache
  mov ebx, dword [dp+5]     ;return dp
  next

;-------------------------------------------------------------------------
;return next free head space address

;       ( --- a1 )

code 'hhere', hhere
  push ebx                  ;flush top of stack cache
  mov ebx, dword [hp+5]     ;return hp
  next

;-------------------------------------------------------------------------
;word to mask out lex (immdiate etc) bits from a count byte

;       ( n1 --- n1' )

code 'lexmask', lexmask
  and ebx, $1f              ;mask out everything except length bits
  next                      ;max lengh for word name is 32 charactes

;-------------------------------------------------------------------------
;move from code field address to body field address

;       ( a1 --- a2 )

code '>body', tobody
  add ebx, byte 5           ;call instruction in cfa is 5 bytes
  next

;-------------------------------------------------------------------------
;move from body field address back to code field address

;       ( a1 --- a2 )

code 'body>', bodyto
  sub ebx, byte 5           ;skip back to call instruction in cfa
  next

;-------------------------------------------------------------------------
;move from name field to link field

;       ( a1 --- a2 )

code 'n>link', ntolink
  sub ebx, byte 4          ;link field is 4 bytes just ahead of nfa
  next

;-------------------------------------------------------------------------
;move from link field to name field

;       ( a1 --- a2 )

code 'l>name', linktoname
  add ebx, byte 4          ;link field is 4 bytes
  next

;-------------------------------------------------------------------------
;move from nfa to cfa

;       ( a1 --- a2 )

colon 'name>', nameto
  dd count                  ;convert a1 to a1+1 n1
  dd lexmask, plus          ;mask lex bits out of count and add n1 to a1
  dd fetch                  ;fetch contents of cfa pointer
  dd exit

;-------------------------------------------------------------------------
;move from cfa to name field

colon '>name', toname
  dd cellminus, fetch         ;cell preceeding cfa points to nfa
  dd exit

;-------------------------------------------------------------------------
;put forth in interpret mode

  _immediate_

colon '[', lbracket
  dd state, off
  dd exit

;-------------------------------------------------------------------------
;put forth in compile mode

colon ']', rbracket
  dd state, on              ;this word is not the compiler because it
  dd exit                   ;should not be the compiler.  nuff sed.

;-------------------------------------------------------------------------
;alloate n1 bytes of dictionary space

;       ( n1 --- )

code 'allot', allot
  add dword [dp+5], ebx     ;add n1 to dictionary pointer
  pop ebx                   ;cache new top of stack
  next

;-------------------------------------------------------------------------
;allocate n1 bytes of head space

;       ( n1 --- )

code 'hallot', hallot
  add dword [hp+5], ebx     ;add n1 to head space pointer
  pop ebx
  next

;-------------------------------------------------------------------------
;compile 32 bit data into dictionary space

;       ( n1 --- )

code ',', comma
  mov eax, [dp+5]           ;get next dictionary address
  add dword [dp+5], byte 4  ;allot dictionary space
  mov [eax], ebx            ;write data n1 into dictionary
  pop ebx
  next

;-------------------------------------------------------------------------
;compile 16 bit word into dictionary space

;       ( w1 --- )

code 'w,', wcomma
  mov eax, [dp+5]           ;get dictionary pointer
  add dword [dp+5], byte 2
  mov word [eax], bx        ;store w1 in dictionary
  pop ebx
  next

;-------------------------------------------------------------------------
;compile a byte (character) into dictionary space

;       ( c1 --- )

code 'c,', ccomma
  mov eax, dword [dp+5]     ;get next dictionary address
  inc dword [dp+5]          ;allocate one byte
  mov byte [eax], bl
  pop ebx
  next

;-------------------------------------------------------------------------
;compile n1 into head space

;       ( n1 --- )

code 'h,', hcomma
  mov eax, dword [hp+5]     ;get address of next free location in headers
  add dword [hp+5], byte 4  ;alloocate the space
  mov dword [eax], ebx      ;store data in allocated space
  pop ebx
  next

;-------------------------------------------------------------------------
;compile string at a1 of length n1 into dictionary

;       ( a1 n1 --- )

colon 's,', scomma
  dd here, swap             ;from to count
  dd dup, allot             ;allocate the space first
  dd cmove_                 ;move string into place
  dd exit

;-------------------------------------------------------------------------
;parse string from input and compile into dictionary as counted string

colon ',"', commaq
  dd plit, $22, parse
  dd dup, ccomma
  dd scomma
  dd exit

;-------------------------------------------------------------------------
;like ," but does not store count byte

colon ",'", comma1q
  dd plit, $27, parse
  dd scomma
  dd exit

;-------------------------------------------------------------------------
;fetch compiled in parameter - equiv of r> dup cell+ >r @

;       ( --- n1 )

code 'param', param
  push ebx                  ;push cached top of stack item
  mov ebx, [ebp]            ;get top item of return stack in ebx
  add dword [ebp], byte 4   ;advance return address past parameter
  mov ebx, dword [ebx]      ;fetch parameter
  next

;-------------------------------------------------------------------------
;compile inline item (from current executing def) into new definition

colon 'compile', compile
  dd param                  ;fetch item to compile from return address
  dd comma                  ;compile it into word being created
  dd exit

;This word and [compile] have become a bit of an issue in the forth
;community.  compile takes the next token from the execution stream
;and compiles it into the definition currently being created.  [compile]
;takes the next token out of the INPUT stream and compiles it into the
;definition currently being created. [compile] is used to compile immediate
;words which would normally execute when in compile mode instead of being
;compiled.
;
;The perceived problem with this is that they have very similar names and
;you as the programmer would need to know every single immediate word in
;the entire dictionary in order to know how to use each of the above.
;
;In order to solve this huge non-problem a new word has been invented that
;will compile any word, immediate or otherwise, thus relieving you of the
;responsibility of knowing the language you are programming in.
;
;Like all good ans words this aforementioned new word has a name that
;  - totally - fails - to - describe - its - function
;
;  "postpone"         will probably remain undefined within isforth

;-------------------------------------------------------------------------
;compile an immediate word

  _immediate_

colon '[compile]', bcompile
  dd tick                   ;parse input for word name and 'find' it
  dd comma                  ;compile it in
  dd exit

;-------------------------------------------------------------------------
;compile literal into : definition

  _immediate_

colon 'literal', literal
  dd compile, plit          ;compile (lit)
  dd comma                  ;compile n1
  dd exit

;------------------------------------------------------------------------
;shorthand for '] literal'

colon ']#', rbsharp
  dd rbracket, literal
  dd exit

;------------------------------------------------------------------------
;compile word as literal

  _immediate_

colon "[']", btick
  dd compile, plit          ;compile (lit)
  dd bcompile               ;parse and compile word to be literalized
  dd exit

;-------------------------------------------------------------------------
;compile (abort") and the abort message string

  _immediate_

colon 'abort"', abortq
  dd compile, pabortq
  dd commaq
  dd exit

;-------------------------------------------------------------------------
;compile a string to be displayed at run time

  _immediate_

colon '."', dotquote
  dd compile, pdotq
  dd commaq
  dd exit

;-------------------------------------------------------------------------
;compile a call instruction to literal address

colon ',call', ccall
  dd param                  ;fetch target address of call
  dd plit, $0e8, ccomma     ;compile opcode for call instruction
  dd here, cellplus, minus  ;compute delta from call location tatget
  dd comma                  ;compile call target delta
  dd exit

;-------------------------------------------------------------------------
;patch cfa of last word (non coded defs only) to use specified word

colon ';uses', suses
  dd param                  ;get address of word to be used by new word

;now find the cfa of the word to patch (word being created)

  dd last, fetch            ;get nfa of last defined word
  dd nameto                 ;point at cfa of word being created
  dd oneplus                ;skip the call instruction
  dd duptor                 ;keep copy of address to patch
  dd cellplus, minus        ;compute delta from here to word to use
  dd rto, store             ;patch cfa of latest word
  dd exit

;-------------------------------------------------------------------------
;patch last definition to use asm code directly following ;code

colon ';code', scode
  dd rto                    ;use of ;code is an implied unnest!

  dd last, fetch            ;get nfa of last defined word
  dd nameto                 ;point at cfa of word being created
  dd oneplus                ;skip the call instruction
  dd duptor                 ;keep copy of address to patch
  dd cellplus, minus        ;compute delta from here to word to use
  dd rto, store             ;patch cfa of latest word
  dd exit

;-------------------------------------------------------------------------
;define run time action of a word being compiled

_immediate_

colon 'does>', does
  dd compile, scode         ;compile ;code at the does> location
  dd ccall, dodoes          ;compile a call to dodoes at here
  dd exit

;-------------------------------------------------------------------------
;create a new word header

colon '(head,)', phead
  dd hhere, tor             ;remember link field address of new header
  dd plit, 0, hcomma        ;dummy link to as yet unknown thread
  dd hhere, dup             ;get address where nfa will be compiled
  dd last, store            ;remember address of new words nfa
  dd comma                  ;link cell preceeding cfa to nfa
  dd hhere, strstore        ;store string at hhere
  dd current, fetch         ;get address of first thread of current voc
  dd hhere, hash, plus      ;hash new word name, get thread to link it into
  dd dup, thread, store     ;remember address of thread (for reveal)
  dd fetch, rto, store      ;link new word to previous one in thread
  dd hhere, cfetch, oneplus ;allocate name field !!
  dd hallot
  dd here, hcomma           ;compile address of cfa into header
  dd exit

;-------------------------------------------------------------------------
;create a new word header in head space

colon 'head,', headcomma
  dd bl_, parseword         ;parse name from tib
  dd phead                  ;create header from name
  dd exit

;-------------------------------------------------------------------------
;link most recently created header into current vocabulary chain

colon 'reveal', reveal
  dd last, fetch            ;get nfa of most recent definition
  dd thread, fetch          ;get address of thread to link into
  dd store                  ;link new header into chain
  dd exit

;-------------------------------------------------------------------------
;create new dictionary entry

colon 'create', create
  dd headcomma              ;create header for new word
  dd ccall, dovariable      ;compile a call to dovariable in new words cfa
  dd reveal                 ;link header into current
  dd exit

;-------------------------------------------------------------------------
;these two words are used together a heck of a lot

colon 'create,', createc
  dd create
  dd comma
  dd exit

;-------------------------------------------------------------------------
;make the most recent forth definition an immediate word

colon 'immediate', immediate
  dd plit, $40              ;immediate flag value
  dd last, fetch            ;get addrress of nfa of last word
  dd cset                   ;make word immediate
  dd exit

;-------------------------------------------------------------------------
;create a second header on an already existing word whose cfa is at a1

colon 'alias', alias
  dd headcomma              ;create new header
  dd plit, -4, dup          ;deallocate cfa pointer that points to here
  dd hallot, allot          ;deallocate nfa pointer at cfa -4
  dd dup, hcomma            ;point header at cfa of word to alias
  dd toname, qdup           ;does word being aliased have an nfa?
  dd doif, .L2
  dd cfetch                 ;get name field count byte and lex bits
  dd plit, $40, andd        ;is it immediate
  dd doif, .L1
  dd immediate              ;make alias immediate too
.L1:
  dd dothen                 ;waste some code space just for the decompiler
.L2:
  dd dothen                 ; :/
  dd plit, $20              ;mark this as an alias
  dd last, fetch, cset      ;see header relocation code
  dd reveal                 ;link alias into vocabulary
  dd exit

;-------------------------------------------------------------------------
;create a defered word - (a re-vectorable word, not a fwd reference)

;use of defered in order to create forward references is bad style.  this
;word is intended to create words that can be revectored to do different
;things depending on context.
;
; e.g.  emit is a defered word that is normally vectored to (emit) which
;       will output the emitted character to the console.  you can
;       revector emit to write the character to some file or device
;       instead.

colon 'defer', defer
  dd create                 ;create new dictionary entry
  dd suses, dodefer         ;patch new word to use dodefer not dovariable
  dd compile, crash         ;compile default vector into defered word
  dd exit

;-------------------------------------------------------------------------
;add current definition onto end of defered chain (or beginning!!)

  _immediate_

colon 'defers', defers
  dd last, fetch, nameto    ;get cfa of word being defined
  dd tick, tobody           ;get body field address of defered word
  dd dup, fetch, comma      ;compile its contents into word being defined
  dd store                  ;point defered word at new word
  dd exit

; e.g.
;
; defer foo ' blah is foo

; : xyzzy defers foo ..... ;
; : abcde defers foo ..... ;

;when foo executes it is now defered to abcde which calls xyzzy. xyzzy
;calls blah.

; : fooblah ...... defers foo ; \ patch to start of chain

;-------------------------------------------------------------------------
;begin compiling a definition

colon ':', colon_
  dd headcomma              ;create header for new word
  dd ccall, nest            ;compile call to nest at new words cfa
  dd rbracket               ;set state on (were compiling now)
  dd exit

;-------------------------------------------------------------------------
;complete definition of a colon definition

  _immediate_

colon ';', semicolon
  dd compile, exit          ;compile an unnest onto end of colon def
  dd lbracket               ;state off
  dd reveal
  dd exit

;-------------------------------------------------------------------------
;advise not using this word. itterative methods are ALWAYS better

  _immediate_

colon 'recurse', recurse
  dd last, fetch            ;foot in self shoot
  dd nameto, comma
  dd exit

;-------------------------------------------------------------------------
;add handler for a syscall

;       ( #params sys# --- )

colon 'syscall', syscall_
  dd create                 ;create the syscall handler word
  dd ccomma                 ;compile in its syscall number
  dd ccomma                 ;compile in parameter count
  dd suses, do_syscall      ;patch new word to use dosyscall
  dd exit

;-------------------------------------------------------------------------
;create handler for singlan sig#

;       ( addr sig# --- )

; colon 'signal', signal
;   dd create, here, bodyto   ;create and point to cfa of new word
;   dd suses, do_signal
;   dd rot, comma             ;compile address of signal handler
;   dd swap, sys_signal       ;make cfa a handler for specified signal
;   dd exit

;=========================================================================
