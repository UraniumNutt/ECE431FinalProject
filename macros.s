ldptr: .macro data, ptr
		lda #<\data
		sta \ptr
		lda #>\data
		sta \ptr + 1
.endm

save_stack: .macro

    php
    pha
    phx
    phy

.endm

restore_stack: .macro

    ply
    plx
    pla
    plp

.endm