#include <stdint.h>
#include <stddef.h>



#define N_COUNTERS 12

// clang-format off
char *riscv_hpm_counter_names[N_COUNTERS] = {
    [0] = "NumCycles",
    [1] = "NumInstrRet",
    [2] = "NumCyclesLSU",
    [3] = "NumCyclesIF",
    [4] = "NumLoads",
    [5] = "NumStores",
    [6] = "NumJumps",
    [7] = "NumBranches",
    [8] = "NumBranchesTaken",
    [9] = "NumInstrRetC",
    [10] = "NumCyclesMulWait",
    [11] = "NumCyclesDivWait",
};
// clang-format on


extern void riscv_hpm_pause(void);
extern void riscv_hpm_clear_counters(void);
extern void riscv_hpm_resume(void);

void riscv_hpm_init_counters(void)
{
    riscv_hpm_pause();
    riscv_hpm_clear_counters();
    riscv_hpm_resume();
}


uint32_t riscv_hpm_get_n_counters(void) { return N_COUNTERS; }
char *riscv_hpm_get_counter_name(uint32_t index)
{
    if (index < N_COUNTERS) {
        return riscv_hpm_counter_names[index];
    }

    return NULL;
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
}
