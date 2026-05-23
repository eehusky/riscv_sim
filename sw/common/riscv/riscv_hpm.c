#include <stddef.h>
#include <stdint.h>

#include "riscv_hpm.h"
#include "riscv_csr.h"

#include "nstdio.h"


char *__attribute__((weak)) riscv_hpm_counter_names[32] = {
    [0] = "mcycle",         [1] = "time",           [2] = "minstret",       [3] = "mhpmcounter3",
    [4] = "mhpmcounter4",   [5] = "mhpmcounter5",   [6] = "mhpmcounter6",   [7] = "mhpmcounter7",
    [8] = "mhpmcounter8",   [9] = "mhpmcounter9",   [10] = "mhpmcounter10", [11] = "mhpmcounter11",
    [12] = "mhpmcounter12", [13] = "mhpmcounter13", [14] = "mhpmcounter14", [15] = "mhpmcounter15",
    [16] = "mhpmcounter16", [17] = "mhpmcounter17", [18] = "mhpmcounter18", [19] = "mhpmcounter19",
    [20] = "mhpmcounter20", [21] = "mhpmcounter21", [22] = "mhpmcounter22", [23] = "mhpmcounter23",
    [24] = "mhpmcounter24", [25] = "mhpmcounter25", [26] = "mhpmcounter26", [27] = "mhpmcounter27",
    [28] = "mhpmcounter28", [29] = "mhpmcounter29", [30] = "mhpmcounter30", [31] = "mhpmcounter31",
};

uint32_t  __attribute__((weak)) riscv_hpm_get_n_counters(void) { return 32; }
char * __attribute__((weak)) riscv_hpm_get_counter_name(uint32_t index)
{
    if (index < 32) {
        return riscv_hpm_counter_names[index];
    }

    return NULL;
}

void riscv_hpm_init_counters(void)
{
    riscv_hpm_pause();
    riscv_hpm_clear_counters();
    riscv_hpm_select_counters();
    riscv_hpm_resume();
}

void riscv_hpm_pause(void) { csr_write_mcountinhibit(0xFFFFFFFF); }

void riscv_hpm_resume(void) { csr_write_mcountinhibit(0); }

void riscv_hpm_clear_counters(void)
{
    asm volatile("csrw mcycle,        zero");
    // asm volatile("csrw time,          zero");
    asm volatile("csrw minstret,      zero");
    asm volatile("csrw mhpmcounter3,  zero");
    asm volatile("csrw mhpmcounter4,  zero");
    asm volatile("csrw mhpmcounter5,  zero");
    asm volatile("csrw mhpmcounter6,  zero");
    asm volatile("csrw mhpmcounter7,  zero");
    asm volatile("csrw mhpmcounter8,  zero");
    asm volatile("csrw mhpmcounter9,  zero");
    asm volatile("csrw mhpmcounter10, zero");
    asm volatile("csrw mhpmcounter11, zero");
    asm volatile("csrw mhpmcounter12, zero");
    asm volatile("csrw mhpmcounter13, zero");
    asm volatile("csrw mhpmcounter14, zero");
    asm volatile("csrw mhpmcounter15, zero");
    asm volatile("csrw mhpmcounter16, zero");
    asm volatile("csrw mhpmcounter17, zero");
    asm volatile("csrw mhpmcounter18, zero");
    asm volatile("csrw mhpmcounter19, zero");
    asm volatile("csrw mhpmcounter20, zero");
    asm volatile("csrw mhpmcounter21, zero");
    asm volatile("csrw mhpmcounter22, zero");
    asm volatile("csrw mhpmcounter23, zero");
    asm volatile("csrw mhpmcounter24, zero");
    asm volatile("csrw mhpmcounter25, zero");
    asm volatile("csrw mhpmcounter26, zero");
    asm volatile("csrw mhpmcounter27, zero");
    asm volatile("csrw mhpmcounter28, zero");
    asm volatile("csrw mhpmcounter29, zero");
    asm volatile("csrw mhpmcounter30, zero");
    asm volatile("csrw mhpmcounter31, zero");
}

