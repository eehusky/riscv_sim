

#include "riscv_io.h"


static inline void rsd_sim_exit(int exitcode)
{
    asm volatile("j _end");
}
static inline void rsd_sim_putc(char ch)
{
    write32(0x40002000, ch);
}

static inline void rsd_putstring(char *s)
{
    char *p = s;
    while (*p) {
        rsd_sim_putc(*p++);
    }
}

#define ADDR_TIMER_BASE    (0x40000000)
#define ADDR_TIMER_LOW     (ADDR_TIMER_BASE + 0);
#define ADDR_TIMER_HI      (ADDR_TIMER_BASE + 4);
#define ADDR_TIMER_CMP_LOW (ADDR_TIMER_BASE + 8);
#define ADDR_TIMER_CMP_HI  (ADDR_TIMER_BASE + 12);



int main(void)
{

    rsd_putstring("Hello World\n");



    for (int i = 0; i < 10; ++i) {
        asm volatile("wfi");
    }

    //read32(0x40000000);
    //for (int i = 0; i < 10; ++i) {
    //    asm volatile("wfi");
    //}

    rsd_sim_exit(0);
}
