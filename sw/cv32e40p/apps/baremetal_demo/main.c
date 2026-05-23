#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "riscv_csr.h"
#include "riscv_hpm.h"
#include "riscv_info.h"

#include "nstdio.h"
#include "riscv_io.h"
#include "sim_extensions.h"
#include "vector_table.h"

#define ITCM_ADDR 0x80000000
#define ITCM_SIZE 0x00020000
#define MTIME_ADDR 0x00002000
#define MTIME_SIZE 0x00001000
#define SIMCTRL_ADDR 0x00003000
#define SIMCTRL_SIZE 0x00001000
#define DTCM_ADDR 0x80020000
#define DTCM_SIZE 0x00020000
#define CACHED_ADDR 0x90000000
#define CACHED_SIZE 0x00020000
#define UNCACHED_ADDR 0xA0000000
#define UNCACHED_SIZE 0x00020000
#define AXIL_ADDR 0xB0000000
#define AXIL_SIZE 0x00020000

float e(int interations)
{
    // https://stackoverflow.com/a/37715090
    float number = interations;
    float factorial = 1;
    float constant = 0;
    float counter = interations;
    float variable = 0;
    float euler = 0;

    while (counter > 1) {
        variable = number;

        factorial = 1;
        while (number > 1) {
            factorial = factorial * number;
            number--;
        } // number is now 1

        constant = (1 / factorial) + constant;
        counter--;
        variable = variable - 1;
        number = variable;
    }

    euler = constant + 1 + (1 / 1.f); // the 1 and 1/1! in the original formula...
    // nprintf("e = : %f\n", euler);
    return euler;
}

float pi(int iterations)
{
    float pi = 0.0;
    int sign = 1;

    for (int i = 1; i <= iterations * 2; i += 2) {
        pi += sign * (4.0f / i);
        sign = -sign;
    }

    return pi;
}

void do_floats(void)
{
    sim_putstring("  cv32e40p floats demo\n");

    nprintf("    computing pi with 5000 iterations\n");
    float computed_pi = pi(5000);
    nprintf("      pi is:   %.12f (%.12f) error=%.12f\n", computed_pi, M_PI, ((float)M_PI) - computed_pi);

    nprintf("    computing e with 8 iterations\n");
    float computed_e = e(8);
    nprintf("      e is:    %.12f (%.12f) error=%.12f\n", computed_e, M_E, ((float)M_E) - computed_e);
}

void do_mtime(void)
{
    sim_putstring("  ibex mtime demo\n");
    uint64_t mtime = mtime_get();
    mtimecmp_set(mtime + 2048);
    for (int i = 0; i < 10; ++i) {
        asm volatile("wfi");
    }
    csr_clr_bits_mie(MIE_MTI_BIT_MASK);
}

void do_addr(void)
{
    sim_putstring("  cv32e40p addr demo\n");
    uint32_t blah = 0;

    sim_putstring("    cv32e40p cached demo\n");
    write32(CACHED_ADDR, 0xDEADBEEF);
    read32(CACHED_ADDR);
    write32(CACHED_ADDR + CACHED_SIZE - 4, 0xDEADBEEF);
    read32(CACHED_ADDR + CACHED_SIZE - 4);
    for (int i = 0; i < 512; ++i) {
        write32(CACHED_ADDR + (i * 4), blah + 1);
        blah = read32(CACHED_ADDR + (i * 4));
    }

    sim_putstring("    cv32e40p uncached demo\n");
    write32(UNCACHED_ADDR, 0xDEADBEEF);
    read32(UNCACHED_ADDR);
    write32(UNCACHED_ADDR + UNCACHED_SIZE - 4, 0xDEADBEEF);
    read32(UNCACHED_ADDR + UNCACHED_SIZE - 4);
    for (int i = 0; i < 512; ++i) {
        write32(UNCACHED_ADDR + (i * 4), blah + 1);
        blah = read32(UNCACHED_ADDR + (i * 4));
    }

    sim_putstring("    cv32e40p axil demo\n");
    write32(AXIL_ADDR, 0xDEADBEEF);
    read32(AXIL_ADDR);
    write32(AXIL_ADDR + AXIL_SIZE - 4, 0xDEADBEEF);
    read32(AXIL_ADDR + AXIL_SIZE - 4);
    for (int i = 0; i < 512; ++i) {
        write32(AXIL_ADDR + (i * 4), blah + 1);
        blah = read32(AXIL_ADDR + (i * 4));
    }
}

int main(void)
{
    sim_putstring("cv32e40p main demo\n");
    riscv_dump_info();

    riscv_hpm_init_counters();


    do_floats();
    do_mtime();
    do_addr();

    sim_putstring("  cv32e40p counter demo\n");

    riscv_hpm_counters_dump();

    return 0;
}

void riscv_mtvec_mti(void)
{
    sim_putstring("    riscv_mtvec_mti\n");
    uint64_t mtimecmp = mtimecmp_get();
    mtimecmp_set(mtimecmp + 2048);
}
