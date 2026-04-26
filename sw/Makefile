
all:



app1:
	mkdir -p build
	cmake -S app1 -B build
	make -C build/
	../tb/biriscv/riscv_top/build/tb_biriscv_idcache_top -f build/app1.elf

apprsd:
	mkdir -p build
	cmake -S apprsd -B build
	make -C build/
	../tb/rsd/rsd_top/build/tb_rsd_top -f build/apprsd.elf -c 23500

freertos:
	mkdir -p build
	cmake -S freertos -B build
	make -C build/
	../tb/biriscv/riscv_top/build/tb_biriscv_idcache_top -f build/biriscv_freertos.elf

clean:
	rm -rf ./build/
	rm -rf ./.cache


.PHONY: sim clean app1 apprsd freertos
FORCE:
