/* crt0.S */
.section .text.start
.global _start

_start:
    la sp, _stack_top                   // Load the stack pointer address from linker script
    la a0, freertos_risc_v_trap_handler // Load the exception handler
    csrw mtvec, a0                      // into mtvec
    call main                           // Jump to C main function
