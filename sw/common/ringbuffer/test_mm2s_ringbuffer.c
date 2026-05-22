#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mm2s_ringbuffer.h"
#include "s2mm_ringbuffer.h"
#include "test_mm2s_ringbuffer.h"


void __attribute__((weak)) ringbuffer_puts(char *s){}
void __attribute__((weak)) ringbuffer_cache_writeback(uint32_t addr, uint32_t count){}

#define PUTS(s)                      (ringbuffer_puts((s)))
#define CACHE_WRITEBACK(addr, count) (ringbuffer_cache_writeback((addr), (count)))

#define BUFFER_SIZE 4096
unsigned char buffers[4][BUFFER_SIZE] __attribute__((aligned(4096)));

void test_ringbuffer_mm2s_helloworld(void *dev_address)
{
    PUTS("ringbuffer_stuff\n");

    int rc;
    struct mm2s_ringbuffer *dev;

    PUTS("mm2s_ringbuffer_init\n");

    dev = mm2s_ringbuffer_init(dev_address);
    if (dev == NULL) {
        PUTS("mm2s_ringbuffer_init failed\n");
        return;
    }

    PUTS("mm2s_ringbuffer_set_buffer\n");
    rc = mm2s_ringbuffer_set_buffer(dev, buffers[0], BUFFER_SIZE);
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



void test_ringbuffer_s2mm_helloworld(void *dev_address)
{
    PUTS("ringbuffer_stuff\n");

    int rc;
    struct s2mm_ringbuffer *dev;

    PUTS("s2mm_ringbuffer_init\n");

    dev = s2mm_ringbuffer_init(dev_address);
    if (dev == NULL) {
        PUTS("s2mm_ringbuffer_init failed\n");
        return;
    }

    PUTS("s2mm_ringbuffer_set_buffer\n");
    rc = s2mm_ringbuffer_set_buffer(dev, buffers[1], BUFFER_SIZE);
    if (rc) {
        PUTS("s2mm_ringbuffer_set_buffer failed\n");
        return;
    }

    PUTS("s2mm_ringbuffer_start\n");
    rc = s2mm_ringbuffer_start(dev);
    if (rc) {
        PUTS("s2mm_ringbuffer_start failed\n");
        return;
    }

    uint8_t readbuf[16];

    PUTS("s2mm_ringbuffer_get\n");
    rc = s2mm_ringbuffer_get(dev, readbuf, 16);
    if (rc < 0) {
        PUTS("s2mm_ringbuffer_get failed\n");
        return;
    }

    PUTS("s2mm_ringbuffer_commit\n");
    rc = s2mm_ringbuffer_commit(dev);
    if (rc) {
        PUTS("s2mm_ringbuffer_commit failed\n");
        return;
    }
}
