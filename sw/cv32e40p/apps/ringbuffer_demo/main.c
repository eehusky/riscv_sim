/* FreeRTOS kernel includes. */
#include <stdio.h>

#include <FreeRTOS.h>
#include <queue.h>
#include <semphr.h>
#include <task.h>
#include "portmacro.h"

#include "sim_extensions.h"
#include "riscv_csr.h"
#include "riscv_io.h"

#include "ringbuffer_addrmap.h"
#include "ringbuffer_explode.h"
#include "mm2s_ringbuffer.h"
#include "s2mm_ringbuffer.h"

// #define DEBUG(s) sim_putstring((s))
#ifndef DEBUG
#define DEBUG(s)
#endif

#define ERROR(s) sim_putstring((s))
#ifndef ERROR
#define ERROR(s)
#endif

/*-----------------------------------------------------------*/
/*-- FreeRTOS Hooks------------------------------------------*/
/*-----------------------------------------------------------*/

void vApplicationMallocFailedHook(void)
{
    /* vApplicationMallocFailedHook() will only be called if
     * configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is a hook
     * function that will get called if a call to pvPortMalloc() fails.
     * pvPortMalloc() is called internally by the kernel whenever a task, queue,
     * timer or semaphore is created.  It is also called by various parts of the
     * demo application.  If heap_1.c or heap_2.c are used, then the size of the
     * heap available to pvPortMalloc() is defined by configTOTAL_HEAP_SIZE in
     * FreeRTOSConfig.h, and the xPortGetFreeHeapSize() API function can be used
     * to query the size of free heap space that remains (although it does not
     * provide information on how the remaining heap might be fragmented). */
    ERROR("vApplicationMallocFailedHook\n");
    sim_exit(0);
}

void vApplicationIdleHook(void)
{
    /* vApplicationIdleHook() will only be called if configUSE_IDLE_HOOK is set
     * to 1 in FreeRTOSConfig.h.  It will be called on each iteration of the idle
     * task.  It is essential that code added to this hook function never attempts
     * to block in any way (for example, call xQueueReceive() with a block time
     * specified, or call vTaskDelay()).  If the application makes use of the
     * vTaskDelete() API function (as this demo application does) then it is also
     * important that vApplicationIdleHook() is permitted to return to its calling
     * function, because it is the responsibility of the idle task to clean up
     * memory allocated by the kernel to any task that has since been deleted. */
    asm volatile("wfi"); // Enter low power mode
}

void vApplicationStackOverflowHook(TaskHandle_t pxTask, char *pcTaskName)
{
    (void)pcTaskName;
    (void)pxTask;

    ERROR("vApplicationStackOverflowHook\n");
    sim_exit(0);
}

void vApplicationTickHook(void) {}

void vAssertCalled(void)
{
    ERROR("vAssertCalled\n");
    sim_exit(0);
}

/*-----------------------------------------------------------*/

// SemaphoreHandle_t sem_mm2s = NULL;
// SemaphoreHandle_t sem_s2mm = NULL;
// struct mm2s_ringbuffer *mm2s_0;//devs[2] = {NULL, NULL};
// struct s2mm_ringbuffer *s2mm_0;//devs[2] = {NULL, NULL};

struct mm2s_channel {
    struct mm2s_ringbuffer *dev;
    uint32_t n_bytes;
    uint32_t dma_buffer_size;
    uint32_t buffer_size;
    uint8_t pattern;
    uint8_t *dma_buffer;
    uint8_t *buffer;
    SemaphoreHandle_t isr_sem;
};
struct s2mm_channel {
    struct s2mm_ringbuffer *dev;
    uint32_t n_bytes;
    uint32_t dma_buffer_size;
    uint32_t buffer_size;
    uint8_t pattern;
    uint8_t *dma_buffer;
    uint8_t *buffer;
    SemaphoreHandle_t isr_sem;
};
static struct mm2s_channel _mm2s_channels[2];
static struct s2mm_channel _s2mm_channels[2];

#define RINGBUFFER_BASE 0xB0000000
#define RINGBUFFER_INT_ENABLE RINGBUFFER_BASE + 0
#define RINGBUFFER_INT_ACTIVE RINGBUFFER_BASE + 4

