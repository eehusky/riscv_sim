#include <stdint.h>

#include "biriscv_extensions.h"
#include "riscv-csr.h"
#include "riscv-interrupts.h"

// void riscv_mtvec_table(void)  __attribute__ ((naked, section(".text.mtvec_table") ,aligned(16)));
// void riscv_mtvec_table(void) {
//     __asm__ volatile (
//         ".org  riscv_mtvec_table + 0*4;"
//         "jal   zero,riscv_mtvec_exception;"  /* 0  */
//         ".org  riscv_mtvec_table + 1*4;"
//         "jal   zero,riscv_mtvec_ssi;"  /* 1  */
//         ".org  riscv_mtvec_table + 3*4;"
//         "jal   zero,riscv_mtvec_msi;"  /* 3  */
//         ".org  riscv_mtvec_table + 5*4;"
//         "jal   zero,riscv_mtvec_sti;"  /* 5  */
//         ".org  riscv_mtvec_table + 7*4;"
//         "jal   zero,riscv_mtvec_mti;"  /* 7  */
//         ".org  riscv_mtvec_table + 9*4;"
//         "jal   zero,riscv_mtvec_sei;"  /* 9  */
//         ".org  riscv_mtvec_table + 11*4;"
//         "jal   zero,riscv_mtvec_mei;"  /* 11 */
//         ".org  riscv_mtvec_table + 16*4;"
//         "jal   riscv_mtvec_platform_irq0;"
//         "jal   riscv_mtvec_platform_irq1;"
//         "jal   riscv_mtvec_platform_irq2;"
//         "jal   riscv_mtvec_platform_irq3;"
//         "jal   riscv_mtvec_platform_irq4;"
//         "jal   riscv_mtvec_platform_irq5;"
//         "jal   riscv_mtvec_platform_irq6;"
//         "jal   riscv_mtvec_platform_irq7;"
//         "jal   riscv_mtvec_platform_irq8;"
//         "jal   riscv_mtvec_platform_irq9;"
//         "jal   riscv_mtvec_platform_irq10;"
//         "jal   riscv_mtvec_platform_irq11;"
//         "jal   riscv_mtvec_platform_irq12;"
//         "jal   riscv_mtvec_platform_irq13;"
//         "jal   riscv_mtvec_platform_irq14;"
//         "jal   riscv_mtvec_platform_irq15;"
//
//         : /* output: none */
//         : /* input : immediate */
//         : /* clobbers: none */
//         );
// }

void riscv_mtvec_nop(void) {}

void riscv_mtvec_ssi(void) __attribute__((weak));
void riscv_mtvec_msi(void) __attribute__((weak));
void riscv_mtvec_usi(void) __attribute__((weak));
void riscv_mtvec_sti(void) __attribute__((weak));
void riscv_mtvec_mti(void) __attribute__((weak));
void riscv_mtvec_uti(void) __attribute__((weak));
void riscv_mtvec_sei(void) __attribute__((weak));
void riscv_mtvec_mei(void) __attribute__((weak));
void riscv_mtvec_uei(void) __attribute__((weak));
void riscv_mtvec_platform_irq0(void) __attribute__((weak));
void riscv_mtvec_platform_irq1(void) __attribute__((weak));
void riscv_mtvec_platform_irq2(void) __attribute__((weak));
void riscv_mtvec_platform_irq3(void) __attribute__((weak));
void riscv_mtvec_platform_irq4(void) __attribute__((weak));
void riscv_mtvec_platform_irq5(void) __attribute__((weak));
void riscv_mtvec_platform_irq6(void) __attribute__((weak));
void riscv_mtvec_platform_irq7(void) __attribute__((weak));
void riscv_mtvec_platform_irq8(void) __attribute__((weak));
void riscv_mtvec_platform_irq9(void) __attribute__((weak));
void riscv_mtvec_platform_irq10(void) __attribute__((weak));
void riscv_mtvec_platform_irq11(void) __attribute__((weak));
void riscv_mtvec_platform_irq12(void) __attribute__((weak));
void riscv_mtvec_platform_irq13(void) __attribute__((weak));
void riscv_mtvec_platform_irq14(void) __attribute__((weak));
void riscv_mtvec_platform_irq15(void) __attribute__((weak));
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

