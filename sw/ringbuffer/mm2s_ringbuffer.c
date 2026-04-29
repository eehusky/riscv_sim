#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "biriscv_extensions.h"
#include "mm2s_ringbuffer.h"
#include "ringbuffer_explode.h"

struct mm2s_ringbuffer {
    ringbuffer_mm2sx_t *regs;
    uint8_t *buffer;
    size_t buffer_size;

    uint32_t capacity;
    uint32_t width;
    uint32_t ptr_width;
    uint32_t headptr;
    uint32_t tailptr;
};

static uint32_t _level(uint32_t headptr, uint32_t tailptr, uint32_t buffer_size)
{
    if (headptr == tailptr) {
        return 0;
    }

    if (tailptr > headptr) {
        return headptr + (buffer_size - tailptr);
    }

    return headptr - tailptr;
}
static inline void _advance_head(struct mm2s_ringbuffer *dev)
{
    uint32_t nxt = dev->headptr + dev->width;
    dev->headptr = nxt <= dev->capacity ? nxt : 0;
}
static uint32_t _roomfor(struct mm2s_ringbuffer *dev, uint32_t cnt)
{
    uint32_t lvl;
    uint32_t fre;

    lvl = _level(dev->headptr, dev->tailptr, dev->buffer_size);
    fre = dev->buffer_size - lvl;
    if (fre >= cnt) {
        return cnt;
    }

    lvl = mm2s_ringbuffer_level(dev);
    fre = dev->buffer_size - lvl;
    if (fre >= cnt) {
        return cnt;
    }

    return fre;
}

struct mm2s_ringbuffer *mm2s_ringbuffer_init(void *dev_address)
{
    struct mm2s_ringbuffer *dev;

    if (dev_address == NULL) {
        return NULL;
    }

    dev = malloc(sizeof((*dev)));
    if (dev == NULL) {
        return NULL;
    }

    memset(dev, 0, sizeof(*dev));

    dev->regs = dev_address;

    // check id and versions registers
    if (dev->regs->ID != RINGBUFFER_MM2SX__ID__ID_reset) {
        free(dev);
        return NULL;
    }

    if (dev->regs->VERSION != RINGBUFFER_MM2SX__VERSION__VERSION_reset) {
        free(dev);
        return NULL;
    }

    // make sure we can read and write
    dev->regs->SCRATCH = 0xDEADBEEF;
    if (dev->regs->SCRATCH != 0xDEADBEEF) {
        free(dev);
        return NULL;
    }
    dev->regs->SCRATCH = 0;

    // load up initial values
    dev->ptr_width =
        (dev->regs->WIDTH & RINGBUFFER_MM2SX__WIDTH__PTR_WIDTH_bm) >> RINGBUFFER_MM2SX__WIDTH__PTR_WIDTH_bp;
    dev->width = (dev->regs->WIDTH & RINGBUFFER_MM2SX__WIDTH__M_AXIS_TDATA_WIDTH_bm) >>
                 RINGBUFFER_MM2SX__WIDTH__M_AXIS_TDATA_WIDTH_bp;
    dev->headptr = dev->regs->HEADPTR;
    dev->tailptr = dev->regs->TAILPTR;

