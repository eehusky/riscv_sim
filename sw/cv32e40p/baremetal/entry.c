#include <stdint.h>

#include "riscv_csr.h"
#include "riscv_interrupts.h"

extern void riscv_mtvec_exception(void);
#if 0
void riscv_mtvec_instruction_address_misaligned(void)
{
    biriscv_putstring("mtvec_instruction_address_misaligned\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_instruction_access_fault(void)
{
    biriscv_putstring("mtvec_instruction_access_fault\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_illegal_instruction(void)
{
    biriscv_putstring("mtvec_illegal_instruction\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_breakpoint(void)
{
    biriscv_putstring("mtvec_breakpoint\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_load_address_misaligned(void)
{
    biriscv_putstring("mtvec_load_address_misaligned\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_load_access_fault(void)
{
    biriscv_putstring("mtvec_load_access_fault\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_store_amo_address_misaligned(void)
{
    biriscv_putstring("mtvec_store_amo_address_misaligned\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_store_amo_access_fault(void)
{
    biriscv_putstring("mtvec_store_amo_access_fault\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_environment_call_from_u_mode(void)
{
    biriscv_putstring("mtvec_environment_call_from_u_mode\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_environment_call_from_s_mode(void)
{
    biriscv_putstring("mtvec_environment_call_from_s_mode\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_environment_call_from_m_mode(void)
{
    biriscv_putstring("mtvec_environment_call_from_m_mode\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_instruction_page_fault(void)
{
    biriscv_putstring("mtvec_instruction_page_fault\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_load_page_fault(void)
{
    biriscv_putstring("mtvec_load_page_fault\n");
    biriscv_sim_exit(0);
}
void riscv_mtvec_store_amo_page_fault(void)
{
    biriscv_putstring("mtvec_store_amo_page_fault\n");
    biriscv_sim_exit(0);
}

void configure_interrupts(void)
{
    // Global interrupt disable
    csr_clr_bits_mstatus(MSTATUS_MIE_BIT_MASK);
    csr_write_mie(0);

    // Setup the IRQ handler entry point, set the mode to vectored
    csr_write_mtvec((uint_xlen_t)riscv_mtvec_exception | 1);

    // Enable MIE.MTI
    csr_set_bits_mie(MIE_MEI_BIT_MASK);
    csr_set_bits_mie(MIE_MTI_BIT_MASK);

    // Global interrupt enable
    csr_set_bits_mstatus(MSTATUS_MIE_BIT_MASK);
}
#endif

extern int main(void);

void _entry(void)
{
    //configure_interrupts();

    main();

    while(1){
        asm volatile("wfi");
    }
}
