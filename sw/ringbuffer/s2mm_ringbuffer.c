#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "ringbuffer_explode.h"
#include "s2mm_ringbuffer.h"

struct s2mm_ringbuffer {
    ringbuffer_s2mmx_t *regs;
    uint8_t *buffer;
    size_t buffer_size;

    uint32_t capacity;
    uint32_t width;
    uint32_t ptr_width;
    uint32_t headptr;
    uint32_t tailptr;
};

static inline uint32_t _level(uint32_t headptr, uint32_t tailptr, uint32_t buffer_size)
{
    if (headptr == tailptr) {
        return 0;
    }

    if (tailptr > headptr) {
        return headptr + (buffer_size - tailptr);
    }

    return headptr - tailptr;
}

int s2mm_ringbuffer_set_buffer(struct s2mm_ringbuffer *dev, void *buffer, size_t buffer_size)
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
bool s2mm_ringbuffer_is_active(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }

    return (dev->regs->CSR & RINGBUFFER_S2MMX__CSR__ACTIVE_bm) != 0;
}
int s2mm_ringbuffer_start(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->CSR = RINGBUFFER_S2MMX__CSR__START_bm;

    return 0;
}
int s2mm_ringbuffer_stop(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->CSR = RINGBUFFER_S2MMX__CSR__STOP_bm;

    return 0;
}
int s2mm_ringbuffer_pause(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->CSR = RINGBUFFER_S2MMX__CSR__PAUSE_bm;

    return 0;
}
int s2mm_ringbuffer_set_threshold(struct s2mm_ringbuffer *dev, int value)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->LEVEL_THRESHOLD = value;

    return 0;
}
int s2mm_ringbuffer_get_threshold(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    return dev->regs->LEVEL_THRESHOLD;
}
int s2mm_ringbuffer_width(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    return dev->width;
}

int s2mm_ringbuffer_capacity(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    return dev->capacity;
}
bool s2mm_ringbuffer_is_empty(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }
    return s2mm_ringbuffer_level(dev) == 0;
}
bool s2mm_ringbuffer_is_full(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }
    return s2mm_ringbuffer_capacity(dev) == s2mm_ringbuffer_level(dev);
}
int s2mm_ringbuffer_free(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    return s2mm_ringbuffer_capacity(dev) - s2mm_ringbuffer_level(dev);
}

inline void s2mm_ringbuffer_write_intr_enable(struct s2mm_ringbuffer *dev, uint32_t mask)
{
    if (dev == NULL) {
        return;
    }
    dev->regs->INTR_ENABLE = mask;
}
inline uint32_t s2mm_ringbuffer_read_intr_enable(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }

    return (dev->regs->INTR_ENABLE);
}
inline uint32_t s2mm_ringbuffer_read_intr_active(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return false;
    }

    return (dev->regs->INTR_ACTIVE);
}
inline void s2mm_ringbuffer_clear_intr(struct s2mm_ringbuffer *dev, uint32_t mask)
{
    if (dev == NULL) {
        return;
    }
    dev->regs->INTR_ACTIVE = mask;
}

static inline void _advance_tail(struct s2mm_ringbuffer *dev)
{
    uint32_t nxt = dev->tailptr + dev->width;
    dev->tailptr = nxt <= dev->capacity ? nxt : 0;
}
static inline uint32_t _tail_to_end(struct s2mm_ringbuffer *dev) { return dev->buffer_size - dev->tailptr; }

struct s2mm_ringbuffer *s2mm_ringbuffer_init(void *dev_address)
{
    struct s2mm_ringbuffer *dev;

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
    if (dev->regs->ID != RINGBUFFER_S2MMX__ID__ID_reset) {
        free(dev);
        return NULL;
    }

    if (dev->regs->VERSION != RINGBUFFER_S2MMX__VERSION__VERSION_reset) {
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
        (dev->regs->WIDTH & RINGBUFFER_S2MMX__WIDTH__PTR_WIDTH_bm) >> RINGBUFFER_S2MMX__WIDTH__PTR_WIDTH_bp;
    dev->width = (dev->regs->WIDTH & RINGBUFFER_S2MMX__WIDTH__S_AXIS_TDATA_WIDTH_bm) >>
                 RINGBUFFER_S2MMX__WIDTH__S_AXIS_TDATA_WIDTH_bp;
    dev->headptr = dev->regs->HEADPTR;
    dev->tailptr = dev->regs->TAILPTR;

    return dev;
}
int s2mm_ringbuffer_get_dumb(struct s2mm_ringbuffer *dev, void *buffer, size_t buffer_size)
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

    if ((buffer_size % dev->width) != 0) {
        return -1;
    }

    uint32_t level = s2mm_ringbuffer_level(dev);
    uint32_t count = level < buffer_size ? level : buffer_size;

    int i;
    for (i = 0; i < count; i++) {
        _advance_tail(dev);
        ((uint8_t *)buffer)[i] = dev->buffer[dev->tailptr];
    }

    return i;
}
int s2mm_ringbuffer_commit(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }

    dev->regs->TAILPTR = dev->tailptr;

    return 0;
}
int s2mm_ringbuffer_level(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    dev->headptr = dev->regs->HEADPTR;
    return _level(dev->headptr, dev->tailptr, dev->buffer_size);
}
int s2mm_ringbuffer_flush(struct s2mm_ringbuffer *dev)
{
    if (dev == NULL) {
        return -1;
    }
    dev->regs->TAILPTR = dev->regs->HEADPTR;
    dev->headptr = dev->regs->HEADPTR;
    dev->tailptr = dev->regs->TAILPTR;
    return 0;
}



int s2mm_ringbuffer_get(struct s2mm_ringbuffer *dev, void *buffer, size_t buffer_size)
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

    if ((buffer_size % dev->width) != 0) {
        return -1;
    }

    uint32_t level = s2mm_ringbuffer_level(dev);
    uint32_t count = level < buffer_size ? level : buffer_size;

    int i;
    for (i = 0; i < count; i++) {
        _advance_tail(dev);
        ((uint8_t *)buffer)[i] = dev->buffer[dev->tailptr];
    }

    return i;
}
