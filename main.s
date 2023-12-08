    .org $8000    
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
fsm_state = $20                           ; reserve space for the finite state machine state
     
reset     
     
    ldx #$ff                             ; set up the stack
    txs         
    sei     
    jsr ACIAInit                         ; init the UART
    lda #%11110111                       ; set the VIA pins to output, except for bit3, which is for miso
    sta DDRA     
     
    jsr ACIAByteIn                       ; wait for the user to press a key to make sure the serial session is established    
    jsr spi_idle                         ; set spi to the idle state
    lda #'q'                             ; set the state of the fsm to querry
    sta fsm_state             
     
    ldptr startmessage, stringptr        ; starting message
    jsr print_string     
    jsr print_new_line         
    ldptr welcomemessage, stringptr      ; welcome message
    jsr print_string     
    jsr clk_pump                         ; 'pump' the clock to go into spi mode
    jsr spi_active                       ; activate the card
     
    ldptr cmd0, spi_buffer               ; initialize the card
    jsr spi_sd_send_command    
    ldptr cmd8, spi_buffer               ; check the voltage range (dont use result)
    jsr spi_sd_send_command     
    jsr spi_read_byte                    ; this command returns a 32 bit value, but we dont need it
    jsr spi_read_byte     
    jsr spi_read_byte     
    jsr spi_read_byte         
    ldptr cardinitmesg, stringptr     
    jsr print_string         
    jsr sd_card_init                     ; 'Initiate initalization process' waits until return code = 0x00
    ldptr initsuccess, stringptr         ; Initalization succsessful 
    jsr print_string     
     
main                                     ; jumps to diffrent parts of the program based on the state
    lda fsm_state                        ; loads the state
    cmp #'d'                             ; jump to the hex_dump if it is 'd'
    bne .not_hex_dump     
    jmp hex_dump     
.not_hex_dump     
    cmp #'h'                             ; jump to the hex_write if it is 'h'
    bne .not_hex_write     
    jmp hex_write     
.not_hex_write     
    cmp #'a'                             ; jump to the ascii_dump if it is 'a'
    bne .not_ascii_dump     
    jmp ascii_dump     
.not_ascii_dump     
    cmp #'w'                             ; jump to the ascii_write if it is 'w'
    bne .not_ascii_write     
    jmp ascii_write     
.not_ascii_write     
    cmp #'q'                             ; jump to the querry if it is 'q'
    bne .not_querry     
    jmp querry     
.not_querry                              ; otherwise, jump to the unknown state
    jmp unknown

hex_dump                                 ; preformes a hex dump
    ldptr hex_dump_message, stringptr    ; prints the hex dump text
    jsr print_string 
     
    ldptr startingread, stringptr        ; starting the read
    jsr print_string     
    
    ldptr cmd17, spi_buffer              ; load cmd17 into the spi buffer
    jsr spi_sd_send_command              ; send the command in the buffer
    ldptr dumpmesg, stringptr 
    jsr print_string                     
    jsr spi_sd_read_sector               ; read the sector into the buffer
    jsr dump_sector                      ; print the buffer in hex
 
    lda #'q'                             ; next state is querry
    sta fsm_state 
    jmp main                             ; return to main
 
hex_write                                ; hex editor, not implemented
    ldptr hex_write_message, stringptr
    jsr print_string
    ; do stuff here
    lda #'q'                             ; next state is querry
    sta fsm_state
    jmp main

ascii_dump                               ; dump the sector in ascii
 
    ldptr acsii_dump_message, stringptr  ; ascii dump message
    jsr print_string 
    ldptr startingread, stringptr        ; starting read operation
    jsr print_string 
 
    ldptr cmd17, spi_buffer              ; load cmd17 into spi buffer
    jsr spi_sd_send_command              ; send the command in the buffer
    jsr spi_sd_read_sector               ; read the sector into the buffer
    jsr dump_sectorASCII                 ; print the contents of the buffer in ascii
 
    lda #'q'                             ; next state is querry
    sta fsm_state 
    jmp main                             ; return to main
 
ascii_write                              ; write the ascii string onto the sector

    ldptr ascii_write_message, stringptr ; write message string
    jsr print_string
    ldptr stringprompt, stringptr        ; prompts the user for the string
    jsr print_string    

    ldptr STRINGBUFFER, stringptr        ; sets the string pointer to the buffer used for input
    jsr input_string                     ; gets the input from the user
    ldptr STRINGBUFFER, stringptr        ; (re)sets the string pointer to the buffer used for input
    jsr spi_write_string                 ; writes the string in the buffer to the buffer for the sector
    ldptr cmd24, spi_buffer              ; sends the command for writing a sector to the card
    jsr spi_sd_send_command              ; writes the internal buffer to the card
    jsr spi_write_sector

    jsr get_return_code                  ; read the 16 bit crc (dont do anything with it)
    jsr get_return_code

.busy                                    ; wait until the card has finished the write operation 
    jsr spi_read_byte
    cmp #$00                             ; a status of 0x00 is busy
    beq .busy    
    ldptr donewriting, stringptr         ; print that the write operation finished
    jsr print_string    

    lda #'q'                             ; next state is querry        
    sta fsm_state
    jmp main                             ; return to main

querry                                   ; ask the user what they want do do
    ldptr querry_prompt, stringptr       ; give the user the options for the querry
    jsr print_string
    ldptr querry_message, stringptr      ; ask them for their querry
    jsr print_string
    ldptr STRINGBUFFER, stringptr        ; set the stringptr to the buffer used for input 
    jsr input_string                     ; get the input
    lda (stringptr)                      ; get the first char of the querry
    cmp #'d'                             ; if it is any of these letters, it is a valid querry
    beq .valid
    cmp #'h'
    beq .valid
    cmp #'a'
    beq .valid
    cmp #'w'
    beq .valid
    lda #'u'                             ; if it is none of those, it is an unknown querry
.valid
    sta fsm_state                        ; set the fsm state again
.exit
    jmp main                             ; return to main

unknown                                  ; informs the user that the option they chose 
    ldptr unknown_message, stringptr     ; prints the message
    jsr print_string
    lda #'q'                             ; sets the state to querry
    sta fsm_state
    jmp main                             ; returns to main

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
