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
	jsr ACIAInit
	jsr VIA_output_all
	jsr ACIAWaitRx

	jsr spi_idle    	; set spi to the idle state
	
main:

	ldptr startmessage, stringptr
	jsr PrintString
	jsr PrintNewLine
	ldptr sequencemesg, stringptr
	jsr PrintString

	jsr spi_sd_init

	jsr spi_active
	
	ldptr cmd0, SPIBUFFER
	jsr spi_sd_send_command

	ldptr cmd8, SPIBUFFER
	jsr spi_sd_send_command
	jsr spi_read_byte
	jsr spi_read_byte
	jsr spi_read_byte
	jsr spi_read_byte

cardinitloop
	
	jsr wait
	ldptr cmd55, SPIBUFFER
	jsr spi_sd_send_command
	
	ldptr cmd41, SPIBUFFER
	jsr spi_sd_send_command
	cmp #$00
	bne cardinitloop
	ldptr initsuccess, stringptr
	jsr PrintString

	ldptr startingread, stringptr
	jsr PrintString

	ldptr cmd17, SPIBUFFER
	jsr spi_sd_send_command

	ldptr dumpmesg, stringptr
	jsr PrintString

	jsr spi_clock_frame
	jsr spi_sd_read_sector

	jsr spi_inactive
	jsr spi_idle


end:
	jmp end 

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

startmessage:
	.asciiz "Debugging SPI: \r\n"
dumpmesg:
	.asciiz "Dumping contents of first sector (512 Bytes): \r\n"
startingread:
	.asciiz "Starting CMD17!\r\n"
cardinitmesg:
	.asciiz "Entering initalization loop until 0x00 is returned.\r\n"
initsuccess:
	.asciiz "Initalization success!\r\n"


nmi:
exitnmi:
	rti	
irq:
	save_stack
exitirq:
	
	restore_stack
	rti

	.org $fffa
	.word nmi
	.word reset
	.word irq
