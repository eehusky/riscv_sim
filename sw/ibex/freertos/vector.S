.balign 256, 0
.option norvc
.global freertos_vector_table
freertos_vector_table:
IRQ_0:
        j freertos_risc_v_exception_handler
IRQ_1:
        j freertos_risc_v_interrupt_handler
IRQ_2:
        j freertos_risc_v_interrupt_handler
IRQ_3:
        j freertos_risc_v_interrupt_handler
IRQ_4:
        j freertos_risc_v_interrupt_handler
IRQ_5:
        j freertos_risc_v_interrupt_handler
IRQ_6:
        j freertos_risc_v_interrupt_handler
IRQ_7:
        j freertos_risc_v_mtimer_interrupt_handler
IRQ_8:
        j freertos_risc_v_interrupt_handler
IRQ_9:
        j freertos_risc_v_interrupt_handler
IRQ_10:
        j freertos_risc_v_interrupt_handler
IRQ_11:
        j freertos_risc_v_interrupt_handler
IRQ_12:
        j freertos_risc_v_interrupt_handler
IRQ_13:
        j freertos_risc_v_interrupt_handler
IRQ_14:
        j freertos_risc_v_interrupt_handler
IRQ_15:
        j freertos_risc_v_interrupt_handler
