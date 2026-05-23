#include <stdint.h>
#include <stddef.h>

#include "riscv_hpm.h"
#define N_COUNTERS 16

// clang-format off
char *riscv_hpm_counter_names[N_COUNTERS] = {
    [0] = "mcycle",
    [1] = "minstret",
    [2] = "LD_STALL",
    [3] = "JMP_STALL",
    [4] = "IMISS",
    [5] = "LD",
    [6] = "ST",
    [7] = "JUMP",
    [8] = "BRANCH",
    [9] = "BRANCH_TAKEN",
    [10] = "COMP_INSTR",
    [11] = "PIPE_STALL",
    [12] = "APU_TYPE",
    [13] = "APU_CONT",
    [14] = "APU_DEP",
    [15] = "APU_WB",
};
// clang-format on

uint32_t riscv_hpm_get_n_counters(void) { return N_COUNTERS; }
char *riscv_hpm_get_counter_name(uint32_t index)
{
    if (index < N_COUNTERS) {
        return riscv_hpm_counter_names[index];
    }

    return NULL;
}



void riscv_hpm_init_counters(void)
{
    riscv_hpm_pause();
    riscv_hpm_clear_counters();
    asm volatile("csrw    mhpmevent3,  %0" : : "r"(1<<2) :);
    asm volatile("csrw    mhpmevent4,  %0" : : "r"(1<<3) :);
    asm volatile("csrw    mhpmevent5,  %0" : : "r"(1<<4) :);
    asm volatile("csrw    mhpmevent6,  %0" : : "r"(1<<5) :);
    asm volatile("csrw    mhpmevent7,  %0" : : "r"(1<<6) :);
    asm volatile("csrw    mhpmevent8,  %0" : : "r"(1<<7) :);
    asm volatile("csrw    mhpmevent9,  %0" : : "r"(1<<8) :);
    asm volatile("csrw    mhpmevent10, %0" : : "r"(1<<9) :);
    asm volatile("csrw    mhpmevent11, %0" : : "r"(1<<10) :);
    asm volatile("csrw    mhpmevent12, %0" : : "r"(1<<11) :);
    asm volatile("csrw    mhpmevent13, %0" : : "r"(1<<12) :);
    asm volatile("csrw    mhpmevent14, %0" : : "r"(1<<13) :);
    asm volatile("csrw    mhpmevent15, %0" : : "r"(1<<14) :);
    asm volatile("csrw    mhpmevent16, %0" : : "r"(1<<15) :);
    asm volatile("csrw    mhpmevent17, %0" : : "r"(1<<16) :);
    asm volatile("csrw    mhpmevent18, %0" : : "r"(1<<17) :);
    riscv_hpm_resume();
}


void riscv_hpm_fetch_counters(uint32_t data[32])
{
    asm volatile("csrr %0, mcycle" : "=r"(data[0]));
    asm volatile("csrr %0, minstret" : "=r"(data[1]));
    asm volatile("csrr %0, mhpmcounter3" : "=r"(data[2]));
    asm volatile("csrr %0, mhpmcounter4" : "=r"(data[3]));
    asm volatile("csrr %0, mhpmcounter5" : "=r"(data[4]));
    asm volatile("csrr %0, mhpmcounter6" : "=r"(data[5]));
    asm volatile("csrr %0, mhpmcounter7" : "=r"(data[6]));
    asm volatile("csrr %0, mhpmcounter8" : "=r"(data[7]));
    asm volatile("csrr %0, mhpmcounter9" : "=r"(data[8]));
    asm volatile("csrr %0, mhpmcounter10" : "=r"(data[9]));
    asm volatile("csrr %0, mhpmcounter11" : "=r"(data[10]));
    asm volatile("csrr %0, mhpmcounter12" : "=r"(data[11]));
    asm volatile("csrr %0, mhpmcounter13" : "=r"(data[12]));
    asm volatile("csrr %0, mhpmcounter14" : "=r"(data[13]));
    asm volatile("csrr %0, mhpmcounter15" : "=r"(data[14]));
    asm volatile("csrr %0, mhpmcounter16" : "=r"(data[15]));
    asm volatile("csrr %0, mhpmcounter17" : "=r"(data[16]));
    asm volatile("csrr %0, mhpmcounter18" : "=r"(data[17]));
}
