#ifndef __SIM_EXTENSIONS_H__
#define  __SIM_EXTENSIONS_H__

#include <stdint.h>

#define csr_read(reg)                                                                                                  \
    ({                                                                                                                 \
        uint32_t __tmp;                                                                                                \
        asm volatile("csrr %0, " #reg : "=r"(__tmp));                                                                  \
        __tmp;                                                                                                         \
    })

#define csr_write(reg, val) ({ asm volatile("csrw " #reg ", %0" ::"rK"(val)); })

static inline void mtimecmp_set(uint32_t next) { csr_write(0x7c0, next); }
static inline uint32_t mtimecmp_get(void) { return csr_read(0x7c0); }

static inline uint32_t mtime_get(void)
{
    return csr_read(0xc00); // or 0xc01
}


#define CSR_SIM_CTRL_EXIT (0 << 24)
#define CSR_SIM_CTRL_PUTC (1 << 24)

static inline void sim_exit(int exitcode)
{
    unsigned int arg = CSR_SIM_CTRL_EXIT | ((unsigned char)exitcode);
    asm volatile("csrw dscratch,%0" : : "r"(arg));
}

static inline void sim_putc(int ch)
{
    unsigned int arg = CSR_SIM_CTRL_PUTC | (ch & 0xFF);
    asm volatile("csrw dscratch,%0" : : "r"(arg));
}

static inline void sim_putstring(const char *s)
{
    char *p = (char *)s;
    while (*p) {
        sim_putc(*p++);
    }
}

#endif
