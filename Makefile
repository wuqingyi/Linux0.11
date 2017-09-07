ASM=nasm
CC	=gcc $(RAMDISK)
CFLAGS	=-c -m32
LD =ld
#-Ttext 0x0000 起始地址必须设置为0。nasm不支持在elf文件中使用org
LDFLAG=-melf_i386 -Ttext 0x0000 -e startup_32 
BINS=boot/bootsect.bin boot/setup.bin
OBJS=boot/head.o init/main.o
.PHONY: image clean

#系统模块现在设置为240个扇区，不一定足够！！！
image:$(BINS) kernel.bin
	dd if=boot/bootsect.bin of=a.img bs=512 count=1         conv=notrunc
	dd if=boot/setup.bin    of=a.img bs=512 count=4   seek=1 conv=notrunc
	dd if=kernel.bin            of=a.img bs=512 count=240 seek=5 conv=notrunc

boot/bootsect.bin: boot/bootsect.asm
	$(ASM) -o $@ $<

boot/setup.bin: boot/setup.asm
	$(ASM) -o $@ $<

#-gstabs 设置添加调试信息	
kernel.bin:system.elf tool/build.c
	gcc -o build tool/build.c -gstabs
	./build
	
system.elf:$(OBJS)
	$(LD) $(LDFLAG) -o $@ $(OBJS)
	
boot/head.o:boot/head.asm
	$(ASM) -felf -o $@ $<

init/main.o:init/main.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(BINS) $(OBJS) system.elf kernel.bin build