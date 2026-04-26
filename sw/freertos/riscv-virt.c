#include <FreeRTOS.h>

#include "riscv-virt.h"
#include "biriscv_extensions.h"



int xGetCoreID(void)
{
    int id;

    asm volatile("csrr %0, mhartid" : "=r"(id));

    return id;
}

void vSendString(const char *s)
{
    portENTER_CRITICAL();

    biriscv_putstring(s);
    biriscv_sim_putc('\n');

    portEXIT_CRITICAL();
}

void handle_trap(void)
{
    while (1)
        ;
}
