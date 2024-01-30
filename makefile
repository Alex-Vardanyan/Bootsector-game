all:
	nasm -f bin breakout.asm -o breakout.bin
run:
	qemu-system-i386 -drive format=raw,file=breakout.bin
