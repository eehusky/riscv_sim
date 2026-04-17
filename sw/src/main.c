/* main.c */
//#define UART_BASE 0x10000000 // Common base for QEMU 'virt' machine

#define UART_BASE 0x92000004
#define ULITE_STATUS 0x92000008

#define UART_THR  ((volatile char*)(UART_BASE + 0))
#define UART_STATUS  ((volatile char*)(ULITE_STATUS + 0))
void uart_putc(char c) {
    *UART_THR = c; // Write character to Transmit Holding Register
}

#define CSR_SIM_CTRL_EXIT (0 << 24)
#define CSR_SIM_CTRL_PUTC (1 << 24)

static inline void sim_exit(int exitcode)
{
    unsigned int arg = CSR_SIM_CTRL_EXIT | ((unsigned char)exitcode);
    asm volatile ("csrw dscratch,%0": : "r" (arg));
}

static inline void sim_putc(int ch)
{
    unsigned int arg = CSR_SIM_CTRL_PUTC | (ch & 0xFF);
    asm volatile ("csrw dscratch,%0": : "r" (arg));
}

char *msg = "Hello RISC-V Bare-metal!\n";

#include <stdlib.h>
#include <stdio.h>
void main() {

    //while(1);
    char *p;

    //void *d = malloc(1024);

    p = msg;
    while (*p) {
        sim_putc(*p++);
    }
    p = msg;
    while (*p) {
        while(((*UART_STATUS) & (1<<3)));
        uart_putc(*p++);
    }

    while(!((*UART_STATUS) & (1<<2)));

    printf(msg);

    sim_exit(0);
}


//rv32i/ilp32;@march=rv32i@mabi=ilp32
//rv32im/ilp32;@march=rv32im@mabi=ilp32
//rv32iac/ilp32;@march=rv32iac@mabi=ilp32
//rv32imac/ilp32;@march=rv32imac@mabi=ilp32
//rv32imafc/ilp32f;@march=rv32imafc@mabi=ilp32f
//rv64imac/lp64;@march=rv64imac@mabi=lp64
//rv64imafdc/lp64d;@march=rv64imafdc@mabi=lp64d
