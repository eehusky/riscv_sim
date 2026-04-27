#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#include "biriscv_extensions.h"
#include "ringbuffer_addrmap.h"

#include "mm2s_ringbuffer.h"
#include "ringbuffer_explode.h"
#include "risvc_io.h"
#include "s2mm_ringbuffer.h"
#include "test_mm2s_ringbuffer.h"

#define MTIME_FREQ_HZ 100000000

#define MTIMER_SECONDS_TO_CLOCKS(SEC) ((uint64_t)(((SEC) * (MTIME_FREQ_HZ))))

#define MTIMER_MSEC_TO_CLOCKS(MSEC) ((uint64_t)(((MSEC) * (MTIME_FREQ_HZ)) / 1000))

#define MTIMER_USEC_TO_CLOCKS(USEC) ((uint64_t)(((USEC) * (MTIME_FREQ_HZ)) / 1000000))

uint32_t timer_calls = 0;
uint32_t s2mm_n_bytes = 0;
uint32_t mm2s_n_bytes = 0;
struct mm2s_ringbuffer *mm2s_0;
struct s2mm_ringbuffer *s2mm_0;

void riscv_mtvec_mti(void)
{
    // continue timer chain, period + previous compare
    biriscv_timer_set_mtimecmp(biriscv_timer_get_mtimecmp() + MTIMER_USEC_TO_CLOCKS(10));
    timer_calls += 1;
}

void interrupt_stuff()
{
    // start timer chain, period + current time
    biriscv_timer_set_mtimecmp(biriscv_timer_get_mtime() + MTIMER_USEC_TO_CLOCKS(10));
    while (1) {
        asm volatile("wfi");
        if (timer_calls == 10) {
            break;
        }
    }
}

char putbuffer[256];
char getbuffer[256];

void ringbuffer_puts(char *s) { biriscv_putstring(s); }
void ringbuffer_cache_writeback(uint32_t addr, uint32_t count) { biriscv_dcache_writeback_range((addr), (count)); }

static inline void mm2s_ringbuffer_isr(struct mm2s_ringbuffer *dev)
{
    biriscv_putstring("  mm2s_ringbuffer_isr\n");
    uint32_t enabled;
    uint32_t active;
    uint32_t pending;

    enabled = mm2s_ringbuffer_read_intr_enable(dev);
    active = mm2s_ringbuffer_read_intr_active(dev);
    pending = active & enabled;

    while (pending) {

        if (pending & MM2S_RINGBUFFERX__INTR_ACTIVE__ERROR_bm) {
            biriscv_putstring("    mm2s_ringbuffer_isr_error\n");
            mm2s_ringbuffer_clear_intr(dev, MM2S_RINGBUFFERX__INTR_ACTIVE__ERROR_bm);
        }
        if (pending & MM2S_RINGBUFFERX__INTR_ACTIVE__LEVEL_bm) {
            biriscv_putstring("    mm2s_ringbuffer_isr_level\n");

            int rv;
            rv = mm2s_ringbuffer_put(mm2s_0, putbuffer, 256);
            if (rv > 0) {
                mm2s_n_bytes += rv;
            }
            // biriscv_dcache_flush();
            mm2s_ringbuffer_commit(mm2s_0);

            if (mm2s_n_bytes > 4096) {
                mm2s_ringbuffer_write_intr_enable(dev, 0);
            }

            mm2s_ringbuffer_clear_intr(dev, MM2S_RINGBUFFERX__INTR_ACTIVE__LEVEL_bm);
        }
        enabled = mm2s_ringbuffer_read_intr_enable(dev);
        active = mm2s_ringbuffer_read_intr_active(dev);
        pending = active & enabled;
    }
    // biriscv_putstring("Exiting\n");
    // biriscv_sim_exit(0);
}
static inline void s2mm_ringbuffer_isr(struct s2mm_ringbuffer *dev)
{
    biriscv_putstring("  s2mm_ringbuffer_isr\n");
    uint32_t enabled;
    uint32_t active;
    uint32_t pending;

    enabled = s2mm_ringbuffer_read_intr_enable(dev);
    active = s2mm_ringbuffer_read_intr_active(dev);
    pending = active & enabled;

    while (pending) {
        if (pending & S2MM_RINGBUFFERX__INTR_ACTIVE__OVERRUN_bm) {
            biriscv_putstring("    s2mm_ringbuffer_isr_overrun\n");
            s2mm_ringbuffer_clear_intr(dev, S2MM_RINGBUFFERX__INTR_ACTIVE__OVERRUN_bm);
        }
        if (pending & S2MM_RINGBUFFERX__INTR_ACTIVE__ERROR_bm) {
            biriscv_putstring("    s2mm_ringbuffer_isr_error\n");
            s2mm_ringbuffer_clear_intr(dev, S2MM_RINGBUFFERX__INTR_ACTIVE__ERROR_bm);
        }
        if (pending & S2MM_RINGBUFFERX__INTR_ACTIVE__LEVEL_bm) {
            biriscv_putstring("    s2mm_ringbuffer_isr_level\n");
            s2mm_n_bytes += s2mm_ringbuffer_level(dev);
            s2mm_ringbuffer_flush(dev);
            // int rv;
            // do {
            //     rv = s2mm_ringbuffer_get(dev, getbuffer, 256);
            //     if (rv > 0) {
            //         s2mm_n_bytes += rv;
            //     }
            //     s2mm_ringbuffer_commit(dev);
            // } while (rv > 0);
            s2mm_ringbuffer_clear_intr(dev, S2MM_RINGBUFFERX__INTR_ACTIVE__LEVEL_bm);
        }
        enabled = s2mm_ringbuffer_read_intr_enable(dev);
        active = s2mm_ringbuffer_read_intr_active(dev);
        pending = active & enabled;
    }
}

