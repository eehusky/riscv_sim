cmake_minimum_required(VERSION 3.5)
project(tb_biriscv_benchmark)

set(REPO_DIR                  ${CMAKE_CURRENT_SOURCE_DIR}/../../../)
set(BIRISCV      ${REPO_DIR}/cores/biriscv)
set(VERILOG_AXI  ${REPO_DIR}/cores/verilog-axi/)
set(VERILOG_UART ${REPO_DIR}/cores/verilog-uart/)
set(WB2AXIP      ${REPO_DIR}/cores/wb2axip/)


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

set(PGO_FLAGS "")
if ("$ENV{PGO}" STREQUAL "GEN")
    execute_process(COMMAND echo "PROFILE GENERATION")
    set(PGO_FLAGS "-fprofile-generate")
endif()
if ("$ENV{PGO}" STREQUAL "USE")
    execute_process(COMMAND echo "PROFILE COMPILE")
    set(PGO_FLAGS "-fprofile-use -fprofile-correction")
endif()



set(CMAKE_CXX_STANDARD              ${SystemC_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED     ${SystemC_CXX_STANDARD_REQUIRED})
set(CMAKE_EXPORT_COMPILE_COMMANDS   "ON")
set(CXX_WARNING                     "-Wall -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation -Wno-uninitialized")
set(CMAKE_CXX_FLAGS                 "${PGO_FLAGS} -O3 -flto -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS                   "${PGO_FLAGS} -O3 -flto -fstrict-aliasing -march=native ${CXX_WARNING}")
set(LD_FLAGS                        "${PGO_FLAGS} -flto=auto -fwhole-program")

string(STRIP ${CMAKE_CXX_FLAGS} CMAKE_CXX_FLAGS)
string(STRIP ${CMAKE_C_FLAGS}   CMAKE_C_FLAGS)
string(STRIP ${LD_FLAGS}        LD_FLAGS)


set(MY_VERILATOR_ARGS
    -O3
    --timescale-override 1ns/1ns
    #--x-assign fast
    #--x-initial fast
    #--noassert
    #--decorations none
    -Wno-NORETURN
    -Wno-WIDTHEXPAND
    -Wno-WIDTHTRUNC
    -Wno-CASEINCOMPLETE
    -Wno-context
    #--Wall
    --report-unoptflat
    #--expand-limit 100000
    #--unroll-count 512
    #--trace-fst
    --trace-structs
    --no-trace-params
    -CFLAGS "${CMAKE_CXX_FLAGS}"
    -LDFLAGS "-lelf -lbfd"
)


add_executable(tb_top
    ../../common/elf_load.cpp
    sim_main.cpp
)

verilate(tb_top
    PREFIX
        Vtb_top
    OPT_GLOBAL
        ${CMAKE_CXX_FLAGS}
    OPT_SLOW
        ${CMAKE_CXX_FLAGS}
    OPT_FAST
        ${CMAKE_CXX_FLAGS}
    INCLUDE_DIRS
        ${BIRISCV}/src/core/
    TOP_MODULE
        tb_top
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

        ## DPORT
        ${WB2AXIP}/rtl/sfifo.v
        ${REPO_DIR}/rtl/dport/obi_pkg.sv
        ${REPO_DIR}/rtl/dport/obi2iob.sv
        ${REPO_DIR}/rtl/dport/obi2axi.sv
        ${REPO_DIR}/rtl/dport/obi2axil.sv
        ${REPO_DIR}/rtl/dport/obi_addrdecode.sv
        ${REPO_DIR}/rtl/dport/obi_mux.sv
        ${REPO_DIR}/rtl/dport/obi_demux.sv
        ${REPO_DIR}/rtl/dport/obi_ram.sv
        ${REPO_DIR}/rtl/dport/obi_xbar.sv
        ${REPO_DIR}/rtl/dport/obi_dummy.sv
        ${REPO_DIR}/rtl/dport/obi_if.sv
        ${REPO_DIR}/rtl/dport/axi_if.sv
        ${REPO_DIR}/rtl/dport/axil_if.sv
        ${REPO_DIR}/rtl/dport/obi_rsp_queue.sv
        ${REPO_DIR}/rtl/dport/obi_dtcm.sv
        #
        ${REPO_DIR}/rtl/dport/mtime32.sv
        ${REPO_DIR}/rtl/dport/sim_ctrl.sv
        #${VERILOG_AXI}/rtl/axi_dp_ram.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_rd_if.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_if.v
        ${VERILOG_AXI}/rtl/axi_ram_rd_if.v
        #${VERILOG_AXI}/rtl/axil_ram.v
        #${VERILOG_AXI}/rtl/axi_ram.v

        ##
        ../biriscv_wrapper.sv
        tb_top.sv
        #
    VERILATOR_ARGS
        ${MY_VERILATOR_ARGS}
)


target_include_directories(tb_top
    PUBLIC
        SystemC::systemc
        ${.}
        ../../common/
)
