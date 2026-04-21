#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "biriscv_extensions.h"
#include "mm2s_ringbuffer.h"
#include "ringbuffer_addrmap.h"
#include "ringbuffer_explode.h"
#include "riscv-csr.h"

extern uint32_t _vector_table;

char *msg = "Hello Bi-RISC-V!\n";

volatile char data[1024];
volatile char data2[1024];

void cache_stuff()
{
    // volatile char *data = (char *)(1<<12);

    // char *p;
    // p = msg;
    // while (*p) {
    //     biriscv_sim_putc(*p++);
    // }

    // biriscv_sim_putc('\n');
    // p = msg;
    // printf(msg);

    // for (int i = 0; i < 1000; ++i);

    // for (int i = 0; i < 1024; i+=128){
    //     data[i];
    //     data[i+32];
    //     data[i+64];
    //     data[i+96];
    // }

    // for (int i = 0; i < 1000; ++i);

    // for (int i = 0; i < 1024; ++i)
    //{
    //     data[i] = i&0xFF;
    // }
    memset((void *)data, 0xAA, sizeof(data));

    // biriscv_dcache_flush();
    memcpy((void *)data2, (void *)data, sizeof(data));

    biriscv_dcache_flush();
    // for (int i = 0; i < 1000; ++i);
    biriscv_sim_exit(0);
}

void riscv_mtvec_mei(void) { biriscv_putstring("mtvec_mei\n"); }

#define MTIME_FREQ_HZ 100000000

#define MTIMER_SECONDS_TO_CLOCKS(SEC) ((uint64_t)(((SEC) * (MTIME_FREQ_HZ))))

#define MTIMER_MSEC_TO_CLOCKS(MSEC) ((uint64_t)(((MSEC) * (MTIME_FREQ_HZ)) / 1000))

#define MTIMER_USEC_TO_CLOCKS(USEC) ((uint64_t)(((USEC) * (MTIME_FREQ_HZ)) / 1000000))

uint32_t timer_calls = 0;

void riscv_mtvec_mti(void)
{
    // continue timer chain, period + previous compare
    biriscv_timer_set_mtimecmp(biriscv_timer_get_mtimecmp() + MTIMER_USEC_TO_CLOCKS(10));
    timer_calls += 1;
}

extern void riscv_mtvec_exception(void);
void interrupt_stuff()
{
    // Global interrupt disable
    csr_clr_bits_mstatus(MSTATUS_MIE_BIT_MASK);
    csr_write_mie(0);

    // Setup the IRQ handler entry point, set the mode to vectored
    csr_write_mtvec((uint_xlen_t)riscv_mtvec_exception | 1);

    // Enable MIE.MTI
    csr_set_bits_mie(MIE_MEI_BIT_MASK);
    csr_set_bits_mie(MIE_MTI_BIT_MASK);

    // Global interrupt enable
    csr_set_bits_mstatus(MSTATUS_MIE_BIT_MASK);

    // start timer chain, period + current time
    // biriscv_timer_set_mtimecmp(biriscv_timer_get_mtime() + MTIMER_USEC_TO_CLOCKS(10));
    // while(1){
    //    asm volatile ("wfi");
    //    if(timer_calls ==10) break;
    //}
}

unsigned char buffers[4][4096] __attribute__((aligned(4096)));

void ringbuffer_stuff()
{
    // memset(_bss, 0, _ebss-_bss);

    biriscv_putstring("ringbuffer_stuff\n");

    int rc;
    struct mm2s_ringbuffer *dev;
    void *buffer = malloc(4096);
    ringbuffer_t *inst = ((ringbuffer_t *)0xa0000000UL);

    biriscv_putstring("mm2s_ringbuffer_init\n");

    dev = mm2s_ringbuffer_init((mm2s_ringbufferx_t *)(&(inst->mm2s_ringbuffer[0])));
    if (dev == NULL) {
        biriscv_putstring("mm2s_ringbuffer_init failed\n");
        return;
    }

    biriscv_putstring("mm2s_ringbuffer_set_buffer\n");
    rc = mm2s_ringbuffer_set_buffer(dev, buffers[0], 4096);
    if (rc) {
        biriscv_putstring("mm2s_ringbuffer_set_buffer failed\n");
        return;
    }
    biriscv_putstring("mm2s_ringbuffer_start\n");
    rc = mm2s_ringbuffer_start(dev);
    if (rc) {
        biriscv_putstring("mm2s_ringbuffer_start failed\n");
        return;
    }
    char *teststring = "Hello World";
    biriscv_putstring("mm2s_ringbuffer_put\n");
    rc = mm2s_ringbuffer_put(dev, teststring, strlen(teststring));
    if (rc < 0) {
        biriscv_putstring("mm2s_ringbuffer_put failed\n");
        return;
    }
    biriscv_dcache_writeback_range((uint32_t)&buffers[0][0], strlen(teststring));
    // biriscv_dcache_writeback((uint32_t)&buffers[0][0]);
    // biriscv_dcache_writeback((uint32_t)&buffers[0][8]);
    // biriscv_dcache_flush();
    biriscv_putstring("mm2s_ringbuffer_commit\n");
    rc = mm2s_ringbuffer_commit(dev);
    if (rc) {
        biriscv_putstring("mm2s_ringbuffer_commit failed\n");
        return;
    }
}

static inline uint32_t read32(uint32_t addr)
{
    uint32_t rv;
    asm volatile("lw    %0, 0(%1)"
                 : "=r"(rv)  /* output: register %0 */
                 : "r"(addr) /* input : register */
                 : /* clobbers: none */);
    return rv;
}
static inline void write32(uint32_t addr, uint32_t value)
{
    asm volatile("sw    %1, 0(%0)"
                 :            /* output: none */
                 : "r"(addr), /* input : register */
                   "r"(value) /* input : register */
                 : /* clobbers: none */);
}

void main()
{
    write32(0xA00000F4, 0x00000000);
    write32(0xA00000F4, 0xDEADBEEF);

    if (read32(0xA00000F4) == 0xDEADBEEF) {
        biriscv_putstring("loadstore\n");
    } else {
        biriscv_putstring("loadstore2\n");
    }
    interrupt_stuff();
    ringbuffer_stuff();

    for (int i = 0; i < 1000; ++i)
        ;

    biriscv_putstring("Exiting\n");
    biriscv_sim_exit(0);
}
