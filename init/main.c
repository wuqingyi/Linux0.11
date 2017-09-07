long user_stack[4096 >> 2];
struct
{
    long *a;
    short b;
} stack_start = {&user_stack[4096 >> 2], 0x10};

extern void init_idt_desc(unsigned char vector, unsigned char desc_type,
                          int_handler handler, unsigned char privilege);

void main(void)
{
    trap_init();
}