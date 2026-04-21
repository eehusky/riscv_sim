#ifndef MM2S_RINGBUFFER_H
#define MM2S_RINGBUFFER_H

#include <stddef.h>
#include <stdbool.h>

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



#endif /* MM2S_RINGBUFFER_H */
