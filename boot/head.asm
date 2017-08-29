[BITS 32]
extern stack_start, main, printk
global _idt, _gdt, _pg_dir, _tmp_floppy_area
startup_32:
_pg_dir:
    mov eax, 10h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    lss esp, [stack_start]

    call setup_idt
    call setup_gdt

    mov eax, 10h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    lss esp, [stack_start]

    ;check that A20 really IS enable
    xor eax, eax
.1: inc eax
    mov dword [000000h], eax
    cmp dword [100000h], eax
    je .1

    mov eax, cr0
    and eax, 80000011h
    or eax, 2
    mov cr0, eax
    call check_x87
    jmp after_page_tables

check_x87:
    finit
    fstsw ax
    cmp al, 0
    je .1
    mov eax, cr0
    xor eax, 6
    mov cr0, eax
    ret
align 4
.1:
    db 0dbh, 0e4h
    ret

setup_idt:
    lea edx, [ignore_int]
    mov eax, 80000h
    mov ax, dx
    mov dx, 8e00h

    lea edi, [_idt]
    mov ecx, 256
rp_sidt:
    mov [edi], eax
    mov [edi+4], edx
    add edi, 8
    dec ecx
    jne rp_sidt
    lidt [idt_descr]
    ret

setup_gdt:
    lgdt [gdt_descr]
    ret

_tmp_floppy_area:
    times 1024 db 0

after_page_tables:
    push dword 0
    push dword 0
    push dword 0
    push L6
    push main
    jmp setup_paging
L6:
    jmp L6

int_msg:
    db "Unknown interrupt",13, 10,0

align 4
ignore_int:
    push eax
    push ecx
    push edx
    push ds
    push es
    push fs
    mov eax, 10h
    mov ds, ax
    mov es, ax
    mov fs, ax
    push int_msg
    call printk
    pop eax
    pop fs
    pop es
    pop ds
    pop edx
    pop ecx
    pop eax
    iret

align 4
setup_paging:
    mov ecx, 1024*5
    xor eax, eax
    xor edi, edi
    cld
    mov dword [_pg_dir], 1000h+7         ;+7:p=1,r/w=1,u/s=1
    mov dword [_pg_dir+4], 2000h+7
    mov dword [_pg_dir+8], 3000h+7
    mov dword [_pg_dir+12],4000h+7
    mov edi, 4000h+4092
    mov eax, 0fff007h
    std
.1:
    stosd
    sub eax, 1000h
    jge .1
    xor eax, eax
    mov cr3, eax
    mov eax, cr0
    or eax, 80000000h
    mov cr0, eax
    ret

align 4
    dw 0
idt_descr:
    dw 256*8-1
    dd _idt

align 4
    dw 0
gdt_descr:
    dw 256*8-1
    dd _gdt

_idt:
    times 256 dq 0000000000000000h

_gdt:
    dq 0000000000000000h
    dq 00c09a0000000fffh
    dq 00c0920000000fffh
    dq 0000000000000000h
    times 252 dq 0000000000000000h