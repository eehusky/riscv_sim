cmake_minimum_required(VERSION 3.5)
project(tb_top_demo)

set(REPO_DIR     ${CMAKE_CURRENT_SOURCE_DIR}/../../../)
set(CV32E40P     ${REPO_DIR}/cores/cv32e40p)
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



set(CMAKE_CXX_STANDARD              ${SystemC_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED     ${SystemC_CXX_STANDARD_REQUIRED})
set(CMAKE_EXPORT_COMPILE_COMMANDS   "ON")
set(CXX_WARNING                     "-Wall -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation -Wno-uninitialized")
set(CMAKE_CXX_FLAGS                 "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS                   "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")
#set(LD_FLAGS                        "")
#-O3 -flto
#-O3 -flto
#set(LD_FLAGS                        "-fwhole-program")

string(STRIP ${CMAKE_CXX_FLAGS} CMAKE_CXX_FLAGS)
string(STRIP ${CMAKE_C_FLAGS}   CMAKE_C_FLAGS)
#string(STRIP ${LD_FLAGS}        LD_FLAGS)
#set(CMAKE_MODULE_LINKER_FLAGS   ${LD_FLAGS})
#set(CMAKE_SHARED_LINKER_FLAGS   ${LD_FLAGS})
#set(CMAKE_STATIC_LINKER_FLAGS   ${LD_FLAGS})
#set(CMAKE_EXE_LINKER_FLAGS      ${LD_FLAGS})

set(MY_VERILATOR_ARGS
    -O3
    --timescale-override 1ns/1ns
    --x-assign fast
    --x-initial fast
    #--noassert
    --decorations none
    -Wno-context
    -Wno-WIDTHEXPAND
    -Wno-WIDTHTRUNC
    -Wno-CASEINCOMPLETE
    -Wno-UNOPTFLAT
    -Wno-COMBDLY

    -Wno-ASCRANGE
    -Wno-WIDTHCONCAT
    -Wno-UNSIGNED
    --report-unoptflat
    #--expand-limit 100000
    --trace-fst
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


#file(GLOB SOURCE_FILES ${CV32E40P}/rtl/*.sv)

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
        #${CV32E40P}/rtl/include
        #${CV32E40P}/bhv/include
        #${CV32E40P}/sva/
        #${CV32E40P}/bhv/
        #${CV32E40P}/bhv/include
        #${CV32E40P}/rtl/vendor/pulp_platform_common_cells/src/
        ${BIRISCV}/src/core/
        ${CV32E40P}/rtl/vendor/pulp_platform_common_cells/include/ # Needed for FPU
    SOURCES
        ${CV32E40P}/rtl/include/cv32e40p_pkg.sv
        ${CV32E40P}/rtl/include/cv32e40p_fpu_pkg.sv
        ${CV32E40P}/rtl/include/cv32e40p_apu_core_pkg.sv
        #
        ${CV32E40P}/bhv/cv32e40p_sim_clock_gate.sv
        #
        ##${CV32E40P}/bhv/include/cv32e40p_tracer_pkg.sv
        ##${CV32E40P}/bhv/include/cv32e40p_rvfi_pkg.sv
        ##${CV32E40P}/bhv/cv32e40p_tb_wrapper.sv
        #${CV32E40P}/bhv/cv32e40p_apu_tracer.sv
        ##${CV32E40P}/bhv/cv32e40p_core_log.sv
        #${CV32E40P}/bhv/cv32e40p_instr_trace.svh
        #${CV32E40P}/bhv/cv32e40p_rvfi.sv
        #${CV32E40P}/bhv/cv32e40p_rvfi_trace.sv
        #${CV32E40P}/bhv/cv32e40p_sim_clock_gate.sv
        #${CV32E40P}/bhv/cv32e40p_tb_wrapper.sv
        #${CV32E40P}/bhv/cv32e40p_tracer.sv
        #${CV32E40P}/bhv/insn_trace.sv
        #${CV32E40P}/bhv/pipe_freeze_trace.sv
        #${CV32E40P}/sva/cv32e40p_prefetch_controller_sva.sv
        #
        ${CV32E40P}/rtl/cv32e40p_fp_wrapper.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_cast_multi.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_classifier.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_divsqrt_multi.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_divsqrt_th_32.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_fma_multi.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_fma.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_noncomp.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_opgroup_block.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_opgroup_fmt_slice.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_opgroup_multifmt_slice.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_pkg.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_rounding.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/src/fpnew_top.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/clk/rtl/gated_clk_cell.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ctrl.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ff1.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_pack_single.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_prepare.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_round_single.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_special.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_srt_single.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_top.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_dp.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_frbus.v
        ${CV32E40P}/rtl/vendor/pulp_platform_fpnew/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_src_type.v
        #
        ${CV32E40P}/rtl/vendor/pulp_platform_common_cells/src/cf_math_pkg.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_common_cells/src/lzc.sv
        ${CV32E40P}/rtl/vendor/pulp_platform_common_cells/src/rr_arb_tree.sv
        #
        ${CV32E40P}/rtl/cv32e40p_aligner.sv
        ${CV32E40P}/rtl/cv32e40p_alu_div.sv
        ${CV32E40P}/rtl/cv32e40p_alu.sv
        ${CV32E40P}/rtl/cv32e40p_apu_disp.sv
        ${CV32E40P}/rtl/cv32e40p_compressed_decoder.sv
        ${CV32E40P}/rtl/cv32e40p_controller.sv
        ${CV32E40P}/rtl/cv32e40p_core.sv
        ${CV32E40P}/rtl/cv32e40p_cs_registers.sv
        ${CV32E40P}/rtl/cv32e40p_decoder.sv
        ${CV32E40P}/rtl/cv32e40p_ex_stage.sv
        ${CV32E40P}/rtl/cv32e40p_ff_one.sv
        ${CV32E40P}/rtl/cv32e40p_fifo.sv
        ${CV32E40P}/rtl/cv32e40p_hwloop_regs.sv
        ${CV32E40P}/rtl/cv32e40p_id_stage.sv
        ${CV32E40P}/rtl/cv32e40p_if_stage.sv
        ${CV32E40P}/rtl/cv32e40p_int_controller.sv
        ${CV32E40P}/rtl/cv32e40p_load_store_unit.sv
        ${CV32E40P}/rtl/cv32e40p_mult.sv
        ${CV32E40P}/rtl/cv32e40p_obi_interface.sv
        ${CV32E40P}/rtl/cv32e40p_popcnt.sv
        ${CV32E40P}/rtl/cv32e40p_prefetch_buffer.sv
        ${CV32E40P}/rtl/cv32e40p_prefetch_controller.sv
        ${CV32E40P}/rtl/cv32e40p_register_file_ff.sv
        #${CV32E40P}/rtl/cv32e40p_register_file_latch.sv
        ${CV32E40P}/rtl/cv32e40p_sleep_unit.sv
        ${CV32E40P}/rtl/cv32e40p_top.sv
        #
        ${VERILOG_AXI}/rtl/axi_dp_ram.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_rd_if.v
        ${VERILOG_AXI}/rtl/axi_ram_wr_if.v
        ${VERILOG_AXI}/rtl/axi_ram_rd_if.v
        ${VERILOG_AXI}/rtl/axil_ram.v
        ${VERILOG_AXI}/rtl/axi_ram.v
        #
        ${VERILOG_UART}/rtl/uart.v
        ${VERILOG_UART}/rtl/uart_rx.v
        ${VERILOG_UART}/rtl/uart_tx.v
        #
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
        ## Ringbuffer
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s_fetch_if.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s_arbiter.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s_addr_pipelined.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s_addr_stage.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s_channel.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s_beatbox.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s_handshake.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s_gearbox.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s.vlt
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_mm2s.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_s2mm_req_if.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_s2mm_arbiter.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_s2mm_channel.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_s2mm_collapse.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_s2mm_addr.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_s2mm_handshake.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_s2mm.vlt
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_s2mm.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_csr_if.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_axis_if.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_level.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_fsm.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_arbiter.v
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_priority_encoder.v
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_sfifo.v
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_addrmap.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_addrmap.vlt
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_addrmap_pkg.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_addrmap_pkg.vlt
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_axil.sv
        ${REPO_DIR}/cores/ringbuffer/ringbuffer_axil.vlt
        #
        ${BIRISCV}/src/core/biriscv_trace_sim.v
        #
        ../cv32e40p_wrapper.sv
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
