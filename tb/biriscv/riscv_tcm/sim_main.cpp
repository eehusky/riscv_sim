#include <memory>
#include <getopt.h>

#include <verilated.h>

#include "elf_load.h"
#include "mem_api.h"

#include "Vtb_riscv_tcm_top.h"
#include "Vtb_riscv_tcm_top__Syms.h"

#define CLK_PERIOD 10
#define MEM_BASE 0x00000000
#define MEM_SIZE (64 * 1024)
#define GETOPTS_ARGS "f:c:h"

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
    Vtb_riscv_tcm_top           *m_dut;
    uint32_t           lo_addr;
    uint32_t           hi_addr;

    bootstrap(Vtb_riscv_tcm_top *dut)
    {
        m_dut = dut;
        lo_addr = 0xFFFFFFFF;
        hi_addr = 0x0;
    }

    bool create_memory(uint32_t base, uint32_t size, uint8_t *mem = NULL)
    {
        assert(base >= MEM_BASE && ((base + size) < (MEM_BASE + MEM_SIZE)));
        return true;
    }
    bool valid_addr(uint32_t addr) { return true; }
    void write(uint32_t addr, uint8_t data)
    {
        lo_addr = addr<lo_addr ? addr : lo_addr;
        hi_addr = addr>hi_addr ? addr : hi_addr;
        m_dut->tb_riscv_tcm_top->i_riscv_tcm_top->vlSymsp->\
            TOP__tb_riscv_tcm_top__i_riscv_tcm_top__i_riscv_tcm_top__u_tcm.write(addr, data);
    }
    uint8_t read(uint32_t addr)
    {
        return m_dut->tb_riscv_tcm_top->i_riscv_tcm_top->vlSymsp->\
            TOP__tb_riscv_tcm_top__i_riscv_tcm_top__i_riscv_tcm_top__u_tcm.read(addr);
    }

    void dump()
    {
        printf("lo_addr = 0x%08X\n", lo_addr);
        printf("hi_addr = 0x%08X\n", hi_addr);
        for (int i = 0; i < hi_addr-lo_addr; i+=8)
        {
            printf(
                "%02X %02X %02X %02X %02X %02X %02X %02X\n",
                read(i+0),
                read(i+1),
                read(i+2),
                read(i+3),
                read(i+4),
                read(i+5),
                read(i+6),
                read(i+7)
            );
        }
    }


};




int main(int argc, char** argv) {

    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    contextp->debug(0);
    contextp->randReset(0);
    contextp->traceEverOn(true);
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

    const std::unique_ptr<Vtb_riscv_tcm_top> top{new Vtb_riscv_tcm_top{contextp.get(), "TOP"}};
    bootstrap *boot = new bootstrap(top.get());
    elf_load elf(filename, boot);
    if (!elf.load()) {
        fprintf (stderr,"Error: Could not open %s\n", filename);
        exit(1);
    }

    top->i_clk = 0;
    top->i_rst = 1;
    top->i_rst_cpu = 1;

    while (!contextp->gotFinish()) {
        contextp->timeInc(CLK_PERIOD/2);
        top->i_clk = !top->i_clk;
        top->eval();
        if (contextp->time() > 1000) {
            break;
        }
    }
    boot->dump();
    top->i_rst = 0;
    top->i_rst_cpu = 0;

    while (!contextp->gotFinish() && !(max_cycles != -1 && cycles >= max_cycles)) {
        contextp->timeInc(CLK_PERIOD/2);
        top->i_clk = !top->i_clk;
        top->eval();
        cycles += 1;
    }

    top->final();

    contextp->statsPrintSummary();

    return 0;
}
