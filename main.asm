   DEVICE ZXSPECTRUM48

   org $8000 ; lowest place in memory that we can place our code. We can use 32k from here.

; Needed for DeZog https://github.com/maziac/DeZog/blob/main/documentation/Usage.md#launchjson
start:
  ld a, 1+4+16+64
  ld hl, $4000
  ret

   ; 
   ; to run the SNA, open the zesarus emulator
   ; then press F5 
   ; choose 'smart load'
   ; and navigate to the directory where the sna is
   ; then run it
   SAVESNA "hello.sna", start ; label to start the programme running from

; Needed for dezog
;===========================================================================
; Stack.
;===========================================================================


; Stack: this area is reserved for the stack
STACK_SIZE: equ 100    ; in words


; Reserve stack space
    defw 0  ; WPMEM, 2
stack_bottom:
    defs    STACK_SIZE*2, 0
stack_top:
    ;defw 0
    defw 0  ; WPMEM, 2
