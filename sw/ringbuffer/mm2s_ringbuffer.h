#ifndef __MM2S_RINGBUFFER_H__
#define __MM2S_RINGBUFFER_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

struct mm2s_ringbuffer;

struct mm2s_ringbuffer *mm2s_ringbuffer_init(void *dev_address);
int mm2s_ringbuffer_set_buffer(struct mm2s_ringbuffer *dev, void *buffer, size_t buffer_size);
bool mm2s_ringbuffer_is_active(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_start(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_stop(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_pause(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_set_threshold(struct mm2s_ringbuffer *dev, int value);
int mm2s_ringbuffer_get_threshold(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_width(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_put(struct mm2s_ringbuffer *dev, void *buffer, size_t buffer_size);
int mm2s_ringbuffer_commit(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_level(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_capacity(struct mm2s_ringbuffer *dev);
bool mm2s_ringbuffer_is_empty(struct mm2s_ringbuffer *dev);
bool mm2s_ringbuffer_is_full(struct mm2s_ringbuffer *dev);
int mm2s_ringbuffer_free(struct mm2s_ringbuffer *dev);

void mm2s_ringbuffer_write_intr_enable(struct mm2s_ringbuffer *dev, uint32_t mask);
uint32_t mm2s_ringbuffer_read_intr_enable(struct mm2s_ringbuffer *dev);
uint32_t mm2s_ringbuffer_read_intr_active(struct mm2s_ringbuffer *dev);
void mm2s_ringbuffer_clear_intr(struct mm2s_ringbuffer *dev, uint32_t mask);

#endif /* __MM2S_RINGBUFFER_H__ */
