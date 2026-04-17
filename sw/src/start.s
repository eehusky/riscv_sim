/* start.S */
.section .text.start
.global _start

_start:
    la sp, _stack_top    # Load the stack pointer address from linker script
    call main            # Jump to C main function
