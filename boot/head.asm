extern _stack_start
global _idt, _gdt, _pg_dir, _tmp_floppy_area
[BITS 32]
_pg_dir:
startup_32:
    mov ax, 10h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    lss 