#define DMA_BUFFER_SIZE 2048
static unsigned char buffers[4][DMA_BUFFER_SIZE] __attribute__((aligned(4096)));
#define PUT_BUFFER_SIZE 512
#define GET_BUFFER_SIZE 512
static unsigned char channel_buffers[4][PUT_BUFFER_SIZE];
static SemaphoreHandle_t sem_isr = NULL;

void freertos_risc_v_application_interrupt_handler(void)
{
    uint32_t enabled;
    uint32_t active;
    uint32_t pending;
    BaseType_t xHigherPriorityTaskWoken;
    BaseType_t xHigherPriorityTaskWoken2 = 0;

    // sim_putstring("riscv_mtvec_mei\n");

    enabled = read32(RINGBUFFER_INT_ENABLE);
    active = read32(RINGBUFFER_INT_ACTIVE);
    pending = active & enabled;
    write32(RINGBUFFER_INT_ACTIVE, pending);

    while (pending) {
        if (pending & RINGBUFFER__INTR_ACTIVE__S2MM_0_bm) {
            xSemaphoreGiveFromISR(_s2mm_channels[0].isr_sem, &xHigherPriorityTaskWoken);
            xHigherPriorityTaskWoken2 |= xHigherPriorityTaskWoken;
        }
        if (pending & RINGBUFFER__INTR_ACTIVE__MM2S_0_bm) {
            xSemaphoreGiveFromISR(_mm2s_channels[0].isr_sem, &xHigherPriorityTaskWoken);
            xHigherPriorityTaskWoken2 |= xHigherPriorityTaskWoken;
        }
        if (pending & RINGBUFFER__INTR_ACTIVE__S2MM_1_bm) {
            xSemaphoreGiveFromISR(_s2mm_channels[1].isr_sem, &xHigherPriorityTaskWoken);
            xHigherPriorityTaskWoken2 |= xHigherPriorityTaskWoken;
        }
        if (pending & RINGBUFFER__INTR_ACTIVE__MM2S_1_bm) {
            xSemaphoreGiveFromISR(_mm2s_channels[1].isr_sem, &xHigherPriorityTaskWoken);
            xHigherPriorityTaskWoken2 |= xHigherPriorityTaskWoken;
        }

        enabled = read32(RINGBUFFER_INT_ENABLE);
        active = read32(RINGBUFFER_INT_ACTIVE);
        pending = active & enabled;
        write32(RINGBUFFER_INT_ACTIVE, pending);
    }
    csr_clr_bits_mip(0x800);
    portYIELD_FROM_ISR(xHigherPriorityTaskWoken2);
}

struct mm2s_ringbuffer *configure_mm2s(void *dev_address, void *buffer, size_t buffer_size)
{
    int rc;
    struct mm2s_ringbuffer *dev;

    DEBUG("configure_mm2s\n");

    dev = mm2s_ringbuffer_init(dev_address);
    if (dev == NULL) {
        ERROR("mm2s_ringbuffer_init failed\n");
        return NULL;
    }

    rc = mm2s_ringbuffer_set_buffer(dev, buffer, buffer_size);
    if (rc) {
        ERROR("mm2s_ringbuffer_set_buffer failed\n");
        return NULL;
    }

    rc = mm2s_ringbuffer_start(dev);
    if (rc) {
        ERROR("mm2s_ringbuffer_start failed\n");
        return NULL;
    }

    return dev;
}

struct s2mm_ringbuffer *configure_s2mm(void *dev_address, void *buffer, size_t buffer_size)
{
    int rc;
    struct s2mm_ringbuffer *dev;

    DEBUG("configure_s2mm\n");

    dev = s2mm_ringbuffer_init(dev_address);
    if (dev == NULL) {
        ERROR("s2mm_ringbuffer_init failed\n");
        return NULL;
    }

    rc = s2mm_ringbuffer_set_buffer(dev, buffer, buffer_size);
    if (rc) {
        ERROR("s2mm_ringbuffer_set_buffer failed\n");
        return NULL;
    }

    rc = s2mm_ringbuffer_start(dev);
    if (rc) {
        ERROR("s2mm_ringbuffer_start failed\n");
        return NULL;
    }

