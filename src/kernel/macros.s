;macros.1       - isforth macro definitions
;-------------------------------------------------------------------------

%xdefine imm 0              ;set to $40 to make next word immediate

%xdefine vlink 0            ;link to previous word in vocabulary

%xdefine forth_link 0       ;link to previous word in forth vocab
%xdefine comp_link 0        ;link to previous word in compiler vocab
%xdefine root_link 0        ;link to previous word in root vocab

%xdefine voc 0              ;currently linking to forth vocabulary

; ------------------------------------------------------------------------
; debugg verion must be jump next

;%define inline              ;comment out for jump next

;-------------------------------------------------------------------------
;define 'next' macro

%ifdef inline
  %macro next 0.nolist
   lodsd                    ;get next execution token
   jmp eax                  ;execute it
  %endmacro
%else
  %macro next 0.nolist
   jmp _next
  %endmacro
%endif

;-------------------------------------------------------------------------
;macro to make next assembled word an immediate word

;this is the reverse of how forth actually does it.  forth makes the
;previously defined word immedite not the next

%macro _immediate_ 0.nolist
 %xdefine imm 040h
%endmacro

;-------------------------------------------------------------------------
;macro to flag following word as headerless

%macro _noname_ 0.nolist
 dd 0                       ;null nfa pointer at cfa -4
%endmacro

;-------------------------------------------------------------------------
;sub macro to compile headers for forth words.

%macro header 2.nolist
[section headers] 
 dd vlink                   ;link to previous word in vocabulary
%%link:
%xdefine vlink %%link
 db (%%name-$-1)+imm        ;name length + flags
 db %1                      ;name
%%name:
 dd %2                      ;pointer to cfa (in .data section)
%xdefine imm 0
;__SECT__
section list
 dd %%link                  ;cfa -4 points to nfa
%endmacro

;-------------------------------------------------------------------------
;macro - compile a header in head space for a coded definition

%macro code 2.nolist
 header %1,%2               ;create header in head space
%2:                         ;make label for new coded definition
%endmacro

;-------------------------------------------------------------------------
;macro - compile a header in head space for a high level definition

%macro colon 2.nolist
 header %1,%2               ;create header which will point at
%2:                         ;this label as its code vector
 call nest                  ;which calls the function to interpret
%endmacro                   ;what ever is assembled after this macro

;-------------------------------------------------------------------------
;macro - construct a forth variable

%macro _variable_ 3.nolist  ;usage: var 'name',name,value
 code %1,%2
 call dovariable
 dd %3
%endmacro

;-------------------------------------------------------------------------
;macro - construct a forth constant

%macro _constant_ 3.nolist  ;usage: const 'name',name,value
 code %1,%2
 call doconstant
 dd %3
%endmacro

;-------------------------------------------------------------------------
;macro - create a syscall word

%macro _syscall_ 4.nolist
 code %1,%2
 call do_syscall
 db %3,%4
%endmacro

;-------------------------------------------------------------------------
;save voclink to current vocabs link variable

%macro save_link 0.nolist
 %if(voc = 0)               ;were we linking on the forth vocabulary ?
  %xdefine forth_link vlink ;yes - set new end of forth vocab
 %elif(voc = 1)             ;were we linking on the compiler vocabulary ?
  %xdefine comp_link vlink  ;yes - set new end of compiler vocab
 %else
  %xdefine root_link vlink  ;musta been root vocab then. set new end
 %endif
%endmacro

;-------------------------------------------------------------------------
;link all new definitions to the forth vocabulary

%macro _forth_ 0.nolist
 save_link                  ;save link address of previous vocabulary
 %xdefine vlink forth_link  ;start linking on forth vocabulary
 %define voc 0
%endmacro

;-------------------------------------------------------------------------
;link all new definitions to the compiler vocabulary

%macro _compiler_ 0.nolist
 save_link                  ;save link address of previous vocabulary
 %xdefine vlink comp_link   ;start linking on compiler vocabulary
 %define voc 1
%endmacro

;-------------------------------------------------------------------------
;link all new definitions to the root vocabulary

%macro _root_ 0.nolist
 save_link                  ;save link address of previous vocabulary
 %xdefine vlink root_link   ;start linking on root vocabulary
 %xdefine voc 2
%endmacro

;=========================================================================