    return dev;
}
int mm2s_ringbuffer_set_buffer(struct mm2s_ringbuffer *dev, void *buffer, size_t buffer_size)
{
    if (dev == NULL) {
        return -1;
    }

    if (buffer == NULL) {
        return -1;
    }

    if (buffer_size <= dev->width) {
        return -1;
    }

    if ((buffer_size - dev->width) > (1 << (dev->ptr_width * 8)) - 1) {
        return -1;
    }

    dev->regs->BASEADDRESS_LO = (((uint32_t)buffer) & 0xFFFFFFFF);
    // dev->regs->BASEADDRESS_HI = ((((uint32_t)buffer)>>32) & 0xFFFFFFFF);
    dev->regs->SIZE = buffer_size - dev->width;

    dev->buffer = buffer;
    dev->buffer_size = buffer_size;
    dev->capacity = buffer_size - dev->width;

    return 0;
}
bool mm2s_ringbuffer_is_active(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }

    return (dev->regs->CSR & RINGBUFFER_MM2SX__CSR__ACTIVE_bm) != 0;
}
int mm2s_ringbuffer_start(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->CSR = RINGBUFFER_MM2SX__CSR__START_bm;

    return 0;
}
int mm2s_ringbuffer_stop(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->CSR = RINGBUFFER_MM2SX__CSR__STOP_bm;

    return 0;
}
int mm2s_ringbuffer_pause(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->CSR = RINGBUFFER_MM2SX__CSR__PAUSE_bm;

    return 0;
}
int mm2s_ringbuffer_set_threshold(struct mm2s_ringbuffer *dev, int value)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->LEVEL_THRESHOLD = value;

    return 0;
}
int mm2s_ringbuffer_get_threshold(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    return dev->regs->LEVEL_THRESHOLD;
}
int mm2s_ringbuffer_width(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    return dev->width;
}
int mm2s_ringbuffer_put2(struct mm2s_ringbuffer *dev, void *buffer, size_t buffer_size)
{
    if (dev == NULL) {
        return -1;
    }

    if (dev->buffer == NULL) {
        return -1;
    }

    if (buffer == NULL) {
        return -1;
    }

    if (buffer_size < dev->width) {
        return -1;
    }

    int i;
    int count = _roomfor(dev, buffer_size);
    for (i = 0; i < count; i++) {
        _advance_head(dev);
        dev->buffer[dev->headptr] = ((uint8_t *)buffer)[i];
    }
    biriscv_dcache_writeback_range((uint32_t)dev->buffer, dev->buffer_size);
    return count;
}
int mm2s_ringbuffer_commit(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->HEADPTR = dev->headptr;

    return 0;
}
int mm2s_ringbuffer_level(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    dev->tailptr = dev->regs->TAILPTR;
    return _level(dev->headptr, dev->tailptr, dev->buffer_size);
}
int mm2s_ringbuffer_capacity(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    return dev->capacity;
}
bool mm2s_ringbuffer_is_empty(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }
    return mm2s_ringbuffer_level(dev) == 0;
}
bool mm2s_ringbuffer_is_full(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }
    return mm2s_ringbuffer_capacity(dev) == mm2s_ringbuffer_level(dev);
}
int mm2s_ringbuffer_free(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    return mm2s_ringbuffer_capacity(dev) - mm2s_ringbuffer_level(dev);
}

int mm2s_ringbuffer_put(struct mm2s_ringbuffer *dev, void *buffer, size_t buffer_size)
{
    if (dev == NULL) {
        return -1;
    }

    if (dev->buffer == NULL) {
        return -1;
    }

    if (buffer == NULL) {
        return -1;
    }

    if (buffer_size < dev->width) {
        return -1;
    }

    int count = _roomfor(dev, buffer_size);
    if (count == 0) {
        return 0;
    }

    uint32_t c = 0;

    // printf("head=%d, tail=%d\n", dev->headptr, dev->tailptr);
    _advance_head(dev);

    if (count >= (dev->buffer_size - dev->headptr)) {
        // printf("head=%d, tail=%d, count=%d, h2e=%d\n", dev->headptr, dev->tailptr, count, dev->buffer_size -
        // dev->headptr);
        memcpy(dev->buffer + dev->headptr, buffer + c, dev->buffer_size - dev->headptr);
        biriscv_dcache_writeback_range((uint32_t)dev->buffer + dev->headptr, dev->buffer_size - dev->headptr);
        c += (dev->buffer_size - dev->headptr);
        dev->headptr = 0;
    }
    memcpy(dev->buffer + dev->headptr, buffer + c, count - c);
    biriscv_dcache_writeback_range((uint32_t)dev->buffer + dev->headptr, count - c);
    dev->headptr += count - c - 1;
    // biriscv_dcache_writeback_range((uint32_t)dev->buffer, dev->buffer_size);

    return count;
}

void mm2s_ringbuffer_write_intr_enable(struct mm2s_ringbuffer *dev, uint32_t mask)
{
    if (dev == NULL) {
        return;
    }
    dev->regs->INTR_ENABLE = mask;
}
uint32_t mm2s_ringbuffer_read_intr_enable(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }

    return (dev->regs->INTR_ENABLE);
}
uint32_t mm2s_ringbuffer_read_intr_active(struct mm2s_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }

    return (dev->regs->INTR_ACTIVE);
}
void mm2s_ringbuffer_clear_intr(struct mm2s_ringbuffer *dev, uint32_t mask)
{
    if (dev == NULL) {
        return;
    }
    dev->regs->INTR_ACTIVE = mask;
}
