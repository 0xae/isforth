; fload.s   - file load.  interpret forth sources from a file
;-------------------------------------------------------------------------

;stripped out of compile.s and performed major surgery for readability

;-------------------------------------------------------------------------

; i shall probably rename fload when i can think of a better name but the
; word 'needs' and its variants will never be part of isforth.  add them
; yourself if you realy gotta (sorry mrreach :)
;
; rationale...
;
;  foo.c includes foo.h
;  foo.h includes bar.h and futz.h
;  bar.h includes whussit.h and bleh.h
;  futs.h includes the already included bleh.h and....
;
; what you end up with is an include tree.  you have absolutely no idea
; which files included which files and it is highly probable that you
; are totally oblivious to some of the files that 'were' included.
;
; what you shoud have is a single load file including all the required
; source files.  if one of those files relies on some other file then
; it should not include it itself.
;
; if your compile aborts with "bleh ?" you should know which file it was
; that you forgot to include.  if you dont then grep is your friend

;-------------------------------------------------------------------------

 _variable_ 'fd', fd, 0             ;file handle of file being floaded
 _constant_ 'line#', linenum, 0     ;current line number of file
 _constant_ 'flsz', flsz, 0         ;fload file size
 _constant_ 'fladdr', fladdr, 0     ;fload memory map address
 _constant_ 'fl>in', fltoin, 0      ;pointer to current line of file

 _constant_ 'ktotal', ktotal, 0     ;total of all floaded file sizes

;-------------------------------------------------------------------------
;abort if file didnt open (n1 = file handle or error)

;       ( n1 --- )

colon '?open', qopen
  dd zgreater, qexit        ;open ok ???
  dd cr, hhere, count, type ;display offending filename
  dd true, pabortq          ;abort with error message
  db 11, ' open error'
  dd exit

;-------------------------------------------------------------------------
;push one item onto fload stack

;       ( n1 --- )

flpush:
  mov eax, [lsp+5]          ;get fload stack address in eax
  mov [eax], ebx            ;push item n1 onto stack
  add dword [lsp+5], byte 4 ;advance pointer
  pop ebx
  next

;-------------------------------------------------------------------------
;pop one item off fload stack

;       ( --- n1 )

flpop:
  sub dword [lsp+5], byte 4
  mov eax, [lsp+5]
  push ebx
  mov ebx, [eax]
  next

;-------------------------------------------------------------------------
;list of items to pop off fload stack on completion of a nested fload

  _noname_

pop_list:
  call dovariable

  dd linenum+5, flsz+5, fladdr+5
  dd fltoin+5, refill+5, toin+5
  dd fd+5, numtib+5, ttib+5
  dd 0

;-------------------------------------------------------------------------

  _noname_

restore_state:
  call nest

  dd pop_list               ;point to list of items to be restored

  dd dobegin                ;restore previous fload state
.L0:
  dd dcount, qdup           ;get next item to be restored
  dd qwhile, .L1            ;while it is not zero
  dd flpop, swap, store     ;pop item off fload stack and store in item
  dd dorepeat, .L0
.L1:
  dd drop, exit

;-------------------------------------------------------------------------
;fload completed, restore previous fload state

  _noname_

endfload:
  call nest

  dd flsz                   ;count total size of all floads
  dd zplusstoreto, ktotal+5
  dd flsz, fladdr           ;unmap file we completed
  dd sys_munmap
  dd fd, fetch, sys_close   ;close the file
  dd drop2
  dd restore_state          ;restore previous fload status
  dd floads, decr           ;decremet fload nest depth counter
  dd exit

;-------------------------------------------------------------------------
;aborts an fload - leaves line# of error intact

colon 'abort-fload', abortfload
  dd linenum, endfload      ;headerfull so \s in comments.f extension
  dd zstoreto, linenum+5    ;can reference it
  dd exit

;-------------------------------------------------------------------------
;determine byte size of file

;this sorta belongs in file.f but we cant put it there because the kernel
;would then have to forward reference an extension! :)

;       ( fd --- size )

colon '?fl-size', qfs
  dd plit, 2, plit, 0
  dd rot, sys_lseek
  dd exit

;-------------------------------------------------------------------------
;mmap file fd with r/w perms n2 with mapping type n1

;       ( fd flags prot --- address size )

colon 'fmmap', fmmap
  dd tor2
  dd dup, qfs, tuck
  dd plit, 0, dashrot
  dd rto2, rot
  dd plit, 0
  dd sys_mmap
  dd swap, exit

;-------------------------------------------------------------------------
;list of items to save when nesting floads

  _noname_

push_list:
  call dovariable

  dd ttib+5, numtib+5, fd+5
  dd toin+5, refill+5, fltoin+5
  dd fladdr+5, flsz+5, linenum+5
  dd 0

;-------------------------------------------------------------------------
;push all above listed items onto fload stack

  _noname_

save_state:
  call nest

  dd push_list              ;point to list of items to be saved

  dd dobegin
.L0:
  dd dcount, qdup           ;get next item
  dd qwhile, .L1            ;while its not zero
  dd fetch, flpush          ;fetch and push its contents to fload stak
  dd dorepeat, .L0

.L1:
  dd drop, exit

;-------------------------------------------------------------------------
;init for interpreting of next line of memory mapped file being floaded

  _noname_

colon 'flrefill', flrefill
  dd fladdr, flsz, plus     ;did we interpret the entire file?
  dd fltoin, equals
  dd doif, .L1              ;if so end floading of this file
  dd endfload, exit         ;and restore previous files fload state
.L1:
  dd dothen

  dd zincrto, linenum+5     ;not done, increment current file line number
  dd fltoin, dup            ;set tib = address of next line to interpret
  dd ttib, store
  dd plit, 1024, plit, $0a  ;scan for eol on this line of source
  dd scan
  dd zequals, pabortq       ;coder needs a new enter key
  db 19, 'Fload Line Too Long'
  dd oneplus, dup           ;point beyond the eol
  dd fltoin, minus          ;calculate total length of current line
  dd numtib, store          ;set tib size = line length
  dd zstoreto, fltoin+5     ;set address of next line to interpret
  dd toin, off              ;set parse offset to start of current line

  dd exit

;-------------------------------------------------------------------------
;fload file whose name is an ascii string

;     ( a1 --- )

colon '(fload)', pfload
  dd sys_open3              ;attempt to open specified file
  dd dup, qopen             ;abort if not open

  dd dup, plit, 2           ;map private
  dd plit, 3, fmmap         ;prot read.  memory map file

  dd save_state             ;save state of previous fload if any

  dd plit, flrefill         ;make fload-refil forths input refill
  dd zstoreto, refill+5

  dd zstoreto, flsz+5       ;remember size of memory mapping
  dd dup
  dd zstoreto, fladdr+5     ;set address of files memory mapping
  dd zstoreto, fltoin+5     ;set this address as current file parse point

  dd fd, store              ;save open file descriptor
  dd floads, incr           ;count fload nest depth

  dd zoffto, linenum+5      ;reset current line of file being interpreted

  dd refill, exit

;-------------------------------------------------------------------------
;intepret from a file

colon 'fload', fload
  dd floads, fetch          ;max fload nest depth is 5 and thats too manu
  dd plit, 5, equals
  dd pabortq
  db 22, 'Floads Nested Too Deep'

  dd plit, 0, dup           ;file perms and flags
  dd bl_, word_             ;parse in file name
  dd hhere, count, s2z      ;make file name asciiz
  dd pfload, exit ;

;==========================================================================
