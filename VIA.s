VIA_base_address = $7c00

PORTB             = VIA_base_address + 0
PORTA             = VIA_base_address + 1
DDRB              = VIA_base_address + 2
DDRA              = VIA_base_address + 3
T1CL              = VIA_base_address + 4
T1CH              = VIA_base_address + 5
T1LL              = VIA_base_address + 6
T1LH              = VIA_base_address + 7
T2CL              = VIA_base_address + 8
T2CH              = VIA_base_address + 9
SR                = VIA_base_address + 10
ACR               = VIA_base_address + 11
PCR               = VIA_base_address + 12
IFR               = VIA_base_address + 13
IER               = VIA_base_address + 14
PORTA_NOHANDSHAKE = VIA_base_address + 15

BIT0 = %00000001
BIT1 = %00000010
BIT2 = %00000100
BIT3 = %00001000
BIT4 = %00010000
BIT5 = %00100000
BIT6 = %01000000
BIT7 = %10000000

VIA_output_all
    lda #%11111111 ; Set all pins on port B to output
	sta DDRB
	lda #%11111111 ; Set all pins on port A to output
	sta DDRA
	rts

VIA_T1_continous_interrupts
	lda #%01000000 ; Set up T1 to do continuous interupts
	sta ACR


	lda #$FF ; must load low byte first, 
	sta T1CL ; load low byte into counter

	lda #$FF
	sta T1CH ; load high byte into counter

	lda #%11000000
	sta IER ; enable VIA interupts for T1
    rts