    s2mm_ringbuffer_set_threshold(dev, 500);
    s2mm_ringbuffer_write_intr_enable(dev, RINGBUFFER_S2MMX__INTR_ENABLE__LEVEL_bm);

    return dev;
}

static void mm2s_ringbuffer_task(void *pvParameters)
{
    struct mm2s_channel *channel = (struct mm2s_channel *)pvParameters;
    uint32_t enabled;
    uint32_t active;
    uint32_t pending;

    DEBUG("mm2s_ringbuffer_task started\n");

    // ringbuffer_t *inst = ((ringbuffer_t *)RINGBUFFER_BASE);
    // mm2s_0 = configure_mm2s((void *)&(inst->ringbuffer_mm2s[0]), buffers[0], DMA_BUFFER_SIZE);

    mm2s_ringbuffer_set_threshold(channel->dev, 1);
    mm2s_ringbuffer_write_intr_enable(channel->dev, RINGBUFFER_MM2SX__INTR_ENABLE__LEVEL_bm);

    for (;;) {
        xSemaphoreTake(channel->isr_sem, -1);

        DEBUG("  mm2s_ringbuffer_isr\n");

        enabled = mm2s_ringbuffer_read_intr_enable(channel->dev);
        active = mm2s_ringbuffer_read_intr_active(channel->dev);
        pending = active & enabled;
        while (pending) {
            if (pending & RINGBUFFER_MM2SX__INTR_ACTIVE__ERROR_bm) {
                DEBUG("    mm2s_ringbuffer_isr_error\n");
                mm2s_ringbuffer_clear_intr(channel->dev, RINGBUFFER_MM2SX__INTR_ACTIVE__ERROR_bm);
            }
            if (pending & RINGBUFFER_MM2SX__INTR_ACTIVE__LEVEL_bm) {
                DEBUG("    mm2s_ringbuffer_isr_level\n");
                mm2s_ringbuffer_clear_intr(channel->dev, RINGBUFFER_MM2SX__INTR_ACTIVE__LEVEL_bm);
            }
            enabled = mm2s_ringbuffer_read_intr_enable(channel->dev);
            active = mm2s_ringbuffer_read_intr_active(channel->dev);
            pending = active & enabled;
        }
    }
}

static void s2mm_ringbuffer_task(void *pvParameters)
{
    struct s2mm_channel *channel = (struct s2mm_channel *)pvParameters;
    uint32_t enabled;
    uint32_t active;
    uint32_t pending;
    uint32_t matchword;
    int i;
    DEBUG("s2mm_ringbuffer_task started\n");

    // ringbuffer_t *inst = ((ringbuffer_t *)RINGBUFFER_BASE);
    // s2mm_0 = configure_s2mm((void *)&(inst->ringbuffer_s2mm[0]), buffers[1], DMA_BUFFER_SIZE);

    for (;;) {
        // printf("s2mm_n_bytes: %d\n", channel->n_bytes);
        xSemaphoreTake(channel->isr_sem, -1);

        DEBUG("  s2mm_ringbuffer_isr\n");

        enabled = s2mm_ringbuffer_read_intr_enable(channel->dev);
        active = s2mm_ringbuffer_read_intr_active(channel->dev);
        pending = active & enabled;

        while (pending) {
            if (pending & RINGBUFFER_S2MMX__INTR_ACTIVE__OVERRUN_bm) {
                DEBUG("    s2mm_ringbuffer_isr_overrun\n");
                s2mm_ringbuffer_clear_intr(channel->dev, RINGBUFFER_S2MMX__INTR_ACTIVE__OVERRUN_bm);
            }
            if (pending & RINGBUFFER_S2MMX__INTR_ACTIVE__ERROR_bm) {
                DEBUG("    s2mm_ringbuffer_isr_error\n");
                s2mm_ringbuffer_clear_intr(channel->dev, RINGBUFFER_S2MMX__INTR_ACTIVE__ERROR_bm);
            }
            if (pending & RINGBUFFER_S2MMX__INTR_ACTIVE__LEVEL_bm) {
                DEBUG("    s2mm_ringbuffer_isr_level\n");
                channel->n_bytes += s2mm_ringbuffer_level(channel->dev);
                // s2mm_ringbuffer_flush(s2mm_0);
                int rv;
                do {
                    rv = s2mm_ringbuffer_get(channel->dev, channel->buffer, GET_BUFFER_SIZE);
                    s2mm_ringbuffer_commit(channel->dev);
                    for (i = 0; i < rv; i += 4) {
                        matchword = ((((channel->pattern + 0))) << 0) | ((((channel->pattern + 1))) << 8) |
                                    ((((channel->pattern + 2))) << 16) | ((((channel->pattern + 3))) << 24);
                        if (*((uint32_t *)(channel->buffer + i)) != matchword) {
                            printf("buffer mismatch %02X != %02X\n", matchword, *((uint32_t *)(channel->buffer + i)));
                            sim_exit(-1);
                        }
                        // if (getbuffer[i] != (s2mm_pat & 0xFF)) {
                        //     printf("buffer mismatch %02X != %02X\n", (s2mm_pat & 0xFF), getbuffer[i]);
                        //     sim_exit(0);
                        // }
                        channel->pattern += 4;
                    }
                } while (rv > 0);
                s2mm_ringbuffer_clear_intr(channel->dev, RINGBUFFER_S2MMX__INTR_ACTIVE__LEVEL_bm);
            }
            enabled = s2mm_ringbuffer_read_intr_enable(channel->dev);
            active = s2mm_ringbuffer_read_intr_active(channel->dev);
            pending = active & enabled;
        }
    }
}

