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

#define ITCM_ADDR     0x80000000
#define ITCM_SIZE     0x00020000
#define MTIME_ADDR    0x00002000
#define MTIME_SIZE    0x00001000
#define SIMCTRL_ADDR  0x00003000
#define SIMCTRL_SIZE  0x00001000
#define DTCM_ADDR     0x80020000
#define DTCM_SIZE     0x00020000
#define CACHED_ADDR   0x90000000
#define CACHED_SIZE   0x00020000
#define UNCACHED_ADDR 0xA0000000
#define UNCACHED_SIZE 0x00020000
#define AXIL_ADDR     0xB0000000
#define AXIL_SIZE     0x00020000


// mcycle(h)        0xB00 (0xB80) 0 NumCycles
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

char *counter_names[16]={
    [0]  ="CYCLES"      ,
    [1]  ="INSTR"       ,
    [2]  ="LD_STALL"    ,
    [3]  ="JMP_STALL"   ,
    [4]  ="IMISS"       ,
    [5]  ="LD"          ,
    [6]  ="ST"          ,
    [7]  ="JUMP"        ,
    [8]  ="BRANCH"      ,
    [9]  ="BRANCH_TAKEN",
    [10] ="COMP_INSTR"  ,
    [11] ="PIPE_STALL"  ,
    [12] ="APU_TYPE"    ,
    [13] ="APU_CONT"    ,
    [14] ="APU_DEP"     ,
    [15] ="APU_WB"      ,
    //[16] ="RESERVED"    ,
    //[17] ="RESERVED"    ,
    //[18] ="RESERVED"    ,
    //[19] ="RESERVED"    ,
    //[20] ="RESERVED"    ,
    //[21] ="RESERVED"    ,
    //[22] ="RESERVED"    ,
    //[23] ="RESERVED"    ,
    //[24] ="RESERVED"    ,
    //[25] ="RESERVED"    ,
    //[26] ="RESERVED"    ,
    //[27] ="RESERVED"    ,
    //[28] ="RESERVED"    ,
    //[29] ="RESERVED"    ,
    //[30] ="RESERVED"    ,
    //[31] ="RESERVED"    ,
};

void dump_counters(void)
{
    csr_write_mcountinhibit(0xFFFFFFFF);
    uint32_t data[16];

    //asm volatile("csrr %0, mhpmcounter1" : "=r"(data[1]));
    //asm volatile("csrr %0, mhpmcounter2" : "=r"(data[2]));
    data[0] = csr_read_mcycle();
    data[1] = csr_read_minstret();
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
    //asm volatile("csrr %0, mhpmcounter17" : "=r"(data[16]));
    //asm volatile("csrr %0, mhpmcounter18" : "=r"(data[17]));
    //asm volatile("csrr %0, mhpmcounter19" : "=r"(data[18]));
    //asm volatile("csrr %0, mhpmcounter20" : "=r"(data[19]));
    //asm volatile("csrr %0, mhpmcounter21" : "=r"(data[20]));
    //asm volatile("csrr %0, mhpmcounter22" : "=r"(data[21]));
    //asm volatile("csrr %0, mhpmcounter23" : "=r"(data[22]));
    //asm volatile("csrr %0, mhpmcounter24" : "=r"(data[23]));
    //asm volatile("csrr %0, mhpmcounter25" : "=r"(data[24]));
    //asm volatile("csrr %0, mhpmcounter26" : "=r"(data[25]));
    //asm volatile("csrr %0, mhpmcounter27" : "=r"(data[26]));
    //asm volatile("csrr %0, mhpmcounter28" : "=r"(data[27]));
    //asm volatile("csrr %0, mhpmcounter29" : "=r"(data[28]));
    //asm volatile("csrr %0, mhpmcounter30" : "=r"(data[29]));
    //asm volatile("csrr %0, mhpmcounter31" : "=r"(data[30]));

    for (int i = 0; i < 16; ++i)
    {
        nprintf("%13s:  %u\n", counter_names[i], (uint32_t)data[i]);
    }

    csr_write_mcountinhibit(0);
}

void enable_counters(void)
{
    csr_write_mcountinhibit(0xFFFFFFFF);

    //asm volatile ("csrw    mhpmevent1,  %0" : : "r" (1<<1) : );
    //asm volatile ("csrw    mhpmevent2,  %0" : : "r" (1<<2) : );
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
    //asm volatile ("csrw    mhpmevent17, %0" : : "r" (1<<17) : );
    //asm volatile ("csrw    mhpmevent18, %0" : : "r" (1<<18) : );
    //asm volatile ("csrw    mhpmevent19, %0" : : "r" (1<<19) : );
    //asm volatile ("csrw    mhpmevent20, %0" : : "r" (1<<20) : );
    //asm volatile ("csrw    mhpmevent21, %0" : : "r" (1<<21) : );
    //asm volatile ("csrw    mhpmevent22, %0" : : "r" (1<<22) : );
    //asm volatile ("csrw    mhpmevent23, %0" : : "r" (1<<23) : );
    //asm volatile ("csrw    mhpmevent24, %0" : : "r" (1<<24) : );
    //asm volatile ("csrw    mhpmevent25, %0" : : "r" (1<<25) : );
    //asm volatile ("csrw    mhpmevent26, %0" : : "r" (1<<26) : );
    //asm volatile ("csrw    mhpmevent27, %0" : : "r" (1<<27) : );
    //asm volatile ("csrw    mhpmevent28, %0" : : "r" (1<<28) : );
    //asm volatile ("csrw    mhpmevent29, %0" : : "r" (1<<29) : );
    //asm volatile ("csrw    mhpmevent30, %0" : : "r" (1<<30) : );
    //asm volatile ("csrw    mhpmevent31, %0" : : "r" (1<<31) : );

    csr_write_mcountinhibit(0);
}


//void do_floats(void)
//{
//    sim_putstring("  cv32e40p floats demo\n");
//    float x = 3.14159;
//    x*= (float)((uint32_t)mtime_get());
//    x*= (float)((uint32_t)mtime_get());
//    nprintf("%s %.6f\n", "    pi is", 3.14159f);
//    nprintf("%s %.6f\n", "    e is", 2.718f);
//    nprintf("%s %.6f\n", "    random is", x);
//}

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

int main(void)
{
    sim_putstring("cv32e40p main demo\n");

    enable_counters();

    //do_floats();
    do_mtime();
    do_addr();

    sim_putstring("  cv32e40p counter demo\n");
    dump_counters();
    return 0;
}

void riscv_mtvec_mti(void)
{
    sim_putstring("    riscv_mtvec_mti\n");
    uint64_t mtimecmp = mtimecmp_get();
    mtimecmp_set(mtimecmp + 2048);
}
