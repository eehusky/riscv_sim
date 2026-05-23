#include <stdint.h>
#include <stddef.h>

char *riscv_hpm_counter_names[13] = {
    [0] = "NumCycles",         [1] = "Time",          [2] = "NumInstrRet",
    [3] = "NumCyclesLSU",      [4] = "NumCyclesIF",   [5] = "NumLoads",
    [6] = "NumStores",         [7] = "NumJumps",      [8] = "NumBranches",
    [9] = "NumBranchesTaken",  [10] = "NumInstrRetC", [11] = "NumCyclesMulWait",
    [12] = "NumCyclesDivWait",
};

uint32_t riscv_hpm_get_n_counters(void) { return 13; }
char *riscv_hpm_get_counter_name(uint32_t index)
{
    if (index < 13) {
        return riscv_hpm_counter_names[index];
    }

    return NULL;
}