void riscv_excp_instruction_address_misaligned(void) __attribute__((weak));
void riscv_excp_instruction_access_fault(void) __attribute__((weak));
void riscv_excp_illegal_instruction(void) __attribute__((weak));
void riscv_excp_breakpoint(void) __attribute__((weak));
void riscv_excp_load_address_misaligned(void) __attribute__((weak));
void riscv_excp_load_access_fault(void) __attribute__((weak));
void riscv_excp_store_amo_address_misaligned(void) __attribute__((weak));
void riscv_excp_store_amo_access_fault(void) __attribute__((weak));
void riscv_excp_environment_call_from_u_mode(void) __attribute__((weak));
void riscv_excp_environment_call_from_s_mode(void) __attribute__((weak));
void riscv_excp_reserved10(void) __attribute__((weak));
void riscv_excp_environment_call_from_m_mode(void) __attribute__((weak));
void riscv_excp_instruction_page_fault(void) __attribute__((weak));
void riscv_excp_load_page_fault(void) __attribute__((weak));
void riscv_excp_reserved14(void) __attribute__((weak));
void riscv_excp_store_amo_page_fault(void) __attribute__((weak));
void (*exception_handlers[32])(void) = {
    [0] = riscv_excp_instruction_address_misaligned, /* Instruction address misaligned */
    [1] = riscv_excp_instruction_access_fault,       /* Instruction access fault */
    [2] = riscv_excp_illegal_instruction,            /* Illegal instruction */
    [3] = riscv_excp_breakpoint,                     /* Breakpoint */
    [4] = riscv_excp_load_address_misaligned,        /* Load address misaligned */
    [5] = riscv_excp_load_access_fault,              /* Load access fault */
    [6] = riscv_excp_store_amo_address_misaligned,   /* Store/AMO address misaligned  */
    [7] = riscv_excp_store_amo_access_fault,         /* Store/AMO access fault */
    [8] = riscv_excp_environment_call_from_u_mode,   /* Environment call from U-mode */
    [9] = riscv_excp_environment_call_from_s_mode,   /* Environment call from S-mode */
    [10] = riscv_excp_reserved10,                    /* Reserved */
    [11] = riscv_excp_environment_call_from_m_mode,  /* Environment call from M-mode */
    [12] = riscv_excp_instruction_page_fault,        /* Instruction page fault */
    [13] = riscv_excp_load_page_fault,               /* Load page fault */
    [14] = riscv_excp_reserved14,                    /* Reserved */
    [15] = riscv_excp_store_amo_page_fault,          /* Store/AMO page fault */
    [16] = riscv_mtvec_nop,
    [17] = riscv_mtvec_nop,
    [18] = riscv_mtvec_nop,
    [19] = riscv_mtvec_nop,
    [20] = riscv_mtvec_nop,
    [21] = riscv_mtvec_nop,
    [22] = riscv_mtvec_nop,
    [23] = riscv_mtvec_nop,
    [24] = riscv_mtvec_nop,
    [25] = riscv_mtvec_nop,
    [26] = riscv_mtvec_nop,
    [27] = riscv_mtvec_nop,
    [28] = riscv_mtvec_nop,
    [29] = riscv_mtvec_nop,
    [30] = riscv_mtvec_nop,
    [31] = riscv_mtvec_nop,
};

