#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#include "riscv_csr.h"
#include "riscv_interrupts.h"

#include "prj_nanoprintf.h"
#include "riscv_io.h"
#include "sim_extensions.h"
#include "vector_table.h"

int main(void)
{
    sim_putstring("Main\n");

    nprintf("%s %.2f\n", "pi is", 3.14f);

    uint64_t mtime = mtime_get();
    mtimecmp_set(mtime + 2048);

    asm volatile("wfi");
    asm volatile("wfi");
    asm volatile("wfi");
    asm volatile("wfi");

    return 0;
}

void riscv_mtvec_mti(void)
{
    sim_putstring("riscv_mtvec_mti\n");
    uint64_t mtimecmp = mtimecmp_get();
    mtimecmp_set(mtimecmp + 2048);
}
