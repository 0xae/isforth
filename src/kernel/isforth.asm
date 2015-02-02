;isforth.asm    - isforth main kernel source   (c) 2000+ mark i manning iv
;=========================================================================

  bits 32                   ;This field intentionally NOT left blank

  %define ver $0118         ;hi byte = maj ver : lo byte = min ver

;-------------------------------------------------------------------------

; any modifications made within the kernel sources will require that the
; linker script also be modified.  see linker script for details

;-------------------------------------------------------------------------
;so im cleaning up a lil' but dont expect me to give up ALL my magic #'s!

  %define MEMSZ $100000     ;one meg
  %define STKSZ $1000       ;4k (return stack size)
  %define FLDSZ 36 * 5      ;fload stack size (5 nested floads max)
  %define TIBSZ $400        ;terminal input buffer size

;-------------------------------------------------------------------------

  %include "macros.s"       ;macros to create headers etc

;-------------------------------------------------------------------------

 [section .bss]             ;this bss section is bigger than it needs to
 resb $100000               ;be. fsave will shrink it

;-------------------------------------------------------------------------

 [section .text]            ;i dont comment on bullshit
  global _start             ; (much :)

;-------------------------------------------------------------------------
;forth kernel initialization...
;-------------------------------------------------------------------------

_start:                     ;stupid linker needs this bullshit
origin:
  mov edi, _start           ;point to entry point
  and edi, $0fffff000       ;mask to start of section address

;edi now points to the 0th byte of program memory belonging to this
;process.  this is the address of the programs elf headers.

  call init_mem             ;sys_brk out to 1m and sys_mprotect to rwx
  call alloc_ret            ;allocate return stack
  call init_vars            ;initialize some forth variables
  call get_args             ;set address of argp envp etc
  call unpack               ;relocate headers to allocated head space
  call chk_tty              ;chk if stdin/out are on a terminal
  call clr_mem              ;erase as yet unused list space

  mov [rp0+5], ebp          ;set address of bottom of return stack
  mov [sp0+5], esp          ;set address of bottom of parameter stack
  jmp doquit

;-------------------------------------------------------------------------
;test if fd in ebx is a tty. return result in eax

_chk_tty:
  mov eax, $36              ;ioctl
  mov ecx, $5401            ;tcgets
  mov edx, [dp+5]           ;here
  int $80                   ;is handle ebx a tty?
  sub eax, 1
  sbb eax, eax              ;0 = fales. -1 = true
  ret

;-------------------------------------------------------------------------

chk_tty:
  xor ebx, ebx              ;stdin
  call _chk_tty             ;test fd ebx = tty
  mov [intty+5], eax        ;store result for stdin

  mov ebx, 1                ;stdout
  call _chk_tty             ;get parameters for syscall
  mov [outtty+5], eax       ;store result for stdout
  ret

;-------------------------------------------------------------------------

_fetchmap:
  push 0                    ;offset_t
  push -1                   ;fd
  push edx                  ;flags
  push ecx                  ;prot
  push ebx                  ;size
  push 0                    ;*start
  mov ebx, esp              ;point edx at parameters
  mov eax, $5a              ;mmap
  int $80
  add esp, 24
  ret

;-------------------------------------------------------------------------
;allocate return stack of 4k (one page)

alloc_ret:
  mov ebx, STKSZ
  mov ecx, 3
  mov edx, $22
  call _fetchmap
  add eax, STKSZ            ;point to top of buffer we just allocated
  mov ebp, eax              ;set return stack pointer
  ret

;-------------------------------------------------------------------------
;allocate forths list and head space

init_mem:
  mov eax, $7d              ;sys mprotect all memory as +rwx
  mov ebx, edi
  mov ecx, MEMSZ
  mov edx, 7
  int $80                   ;make the entire program space rwx
  ret

;-------------------------------------------------------------------------

init_vars:
  mov dword [qtty+5], 0     ;terminal properties not set yet
  mov dword [shebang+5], 0  ;not running as a script

  mov eax, edi              ;set fload nest stack at end of memory
  add eax, MEMSZ-1-FLDSZ
  mov [lsp+5], eax          ;dont nest floads!!!

  sub eax, TIBSZ            ;1k for terminal input
  mov [ttib+5], eax
  dec eax

  mov [thead+5],eax         ;mark upper bounds of head space

  mov eax, edi              ;set address of top of list space
  add eax, MEMSZ/2          ;split mem in 2
  add eax, $3ff
  and eax, -$400
  mov [hp+5], eax           ;address for headers to be relocated to
  mov [bhead+5], eax        ;needed by fsave - bottom of head space
  ret

;-------------------------------------------------------------------------

get_args:
  pop edx                   ;our return address (bleh)
  xor eax, eax

  mov [argp+5], eax         ;pointer to argv[]
  mov [envp+5], eax         ;pointer to envp[]
  mov [auxp+5], eax         ;pointer to auxp[]

  pop ecx                   ;argc
  pop dword [arg0+5]        ;program name
  mov [argp+5], esp
  lea esi, [esp + 4 * ecx]  ;point to env vars
  dec ecx
  mov [argc+5], ecx         ;set argc
  mov [envp+5], esi         ;scan to end of env vars
L0:
  lodsd
  cmp eax, 0
  jne L0
  inc esi
  mov [auxp+5], esi         ;point to aux vectors
  jmp edx

;-------------------------------------------------------------------------
;not required but keeps users list space clean at start of world

clr_mem:
  mov edi, [dp+5]           ;erase list space
  mov ecx, [bhead+5]        ;address at top of list space plus 1
  sub ecx, edi
  xor eax, eax
  rep stosb                 ;erase entire unused part of list space
  ret

