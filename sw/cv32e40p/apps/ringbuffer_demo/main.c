/*
 * FreeRTOS V202212.00
 * Copyright (C) 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * https://www.FreeRTOS.org
 * https://github.com/FreeRTOS
 *
 */

/* FreeRTOS kernel includes. */
#include <stdio.h>

#include <FreeRTOS.h>
#include <queue.h>
#include <semphr.h>
#include <task.h>

#include "sim_extensions.h"

#include "portmacro.h"
#include "ringbuffer_addrmap.h"

#include "mm2s_ringbuffer.h"
#include "ringbuffer_explode.h"
#include "riscv_csr.h"
#include "riscv_io.h"
#include "s2mm_ringbuffer.h"
#include "test_mm2s_ringbuffer.h"

// #define DEBUG(s) sim_putstring((s))
#define DEBUG(s)
#define ERROR(s) sim_putstring((s))
// #define ERROR(s)

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

SemaphoreHandle_t sem_mm2s = NULL;
SemaphoreHandle_t sem_s2mm = NULL;
SemaphoreHandle_t sem_isr = NULL;
struct mm2s_ringbuffer *mm2s_0 = NULL;
struct s2mm_ringbuffer *s2mm_0 = NULL;
uint32_t n_s2mm_bytes = 0;
uint32_t n_mm2s_bytes = 0;
uint8_t s2mm_pat = 0;
uint8_t mm2s_pat = 0;

#define RINGBUFFER_BASE 0xB0000000
#define RINGBUFFER_INT_ENABLE RINGBUFFER_BASE + 0
#define RINGBUFFER_INT_ACTIVE RINGBUFFER_BASE + 4

#define DMA_BUFFER_SIZE 1024
unsigned char buffers[4][DMA_BUFFER_SIZE] __attribute__((aligned(4096)));
#define PUT_BUFFER_SIZE 256
char putbuffer[PUT_BUFFER_SIZE];
#define GET_BUFFER_SIZE 256
char getbuffer[GET_BUFFER_SIZE];

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

    while (pending) {
        if (pending & RINGBUFFER__INTR_ACTIVE__S2MM_0_bm) {
            xSemaphoreGiveFromISR(sem_s2mm, &xHigherPriorityTaskWoken);
            xHigherPriorityTaskWoken2 |= xHigherPriorityTaskWoken;
        }
        if (pending & RINGBUFFER__INTR_ACTIVE__MM2S_0_bm) {
            xSemaphoreGiveFromISR(sem_mm2s, &xHigherPriorityTaskWoken);
            xHigherPriorityTaskWoken2 |= xHigherPriorityTaskWoken;
        }
        write32(RINGBUFFER_INT_ACTIVE, pending);
        enabled = read32(RINGBUFFER_INT_ENABLE);
        active = read32(RINGBUFFER_INT_ACTIVE);
        pending = active & enabled;
    }
    csr_clr_bits_mip(0x800);
    portYIELD_FROM_ISR(xHigherPriorityTaskWoken2);
}

struct mm2s_ringbuffer *configure_mm2s(void *dev_address, void *buffer, size_t buffer_size, int32_t instance)
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

struct s2mm_ringbuffer *configure_s2mm(void *dev_address, void *buffer, size_t buffer_size, int32_t instance)
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

    s2mm_ringbuffer_set_threshold(dev, 99);
    s2mm_ringbuffer_write_intr_enable(dev, RINGBUFFER_S2MMX__INTR_ENABLE__LEVEL_bm);

    return dev;
}

