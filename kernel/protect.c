#include <protect.h>

typedef void(int *int_handler)();

void init_idt_desc(unsigned char vector, unsigned char desc_type,
    int_handler handler, unsigned char privilege)
{
    GATE* p_gate = &idt[vector];
    unsigned int base = (unsigned int)handler;
    p_gate->offset_low = base & 0xffff;
    p_gate->selector = SELECTOR_KERNEL_CS;
    p_gate->dcount = 0;
    p_gate->attr = desc_type|(privilege<<5);
    p_gate->offset_high = (base>>16)&0xffff;
}