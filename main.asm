   DEVICE ZXSPECTRUM48

   org $8000
start:
   jp print_hello

; Character Codes
ENTER       equ $0D

; ROM routines
ROM_CLS     equ $0DAF
ROM_PRINT   equ $203C

NUMBER_PRINT equ $1A1B

hello:
   db "Hello, World!", ENTER
HELLO_LEN   equ $ - hello

print_hello:
    call ROM_CLS
    ld a, 27
    ld c, -2
    sub a, c
    ld bc, (a)
    call NUMBER_PRINT
    ret

; Deployment
LENGTH      equ $ - start

   ; option 2: snapshot
   ; to run the SNA, open the zesarus emulator
   ; then press F5 
   ; choose 'smart load'
   ; and navigate to the directory where the sna is
   ; then run it
   SAVESNA "hello.sna", start
