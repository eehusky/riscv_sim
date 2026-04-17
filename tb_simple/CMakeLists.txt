cmake_minimum_required(VERSION 3.5)
project(tb_simple)

set(REPO_DIR                  ${CMAKE_CURRENT_SOURCE_DIR}/../../)

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



set(CMAKE_CXX_STANDARD          ${SystemC_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ${SystemC_CXX_STANDARD_REQUIRED})
set(CMAKE_EXPORT_COMPILE_COMMANDS   "ON")

set(CXX_WARNING           "-Wall -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation")

set(CMAKE_CXX_FLAGS             "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS               "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")

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

verilator_link_systemc(tb_simple)
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
        ${REPO_DIR}/src/core/
    TOP_MODULE
        tb_riscv_tcm_top
    SOURCES
        ##
        ${REPO_DIR}/src/core/biriscv_alu.v
        ${REPO_DIR}/src/core/biriscv_csr_regfile.v
        ${REPO_DIR}/src/core/biriscv_csr.v
        ${REPO_DIR}/src/core/biriscv_decoder.v
        ${REPO_DIR}/src/core/biriscv_decode.v
        ${REPO_DIR}/src/core/biriscv_defs.v
        ${REPO_DIR}/src/core/biriscv_divider.v
        ${REPO_DIR}/src/core/biriscv_exec.v
        ${REPO_DIR}/src/core/biriscv_fetch.v
        ${REPO_DIR}/src/core/biriscv_frontend.v
        ${REPO_DIR}/src/core/biriscv_issue.v
        ${REPO_DIR}/src/core/biriscv_lsu.v
        ${REPO_DIR}/src/core/biriscv_mmu.v
        ${REPO_DIR}/src/core/biriscv_multiplier.v
        ${REPO_DIR}/src/core/biriscv_npc.v
        ${REPO_DIR}/src/core/biriscv_pipe_ctrl.v
        ${REPO_DIR}/src/core/biriscv_regfile.v
        ${REPO_DIR}/src/core/biriscv_trace_sim.v
        ${REPO_DIR}/src/core/biriscv_xilinx_2r1w.v
        ${REPO_DIR}/src/core/riscv_core.v
        ##
        ${REPO_DIR}/src/dcache/dcache_axi_axi.v
        ${REPO_DIR}/src/dcache/dcache_axi.v
        ${REPO_DIR}/src/dcache/dcache_core_data_ram.v
        ${REPO_DIR}/src/dcache/dcache_core_tag_ram.v
        ${REPO_DIR}/src/dcache/dcache_core.v
        ${REPO_DIR}/src/dcache/dcache_if_pmem.v
        ${REPO_DIR}/src/dcache/dcache_mux.v
        ${REPO_DIR}/src/dcache/dcache_pmem_mux.v
        ${REPO_DIR}/src/dcache/dcache.v
        ##
        ${REPO_DIR}/src/icache/icache_data_ram.v
        ${REPO_DIR}/src/icache/icache_tag_ram.v
        ${REPO_DIR}/src/icache/icache.v
        ##
        ${REPO_DIR}/src/tcm/dport_axi.v
        ${REPO_DIR}/src/tcm/dport_mux.v
        ${REPO_DIR}/src/tcm/tcm_mem_pmem.v
        ${REPO_DIR}/src/tcm/tcm_mem_ram.v
        ${REPO_DIR}/src/tcm/tcm_mem.v
        ##
        ${REPO_DIR}/src/top/riscv_tcm_top.v
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
