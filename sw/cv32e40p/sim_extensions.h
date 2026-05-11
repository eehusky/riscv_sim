#ifndef __SIM_EXTENSIONS_H__
#define  __SIM_EXTENSIONS_H__
#include "riscv_io.h"
#include <stdint.h>


#define MTIME_LOW     0x00002000
#define MTIME_HIGH    0x00002004
#define MTIMECMP_LOW  0x00002008
#define MTIMECMP_HIGH 0x0000200C

#define SIM_CTRL_OUT  0x00003000
#define SIM_CTRL_EXIT 0x00003004


static inline void sim_exit(int exitcode)
{
    asm volatile("sw    %1, 0(%0)"
                 :            /* output: none */
                 : "r"(SIM_CTRL_EXIT), /* input : register */
                   "r"(exitcode) /* input : register */
                 : /* clobbers: none */);
}

static inline void sim_putc(int ch)
{
    asm volatile("sw    %1, 0(%0)"
                 :            /* output: none */
                 : "r"(SIM_CTRL_OUT), /* input : register */
                   "r"(ch) /* input : register */
                 : /* clobbers: none */);
}

static inline void sim_putstring(const char *s)
{
    char *p = (char *)s;
    while (*p) {
        sim_putc(*p++);
    }
}

static inline void mtimecmp_set( uint64_t cmp )
{
    write32(MTIMECMP_LOW, (uint32_t)cmp);
    write32(MTIMECMP_HIGH, (uint32_t)(cmp>>32));
}
static inline uint64_t mtimecmp_get(void)
{
    uint64_t upper = read32(MTIMECMP_HIGH);
    uint64_t lower = read32(MTIMECMP_LOW);
    return (upper<<32) | lower;
}
static inline uint64_t mtime_get(void)
{
    uint64_t lower = read32(MTIME_LOW);
    uint64_t upper = read32(MTIME_HIGH);
    return (upper<<32) | lower;
}


#endif
