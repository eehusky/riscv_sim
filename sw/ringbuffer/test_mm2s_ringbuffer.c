#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mm2s_ringbuffer.h"

int main(int argc, char const *argv[])
{
    struct mm2s_ringbuffer *dev;
    void *buffer = malloc(4096);

    dev = mm2s_ringbuffer_init(0);
    if (dev == NULL) {
        printf("MM2S Init Failed\n");
        return -1;
    }
    mm2s_ringbuffer_set_buffer(dev, buffer, 4096);
    mm2s_ringbuffer_start(dev);

    char *teststring = "Hello World";
    mm2s_ringbuffer_put(dev, teststring, strlen(teststring));
    mm2s_ringbuffer_commit(dev);

    return 0;
}

#define PUTS(s) (biriscv_putstring((s)))
#define CACHE_WRITEBACK(addr, count) (biriscv_dcache_writeback_range((addr), (count)))

unsigned char buffers[4][4096] __attribute__((aligned(4096)));

void test_ringbuffer(void)
{
    PUTS("ringbuffer_stuff\n");

    int rc;
    struct mm2s_ringbuffer *dev;
    void *buffer = malloc(4096);

    ringbuffer_t *inst = ((ringbuffer_t *)0xa0000000UL);

    PUTS("mm2s_ringbuffer_init\n");

    dev = mm2s_ringbuffer_init((mm2s_ringbufferx_t *)(&(inst->mm2s_ringbuffer[0])));
    if (dev == NULL) {
        PUTS("mm2s_ringbuffer_init failed\n");
        return;
    }

    PUTS("mm2s_ringbuffer_set_buffer\n");
    rc = mm2s_ringbuffer_set_buffer(dev, buffers[0], 4096);
    if (rc) {
        PUTS("mm2s_ringbuffer_set_buffer failed\n");
        return;
    }

    PUTS("mm2s_ringbuffer_start\n");
    rc = mm2s_ringbuffer_start(dev);
    if (rc) {
        PUTS("mm2s_ringbuffer_start failed\n");
        return;
    }

    char *teststring = "Hello World";

    PUTS("mm2s_ringbuffer_put\n");
    rc = mm2s_ringbuffer_put(dev, teststring, strlen(teststring));
    if (rc < 0) {
        PUTS("mm2s_ringbuffer_put failed\n");
        return;
    }

    CACHE_WRITEBACK((uint32_t)&buffers[0][0], strlen(teststring));

    PUTS("mm2s_ringbuffer_commit\n");
    rc = mm2s_ringbuffer_commit(dev);
    if (rc) {
        PUTS("mm2s_ringbuffer_commit failed\n");
        return;
    }
}
