    .include ACIA.s

STRINGBUFFER = $400

InputString           ; Allows the user to enter a string, loading it into the Stringptr
    ldy #$00          ; use y as an index
.loop
    jsr ACIAByteIn    ; get the byte from the user
    cmp #$7f          ; if they pressed backspace, jump to .backspace
    beq .backspace
    cmp #'\r'         ; if they pressed enter, jump to .enter
    beq .enter
    cpy #$ff          ; if y is 255, dont admit any more bytes,
    beq .loop
    sta (stringptr),y ; otherwise, put the byte in the buffer
    jsr ACIAByteOut   ; print the byte so the user can see what they type
    iny               ; and increment the y index
    jmp .loop         ; go back to the start of the loop

.backspace            ; if backspace was pressed ...
    cpy #$00          ; if the index is 0, then no chars have been typed, so go back to the loop
    beq .loop      
    dey               ; otherwise, decrement the index 
    lda #'\b'         ; move back one char
    jsr ACIAByteOut
    lda #' '          ; write a space over the old char
    jsr ACIAByteOut
    lda #'\b'         ; go back to the old chars position on the sceen
    jsr ACIAByteOut
    jmp .loop         ; go back to the loop
.enter                ; if enter was pressed ...
    lda #'\r'         ; return the carriage to the begining of the line
    jsr ACIAByteOut
    lda #'\n'         ; and go to the next line
    jsr ACIAByteOut
    lda #'\0'         ; make sure the string is null terminated
    sta (stringptr),y
    rts


DumpSector
    ldx #$00
    ldy #16
.loop
    lda BLOCKBUFFERLOW,x
    jsr PrintHex
    lda #' '
    jsr ACIAByteOut
    dey
    bne .no_new_line
    jsr PrintNewLine
    ldy #16
.no_new_line
    inx
    bne .loop
    
HighSector
    ldx #$00
    ldy #16
.loop
    lda BLOCKBUFFERHIGH,x
    jsr PrintHex
    lda #' '
    jsr ACIAByteOut
    dey
    bne .no_new_line
    jsr PrintNewLine
    ldy #16
.no_new_line
    inx
    bne .loop
    rts

DumpSectorASCII
    ldx #$00
.loop
    lda BLOCKBUFFERLOW,x
    jsr ACIAByteOut
    inx
    bne .loop
HighSectorASCII
    ldx #$00
.loop
    lda BLOCKBUFFERHIGH,x
    jsr ACIAByteOut
    inx
    bne .loop
    rts   

PrintHex

    pha ; save a to the stack
    lda #'0'
    jsr ACIAByteOut
    lda #'x'
    jsr ACIAByteOut
    pla ; load a from the stack
    pha ; save it again
    pha ; and again
    ror
    ror
    ror
    ror
    jsr HexDigitConverter
    pla ; pull it again
    jsr HexDigitConverter
    ;jsr PrintNewLine
    pla ; pull it one last time, so a is not clobbered when returning
    rts

HexDigitConverter

    clc
    and #$f ; make out the upper nibble
    cmp #10 ; if it is 10 or greater it is a letter
    bmi letter
    adc #6
letter
    adc #48
    jsr ACIAByteOut
    rts

PrintString ; print the sting at the specified pointer

    phy
    ldy #0
PrintStringLoop
    lda (stringptr),Y
    beq PrintStringExit
    jsr ACIAByteOut
    iny
    jmp PrintStringLoop

PrintStringExit
    ply
    rts

PrintNewLine

    lda #<NewLine
    sta stringptr
    lda #>NewLine
    sta stringptr + 1

    jsr PrintString
    rts

NewLine: 
    .asciiz "\r\n"