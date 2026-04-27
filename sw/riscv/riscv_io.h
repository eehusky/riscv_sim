#ifndef __RISCV_IO_H__
#define __RISCV_IO_H__

#include <stdint.h>

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


#endif