void riscv_mtvec_mei(void)
{
    uint32_t enabled;
    uint32_t active;
    uint32_t pending;

    biriscv_putstring("riscv_mtvec_mei\n");

    enabled = read32(0xa0000000);
    active = read32(0xa0000004);
    pending = active & enabled;

    while (pending) {
        if (pending & RINGBUFFER__INTR_ACTIVE__S2MM_0_bm) {
            s2mm_ringbuffer_isr(s2mm_0);
        }
        if (pending & RINGBUFFER__INTR_ACTIVE__MM2S_0_bm) {
            mm2s_ringbuffer_isr(mm2s_0);
        }
        enabled = read32(0xa0000000);
        active = read32(0xa0000004);
        pending = active & enabled;
    }
}

struct mm2s_ringbuffer *configure_mm2s(void *dev_address, void *buffer, size_t buffer_size, int32_t instance)
{
    int rc;
    struct mm2s_ringbuffer *dev;

    biriscv_putstring("configure_mm2s\n");

    dev = mm2s_ringbuffer_init(dev_address);
    if (dev == NULL) {
        biriscv_putstring("mm2s_ringbuffer_init failed\n");
        return NULL;
    }

    rc = mm2s_ringbuffer_set_buffer(dev, buffer, buffer_size);
    if (rc) {
        biriscv_putstring("mm2s_ringbuffer_set_buffer failed\n");
        return NULL;
    }

    rc = mm2s_ringbuffer_start(dev);
    if (rc) {
        biriscv_putstring("mm2s_ringbuffer_start failed\n");
        return NULL;
    }

    return dev;
}
struct s2mm_ringbuffer *configure_s2mm(void *dev_address, void *buffer, size_t buffer_size, int32_t instance)
{
    int rc;
    struct s2mm_ringbuffer *dev;

    biriscv_putstring("configure_s2mm\n");

    dev = s2mm_ringbuffer_init(dev_address);
    if (dev == NULL) {
        biriscv_putstring("s2mm_ringbuffer_init failed\n");
        return NULL;
    }

    rc = s2mm_ringbuffer_set_buffer(dev, buffer, buffer_size);
    if (rc) {
        biriscv_putstring("s2mm_ringbuffer_set_buffer failed\n");
        return NULL;
    }

    rc = s2mm_ringbuffer_start(dev);
    if (rc) {
        biriscv_putstring("s2mm_ringbuffer_start failed\n");
        return NULL;
    }

    s2mm_ringbuffer_set_threshold(dev, 255);
    s2mm_ringbuffer_write_intr_enable(dev, S2MM_RINGBUFFERX__INTR_ENABLE__LEVEL_bm);

    return dev;
}

#define BUFFER_SIZE 4096
unsigned char buffers[4][BUFFER_SIZE] __attribute__((aligned(4096)));

int main(void)
{
    ringbuffer_t *inst = ((ringbuffer_t *)0xa0000000UL);

    write32(0xa0000000, RINGBUFFER__INTR_ENABLE__S2MM_0_bm | RINGBUFFER__INTR_ENABLE__MM2S_0_bm);

    mm2s_0 = configure_mm2s((void *)&(inst->mm2s_ringbuffer[0]), buffers[0], BUFFER_SIZE, 0);
    s2mm_0 = configure_s2mm((void *)&(inst->s2mm_ringbuffer[0]), buffers[1], BUFFER_SIZE, 0);

    // mm2s_ringbuffer_set_threshold(mm2s_0, 1);
    // mm2s_ringbuffer_write_intr_enable(mm2s_0, MM2S_RINGBUFFERX__INTR_ENABLE__LEVEL_bm);

    for (int i = 0; i < 256; ++i) {
        putbuffer[i] = i;
    }

    int rv;
    rv = mm2s_ringbuffer_put(mm2s_0, putbuffer, 256);
    if (rv > 0) {
        mm2s_n_bytes += rv;
    }
    biriscv_dcache_flush();
    mm2s_ringbuffer_commit(mm2s_0);

    for (int i = 0; i < 1000; ++i) {
        asm volatile("nop");
    }

    printf("s2mm_n_bytes=%d\n", s2mm_n_bytes);
    printf("mm2s_n_bytes=%d\n", mm2s_n_bytes);

    biriscv_putstring("Done\n");
    biriscv_sim_exit(0);
}