static void send_task(void *pvParameters)
{
    DEBUG("send_task started\n");
    struct mm2s_channel *channel = (struct mm2s_channel *)pvParameters;
    int done = 0;
    int n_bytes = 248 * 2;
    int i = 0;
    int rv;
    uint32_t word;
    while (1) {
        vTaskDelay(1);

        if (channel->n_bytes < 2048 * 4) {
            for (i = 0; i < n_bytes; i += 4) {
                *((uint32_t *)(channel->buffer + i)) =
                    ((((channel->pattern + 0))) << 0) | ((((channel->pattern + 1))) << 8) |
                    ((((channel->pattern + 2))) << 16) | ((((channel->pattern + 3))) << 24);
                channel->pattern += 4;
            }

            rv = mm2s_ringbuffer_put(channel->dev, channel->buffer, n_bytes);
            if (rv > 0) {
                channel->n_bytes += rv;
            }
            mm2s_ringbuffer_commit(channel->dev);
        } else {
            done = 1;
        }
        if (done) {
            sim_exit(0);
        }
    }
}

static void stats_task(void *pvParameters)
{
    DEBUG("stats_task started\n");

    void **args = (void **)pvParameters;
    struct mm2s_channel *channel0 = (struct mm2s_channel *)args[0];
    struct mm2s_channel *channel1 = (struct mm2s_channel *)args[1];
    struct s2mm_channel *channel2 = (struct s2mm_channel *)args[2];
    struct s2mm_channel *channel3 = (struct s2mm_channel *)args[3];

    while (1) {
        vTaskDelay(1);
        printf("mm2s_0_bytes=%d, mm2s_1_bytes=%d, s2mm_0_bytes=%d, s2mm_1_bytes=%d\n", channel0->n_bytes,
               channel1->n_bytes, channel2->n_bytes, channel3->n_bytes);
        // printf(
        //     "mm2s_0_level=%d, mm2s_1_level=%d, s2mm_0_level=%d, s2mm_1_level=%d\n",
        //     mm2s_ringbuffer_level(channel0->dev),
        //     mm2s_ringbuffer_level(channel1->dev),
        //     s2mm_ringbuffer_level(channel2->dev),
        //     s2mm_ringbuffer_level(channel3->dev)
        //);
    }
}

