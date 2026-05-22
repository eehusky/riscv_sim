cmake_minimum_required(VERSION 3.5)
project(tb_top_demo)
find_package(verilator NO_DEFAULT_PATH PATHS $ENV{VERILATOR_ROOT})

set(REPO_DIR     ${CMAKE_CURRENT_SOURCE_DIR}/../../../)
set(IBEX         ${REPO_DIR}/cores/ibex)
set(BIRISCV      ${REPO_DIR}/cores/biriscv)
set(VERILOG_AXI  ${REPO_DIR}/cores/verilog-axi/)
set(VERILOG_UART ${REPO_DIR}/cores/verilog-uart/)
set(WB2AXIP      ${REPO_DIR}/cores/wb2axip/)


set(PGO_FLAGS "")
if ("$ENV{PGO}" STREQUAL "GEN")
    execute_process(COMMAND echo "PROFILE GENERATION")
    set(PGO_FLAGS "-fprofile-generate")
endif()
if ("$ENV{PGO}" STREQUAL "USE")
    execute_process(COMMAND echo "PROFILE COMPILE")
    set(PGO_FLAGS "-fprofile-use -fprofile-correction")
endif()


set(CMAKE_CXX_STANDARD              "23")
set(CMAKE_CXX_STANDARD_REQUIRED     "23")
set(CMAKE_EXPORT_COMPILE_COMMANDS   "ON")
set(CXX_WARNING                     "-Wall -Wno-unused-but-set-variable -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation -Wno-uninitialized")
set(CMAKE_CXX_FLAGS                 "${PGO_FLAGS} -O3 -flto -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS                   "${PGO_FLAGS} -O3 -flto -fstrict-aliasing -march=native ${CXX_WARNING}")
set(LD_FLAGS                        "${PGO_FLAGS} -flto=auto -fwhole-program")

string(STRIP ${CMAKE_CXX_FLAGS} CMAKE_CXX_FLAGS)
string(STRIP ${CMAKE_C_FLAGS}   CMAKE_C_FLAGS)
#string(STRIP ${LD_FLAGS}        LD_FLAGS)

set(MY_VERILATOR_ARGS
    -O3
    --timescale-override 1ns/1ns
    --x-assign fast
    --x-initial fast
    #--noassert
    --decorations none
    #-Wno-context
    -Wno-WIDTHEXPAND
    -Wno-WIDTHTRUNC
    -Wno-CASEINCOMPLETE
    #-Wno-UNOPTFLAT
    #-Wno-COMBDLY
    #-Wno-ASCRANGE
    #-Wno-WIDTHCONCAT
    #-Wno-UNSIGNED
    #-Wno-BLKANDNBLK
    #-Wno-SYMRSVDWORD
    #-Wno-MULTIDRIVEN
    -Wno-UNOPTFLAT

    --report-unoptflat
    #--expand-limit 100000
    #--trace-fst
    --trace-structs
    --no-trace-params
    #--unroll-count 512
    -CFLAGS "${CMAKE_CXX_FLAGS}"
    -LDFLAGS "-lelf -lbfd ${LD_FLAGS}"

    #--json-only-output tree_temp.json
    #--json-only-meta-output meta_temp.json
    #--bbox-sys
    #--bbox-unsup
    #--prefix vljson
)


add_executable(tb_top
    ${REPO_DIR}/tb/common/elf_load.cpp
    sim_main.cpp
)

verilate(tb_top
    PREFIX
        Vtb_top
    TOP_MODULE
        tb_top
    OPT_GLOBAL
        ${CMAKE_CXX_FLAGS}
    OPT_SLOW
        ${CMAKE_CXX_FLAGS}
    OPT_FAST
        ${CMAKE_CXX_FLAGS}
    INCLUDE_DIRS
        ${IBEX}/vendor/lowrisc_ip/ip/prim/rtl
        ${IBEX}/vendor/lowrisc_ip/dv/sv/dv_utils

    SOURCES
        ## IBEX
        ${IBEX}/vendor/lowrisc_ip/ip/prim/rtl/prim_util_pkg.sv
        ${IBEX}/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi_pkg.sv
        ${IBEX}/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_pkg.sv
        ${IBEX}/vendor/lowrisc_ip/ip/prim/rtl/prim_cipher_pkg.sv
        ${IBEX}/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_ram_1p_pkg.sv
        ${IBEX}/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_ram_1p.sv
        ${IBEX}/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_clock_gating.sv
        ${IBEX}/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_buf.sv

        ${IBEX}/rtl/ibex_pkg.sv
        ${IBEX}/rtl/ibex_icache.sv
        ${IBEX}/rtl/ibex_alu.sv
        ${IBEX}/rtl/ibex_compressed_decoder.sv
        ${IBEX}/rtl/ibex_controller.sv
        ${IBEX}/rtl/ibex_counter.sv
        ${IBEX}/rtl/ibex_cs_registers.sv
        ${IBEX}/rtl/ibex_decoder.sv
        ${IBEX}/rtl/ibex_ex_block.sv
        ${IBEX}/rtl/ibex_id_stage.sv
        ${IBEX}/rtl/ibex_if_stage.sv
        ${IBEX}/rtl/ibex_load_store_unit.sv
        ${IBEX}/rtl/ibex_multdiv_slow.sv
        ${IBEX}/rtl/ibex_multdiv_fast.sv
        ${IBEX}/rtl/ibex_prefetch_buffer.sv
        ${IBEX}/rtl/ibex_fetch_fifo.sv
        ${IBEX}/rtl/ibex_register_file_ff.sv
        ${IBEX}/rtl/ibex_core.sv
        ${IBEX}/rtl/ibex_top.sv
        ${IBEX}/rtl/ibex_dummy_instr.sv
        ${IBEX}/rtl/ibex_csr.sv
        ${IBEX}/rtl/ibex_pmp.sv
        ${IBEX}/rtl/ibex_wb_stage.sv
        ${IBEX}/rtl/ibex_branch_predict.sv


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
        ${VERILOG_AXI}/rtl/axi_dp_ram.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_rd_if.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_if.v
        ${VERILOG_AXI}/rtl/axi_ram_rd_if.v
        ${VERILOG_AXI}/rtl/axil_ram.v
        ${VERILOG_AXI}/rtl/axi_ram.v
        #
        ../ibex_wrapper.sv
        tb_top.sv
        tb_top.vlt
        #
    VERILATOR_ARGS
        ${MY_VERILATOR_ARGS}
)


target_include_directories(tb_top
    PUBLIC
        ${.}
        ${REPO_DIR}/tb/common/
)
