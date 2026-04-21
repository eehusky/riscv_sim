cmake_minimum_required(VERSION 3.5)
project(tb_biriscv_idcache_top)

set(REPO_DIR                  ${CMAKE_CURRENT_SOURCE_DIR}/../../../)
set(BIRISCV                   ${REPO_DIR}/cores/biriscv)
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

    #--json-only-output tree_temp.json
    #--json-only-meta-output meta_temp.json
    #--bbox-sys
    #--bbox-unsup
    #--prefix vljson

)


add_executable(tb_biriscv_idcache_top
    ../common/elf_load.cpp
    sim_main.cpp
)

verilate(tb_biriscv_idcache_top
    PREFIX
        Vtb_biriscv_idcache_top
    OPT_GLOBAL
        ${CMAKE_CXX_FLAGS}
    OPT_SLOW
        ${CMAKE_CXX_FLAGS}
    OPT_FAST
        ${CMAKE_CXX_FLAGS}
    INCLUDE_DIRS
        ${BIRISCV}/src/core/
    TOP_MODULE
        tb_biriscv_idcache_top
    SOURCES
        ##
        ##BIRISCV I/D Cache Core
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
        ${BIRISCV}/src/dcache/dcache_axi_axi.v
        ${BIRISCV}/src/dcache/dcache_axi.v
        ${BIRISCV}/src/dcache/dcache_core_data_ram.v
        ${BIRISCV}/src/dcache/dcache_core_tag_ram.v
        ${BIRISCV}/src/dcache/dcache_core.v
        ${BIRISCV}/src/dcache/dcache_if_pmem.v
        ${BIRISCV}/src/dcache/dcache_mux.v
        ${BIRISCV}/src/dcache/dcache_pmem_mux.v
        ${BIRISCV}/src/dcache/dcache.v
        ${BIRISCV}/src/icache/icache_data_ram.v
        ${BIRISCV}/src/icache/icache_tag_ram.v
        ${BIRISCV}/src/icache/icache.v
        ${BIRISCV}/src/top/riscv_top.v
        biriscv_idcache_top.v
        ##
        ## AXI Crossbar
        ${VERILOG_AXI}/rtl/axi_crossbar.v
        ${VERILOG_AXI}/rtl/axi_crossbar_wr.v
        ${VERILOG_AXI}/rtl/axi_crossbar_rd.v
        ${VERILOG_AXI}/rtl/axi_crossbar_addr.v
        ${VERILOG_AXI}/rtl/axi_register_rd.v
        ${VERILOG_AXI}/rtl/axi_register_wr.v
        ${VERILOG_AXI}/rtl/arbiter.v
        ${VERILOG_AXI}/rtl/priority_encoder.v
        ${REPO_DIR}/rtl/axi_crossbar_wrap_3x2.v
        ##
        ## AXI2AXIL Adapter
        ${VERILOG_AXI}/rtl/axi_axil_adapter.v
        ${VERILOG_AXI}/rtl/axi_axil_adapter_wr.v
        ${VERILOG_AXI}/rtl/axi_axil_adapter_rd.v
        ##
        ## AXI RAM
        ${VERILOG_AXI}/rtl/axi_ram.v
        ##
        ## SOC Memory Network
        ${REPO_DIR}/rtl/soc_mem.vlt
        ${REPO_DIR}/rtl/soc_mem.sv
        ##
        ## Ringbuffer
        ${REPO_DIR}/rtl/ringbuffer/mm2s_fetch_if.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_regblock_if.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer_arbiter.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer_addr_pipelined.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer_addr_stage.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer_channel.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer_beatbox.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer_handshake.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer_gearbox.sv
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer.vlt
        ${REPO_DIR}/rtl/ringbuffer/mm2s_ringbuffer.sv
        ${REPO_DIR}/rtl/ringbuffer/s2mm_req_if.sv
        ${REPO_DIR}/rtl/ringbuffer/s2mm_regblock_if.sv
        ${REPO_DIR}/rtl/ringbuffer/s2mm_ringbuffer_arbiter.sv
        ${REPO_DIR}/rtl/ringbuffer/s2mm_ringbuffer_channel.sv
        ${REPO_DIR}/rtl/ringbuffer/s2mm_ringbuffer_collapse.sv
        ${REPO_DIR}/rtl/ringbuffer/s2mm_ringbuffer_addr.sv
        ${REPO_DIR}/rtl/ringbuffer/s2mm_ringbuffer_handshake.sv
        ${REPO_DIR}/rtl/ringbuffer/s2mm_ringbuffer.vlt
        ${REPO_DIR}/rtl/ringbuffer/s2mm_ringbuffer.sv
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_axis_if.sv
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_level.sv
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_fsm.sv
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_arbiter.v
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_priority_encoder.v
        ${REPO_DIR}/rtl/ringbuffer/sfifo.v
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_addrmap.sv
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_addrmap.vlt
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_addrmap_pkg.sv
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_addrmap_pkg.vlt
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_axil.sv
        ${REPO_DIR}/rtl/ringbuffer/ringbuffer_axil.vlt

        ##
        tb_biriscv_idcache_top.sv
        #
    VERILATOR_ARGS
        ${MY_VERILATOR_ARGS}
)


target_include_directories(tb_biriscv_idcache_top
    PUBLIC
        SystemC::systemc
        ${.}
        ../common/
)
