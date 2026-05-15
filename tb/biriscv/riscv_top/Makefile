
all: sim

build/Makefile:
	mkdir -p build
	cd build && cmake ..

build/risvc_top: build/Makefile FORCE
	make -C build/ --jobs=$(shell nproc)

clean:
	rm -rf ./.generated/
	rm -rf ./.cache/
	rm -rf ./build/
	rm -rf ./.pytest_cache
	rm -rf ./__pycache__
	rm -f ./results.xml
	rm -f ./dump.fst


sim: build/risvc_top FORCE
	#./build/risvc_top

.PHONY: sim clean bclean
FORCE:
