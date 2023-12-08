    .org $8000

	;.include ACIA.s
	.include macros.s
	.include VIA.s
	.include SPILib.s
	.include IO.s

reset:

	ldx #$ff
	txs

	sei
	jsr ACIAInit
	jsr VIA_output_all
	jsr ACIAByteIn  	; wait for the user to press a key to make sure the serial session is established

	jsr spi_idle    	; set spi to the idle state

	
main:

	ldptr startmessage, stringptr
	jsr PrintString
	jsr PrintNewLine

	jsr spi_sd_init
	jsr spi_active
	
	ldptr cmd0, SPIBUFFER
	jsr spi_sd_send_command

	ldptr cmd8, SPIBUFFER
	jsr spi_sd_send_command
	jsr spi_read_byte ; this command returns a 32 bit value, but we dont need it
	jsr spi_read_byte
	jsr spi_read_byte
	jsr spi_read_byte

	ldptr cardinitmesg, stringptr
	jsr PrintString

	jsr sd_card_init

	ldptr initsuccess, stringptr
	jsr PrintString

	ldptr startingread, stringptr
	jsr PrintString

	ldptr cmd17, SPIBUFFER
	jsr spi_sd_send_command

	ldptr dumpmesg, stringptr
	jsr PrintString

	jsr spi_sd_read_sector
	jsr DumpSector
	jsr DumpSectorASCII

	ldptr finished, stringptr
	jsr PrintString

	ldptr stringprompt, stringptr
	jsr PrintString

	ldptr STRINGBUFFER, stringptr
	jsr InputString
	ldptr STRINGBUFFER, stringptr
	jsr spi_write_string
	ldptr reprintingbuffer, stringptr
	jsr PrintString
	jsr DumpSectorASCII

	ldptr cmd24, SPIBUFFER
	jsr spi_sd_send_command
	jsr PrintHex

	jsr spi_write_sector
	jsr get_return_code
	jsr PrintHex
	jsr get_return_code
	jsr PrintHex

busy
	jsr spi_read_byte
	cmp #$00
	beq busy

	ldptr donewriting, stringptr
	jsr PrintString

	jsr spi_inactive
	jsr spi_idle


end:
	jmp end 


startmessage:
	.asciiz "SD Explorer: \r\n"
dumpmesg:
	.asciiz "Dumping contents of first sector (512 Bytes): \r\n"
startingread:
	.asciiz "Starting read sector operation.\r\n"
cardinitmesg:
	.asciiz "Starting initialization.\r\n"
initsuccess:
	.asciiz "Initialization successful!\r\n"
finished:
	.asciiz "\r\nFinished sector dump!\r\n"
stringprompt:
	.asciiz "\r\nEnter a string to dump onto the sector: "
reprintingbuffer:
	.asciiz "\r\nDumping new contents of block before writing: \r\n"
donewriting:
	.asciiz "\r\nFinished Write Operation!\r\n"



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
