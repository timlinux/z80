; #ZX Spectrum screen drawing program
; Draws 0101010101010101 pattern (0x55) to all 6144 screen bytes
; Screen memory starts at 0x4000 and is 6144 bytes (32*192 bytes)

      DEVICE ZXSPECTRUM48

; Shadow buffer in high memory (above BASIC/variables)
SHADOW_SCREEN   EQU 0xA000      ; 6912 bytes needed (moved higher)
REAL_SCREEN     EQU 0x4000
SCREEN_SIZE     EQU 6912        ; 6144 pixels + 768 attributes

        ORG 0x8000              ; Load program at 32768

start:
        JP game_loop            ; Jump directly to main loop

; Draw a pixel to shadow buffer instead of real screen
; Input: B=Y coord, C=X coord, A=pixel pattern
draw_pixel_shadow:
    ; Calculate screen address in shadow buffer
    CALL calc_screen_addr       ; Returns HL = screen address
    LD DE, SHADOW_SCREEN - REAL_SCREEN
    ADD HL, DE                  ; Convert to shadow buffer address
    
    ; Set the pixel bit
    LD (HL), A
    RET

; Copy shadow buffer to real screen (page flip)
flip_screen:
    LD HL, SHADOW_SCREEN
    LD DE, REAL_SCREEN
    LD BC, SCREEN_SIZE
    LDIR                        ; Fast block copy
    RET

; Clear shadow buffer
clear_shadow:
    LD HL, SHADOW_SCREEN
    LD DE, SHADOW_SCREEN + 1
    LD BC, SCREEN_SIZE - 1
    LD (HL), 0
    LDIR                        ; Fill with zeros
    RET

; Simple sprite data (8x8 pixel block) - hollow square
sprite_data:
    DB 0xFF, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0xFF

; Draw sprites to shadow buffer
draw_sprites:
    ; Draw a simple sprite at center of screen
    LD B, 1                     ; Y coordinate (center: 192/2)
    LD C, 1  http://localhost:5173/properties http://localhost:5173/properties                  ; X coordinate (byte boundary)
    LD HL, sprite_data          ; Point to sprite data
    LD D, 8                     ; 8 rows

draw_sprite_loop:
    PUSH BC                     ; Save coordinates
    PUSH HL                     ; Save sprite data pointer
    LD A, (HL)                  ; Get sprite row data
    CALL draw_pixel_shadow      ; Draw to shadow buffer
    POP HL                      ; Restore sprite data pointer
    POP BC                      ; Restore coordinates
    INC HL                      ; Next sprite row
    INC B                       ; Next Y coordinate
    DEC D                       ; Decrement row counter
    JR NZ, draw_sprite_loop     ; Continue if more rows
    RET

; Draw background pattern to shadow buffer
draw_background:
    ; Draw checkerboard pattern
    LD B, 0                     ; Start Y = 0

draw_bg_row:
    LD C, 0                     ; Start X = 0
    
draw_bg_col:
    ; Calculate checkerboard pattern
    LD A, B                     ; Get Y
    AND 0x08                    ; Check Y bit 3
    LD E, A                     ; Save Y pattern
    LD A, C                     ; Get X
    AND 0x08                    ; Check X bit 3
    XOR E                       ; XOR with Y pattern
    JR Z, draw_bg_black         ; Jump if 0
    LD A, 0x55                  ; Striped pattern
    JR draw_bg_pixel
    
draw_bg_black:
    LD A, 0xAA                  ; Different striped pattern
    
draw_bg_pixel:
    CALL draw_pixel_shadow      ; Draw to shadow
    INC C                       ; Next X
    LD A, C
    CP 32                       ; Check if end of row
    JR NZ, draw_bg_col          ; Continue row
    
    INC B                       ; Next Y
    LD A, B
    CP 192                      ; Check if end of screen
    JR NZ, draw_bg_row          ; Continue next row
    RET

; Check for keypress (CAPS SHIFT to exit)
check_input:
    ; Read keyboard row 0 (CAPS SHIFT - V)
    LD A, 0xFE                  ; Select row 0
    IN A, (0xFE)                ; Read keyboard
    BIT 0, A                    ; Test CAPS SHIFT (bit 0)
    RET Z                       ; Return with Z flag if pressed (exit)
    OR A                        ; Clear Z flag (continue)
    RET

; Double buffering game loop with input handling
game_loop:
    CALL check_input            ; Check for exit key
    RET Z                       ; Exit if CAPS SHIFT pressed
    
    CALL clear_shadow           ; Clear back buffer
    CALL draw_background        ; Draw to shadow buffer
    CALL draw_sprites           ; Draw to shadow buffer
    CALL flip_screen            ; Show completed frame
    
    ; Simple delay
    LD BC, 1000
delay_loop:
    DEC BC
    LD A, B
    OR C
    JR NZ, delay_loop
    
    JR game_loop

; Helper: Calculate screen address from coordinates
; Input: B=Y, C=X  Output: HL=screen address
calc_screen_addr:
    ; ZX Spectrum screen layout: Y7 Y6 Y5 Y4 Y3 Y2 Y1 Y0
    ; Screen address = 010Y7Y6Y5 Y2Y1Y0Y4Y3 XXXXX000
    LD A, B                    ; Get Y coordinate
    AND 0x18                   ; Extract Y7,Y6,Y5 (bits 5,4,3)
    OR 0x40                    ; Set bits 6,7 for screen area
    LD H, A                    ; High byte done
    
    LD A, B                    ; Get Y coordinate again
    AND 0x07                   ; Extract Y2,Y1,Y0 (bits 2,1,0)
    RLC A                      ; Shift left 3 positions
    RLC A
    RLC A
    LD D, A                    ; Save Y2Y1Y0 shifted
    
    LD A, B                    ; Get Y coordinate again
    AND 0xC0                   ; Extract Y4,Y3 (bits 7,6 originally bits 4,3)
    RRC A                      ; Shift right to correct position
    RRC A
    OR D                       ; Combine with Y2Y1Y0
    OR C                       ; Add X coordinate
    LD L, A                    ; Low byte done
    RET
; now save the program to a file
; using ZX Spectrum tape format (TAP)
        SAVETAP "screen_draw.tap", CODE, "screendraw", start, $-start, start
        END start
