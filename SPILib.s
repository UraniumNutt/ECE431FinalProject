spi_buffer = $10
block_buffer_low = $200
block_buffer_high = block_buffer_low + $100
sck = BIT0
mosi = BIT1
cs = BIT2
miso = BIT3

spi_write_byte                      ; writes the byte stored in the y register
                         
    phx                             ; save the x register
    ldx #8                          ; counter for the number of times to shift the byte
 
.loop 
 
    lda PORTA 
    ora #mosi                       ; set the data to high
    and #~sck                       ; set the clock low
    sta PORTA   
                                    ; set up the data
    tya                             ; transfer the data passed in the y regsiter to the a register
    and #BIT7
    beq .zero                       ; if the bit is one, put it on the mosi
    lda #mosi
    ora PORTA
    jmp .write
.zero                               ; if it is, then put a zero on the mosi
    lda #~mosi
    and PORTA
.write
    sta PORTA                       ; write the bit to the port 
    lda PORTA
    ora #sck                        ; set the clock to high
    sta PORTA   
    tya                             ; pull the data from y into a again
    clc 
    asl
    tay                             ; shift the data byte, store it back in y   
    dex                             ; decrement the counter of the number of shifts remaining
    bne .loop                       ; if the counter is not zero, repeat the loop   
    lda PORTA
    ora #mosi
    sta PORTA                       ; set the data to high
    plx                             ; restore the x register before returning
    rts

                                    ; NOTE: This subroutine is strongly based on the example code at: https://github.com/gfoot/sdcard6502/blob/master/src/4_readsector.s

spi_read_byte                       ; reads one byte from spi, returns it in the a register
    phx                             ; save the state of the x register
    ldx #8                          ; use x as a counter, set it to 8
.loop                   
    lda PORTA                   
    and #~sck                       ; clock low
    sta PORTA                   
    lda PORTA                   
    ora #sck                        ; clock high
    sta PORTA                   

    lda PORTA                       ; load the bit after the positive clk edge
    and #miso                   

    clc                             ; set the carry bit to indicate that the bit was set
    beq .notset
    sec
.notset

    tya                             ; get the partial result from y
    rol                             ; roll it left
    tay                             ; put it back in y

    dex                             ; decrement the counter
    bne .loop                       ; if it is not zero, continue the loop
    tya                             ; load the result into a before returning

    plx                             ; restore the x register before returning
    rts

spi_sd_send_command                 ; sends an entire command of bytes from the spi buffer to the card
    jsr spi_clock_frame             ; send a filler byte before doing anything
    ldy #0                          ; use the y register as an index, set it to zero
.loop            
    lda (spi_buffer),y              ; load a with the address at spi_buffer + y
    phy                             ; save the index
    tay                             ; transfer a to y for the write subroutine
    jsr spi_write_byte              ; write the byte
    ply                             ; restore the index
    iny                             ; increment the index
    cpy #6                          ; if the index is less than 6, loop
    bne .loop
    jsr get_return_code             ; before returning, get the return code from the card
    rts

get_return_code                     ; gets the return code from a command, loads it in the a register
    jsr delay                       ; wait a few moments before reading
    jsr spi_read_byte               ; read from the card
    cmp #$ff                        ; if $ff was read, the card is idle (not ready to send the code)
    beq get_return_code             ; loop until the code is valid
    rts

spi_sd_read_sector                  ; read an entire sectore (512 bytes) from the card, loads it into the block buffers
    jsr spi_read_byte               ; read a byte
    cmp #$fe                        ; $fe indicates the card is about to send the data
    bne spi_sd_read_sector          ; if the byte read is not $fe, then continue to wait until the card is ready
    ldx #$00                        ; use the x register as a index, set it to zero
read_sector_low
    jsr spi_read_byte               ; read a byte
    sta block_buffer_low,x          ; store it into the low buffer base address + x
    inx                             ; increment the index
    bne read_sector_low             ; if the index is not zero (has not rolled over), loop
    ldx #$00                        ; reset the index for the next 256 bytes
read_sector_high
    jsr spi_read_byte               ; read a byte
    sta block_buffer_high,x         ; store it into the high buffer + x
    inx                             ; increment the index
    bne read_sector_high            ; if the index has not rolled over, loop
    jsr spi_read_byte               ; after reading a block, the card send a 16 bit crc, read these two bytes
    jsr spi_read_byte
    rts