void riscv_hpm_select_counters(void)
{
    // asm volatile ("csrw  mhpmevent0,  %0" : : "r" (1<<0) : ); // mcycle
    // asm volatile ("csrw  mhpmevent1,  %0" : : "r" (1<<1) : ); // time
    // asm volatile ("csrw  mhpmevent2,  %0" : : "r" (1<<2) : ); // minstret
    asm volatile("csrw    mhpmevent3,  %0" : : "r"(1 << 3) :);
    asm volatile("csrw    mhpmevent4,  %0" : : "r"(1 << 4) :);
    asm volatile("csrw    mhpmevent5,  %0" : : "r"(1 << 5) :);
    asm volatile("csrw    mhpmevent6,  %0" : : "r"(1 << 6) :);
    asm volatile("csrw    mhpmevent7,  %0" : : "r"(1 << 7) :);
    asm volatile("csrw    mhpmevent8,  %0" : : "r"(1 << 8) :);
    asm volatile("csrw    mhpmevent9,  %0" : : "r"(1 << 9) :);
    asm volatile("csrw    mhpmevent10, %0" : : "r"(1 << 10) :);
    asm volatile("csrw    mhpmevent11, %0" : : "r"(1 << 11) :);
    asm volatile("csrw    mhpmevent12, %0" : : "r"(1 << 12) :);
    asm volatile("csrw    mhpmevent13, %0" : : "r"(1 << 13) :);
    asm volatile("csrw    mhpmevent14, %0" : : "r"(1 << 14) :);
    asm volatile("csrw    mhpmevent15, %0" : : "r"(1 << 15) :);
    asm volatile("csrw    mhpmevent16, %0" : : "r"(1 << 16) :);
    asm volatile("csrw    mhpmevent17, %0" : : "r"(1 << 17) :);
    asm volatile("csrw    mhpmevent18, %0" : : "r"(1 << 18) :);
    asm volatile("csrw    mhpmevent19, %0" : : "r"(1 << 19) :);
    asm volatile("csrw    mhpmevent20, %0" : : "r"(1 << 20) :);
    asm volatile("csrw    mhpmevent21, %0" : : "r"(1 << 21) :);
    asm volatile("csrw    mhpmevent22, %0" : : "r"(1 << 22) :);
    asm volatile("csrw    mhpmevent23, %0" : : "r"(1 << 23) :);
    asm volatile("csrw    mhpmevent24, %0" : : "r"(1 << 24) :);
    asm volatile("csrw    mhpmevent25, %0" : : "r"(1 << 25) :);
    asm volatile("csrw    mhpmevent26, %0" : : "r"(1 << 26) :);
    asm volatile("csrw    mhpmevent27, %0" : : "r"(1 << 27) :);
    asm volatile("csrw    mhpmevent28, %0" : : "r"(1 << 28) :);
    asm volatile("csrw    mhpmevent29, %0" : : "r"(1 << 29) :);
    asm volatile("csrw    mhpmevent30, %0" : : "r"(1 << 30) :);
    asm volatile("csrw    mhpmevent31, %0" : : "r"(1 << 31) :);
}

void riscv_hpm_fetch_events(uint32_t data[32])
{
    // asm volatile("csrr %0, mhpmevent0" : "=r"(data[0]));
    // asm volatile("csrr %0, mhpmevent1" : "=r"(data[1]));
    // asm volatile("csrr %0, mhpmevent2" : "=r"(data[2]));
    asm volatile("csrr %0, mhpmevent3" : "=r"(data[3]));
    asm volatile("csrr %0, mhpmevent4" : "=r"(data[4]));
    asm volatile("csrr %0, mhpmevent5" : "=r"(data[5]));
    asm volatile("csrr %0, mhpmevent6" : "=r"(data[6]));
    asm volatile("csrr %0, mhpmevent7" : "=r"(data[7]));
    asm volatile("csrr %0, mhpmevent8" : "=r"(data[8]));
    asm volatile("csrr %0, mhpmevent9" : "=r"(data[9]));
    asm volatile("csrr %0, mhpmevent10" : "=r"(data[10]));
    asm volatile("csrr %0, mhpmevent11" : "=r"(data[11]));
    asm volatile("csrr %0, mhpmevent12" : "=r"(data[12]));
    asm volatile("csrr %0, mhpmevent13" : "=r"(data[13]));
    asm volatile("csrr %0, mhpmevent14" : "=r"(data[14]));
    asm volatile("csrr %0, mhpmevent15" : "=r"(data[15]));
    asm volatile("csrr %0, mhpmevent16" : "=r"(data[16]));
    asm volatile("csrr %0, mhpmevent17" : "=r"(data[17]));
    asm volatile("csrr %0, mhpmevent18" : "=r"(data[18]));
    asm volatile("csrr %0, mhpmevent19" : "=r"(data[19]));
    asm volatile("csrr %0, mhpmevent20" : "=r"(data[20]));
    asm volatile("csrr %0, mhpmevent21" : "=r"(data[21]));
    asm volatile("csrr %0, mhpmevent22" : "=r"(data[22]));
    asm volatile("csrr %0, mhpmevent23" : "=r"(data[23]));
    asm volatile("csrr %0, mhpmevent24" : "=r"(data[24]));
    asm volatile("csrr %0, mhpmevent25" : "=r"(data[25]));
    asm volatile("csrr %0, mhpmevent26" : "=r"(data[26]));
    asm volatile("csrr %0, mhpmevent27" : "=r"(data[27]));
    asm volatile("csrr %0, mhpmevent28" : "=r"(data[28]));
    asm volatile("csrr %0, mhpmevent29" : "=r"(data[29]));
    asm volatile("csrr %0, mhpmevent30" : "=r"(data[30]));
    asm volatile("csrr %0, mhpmevent31" : "=r"(data[31]));
}

