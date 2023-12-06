ACIA_base_address = $7e00

ACIADATA    = ACIA_base_address
ACIASTATUS  = ACIA_base_address + 1
ACIACOMMAND = ACIA_base_address + 2
ACIACONTROL = ACIA_base_address + 3

stringptr = $00f0

ACIAInit
    LDA #%00001011 ; init the 6551
    STA ACIACOMMAND
    LDA #%00000000
    STA ACIACONTROL
    RTS

ACIAWaitRx ; polls until byte has be recived, then returns

    lda ACIASTATUS
    and #%00001000 ; reciver full bit 
    beq ACIAWaitRx ; if not full, loop
    rts

ACIAWaitTx ; polls until byte has been trasmited, then returns

    lda ACIASTATUS
    and #%00010000 ; transmit empty bit
    beq ACIAWaitTx ; if not empty, loop
    rts

ACIAByteIn ; takes in one byte from the ACIA

    jsr ACIAWaitRx ; wait until there is a byte ready
    lda ACIADATA ; reads the byte
    rts

ACIAByteOut ; sends one byte from the ACIA

    pha ; save a
    jsr ACIAWaitTx ; wait until acia ready to transmit 
    pla ; restores a
    sta ACIADATA ; sends a out
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

