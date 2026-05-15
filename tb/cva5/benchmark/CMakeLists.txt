cmake_minimum_required(VERSION 3.5)
project(tb_cva5_benchmark)

set(REPO_DIR     ${CMAKE_CURRENT_SOURCE_DIR}/../../../)
set(CVA5         ${REPO_DIR}/cores/cva5)
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
set(CXX_WARNING                     "-Wall -Wno-unused-but-set-variable -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation -Wno-uninitialized")
set(CMAKE_CXX_FLAGS                 "${PGO_FLAGS} -O3 -flto -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS                   "${PGO_FLAGS} -O3 -flto -fstrict-aliasing -march=native ${CXX_WARNING}")
set(LD_FLAGS                        "${PGO_FLAGS} -fwhole-program")

set(CMAKE_CXX_FLAGS                 "${PGO_FLAGS} -Og -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS                   "${PGO_FLAGS} -Og -fstrict-aliasing -march=native ${CXX_WARNING}")
set(LD_FLAGS                        "${PGO_FLAGS}")

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
    -Wno-BLKANDNBLK
    -Wno-SYMRSVDWORD
    -Wno-MULTIDRIVEN
    --report-unoptflat
    #--expand-limit 100000
    --trace-fst
    #--unroll-count 512
    -CFLAGS "${CMAKE_CXX_FLAGS}"
    -LDFLAGS "-lelf -lbfd ${LD_FLAGS}"

    #--json-only-output tree_temp.json
    #--json-only-meta-output meta_temp.json
    #--bbox-sys
    #--bbox-unsup
    #--prefix vljson
)


#file(GLOB SOURCE_FILES ${CV32E40P}/rtl/*.sv)

add_executable(tb_cva5
    ${REPO_DIR}/tb/common/elf_load.cpp
    sim_main.cpp
)

verilate(tb_cva5
    PREFIX
        Vtb_cva5
    TOP_MODULE
        tb_cva5
    OPT_GLOBAL
        ${CMAKE_CXX_FLAGS}
    OPT_SLOW
        ${CMAKE_CXX_FLAGS}
    OPT_FAST
        ${CMAKE_CXX_FLAGS}
    INCLUDE_DIRS

    SOURCES
        ## CVA5
        ${CVA5}/core/types_and_interfaces/cva5_config.sv
        ${CVA5}/core/types_and_interfaces/riscv_types.sv
        ${CVA5}/core/types_and_interfaces/csr_types.sv
        ${CVA5}/core/types_and_interfaces/cva5_types.sv
        ${CVA5}/core/types_and_interfaces/fpu_types.sv
        ${CVA5}/core/types_and_interfaces/opcodes.sv
        ${CVA5}/core/types_and_interfaces/internal_interfaces.sv
        ${CVA5}/core/types_and_interfaces/external_interfaces.sv
        ${CVA5}/core/common_components/ram/lutram_1w_1r.sv
        ${CVA5}/core/common_components/ram/lutram_1w_mr.sv
        ${CVA5}/core/common_components/ram/sdp_ram.sv
        ${CVA5}/core/common_components/ram/sdp_ram_padded.sv
        ${CVA5}/core/common_components/ram/tdp_ram.sv
        ${CVA5}/core/common_components/set_clr_reg_with_rst.sv
        ${CVA5}/core/common_components/one_hot_to_integer.sv
        ${CVA5}/core/common_components/cycler.sv
        ${CVA5}/core/common_components/lfsr.sv
        ${CVA5}/core/common_components/cva5_fifo.sv
        ${CVA5}/core/common_components/priority_encoder.sv
        ${CVA5}/core/common_components/round_robin.sv
        ${CVA5}/core/common_components/toggle_memory.sv
        ${CVA5}/core/common_components/toggle_memory_set.sv
        ${CVA5}/core/execution_units/csr_unit.sv
        ${CVA5}/core/execution_units/gc_unit.sv
        ${CVA5}/core/execution_units/branch_comparator.sv
        ${CVA5}/core/execution_units/branch_unit.sv
        ${CVA5}/core/execution_units/barrel_shifter.sv
        ${CVA5}/core/execution_units/alu_unit.sv
        ${CVA5}/core/memory_sub_units/local_mem_sub_unit.sv
        ${CVA5}/core/memory_sub_units/axi_master.sv
        ${CVA5}/core/memory_sub_units/avalon_master.sv
        ${CVA5}/core/memory_sub_units/wishbone_master.sv
        ${CVA5}/core/execution_units/load_store_unit/amo_alu.sv
        ${CVA5}/core/execution_units/load_store_unit/amo_unit.sv
        ${CVA5}/core/execution_units/load_store_unit/dcache_inv.sv
        ${CVA5}/core/execution_units/load_store_unit/dcache_noinv.sv
        ${CVA5}/core/execution_units/load_store_unit/addr_hash.sv
        ${CVA5}/core/execution_units/load_store_unit/store_queue.sv
        ${CVA5}/core/execution_units/load_store_unit/load_store_queue.sv
        ${CVA5}/core/execution_units/load_store_unit/load_store_unit.sv
        ${CVA5}/core/execution_units/mul_unit.sv
        ${CVA5}/core/execution_units/custom_unit.sv
        ${CVA5}/core/common_components/clz.sv
        ${CVA5}/core/execution_units/div_core.sv
        ${CVA5}/core/execution_units/div_unit.sv
        ${CVA5}/core/execution_units/fp_unit/fp_roundup.sv
        ${CVA5}/core/execution_units/fp_unit/fp_special_case_detection.sv
        ${CVA5}/core/execution_units/fp_unit/fp_rs_preprocess.sv
        ${CVA5}/core/execution_units/fp_unit/fp_preprocessing.sv
        ${CVA5}/core/execution_units/fp_unit/fp_sticky_tracking.sv
        ${CVA5}/core/execution_units/fp_unit/fp_add.sv
        ${CVA5}/core/execution_units/fp_unit/fp_mul.sv
        ${CVA5}/core/execution_units/fp_unit/fp_madd_wrapper.sv
        ${CVA5}/core/execution_units/fp_unit/divider/q_lookup.sv
        ${CVA5}/core/execution_units/fp_unit/divider/on_the_fly.sv
        ${CVA5}/core/execution_units/fp_unit/divider/carry_save_shift.sv
        ${CVA5}/core/execution_units/fp_unit/divider/fp_div_core.sv
        ${CVA5}/core/execution_units/fp_unit/fp_div.sv
        ${CVA5}/core/execution_units/fp_unit/fp_sqrt_core.sv
        ${CVA5}/core/execution_units/fp_unit/fp_sqrt.sv
        ${CVA5}/core/execution_units/fp_unit/fp_div_sqrt_wrapper.sv
        ${CVA5}/core/execution_units/fp_unit/fp_wb2int_misc.sv
        ${CVA5}/core/execution_units/fp_unit/fp_wb2fp_misc.sv
        ${CVA5}/core/execution_units/fp_unit/fp_prenormalize.sv
        ${CVA5}/core/execution_units/fp_unit/fp_normalize_rounding_top.sv
        ${CVA5}/core/execution_units/fp_unit/fpu_top.sv
        ${CVA5}/core/fetch_stage/ras.sv
        ${CVA5}/core/fetch_stage/branch_predictor.sv
        ${CVA5}/core/fetch_stage/icache_tag_banks.sv
        ${CVA5}/core/fetch_stage/icache.sv
        ${CVA5}/core/fetch_stage/fetch.sv
        ${CVA5}/core/instruction_metadata_and_id_management.sv
        ${CVA5}/core/mmu/perms_check.sv
        ${CVA5}/core/mmu/itlb.sv
        ${CVA5}/core/mmu/dtlb.sv
        ${CVA5}/core/mmu/mmu.sv
        ${CVA5}/core/decode_and_issue.sv
        ${CVA5}/core/register_free_list.sv
        ${CVA5}/core/renamer.sv
        ${CVA5}/core/register_file.sv
        ${CVA5}/core/fp_writeback.sv
        ${CVA5}/core/writeback.sv
        ${CVA5}/core/core_arbiter.sv
        ${CVA5}/apu/busses/multicore_arbiter.sv
        ${CVA5}/apu/busses/axi_adapter.sv
        ${CVA5}/apu/busses/wishbone_adapter.sv
        ${CVA5}/apu/clint/clint.sv
        ${CVA5}/apu/clint/clint_wrapper.sv
        ${CVA5}/apu/plic/plic_gateway.sv
        ${CVA5}/apu/plic/plic_cmptree.sv
        ${CVA5}/apu/plic/plic.sv
        ${CVA5}/apu/plic/plic_wrapper.sv
        ${CVA5}/core/cva5.sv

        ## DPORT
        ${WB2AXIP}/rtl/sfifo.v
        ${REPO_DIR}/rtl/dport/dport_pkg.sv
        ${REPO_DIR}/rtl/dport/dport2iob.sv
        ${REPO_DIR}/rtl/dport/dport2axi.sv
        ${REPO_DIR}/rtl/dport/dport2axil.sv
        ${REPO_DIR}/rtl/dport/dport_addrdecode.sv
        ${REPO_DIR}/rtl/dport/dport_mux.sv
        ${REPO_DIR}/rtl/dport/dport_ram.sv
        ${REPO_DIR}/rtl/dport/dport_dummy.sv
        ${REPO_DIR}/rtl/dport/obi_if.sv
        ${REPO_DIR}/rtl/dport/axi_if.sv
        ${REPO_DIR}/rtl/dport/axil_if.sv
        ${REPO_DIR}/rtl/dport/dport_rsp_queue.sv
        ${REPO_DIR}/rtl/dport/dport_dtcm.sv
        #
        ${REPO_DIR}/rtl/dport/mtime32.sv
        ${REPO_DIR}/rtl/dport/sim_ctrl.sv
        #${VERILOG_AXI}/rtl/axi_dp_ram.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_rd_if.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_if.v
        ${VERILOG_AXI}/rtl/axi_ram_rd_if.v
        #${VERILOG_AXI}/rtl/axil_ram.v
        #${VERILOG_AXI}/rtl/axi_ram.v

        tb_cva5.sv
        tb_cva5.vlt
        #
    VERILATOR_ARGS
        ${MY_VERILATOR_ARGS}
)


target_include_directories(tb_cva5
    PUBLIC
        ${.}
        ${REPO_DIR}/tb/common/
)
