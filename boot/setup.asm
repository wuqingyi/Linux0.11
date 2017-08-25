INITSEG     EQU 9000h
SYSSEG      EQU 1000h
SETUPSEG    EQU 9020h

start:
;get current cursor position and save it for posterity.
    mov ax, INITSEG
    mov ds, ax
    mov ah, 03h
    xor bh, bh
    int 10h
    mov [0], dx

;Get memory size (extended mem, kB)
    mov ah, 88h
    int 15h
    mov [2], ax

;Get video-card data
    mov ah, 0fh
    int 10h
    mov [4], bx         ;bh = display page
    mov [6], ax         ;al = video mode, ah = window width

;check for EGA/VGA and some config parameters
    mov ah, 12h
    mov bl, 10h
    int 10h
    mov [8], ax
    mov [10], bx
    mov [12], cx

;Get hd0 data

	mov	ax, 0000h
	mov	ds, ax
	lds	si, [4*41h]
	mov	ax, INITSEG
	mov	es, ax
	mov	di, 0080h
	mov	cx, 10h
	rep
    movsb

;Get hd1 data
    mov ax, 0000h
    mov ds, ax
    lds si, [4*46h]
    mov ax, INITSEG
    mov es, ax
    mov di, 0090h
    mov cx, 10h
    rep
    movsb

;check that there is a hd1 :-)

    mov ax, 1500h
    mov dl, 81h
    int 13h
    jc no_disk1
    cmp ah, 3
    je is_disk1
no_disk1:
    mov ax, INITSEG
    mov es, ax
    mov di, 90h
    mov cx, 10h
    mov ax, 00h
    rep
    stosb
is_disk1:

;===========================================
;now we want to move to protected mode ...
;-------------------------------------------

;关中断
    cli

;move the system to it's rightful place
    mov ax, 0
    cld             ;move forward
do_move:
    mov es, ax
    add ax, 1000h
    cmp ax, 9000h
    jz end_move
    mov ds, ax
    xor di, di
    xor si, si
    mov cx, 8000h
    rep movsw
    jmp do_move

end_move:
    mov ax, SETUPSEG
    mov ds, ax
    lidt idt_48
    lgdt gdt_48

;打开A20
    call empty_8042
    mov al, 0d1h
    out 64h, al
    call empty_8042
    mov al, 0dfh
    out 60h, al
    call empty_8042

    

empty_8042:
    nop
    nop
    in al, 64h
    test al, 2
    jnz empty_8042
    ret

label_gdt:
    dw 0,0,0,0
    dw 07ffh            ;8Mb - limit=2047 (2048*4096=8Mb)
    dw 0000h            ;base address=0
    dw 9a00h            ;code read/exec
    dw 00c0h            ;granularity=4096, 386

    dw 07ffh
    dw 0000h
    dw 9200h
    dw 00c0h

idt_48:
    dw 0, 0, 0

gdt_48:
    dw 8000h            ;gdt limit=2048, 256 GDT entries
    dw 512+label_gdt, 09h     ;gdt base = 0X9xxxx

