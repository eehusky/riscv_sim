#include <assert.h>
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

// Bit Character   Description
// 0   A           Atomic extension
// 1   B           Tentatively reserved for Bit-Manipulation extension
// 2   C           Compressed extension
// 3   D           Double-precision floating-point extension
// 4   E           RV32E base ISA
// 5   F           Single-precision floating-point extension
// 6   G           Reserved
// 7   H           Hypervisor extension
// 8   I           RV32I/64I/128I base ISA
// 9   J           Tentatively reserved for Dynamically Translated Languages extension
// 10  K           Reserved
// 11  L           Reserved
// 12  M           Integer Multiply/Divide extension
// 13  N           Tentatively reserved for User-Level Interrupts extension
// 14  O           Reserved
// 15  P           Tentatively reserved for Packed-SIMD extension
// 16  Q           Quad-precision floating-point extension
// 17  R           Reserved
// 18  S           Supervisor mode implemented
// 19  T           Reserved
// 20  U           User mode implemented
// 21  V           Tentatively reserved for Vector extension
// 22  W           Reserved
// 23  X           Non-standard extensions present
// 24  Y           Reserved
// 25  Z           Reserved

// clang-format off
char *isa_descriptions[32]={
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
char isa_letters[32]={
    [0] =  'A',
    [1] =  'B',
    [2] =  'C',
    [3] =  'D',
    [4] =  'E',
    [5] =  'F',
    [6] =  'G',
    [7] =  'H',
    [8] =  'I',
    [9] =  'J',
    [10] = 'K',
    [11] = 'L',
    [12] = 'M',
    [13] = 'N',
    [14] = 'O',
    [15] = 'P',
    [16] = 'Q',
    [17] = 'R',
    [18] = 'S',
    [19] = 'T',
    [20] = 'U',
    [21] = 'V',
    [22] = 'W',
    [23] = 'X',
    [24] = 'Y',
    [25] = 'Z',
    [26] = '*',
    [27] = '*',
    [28] = '*',
    [29] = '*',
    [30] = '*',
    [31] = '*',
};


// mcycle(h)        0xB00 (0xB80) 0 NumCycles
// time(h)                        1 ---
// minstret(h)      0xB02 (0xB82) 2 NumInstrRet
// mhpmcounter3(h)  0xB03 (0xB83) 3 NumCyclesLSU
// mhpmcounter4(h)  0xB04 (0xB84) 4 NumCyclesIF
// mhpmcounter5(h)  0xB05 (0xB85) 5 NumLoads
// mhpmcounter6(h)  0xB06 (0xB86) 6 NumStores
// mhpmcounter7(h)  0xB07 (0xB87) 7 NumJumps
// mhpmcounter8(h)  0xB08 (0xB88) 8 NumBranches
// mhpmcounter9(h)  0xB09 (0xB89) 9 NumBranchesTaken
// mhpmcounter10(h) 0xB0A (0xB8A) 10 NumInstrRetC
// mhpmcounter11(h) 0xB0B (0xB8B) 11 NumCyclesMulWait
// mhpmcounter12(h) 0xB0C (0xB8C) 12 NumCyclesDivWait


char *  __attribute__((weak)) counter_names2[32]={
    [0]  ="mcycle",
    [1]  ="time" ,
    [2]  ="minstret",
    [3]  ="mhpmcounter3",
    [4]  ="mhpmcounter4",
    [5]  ="mhpmcounter5",
    [6]  ="mhpmcounter6",
    [7]  ="mhpmcounter7",
    [8]  ="mhpmcounter8",
    [9]  ="mhpmcounter9",
    [10] ="mhpmcounter10",
    [11] ="mhpmcounter11",
    [12] ="mhpmcounter12",
    [13] ="mhpmcounter13",
    [14] ="mhpmcounter14",
    [15] ="mhpmcounter15",
    [16] ="mhpmcounter16",
    [17] ="mhpmcounter17",
    [18] ="mhpmcounter18",
    [19] ="mhpmcounter19",
    [20] ="mhpmcounter20",
    [21] ="mhpmcounter21",
    [22] ="mhpmcounter22",
    [23] ="mhpmcounter23",
    [24] ="mhpmcounter24",
    [25] ="mhpmcounter25",
    [26] ="mhpmcounter26",
    [27] ="mhpmcounter27",
    [28] ="mhpmcounter28",
    [29] ="mhpmcounter29",
    [30] ="mhpmcounter30",
    [31] ="mhpmcounter31",
};


#define N_COUNTERS 13
char *counter_names[N_COUNTERS]={
    [0] = "NumCycles",
    [1] = "Time",
    [2] = "NumInstrRet",
    [3] = "NumCyclesLSU",
    [4] = "NumCyclesIF",
    [5] = "NumLoads",
    [6] = "NumStores",
    [7] = "NumJumps",
    [8] = "NumBranches",
    [9] = "NumBranchesTaken",
    [10] = "NumInstrRetC",
    [11] = "NumCyclesMulWait",
    [12] = "NumCyclesDivWait",
};
extern char *counter_names[N_COUNTERS];
// clang-format on

void dump_info(void)
{
    uint32_t misa = csr_read_misa();

    nprintf("mvendorid: 0x%08X\n",csr_read_mvendorid());
    nprintf("marchid:   0x%08X\n",csr_read_marchid());
    nprintf("mimpid:    0x%08X\n",csr_read_mimpid());
    nprintf("mhartid:   0x%08X\n",csr_read_mhartid());
    nprintf("misa:      0x%08X  ",misa);

    for (int i = 0; i < 32; ++i) {
        if(misa &(1<<i)){
            nprintf("%c",isa_letters[i]);
        }
    }
    nprintf("\n");
    for (int i = 0; i < 32; ++i) {
        if(misa &(1<<i)){
            nprintf("  Bit %2d: %c %s\n",i, isa_letters[i], isa_descriptions[i]);
        }
    }
    nprintf("\n");
}


void reset_counters(void)
{
    asm volatile("csrw mcycle,        zero");
    //asm volatile("csrw time,          zero");
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
void select_counters(void)
{
    //asm volatile ("csrw  mhpmevent0,  %0" : : "r" (1<<0) : ); // mcycle
    //asm volatile ("csrw  mhpmevent1,  %0" : : "r" (1<<1) : ); // time
    //asm volatile ("csrw  mhpmevent2,  %0" : : "r" (1<<2) : ); // minstret
    asm volatile ("csrw    mhpmevent3,  %0" : : "r" (1<<3) : );
    asm volatile ("csrw    mhpmevent4,  %0" : : "r" (1<<4) : );
    asm volatile ("csrw    mhpmevent5,  %0" : : "r" (1<<5) : );
    asm volatile ("csrw    mhpmevent6,  %0" : : "r" (1<<6) : );
    asm volatile ("csrw    mhpmevent7,  %0" : : "r" (1<<7) : );
    asm volatile ("csrw    mhpmevent8,  %0" : : "r" (1<<8) : );
    asm volatile ("csrw    mhpmevent9,  %0" : : "r" (1<<9) : );
    asm volatile ("csrw    mhpmevent10, %0" : : "r" (1<<10) : );
    asm volatile ("csrw    mhpmevent11, %0" : : "r" (1<<11) : );
    asm volatile ("csrw    mhpmevent12, %0" : : "r" (1<<12) : );
    asm volatile ("csrw    mhpmevent13, %0" : : "r" (1<<13) : );
    asm volatile ("csrw    mhpmevent14, %0" : : "r" (1<<14) : );
    asm volatile ("csrw    mhpmevent15, %0" : : "r" (1<<15) : );
    asm volatile ("csrw    mhpmevent16, %0" : : "r" (1<<16) : );
    asm volatile ("csrw    mhpmevent17, %0" : : "r" (1<<17) : );
    asm volatile ("csrw    mhpmevent18, %0" : : "r" (1<<18) : );
    asm volatile ("csrw    mhpmevent19, %0" : : "r" (1<<19) : );
    asm volatile ("csrw    mhpmevent20, %0" : : "r" (1<<20) : );
    asm volatile ("csrw    mhpmevent21, %0" : : "r" (1<<21) : );
    asm volatile ("csrw    mhpmevent22, %0" : : "r" (1<<22) : );
    asm volatile ("csrw    mhpmevent23, %0" : : "r" (1<<23) : );
    asm volatile ("csrw    mhpmevent24, %0" : : "r" (1<<24) : );
    asm volatile ("csrw    mhpmevent25, %0" : : "r" (1<<25) : );
    asm volatile ("csrw    mhpmevent26, %0" : : "r" (1<<26) : );
    asm volatile ("csrw    mhpmevent27, %0" : : "r" (1<<27) : );
    asm volatile ("csrw    mhpmevent28, %0" : : "r" (1<<28) : );
    asm volatile ("csrw    mhpmevent29, %0" : : "r" (1<<29) : );
    asm volatile ("csrw    mhpmevent30, %0" : : "r" (1<<30) : );
    asm volatile ("csrw    mhpmevent31, %0" : : "r" (1<<31) : );
}

void counters_init(void)
{
    csr_write_mcountinhibit(0xFFFFFFFF);
    reset_counters();
    select_counters();
    csr_write_mcountinhibit(0);
}

void counters_fetch_hpmevent(uint32_t data[32])
{
    //asm volatile("csrr %0, mhpmevent0" : "=r"(data[0]));
    //asm volatile("csrr %0, mhpmevent1" : "=r"(data[1]));
    //asm volatile("csrr %0, mhpmevent2" : "=r"(data[2]));
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

void counters_fetch_hpmcounter(uint32_t data[32])
{
    uint32_t inhibit = csr_read_mcountinhibit();
    asm volatile("csrr %0, mcycle"       : "=r"(data[0]));
    //asm volatile("csrr %0, "         : "=r"(data[1]));
    asm volatile("csrr %0, minstret"     : "=r"(data[2]));
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
    csr_write_mcountinhibit(inhibit);
}

void counters_dump(void)
{
    uint32_t data[32];

    csr_write_mcountinhibit(0xFFFFFFFF);
    counters_fetch_hpmcounter(data);

    for (int i = 0; i < N_COUNTERS; ++i)
    {
        nprintf("%16s:  %u\n", counter_names[i], (uint32_t)data[i]);
    }
    csr_write_mcountinhibit(0);
}

int main(void)
{
    sim_putstring("cv32e40p main demo\n");

    dump_info();

    counters_init();

    //sim_putstring("  cv32e40p counter demo\n");
    counters_dump();
    return 0;
}

void do_mtime(void)
{
    sim_putstring("  cv32e40p mtime demo\n");
    uint64_t mtime = mtime_get();
    mtimecmp_set(mtime + 2048);
    asm volatile("wfi");
    asm volatile("wfi");
    csr_clr_bits_mie(MIE_MTI_BIT_MASK);
}

void do_addr(void)
{
    sim_putstring("  cv32e40p addr demo\n");
    uint32_t blah = 0;

    sim_putstring("    cv32e40p cached demo\n");
    write32(CACHED_ADDR,0xDEADBEEF);
    read32(CACHED_ADDR);
    write32(CACHED_ADDR+CACHED_SIZE-4,0xDEADBEEF);
    read32(CACHED_ADDR+CACHED_SIZE-4);
    for (int i = 0; i < 512; ++i)
    {
        write32(CACHED_ADDR+(i*4),blah+1);
        blah = read32(CACHED_ADDR+(i*4));
    }

    sim_putstring("    cv32e40p uncached demo\n");
    write32(UNCACHED_ADDR,0xDEADBEEF);
    read32(UNCACHED_ADDR);
    write32(UNCACHED_ADDR+UNCACHED_SIZE-4,0xDEADBEEF);
    read32(UNCACHED_ADDR+UNCACHED_SIZE-4);
    for (int i = 0; i < 512; ++i)
    {
        write32(UNCACHED_ADDR+(i*4),blah+1);
        blah = read32(UNCACHED_ADDR+(i*4));
    }

    sim_putstring("    cv32e40p axil demo\n");
    write32(AXIL_ADDR,0xDEADBEEF);
    read32(AXIL_ADDR);
    write32(AXIL_ADDR+AXIL_SIZE-4,0xDEADBEEF);
    read32(AXIL_ADDR+AXIL_SIZE-4);
    for (int i = 0; i < 512; ++i)
    {
        write32(AXIL_ADDR+(i*4),blah+1);
        blah = read32(AXIL_ADDR+(i*4));
    }

}

int main2(void)
{
    sim_putstring("cv32e40p main demo\n");

    dump_info();

    select_counters();

    //do_floats();
    do_mtime();
    do_addr();

    sim_putstring("  cv32e40p counter demo\n");
    return 0;
}

void riscv_mtvec_mti(void)
{
    sim_putstring("    riscv_mtvec_mti\n");
    uint64_t mtimecmp = mtimecmp_get();
    mtimecmp_set(mtimecmp + 2048);
}
