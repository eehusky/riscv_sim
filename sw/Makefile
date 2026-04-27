
all:



app1:
	mkdir -p build
	cmake -S biriscv/apps/baremetal_demo -B build
	make -C build/
	../tb/biriscv/riscv_top/build/tb_biriscv_idcache_top -f build/app1.elf


freertos:
	mkdir -p build
	cmake -S biriscv/apps/freertos_demo -B build
	make -C build/
	../tb/biriscv/riscv_top/build/tb_biriscv_idcache_top -f build/freertos_demo.elf

ringbuffer:
	mkdir -p build
	cmake -S biriscv/apps/ringbuffer_demo -B build
	make -C build/
	../tb/biriscv/riscv_top/build/tb_biriscv_idcache_top -f build/ringbuffer_demo.elf

apprsd:
	mkdir -p build
	cmake -S rsd/apps/baremetal_demo -B build
	make -C build/
	../tb/rsd/rsd_top/build/tb_rsd_top -f build/apprsd.elf -c 23500

clean:
	rm -rf ./build/
	rm -rf ./.cache


.PHONY: sim clean app1 apprsd freertos ringbuffer
FORCE:
