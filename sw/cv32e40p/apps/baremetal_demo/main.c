#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>


#include "riscv_io.h"



int main(void)
{
    uint32_t base = 0x80000000|(1<<16);
    //volatile uint32_t *data = (uint32_t*)(1<<16);

    write32(base,0xDEADBEEF);
    read32(base);
    //read32(base+4);
    //write32(0x10000000,0xDEADBEEF);
    //write32(0x10000000,0xDEADBEEF);
    //write32(base+4,0xCAFEBABE);

    //volatile float x = 3.14159;
    //x= x*2;
    //write32(base+8,*((uint32_t*)&x));

    //volatile int blah =0;
    //for (int i = 0; i < 10; ++i)
    //{
    //    blah+=1;
    //}
    //uint32_t terminate = 0x1A110800;


    //asm volatile("j    %0"
    //             :            /* output: none */
    //             : "r"(terminate) /* input : register */
    //             : /* clobbers: none */);

}
