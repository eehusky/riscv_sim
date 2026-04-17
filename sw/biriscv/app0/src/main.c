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
    p = msg;

    printf(msg);

    biriscv_sim_exit(0);
}

