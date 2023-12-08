SPIBUFFER = $10
BLOCKBUFFERLOW = $200
BLOCKBUFFERHIGH = BLOCKBUFFERLOW + $100
SCK = BIT0
MOSI = BIT1
CS = BIT2
MISO = BIT3

transmit_spi:

    phx
	ldx #8 ; counter for the number of times to shift the byte

spi_bit_loop:

    lda PORTA
	ora #MOSI ; set the data to high
    and #~SCK ; set the clock low
	sta PORTA 

	; set up the data
	tya ; transfer the data passed in the y regsiter to the a register
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

	tya ; pull the data from y into a again
	clc
	asl
	tay ; shift the data byte, store it back in y

	dex         ; decrement the counter of the number of shifts remaining
	bne spi_bit_loop ; if the counter is not zero, repeat the loop

    lda PORTA
	ora #MOSI
	sta PORTA ; set the data to high
    plx
	rts

spi_read_byte:
    phx
    ldx #8
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

    plx
    rts

spi_sd_send_command:
    jsr spi_clock_frame
    ldy #0
spi_sd_send_command_loop:
    lda (SPIBUFFER),y
    phy
    tay
    jsr transmit_spi
    ply
    iny
    tya
    cmp #6
    bne spi_sd_send_command_loop
	jsr get_return_code
    rts

get_return_code:
    jsr wait
    jsr spi_read_byte
    cmp #$ff
    beq get_return_code
    rts

spi_sd_read_sector:
    jsr spi_read_byte
    cmp #$fe
    bne spi_sd_read_sector
    ldx #$00
read_sector_low:
    jsr spi_read_byte
    sta BLOCKBUFFERLOW,x
    inx
    bne read_sector_low
    ldx #$00
read_sector_high:
    jsr spi_read_byte
    sta BLOCKBUFFERHIGH,x
    inx
    bne read_sector_high
    jsr spi_read_byte
    jsr spi_read_byte
    rts

spi_write_sector ; writes the contents of BLOCKBUFFERLOW and BLOCKBUFFERHIGH to the sd card
    ;jsr get_return_code
    ldy #$fe
	jsr transmit_spi
    ldx #$00 ; load the x index with 0
.lowloop
    lda BLOCKBUFFERLOW,x
    tay
    jsr transmit_spi
    inx
    bne .lowloop
    ldx #$00
.highloop
    lda BLOCKBUFFERHIGH,x
    tay
    jsr transmit_spi
    inx
    bne .highloop
    rts



spi_write_string           ; takes a string, and puts its bytes in BLOCKBUFFERLOW
    ldy #$00               ; load the index with 0
.loop
    lda (stringptr),y      ; load from the stringptr
    cmp #$00               ; if at the end of the string, then exit
    beq .exit
    sta BLOCKBUFFERLOW,y ; store the char into the block buffer
    iny                    ; increment y to the next char
    jmp .loop              ; loop

.exit                      ; exit
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

sd_card_init
	
	jsr wait
	ldptr cmd55, SPIBUFFER
	jsr spi_sd_send_command
	
	ldptr cmd41, SPIBUFFER
	jsr spi_sd_send_command
	cmp #$00
	bne sd_card_init
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
cmd24:
    .byte $58, $00, $00, $00, $00, $01
cmd55:
	.byte $77, $00, $00, $00, $00, $01
cmd41:
	.byte $69, $40, $00, $00, $00, $01