int main(void)
{
    printf("%d: %s\n", mtime_get(), "Hello FreeRTOS!");

    ringbuffer_t *inst = ((ringbuffer_t *)RINGBUFFER_BASE);

    _mm2s_channels[0].dev = configure_mm2s((void *)&(inst->ringbuffer_mm2s[0]), buffers[0], DMA_BUFFER_SIZE);
    _mm2s_channels[0].isr_sem = xSemaphoreCreateBinary();
    _mm2s_channels[0].n_bytes = 0;
    _mm2s_channels[0].dma_buffer_size = DMA_BUFFER_SIZE;
    _mm2s_channels[0].buffer_size = PUT_BUFFER_SIZE;
    _mm2s_channels[0].pattern = 0;
    _mm2s_channels[0].dma_buffer = buffers[0];
    _mm2s_channels[0].buffer = channel_buffers[0];
    _mm2s_channels[1].dev = configure_mm2s((void *)&(inst->ringbuffer_mm2s[1]), buffers[1], DMA_BUFFER_SIZE);
    _mm2s_channels[1].isr_sem = xSemaphoreCreateBinary();
    _mm2s_channels[1].n_bytes = 0;
    _mm2s_channels[1].dma_buffer_size = DMA_BUFFER_SIZE;
    _mm2s_channels[1].buffer_size = PUT_BUFFER_SIZE;
    _mm2s_channels[1].pattern = 0;
    _mm2s_channels[1].dma_buffer = buffers[1];
    _mm2s_channels[1].buffer = channel_buffers[1];

    _s2mm_channels[0].dev = configure_s2mm((void *)&(inst->ringbuffer_s2mm[0]), buffers[2], DMA_BUFFER_SIZE);
    _s2mm_channels[0].isr_sem = xSemaphoreCreateBinary();
    _s2mm_channels[0].n_bytes = 0;
    _s2mm_channels[0].dma_buffer_size = DMA_BUFFER_SIZE;
    _s2mm_channels[0].buffer_size = PUT_BUFFER_SIZE;
    _s2mm_channels[0].pattern = 0;
    _s2mm_channels[0].dma_buffer = buffers[2];
    _s2mm_channels[0].buffer = channel_buffers[2];
    _s2mm_channels[1].dev = configure_s2mm((void *)&(inst->ringbuffer_s2mm[1]), buffers[3], DMA_BUFFER_SIZE);
    _s2mm_channels[1].isr_sem = xSemaphoreCreateBinary();
    _s2mm_channels[1].n_bytes = 0;
    _s2mm_channels[1].dma_buffer_size = DMA_BUFFER_SIZE;
    _s2mm_channels[1].buffer_size = PUT_BUFFER_SIZE;
    _s2mm_channels[1].pattern = 0;
    _s2mm_channels[1].dma_buffer = buffers[3];
    _s2mm_channels[1].buffer = channel_buffers[3];

    sem_isr = xSemaphoreCreateBinary();

    void *args[4] = {
        &_mm2s_channels[0],
        &_mm2s_channels[1],
        &_s2mm_channels[0],
        &_s2mm_channels[1],
    };

    xTaskCreate(s2mm_ringbuffer_task, "s2mm_0", configMINIMAL_STACK_SIZE, &_s2mm_channels[0], tskIDLE_PRIORITY + 3,
                NULL);
    xTaskCreate(s2mm_ringbuffer_task, "s2mm_1", configMINIMAL_STACK_SIZE, &_s2mm_channels[1], tskIDLE_PRIORITY + 3,
                NULL);
    xTaskCreate(send_task, "mm2s_0", configMINIMAL_STACK_SIZE, &_mm2s_channels[0], tskIDLE_PRIORITY + 2, NULL);
    xTaskCreate(send_task, "mm2s_1", configMINIMAL_STACK_SIZE, &_mm2s_channels[1], tskIDLE_PRIORITY + 2, NULL);
    xTaskCreate(stats_task, "stats", configMINIMAL_STACK_SIZE, args, tskIDLE_PRIORITY + 1, NULL);
    //  xTaskCreate(mm2s_ringbuffer_task, "mm2s", configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 2, NULL);

    write32(RINGBUFFER_INT_ENABLE, RINGBUFFER__INTR_ENABLE__S2MM_0_bm | RINGBUFFER__INTR_ENABLE__S2MM_1_bm);

    sim_putstring("vTaskStartScheduler\n");
    vTaskStartScheduler();

    return 0;
}
