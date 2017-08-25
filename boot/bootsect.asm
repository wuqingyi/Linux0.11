SETUPLEN    EQU 4
BOOTSECT    EQU 07C0h
INITSEG     EQU 9000h
SETUPSEG    EQU 9020h
SYSSEG      EQU 1000h
SYSSIZE     equ 3000h
ENDSEG      EQU SYSSEG + SYSSIZE
ROOT_DEV    EQU 306h

start:
    mov ax, BOOTSECT
    mov ds, ax
    mov ax, INITSEG
    mov es, ax
    mov cx, 256
    sub si, si
    sub di, di
loop_start:
    movsw
    loop loop_start
    jmp INITSEG:go
go:
    mov ax, cs
    mov ds, ax
    mov es, ax
    ;put stack at 9ff00h
    mov ss, ax
    mov sp, 0ff00h

load_setup:
    mov dx, 0000h           ;drive 0, head 0
    mov cx, 0002h           ;sector 2, track 0
    mov bx, 0200h           ;address 512, in INITSEG(es has been set up)
    mov ax, 0200h + SETUPLEN ;service 2, nr of sectors
    int 13h
    jnc ok_load_setup
    xor dx, dx              ;reset the diskette
    xor ax, ax
    int 13h
    jmp load_setup

ok_load_setup:
; Get disk drive parameters, specifically nr of sectors/track
    mov dl, 00h
    mov ax, 0800h           ;AH=8 is get drive parameters
    int 13h
    mov ch, 00h
    mov [sectors], cx
    mov ax, INITSEG
    mov es, ax

;Print some inane message
    mov ah, 03h             ;read cursor pos
    xor bh, bh
    int 10h

    mov cx, 24
    mov bx, 0007h           ;page 0, attribute 7(normal)
    mov bp, (INITSEG<<4)+msg1
    mov ax, 1301h           ;! write string, move cursor
    int 10h

;load the system (at 0x10000)
    mov ax, SYSSEG
    mov es, ax
    call read_it
    call kill_motor

; After that we check which root-device to use. If the device is
; defined (!= 0), nothing is done and the given device is used.
; Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
; on the number of sectors that the BIOS reports currently.
    mov ax, [root_dev]
    cmp ax, 0
    jne root_defined
    mov bx, [sectors]
    mov ax, 0208h           ;/dev/ps0 - 1.2Mb
    cmp bx, 15
    je root_defined
    mov ax, 021ch           ;/dev/PS0 - 1.44Mb
    cmp bx, 18
    je root_defined
undef_root:
    jmp undef_root
root_defined:
    mov [root_dev], ax

; after that (everyting loaded), we jump to
; the setup-routine loaded directly after
; the bootblock:
    jmp SETUPSEG:0

sread:  dw 1+SETUPLEN       ;sectors read of current track
head:   dw 0                ;current head
track:  dw 0                ;current track

read_it:
    mov ax, es
    test ax, 0fffh
die:
    jne die                 ;es must be at 64kB boundary
    xor bx, bx              ;bx is starting address within segment
rp_read:
    mov ax, es
    cmp ax, ENDSEG
    jb ok1_read
    ret
ok1_read:
    mov ax, [sectors]
    sub ax, [sread]
    mov cx, ax
    shl cx, 9
    add cx, bx
    jnc ok2_read
    je ok2_read
    xor ax, ax
    sub ax, bx
    shr ax, 9
ok2_read:
    call read_track
    mov cx, ax
    add ax, [sread]
    cmp ax, [sectors]
    jne ok3_read
    mov ax, 1
    sub ax, [head]
    jne ok4_read
    inc word [track]
ok4_read:
    mov [head], ax
    xor ax, ax
ok3_read:
    mov [sread], ax
    shl cx, 9
    add bx, cx
    jnc rp_read
    mov ax, es
    add ax, 1000h
    mov es, ax
    xor bx, bx
    jmp rp_read

read_track:
    push ax
    push bx
    push cx
    push dx
    mov dx, [track]
    mov cx, [sread]
    inc cx
    mov ch, dl
    mov dx, [head]
    mov dh, dl
    mov dl, 0
    and dx, 0100h
    mov ah, 2
    int 13h
    jc bad_rt
    pop dx
    pop cx
    pop bx
    pop ax
    ret
bad_rt:
    xor dx, dx
    int 13h
    pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track


kill_motor:
    push dx
    mov dx, 03f2h
    mov al, 0
    out dx, al
    pop dx
    ret

;=========================================================
;data zone
;---------------------------------------------------------
sectors: dw 0

msg1:
    db 13,10,"Loading system ...",13,10,13,10

times 508 - ($ - $$) db 0

root_dev: 
    dw ROOT_DEV
boot_flag:
	dw 0xAA55