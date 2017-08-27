extern stack_start
global _idt, _gdt, _pg_dir, _tmp_floppy_area
[BITS 32]
_pg_dir:
startup_32:
    mov eax, 10h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    lss esp, stack_start

    call setup_idt
    call setup_dgt

    mov eax, 10h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    lss esp, stack_start

    ;check that A20 really IS enable
    xor eax, eax
.1:  inc eax
    mov [000000h], eax
    cmp [100000h], eax
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
    je .2
    mov eax, cr0
    xor eax, 6
    mov cr0, eax
    ret
align 2