spi_write_sector                    ; writes the contents of block_buffer_low and block_buffer_high to the sd card
    ldy #$fe                        ; write the value $fe, to indicate to the card than the next byte is the first byte to write
	jsr spi_write_byte
    ldx #$00                        ; use the x register as an index, load it with zero
.lowloop
    lda block_buffer_low,x          ; load the byte from the buffer
    tay                             ; transfer it to y for the write subroutine
    jsr spi_write_byte
    inx                             ; increment the index
    bne .lowloop                    ; if the index has not rolled over, loop
    ldx #$00                        ; reset the index
.highloop
    lda block_buffer_high,x         ; load the byte from the high buffer
    tay                             ; transfer it to y for the write subroutine
    jsr spi_write_byte          
    inx                             ; increment the index
    bne .highloop                   ; if it has not rolled over, loop
    rts



spi_write_string                    ; takes a string, and puts its bytes in block_buffer_low
    ldy #$00                        ; use y as an index, load it with zero
.loop
    lda (stringptr),y               ; load from the stringptr
    cmp #$00                        ; if at the end of the string, then exit
    beq .exit
    sta block_buffer_low,y          ; store the char into the block buffer
    iny                             ; increment y to the next char
    jmp .loop                       ; loop

.exit                               ; exit
    rts

clk_pump                            ; for the sd card to go into spi mode, it needs to be clocked at least 74(?) times

    ldx #255                        ; use the x register as a counter, start it at 255
.loop
    lda #sck                        ; load a with the bit for the sck
    eor PORTA                       ; toggle the bit
    sta PORTA                       ; store it to the output port
    dex                             ; decrement the counter
    bne .loop                       ; if the counter has not reached zero, loop
    lda #sck                        ; load the bit for the sck again
    ora PORTA                       ; set it to high, (idle high)
    sta PORTA
    rts

sd_card_init                        ; waits for cmd41 to return 0x00
	
    jsr delay                       ; add a small delay
    ldptr cmd55, spi_buffer         ; cmd41 must come after (a)cmd55
    jsr spi_sd_send_command

    ldptr cmd41, spi_buffer         ; now send cmd41
    jsr spi_sd_send_command
    cmp #$00                        ; if the return code is not $00 ($01), loop
    bne sd_card_init
    rts

spi_clock_frame                     ; toggles the clock 8 times (sends a filler byte)

    ldx #16                         ; use the x register as a counter, load it with 16
.loop
    nop                             ; add a small delay
    nop
    nop
    lda #sck                        ; load the sck bit
    eor PORTA                       ; toggle the bit 
    sta PORTA                       
    dex                             ; decrement the counter
    bne .loop                       ; if it has not reached zero, loop
    lda #sck                        ; set the clock to high (idle high) before returning
    ora PORTA
    sta PORTA
    rts

spi_idle                            ; sets the spi bus to the idle state

    lda PORTA
    ora #cs                         ; chip select -> 1
    ora #mosi                       ; data -> 1
    ora #sck                        ; clk -> 1
    sta PORTA

    rts

spi_active                          ; set the spi bus to the active state
    lda PORTA
    and #~cs    
    sta PORTA                       ; set the cs to low
    rts

spi_inactive                        ; sets the spi bus to the inactive state
    lda PORTA
    ora #cs
    sta PORTA                       ; set the cs to high
    rts

delay                               ; adds a small delay
	ldx #255                        ; use the x register as a counter
.loop
	nop                             ; add nop's to make the delay even longer
	nop
	nop
	nop
	dex                             ; decrement the counter
	bne .loop                       ; if the counter has not reached zero, loop
	rts

; the command bytes

cmd0
	.byte $40, $00, $00, $00, $00, $95
cmd1
	.byte $41, $00, $00, $00, $00, $96
cmd8
	.byte $48, $00, $00, $01, $aa, $87
cmd9
	.byte $49, $00, $00, $00, $00, $01
cmd17
	.byte $51, $00, $00, $00, $00, $01
cmd24
    .byte $58, $00, $00, $00, $00, $01
cmd55
	.byte $77, $00, $00, $00, $00, $01
cmd41
	.byte $69, $40, $00, $00, $00, $01
