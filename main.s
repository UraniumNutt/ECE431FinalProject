    .org $8000    
    ;.include ACIA.s
    .include macros.s
    .include VIA.s
    .include SPILib.s
    .include IO.s

	; hex dump (d)
	; hex write (h)
	; ascii dump (a)
	; ascii write (w)
	; mode querry (q)
	; unknown querry (u)
fsm_state = $20

    
reset

    ldx #$ff              ; set up the stack
    txs    
    sei
    jsr ACIAInit
    jsr VIA_output_all
    jsr ACIAByteIn      ; wait for the user to press a key to make sure the serial session is established    
    jsr spi_idle        ; set spi to the idle state
	lda #'q'
	sta fsm_state

	ldptr startmessage, stringptr
    jsr print_string
    jsr print_new_line    
	ldptr welcomemessage, stringptr
	jsr print_string
    jsr clk_pump
    jsr spi_active

    ldptr cmd0, spi_buffer
    jsr spi_sd_send_command    
    ldptr cmd8, spi_buffer
    jsr spi_sd_send_command
    jsr spi_read_byte ; this command returns a 32 bit value, but we dont need it
    jsr spi_read_byte
    jsr spi_read_byte
    jsr spi_read_byte    
    ldptr cardinitmesg, stringptr
    jsr print_string    
    jsr sd_card_init    
    ldptr initsuccess, stringptr
    jsr print_string

    
	; hex dump (d)
	; hex write (h)
	; ascii dump (a)
	; ascii write (w)
	; mode querry (q)
	; unknown querry (u)

main
	lda fsm_state
	cmp #'d'
	bne .not_hex_dump
	jmp hex_dump
.not_hex_dump
	cmp #'h'
	bne .not_hex_write
	jmp hex_write
.not_hex_write
	cmp #'a'
	bne .not_ascii_dump
	jmp ascii_dump
.not_ascii_dump
	cmp #'w'
	bne .not_ascii_write
	jmp ascii_write
.not_ascii_write
	cmp #'q'
	bne .not_querry
	jmp querry
.not_querry
	jmp unknown

hex_dump
	ldptr hex_dump_message, stringptr
	jsr print_string
	
	ldptr startingread, stringptr
    jsr print_string    
    ldptr cmd17, spi_buffer
    jsr spi_sd_send_command    
    ldptr dumpmesg, stringptr
    jsr print_string    
    jsr spi_sd_read_sector
    jsr dump_sector

	lda #'q' ; next state is querry
	sta fsm_state
	jmp main ; return to main

hex_write
	ldptr hex_write_message, stringptr
	jsr print_string
	; do stuff here
	lda #'q' ; next state is querry
	sta fsm_state
	jmp main

ascii_dump

	ldptr acsii_dump_message, stringptr
	jsr print_string
	
	ldptr startingread, stringptr
    jsr print_string    
    ldptr cmd17, spi_buffer
    jsr spi_sd_send_command     
    jsr spi_sd_read_sector
	jsr dump_sectorASCII

	

	lda #'q' ; next state is querry
	sta fsm_state
	jmp main

ascii_write
	ldptr ascii_write_message, stringptr
	jsr print_string

	ldptr stringprompt, stringptr
    jsr print_string    
    ldptr STRINGBUFFER, stringptr
    jsr input_string
    ldptr STRINGBUFFER, stringptr
    jsr spi_write_string 
    ldptr cmd24, spi_buffer
    jsr spi_sd_send_command    
    jsr spi_write_sector

	jsr get_return_code
    jsr get_return_code

.busy
    jsr spi_read_byte
    cmp #$00
    beq .busy    
    ldptr donewriting, stringptr
    jsr print_string    

	lda #'q' ; next state is querry
	sta fsm_state
	jmp main

querry
	ldptr querry_prompt, stringptr
	jsr print_string
	ldptr querry_message, stringptr
	jsr print_string
	ldptr STRINGBUFFER, stringptr
	jsr input_string
	lda (stringptr) ; get the first char of the querry
	cmp #'d'
	beq .valid
	cmp #'h'
	beq .valid
	cmp #'a'
	beq .valid
	cmp #'w'
	beq .valid
	lda #'u'
.valid
	sta fsm_state
.exit
	jmp main

unknown
	ldptr unknown_message, stringptr
	jsr print_string
	; do stuff here
	lda #'q'
	sta fsm_state
	jmp main




    
     
;     ldptr stringprompt, stringptr
;     jsr print_string    
;     ldptr STRINGBUFFER, stringptr
;     jsr input_string
;     ldptr STRINGBUFFER, stringptr
;     jsr spi_write_string
;     ldptr reprintingbuffer, stringptr
;     jsr print_string
;     jsr dump_sectorASCII    
;     ldptr cmd24, spi_buffer
;     jsr spi_sd_send_command
;     jsr print_hex    
;     jsr spi_write_sector
;     jsr get_return_code
;     jsr print_hex
;     jsr get_return_code
;     jsr print_hex

; busy
;     jsr spi_read_byte
;     cmp #$00
;     beq busy    
;     ldptr donewriting, stringptr
;     jsr print_string    
;     jsr spi_inactive
;     jsr spi_idle


end
    jmp end 


startmessage
    .asciiz "SD Explorer \r\n"
welcomemessage
	.asciiz "\r\nSD Explorer allows you to directly view and modifiy the first sector of an SD card!\r\n"
dumpmesg
    .asciiz "Dumping contents of first sector (512 Bytes) \r\n"
startingread
    .asciiz "Starting read sector operation.\r\n"
cardinitmesg
    .asciiz "Starting initialization.\r\n"
initsuccess
    .asciiz "Initialization successful!\r\n"
finished
    .asciiz "\r\nFinished sector dump!\r\n"
stringprompt
    .asciiz "\r\nEnter a string to dump onto the sector "
reprintingbuffer
    .asciiz "\r\nDumping new contents of block before writing \r\n"
donewriting
    .asciiz "\r\nFinished Write Operation!\r\n"

hex_dump_message
	.asciiz "Hex dump:\r\n"
hex_write_message
	.asciiz "Hex editor: \r\n"
acsii_dump_message
	.asciiz "ASCII dump: \r\n"
ascii_write_message
	.asciiz "ASCII writer: \r\n"
querry_message
	.asciiz "Enter option: "
querry_prompt
	.asciiz "\r\nOptions: hex (d)ump, (h)ex write, (a)scii dump, ascii (w)rite\r\n"
unknown_message
	.asciiz "Unknown option\r\n"

	; hex dump (d)
	; hex write (h)
	; ascii dump (a)
	; ascii write (w)
	; mode querry (q)
	; unknown querry (u)



nmi
exitnmi
    rti    
irq
    save_stack
exitirq

    restore_stack
    rti    
    .org $fffa
    .word nmi
    .word reset
    .word irq