void riscv_hpm_fetch_counters(uint32_t data[32])
{
    asm volatile("csrr %0, mcycle" : "=r"(data[0]));
    // asm volatile("csrr %0, "         : "=r"(data[1]));
    asm volatile("csrr %0, minstret" : "=r"(data[2]));
    asm volatile("csrr %0, mhpmcounter3" : "=r"(data[3]));
    asm volatile("csrr %0, mhpmcounter4" : "=r"(data[4]));
    asm volatile("csrr %0, mhpmcounter5" : "=r"(data[5]));
    asm volatile("csrr %0, mhpmcounter6" : "=r"(data[6]));
    asm volatile("csrr %0, mhpmcounter7" : "=r"(data[7]));
    asm volatile("csrr %0, mhpmcounter8" : "=r"(data[8]));
    asm volatile("csrr %0, mhpmcounter9" : "=r"(data[9]));
    asm volatile("csrr %0, mhpmcounter10" : "=r"(data[10]));
    asm volatile("csrr %0, mhpmcounter11" : "=r"(data[11]));
    asm volatile("csrr %0, mhpmcounter12" : "=r"(data[12]));
    asm volatile("csrr %0, mhpmcounter13" : "=r"(data[13]));
    asm volatile("csrr %0, mhpmcounter14" : "=r"(data[14]));
    asm volatile("csrr %0, mhpmcounter15" : "=r"(data[15]));
    asm volatile("csrr %0, mhpmcounter16" : "=r"(data[16]));
    asm volatile("csrr %0, mhpmcounter17" : "=r"(data[17]));
    asm volatile("csrr %0, mhpmcounter18" : "=r"(data[18]));
    asm volatile("csrr %0, mhpmcounter19" : "=r"(data[19]));
    asm volatile("csrr %0, mhpmcounter20" : "=r"(data[20]));
    asm volatile("csrr %0, mhpmcounter21" : "=r"(data[21]));
    asm volatile("csrr %0, mhpmcounter22" : "=r"(data[22]));
    asm volatile("csrr %0, mhpmcounter23" : "=r"(data[23]));
    asm volatile("csrr %0, mhpmcounter24" : "=r"(data[24]));
    asm volatile("csrr %0, mhpmcounter25" : "=r"(data[25]));
    asm volatile("csrr %0, mhpmcounter26" : "=r"(data[26]));
    asm volatile("csrr %0, mhpmcounter27" : "=r"(data[27]));
    asm volatile("csrr %0, mhpmcounter28" : "=r"(data[28]));
    asm volatile("csrr %0, mhpmcounter29" : "=r"(data[29]));
    asm volatile("csrr %0, mhpmcounter30" : "=r"(data[30]));
    asm volatile("csrr %0, mhpmcounter31" : "=r"(data[31]));
}



void riscv_hpm_counters_dump(void)
{
    uint32_t data[32];

    riscv_hpm_pause();

    riscv_hpm_fetch_counters(data);

    for (int i = 0; i < riscv_hpm_get_n_counters(); ++i) {
        nprintf("%16s:  %u\n", riscv_hpm_get_counter_name(i), (uint32_t)data[i]);
    }

    riscv_hpm_resume();
}
