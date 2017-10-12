void main(void)
{
    trap_init();
    tty_init();
    sched_init();
    sti();
    move_to_user_mode();
    if (!fork())
    {
        init();
    }

    for (;;);
}