static void mm2s_ringbuffer_task(void *pvParameters)
{
    uint32_t enabled;
    uint32_t active;
    uint32_t pending;

    DEBUG("mm2s_ringbuffer_task started\n");

    ringbuffer_t *inst = ((ringbuffer_t *)RINGBUFFER_BASE);
    mm2s_0 = configure_mm2s((void *)&(inst->ringbuffer_mm2s[0]), buffers[0], DMA_BUFFER_SIZE, 0);

    mm2s_ringbuffer_set_threshold(mm2s_0, 1);
    mm2s_ringbuffer_write_intr_enable(mm2s_0, RINGBUFFER_MM2SX__INTR_ENABLE__LEVEL_bm);

    for (;;) {
        xSemaphoreTake(sem_mm2s, -1);

        DEBUG("  mm2s_ringbuffer_isr\n");

        enabled = mm2s_ringbuffer_read_intr_enable(mm2s_0);
        active = mm2s_ringbuffer_read_intr_active(mm2s_0);
        pending = active & enabled;
        while (pending) {

            if (pending & RINGBUFFER_MM2SX__INTR_ACTIVE__ERROR_bm) {
                DEBUG("    mm2s_ringbuffer_isr_error\n");
                mm2s_ringbuffer_clear_intr(mm2s_0, RINGBUFFER_MM2SX__INTR_ACTIVE__ERROR_bm);
            }
            if (pending & RINGBUFFER_MM2SX__INTR_ACTIVE__LEVEL_bm) {
                DEBUG("    mm2s_ringbuffer_isr_level\n");

                int rv;
                rv = mm2s_ringbuffer_put(mm2s_0, putbuffer, PUT_BUFFER_SIZE);
                if (rv > 0) {
                    n_mm2s_bytes += rv;
                }
                //  biriscv_dcache_flush();
                mm2s_ringbuffer_commit(mm2s_0);

                // if (mm2s_n_bytes > 4096) {
                //     mm2s_ringbuffer_write_intr_enable(dev, 0);
                // }

                mm2s_ringbuffer_clear_intr(mm2s_0, RINGBUFFER_MM2SX__INTR_ACTIVE__LEVEL_bm);
            }
            enabled = mm2s_ringbuffer_read_intr_enable(mm2s_0);
            active = mm2s_ringbuffer_read_intr_active(mm2s_0);
            pending = active & enabled;
        }
    }
}

static void s2mm_ringbuffer_task(void *pvParameters)
{
    uint32_t enabled;
    uint32_t active;
    uint32_t pending;
    uint32_t matchword;
    int i;
    DEBUG("s2mm_ringbuffer_task started\n");

    ringbuffer_t *inst = ((ringbuffer_t *)RINGBUFFER_BASE);
    s2mm_0 = configure_s2mm((void *)&(inst->ringbuffer_s2mm[0]), buffers[1], DMA_BUFFER_SIZE, 0);

    for (;;) {
        xSemaphoreTake(sem_s2mm, -1);

        DEBUG("  s2mm_ringbuffer_isr\n");

        enabled = s2mm_ringbuffer_read_intr_enable(s2mm_0);
        active = s2mm_ringbuffer_read_intr_active(s2mm_0);
        pending = active & enabled;

        while (pending) {
            if (pending & RINGBUFFER_S2MMX__INTR_ACTIVE__OVERRUN_bm) {
                DEBUG("    s2mm_ringbuffer_isr_overrun\n");
                s2mm_ringbuffer_clear_intr(s2mm_0, RINGBUFFER_S2MMX__INTR_ACTIVE__OVERRUN_bm);
            }
            if (pending & RINGBUFFER_S2MMX__INTR_ACTIVE__ERROR_bm) {
                DEBUG("    s2mm_ringbuffer_isr_error\n");
                s2mm_ringbuffer_clear_intr(s2mm_0, RINGBUFFER_S2MMX__INTR_ACTIVE__ERROR_bm);
            }
            if (pending & RINGBUFFER_S2MMX__INTR_ACTIVE__LEVEL_bm) {
                DEBUG("    s2mm_ringbuffer_isr_level\n");
                n_s2mm_bytes += s2mm_ringbuffer_level(s2mm_0);
                // s2mm_ringbuffer_flush(s2mm_0);
                int rv;
                do {
                    rv = s2mm_ringbuffer_get(s2mm_0, getbuffer, GET_BUFFER_SIZE);
                    s2mm_ringbuffer_commit(s2mm_0);
                    for (i = 0; i < rv; i += 4) {
                        matchword = ((((s2mm_pat + 0))) << 0) | ((((s2mm_pat + 1))) << 8) | ((((s2mm_pat + 2))) << 16) |
                                    ((((s2mm_pat + 3))) << 24);
                        if (*((uint32_t *)(getbuffer + i)) != matchword) {
                            printf("buffer mismatch %02X != %02X\n", matchword, *((uint32_t *)(getbuffer + i)));
                            sim_exit(-1);
                        }
                        // if (getbuffer[i] != (s2mm_pat & 0xFF)) {
                        //     printf("buffer mismatch %02X != %02X\n", (s2mm_pat & 0xFF), getbuffer[i]);
                        //     sim_exit(0);
                        // }
                        s2mm_pat += 4;
                    }
                } while (rv > 0);
                s2mm_ringbuffer_clear_intr(s2mm_0, RINGBUFFER_S2MMX__INTR_ACTIVE__LEVEL_bm);
            }
            enabled = s2mm_ringbuffer_read_intr_enable(s2mm_0);
            active = s2mm_ringbuffer_read_intr_active(s2mm_0);
            pending = active & enabled;
        }
    }
}