;-------------------------------------------------------------------------

  [section list align=4]

LISTSTART:

;-------------------------------------------------------------------------
;some important variables and constants

 _constant_ 'origin', org, origin
 _constant_ 'version', version, ver

 _constant_ 'thead', thead, 0   ;address of top of head space
 _constant_ 'head0', bhead, 0   ;address of bottom of head space

 _constant_ 'arg0', arg0, 0     ;program name
 _constant_ 'argc', argc, 0     ;arg count
 _constant_ 'argp', argp, 0     ;address of args on stack
 _constant_ 'envp', envp, 0     ;environment vectors
 _constant_ 'auxp', auxp, 0     ;aux vectors
 _variable_ "'tib", ttib, 0     ;address of tib

 _constant_ 'shebang', shebang, 0
 _constant_ 'intty', intty, 0
 _constant_ 'outtty', outtty, 0

;-------------------------------------------------------------------------
;note: older kernels such as 2.2.x do not support anonymous shared
;blocks, you must make anonymous mappings private if you wish to maintain
;support for older kernels

 _constant_ 'heap-prot', heap_prt, 7       ;+rwx
 _constant_ 'heap-flags', heap_flg, $22    ;anonymous private

;-------------------------------------------------------------------------
;these need a better home

 _constant_ 'turnkeyd', turnkeyd, 0 ;true if we are a turnkeyd app
 _constant_ 'lsp', lsp, 0           ;fload nest stack pointer
 _variable_ '?tty', qtty, 0         ;flag: term initialized already ?

;-------------------------------------------------------------------------

;     ( flags prot size --- )

code '@map', fmap
  mov ecx, [heap_prt+5]
  mov edx, [heap_flg+5]

  call _fetchmap

  cmp eax, $0fffff000
  jbe .L1

  mov ebx, -1
  next
.L1:
  push eax
  xor ebx, ebx
  next

;-------------------------------------------------------------------------
;made deferred to facilitate their use in debugging extensions

code '.s', dots
  call dodefer
  dd noop

;-------------------------------------------------------------------------
;unsigned version of the above

code '.us', dotus
  call dodefer
  dd noop

;-------------------------------------------------------------------------
;useful for debugging the forth kernel

code 'break', break
  next

;-------------------------------------------------------------------------
;deferd initialization chain  (default priority)

;       ( --- )

code 'default', _default    ;forward references dodefer and noop
  call dodefer              ;nothing added to this chain yet
  dd noop

;-------------------------------------------------------------------------
;deferd initialization chain  (hi priority)

;       ( --- )

code 'pdefault', _pdefault  ;forward references dodefer and noop
  call dodefer              ;nothing added to this chain yet
  dd noop

;-------------------------------------------------------------------------
;deferd initialization chain  (lo priority)

;this chain is only executed after everything in the high priority and
;default priority initialization chain has already been initialized

;       ( --- )

code 'ldefault', _ldefault  ;forward references dodefer and noop
  call dodefer              ;nothing added to this chain yet
  dd noop

;-------------------------------------------------------------------------
;defered exit chain

;       ( --- )

code 'atexit', atexit       ;forward references dodefer and noop
  call dodefer              ;nothing added to this chain yet
  dd noop

;-------------------------------------------------------------------------
;the beef (moo!)

 %include "reloc.s"         ;head space relocation (see fsave.f)
 %include "syscalls.s"      ;interface to the 'BIOS' ;)
 %include "stack.s"         ;stack manipulation etc
 %include "memory.s"        ;fetching and storing etc
 %include "logic.s"         ;and/or/xor etc
 %include "math.s"          ;basic math functions +/-* etc
 %include "loops.s"         ;looping and branching constructs
 %include "exec.s"          ;word execution, nest/next etc
 %include "io.s"            ;console i/o etc
 %include "find.s"          ;dictionary searches
 %include "fload.s"         ;interpret from file
 %include "compile.s"       ;compilation/creating words
 %include "interpret.s"     ;inner interpreter
 %include "vocabs.s"        ;vocabulary creation etc

;-------------------------------------------------------------------------
;do not define any words below this point unless they are headerless
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------

;in windows you quit by hitting the start button.  in forth you start
;by jumping to quit :)
;
;according to the forth tradition the word quit is the main loop of the
;inner interpreter.  i have a slightly modified view of what quit is
;however - to me quit is the inner compiler.  the interpret loop that
;(quit) calls is just a means of interfacing to the compiler and testing
;that which you compile.
;
;once development is complete and your new application executable is saved
;out the compiling and creating words are usually never referenced again.
;in a turnkeyd application where all headers have been stripped out of the
;target executable it would be silly to make a reference to words like
;(quit) because that path eventually tries to search the dictionary and in
;a turnkeyd application there is no dictionary.
;
;in a turnkeyd application quit becomes main.
;
;to make a turnketd application in isforth one would do
;
;  ' app-main is quit
;  turnkey app-filename
;
;when the application is executed the call to quit above will jump to your
;app-main.  if you do not want anything initialized by the isforth kernel
;(like the terminal etc) you could instead do...
;
;  ' app-main is default
;  ' noop is pdefault
;  turnkey app-filename
;
;-------------------------------------------------------------------------

;-now we start running Forth code...

doquit:
  call nest                 ;the following is a colon definition
  dd _pdefault              ;hi priority defered init chain
  dd _default               ;std priority defered init chain
  dd _ldefault              ;low priority deferred init chain
  dd quit                   ;run inner function - never returns to here

;-------------------------------------------------------------------------
;marks end of code space (where boot will set dp pointing to)

;note:   do not define anything at all below this point

_end:                       ;when isforth loads, this is where headers are

section headers
_hend:

;=========================================================================
