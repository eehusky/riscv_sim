#include <stdint.h>


#include "riscv_io.h"
#include "sim_extensions.h"
#include "vector_table.h"
#include "riscv_csr.h"
#include "riscv_interrupts.h"

static void riscv_mtvec_nop(void) {}
// ----------------------------------------------------------------------------
// -- Interrupt Handlers ------------------------------------------------------
// ----------------------------------------------------------------------------

void riscv_mtvec_ssi(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_ssi(void)
{
    sim_putstring("riscv_mtvec_ssi\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_msi(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_msi(void)
{
    sim_putstring("riscv_mtvec_msi\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_usi(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_usi(void)
{
    sim_putstring("riscv_mtvec_usi\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_sti(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_sti(void)
{
    sim_putstring("riscv_mtvec_sti\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_mti(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_mti(void)
{
    sim_putstring("riscv_mtvec_mti\n");
    // sim_exit(0x80000000);
}
void riscv_mtvec_uti(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_uti(void)
{
    sim_putstring("riscv_mtvec_uti\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_sei(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_sei(void)
{
    sim_putstring("riscv_mtvec_sei\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_mei(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_mei(void)
{
    sim_putstring("riscv_mtvec_mei\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_uei(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_uei(void)
{
    sim_putstring("riscv_mtvec_uei\n");
    sim_exit(0x80000000);
}

// ----------------------------------------------------------------------------
// -- Exception Handlers ------------------------------------------------------
// ----------------------------------------------------------------------------

void riscv_mtvec_instruction_address_misaligned(void)
{
    sim_putstring("mtvec_instruction_address_misaligned\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_instruction_access_fault(void)
{
    sim_putstring("mtvec_instruction_access_fault\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_illegal_instruction(void)
{
    sim_putstring("mtvec_illegal_instruction\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_breakpoint(void)
{
    sim_putstring("mtvec_breakpoint\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_load_address_misaligned(void)
{
    sim_putstring("mtvec_load_address_misaligned\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_load_access_fault(void)
{
    sim_putstring("mtvec_load_access_fault\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_store_amo_address_misaligned(void)
{
    sim_putstring("mtvec_store_amo_address_misaligned\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_store_amo_access_fault(void)
{
    sim_putstring("mtvec_store_amo_access_fault\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_environment_call_from_u_mode(void)
{
    sim_putstring("mtvec_environment_call_from_u_mode\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_environment_call_from_s_mode(void)
{
    sim_putstring("mtvec_environment_call_from_s_mode\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_environment_call_from_m_mode(void)
{
    sim_putstring("mtvec_environment_call_from_m_mode\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_instruction_page_fault(void)
{
    sim_putstring("mtvec_instruction_page_fault\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_load_page_fault(void)
{
    sim_putstring("mtvec_load_page_fault\n");
    sim_exit(0x80000000);
}
void riscv_mtvec_store_amo_page_fault(void)
{
    sim_putstring("mtvec_store_amo_page_fault\n");
    sim_exit(0x80000000);
}

void (*exception_handlers[16])(void) = {
    [0] = riscv_mtvec_instruction_address_misaligned, /* Instruction address misaligned */
    [1] = riscv_mtvec_instruction_access_fault,       /* Instruction access fault */
    [2] = riscv_mtvec_illegal_instruction,            /* Illegal instruction */
    [3] = riscv_mtvec_breakpoint,                     /* Breakpoint */
    [4] = riscv_mtvec_load_address_misaligned,        /* Load address misaligned */
    [5] = riscv_mtvec_load_access_fault,              /* Load access fault */
    [6] = riscv_mtvec_store_amo_address_misaligned,   /* Store/AMO address misaligned  */
    [7] = riscv_mtvec_store_amo_access_fault,         /* Store/AMO access fault */
    [8] = riscv_mtvec_environment_call_from_u_mode,   /* Environment call from U-mode */
    [9] = riscv_mtvec_environment_call_from_s_mode,   /* Environment call from S-mode */
    [10] = riscv_mtvec_nop,                           /* Reserved */
    [11] = riscv_mtvec_environment_call_from_m_mode,  /* Environment call from M-mode */
    [12] = riscv_mtvec_instruction_page_fault,        /* Instruction page fault */
    [13] = riscv_mtvec_load_page_fault,               /* Load page fault */
    [14] = riscv_mtvec_nop,                           /* Reserved */
    [15] = riscv_mtvec_store_amo_page_fault,          /* Store/AMO page fault */
};

#define MCAUSE_INT 0x80000000
#define MCAUSE_INT_CAUSE 0x0000001F
#define MCAUSE_EXCP_CAUSE 0x0000000F
void (*interrupt_handlers[32])(void) = {
    [0] = riscv_mtvec_usi,
    [1] = riscv_mtvec_ssi,
    [2] = riscv_mtvec_nop,
    [3] = riscv_mtvec_msi,
    [4] = riscv_mtvec_uti,
    [5] = riscv_mtvec_sti,
    [6] = riscv_mtvec_nop,
    [7] = riscv_mtvec_mti,
    [8] = riscv_mtvec_uei,
    [9] = riscv_mtvec_sei,
    [10] = riscv_mtvec_nop,
    [11] = riscv_mtvec_mei,
    [12] = riscv_mtvec_nop,
    [13] = riscv_mtvec_nop,
    [14] = riscv_mtvec_nop,
    [15] = riscv_mtvec_nop,
    [16] = riscv_mtvec_platform_irq0,
    [17] = riscv_mtvec_platform_irq1,
    [18] = riscv_mtvec_platform_irq2,
    [19] = riscv_mtvec_platform_irq3,
    [20] = riscv_mtvec_platform_irq4,
    [21] = riscv_mtvec_platform_irq5,
    [22] = riscv_mtvec_platform_irq6,
    [23] = riscv_mtvec_platform_irq7,
    [24] = riscv_mtvec_platform_irq8,
    [25] = riscv_mtvec_platform_irq9,
    [26] = riscv_mtvec_platform_irq10,
    [27] = riscv_mtvec_platform_irq11,
    [28] = riscv_mtvec_platform_irq12,
    [29] = riscv_mtvec_platform_irq13,
    [30] = riscv_mtvec_platform_irq14,
    [31] = riscv_mtvec_platform_irq15,
};

static inline void riscv_mtvec_interrupt(void)
{
    int i;
    uint_xlen_t mip;
    uint_xlen_t mie;
    uint_xlen_t active;
    while (1) {
        mip = csr_read_mip();
        mie = csr_read_mie();
        active = mip & mie;

        if (!active) {
            return;
        }

        i = 0;
        while (active) {
            if (active & 1) {
                interrupt_handlers[i]();
            }
            active >>= 1;
            i++;
        }
        csr_clr_bits_mip(mip & mie);
    }
}

void riscv_mtvec_exception(void) __attribute__((interrupt("machine"), weak));
void riscv_mtvec_exception(void)
{
    uint_xlen_t this_cause = csr_read_mcause();
    if (this_cause & MCAUSE_INT) {
        riscv_mtvec_interrupt();
        return;
    }
    exception_handlers[this_cause & MCAUSE_EXCP_CAUSE]();
}

void configure_interrupts(void)
{
    // Global interrupt disable
    csr_clr_bits_mstatus(MSTATUS_MIE_BIT_MASK);
    csr_write_mie(0);
    csr_write_mip(0);

    // Setup the IRQ handler entry point, set the mode to vectored
    csr_write_mtvec((uint_xlen_t)riscv_mtvec_table | 1);

    // Enable MIE.MTI
    csr_set_bits_mie(MIE_MEI_BIT_MASK);
    csr_set_bits_mie(MIE_MTI_BIT_MASK);

    // Global interrupt enable
    csr_set_bits_mstatus(MSTATUS_MIE_BIT_MASK);
}

extern int main(void);

void _entry(void)
{
    // clear initial mtime
    mtimecmp_set(0);

    // enable fpu
    csr_set_bits_mstatus(1<<MSTATUS_FS_BIT_OFFSET);

    configure_interrupts();

    int rc = main();

    sim_exit(rc);
}
