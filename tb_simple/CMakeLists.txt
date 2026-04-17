cmake_minimum_required(VERSION 3.5)
project(tb_simple)

set(REPO_DIR                  ${CMAKE_CURRENT_SOURCE_DIR}/../../)
set(BIRISCV                   ${REPO_DIR}/cores/birisc)

find_package(verilator
    NO_DEFAULT_PATH
    PATHS
        $ENV{VERILATOR_ROOT}
)

find_package(SystemCLanguage
    NO_DEFAULT_PATH
    PATHS
        $ENV{SYSTEMC}
)



set(CMAKE_CXX_STANDARD              ${SystemC_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED     ${SystemC_CXX_STANDARD_REQUIRED})
set(CMAKE_EXPORT_COMPILE_COMMANDS   "ON")
set(CXX_WARNING                     "-Wall -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation")
set(CMAKE_CXX_FLAGS                 "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS                   "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")

string(STRIP ${CMAKE_CXX_FLAGS} CMAKE_CXX_FLAGS)
string(STRIP ${CMAKE_C_FLAGS}   CMAKE_C_FLAGS)


set(MY_VERILATOR_ARGS
    -O3
    --timescale-override 1ns/1ns
    #--x-assign fast
    #--x-initial fast
    #--noassert
    #--decorations none
    -Wno-context
    #--Wall
    --report-unoptflat
    --expand-limit 100000
    --trace-fst
    --unroll-count 512
    -CFLAGS "${CMAKE_CXX_FLAGS}"
    -LDFLAGS "-lelf -lbfd"
)


add_executable(tb_simple
    elf_load.cpp
    sim_main.cpp
)

verilate(tb_simple
    PREFIX
        Vtb_riscv_tcm_top
    OPT_GLOBAL
        ${CMAKE_CXX_FLAGS}
    OPT_SLOW
        ${CMAKE_CXX_FLAGS}
    OPT_FAST
        ${CMAKE_CXX_FLAGS}
    INCLUDE_DIRS
        ${BIRISCV}/src/core/
    TOP_MODULE
        tb_riscv_tcm_top
    SOURCES
        ##
        ${BIRISCV}/src/core/biriscv_alu.v
        ${BIRISCV}/src/core/biriscv_csr_regfile.v
        ${BIRISCV}/src/core/biriscv_csr.v
        ${BIRISCV}/src/core/biriscv_decoder.v
        ${BIRISCV}/src/core/biriscv_decode.v
        ${BIRISCV}/src/core/biriscv_defs.v
        ${BIRISCV}/src/core/biriscv_divider.v
        ${BIRISCV}/src/core/biriscv_exec.v
        ${BIRISCV}/src/core/biriscv_fetch.v
        ${BIRISCV}/src/core/biriscv_frontend.v
        ${BIRISCV}/src/core/biriscv_issue.v
        ${BIRISCV}/src/core/biriscv_lsu.v
        ${BIRISCV}/src/core/biriscv_mmu.v
        ${BIRISCV}/src/core/biriscv_multiplier.v
        ${BIRISCV}/src/core/biriscv_npc.v
        ${BIRISCV}/src/core/biriscv_pipe_ctrl.v
        ${BIRISCV}/src/core/biriscv_regfile.v
        ${BIRISCV}/src/core/biriscv_trace_sim.v
        ${BIRISCV}/src/core/biriscv_xilinx_2r1w.v
        ${BIRISCV}/src/core/riscv_core.v
        ##
        ${BIRISCV}/src/dcache/dcache_axi_axi.v
        ${BIRISCV}/src/dcache/dcache_axi.v
        ${BIRISCV}/src/dcache/dcache_core_data_ram.v
        ${BIRISCV}/src/dcache/dcache_core_tag_ram.v
        ${BIRISCV}/src/dcache/dcache_core.v
        ${BIRISCV}/src/dcache/dcache_if_pmem.v
        ${BIRISCV}/src/dcache/dcache_mux.v
        ${BIRISCV}/src/dcache/dcache_pmem_mux.v
        ${BIRISCV}/src/dcache/dcache.v
        ##
        ${BIRISCV}/src/icache/icache_data_ram.v
        ${BIRISCV}/src/icache/icache_tag_ram.v
        ${BIRISCV}/src/icache/icache.v
        ##
        ${BIRISCV}/src/tcm/dport_axi.v
        ${BIRISCV}/src/tcm/dport_mux.v
        ${BIRISCV}/src/tcm/tcm_mem_pmem.v
        ${BIRISCV}/src/tcm/tcm_mem_ram.v
        ${BIRISCV}/src/tcm/tcm_mem.v
        ##
        ${BIRISCV}/src/top/riscv_tcm_top.v
        ##
        riscv_tcm_top_wrapper.v
        tb_riscv_tcm_top.sv
        #
    VERILATOR_ARGS
        ${MY_VERILATOR_ARGS}
)


target_include_directories(tb_simple
    PUBLIC
        SystemC::systemc
        ${.}
)