static void stats_task(void *pvParameters)
{
    DEBUG("stats_task started\n");
    int done = 0;
    int n_bytes = 248;
    int i = 0;
    int rv;
    uint32_t word;
    while (1) {
        vTaskDelay(1);
        printf("n_s2mm_bytes=%d, n_mm2s_bytes=%d\n", n_s2mm_bytes, n_mm2s_bytes);

        if (n_mm2s_bytes < 2048) {
            for (i = 0; i < n_bytes; i += 4) {
                *((uint32_t *)(putbuffer + i)) = ((((mm2s_pat + 0))) << 0) | ((((mm2s_pat + 1))) << 8) |
                                                 ((((mm2s_pat + 2))) << 16) | ((((mm2s_pat + 3))) << 24);
                mm2s_pat += 4;
            }

            rv = mm2s_ringbuffer_put(mm2s_0, putbuffer, n_bytes);
            if (rv > 0) {
                n_mm2s_bytes += rv;
            }

            mm2s_ringbuffer_commit(mm2s_0);
        } else {
            done = 1;
        }

        if (done) {
            sim_exit(0);
        }
    }
}

int main(void)
{
    printf("%d: %s\n", mtime_get(), "Hello FreeRTOS!");

    sem_mm2s = xSemaphoreCreateBinary();
    sem_s2mm = xSemaphoreCreateBinary();
    sem_isr = xSemaphoreCreateBinary();

    // xTaskCreate(isr_task, "tisr", configMINIMAL_STACK_SIZE*2, NULL, tskIDLE_PRIORITY + 3, NULL);
    xTaskCreate(s2mm_ringbuffer_task, "s2mm", configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 3, NULL);
    xTaskCreate(mm2s_ringbuffer_task, "mm2s", configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 2, NULL);
    xTaskCreate(stats_task, "stats", configMINIMAL_STACK_SIZE, NULL, tskIDLE_PRIORITY + 4, NULL);

    int i;
    for (i = 0; i < PUT_BUFFER_SIZE; i++) {
        putbuffer[i] = i;
    }

    // write32(RINGBUFFER_INT_ENABLE, RINGBUFFER__INTR_ENABLE__S2MM_0_bm | RINGBUFFER__INTR_ENABLE__MM2S_0_bm);
    write32(RINGBUFFER_INT_ENABLE, RINGBUFFER__INTR_ENABLE__S2MM_0_bm);

    sim_putstring("vTaskStartScheduler\n");
    vTaskStartScheduler();

    return 0;
}
