#include <stdint.h>

#include "riscv_csr.h"
#include "nstdio.h"

// clang-format off
static char *isa_descriptions[32]={
    [0] = "Atomic extension",
    [1] = "*Bit-Manipulation extension",
    [2] = "Compressed extension",
    [3] = "Double-precision floating-point extension",
    [4] = "RV32E base ISA",
    [5] = "Single-precision floating-point extension",
    [6] = "Reserved",
    [7] = "Hypervisor extension",
    [8] = "RV32I/64I/128I base ISA",
    [9] = "*Dynamically Translated Languages extension",
    [10] = "Reserved",
    [11] = "Reserved",
    [12] = "Integer Multiply/Divide extension",
    [13] = "*User-Level Interrupts extension",
    [14] = "Reserved",
    [15] = "*Packed-SIMD extension",
    [16] = "Quad-precision floating-point extension",
    [17] = "Reserved",
    [18] = "Supervisor mode implemented",
    [19] = "Reserved",
    [20] = "User mode implemented",
    [21] = "*Vector extension",
    [22] = "Reserved",
    [23] = "Non-standard extensions present",
    [24] = "Reserved",
    [25] = "Reserved",
    [26] = "Reserved",
    [27] = "Reserved",
    [28] = "Reserved",
    [29] = "Reserved",
    [30] = "Reserved",
    [31] = "Reserved",
};
static char *isa_letters[32]={
    [0] =  "A",
    [1] =  "B",
    [2] =  "C",
    [3] =  "D",
    [4] =  "E",
    [5] =  "F",
    [6] =  "G",
    [7] =  "H",
    [8] =  "I",
    [9] =  "J",
    [10] = "K",
    [11] = "L",
    [12] = "M",
    [13] = "N",
    [14] = "O",
    [15] = "P",
    [16] = "Q",
    [17] = "R",
    [18] = "S",
    [19] = "T",
    [20] = "U",
    [21] = "V",
    [22] = "W",
    [23] = "X",
    [24] = "Y",
    [25] = "Z",
    [26] = "*",
    [27] = "*",
    [28] = "*",
    [29] = "*",
    [30] = "*",
    [31] = "*",
};
// clang-format on

void riscv_dump_info(void)
{
    uint32_t misa = csr_read_misa();

    nprintf("mvendorid: 0x%08X (%d)\n", csr_read_mvendorid(), csr_read_mvendorid());
    nprintf("marchid:   0x%08X (%d)\n", csr_read_marchid(), csr_read_marchid());
    nprintf("mimpid:    0x%08X (%d)\n", csr_read_mimpid(), csr_read_mimpid());
    nprintf("mhartid:   0x%08X (%d)\n", csr_read_mhartid(), csr_read_mhartid());
    nprintf("misa:      0x%08X (", misa);

    for (int i = 0; i < 32; ++i) {
        if (misa & (1 << i)) {
            nprintf("%s", isa_letters[i]);
        }
    }
    nprintf(")\n");
    for (int i = 0; i < 32; ++i) {
        if (misa & (1 << i)) {
            nprintf("  Bit %2d: %s %s\n", i, isa_letters[i], isa_descriptions[i]);
        }
    }
    nprintf("\n");
}
