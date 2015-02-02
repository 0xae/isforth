;interpret.s    - isforth inner interpreter
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
;compile a number or return its value

colon '?comp#', qcompnum
  dd state, fetch           ;do we compile this number or...
  dd nott, qexit            ;just leave it on the stack
  dd literal
  dd exit

;-------------------------------------------------------------------------
;input not a known word. its it a valid number in current radix?

;       ( --- | n1 )

colon '?#', qnum
  dd hhere, cfetch, zequals ;null input ?
  dd qexit                  ;null input is not an error

  dd hhere, number          ; ( --- n1 true | false )
  dd nott, qmissing         ;abort if not valid number
  dd qcompnum
  dd exit

;-------------------------------------------------------------------------
;input is a known word. compile it or execute it

;       ( xt [ t | 1 ] --- )

colon '?exec', qexec
  dd state, fetch, xorr
  dd qcolon, execute, comma
  dd exit

;-------------------------------------------------------------------------
;interpret/compile word or number

;       ( xt [t | 1] | false --- | n1 )

colon '(xinterpret)', pxinterpret
  dd qdup
  dd qcolon
  dd qexec, qnum
  dd exit

;-------------------------------------------------------------------------
;deferring interpret allows for target tethering

code '(interpret)', pinterpret
  call dodefer
  dd pxinterpret

;-------------------------------------------------------------------------
;interpret till no input left

colon 'interpret', interpret
  dd dobegin
.L0:
  dd defined                ;is the typed in stuff a valid forth word?
  dd pinterpret             ;interpret, compile or abort
  dd qstack                 ;did any of the above over/underflow?
  dd left, zequals          ;if theres anything left keep going
  dd quntil, .L0
  dd exit                   ;else return to quit for an "ok"

;-------------------------------------------------------------------------
;display status line info

;quit calls this defered word which is patched at extend time to
;display status information.  your code can also patch itself into quit
;via this word.

code '.status', dotstatus
  call dodefer
  dd noop

;-------------------------------------------------------------------------
;conditionally display "ok" after user input

colon '.ok', dotok
  dd floads, fetch, qexit   ;never display ok when floading

  dd state, fetch, nott     ;no ok mesage while still in compile mode
  dd qok, fetch, andd       ;abort errors are never ok
  dd doif, .L0              ;but go ahead and output a cr

  dd pdotq                  ;ok... display ok message
  db 3, ' ok'

.L0:
  dd dothen
  dd cr                     ;output a new line
  dd qok, on                ;reset ?ok till next error
  dd exit

;-------------------------------------------------------------------------
;forths inner interpret (erm compiler :) loop

colon '(quit)', pquit
  dd lbracket               ;state off
  dd rp0, rpstore           ;reset stack pointers
  dd sp0, spstore
  dd dobegin
.L0:
  dd dotstatus, dotok       ;display status and ok message (maybe)
  dd interpret              ;interpret user input
  dd doagain, .L0
  dd exit                   ;this should never get executed

;-------------------------------------------------------------------------
;displays errant line number ONLY if we are aborting an fload

code '.line#', dotl
  call dodefer              ;its an extension in src/isforth.f
  dd noop

; ------------------------------------------------------------------------

colon '(abort)', pabort
  dd dotl                   ;kludgy but it works
  dd dobegin
.L0:
  dd floads, fetch          ;close all in progress floads
  dd qwhile, .L1
  dd abortfload
  dd dorepeat, .L0

.L1:
  dd numtib, off            ;flush input on abort
  dd toin, off
  dd qok, off               ;no ok message
  dd quit
  dd exit

;=========================================================================
