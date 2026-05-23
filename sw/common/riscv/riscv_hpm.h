#ifndef __RISCV_HPM_H__
#define __RISCV_HPM_H__
#include <stdint.h>

uint32_t riscv_hpm_get_n_counters(void);
char *riscv_hpm_get_counter_name(uint32_t index);

void riscv_hpm_init_counters(void);
void riscv_hpm_pause(void);
void riscv_hpm_resume(void);
void riscv_hpm_clear_counters(void);
void riscv_hpm_fetch_counters(uint32_t data[32]);
void riscv_hpm_counters_dump(void);

//void riscv_hpm_select_counters(void);
//void riscv_hpm_fetch_events(uint32_t data[32]);
//void riscv_hpm_check_implemented(void);
//void riscv_hpm_events_dump(void);
//void riscv_get_event_ids(int32_t ids[32]);



#endif
