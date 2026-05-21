
all: biriscv ibex cv32e40p picorv32


biriscv:
	make -C biriscv/benchmark all

ibex:
	make -C ibex/benchmark all
	make -C ibex/debug all

picorv32:
	make -C picorv32/benchmark all

cv32e40p:
	make -C cv32e40p/benchmark all
	make -C cv32e40p/demo all
	make -C cv32e40p/ringbuffer all


clean:
	make -C biriscv/benchmark clean
	make -C ibex/benchmark clean
	make -C picorv32/benchmark clean
	make -C cv32e40p/benchmark clean
	make -C cv32e40p/demo clean
	make -C cv32e40p/ringbuffer clean


.PHONY: clean
.PHONY: cv32e40p
.PHONY: ibex
.PHONY: biriscv
.PHONY: picorv32

FORCE:
