#include <stdio.h>

#include "biriscv_extensions.h"

char *msg = "Hello Bi-RISC-V!\n";


void main()
{
    char *p;

    p = msg;
    while (*p) {
        biriscv_sim_putc(*p++);
    }
    //for (int i = 0; i < 10; ++i)
    //{
    //    biriscv_sim_putc('A'+i);
    //}
    //biriscv_sim_putc('\n');
    p = msg;
    printf(msg);

    //for (int i = 0; i < 1000; ++i);
    biriscv_sim_exit(0);
}

