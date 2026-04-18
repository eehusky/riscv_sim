cmake_minimum_required(VERSION 3.5)
project(tb_soc_top)

set(REPO_DIR        ${CMAKE_CURRENT_SOURCE_DIR}/../../)
set(VERILOG_AXI $ENV{HOME}/github/alexforencich/verilog-axi/)

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
set(CMAKE_CXX_FLAGS             "-Og -fstrict-aliasing -march=native -Wall -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation")
set(CMAKE_C_FLAGS               "-Og -fstrict-aliasing -march=native -Wall -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation")


############################################################
# Verilation!
############################################################
execute_process(COMMAND cocotb-config --share   OUTPUT_VARIABLE COCOTB_SHARE OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND cocotb-config --lib-dir OUTPUT_VARIABLE COCOTB_LIB_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)

add_executable(Vtop)
verilate(Vtop
    PREFIX Vtop
    OPT_GLOBAL
        ${CMAKE_CXX_FLAGS}
    OPT_SLOW
        ${CMAKE_CXX_FLAGS}
    OPT_FAST
        ${CMAKE_CXX_FLAGS}
    TOP_MODULE
        tb_soc_top
    SOURCES
        ${VERILOG_AXI}/rtl/axi_ram.v
        ${VERILOG_AXI}/rtl/axi_crossbar.v
        ${VERILOG_AXI}/rtl/axi_crossbar_wr.v
        ${VERILOG_AXI}/rtl/axi_crossbar_rd.v
        ${VERILOG_AXI}/rtl/axi_crossbar_addr.v
        ${VERILOG_AXI}/rtl/axi_register_rd.v
        ${VERILOG_AXI}/rtl/axi_register_wr.v
        ${VERILOG_AXI}/rtl/axi_axil_adapter.v
        ${VERILOG_AXI}/rtl/axi_axil_adapter_wr.v
        ${VERILOG_AXI}/rtl/axi_axil_adapter_rd.v
        ${VERILOG_AXI}/rtl/arbiter.v
        ${VERILOG_AXI}/rtl/priority_encoder.v
        #
        ${REPO_DIR}/rtl/soc_mem.vlt
        ${REPO_DIR}/rtl/soc_mem.sv
        ${REPO_DIR}/rtl/axi_crossbar_wrap_3x2.v
        #
        tb_soc_top.sv
        tb_soc_top.vlt
        #
        ${COCOTB_SHARE}/lib/verilator/verilator.cpp
    VERILATOR_ARGS
        -O3
        #--main
        --timescale-override 1ns/1ns
        #--x-assign fast
        #--x-initial fast
        #--noassert
        #--decorations none
        #-Wno-context
        #--runtime-debug
        --report-unoptflat
        #--Wall
        -CFLAGS "${CMAKE_CXX_FLAGS}"
        --timing
        --vpi
        --trace-fst

        #--json-only-output tree_temp.json
        #--json-only-meta-output meta_temp.json
        #--bbox-sys
        #--bbox-unsup
        #--prefix vljson

        #--waiver-multiline
        #--waiver-output mywaiver.vlt
        #--public-flat-rw
        -LDFLAGS "-Wl,-rpath,${COCOTB_LIB_DIR} -L${COCOTB_LIB_DIR} -lcocotbvpi_verilator -lgpi -lcocotb -lgpilog -lcocotbutils"
)
