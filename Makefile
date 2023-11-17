PROJ=SD_SPI
FLASHIC = SST39SF040

# Add Windows and Unix support
RM         = rm -rf
COPY       = cp -a
PATH_SEP   = /


flash: build
	minipro -p ${FLASHIC} -w ${PROJ}.bin -s

build: ${PROJ}.s
	vasm6502_oldstyle -wdc02 -Fbin -dotdir -esc ${PROJ}.s -o ${PROJ}.bin

clean:
	$(RM) -f ${PROJ}.bin

.PHONY: prog clean