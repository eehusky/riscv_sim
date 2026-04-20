#include <string.h>
#include <stdio.h>
#include <stdint.h>

#include "biriscv_extensions.h"
#include "riscv-csr.h"

extern uint32_t _vector_table;


char *msg = "Hello Bi-RISC-V!\n";

volatile char data[1024];
volatile char data2[1024];


void cache_stuff()
{
    //volatile char *data = (char *)(1<<12);

    //char *p;
    //p = msg;
    //while (*p) {
    //    biriscv_sim_putc(*p++);
    //}

    //biriscv_sim_putc('\n');
    //p = msg;
    //printf(msg);

    //for (int i = 0; i < 1000; ++i);

    //for (int i = 0; i < 1024; i+=128){
    //    data[i];
    //    data[i+32];
    //    data[i+64];
    //    data[i+96];
    //}

    //for (int i = 0; i < 1000; ++i);

    //for (int i = 0; i < 1024; ++i)
    //{
    //    data[i] = i&0xFF;
    //}
    memset((void*)data,0xAA,sizeof(data));

    //biriscv_dcache_flush();
    memcpy((void*)data2, (void*)data, sizeof(data));

    biriscv_dcache_flush();
    //for (int i = 0; i < 1000; ++i);
    biriscv_sim_exit(0);
}

void riscv_mtvec_mei(void)
{
    biriscv_putstring("mtvec_mei\n");
}

#define MTIME_FREQ_HZ 100000000

#define MTIMER_SECONDS_TO_CLOCKS(SEC)           \
    ((uint64_t)(((SEC)*(MTIME_FREQ_HZ))))

#define MTIMER_MSEC_TO_CLOCKS(MSEC)           \
    ((uint64_t)(((MSEC)*(MTIME_FREQ_HZ))/1000))

#define MTIMER_USEC_TO_CLOCKS(USEC)           \
    ((uint64_t)(((USEC)*(MTIME_FREQ_HZ))/1000000))

uint32_t timer_calls = 0;

void riscv_mtvec_mti(void)  {
    // continue timer chain, period + previous compare
    biriscv_timer_set_mtimecmp(biriscv_timer_get_mtimecmp() + MTIMER_USEC_TO_CLOCKS(10));
    timer_calls+=1;
}


extern void riscv_mtvec_exception(void);
void interrupt_stuff()
{
    // Global interrupt disable
    csr_clr_bits_mstatus(MSTATUS_MIE_BIT_MASK);
    csr_write_mie(0);

    // Setup the IRQ handler entry point, set the mode to vectored
    csr_write_mtvec((uint_xlen_t) riscv_mtvec_exception | 1);

    // Enable MIE.MTI
    csr_set_bits_mie(MIE_MEI_BIT_MASK);
    csr_set_bits_mie(MIE_MTI_BIT_MASK);

    // Global interrupt enable
    csr_set_bits_mstatus(MSTATUS_MIE_BIT_MASK);

    // start timer chain, period + current time
    biriscv_timer_set_mtimecmp(biriscv_timer_get_mtime() + MTIMER_USEC_TO_CLOCKS(10));

    while(1){
        asm volatile ("wfi");
        if(timer_calls ==10) break;
    }
}

void main()
{
    interrupt_stuff();

    //int ctzw;
    //int v = 0x100;
    //asm volatile ("ctzw %0, %1" :"=r"(ctzw): "r"(v));
    //printf("%d\n",ctzw);

    biriscv_putstring("Exiting\n");
    biriscv_sim_exit(0);
}

