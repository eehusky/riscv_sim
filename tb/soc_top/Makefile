COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

export PYGPI_PYTHON_BIN := $(shell cocotb-config --python-bin)
export COCOTB_TRUST_INERTIAL_WRITES = 1
export COCOTB_TEST_MODULES = $(subst $(SPACE),$(COMMA),$(basename $(wildcard test_*.py)))
export LIBPYTHON_LOC := $(shell cocotb-config --libpython)

all: sim

regblock:
	make -C build/ pyregblock
	make -C build/ installpyregblock

build/Makefile:
	mkdir -p build
	cd build && cmake ..

build/Vtop: build/Makefile FORCE
	make -C build/ --jobs=$(shell nproc)

bclean:
	rm -rf ./.generated/
	rm -rf ./build/
	rm -rf ./.pytest_cache
	rm -rf ./__pycache__
	rm -f ./results.xml
	rm -f ./dump.fst

clean: bclean
	rm -rf ./results
	rm -rf ./test_results_summary.xml

sim: build/Vtop FORCE
	./build/Vtop --trace

.PHONY: sim clean bclean
FORCE:
