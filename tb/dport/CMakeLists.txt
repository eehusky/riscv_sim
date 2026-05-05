cmake_minimum_required(VERSION 3.5)
project(tb_dport)

set(REPO_DIR        ${CMAKE_CURRENT_SOURCE_DIR}/../../)
set(VERILOG_AXI     $ENV{HOME}/github/alexforencich/verilog-axi/)
set(IOBCACHE        ${REPO_DIR}/cores/iob_cache_axi_V0.7.1/)



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
        tb_dport
    SOURCES
        #${IOBCACHE}/hardware/src/iob_asym_converter.v
        #${IOBCACHE}/hardware/src/iob_cache_axi_csrs.v
        #${IOBCACHE}/hardware/src/iob_cache_axi.v
        #${IOBCACHE}/hardware/src/iob_cache_back_end_axi.v
        #${IOBCACHE}/hardware/src/iob_cache_control.v
        #${IOBCACHE}/hardware/src/iob_cache_front_end.v
        #${IOBCACHE}/hardware/src/iob_cache_gen_sp_ram.v
        #${IOBCACHE}/hardware/src/iob_cache_memory.v
        #${IOBCACHE}/hardware/src/iob_cache_onehot_to_bin.v
        #${IOBCACHE}/hardware/src/iob_cache_read_channel_axi.v
        #${IOBCACHE}/hardware/src/iob_cache_replacement_policy.v
        #${IOBCACHE}/hardware/src/iob_cache_write_channel_axi.v
        #${IOBCACHE}/hardware/src/iob_counter.v
        #${IOBCACHE}/hardware/src/iob_ctls.v
        #${IOBCACHE}/hardware/src/iob_fifo_sync.v
        #${IOBCACHE}/hardware/src/iob_prio_enc.v
        #${IOBCACHE}/hardware/src/iob_ram_sp.v
        #${IOBCACHE}/hardware/src/iob_ram_t2p.v
        #${IOBCACHE}/hardware/src/iob_regarray_sp.v
        #${IOBCACHE}/hardware/src/iob_reg_cae.v
        #${IOBCACHE}/hardware/src/iob_reg_care.v
        #${IOBCACHE}/hardware/src/iob_reg_car.v
        #${IOBCACHE}/hardware/src/iob_reg_ca.v
        #${IOBCACHE}/hardware/src/iob_reverse.v
        #${IOBCACHE}/hardware/src/iob_universal_converter_iob_iob.v
        #
        ${VERILOG_AXI}/rtl/axi_dp_ram.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_rd_if.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_if.v
        ${VERILOG_AXI}/rtl/axi_ram_rd_if.v
        #
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_sfifo.v
        tb_dport.vlt
        mem2iob_glue.sv
        mem2axi_glue.sv
        mem2axil_glue.sv
        addrdecode.sv
        mem_dport_mux.sv
        mem_dport_axi.sv
        mem_dummy.sv
        dtcm.sv
        tb_dport.sv
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
        #-Wno-WIDTHTRUNC
        #--runtime-debug
        --report-unoptflat
        #--Wall
        -CFLAGS "${CMAKE_CXX_FLAGS}"
        --timing
        --vpi
        --trace-fst
        +incdir+${IOBCACHE}/hardware/src/

        #--json-only-output tree_temp.json
        #--json-only-meta-output meta_temp.json
        #--bbox-sys
        #--bbox-unsup
        #--prefix vljson

        #--waiver-multiline
        #--waiver-output mywaiver.vlt
        --public-flat-rw
        -LDFLAGS "-Wl,-rpath,${COCOTB_LIB_DIR} -L${COCOTB_LIB_DIR} -lcocotbvpi_verilator -lgpi "
)
