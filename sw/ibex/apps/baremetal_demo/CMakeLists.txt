cmake_minimum_required(VERSION 3.10)

set(REPO_DIR    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../)
set(CPU         ${CMAKE_CURRENT_SOURCE_DIR}/../../)
set(COMMON      ${REPO_DIR}/sw/common/)

list(APPEND CMAKE_MODULE_PATH ${COMMON}/riscv/)
include(riscv)

project(ibex_baremetal_demo)
enable_language(ASM)
set(CMAKE_EXPORT_COMPILE_COMMANDS "ON")


set(STACK_SIZE    0x1000 )
set(TARGET        baremetal_demo )
set(LINKER_SCRIPT ${CPU}/baremetal/linker.ld)



add_executable(${TARGET}.elf
    main.c
    ${COMMON}/riscv/riscv_hpm.c
    ${COMMON}/riscv/riscv_info.c
    ${COMMON}/nstdio.c
    ${COMMON}/strlen.c
    ${CPU}/baremetal/start.S
    ${CPU}/baremetal/entry.c
    ${CPU}/baremetal/vector_table.c
    ${CPU}/syscalls.c
    ${CPU}/ibex_hpm.c
)
target_include_directories(${TARGET}.elf
    PRIVATE
        ${COMMON}/riscv/
        ${COMMON}/
        ${CPU}/
        ${CPU}/baremetal
        ${REPO_DIR}/cores/nanoprintf/
)
target_link_libraries(${TARGET}.elf
    PRIVATE
        #/opt/riscv/riscv64-unknown-elf/lib/rv32imafc/ilp32f/libc_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32imafc/ilp32f/libm_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32imafc/ilp32f/libg_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32imafc/ilp32f/libgloss_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libc_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libm_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libg_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libgloss_nano.a
)

set(PROJECT_C_FLAGS
    -O3
    -nostartfiles
    -fno-exceptions
    -ffunction-sections
    -fdata-sections
    -Wall
    #-march=rv32im
    #-mabi=ilp32
    -march=rv32im_zicsr_zifencei_zicntr
    -mabi=ilp32
    -MD
    -mcmodel=medlow
    -mstrict-align
)
set(PROJECT_LINKER_FLAGS
    -nostdlib
    -T${LINKER_SCRIPT}
    -Wl,-Map=${TARGET}.map
    -Wl,--gc-sections
    -Wl,--defsym=__stack_size=${STACK_SIZE}
    -Wl,-Arv32im
    -Wl,-belf32-littleriscv
)


## ----------------------------------------------------------------------------
## ----------------------------------------------------------------------------
## ----------------------------------------------------------------------------

set_target_properties(${TARGET}.elf
    PROPERTIES
        LINK_DEPENDS "${LINKER_SCRIPT}"
)
list(JOIN PROJECT_C_FLAGS      " " _PROJECT_C_FLAGS)
list(JOIN PROJECT_LINKER_FLAGS " " _PROJECT_LINKER_FLAGS)
set(CMAKE_EXE_LINKER_FLAGS  ${_PROJECT_LINKER_FLAGS})
set(CMAKE_CXX_FLAGS         ${_PROJECT_C_FLAGS})
set(CMAKE_ASM_FLAGS         ${_PROJECT_C_FLAGS})
set(CMAKE_C_FLAGS           ${_PROJECT_C_FLAGS})

# Post processing command to create a disassembly file
add_custom_command(
    TARGET ${TARGET}.elf
    POST_BUILD
    COMMAND ${CMAKE_OBJDUMP} -t -S ${TARGET}.elf > ${TARGET}.S
    COMMAND ${CMAKE_OBJDUMP} -t -S --visualize-jumps ${TARGET}.elf > ${TARGET}.disasm
    COMMENT "Invoking: Disassemble"
)

# Post processing command to create a hex file
add_custom_command(
    TARGET ${TARGET}.elf
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex  ${TARGET}.elf  ${TARGET}.hex
    COMMENT "Invoking: Hexdump"
)

add_custom_command(
    TARGET ${TARGET}.elf
    POST_BUILD
    COMMAND ${CMAKE_SIZE} ${TARGET}.elf
    COMMENT "Invoking: Size"
)
