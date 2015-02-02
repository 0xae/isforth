\ variable.f    - isforth constant and variable compilation words etc
\ -------------------------------------------------------------------------

  .( loading variable.f ) cr

\ -------------------------------------------------------------------------

  compiler definitions

\ -------------------------------------------------------------------------
\ compile new constant into dictionary

: constant      ( n1 --- )
  head,                     \ create header for new constant
  ,call doconstant          \ compile call to doconstant in new words cfa
  , reveal ;                \ compile n1 into body of constant

\ ------------------------------------------------------------------------
\ new definition for variable  - see note below

  ' constant alias var

\ -------------------------------------------------------------------------
\ new definition for constant

: const     ( n1 --- )
  create, immediate         \ create const, compile n1 into its body
  does>                     \ patch cfa of new const to do the following
    @ ?comp# ;              \ compile or return number based on state

\ var and const are my new definitions for variable and constant
\ renamed so as to not cause conflicts with existing code.  you
\ will notice the lack of the definition for 'value' which in my
\ opinion is a very badly named word which like all ans inventions
\ totally fails to describe its function.
\
\ my const definition is state smart.  if you are in compile mode
\ it will compile a literal into the : definition you are compiling.
\ if you are in interpret mode it will return the body field contents
\ as usual
\
\ !> const will work of corse but doing this is heavilly frowned upon
\
\ if you ask me this is the way variable and constant should have
\ worked from day one.

\ ------------------------------------------------------------------------
\ create a new variable definition

: variable ( --- )
  create 0 , ;

\ ------------------------------------------------------------------------
\ return body address and state

: ttbsf         ( --- a1 state )
  ' >body                   \ get body filed addr of word specified in tib
  state @ ;                 \ get current compile/interpret state

\ ------------------------------------------------------------------------
\ store n1 in body of var/constant or defered word

: !>        ( n1 --- )
  ttbsf                     \ get address if word to modify and get state
  if                        \ if we are in compile mode
    compile %!> ,           \ compile a %!> and , that address
  else
    !                       \ else store n1 at body field address
  then ; immediate

\ ------------------------------------------------------------------------
\ dont define too many aliases, its bad style

  ' !> alias is

\ ------------------------------------------------------------------------
\ add n1 to body of var/constant or defered word

: +!>       ( n1 --- )
  ttbsf                     \ get body address and state
  if                        \ compile mode ?
    compile %+!> ,          \ yes
  else
    +!                      \ no
  then ; immediate

\ ------------------------------------------------------------------------
\ increment body of var/constant

: incr>     ( --- )
  ttbsf
  if
    compile %incr> ,
  else
    incr
  then ; immediate

\ ------------------------------------------------------------------------
\ decrement body of var/constant

: decr>     ( --- )
  ttbsf
  if
    compile %decr> ,
  else
    decr
  then ; immediate

\ ------------------------------------------------------------------------
\ set body of constant to -1/on/true

: on>       ( --- )
  ttbsf
  if
    compile %on> ,
  else
    on
  then ; immediate

\ ------------------------------------------------------------------------
\ set body of var/constant to 0/off/false

: off>      ( --- )
  ttbsf
  if
    compile %off> ,
  else
    off
  then ; immediate

\ ------------------------------------------------------------------------

 forth definitions

\ ========================================================================
