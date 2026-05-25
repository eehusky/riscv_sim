cmake_minimum_required(VERSION 3.10)

set(REPO_DIR    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../)
set(CPU         ${CMAKE_CURRENT_SOURCE_DIR}/../../)
set(COMMON      ${REPO_DIR}/sw/common/)
set(COREMARK    ${REPO_DIR}/cores/coremark)

list(APPEND CMAKE_MODULE_PATH ${COMMON}/riscv/)
include(riscv)

project(coremark_demo)
enable_language(ASM)
set(CMAKE_EXPORT_COMPILE_COMMANDS "ON")


set(STACK_SIZE    0x1000 )
set(TARGET        coremark )
set(LINKER_SCRIPT ${CPU}/baremetal/linker.ld)



add_executable(${TARGET}.elf
    ${COREMARK}/core_main.c
    ${COREMARK}/core_list_join.c
    ${COREMARK}/core_matrix.c
    ${COREMARK}/core_state.c
    ${COREMARK}/core_util.c
    ${COMMON}/coremark/barebones/core_portme.c
    ${COMMON}/coremark/barebones/ee_printf.c
    ${COMMON}/coremark/barebones/cvt.c


    ${CPU}/baremetal/start.S
    ${CPU}/baremetal/entry.c
    ${CPU}/baremetal/vector_table.c
    #${CPU}/syscalls.c
    ${COMMON}/memset.c
    ${COMMON}/memcpy.c
)
target_include_directories(${TARGET}.elf
    PRIVATE
        ${COREMARK}/
        ${COMMON}/coremark/barebones
        ${COMMON}/riscv/
        ${CPU}/
        ${CPU}/baremetal
        ${REPO_DIR}/cores/nanoprintf/
)
target_link_libraries(${TARGET}.elf
    PRIVATE
        #/opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libc_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libm_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libg_nano.a
        #/opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libgloss_nano.a
)

set(PROJECT_OPT_FLAGS
    -O3
    -flto
    CACHE STRING "PROJECT_OPT_FLAGS"
)
set(PROJECT_M_FLAGS
    #-march=rv32im_zicsr_zifencei_zicntr
    -march=rv32imb_zicsr_zifencei_zicntr
    #-march=rv32imbc_zicsr_zifencei_zicntr_zcmp_zcb
    -mabi=ilp32
    -mcmodel=medlow
    -mstrict-align
    CACHE STRING "PROJECT_M_FLAGS"
)
set(PROJECT_DEFINES
    -DITERATIONS=10
    -DCLOCKS_PER_SEC=100000000
    -DHAS_FLOAT=0
    -DMULTITHREAD=1
    -DCORE_DEBUG=0
    -DMAIN_HAS_NOARGC=1
    -DVALIDATION_RUN=0
    -DPERFORMANCE_RUN=1
    CACHE STRING "PROJECT_DEFINES"
)
set(PROJECT_HOUSEKEEPING_FLAGS
    -nostartfiles
    -fno-exceptions
    -ffunction-sections
    -fdata-sections
    -falign-functions=4
    -Wall
    -MD
)

set(PROJECT_C_FLAGS ${PROJECT_OPT_FLAGS} ${PROJECT_M_FLAGS} ${PROJECT_DEFINES} ${PROJECT_HOUSEKEEPING_FLAGS})

set(PROJECT_LINKER_FLAGS
    -nostdlib
    -T${LINKER_SCRIPT}
    -Wl,-Map=${TARGET}.map
    -Wl,--gc-sections
    -Wl,--defsym=__stack_size=${STACK_SIZE}
    -Wl,-Arv32imb_zicsr_zifencei_zicntr_zcmp_zcb
    -Wl,-belf32-littleriscv
    #-flto=auto
    #-fwhole-program
)
list(APPEND PROJECT_C_FLAGS -DCOMPILER_FLAGS='\"${PROJECT_C_FLAGS}\"')
list(APPEND PROJECT_C_FLAGS -DLINKER_FLAGS='\"${PROJECT_LINKER_FLAGS}\"')

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
