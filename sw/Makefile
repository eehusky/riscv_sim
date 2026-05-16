
all:



biriscv_demo:
	mkdir -p build
	cmake -S biriscv/apps/baremetal_demo -B build
	make -C build/
	../tb/biriscv/demo/build/tb_biriscv -f build/baremetal_demo.elf


biriscv_freertos:
	mkdir -p build
	cmake -S biriscv/apps/freertos_demo -B build
	make -C build/
	../tb/biriscv/benchmark/build/tb_biriscv -f build/freertos_demo.elf

biriscv_ringbuffer:
	mkdir -p build
	cmake -S biriscv/apps/ringbuffer_demo -B build
	make -C build/
	../tb/biriscv/ringbuffer/build/tb_biriscv -f build/ringbuffer_demo.elf

biriscv_coremark:
	mkdir -p build
	cmake -S biriscv/apps/coremark_demo -B build
	make -C build/
	../tb/biriscv/benchmark/build/tb_biriscv -f build/coremark.elf

##


rsd_demo:
	mkdir -p build
	cmake -S rsd/apps/baremetal_demo -B build
	make -C build/
	../tb/rsd/rsd_top/build/tb_rsd_top -f build/apprsd.elf -c 23500

##

cv32e40p_demo:
	mkdir -p build
	cmake -S cv32e40p/apps/baremetal_demo -B build
	make -C build/

cv32e40p_freertos:
	mkdir -p build
	cmake -S cv32e40p/apps/freertos_demo -B build
	make -C build/

cv32e40p_ringbuffer:
	mkdir -p build
	cmake -S cv32e40p/apps/ringbuffer_demo -B build
	make -C build/

cv32e40p_coremark:
	mkdir -p build
	cmake -S cv32e40p/apps/coremark_demo -B build
	make -C build/
	../tb/cv32e40p/benchmark/build/tb_cv32e40p -f build/coremark.elf

##

ibex_coremark:
	mkdir -p build
	cmake -S ibex/apps/coremark_demo -B build
	make -C build/
	../tb/ibex/benchmark/build/tb_ibex -f build/coremark.elf



clean:
	rm -rf ./build/
	rm -rf ./.cache


.PHONY: clean
.PHONY: cv32e40p_demo cv32e40p_freertos cv32e40p_ringbuffer cv32e40p_coremark
.PHONY: ibex_demo     ibex_freertos     ibex_ringbuffer     ibex_coremark
.PHONY: biriscv_demo  biriscv_freertos  biriscv_ringbuffer  biriscv_coremark
.PHONY: rsd_demo      rsd_freertos      rsd_ringbuffer      rsd_coremark
FORCE:
