vasm6502_oldstyle -wdc02 -Fbin -dotdir $1 -o output.bin 
minipro -p SST39SF040 -w output.bin -s
rm output.bin
