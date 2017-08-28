ASM=nasm
ASMTARGET=boot/bootsect.bin boot/setup.bin
CC=gcc
OBJS=main.o boot/head.o
CCFLAGS=-nostdinc -I include
CTARGET=init/main.o
.PHONY: everything clean all

everything: $(ASMTARGET) $(CTARGET)


all: clean everything

boot/bootsect.bin: boot/bootsect.asm
	$(ASM) -o $@ $<

boot/setup.bin: boot/setup.asm
	$(ASM) -o $@ $<

boot/head.o:boot/head.asm init/main.c
	$(ASM) -f elf -o $@ $<

init/main.o:init/main.c
	$(CC) $(CCFLAGS) -o $@ $<
clean:
	rm -f $(ASMTARGET)