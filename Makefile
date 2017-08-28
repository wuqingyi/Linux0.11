ASM=nasm
CFLAGS	=-Wall -O
BINS=boot/bootsect.bin boot/setup.bin
OBJS=boot/head.o init/main.o
.PHONY image clean

image:$(BINS) kernel
	dd if=boot/bootsect.bin of=a.img bs=512 count=1         conv=notrunc
	dd if=boot/setup.bin    of=a.img bs=512 count=4  seek=1 conv=notrunc
	dd if=kernel            of=a.img bs=512 count=10 seek=5 conv=notrunc

boot/bootsect.bin: boot/bootsect.asm
	$(ASM) -o $@ $<

boot/setup.bin: boot/setup.asm
	$(ASM) -o $@ $<
	
kernel:system.elf
	#do something to strip system.elf
	
system.elf:$(OBJS) #...
	gcc -c -o $@ $(OBJS)
	
boot/head.o:boot/head.asm init/main.c
	$(ASM) -f elf -o $@ $<

init/main.o:init/main.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(BINS) $(OBJS)