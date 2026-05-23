

ifeq ($(BUILD_DIR),)
$(error BUILD_DIR is not set or is empty)
endif

ifeq ($(TB_DIR),)
$(error TB_DIR is not set or is empty)
endif

RUN?=1

all:

baremetal_demo: $(TB_DIR)/demo/build/tb_top
	mkdir -p $(BUILD_DIR)
	cmake -S $@ -B $(BUILD_DIR) --fresh
	cmake --build $(BUILD_DIR)
	@if [ "$(RUN)" = "1" ]; then   \
		$< -f $(BUILD_DIR)/$@.elf; \
	fi

freertos_demo: $(TB_DIR)/benchmark/build/tb_top
	mkdir -p $(BUILD_DIR)
	cmake -S $@ -B $(BUILD_DIR) --fresh
	cmake --build $(BUILD_DIR)
	@if [ "$(RUN)" = "1" ]; then   \
		$< -f $(BUILD_DIR)/$@.elf; \
	fi

coremark: $(TB_DIR)/benchmark/build/tb_top
	mkdir -p $(BUILD_DIR)
	cmake -S $@ -B $(BUILD_DIR) --fresh
	cmake --build $(BUILD_DIR)
	@if [ "$(RUN)" = "1" ]; then   \
		$< -f $(BUILD_DIR)/$@.elf; \
	fi

dhrystone: $(TB_DIR)/benchmark/build/tb_top
	mkdir -p $(BUILD_DIR)
	cmake -S $@ -B $(BUILD_DIR) --fresh
	cmake --build $(BUILD_DIR)
	@if [ "$(RUN)" = "1" ]; then   \
		$< -f $(BUILD_DIR)/$@.elf; \
	fi

baremetal_debug: $(TB_DIR)/debug/build/tb_top
	mkdir -p $(BUILD_DIR)
	cmake -S $@ -B $(BUILD_DIR) --fresh
	cmake --build $(BUILD_DIR)
	@if [ "$(RUN)" = "1" ]; then   \
		$< -f $(BUILD_DIR)/$@.elf; \
	fi


.PHONY: baremetal_demo freertos_demo coremark baremetal_debug dhrystone
