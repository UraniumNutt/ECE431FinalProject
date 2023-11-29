transmit_spi:

	ldx #8 ; counter for the number of times to shift the byte

    ; lda PORTA
    ; and #~BIT2
    ; sta PORTA ; set the cs to low

spi_bit_loop:

    lda PORTA
	ora #BIT1 ; set the data to high
    and #~BIT0 ; set the clock low
	sta PORTA 

	; set up the data
	lda SPIDATA
	and #BIT7
	beq spi_bit_zero
	lda #BIT1
	ora PORTA
	jmp spi_bit_write
spi_bit_zero:
	lda #~BIT1
	and PORTA
spi_bit_write:
	sta PORTA

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    lda PORTA
    ora #BIT0 ; set the clock to high
	sta PORTA 

	lda SPIDATA
	clc
	asl
	sta SPIDATA ; shift the data byte


	dex         ; decrement the counter of the number of shifts remaining
	bne spi_bit_loop ; if the counter is not zero, repeat the loop

    lda PORTA
	ora #BIT1
	sta PORTA ; set the data to high

    ; lda PORTA
    ; ora #BIT2
    ; sta PORTA ; set the cs to high

	rts

spi_sd_init:

    ldx #255
sd_init_loop:
    lda #BIT0
    eor PORTA
    sta PORTA
    dex
    bne sd_init_loop
    lda #BIT0
    ora PORTA
    sta PORTA
    rts

spi_clock_frame:

    ldx #16
spi_clock_frame_loop:
    nop
    nop
    nop
    lda #BIT0
    eor PORTA
    sta PORTA
    dex
    bne spi_clock_frame_loop
    lda #BIT0
    ora PORTA
    sta PORTA
    rts

spi_idle:

    lda PORTA
    ora #BIT2 ; chip select -> 1
    ora #BIT1 ; data -> 1
    ora #BIT0 ; clk -> 1
    sta PORTA

    rts
