ASM=nasm
CC	=gcc $(RAMDISK)
CFLAGS	=-Wall -O
LD =ld
LDFLAG=-melf_i386
BINS=boot/bootsect.bin boot/setup.bin
OBJS=boot/head.o init/main.o
.PHONY: image clean

image:$(BINS) kernel
	dd if=boot/bootsect.bin of=a.img bs=512 count=1         conv=notrunc
	dd if=boot/setup.bin    of=a.img bs=512 count=4  seek=1 conv=notrunc
	dd if=kernel            of=a.img bs=512 count=64 seek=5 conv=notrunc

boot/bootsect.bin: boot/bootsect.asm
	$(ASM) -o $@ $<

boot/setup.bin: boot/setup.asm
	$(ASM) -o $@ $<
	
kernel:system.elf
	#do something to strip system.elf
	
system.elf:$(OBJS)
	$(LD) $(LDFLAG) -o $@ $(OBJS)
	
boot/head.o:boot/head.asm
	$(ASM) -felf -o $@ $<

init/main.o:init/main.c
	$(CC) $(CFLAGS) -m32 -o $@ $<

clean:
	rm -f $(BINS) $(OBJS)