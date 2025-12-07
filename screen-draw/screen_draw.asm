; ZX Spectrum screen drawing program
; Draws 0101010101010101 pattern (0x55) to all 6144 screen bytes
; Screen memory starts at 0x4000 and is 6144 bytes (32*192 bytes)

        DEVICE ZXSPECTRUM48

        ORG 0x8000      ; Start program at 32768

hello: DEFB "hello"
hello_len = 5

print_string:
        ; print hello message
        LD DE, hello
        LD C, hello_len
print_loop:
        LD A, (DE)
        CALL 0x10A8       ; Call ROM routine to print character in A
        INC DE
        DEC C
        CALL delay_loop
        JP NZ, print_loop
        CALL delay_loop
        RET

start:
        CALL print_string
        CALL delay_loop
        ; draw pattern to screen
        LD HL, 0x4000   ; Point HL to start of screen memory
        LD BC, 6144     ; Set counter to 6144 bytes (screen size)

fill_loop:
        LD A, 0x55      ; Load pattern 01010101 into A
        LD (HL), A      ; Store pattern at memory location pointed by HL
        INC HL          ; Move to next memory location
        DEC BC          ; Decrement counter
        LD A, B         ; Check if BC = 0
        OR C
        
        JR NZ, fill_loop ; If not zero, continue loop

        RET             ; Return to BASIC

delay_loop:
        PUSH BC
        LD BC, 5000     ; Arbitrary delay count
delay_inner:
        DEC BC
        LD A, B
        OR C
        JR NZ, delay_inner
        POP BC
        RET

; now save the program to a file
; using ZX Spectrum tape format (SNA)
        SAVESNA "screen_draw.sna", start
        END start
