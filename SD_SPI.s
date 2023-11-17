    .org $8000

	.include ACIA.s
	.include macros.s
	.include VIA.s
	.include SPILib.s

SPIDATA = $0000

reset:

	ldx #$ff
	txs

	sei

	;jsr ACIAInit

	jsr VIA_output_all
	;jsr VIA_T1_continous_interrupts
	
	; jsr ACIAWaitRx
	; ldptr testmessage, stringptr
	; jsr PrintString
	;cli

	jsr spi_idle    	; set spi to the idle state
	jsr small_delay     ; add a small delay 
	

main:

	jsr spi_sd_init
	jsr small_delay

	lda PORTA
    and #~BIT2
    sta PORTA ; set the cs to low
	
	lda #%01000000
	sta SPIDATA
	jsr transmit_spi

	lda #%00000000
	sta SPIDATA
	jsr transmit_spi

	lda #%00000000
	sta SPIDATA
	jsr transmit_spi

	lda #%00000000
	sta SPIDATA
	jsr transmit_spi

	lda #%00000000
	sta SPIDATA
	jsr transmit_spi

	lda #$95
	sta SPIDATA
	jsr transmit_spi

	jsr spi_clock_frame
	jsr spi_clock_frame
	
	lda PORTA
    eor #BIT2
    sta PORTA ; set the cs to high

end:
	jmp end

base_delay:
	ldx #0
	ldy #0
base_loop:
	dey
	bne base_loop
	dex
	bne base_loop
	rts

small_delay:
	jsr base_delay
	jsr base_delay
	jsr base_delay
	jsr base_delay
	jsr base_delay
	jsr base_delay
	jsr base_delay
	jsr base_delay
	rts

testmessage: .asciiz "R A I N B O W !"

nmi:
exitnmi:
	rti	
irq:
	save_stack
	
	lda IFR
	and #%11000000
	beq exitirq ; if the interupt was not caused by T1 on the VIA, then exit

	lda T1CL
	lda PORTA
	EOR #$1
	sta PORTA	
exitirq:
	
	restore_stack
	
	rti

	.org $fffa
	.word nmi
	.word reset
	.word irq
