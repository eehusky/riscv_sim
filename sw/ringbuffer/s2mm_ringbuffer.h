#ifndef __S2MM_RINGBUFFER_H__
#define __S2MM_RINGBUFFER_H__

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

struct s2mm_ringbuffer;

struct s2mm_ringbuffer *s2mm_ringbuffer_init(void *dev_address);
int s2mm_ringbuffer_set_buffer(struct s2mm_ringbuffer *dev, void *buffer, size_t buffer_size);
bool s2mm_ringbuffer_is_active(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_start(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_stop(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_pause(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_set_threshold(struct s2mm_ringbuffer *dev, int value);
int s2mm_ringbuffer_get_threshold(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_width(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_get(struct s2mm_ringbuffer *dev, void *buffer, size_t buffer_size);
int s2mm_ringbuffer_commit(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_level(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_capacity(struct s2mm_ringbuffer *dev);
bool s2mm_ringbuffer_is_empty(struct s2mm_ringbuffer *dev);
bool s2mm_ringbuffer_is_full(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_free(struct s2mm_ringbuffer *dev);
int s2mm_ringbuffer_flush(struct s2mm_ringbuffer *dev);

void s2mm_ringbuffer_threshold_interrupt_enable(struct s2mm_ringbuffer *dev);
void s2mm_ringbuffer_threshold_interrupt_disable(struct s2mm_ringbuffer *dev);
void s2mm_ringbuffer_overrun_interrupt_enable(struct s2mm_ringbuffer *dev);
void s2mm_ringbuffer_overrun_interrupt_disable(struct s2mm_ringbuffer *dev);
void s2mm_ringbuffer_error_interrupt_enable(struct s2mm_ringbuffer *dev);
void s2mm_ringbuffer_error_interrupt_disable(struct s2mm_ringbuffer *dev);


void s2mm_ringbuffer_write_intr_enable(struct s2mm_ringbuffer *dev, uint32_t mask);
uint32_t s2mm_ringbuffer_read_intr_enable(struct s2mm_ringbuffer *dev);
uint32_t s2mm_ringbuffer_read_intr_active(struct s2mm_ringbuffer *dev);
void s2mm_ringbuffer_clear_intr(struct s2mm_ringbuffer *dev, uint32_t mask);


#endif /* __S2MM_RINGBUFFER_H__ */
