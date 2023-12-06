SPIBUFFER = $10

SCK = BIT0
MOSI = BIT1
CS = BIT2
MISO = BIT3

transmit_spi:

	ldx #8 ; counter for the number of times to shift the byte

spi_bit_loop:

    lda PORTA
	ora #MOSI ; set the data to high
    and #~SCK ; set the clock low
	sta PORTA 

	; set up the data
	lda SPIDATA
	and #BIT7
	beq spi_bit_zero
	lda #MOSI
	ora PORTA
	jmp spi_bit_write
spi_bit_zero:
	lda #~MOSI
	and PORTA
spi_bit_write:
	sta PORTA


    lda PORTA
    ora #SCK ; set the clock to high
	sta PORTA 

	lda SPIDATA
	clc
	asl
	sta SPIDATA ; shift the data byte

	dex         ; decrement the counter of the number of shifts remaining
	bne spi_bit_loop ; if the counter is not zero, repeat the loop

    lda PORTA
	ora #MOSI
	sta PORTA ; set the data to high

	rts

spi_read_byte:
    ldx #8
    ;jsr spi_active
spi_read_byte_loop:
    lda PORTA
    and #~SCK ; clock low
    sta PORTA 
    lda PORTA
    ora #SCK ; clock high
    sta PORTA 

    lda PORTA
    and #MISO

    clc
    beq notset
    sec
notset:

    tya
    rol
    tay

    dex
    bne spi_read_byte_loop
    tya

    ;jsr spi_inactive

    rts

spi_sd_send_command:
    ;jsr spi_active
    jsr spi_clock_frame
    ldy #0
spi_sd_send_command_loop:
    lda (SPIBUFFER),y
    jsr PrintHex
    sta SPIDATA
    jsr transmit_spi
    iny
    lda #' '
    jsr ACIAByteOut
    tya
    cmp #6
    bne spi_sd_send_command_loop
    ;jsr wait
    ldptr returncodemesg, stringptr
	jsr PrintString
	jsr get_return_code
    pha
	jsr PrintHex
	jsr PrintNewLine
    pla
    ;jsr spi_inactive
    rts

get_return_code:
    jsr wait
    jsr spi_read_byte
    cmp #$ff
    beq get_return_code
    rts

spi_sd_read_sector:
    jsr spi_clock_frame
    jsr spi_clock_frame
    jsr spi_clock_frame
    ldy #8
    ldx #32
read_sector_loop:
    phy
    phx
    jsr spi_read_byte
    jsr PrintHex
    lda #' '
    jsr ACIAByteOut
    jsr spi_read_byte
    jsr PrintHex
    lda #' '
    jsr ACIAByteOut
    plx
    ply
    dey
    bne read_sector_loop
    ldy #8
    phy
    jsr PrintNewLine
    ply
    dex
    bne read_sector_loop
    rts


spi_sd_init:

    ldx #255
sd_init_loop:
    lda #SCK
    eor PORTA
    sta PORTA
    dex
    bne sd_init_loop
    lda #SCK
    ora PORTA
    sta PORTA
    rts

spi_clock_frame:

    ldx #16
spi_clock_frame_loop:
    nop
    nop
    nop
    lda #SCK
    eor PORTA
    sta PORTA
    dex
    bne spi_clock_frame_loop
    lda #SCK
    ora PORTA
    sta PORTA
    rts

spi_idle:

    lda PORTA
    ora #CS ; chip select -> 1
    ora #MOSI ; data -> 1
    ora #SCK ; clk -> 1
    sta PORTA

    rts

spi_active:
    lda PORTA
    and #~CS
    sta PORTA ; set the cs to low
    rts

spi_inactive:
    lda PORTA
    ora #CS
    sta PORTA ; set the cs to high
    rts

wait:
	ldx #255
waitloop:
	nop
	nop
	nop
	nop
	dex
	bne waitloop
	rts

debugmesg:
	.asciiz "A bit was detected! \r\n"
sequencemesg:
	.asciiz "Printing SPI sequences: \r\n"
returncodemesg:
	.asciiz " Command return code: "

cmd0:
	.byte $40, $00, $00, $00, $00, $95
cmd1:
	.byte $41, $00, $00, $00, $00, $96
cmd8:
	.byte $48, $00, $00, $01, $aa, $87
cmd9:
	.byte $49, $00, $00, $00, $00, $01
cmd17:
	.byte $51, $00, $00, $00, $00, $01
cmd55:
	.byte $77, $00, $00, $00, $00, $01
cmd41:
	.byte $69, $40, $00, $00, $00, $01