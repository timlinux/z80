   DEVICE ZXSPECTRUM48

   org $8000 ; lowest place in memory that we can place our code. We can use 32k from here.
 
   jp start

string:
  db "hello"

STRING_LENGTH=5

ROM_CLS     = $0DAF    ; ROM address for Clear Screen routine
COLOR_ATTR  = $5800    ; start of the colour attribute memory
ENTER       = $0D      ; Character code for the enter key
BLACK_WHITE = $47      ; Black paper, white ink

setpixel: ; input b= x coord, c = y coord
  ld a,b
  and $07
  ld d,a 
  ld l,b
  srl l
  srl l
  srl l
  ld a,c
  and $07
  or $40
  ld h,a
  ld a,c
  and $38
  sla a
  sla a
  or l
  ld l,a
  ld a,c
  and $C0
  srl a
  srl a
  srl a
  or h
  ld h,a
  ld a,$00
  scf

sp_loop:
  rra
  dec d
  jp p, sp_loop
  or (hl)
  ld (hl),a
  ret



; Needed for DeZog https://github.com/maziac/DeZog/blob/main/documentation/Usage.md#launchjson
start:
  im 1                 ; interrupt mode 1
  call ROM_CLS         ; clear screen (extended immediate addressing)
  ld hl, string        ; HL = address of string (register, extended immediate)
  ld b, STRING_LENGTH  ; (register, immediate)
loop:
  ld a, (hl)           ; a gets byte at address hl (register, register indirect)
  rst $10              ; print character code in A (modified page zero)
  inc hl               ; incrememt HL to the address of the next chart (register)
  dec b                ; decrement b (register)
  jp nz, loop
  ld a, ENTER
  rst $10
  ld b,10
  ld c,10
drawloop:
  jp setpixel
  dec c
  dec b
  jp nz, drawloop

  

  

 
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