#define MCAUSE_INT 0x80000000
#define MCAUSE_CAUSE 0x0000001F
void handle_trap()
{
    unsigned long mcause = csr_read_mcause();
    if (mcause & MCAUSE_INT) {
        // mask interrupt bit and branch to handler
        interrupt_handlers[mcause & MCAUSE_CAUSE]();
    } else {
        // synchronous exception, branch to handler
        exception_handlers[mcause & MCAUSE_CAUSE]();
    }
}

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

void riscv_mtvec_exception(void) __attribute__((interrupt("machine"))) __attribute__((aligned(64)));
void riscv_mtvec_exception(void)
{
    uint_xlen_t this_cause = csr_read_mcause();

    if (this_cause & MCAUSE_INT) {
        riscv_mtvec_interrupt();
        return;
    }

    biriscv_putstring("mtvec_exception\n");

    switch (this_cause) {
    case RISCV_EXCP_INSTRUCTION_ADDRESS_MISALIGNED:
        biriscv_putstring("RISCV_EXCP_INSTRUCTION_ADDRESS_MISALIGNED\n");
        break;
    case RISCV_EXCP_INSTRUCTION_ACCESS_FAULT:
        biriscv_putstring("RISCV_EXCP_INSTRUCTION_ACCESS_FAULT\n");
        break;
    case RISCV_EXCP_ILLEGAL_INSTRUCTION:
        biriscv_putstring("RISCV_EXCP_ILLEGAL_INSTRUCTION\n");
        break;
    case RISCV_EXCP_BREAKPOINT:
        biriscv_putstring("RISCV_EXCP_BREAKPOINT\n");
        break;
    case RISCV_EXCP_LOAD_ADDRESS_MISALIGNED:
        biriscv_putstring("RISCV_EXCP_LOAD_ADDRESS_MISALIGNED\n");
        break;
    case RISCV_EXCP_LOAD_ACCESS_FAULT:
        biriscv_putstring("RISCV_EXCP_LOAD_ACCESS_FAULT\n");
        break;
    case RISCV_EXCP_STORE_AMO_ADDRESS_MISALIGNED:
        biriscv_putstring("RISCV_EXCP_STORE_AMO_ADDRESS_MISALIGNED\n");
        break;
    case RISCV_EXCP_STORE_AMO_ACCESS_FAULT:
        biriscv_putstring("RISCV_EXCP_STORE_AMO_ACCESS_FAULT\n");
        break;
    case RISCV_EXCP_ENVIRONMENT_CALL_FROM_U_MODE:
        biriscv_putstring("RISCV_EXCP_ENVIRONMENT_CALL_FROM_U_MODE\n");
        break;
    case RISCV_EXCP_ENVIRONMENT_CALL_FROM_S_MODE:
        biriscv_putstring("RISCV_EXCP_ENVIRONMENT_CALL_FROM_S_MODE\n");
        break;
    case RISCV_EXCP_RESERVED10:
        biriscv_putstring("RISCV_EXCP_RESERVED10\n");
        break;
    case RISCV_EXCP_ENVIRONMENT_CALL_FROM_M_MODE:
        biriscv_putstring("RISCV_EXCP_ENVIRONMENT_CALL_FROM_M_MODE\n");
        // Make sure the return address is the instruction AFTER ecall
        csr_write_mepc(csr_read_mepc() + 4);
        break;
    case RISCV_EXCP_INSTRUCTION_PAGE_FAULT:
        biriscv_putstring("RISCV_EXCP_INSTRUCTION_PAGE_FAULT\n");
        break;
    case RISCV_EXCP_LOAD_PAGE_FAULT:
        biriscv_putstring("RISCV_EXCP_LOAD_PAGE_FAULT\n");
        break;
    case RISCV_EXCP_RESERVED14:
        biriscv_putstring("RISCV_EXCP_RESERVED14\n");
        break;
    case RISCV_EXCP_STORE_AMO_PAGE_FAULT:
        biriscv_putstring("RISCV_EXCP_STORE_AMO_PAGE_FAULT\n");
        break;
    }
    biriscv_sim_exit(0);
}
