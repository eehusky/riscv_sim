
all:
runall: runcoremark runfreertos rundemo runringbuffer
rundemo: cv32e40p_demo
runfreertos: biriscv_freertos cv32e40p_freertos
runcoremark: biriscv_coremark cv32e40p_coremark ibex_coremark picorv32_coremark
runringbuffer: cv32e40p_ringbuffer
rundebug: ibex_debug

FRESH ?= 1
ifeq ($(FRESH), 1)
    FRESH = --fresh
else
    FRESH =
endif

biriscv_demo:
	mkdir -p build
	cmake -S biriscv/apps/baremetal_demo -B build $(FRESH)
	cmake --build build/
	../tb/biriscv/demo/build/tb_biriscv -f build/baremetal_demo.elf

biriscv_freertos:
	mkdir -p build
	cmake -S biriscv/apps/freertos_demo -B build $(FRESH)
	cmake --build build/
	../tb/biriscv/benchmark/build/tb_biriscv -f build/freertos_demo.elf

biriscv_ringbuffer:
	mkdir -p build
	cmake -S biriscv/apps/ringbuffer_demo -B build $(FRESH)
	cmake --build build/
	../tb/biriscv/ringbuffer/build/tb_biriscv -f build/ringbuffer_demo.elf

biriscv_coremark:
	mkdir -p build
	cmake -S biriscv/apps/coremark_demo -B build $(FRESH)
	cmake --build build/
	../tb/biriscv/benchmark/build/tb_biriscv -f build/coremark.elf

##


rsd_demo:
	mkdir -p build
	cmake -S rsd/apps/baremetal_demo -B build $(FRESH)
	cmake --build build/
	../tb/rsd/rsd_top/build/tb_rsd_top -f build/apprsd.elf -c 23500

##


cv32e40p_demo:
	mkdir -p build
	cmake -S cv32e40p/apps/baremetal_demo -B build $(FRESH)
	cmake --build build/
	../tb/cv32e40p/demo/build/tb_cv32e40p -f build/baremetal_demo.elf

cv32e40p_freertos:
	mkdir -p build
	cmake -S cv32e40p/apps/freertos_demo -B build $(FRESH)
	cmake --build build/
	../tb/cv32e40p/benchmark/build/tb_cv32e40p -f build/freertos_demo.elf

cv32e40p_ringbuffer:
	mkdir -p build
	cmake -S cv32e40p/apps/ringbuffer_demo -B build $(FRESH)
	cmake --build build/
	../tb/cv32e40p/ringbuffer/build/tb_cv32e40p -f build/ringbuffer_demo.elf

cv32e40p_coremark:
	mkdir -p build
	cmake -S cv32e40p/apps/coremark_demo -B build $(FRESH)
	cmake --build build/
	../tb/cv32e40p/benchmark/build/tb_cv32e40p -f build/coremark.elf

##


ibex_demo:
	mkdir -p build
	cmake -S ibex/apps/baremetal_demo -B build --fresh
	cmake --build build/
	../tb/ibex/demo/build/tb_ibex -f build/baremetal_demo.elf

ibex_freertos:
	mkdir -p build
	cmake -S ibex/apps/freertos_demo -B build --fresh
	cmake --build build/
	../tb/ibex/debug/build/tb_ibex -f build/freertos_demo.elf

ibex_coremark:
	mkdir -p build
	cmake -S ibex/apps/coremark_demo -B build --fresh
	cmake --build build/
	../tb/ibex/benchmark/build/tb_ibex -f build/coremark.elf

ibex_debug:
	mkdir -p build
	cmake -S ibex/apps/debug_demo -B build --fresh
	cmake --build build/
	../tb/ibex/debug/build/tb_ibex -f build/baremetal_debug.elf


##


picorv32_coremark:
	mkdir -p build
	cmake -S picorv32/apps/coremark_demo -B build --fresh
	cmake --build build/
	../tb/picorv32/benchmark/build/tb_picorv32 -f build/coremark.elf


##

clean:
	rm -rf ./build/
	rm -rf ./.cache


.PHONY: clean
.PHONY: cv32e40p_demo cv32e40p_freertos cv32e40p_ringbuffer cv32e40p_coremark cv32e40p_debug
.PHONY: ibex_demo     ibex_freertos     ibex_ringbuffer     ibex_coremark     ibex_debug
.PHONY: biriscv_demo  biriscv_freertos  biriscv_ringbuffer  biriscv_coremark  biriscv_debug
.PHONY: rsd_demo      rsd_freertos      rsd_ringbuffer      rsd_coremark      rsd_debug
.PHONY: picorv32_demo picorv32_freertos picorv32_ringbuffer picorv32_coremark picorv32_debug
FORCE:
