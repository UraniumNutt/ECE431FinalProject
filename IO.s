    .include ACIA.s

STRINGBUFFER = $400

input_string                ; Allows the user to enter a string, loading it into the Stringptr
    ldy #$00                ; use y as an index
.loop       
    jsr ACIAByteIn          ; get the byte from the user
    cmp #$7f                ; if they pressed backspace, jump to .backspace
    beq .backspace      
    cmp #'\r'               ; if they pressed enter, jump to .enter
    beq .enter
    cpy #$ff                ; if y is 255, dont admit any more bytes,
    beq .loop       
    sta (stringptr),y       ; otherwise, put the byte in the buffer
    jsr ACIAByteOut         ; print the byte so the user can see what they type
    iny                     ; and increment the y index
    jmp .loop               ; go back to the start of the loop
.backspace                  ; if backspace was pressed ...
    cpy #$00                ; if the index is 0, then no chars have been typed, so go back to the loop
    beq .loop           
    dey                     ; otherwise, decrement the index 
    lda #'\b'               ; move back one char
    jsr ACIAByteOut     
    lda #' '                ; write a space over the old char
    jsr ACIAByteOut     
    lda #'\b'               ; go back to the old chars position on the sceen
    jsr ACIAByteOut     
    jmp .loop               ; go back to the loop
.enter                      ; if enter was pressed ...
    lda #'\r'               ; return the carriage to the begining of the line
    jsr ACIAByteOut
    lda #'\n'               ; and go to the next line
    jsr ACIAByteOut
    lda #'\0'               ; make sure the string is null terminated
    sta (stringptr),y
    rts


dump_sector                 ; prints an entire sector in a hex dump format
    ldx #$00                ; load x with zero
    ldy #16                 ; load y with 16
.loop
    lda block_buffer_low,x  ; load from the low buffer
    jsr print_hex           ; print the byte in hex
    lda #' '                ; print a space
    jsr ACIAByteOut
    dey                     ; decrement y
    bne .no_new_line        ; if it is not zero, then dont print a new line
    jsr print_new_line      ; print a newline
    ldy #16                 ; reset y to 16
.no_new_line
    inx                     ; increment x
    bne .loop               ; if x has not rolled over, then loop
    
high_sector               
    ldx #$00                ; load x with 0
    ldy #16                 ; load y with 16
.loop
    lda block_buffer_high,x ; load the byte from the high buffer
    jsr print_hex           ; print it in hex
    lda #' '                ; print a space
    jsr ACIAByteOut
    dey                     ; decrement y
    bne .no_new_line        ; if it is not zero, dont pritn a new line
    jsr print_new_line
    ldy #16                 ; reset y to 16
.no_new_line
    inx                     ; increment x
    bne .loop               ; if it has not rolled over, loop
    rts

dump_sectorASCII            ; print an entire sector in ASCII
    ldx #$00                ; load x with 0
.loop
    lda block_buffer_low,x  ; load the byte from the low buffer
    jsr ACIAByteOut         ; print that byte
    inx                     ; increment x
    bne .loop               ; loop
high_sectorASCII
    ldx #$00                ; reset x to zero
.loop
    lda block_buffer_high,x ; load the byte from the high buffer
    jsr ACIAByteOut         ; print that byte
    inx                     ; increment the counter
    bne .loop               ; if the counter has not reached zero, loop
    jsr print_new_line
    rts   

                            ; NOTE: This subroutine is strongly based on the example code at: https://github.com/gfoot/sdcard6502/blob/master/src/4_readsector.s
print_hex                   ; prints the contents of the a register as hex

    pha                     ; save a to the stack
    ; lda #'0'                ; print '0'
    ; jsr ACIAByteOut
    ; lda #'x'                ; print 'x'
    ; jsr ACIAByteOut
    pla                     ; load a from the stack
    pha                     ; save it again
    pha                     ; and again
    ror                     ; mask the low nibble
    ror
    ror
    ror
    jsr hex_digit_converter ; print the low nibble
    pla                     ; pull it again
    jsr hex_digit_converter ; print the high nibble
    pla                     ; restore the a register
    rts

                            ; NOTE: This subroutine is strongly based on the example code at: https://github.com/gfoot/sdcard6502/blob/master/src/4_readsector.s
hex_digit_converter

    clc
    and #$f                 ; make out the upper nibble
    cmp #10                 ; if it is 10 or greater it is a .letter
    bmi .letter              
    adc #6                  ; add 6 to the nibble
.letter
    adc #48                 ; if it is a letter, add 48          
    jsr ACIAByteOut         ; print the ascii char
    rts

print_string                ; print the sting at the specified pointer

    phy                     ; save the y register
    ldy #0                  ; use it as an index, set it to zero
.loop
    lda (stringptr),y       ; load the string at the address of the pointer + the index
    beq .exit               ; if the char is zero, it is the end of the string
    jsr ACIAByteOut         ; if it is not the end of the string, print the char
    iny                     ; increment the index
    jmp .loop               ; loop

.exit
    ply                     ; restore the y register
    rts

print_new_line              ; prints a new line

    lda #'\r'            
    jsr ACIAByteOut
    lda #'\n'
    jsr ACIAByteOut
    rts