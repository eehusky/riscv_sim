#include <memory>
#include <getopt.h>

#include <verilated.h>

#include "elf_load.h"
#include "mem_api.h"

#include "Vtb_cva5.h"
#include "Vtb_cva5__Syms.h"

#define CLK_PERIOD 10
#define MEM_BASE (0x80000000)
#define MEM_SIZE (1<<17)
#define GETOPTS_ARGS "f:c:h"

#define ITCM_BASE 0x80000000
#define ITCM_SIZE 0x00020000
#define DTCM_BASE 0x80020000
#define DTCM_SIZE 0x00020000

static struct option long_options[] =
{
    {"elf",        required_argument, 0, 'f'},
    {"cycles",     required_argument, 0, 'c'},
    {"help",       no_argument,       0, 'h'},
    {0, 0, 0, 0}
};

static void help_options(void)
{
    fprintf (stderr,"Usage:\n");
    fprintf (stderr,"  --elf         | -f FILE       File to load\n");
    fprintf (stderr,"  --cycles      | -c NUM        Max instructions to execute\n");
    exit(-1);
}



class bootstrap: public mem_api
{
public:
    Vtb_cva5           *m_dut;
    uint32_t           lo_addr;
    uint32_t           hi_addr;

    bootstrap(Vtb_cva5 *dut)
    {
        m_dut = dut;
        lo_addr = 0xFFFFFFFF;
        hi_addr = 0x0;
    }

    bool create_memory(uint32_t base, uint32_t size, uint8_t *mem = NULL)
    {
        //printf("base=%08X size=%08X\n", base, size);
        //assert(base >= MEM_BASE && ((base + size) < (MEM_BASE + MEM_SIZE)));
        return true;
    }
    bool valid_addr(uint32_t addr) { return true; }

    void write_itcm(uint32_t addr, uint8_t data)
    {
        addr = addr-ITCM_BASE;
        lo_addr = addr<lo_addr ? addr : lo_addr;
        hi_addr = addr>hi_addr ? addr : hi_addr;
        m_dut->tb_cva5->vlSymsp->TOP__tb_cva5.write_itcm(addr, data);
    }
    uint8_t read_itcm(uint32_t addr)
    {
        return m_dut->tb_cva5->vlSymsp->TOP__tb_cva5.read_itcm(addr);
    }
    void write_dtcm(uint32_t addr, uint8_t data)
    {
        addr = addr-DTCM_BASE;
        m_dut->tb_cva5->vlSymsp->TOP__tb_cva5.write_dtcm(addr, data);
    }
    uint8_t read_dtcm(uint32_t addr)
    {
        addr = addr-DTCM_BASE;
        return m_dut->tb_cva5->vlSymsp->TOP__tb_cva5.read_dtcm(addr);
    }


    void write(uint32_t addr, uint8_t data)
    {
        //printf("addr=%08X\n", addr);
        if(addr >= DTCM_BASE && addr < DTCM_BASE+DTCM_SIZE){
            write_dtcm(addr, data);
        } else if(addr >= ITCM_BASE && addr < ITCM_BASE+ITCM_SIZE){
            write_itcm(addr, data);
        }

    }
    uint8_t read(uint32_t addr)
    {
        return read_itcm(addr);
    }


    void dump()
    {
        printf("lo_addr = 0x%08X\n", lo_addr);
        printf("hi_addr = 0x%08X\n", hi_addr);
        for (int lo = lo_addr; lo < hi_addr; lo+=8)
        {
            printf(
                "%02X %02X %02X %02X %02X %02X %02X %02X\n",
                read(lo+0),
                read(lo+1),
                read(lo+2),
                read(lo+3),
                read(lo+4),
                read(lo+5),
                read(lo+6),
                read(lo+7)
            );
        }
    }

};



int main(int argc, char** argv) {

    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    contextp->debug(0);
    contextp->randReset(0);
    #ifdef VM_TRACE
    contextp->traceEverOn(true);
    #endif
    contextp->commandArgs(argc, argv);


    uint64_t       cycles         = 0;
    int64_t        max_cycles     = (int64_t)-1;
    const char *   filename       = NULL;
    int            help           = 0;
    int c;
    int option_index = 0;
    while ((c = getopt_long (argc, argv, GETOPTS_ARGS, long_options, &option_index)) != -1) {
        switch(c) {
            case 'f':
                filename = optarg;
                break;
            case 'c':
                max_cycles = (int64_t)strtoull(optarg, NULL, 0);
                break;
            case '?':
            default:
                help = 1;
                break;
        }
    }

    if (help || filename == NULL) {
        help_options();
        return 0;
    }

    const std::unique_ptr<Vtb_cva5> top{new Vtb_cva5{contextp.get(), "TOP"}};
    bootstrap *boot = new bootstrap(top.get());


    top->i_clk = 0;
    top->i_rst = 1;
    top->eval();

    elf_load elf(filename, boot);
    if (!elf.load()) {
        fprintf (stderr,"Error: Could not open %s\n", filename);
        exit(1);
    }

    while (!contextp->gotFinish()) {
        contextp->timeInc(CLK_PERIOD/2);
        top->i_clk = !top->i_clk;
        top->eval();
        if (contextp->time() > 1000) {
            break;
        }
    }

    //boot->dump();
    top->i_rst = 0;

    while (!contextp->gotFinish() && !(max_cycles != -1 && cycles >= max_cycles)) {
        contextp->timeInc(CLK_PERIOD/2);
        top->i_clk = !top->i_clk;
        top->eval();
        cycles += 1;
    }
    if (!contextp->gotFinish()){

        printf("\033[33m Reached Cycle Count Limit, Exiting \033[0m \n");
    }


    top->final();

    contextp->statsPrintSummary();

    return 0;
}
