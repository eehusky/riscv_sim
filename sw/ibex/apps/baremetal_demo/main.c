#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "riscv_csr.h"
#include "riscv_hpm.h"
#include "riscv_info.h"

#include "prj_nanoprintf.h"
#include "riscv_io.h"
#include "sim_extensions.h"
#include "vector_table.h"

#define ITCM_ADDR 0x80000000
#define ITCM_SIZE 0x00020000
#define MTIME_ADDR 0x00002000
#define MTIME_SIZE 0x00001000
#define SIMCTRL_ADDR 0x00003000
#define SIMCTRL_SIZE 0x00001000
#define DTCM_ADDR 0x80020000
#define DTCM_SIZE 0x00020000
#define CACHED_ADDR 0x90000000
#define CACHED_SIZE 0x00020000
#define UNCACHED_ADDR 0xA0000000
#define UNCACHED_SIZE 0x00020000
#define AXIL_ADDR 0xB0000000
#define AXIL_SIZE 0x00020000



void do_mtime(void)
{
    sim_putstring("  ibex mtime demo\n");
    uint64_t mtime = mtime_get();
    mtimecmp_set(mtime + 2048);
    for (int i = 0; i < 10; ++i)
    {
        asm volatile("wfi");
    }
    csr_clr_bits_mie(MIE_MTI_BIT_MASK);
}

void do_addr(void)
{
    sim_putstring("  ibex addr demo\n");
    uint32_t blah = 0;

    sim_putstring("    ibex cached demo\n");
    write32(CACHED_ADDR, 0xDEADBEEF);
    read32(CACHED_ADDR);
    write32(CACHED_ADDR + CACHED_SIZE - 4, 0xDEADBEEF);
    read32(CACHED_ADDR + CACHED_SIZE - 4);
    for (int i = 0; i < 512; ++i) {
        write32(CACHED_ADDR + (i * 4), blah + 1);
        blah = read32(CACHED_ADDR + (i * 4));
    }

    sim_putstring("    ibex uncached demo\n");
    write32(UNCACHED_ADDR, 0xDEADBEEF);
    read32(UNCACHED_ADDR);
    write32(UNCACHED_ADDR + UNCACHED_SIZE - 4, 0xDEADBEEF);
    read32(UNCACHED_ADDR + UNCACHED_SIZE - 4);
    for (int i = 0; i < 512; ++i) {
        write32(UNCACHED_ADDR + (i * 4), blah + 1);
        blah = read32(UNCACHED_ADDR + (i * 4));
    }

    sim_putstring("    ibex axil demo\n");
    write32(AXIL_ADDR, 0xDEADBEEF);
    read32(AXIL_ADDR);
    write32(AXIL_ADDR + AXIL_SIZE - 4, 0xDEADBEEF);
    read32(AXIL_ADDR + AXIL_SIZE - 4);
    for (int i = 0; i < 512; ++i) {
        write32(AXIL_ADDR + (i * 4), blah + 1);
        blah = read32(AXIL_ADDR + (i * 4));
    }
}

int main(void)
{
    sim_putstring("ibex main demo\n");

    riscv_dump_info();

    do_mtime();
    do_addr();



    riscv_hpm_counters_dump();
    sim_putstring("  ibex counter demo\n");
    return 0;
}

void riscv_mtvec_mti(void)
{
    sim_putstring("    riscv_mtvec_mti\n");
    uint64_t mtimecmp = mtimecmp_get();
    mtimecmp_set(mtimecmp + 2048);
}
