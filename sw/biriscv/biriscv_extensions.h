#ifndef __BIRISCV_EXTENSIONS_H__
#define __BIRISCV_EXTENSIONS_H__

#include <stdint.h>


#define csr_read(reg) ({ uint32_t __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

#define csr_write(reg, val) ({ \
  asm volatile ("csrw " #reg ", %0" :: "rK"(val)); })

static inline void biriscv_timer_set_mtimecmp(uint32_t next)
{
    csr_write(0x7c0, next);
}

static inline uint32_t biriscv_timer_get_mtime(void)
{
    return csr_read(0xc00); // or 0xc01
}
static inline void biriscv_timer_set_mtime(uint32_t value)
{
    csr_write(0xc01, value);
}


static inline void biriscv_icache_flush(void)
{
    asm volatile ("fence.i");
}

static inline void biriscv_dcache_flush(void)
{
    asm volatile ("csrw pmpcfg0, x0"); // 0x3a0
}
static inline void biriscv_dcache_writeback(uint32_t addr)
{
    asm volatile ("csrw pmpcfg1, %0": : "r" (addr)); // 0x3a1
}
static inline void biriscv_dcache_invalidate(uint32_t addr)
{
    asm volatile ("csrw pmpcfg2, %0": : "r" (addr)); // 0x3a2
}



#define CSR_SIM_CTRL_EXIT (0 << 24)
#define CSR_SIM_CTRL_PUTC (1 << 24)

static inline void biriscv_sim_exit(int exitcode)
{
    unsigned int arg = CSR_SIM_CTRL_EXIT | ((unsigned char)exitcode);
    asm volatile ("csrw dscratch,%0": : "r" (arg));
}

static inline void biriscv_sim_putc(int ch)
{
    unsigned int arg = CSR_SIM_CTRL_PUTC | (ch & 0xFF);
    asm volatile ("csrw dscratch,%0": : "r" (arg));
}

#endif
