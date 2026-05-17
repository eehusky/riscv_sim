module tb_cv32e40p (
    input logic i_clk,
    input logic i_rst
);

    logic        clk_i;
    logic        rst_i;
    logic        rst_ni;
    logic        pulp_clock_en_i;
    logic        scan_cg_en_i;
    logic [31:0] boot_addr_i;
    logic [31:0] mtvec_addr_i;
    logic [31:0] dm_halt_addr_i;
    logic [31:0] hart_id_i;
    logic [31:0] dm_exception_addr_i;
    logic        instr_req_o;
    logic        instr_gnt_i;
    logic        instr_rvalid_i;
    logic [31:0] instr_addr_o;
    logic [31:0] instr_rdata_i;
    logic        data_req_o;
    logic        data_gnt_i;
    logic        data_rvalid_i;
    logic        data_we_o;
    logic [ 3:0] data_be_o;
    logic [31:0] data_addr_o;
    logic [31:0] data_wdata_o;
    logic [31:0] data_rdata_i;
    logic [31:0] irq_i;
    logic        irq_ack_o;
    logic [ 4:0] irq_id_o;
    logic        debug_req_i;
    logic        debug_havereset_o;
    logic        debug_running_o;
    logic        debug_halted_o;
    logic        fetch_enable_i;
    logic        core_sleep_o;
    logic        irq_mei;
    logic        irq_msi;
    logic        irq_mti;
    logic        irq_mti_clear;
    logic        irq_msi_clear;
    logic        irq_mei_clear;

    initial begin
        pulp_clock_en_i     = 0;  // PULP clock enable (only used if COREV_CLUSTER = 1)
        scan_cg_en_i        = 1;  // Enable all clock gates for testing
        boot_addr_i         = 32'h8000_0000;
        mtvec_addr_i        = 32'h8000_1000;
        dm_halt_addr_i      = 32'h1A11_0800;
        hart_id_i           = 0;
        dm_exception_addr_i = 0;
        irq_i               = 0;
        debug_req_i         = 0;
        fetch_enable_i      = 1;  // make the core start fetching instruction immediately
    end

    assign clk_i         = i_clk;
    assign rst_ni        = ~i_rst;
    assign rst_i         = i_rst;
    assign irq_i[2:0]    = 3'b0;
    assign irq_i[3]      = irq_msi;
    assign irq_i[6:4]    = 3'b0;
    assign irq_i[7]      = irq_mti;
    assign irq_i[10:8]   = 3'b0;
    assign irq_i[11]     = irq_mei;
    assign irq_i[15:12]  = 3'b0;

    assign irq_mti_clear = irq_ack_o && irq_id_o == 3;
    assign irq_msi_clear = irq_ack_o && irq_id_o == 7;
    assign irq_mei_clear = irq_ack_o && irq_id_o == 11;

    parameter FPU = 1;
    parameter ZFINX = 0;
    parameter NUM_MHPMCOUNTERS = 29;

    cv32e40p_top #(
        .COREV_PULP      (0),  // PULP ISA Extension (incl. custom CSRs and hardware loop, excl. cv.elw)
        .COREV_CLUSTER   (0),  // PULP Cluster interface (incl. cv.elw)
        .FPU             (FPU),  // Floating Point Unit (interfaced via APU interface)
        .FPU_ADDMUL_LAT  (0),  // Floating-Point ADDition/MULtiplication computing lane pipeline registers number
        .FPU_OTHERS_LAT  (0),  // Floating-Point COMParison/CONVersion computing lanes pipeline registers number
        .ZFINX           (ZFINX),  // Float-in-General Purpose registers
        .NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS)
    ) i_cv32e40p_top (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .pulp_clock_en_i    (pulp_clock_en_i),
        .scan_cg_en_i       (scan_cg_en_i),
        .boot_addr_i        (boot_addr_i),
        .mtvec_addr_i       (mtvec_addr_i),
        .dm_halt_addr_i     (dm_halt_addr_i),
        .hart_id_i          (hart_id_i),
        .dm_exception_addr_i(dm_exception_addr_i),
        .instr_req_o        (instr_req_o),
        .instr_gnt_i        (instr_gnt_i),
        .instr_rvalid_i     (instr_rvalid_i),
        .instr_addr_o       (instr_addr_o),
        .instr_rdata_i      (instr_rdata_i),
        .data_req_o         (data_req_o),
        .data_gnt_i         (data_gnt_i),
        .data_rvalid_i      (data_rvalid_i),
        .data_we_o          (data_we_o),
        .data_be_o          (data_be_o),
        .data_addr_o        (data_addr_o),
        .data_wdata_o       (data_wdata_o),
        .data_rdata_i       (data_rdata_i),
        .irq_i              (irq_i),
        .irq_ack_o          (irq_ack_o),
        .irq_id_o           (irq_id_o),
        .debug_req_i        (debug_req_i),
        .debug_havereset_o  (debug_havereset_o),
        .debug_running_o    (debug_running_o),
        .debug_halted_o     (debug_halted_o),
        .fetch_enable_i     (fetch_enable_i),
        .core_sleep_o       (core_sleep_o)
    );

`define TRACEME
`ifdef TRACEME
    logic [1:0][31:0] hwlp_start_q;
    logic [1:0][31:0] hwlp_end_q;
    logic [1:0][31:0] hwlp_counter_q;
    logic [1:0][31:0] hwlp_counter_n;
      assign hwlp_start_q   = '0;
      assign hwlp_end_q     = '0;
      assign hwlp_counter_q = '0;
      assign hwlp_counter_n = '0;
    //

    logic       [ 0:0]       rvfi_valid;
    logic       [63:0]       rvfi_order;
    integer                  rvfi_start_cycle;
    time                     rvfi_start_time;
    integer                  rvfi_stop_cycle;
    time                     rvfi_stop_time;
    logic       [31:0]       rvfi_insn;
    cv32e40p_rvfi_pkg::rvfi_trap_t              rvfi_trap;
    logic       [ 0:0]       rvfi_halt;
    cv32e40p_rvfi_pkg::rvfi_intr_t              rvfi_intr;
    logic       [ 1:0]       rvfi_mode;
    logic       [ 1:0]       rvfi_ixl;
    logic       [ 1:0]       rvfi_nmip;
    logic       [ 2:0]       rvfi_dbg;
    logic       [ 0:0]       rvfi_dbg_mode;
    cv32e40p_rvfi_pkg::rvfi_wu_t                rvfi_wu;
    logic       [ 0:0]       rvfi_sleep;
    logic       [ 4:0]       rvfi_rd_addr                 [1:0];
    logic       [31:0]       rvfi_rd_wdata                [1:0];
    logic                    rvfi_frd_wvalid              [1:0];
    logic       [ 4:0]       rvfi_frd_addr                [1:0];
    logic       [31:0]       rvfi_frd_wdata               [1:0];
    logic                    rvfi_2_rd;
    logic       [ 4:0]       rvfi_rs1_addr;
    logic       [ 4:0]       rvfi_rs2_addr;
    logic       [ 4:0]       rvfi_rs3_addr;
    logic       [31:0]       rvfi_rs1_rdata;
    logic       [31:0]       rvfi_rs2_rdata;
    logic       [31:0]       rvfi_rs3_rdata;
    logic       [ 4:0]       rvfi_frs1_addr;
    logic       [ 4:0]       rvfi_frs2_addr;
    logic       [ 4:0]       rvfi_frs3_addr;
    logic                    rvfi_frs1_rvalid;
    logic                    rvfi_frs2_rvalid;
    logic                    rvfi_frs3_rvalid;
    logic       [31:0]       rvfi_frs1_rdata;
    logic       [31:0]       rvfi_frs2_rdata;
    logic       [31:0]       rvfi_frs3_rdata;
    logic       [31:0]       rvfi_pc_rdata;
    logic       [31:0]       rvfi_pc_wdata;
    logic       [31:0]       rvfi_mem_addr;
    logic       [31:0]       rvfi_mem_rmask;
    logic       [31:0]       rvfi_mem_wmask;
    logic       [31:0]       rvfi_mem_rdata;
    logic       [31:0]       rvfi_mem_wdata;
    logic       [31:0]       rvfi_csr_fflags_rmask;
    logic       [31:0]       rvfi_csr_fflags_wmask;
    logic       [31:0]       rvfi_csr_fflags_rdata;
    logic       [31:0]       rvfi_csr_fflags_wdata;
    logic       [31:0]       rvfi_csr_frm_rmask;
    logic       [31:0]       rvfi_csr_frm_wmask;
    logic       [31:0]       rvfi_csr_frm_rdata;
    logic       [31:0]       rvfi_csr_frm_wdata;
    logic       [31:0]       rvfi_csr_fcsr_rmask;
    logic       [31:0]       rvfi_csr_fcsr_wmask;
    logic       [31:0]       rvfi_csr_fcsr_rdata;
    logic       [31:0]       rvfi_csr_fcsr_wdata;
    logic       [31:0]       rvfi_csr_jvt_rmask;
    logic       [31:0]       rvfi_csr_jvt_wmask;
    logic       [31:0]       rvfi_csr_jvt_rdata;
    logic       [31:0]       rvfi_csr_jvt_wdata;
    logic       [31:0]       rvfi_csr_mstatus_rmask;
    logic       [31:0]       rvfi_csr_mstatus_wmask;
    logic       [31:0]       rvfi_csr_mstatus_rdata;
    logic       [31:0]       rvfi_csr_mstatus_wdata;
    logic       [31:0]       rvfi_csr_mstatush_rmask;
    logic       [31:0]       rvfi_csr_mstatush_wmask;
    logic       [31:0]       rvfi_csr_mstatush_rdata;
    logic       [31:0]       rvfi_csr_mstatush_wdata;
    logic       [31:0]       rvfi_csr_misa_rmask;
    logic       [31:0]       rvfi_csr_misa_wmask;
    logic       [31:0]       rvfi_csr_misa_rdata;
    logic       [31:0]       rvfi_csr_misa_wdata;
    logic       [31:0]       rvfi_csr_mie_rmask;
    logic       [31:0]       rvfi_csr_mie_wmask;
    logic       [31:0]       rvfi_csr_mie_rdata;
    logic       [31:0]       rvfi_csr_mie_wdata;
    logic       [31:0]       rvfi_csr_mtvec_rmask;
    logic       [31:0]       rvfi_csr_mtvec_wmask;
    logic       [31:0]       rvfi_csr_mtvec_rdata;
    logic       [31:0]       rvfi_csr_mtvec_wdata;
    logic       [31:0]       rvfi_csr_mtvt_rmask;
    logic       [31:0]       rvfi_csr_mtvt_wmask;
    logic       [31:0]       rvfi_csr_mtvt_rdata;
    logic       [31:0]       rvfi_csr_mtvt_wdata;
    logic       [31:0]       rvfi_csr_mcountinhibit_rmask;
    logic       [31:0]       rvfi_csr_mcountinhibit_wmask;
    logic       [31:0]       rvfi_csr_mcountinhibit_rdata;
    logic       [31:0]       rvfi_csr_mcountinhibit_wdata;
    logic       [31:0][31:0] rvfi_csr_mhpmevent_rmask;
    logic       [31:0][31:0] rvfi_csr_mhpmevent_wmask;
    logic       [31:0][31:0] rvfi_csr_mhpmevent_rdata;
    logic       [31:0][31:0] rvfi_csr_mhpmevent_wdata;
    logic       [31:0]       rvfi_csr_mscratch_rmask;
    logic       [31:0]       rvfi_csr_mscratch_wmask;
    logic       [31:0]       rvfi_csr_mscratch_rdata;
    logic       [31:0]       rvfi_csr_mscratch_wdata;
    logic       [31:0]       rvfi_csr_mepc_rmask;
    logic       [31:0]       rvfi_csr_mepc_wmask;
    logic       [31:0]       rvfi_csr_mepc_rdata;
    logic       [31:0]       rvfi_csr_mepc_wdata;
    logic       [31:0]       rvfi_csr_mcause_rmask;
    logic       [31:0]       rvfi_csr_mcause_wmask;
    logic       [31:0]       rvfi_csr_mcause_rdata;
    logic       [31:0]       rvfi_csr_mcause_wdata;
    logic       [31:0]       rvfi_csr_mtval_rmask;
    logic       [31:0]       rvfi_csr_mtval_wmask;
    logic       [31:0]       rvfi_csr_mtval_rdata;
    logic       [31:0]       rvfi_csr_mtval_wdata;
    logic       [31:0]       rvfi_csr_mip_rmask;
    logic       [31:0]       rvfi_csr_mip_wmask;
    logic       [31:0]       rvfi_csr_mip_rdata;
    logic       [31:0]       rvfi_csr_mip_wdata;
    logic       [31:0]       rvfi_csr_mnxti_rmask;
    logic       [31:0]       rvfi_csr_mnxti_wmask;
    logic       [31:0]       rvfi_csr_mnxti_rdata;
    logic       [31:0]       rvfi_csr_mnxti_wdata;
    logic       [31:0]       rvfi_csr_mintstatus_rmask;
    logic       [31:0]       rvfi_csr_mintstatus_wmask;
    logic       [31:0]       rvfi_csr_mintstatus_rdata;
    logic       [31:0]       rvfi_csr_mintstatus_wdata;
    logic       [31:0]       rvfi_csr_mintthresh_rmask;
    logic       [31:0]       rvfi_csr_mintthresh_wmask;
    logic       [31:0]       rvfi_csr_mintthresh_rdata;
    logic       [31:0]       rvfi_csr_mintthresh_wdata;
    logic       [31:0]       rvfi_csr_mscratchcsw_rmask;
    logic       [31:0]       rvfi_csr_mscratchcsw_wmask;
    logic       [31:0]       rvfi_csr_mscratchcsw_rdata;
    logic       [31:0]       rvfi_csr_mscratchcsw_wdata;
    logic       [31:0]       rvfi_csr_mscratchcswl_rmask;
    logic       [31:0]       rvfi_csr_mscratchcswl_wmask;
    logic       [31:0]       rvfi_csr_mscratchcswl_rdata;
    logic       [31:0]       rvfi_csr_mscratchcswl_wdata;
    logic       [31:0]       rvfi_csr_mclicbase_rmask;
    logic       [31:0]       rvfi_csr_mclicbase_wmask;
    logic       [31:0]       rvfi_csr_mclicbase_rdata;
    logic       [31:0]       rvfi_csr_mclicbase_wdata;
    logic       [31:0]       rvfi_csr_tselect_rmask;
    logic       [31:0]       rvfi_csr_tselect_wmask;
    logic       [31:0]       rvfi_csr_tselect_rdata;
    logic       [31:0]       rvfi_csr_tselect_wdata;
    logic       [ 3:0][31:0] rvfi_csr_tdata_rmask;
    logic       [ 3:0][31:0] rvfi_csr_tdata_wmask;
    logic       [ 3:0][31:0] rvfi_csr_tdata_rdata;
    logic       [ 3:0][31:0] rvfi_csr_tdata_wdata;
    logic       [31:0]       rvfi_csr_tinfo_rmask;
    logic       [31:0]       rvfi_csr_tinfo_wmask;
    logic       [31:0]       rvfi_csr_tinfo_rdata;
    logic       [31:0]       rvfi_csr_tinfo_wdata;
    logic       [31:0]       rvfi_csr_mcontext_rmask;
    logic       [31:0]       rvfi_csr_mcontext_wmask;
    logic       [31:0]       rvfi_csr_mcontext_rdata;
    logic       [31:0]       rvfi_csr_mcontext_wdata;
    logic       [31:0]       rvfi_csr_scontext_rmask;
    logic       [31:0]       rvfi_csr_scontext_wmask;
    logic       [31:0]       rvfi_csr_scontext_rdata;
    logic       [31:0]       rvfi_csr_scontext_wdata;
    logic       [31:0]       rvfi_csr_dcsr_rmask;
    logic       [31:0]       rvfi_csr_dcsr_wmask;
    logic       [31:0]       rvfi_csr_dcsr_rdata;
    logic       [31:0]       rvfi_csr_dcsr_wdata;
    logic       [31:0]       rvfi_csr_dpc_rmask;
    logic       [31:0]       rvfi_csr_dpc_wmask;
    logic       [31:0]       rvfi_csr_dpc_rdata;
    logic       [31:0]       rvfi_csr_dpc_wdata;
    logic       [ 1:0][31:0] rvfi_csr_dscratch_rmask;
    logic       [ 1:0][31:0] rvfi_csr_dscratch_wmask;
    logic       [ 1:0][31:0] rvfi_csr_dscratch_rdata;
    logic       [ 1:0][31:0] rvfi_csr_dscratch_wdata;
    logic       [31:0]       rvfi_csr_mcycle_rmask;
    logic       [31:0]       rvfi_csr_mcycle_wmask;
    logic       [31:0]       rvfi_csr_mcycle_rdata;
    logic       [31:0]       rvfi_csr_mcycle_wdata;
    logic       [31:0]       rvfi_csr_minstret_rmask;
    logic       [31:0]       rvfi_csr_minstret_wmask;
    logic       [31:0]       rvfi_csr_minstret_rdata;
    logic       [31:0]       rvfi_csr_minstret_wdata;
    logic       [31:0][31:0] rvfi_csr_mhpmcounter_rmask;
    logic       [31:0][31:0] rvfi_csr_mhpmcounter_wmask;
    logic       [31:0][31:0] rvfi_csr_mhpmcounter_rdata;
    logic       [31:0][31:0] rvfi_csr_mhpmcounter_wdata;
    logic       [31:0]       rvfi_csr_mcycleh_rmask;
    logic       [31:0]       rvfi_csr_mcycleh_wmask;
    logic       [31:0]       rvfi_csr_mcycleh_rdata;
    logic       [31:0]       rvfi_csr_mcycleh_wdata;
    logic       [31:0]       rvfi_csr_minstreth_rmask;
    logic       [31:0]       rvfi_csr_minstreth_wmask;
    logic       [31:0]       rvfi_csr_minstreth_rdata;
    logic       [31:0]       rvfi_csr_minstreth_wdata;
    logic       [31:0][31:0] rvfi_csr_mhpmcounterh_rmask;
    logic       [31:0][31:0] rvfi_csr_mhpmcounterh_wmask;
    logic       [31:0][31:0] rvfi_csr_mhpmcounterh_rdata;
    logic       [31:0][31:0] rvfi_csr_mhpmcounterh_wdata;
    logic       [31:0]       rvfi_csr_cycle_rmask;
    logic       [31:0]       rvfi_csr_cycle_wmask;
    logic       [31:0]       rvfi_csr_cycle_rdata;
    logic       [31:0]       rvfi_csr_cycle_wdata;
    logic       [31:0]       rvfi_csr_instret_rmask;
    logic       [31:0]       rvfi_csr_instret_wmask;
    logic       [31:0]       rvfi_csr_instret_rdata;
    logic       [31:0]       rvfi_csr_instret_wdata;
    logic       [31:0][31:0] rvfi_csr_hpmcounter_rmask;
    logic       [31:0][31:0] rvfi_csr_hpmcounter_wmask;
    logic       [31:0][31:0] rvfi_csr_hpmcounter_rdata;
    logic       [31:0][31:0] rvfi_csr_hpmcounter_wdata;
    logic       [31:0]       rvfi_csr_cycleh_rmask;
    logic       [31:0]       rvfi_csr_cycleh_wmask;
    logic       [31:0]       rvfi_csr_cycleh_rdata;
    logic       [31:0]       rvfi_csr_cycleh_wdata;
    logic       [31:0]       rvfi_csr_instreth_rmask;
    logic       [31:0]       rvfi_csr_instreth_wmask;
    logic       [31:0]       rvfi_csr_instreth_rdata;
    logic       [31:0]       rvfi_csr_instreth_wdata;
    logic       [31:0][31:0] rvfi_csr_hpmcounterh_rmask;
    logic       [31:0][31:0] rvfi_csr_hpmcounterh_wmask;
    logic       [31:0][31:0] rvfi_csr_hpmcounterh_rdata;
    logic       [31:0][31:0] rvfi_csr_hpmcounterh_wdata;
    logic       [31:0]       rvfi_csr_mvendorid_rmask;
    logic       [31:0]       rvfi_csr_mvendorid_wmask;
    logic       [31:0]       rvfi_csr_mvendorid_rdata;
    logic       [31:0]       rvfi_csr_mvendorid_wdata;
    logic       [31:0]       rvfi_csr_marchid_rmask;
    logic       [31:0]       rvfi_csr_marchid_wmask;
    logic       [31:0]       rvfi_csr_marchid_rdata;
    logic       [31:0]       rvfi_csr_marchid_wdata;
    logic       [31:0]       rvfi_csr_mimpid_rmask;
    logic       [31:0]       rvfi_csr_mimpid_wmask;
    logic       [31:0]       rvfi_csr_mimpid_rdata;
    logic       [31:0]       rvfi_csr_mimpid_wdata;
    logic       [31:0]       rvfi_csr_mhartid_rmask;
    logic       [31:0]       rvfi_csr_mhartid_wmask;
    logic       [31:0]       rvfi_csr_mhartid_rdata;
    logic       [31:0]       rvfi_csr_mhartid_wdata;
    logic       [31:0]       rvfi_csr_mcounteren_rmask;
    logic       [31:0]       rvfi_csr_mcounteren_wmask;
    logic       [31:0]       rvfi_csr_mcounteren_rdata;
    logic       [31:0]       rvfi_csr_mcounteren_wdata;
    logic       [ 3:0][31:0] rvfi_csr_pmpcfg_rmask;
    logic       [ 3:0][31:0] rvfi_csr_pmpcfg_wmask;
    logic       [ 3:0][31:0] rvfi_csr_pmpcfg_rdata;
    logic       [ 3:0][31:0] rvfi_csr_pmpcfg_wdata;
    logic       [15:0][31:0] rvfi_csr_pmpaddr_rmask;
    logic       [15:0][31:0] rvfi_csr_pmpaddr_wmask;
    logic       [15:0][31:0] rvfi_csr_pmpaddr_rdata;
    logic       [15:0][31:0] rvfi_csr_pmpaddr_wdata;
    logic       [31:0]       rvfi_csr_mseccfg_rmask;
    logic       [31:0]       rvfi_csr_mseccfg_wmask;
    logic       [31:0]       rvfi_csr_mseccfg_rdata;
    logic       [31:0]       rvfi_csr_mseccfg_wdata;
    logic       [31:0]       rvfi_csr_mseccfgh_rmask;
    logic       [31:0]       rvfi_csr_mseccfgh_wmask;
    logic       [31:0]       rvfi_csr_mseccfgh_rdata;
    logic       [31:0]       rvfi_csr_mseccfgh_wdata;
    logic       [31:0]       rvfi_csr_mconfigptr_rmask;
    logic       [31:0]       rvfi_csr_mconfigptr_wmask;
    logic       [31:0]       rvfi_csr_mconfigptr_rdata;
    logic       [31:0]       rvfi_csr_mconfigptr_wdata;
    logic       [31:0]       rvfi_csr_lpstart0_rmask;
    logic       [31:0]       rvfi_csr_lpstart0_wmask;
    logic       [31:0]       rvfi_csr_lpstart0_rdata;
    logic       [31:0]       rvfi_csr_lpstart0_wdata;
    logic       [31:0]       rvfi_csr_lpend0_rmask;
    logic       [31:0]       rvfi_csr_lpend0_wmask;
    logic       [31:0]       rvfi_csr_lpend0_rdata;
    logic       [31:0]       rvfi_csr_lpend0_wdata;
    logic       [31:0]       rvfi_csr_lpcount0_rmask;
    logic       [31:0]       rvfi_csr_lpcount0_wmask;
    logic       [31:0]       rvfi_csr_lpcount0_rdata;
    logic       [31:0]       rvfi_csr_lpcount0_wdata;
    logic       [31:0]       rvfi_csr_lpstart1_rmask;
    logic       [31:0]       rvfi_csr_lpstart1_wmask;
    logic       [31:0]       rvfi_csr_lpstart1_rdata;
    logic       [31:0]       rvfi_csr_lpstart1_wdata;
    logic       [31:0]       rvfi_csr_lpend1_rmask;
    logic       [31:0]       rvfi_csr_lpend1_wmask;
    logic       [31:0]       rvfi_csr_lpend1_rdata;
    logic       [31:0]       rvfi_csr_lpend1_wdata;
    logic       [31:0]       rvfi_csr_lpcount1_rmask;
    logic       [31:0]       rvfi_csr_lpcount1_wmask;
    logic       [31:0]       rvfi_csr_lpcount1_rdata;
    logic       [31:0]       rvfi_csr_lpcount1_wdata;

    cv32e40p_rvfi #(
        .FPU             (FPU),
        .ZFINX           (ZFINX),
        .NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS)
    ) rvfi_i (
        .clk_i (i_cv32e40p_top.core_i.clk_i),
        .rst_ni(i_cv32e40p_top.core_i.rst_ni),

        .is_decoding_i    (i_cv32e40p_top.core_i.id_stage_i.is_decoding_o),
        .is_illegal_i     (i_cv32e40p_top.core_i.id_stage_i.illegal_insn_dec),
        .trigger_match_i  (i_cv32e40p_top.core_i.id_stage_i.trigger_match_i),
        .data_misaligned_i(i_cv32e40p_top.core_i.data_misaligned),
        .lsu_data_we_ex_i (i_cv32e40p_top.core_i.data_we_ex),
        .debug_mode_i     (i_cv32e40p_top.core_i.debug_mode),
        .debug_cause_i    (i_cv32e40p_top.core_i.debug_cause),
        //// Instr IF probes ////
        .instr_req_i      (i_cv32e40p_top.core_i.instr_req_o),
        .instr_grant_i    (i_cv32e40p_top.core_i.instr_gnt_i),
        .instr_rvalid_i   (i_cv32e40p_top.core_i.instr_rvalid_i),
        .prefetch_req_i   (i_cv32e40p_top.core_i.instr_req_int),
        .pc_set_i         (i_cv32e40p_top.core_i.pc_set),

        .instr_valid_id_i    (i_cv32e40p_top.core_i.instr_valid_id),
        .instr_rdata_id_i    (i_cv32e40p_top.core_i.instr_rdata_id),
        .is_fetch_failed_id_i(i_cv32e40p_top.core_i.is_fetch_failed_id),
        .instr_req_int_i     (i_cv32e40p_top.core_i.instr_req_int),
        .clear_instr_valid_i (i_cv32e40p_top.core_i.clear_instr_valid),
        //// IF probes ////
        .instr_valid_if_i    (i_cv32e40p_top.core_i.if_stage_i.instr_valid),
        .if_valid_i          (i_cv32e40p_top.core_i.if_stage_i.if_valid),
        .if_ready_i          (i_cv32e40p_top.core_i.if_stage_i.if_ready),
        .instr_if_i          (i_cv32e40p_top.core_i.if_stage_i.instr_aligned),
        .pc_if_i             (i_cv32e40p_top.core_i.pc_if),
        //// ID probes ////
        .pc_id_i             (i_cv32e40p_top.core_i.id_stage_i.pc_id_i),
        .id_valid_i          (i_cv32e40p_top.core_i.id_stage_i.id_valid_o),
        .id_ready_i          (i_cv32e40p_top.core_i.id_stage_i.id_ready_o),

        .rs1_addr_id_i     (i_cv32e40p_top.core_i.id_stage_i.regfile_addr_ra_id),
        .rs2_addr_id_i     (i_cv32e40p_top.core_i.id_stage_i.regfile_addr_rb_id),
        .rs3_addr_id_i     (i_cv32e40p_top.core_i.id_stage_i.regfile_addr_rc_id),
        .operand_a_fw_id_i (i_cv32e40p_top.core_i.id_stage_i.operand_a_fw_id),
        .operand_b_fw_id_i (i_cv32e40p_top.core_i.id_stage_i.operand_b_fw_id),
        .operand_c_fw_id_i (i_cv32e40p_top.core_i.id_stage_i.operand_c_fw_id),
        // .instr         (i_cv32e40p_top.core_i.id_stage_i.instr     ),
        .is_compressed_id_i(i_cv32e40p_top.core_i.id_stage_i.is_compressed_i),
        .ebrk_insn_dec_i   (i_cv32e40p_top.core_i.id_stage_i.ebrk_insn_dec),
        .ecall_insn_dec_i  (i_cv32e40p_top.core_i.id_stage_i.ecall_insn_dec),
        .mret_insn_dec_i   (i_cv32e40p_top.core_i.id_stage_i.mret_insn_dec),
        .mret_dec_i        (i_cv32e40p_top.core_i.id_stage_i.mret_dec),

        .csr_cause_i     (i_cv32e40p_top.core_i.csr_cause),
        .debug_csr_save_i(i_cv32e40p_top.core_i.debug_csr_save),

        // HWLOOP regs
        .hwlp_start_q_i  (hwlp_start_q),
        .hwlp_end_q_i    (hwlp_end_q),
        .hwlp_counter_q_i(hwlp_counter_q),
        .hwlp_counter_n_i(hwlp_counter_n),

        .minstret_i         (i_cv32e40p_top.core_i.id_stage_i.minstret),
        //// EX probes ////
        .ex_valid_i         (i_cv32e40p_top.core_i.ex_valid),
        .ex_ready_i         (i_cv32e40p_top.core_i.ex_ready),
        .ex_reg_addr_i      (i_cv32e40p_top.core_i.regfile_alu_waddr_fw),
        .ex_reg_we_i        (i_cv32e40p_top.core_i.regfile_alu_we_fw),
        .ex_reg_wdata_i     (i_cv32e40p_top.core_i.regfile_alu_wdata_fw),
        .apu_en_ex_i        (i_cv32e40p_top.core_i.apu_en_ex),
        .apu_singlecycle_i  (i_cv32e40p_top.core_i.ex_stage_i.apu_singlecycle),
        .apu_multicycle_i   (i_cv32e40p_top.core_i.ex_stage_i.apu_multicycle),
        .wb_contention_lsu_i(i_cv32e40p_top.core_i.ex_stage_i.wb_contention_lsu),
        .wb_contention_i    (i_cv32e40p_top.core_i.ex_stage_i.wb_contention),
        .regfile_we_lsu_i   (i_cv32e40p_top.core_i.ex_stage_i.regfile_we_lsu),
        // .rf_we_alu_i    (i_cv32e40p_top.core_i.id_stage_i.regfile_alu_we_fw_i),
        // .rf_addr_alu_i  (i_cv32e40p_top.core_i.id_stage_i.regfile_alu_waddr_fw_i),
        // .rf_wdata_alu_i (i_cv32e40p_top.core_i.id_stage_i.regfile_alu_wdata_fw_i),

        .mult_ready_i        (i_cv32e40p_top.core_i.ex_stage_i.mult_ready),
        .alu_ready_i         (i_cv32e40p_top.core_i.ex_stage_i.alu_ready),
        //// WB probes ////
        .wb_valid_i          (i_cv32e40p_top.core_i.wb_valid),
        .wb_ready_i          (i_cv32e40p_top.core_i.lsu_ready_wb),
        //// LSU probes ////
        .data_we_ex_i        (i_cv32e40p_top.core_i.data_we_ex),
        .data_atop_ex_i      (i_cv32e40p_top.core_i.data_atop_ex),
        .data_type_ex_i      (i_cv32e40p_top.core_i.data_type_ex),
        .alu_operand_c_ex_i  (i_cv32e40p_top.core_i.alu_operand_c_ex),
        .data_reg_offset_ex_i(i_cv32e40p_top.core_i.data_reg_offset_ex),
        .data_load_event_ex_i(i_cv32e40p_top.core_i.data_load_event_ex),
        .data_sign_ext_ex_i  (i_cv32e40p_top.core_i.data_sign_ext_ex),
        .lsu_rdata_i         (i_cv32e40p_top.core_i.lsu_rdata),
        .data_req_ex_i       (i_cv32e40p_top.core_i.data_req_ex),
        .alu_operand_a_ex_i  (i_cv32e40p_top.core_i.alu_operand_a_ex),
        .alu_operand_b_ex_i  (i_cv32e40p_top.core_i.alu_operand_b_ex),
        .useincr_addr_ex_i   (i_cv32e40p_top.core_i.useincr_addr_ex),
        .data_misaligned_ex_i(i_cv32e40p_top.core_i.data_misaligned_ex),
        .p_elw_start_i       (i_cv32e40p_top.core_i.p_elw_start),
        .p_elw_finish_i      (i_cv32e40p_top.core_i.p_elw_finish),
        .lsu_ready_ex_i      (i_cv32e40p_top.core_i.lsu_ready_ex),
        .lsu_ready_wb_i      (i_cv32e40p_top.core_i.lsu_ready_wb),

        .lsu_data_be_i(i_cv32e40p_top.core_i.load_store_unit_i.data_be),

        .data_req_pmp_i     (i_cv32e40p_top.core_i.data_req_pmp),
        .data_gnt_pmp_i     (i_cv32e40p_top.core_i.data_gnt_pmp),
        .data_rvalid_i      (i_cv32e40p_top.core_i.data_rvalid_i),
        .data_err_pmp_i     (i_cv32e40p_top.core_i.data_err_pmp),
        .data_addr_pmp_i    (i_cv32e40p_top.core_i.data_addr_pmp),
        .data_we_i          (i_cv32e40p_top.core_i.data_we_o),
        .data_atop_i        (i_cv32e40p_top.core_i.data_atop_o),
        .data_be_i          (i_cv32e40p_top.core_i.data_be_o),
        .data_wdata_i       (i_cv32e40p_top.core_i.data_wdata_o),
        .data_rdata_i       (i_cv32e40p_top.core_i.data_rdata_i),
        // Register writes
        .rf_we_wb_i         (i_cv32e40p_top.core_i.id_stage_i.regfile_we_wb_i),
        .rf_addr_wb_i       (i_cv32e40p_top.core_i.id_stage_i.regfile_waddr_wb_i),
        .rf_wdata_wb_i      (i_cv32e40p_top.core_i.id_stage_i.regfile_wdata_wb_i),
        .regfile_alu_we_ex_i(i_cv32e40p_top.core_i.id_stage_i.regfile_alu_we_ex_o),

        // APU
        .apu_req_i   (i_cv32e40p_top.core_i.apu_req_o),
        .apu_gnt_i   (i_cv32e40p_top.core_i.apu_gnt_i),
        .apu_rvalid_i(i_cv32e40p_top.core_i.ex_stage_i.apu_valid),

        // Controller FSM probes
        .ctrl_fsm_cs_i(i_cv32e40p_top.core_i.id_stage_i.controller_i.ctrl_fsm_cs),
        .pc_mux_i     (i_cv32e40p_top.core_i.id_stage_i.controller_i.pc_mux_o),
        .exc_pc_mux_i (i_cv32e40p_top.core_i.id_stage_i.controller_i.exc_pc_mux_o),

        //CSR
        .csr_addr_i     (i_cv32e40p_top.core_i.cs_registers_i.csr_addr_i),
        .csr_we_i       (i_cv32e40p_top.core_i.cs_registers_i.csr_we_int),
        .csr_wdata_int_i(i_cv32e40p_top.core_i.cs_registers_i.csr_wdata_int),

        .csr_fregs_we_i(i_cv32e40p_top.core_i.cs_registers_i.fregs_we_i),

        .csr_mstatus_n_i   (i_cv32e40p_top.core_i.cs_registers_i.mstatus_n),
        .csr_mstatus_q_i   (i_cv32e40p_top.core_i.cs_registers_i.mstatus_q),
        .csr_mstatus_fs_n_i(i_cv32e40p_top.core_i.cs_registers_i.mstatus_fs_n),
        .csr_mstatus_fs_q_i(i_cv32e40p_top.core_i.cs_registers_i.mstatus_fs_q),

        .csr_misa_n_i(i_cv32e40p_top.core_i.cs_registers_i.MISA_VALUE),  // WARL
        .csr_misa_q_i(i_cv32e40p_top.core_i.cs_registers_i.MISA_VALUE),

        .csr_tdata1_n_i           (i_cv32e40p_top.core_i.cs_registers_i.tmatch_control_rdata),//csr_wdata_int                                   ),
        .csr_tdata1_q_i           (i_cv32e40p_top.core_i.cs_registers_i.tmatch_control_rdata),//gen_trigger_regs.tmatch_control_exec_q          ),
        .csr_tdata1_we_i(i_cv32e40p_top.core_i.cs_registers_i.gen_trigger_regs.tmatch_control_we),

        .csr_tdata2_n_i           (i_cv32e40p_top.core_i.cs_registers_i.tmatch_value_rdata),//csr_wdata_int                                   ),
        .csr_tdata2_q_i           (i_cv32e40p_top.core_i.cs_registers_i.tmatch_value_rdata),//gen_trigger_regs.tmatch_control_exec_q          ),
        .csr_tdata2_we_i(i_cv32e40p_top.core_i.cs_registers_i.gen_trigger_regs.tmatch_value_we),

        .csr_tinfo_n_i({16'h0, i_cv32e40p_top.core_i.cs_registers_i.tinfo_types}),
        .csr_tinfo_q_i({16'h0, i_cv32e40p_top.core_i.cs_registers_i.tinfo_types}),

        .csr_mie_n_i       (i_cv32e40p_top.core_i.cs_registers_i.mie_n),
        .csr_mie_q_i       (i_cv32e40p_top.core_i.cs_registers_i.mie_q),
        .csr_mie_we_i      (i_cv32e40p_top.core_i.cs_registers_i.csr_mie_we),
        .csr_mtvec_n_i     (i_cv32e40p_top.core_i.cs_registers_i.mtvec_n),
        .csr_mtvec_q_i     (i_cv32e40p_top.core_i.cs_registers_i.mtvec_q),
        .csr_mtvec_mode_n_i(i_cv32e40p_top.core_i.cs_registers_i.mtvec_mode_n),
        .csr_mtvec_mode_q_i(i_cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q),

        .csr_mcountinhibit_q_i (i_cv32e40p_top.core_i.cs_registers_i.mcountinhibit_q),
        .csr_mcountinhibit_n_i (i_cv32e40p_top.core_i.cs_registers_i.mcountinhibit_n),
        .csr_mcountinhibit_we_i(i_cv32e40p_top.core_i.cs_registers_i.mcountinhibit_we),

        .csr_mhpmevent_n_i(i_cv32e40p_top.core_i.cs_registers_i.mhpmevent_n),
        .csr_mhpmevent_q_i(i_cv32e40p_top.core_i.cs_registers_i.mhpmevent_q),
        .csr_mhpmevent_we_i(i_cv32e40p_top.core_i.cs_registers_i.mhpmevent_we),
        .csr_mscratch_q_i(i_cv32e40p_top.core_i.cs_registers_i.mscratch_q),
        .csr_mscratch_n_i(i_cv32e40p_top.core_i.cs_registers_i.mscratch_n),
        .csr_mepc_q_i(i_cv32e40p_top.core_i.cs_registers_i.mepc_q),
        .csr_mepc_n_i(i_cv32e40p_top.core_i.cs_registers_i.mepc_n),
        .csr_mcause_q_i(i_cv32e40p_top.core_i.cs_registers_i.mcause_q),
        .csr_mcause_n_i(i_cv32e40p_top.core_i.cs_registers_i.mcause_n),
        .csr_mip_n_i(i_cv32e40p_top.core_i.cs_registers_i.mip),
        .csr_mip_q_i(i_cv32e40p_top.core_i.cs_registers_i.mip),
        .csr_mip_we_i('0),  //(i_cv32e40p_top.core_i.cs_registers_i.mip)


        .csr_dcsr_q_i(i_cv32e40p_top.core_i.cs_registers_i.dcsr_q),
        .csr_dcsr_n_i(i_cv32e40p_top.core_i.cs_registers_i.dcsr_n),

        .csr_dpc_n_i(i_cv32e40p_top.core_i.cs_registers_i.depc_n),
        .csr_dpc_q_i(i_cv32e40p_top.core_i.cs_registers_i.depc_q),
        .csr_dpc_we_i('0),  //i_cv32e40p_top.core_i.cs_registers_i.),
        .csr_dscratch0_n_i(i_cv32e40p_top.core_i.cs_registers_i.dscratch0_n),
        .csr_dscratch0_q_i(i_cv32e40p_top.core_i.cs_registers_i.dscratch0_q),
        .csr_dscratch0_we_i('0),  //i_cv32e40p_top.core_i.cs_registers_i.),

        .csr_dscratch1_n_i(i_cv32e40p_top.core_i.cs_registers_i.dscratch1_n),
        .csr_dscratch1_q_i(i_cv32e40p_top.core_i.cs_registers_i.dscratch1_q),
        .csr_dscratch1_we_i('0),  //i_cv32e40p_top.core_i.cs_registers_i.),

        .csr_mhpmcounter_q_i          (i_cv32e40p_top.core_i.cs_registers_i.mhpmcounter_q),
        .csr_mhpmcounter_write_lower_i(i_cv32e40p_top.core_i.cs_registers_i.mhpmcounter_write_lower),
        .csr_mhpmcounter_write_upper_i(i_cv32e40p_top.core_i.cs_registers_i.mhpmcounter_write_upper),

        .csr_mvendorid_i({cv32e40p_pkg::MVENDORID_BANK, cv32e40p_pkg::MVENDORID_OFFSET}),  //TODO: get this from the design instead of the pkg
        .csr_marchid_i  (cv32e40p_pkg::MARCHID),                             //TODO: get this from the design instead of the pkg

        .csr_fcsr_fflags_n_i (i_cv32e40p_top.core_i.cs_registers_i.fflags_n),
        .csr_fcsr_fflags_q_i (i_cv32e40p_top.core_i.cs_registers_i.fflags_q),
        .csr_fcsr_fflags_we_i(i_cv32e40p_top.core_i.cs_registers_i.fflags_we_i),
        .csr_fcsr_frm_n_i    (i_cv32e40p_top.core_i.cs_registers_i.frm_n),
        .csr_fcsr_frm_q_i    (i_cv32e40p_top.core_i.cs_registers_i.frm_q),
        //
        .rvfi_valid(rvfi_valid),
        .rvfi_order(rvfi_order),
        .rvfi_start_cycle(rvfi_start_cycle),
        .rvfi_start_time(rvfi_start_time),
        .rvfi_stop_cycle(rvfi_stop_cycle),
        .rvfi_stop_time(rvfi_stop_time),
        .rvfi_insn(rvfi_insn),
        .rvfi_trap(rvfi_trap),
        .rvfi_halt(rvfi_halt),
        .rvfi_intr(rvfi_intr),
        .rvfi_mode(rvfi_mode),
        .rvfi_ixl(rvfi_ixl),
        .rvfi_nmip(rvfi_nmip),
        .rvfi_dbg(rvfi_dbg),
        .rvfi_dbg_mode(rvfi_dbg_mode),
        .rvfi_wu(rvfi_wu),
        .rvfi_sleep(rvfi_sleep),
        .rvfi_rd_addr(rvfi_rd_addr),
        .rvfi_rd_wdata(rvfi_rd_wdata),
        .rvfi_frd_wvalid(rvfi_frd_wvalid),
        .rvfi_frd_addr(rvfi_frd_addr),
        .rvfi_frd_wdata(rvfi_frd_wdata),
        .rvfi_2_rd(rvfi_2_rd),
        .rvfi_rs1_addr(rvfi_rs1_addr),
        .rvfi_rs2_addr(rvfi_rs2_addr),
        .rvfi_rs3_addr(rvfi_rs3_addr),
        .rvfi_rs1_rdata(rvfi_rs1_rdata),
        .rvfi_rs2_rdata(rvfi_rs2_rdata),
        .rvfi_rs3_rdata(rvfi_rs3_rdata),
        .rvfi_frs1_addr(rvfi_frs1_addr),
        .rvfi_frs2_addr(rvfi_frs2_addr),
        .rvfi_frs3_addr(rvfi_frs3_addr),
        .rvfi_frs1_rvalid(rvfi_frs1_rvalid),
        .rvfi_frs2_rvalid(rvfi_frs2_rvalid),
        .rvfi_frs3_rvalid(rvfi_frs3_rvalid),
        .rvfi_frs1_rdata(rvfi_frs1_rdata),
        .rvfi_frs2_rdata(rvfi_frs2_rdata),
        .rvfi_frs3_rdata(rvfi_frs3_rdata),
        .rvfi_pc_rdata(rvfi_pc_rdata),
        .rvfi_pc_wdata(rvfi_pc_wdata),
        .rvfi_mem_addr(rvfi_mem_addr),
        .rvfi_mem_rmask(rvfi_mem_rmask),
        .rvfi_mem_wmask(rvfi_mem_wmask),
        .rvfi_mem_rdata(rvfi_mem_rdata),
        .rvfi_mem_wdata(rvfi_mem_wdata),
        .rvfi_csr_fflags_rmask(rvfi_csr_fflags_rmask),
        .rvfi_csr_fflags_wmask(rvfi_csr_fflags_wmask),
        .rvfi_csr_fflags_rdata(rvfi_csr_fflags_rdata),
        .rvfi_csr_fflags_wdata(rvfi_csr_fflags_wdata),
        .rvfi_csr_frm_rmask(rvfi_csr_frm_rmask),
        .rvfi_csr_frm_wmask(rvfi_csr_frm_wmask),
        .rvfi_csr_frm_rdata(rvfi_csr_frm_rdata),
        .rvfi_csr_frm_wdata(rvfi_csr_frm_wdata),
        .rvfi_csr_fcsr_rmask(rvfi_csr_fcsr_rmask),
        .rvfi_csr_fcsr_wmask(rvfi_csr_fcsr_wmask),
        .rvfi_csr_fcsr_rdata(rvfi_csr_fcsr_rdata),
        .rvfi_csr_fcsr_wdata(rvfi_csr_fcsr_wdata),
        .rvfi_csr_jvt_rmask(rvfi_csr_jvt_rmask),
        .rvfi_csr_jvt_wmask(rvfi_csr_jvt_wmask),
        .rvfi_csr_jvt_rdata(rvfi_csr_jvt_rdata),
        .rvfi_csr_jvt_wdata(rvfi_csr_jvt_wdata),
        .rvfi_csr_mstatus_rmask(rvfi_csr_mstatus_rmask),
        .rvfi_csr_mstatus_wmask(rvfi_csr_mstatus_wmask),
        .rvfi_csr_mstatus_rdata(rvfi_csr_mstatus_rdata),
        .rvfi_csr_mstatus_wdata(rvfi_csr_mstatus_wdata),
        .rvfi_csr_mstatush_rmask(rvfi_csr_mstatush_rmask),
        .rvfi_csr_mstatush_wmask(rvfi_csr_mstatush_wmask),
        .rvfi_csr_mstatush_rdata(rvfi_csr_mstatush_rdata),
        .rvfi_csr_mstatush_wdata(rvfi_csr_mstatush_wdata),
        .rvfi_csr_misa_rmask(rvfi_csr_misa_rmask),
        .rvfi_csr_misa_wmask(rvfi_csr_misa_wmask),
        .rvfi_csr_misa_rdata(rvfi_csr_misa_rdata),
        .rvfi_csr_misa_wdata(rvfi_csr_misa_wdata),
        .rvfi_csr_mie_rmask(rvfi_csr_mie_rmask),
        .rvfi_csr_mie_wmask(rvfi_csr_mie_wmask),
        .rvfi_csr_mie_rdata(rvfi_csr_mie_rdata),
        .rvfi_csr_mie_wdata(rvfi_csr_mie_wdata),
        .rvfi_csr_mtvec_rmask(rvfi_csr_mtvec_rmask),
        .rvfi_csr_mtvec_wmask(rvfi_csr_mtvec_wmask),
        .rvfi_csr_mtvec_rdata(rvfi_csr_mtvec_rdata),
        .rvfi_csr_mtvec_wdata(rvfi_csr_mtvec_wdata),
        .rvfi_csr_mtvt_rmask(rvfi_csr_mtvt_rmask),
        .rvfi_csr_mtvt_wmask(rvfi_csr_mtvt_wmask),
        .rvfi_csr_mtvt_rdata(rvfi_csr_mtvt_rdata),
        .rvfi_csr_mtvt_wdata(rvfi_csr_mtvt_wdata),
        .rvfi_csr_mcountinhibit_rmask(rvfi_csr_mcountinhibit_rmask),
        .rvfi_csr_mcountinhibit_wmask(rvfi_csr_mcountinhibit_wmask),
        .rvfi_csr_mcountinhibit_rdata(rvfi_csr_mcountinhibit_rdata),
        .rvfi_csr_mcountinhibit_wdata(rvfi_csr_mcountinhibit_wdata),
        .rvfi_csr_mhpmevent_rmask(rvfi_csr_mhpmevent_rmask),
        .rvfi_csr_mhpmevent_wmask(rvfi_csr_mhpmevent_wmask),
        .rvfi_csr_mhpmevent_rdata(rvfi_csr_mhpmevent_rdata),
        .rvfi_csr_mhpmevent_wdata(rvfi_csr_mhpmevent_wdata),
        .rvfi_csr_mscratch_rmask(rvfi_csr_mscratch_rmask),
        .rvfi_csr_mscratch_wmask(rvfi_csr_mscratch_wmask),
        .rvfi_csr_mscratch_rdata(rvfi_csr_mscratch_rdata),
        .rvfi_csr_mscratch_wdata(rvfi_csr_mscratch_wdata),
        .rvfi_csr_mepc_rmask(rvfi_csr_mepc_rmask),
        .rvfi_csr_mepc_wmask(rvfi_csr_mepc_wmask),
        .rvfi_csr_mepc_rdata(rvfi_csr_mepc_rdata),
        .rvfi_csr_mepc_wdata(rvfi_csr_mepc_wdata),
        .rvfi_csr_mcause_rmask(rvfi_csr_mcause_rmask),
        .rvfi_csr_mcause_wmask(rvfi_csr_mcause_wmask),
        .rvfi_csr_mcause_rdata(rvfi_csr_mcause_rdata),
        .rvfi_csr_mcause_wdata(rvfi_csr_mcause_wdata),
        .rvfi_csr_mtval_rmask(rvfi_csr_mtval_rmask),
        .rvfi_csr_mtval_wmask(rvfi_csr_mtval_wmask),
        .rvfi_csr_mtval_rdata(rvfi_csr_mtval_rdata),
        .rvfi_csr_mtval_wdata(rvfi_csr_mtval_wdata),
        .rvfi_csr_mip_rmask(rvfi_csr_mip_rmask),
        .rvfi_csr_mip_wmask(rvfi_csr_mip_wmask),
        .rvfi_csr_mip_rdata(rvfi_csr_mip_rdata),
        .rvfi_csr_mip_wdata(rvfi_csr_mip_wdata),
        .rvfi_csr_mnxti_rmask(rvfi_csr_mnxti_rmask),
        .rvfi_csr_mnxti_wmask(rvfi_csr_mnxti_wmask),
        .rvfi_csr_mnxti_rdata(rvfi_csr_mnxti_rdata),
        .rvfi_csr_mnxti_wdata(rvfi_csr_mnxti_wdata),
        .rvfi_csr_mintstatus_rmask(rvfi_csr_mintstatus_rmask),
        .rvfi_csr_mintstatus_wmask(rvfi_csr_mintstatus_wmask),
        .rvfi_csr_mintstatus_rdata(rvfi_csr_mintstatus_rdata),
        .rvfi_csr_mintstatus_wdata(rvfi_csr_mintstatus_wdata),
        .rvfi_csr_mintthresh_rmask(rvfi_csr_mintthresh_rmask),
        .rvfi_csr_mintthresh_wmask(rvfi_csr_mintthresh_wmask),
        .rvfi_csr_mintthresh_rdata(rvfi_csr_mintthresh_rdata),
        .rvfi_csr_mintthresh_wdata(rvfi_csr_mintthresh_wdata),
        .rvfi_csr_mscratchcsw_rmask(rvfi_csr_mscratchcsw_rmask),
        .rvfi_csr_mscratchcsw_wmask(rvfi_csr_mscratchcsw_wmask),
        .rvfi_csr_mscratchcsw_rdata(rvfi_csr_mscratchcsw_rdata),
        .rvfi_csr_mscratchcsw_wdata(rvfi_csr_mscratchcsw_wdata),
        .rvfi_csr_mscratchcswl_rmask(rvfi_csr_mscratchcswl_rmask),
        .rvfi_csr_mscratchcswl_wmask(rvfi_csr_mscratchcswl_wmask),
        .rvfi_csr_mscratchcswl_rdata(rvfi_csr_mscratchcswl_rdata),
        .rvfi_csr_mscratchcswl_wdata(rvfi_csr_mscratchcswl_wdata),
        .rvfi_csr_mclicbase_rmask(rvfi_csr_mclicbase_rmask),
        .rvfi_csr_mclicbase_wmask(rvfi_csr_mclicbase_wmask),
        .rvfi_csr_mclicbase_rdata(rvfi_csr_mclicbase_rdata),
        .rvfi_csr_mclicbase_wdata(rvfi_csr_mclicbase_wdata),
        .rvfi_csr_tselect_rmask(rvfi_csr_tselect_rmask),
        .rvfi_csr_tselect_wmask(rvfi_csr_tselect_wmask),
        .rvfi_csr_tselect_rdata(rvfi_csr_tselect_rdata),
        .rvfi_csr_tselect_wdata(rvfi_csr_tselect_wdata),
        .rvfi_csr_tdata_rmask(rvfi_csr_tdata_rmask),
        .rvfi_csr_tdata_wmask(rvfi_csr_tdata_wmask),
        .rvfi_csr_tdata_rdata(rvfi_csr_tdata_rdata),
        .rvfi_csr_tdata_wdata(rvfi_csr_tdata_wdata),
        .rvfi_csr_tinfo_rmask(rvfi_csr_tinfo_rmask),
        .rvfi_csr_tinfo_wmask(rvfi_csr_tinfo_wmask),
        .rvfi_csr_tinfo_rdata(rvfi_csr_tinfo_rdata),
        .rvfi_csr_tinfo_wdata(rvfi_csr_tinfo_wdata),
        .rvfi_csr_mcontext_rmask(rvfi_csr_mcontext_rmask),
        .rvfi_csr_mcontext_wmask(rvfi_csr_mcontext_wmask),
        .rvfi_csr_mcontext_rdata(rvfi_csr_mcontext_rdata),
        .rvfi_csr_mcontext_wdata(rvfi_csr_mcontext_wdata),
        .rvfi_csr_scontext_rmask(rvfi_csr_scontext_rmask),
        .rvfi_csr_scontext_wmask(rvfi_csr_scontext_wmask),
        .rvfi_csr_scontext_rdata(rvfi_csr_scontext_rdata),
        .rvfi_csr_scontext_wdata(rvfi_csr_scontext_wdata),
        .rvfi_csr_dcsr_rmask(rvfi_csr_dcsr_rmask),
        .rvfi_csr_dcsr_wmask(rvfi_csr_dcsr_wmask),
        .rvfi_csr_dcsr_rdata(rvfi_csr_dcsr_rdata),
        .rvfi_csr_dcsr_wdata(rvfi_csr_dcsr_wdata),
        .rvfi_csr_dpc_rmask(rvfi_csr_dpc_rmask),
        .rvfi_csr_dpc_wmask(rvfi_csr_dpc_wmask),
        .rvfi_csr_dpc_rdata(rvfi_csr_dpc_rdata),
        .rvfi_csr_dpc_wdata(rvfi_csr_dpc_wdata),
        .rvfi_csr_dscratch_rmask(rvfi_csr_dscratch_rmask),
        .rvfi_csr_dscratch_wmask(rvfi_csr_dscratch_wmask),
        .rvfi_csr_dscratch_rdata(rvfi_csr_dscratch_rdata),
        .rvfi_csr_dscratch_wdata(rvfi_csr_dscratch_wdata),
        .rvfi_csr_mcycle_rmask(rvfi_csr_mcycle_rmask),
        .rvfi_csr_mcycle_wmask(rvfi_csr_mcycle_wmask),
        .rvfi_csr_mcycle_rdata(rvfi_csr_mcycle_rdata),
        .rvfi_csr_mcycle_wdata(rvfi_csr_mcycle_wdata),
        .rvfi_csr_minstret_rmask(rvfi_csr_minstret_rmask),
        .rvfi_csr_minstret_wmask(rvfi_csr_minstret_wmask),
        .rvfi_csr_minstret_rdata(rvfi_csr_minstret_rdata),
        .rvfi_csr_minstret_wdata(rvfi_csr_minstret_wdata),
        .rvfi_csr_mhpmcounter_rmask(rvfi_csr_mhpmcounter_rmask),
        .rvfi_csr_mhpmcounter_wmask(rvfi_csr_mhpmcounter_wmask),
        .rvfi_csr_mhpmcounter_rdata(rvfi_csr_mhpmcounter_rdata),
        .rvfi_csr_mhpmcounter_wdata(rvfi_csr_mhpmcounter_wdata),
        .rvfi_csr_mcycleh_rmask(rvfi_csr_mcycleh_rmask),
        .rvfi_csr_mcycleh_wmask(rvfi_csr_mcycleh_wmask),
        .rvfi_csr_mcycleh_rdata(rvfi_csr_mcycleh_rdata),
        .rvfi_csr_mcycleh_wdata(rvfi_csr_mcycleh_wdata),
        .rvfi_csr_minstreth_rmask(rvfi_csr_minstreth_rmask),
        .rvfi_csr_minstreth_wmask(rvfi_csr_minstreth_wmask),
        .rvfi_csr_minstreth_rdata(rvfi_csr_minstreth_rdata),
        .rvfi_csr_minstreth_wdata(rvfi_csr_minstreth_wdata),
        .rvfi_csr_mhpmcounterh_rmask(rvfi_csr_mhpmcounterh_rmask),
        .rvfi_csr_mhpmcounterh_wmask(rvfi_csr_mhpmcounterh_wmask),
        .rvfi_csr_mhpmcounterh_rdata(rvfi_csr_mhpmcounterh_rdata),
        .rvfi_csr_mhpmcounterh_wdata(rvfi_csr_mhpmcounterh_wdata),
        .rvfi_csr_cycle_rmask(rvfi_csr_cycle_rmask),
        .rvfi_csr_cycle_wmask(rvfi_csr_cycle_wmask),
        .rvfi_csr_cycle_rdata(rvfi_csr_cycle_rdata),
        .rvfi_csr_cycle_wdata(rvfi_csr_cycle_wdata),
        .rvfi_csr_instret_rmask(rvfi_csr_instret_rmask),
        .rvfi_csr_instret_wmask(rvfi_csr_instret_wmask),
        .rvfi_csr_instret_rdata(rvfi_csr_instret_rdata),
        .rvfi_csr_instret_wdata(rvfi_csr_instret_wdata),
        .rvfi_csr_hpmcounter_rmask(rvfi_csr_hpmcounter_rmask),
        .rvfi_csr_hpmcounter_wmask(rvfi_csr_hpmcounter_wmask),
        .rvfi_csr_hpmcounter_rdata(rvfi_csr_hpmcounter_rdata),
        .rvfi_csr_hpmcounter_wdata(rvfi_csr_hpmcounter_wdata),
        .rvfi_csr_cycleh_rmask(rvfi_csr_cycleh_rmask),
        .rvfi_csr_cycleh_wmask(rvfi_csr_cycleh_wmask),
        .rvfi_csr_cycleh_rdata(rvfi_csr_cycleh_rdata),
        .rvfi_csr_cycleh_wdata(rvfi_csr_cycleh_wdata),
        .rvfi_csr_instreth_rmask(rvfi_csr_instreth_rmask),
        .rvfi_csr_instreth_wmask(rvfi_csr_instreth_wmask),
        .rvfi_csr_instreth_rdata(rvfi_csr_instreth_rdata),
        .rvfi_csr_instreth_wdata(rvfi_csr_instreth_wdata),
        .rvfi_csr_hpmcounterh_rmask(rvfi_csr_hpmcounterh_rmask),
        .rvfi_csr_hpmcounterh_wmask(rvfi_csr_hpmcounterh_wmask),
        .rvfi_csr_hpmcounterh_rdata(rvfi_csr_hpmcounterh_rdata),
        .rvfi_csr_hpmcounterh_wdata(rvfi_csr_hpmcounterh_wdata),
        .rvfi_csr_mvendorid_rmask(rvfi_csr_mvendorid_rmask),
        .rvfi_csr_mvendorid_wmask(rvfi_csr_mvendorid_wmask),
        .rvfi_csr_mvendorid_rdata(rvfi_csr_mvendorid_rdata),
        .rvfi_csr_mvendorid_wdata(rvfi_csr_mvendorid_wdata),
        .rvfi_csr_marchid_rmask(rvfi_csr_marchid_rmask),
        .rvfi_csr_marchid_wmask(rvfi_csr_marchid_wmask),
        .rvfi_csr_marchid_rdata(rvfi_csr_marchid_rdata),
        .rvfi_csr_marchid_wdata(rvfi_csr_marchid_wdata),
        .rvfi_csr_mimpid_rmask(rvfi_csr_mimpid_rmask),
        .rvfi_csr_mimpid_wmask(rvfi_csr_mimpid_wmask),
        .rvfi_csr_mimpid_rdata(rvfi_csr_mimpid_rdata),
        .rvfi_csr_mimpid_wdata(rvfi_csr_mimpid_wdata),
        .rvfi_csr_mhartid_rmask(rvfi_csr_mhartid_rmask),
        .rvfi_csr_mhartid_wmask(rvfi_csr_mhartid_wmask),
        .rvfi_csr_mhartid_rdata(rvfi_csr_mhartid_rdata),
        .rvfi_csr_mhartid_wdata(rvfi_csr_mhartid_wdata),
        .rvfi_csr_mcounteren_rmask(rvfi_csr_mcounteren_rmask),
        .rvfi_csr_mcounteren_wmask(rvfi_csr_mcounteren_wmask),
        .rvfi_csr_mcounteren_rdata(rvfi_csr_mcounteren_rdata),
        .rvfi_csr_mcounteren_wdata(rvfi_csr_mcounteren_wdata),
        .rvfi_csr_pmpcfg_rmask(rvfi_csr_pmpcfg_rmask),
        .rvfi_csr_pmpcfg_wmask(rvfi_csr_pmpcfg_wmask),
        .rvfi_csr_pmpcfg_rdata(rvfi_csr_pmpcfg_rdata),
        .rvfi_csr_pmpcfg_wdata(rvfi_csr_pmpcfg_wdata),
        .rvfi_csr_pmpaddr_rmask(rvfi_csr_pmpaddr_rmask),
        .rvfi_csr_pmpaddr_wmask(rvfi_csr_pmpaddr_wmask),
        .rvfi_csr_pmpaddr_rdata(rvfi_csr_pmpaddr_rdata),
        .rvfi_csr_pmpaddr_wdata(rvfi_csr_pmpaddr_wdata),
        .rvfi_csr_mseccfg_rmask(rvfi_csr_mseccfg_rmask),
        .rvfi_csr_mseccfg_wmask(rvfi_csr_mseccfg_wmask),
        .rvfi_csr_mseccfg_rdata(rvfi_csr_mseccfg_rdata),
        .rvfi_csr_mseccfg_wdata(rvfi_csr_mseccfg_wdata),
        .rvfi_csr_mseccfgh_rmask(rvfi_csr_mseccfgh_rmask),
        .rvfi_csr_mseccfgh_wmask(rvfi_csr_mseccfgh_wmask),
        .rvfi_csr_mseccfgh_rdata(rvfi_csr_mseccfgh_rdata),
        .rvfi_csr_mseccfgh_wdata(rvfi_csr_mseccfgh_wdata),
        .rvfi_csr_mconfigptr_rmask(rvfi_csr_mconfigptr_rmask),
        .rvfi_csr_mconfigptr_wmask(rvfi_csr_mconfigptr_wmask),
        .rvfi_csr_mconfigptr_rdata(rvfi_csr_mconfigptr_rdata),
        .rvfi_csr_mconfigptr_wdata(rvfi_csr_mconfigptr_wdata),
        .rvfi_csr_lpstart0_rmask(rvfi_csr_lpstart0_rmask),
        .rvfi_csr_lpstart0_wmask(rvfi_csr_lpstart0_wmask),
        .rvfi_csr_lpstart0_rdata(rvfi_csr_lpstart0_rdata),
        .rvfi_csr_lpstart0_wdata(rvfi_csr_lpstart0_wdata),
        .rvfi_csr_lpend0_rmask(rvfi_csr_lpend0_rmask),
        .rvfi_csr_lpend0_wmask(rvfi_csr_lpend0_wmask),
        .rvfi_csr_lpend0_rdata(rvfi_csr_lpend0_rdata),
        .rvfi_csr_lpend0_wdata(rvfi_csr_lpend0_wdata),
        .rvfi_csr_lpcount0_rmask(rvfi_csr_lpcount0_rmask),
        .rvfi_csr_lpcount0_wmask(rvfi_csr_lpcount0_wmask),
        .rvfi_csr_lpcount0_rdata(rvfi_csr_lpcount0_rdata),
        .rvfi_csr_lpcount0_wdata(rvfi_csr_lpcount0_wdata),
        .rvfi_csr_lpstart1_rmask(rvfi_csr_lpstart1_rmask),
        .rvfi_csr_lpstart1_wmask(rvfi_csr_lpstart1_wmask),
        .rvfi_csr_lpstart1_rdata(rvfi_csr_lpstart1_rdata),
        .rvfi_csr_lpstart1_wdata(rvfi_csr_lpstart1_wdata),
        .rvfi_csr_lpend1_rmask(rvfi_csr_lpend1_rmask),
        .rvfi_csr_lpend1_wmask(rvfi_csr_lpend1_wmask),
        .rvfi_csr_lpend1_rdata(rvfi_csr_lpend1_rdata),
        .rvfi_csr_lpend1_wdata(rvfi_csr_lpend1_wdata),
        .rvfi_csr_lpcount1_rmask(rvfi_csr_lpcount1_rmask),
        .rvfi_csr_lpcount1_wmask(rvfi_csr_lpcount1_wmask),
        .rvfi_csr_lpcount1_rdata(rvfi_csr_lpcount1_rdata),
        .rvfi_csr_lpcount1_wdata(rvfi_csr_lpcount1_wdata)
    );

      initial begin
        #0;
        fork
          rvfi_i.monitor_pipeline();
          rvfi_i.compute_pipeline();
          rvfi_i.update_rvfi();
        join_none
      end

`endif


    /*
    Level sensistive active high interrupt inputs.
    Not all interrupt inputs can be used on CV32E40P.
    Specifically
        irq_i[15:12]
        irq_i[10:8]
        irq_i[6:4]
        irq_i[2:0]
    shall be tied to 0 externally as they are reserved for future standard use
    (or for cores which are not Machine mode only) in the RISC-V Privileged specification.

    MEI: irq_i[11]
    MTI: irq_i[7]
    MSI: irq_i[3]
    correspond to the Machine External Interrupt (MEI), Machine Timer Interrupt (MTI), and Machine Software Interrupt (MSI) respectively.

    The irq_i[31:16] interrupts are a CV32E40P specific extension to the RISC-V Basic (a.k.a. CLINT) interrupt scheme.
    */

    // req         Master Slave    Address transfer request. req=1 signals the availability of valid address phase signals.
    // gnt         Slave  Master   Grant. Ready to accept address transfer. Address transfer is accepted on rising clk with req=1 and gnt=1.
    // addr[]      Master Slave    Address
    // we          Master Slave    Write Enable, high for writes, low for reads.
    // be[]        Master Slave    Byte Enable. Is set for the bytes to write/read.
    // wdata[]     Master Slave    Write data. Only valid for write transactions. Undefined for read transactions

    obi_if instr_dport ();
    assign instr_gnt_i        = instr_dport.gnt;
    assign instr_dport.req    = instr_req_o;
    assign instr_dport.addr   = instr_addr_o;
    assign instr_dport.we     = 0;
    assign instr_dport.be     = 0;
    assign instr_dport.wdata  = 0;
    assign instr_dport.aid    = 0;
    assign instr_dport.rready = 1;
    assign instr_rvalid_i     = instr_dport.rvalid;
    assign instr_rdata_i      = instr_dport.rdata;
    dport_ram #(
        .ADDR_WIDTH(17)
    ) i_instr_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(instr_dport)
    );

    obi_if data_dport ();
    assign data_gnt_i        = data_dport.gnt;
    assign data_dport.req    = data_req_o;
    assign data_dport.addr   = data_req_o ? data_addr_o : 0;
    assign data_dport.we     = data_req_o ? data_we_o : 0;
    assign data_dport.be     = data_req_o ? data_be_o : 0;
    assign data_dport.wdata  = data_req_o ? data_wdata_o : 0;
    assign data_dport.aid    = data_req_o ? 0 : 0;
    assign data_dport.rready = 1;
    assign data_rvalid_i     = data_dport.rvalid;
    assign data_rdata_i      = data_dport.rvalid ? data_dport.rdata : 0;
    //data_dport.err;
    //data_dport.rid;

    obi_if segments[dport_pkg::N_SEGMENTS] ();

    dport_mux i_dport_mux (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .cpu     (data_dport),
        .segments(segments)
    );

    // ------------------------------------------------------------------------

    mtime32 i_mtime (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .dport       (segments[0]),
        .intr_o      (irq_mti),
        .clear_intr_i(irq_mti_clear)
    );

    // ------------------------------------------------------------------------

    sim_ctrl i_sim_ctrl (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[1])
    );

    // ------------------------------------------------------------------------

    axi_if s_axi_dtcm ();
    dport_dtcm #(
        .DATA_WIDTH       (s_axi_dtcm.DATA_WIDTH),
        .ADDR_WIDTH       (dport_pkg::DTCM_WIDTH),
        .STRB_WIDTH       (s_axi_dtcm.STRB_WIDTH),
        .ID_WIDTH         (s_axi_dtcm.ID_WIDTH),
        .B_PIPELINE_OUTPUT(0),
        .B_INTERLEAVE     (0)
    ) i_dport_dtcm (
        .a_clk(clk_i),
        .a_rst(rst_i),
        .dport(segments[2]),
        .s_axi(s_axi_dtcm)
    );

    // ------------------------------------------------------------------------

    axi_if m_axi_cached ();
    dport2axi i_dport2axi_cached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[3]),
        .m_axi(m_axi_cached)
    );

    axi_ram #(
        .DATA_WIDTH(m_axi_cached.DATA_WIDTH),
        .ADDR_WIDTH(dport_pkg::CACHED_WIDTH),
        .STRB_WIDTH(m_axi_cached.STRB_WIDTH),
        .ID_WIDTH  (m_axi_cached.ID_WIDTH)
    ) i_axi_cached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_cached.awid),
        .s_axi_awaddr (m_axi_cached.awaddr[dport_pkg::CACHED_WIDTH-1:0]),
        .s_axi_awlen  (m_axi_cached.awlen),
        .s_axi_awsize (m_axi_cached.awsize),
        .s_axi_awburst(m_axi_cached.awburst),
        .s_axi_awlock (m_axi_cached.awlock),
        .s_axi_awcache(m_axi_cached.awcache),
        .s_axi_awprot (m_axi_cached.awprot),
        .s_axi_awvalid(m_axi_cached.awvalid),
        .s_axi_awready(m_axi_cached.awready),
        .s_axi_wdata  (m_axi_cached.wdata),
        .s_axi_wstrb  (m_axi_cached.wstrb),
        .s_axi_wlast  (m_axi_cached.wlast),
        .s_axi_wvalid (m_axi_cached.wvalid),
        .s_axi_wready (m_axi_cached.wready),
        .s_axi_bid    (m_axi_cached.bid),
        .s_axi_bresp  (m_axi_cached.bresp),
        .s_axi_bvalid (m_axi_cached.bvalid),
        .s_axi_bready (m_axi_cached.bready),
        .s_axi_arid   (m_axi_cached.arid),
        .s_axi_araddr (m_axi_cached.araddr[dport_pkg::CACHED_WIDTH-1:0]),
        .s_axi_arlen  (m_axi_cached.arlen),
        .s_axi_arsize (m_axi_cached.arsize),
        .s_axi_arburst(m_axi_cached.arburst),
        .s_axi_arlock (m_axi_cached.arlock),
        .s_axi_arcache(m_axi_cached.arcache),
        .s_axi_arprot (m_axi_cached.arprot),
        .s_axi_arvalid(m_axi_cached.arvalid),
        .s_axi_arready(m_axi_cached.arready),
        .s_axi_rid    (m_axi_cached.rid),
        .s_axi_rdata  (m_axi_cached.rdata),
        .s_axi_rresp  (m_axi_cached.rresp),
        .s_axi_rlast  (m_axi_cached.rlast),
        .s_axi_rvalid (m_axi_cached.rvalid),
        .s_axi_rready (m_axi_cached.rready)
    );

    // ------------------------------------------------------------------------

    axi_if m_axi_uncached ();
    dport2axi i_dport2axi_uncached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[4]),
        .m_axi(m_axi_uncached)
    );

    axi_ram #(
        .DATA_WIDTH(m_axi_uncached.DATA_WIDTH),
        .ADDR_WIDTH(dport_pkg::UNCACHED_WIDTH),
        .STRB_WIDTH(m_axi_uncached.STRB_WIDTH),
        .ID_WIDTH  (m_axi_uncached.ID_WIDTH)
    ) i_axi_uncached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_uncached.awid),
        .s_axi_awaddr (m_axi_uncached.awaddr[dport_pkg::UNCACHED_WIDTH-1:0]),
        .s_axi_awlen  (m_axi_uncached.awlen),
        .s_axi_awsize (m_axi_uncached.awsize),
        .s_axi_awburst(m_axi_uncached.awburst),
        .s_axi_awlock (m_axi_uncached.awlock),
        .s_axi_awcache(m_axi_uncached.awcache),
        .s_axi_awprot (m_axi_uncached.awprot),
        .s_axi_awvalid(m_axi_uncached.awvalid),
        .s_axi_awready(m_axi_uncached.awready),
        .s_axi_wdata  (m_axi_uncached.wdata),
        .s_axi_wstrb  (m_axi_uncached.wstrb),
        .s_axi_wlast  (m_axi_uncached.wlast),
        .s_axi_wvalid (m_axi_uncached.wvalid),
        .s_axi_wready (m_axi_uncached.wready),
        .s_axi_bid    (m_axi_uncached.bid),
        .s_axi_bresp  (m_axi_uncached.bresp),
        .s_axi_bvalid (m_axi_uncached.bvalid),
        .s_axi_bready (m_axi_uncached.bready),
        .s_axi_arid   (m_axi_uncached.arid),
        .s_axi_araddr (m_axi_uncached.araddr[dport_pkg::UNCACHED_WIDTH-1:0]),
        .s_axi_arlen  (m_axi_uncached.arlen),
        .s_axi_arsize (m_axi_uncached.arsize),
        .s_axi_arburst(m_axi_uncached.arburst),
        .s_axi_arlock (m_axi_uncached.arlock),
        .s_axi_arcache(m_axi_uncached.arcache),
        .s_axi_arprot (m_axi_uncached.arprot),
        .s_axi_arvalid(m_axi_uncached.arvalid),
        .s_axi_arready(m_axi_uncached.arready),
        .s_axi_rid    (m_axi_uncached.rid),
        .s_axi_rdata  (m_axi_uncached.rdata),
        .s_axi_rresp  (m_axi_uncached.rresp),
        .s_axi_rlast  (m_axi_uncached.rlast),
        .s_axi_rvalid (m_axi_uncached.rvalid),
        .s_axi_rready (m_axi_uncached.rready)
    );

    // ------------------------------------------------------------------------

    axil_if m_axil ();
    dport2axil i_dport2axil (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .dport (segments[5]),
        .m_axil(m_axil)
    );

    //axil_ram #(
    //    .DATA_WIDTH     (m_axil.DATA_WIDTH),
    //    .ADDR_WIDTH     (dport_pkg::AXIL_WIDTH),
    //    .STRB_WIDTH     (m_axil.STRB_WIDTH),
    //    .PIPELINE_OUTPUT(0)
    //) i_axil_ram (
    //    .clk           (clk_i),
    //    .rst           (rst_i),
    //    .s_axil_awaddr (m_axil.awaddr[dport_pkg::AXIL_WIDTH-1:0]),
    //    .s_axil_awprot (m_axil.awprot),
    //    .s_axil_awvalid(m_axil.awvalid),
    //    .s_axil_awready(m_axil.awready),
    //    .s_axil_wdata  (m_axil.wdata),
    //    .s_axil_wstrb  (m_axil.wstrb),
    //    .s_axil_wvalid (m_axil.wvalid),
    //    .s_axil_wready (m_axil.wready),
    //    .s_axil_bresp  (m_axil.bresp),
    //    .s_axil_bvalid (m_axil.bvalid),
    //    .s_axil_bready (m_axil.bready),
    //    .s_axil_araddr (m_axil.araddr[dport_pkg::AXIL_WIDTH-1:0]),
    //    .s_axil_arprot (m_axil.arprot),
    //    .s_axil_arvalid(m_axil.arvalid),
    //    .s_axil_arready(m_axil.arready),
    //    .s_axil_rdata  (m_axil.rdata),
    //    .s_axil_rresp  (m_axil.rresp),
    //    .s_axil_rvalid (m_axil.rvalid),
    //    .s_axil_rready (m_axil.rready)
    //);



    localparam int M_AXI_DATA_WIDTH = 32;
    localparam int M_AXI_ADDR_WIDTH = 32;
    localparam int M_AXI_ID_WIDTH = 4;
    localparam int M00_AXIS_TDATA_WIDTH = 8;
    localparam int M01_AXIS_TDATA_WIDTH = 16;
    localparam int S00_AXIS_TDATA_WIDTH = 8;
    localparam int S01_AXIS_TDATA_WIDTH = 16;
    localparam int S_AXIL_DATA_WIDTH = ringbuffer_addrmap_pkg::RINGBUFFER_ADDRMAP_MIN_ADDR_WIDTH;

    ringbuffer_axis_if #(.TDATA_WIDTH(M00_AXIS_TDATA_WIDTH)) m00_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(M01_AXIS_TDATA_WIDTH)) m01_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(S00_AXIS_TDATA_WIDTH)) s00_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(S01_AXIS_TDATA_WIDTH)) s01_axis ();

    logic [M00_AXIS_TDATA_WIDTH-1:0] x00_counter;
    always_ff @(posedge i_clk) begin : proc_x00
        if (i_rst) begin
            x00_counter <= 0;
        end else begin
            if (m00_axis.tready & m00_axis.tvalid) begin
                assert (m00_axis.tdata == x00_counter);
                x00_counter <= x00_counter + 1;
            end
        end
    end

    logic [M01_AXIS_TDATA_WIDTH-1:0] x01_counter;
    always_ff @(posedge i_clk) begin : proc_x01
        if (i_rst) begin
            x01_counter <= 0;
        end else begin
            if (m01_axis.tready & m01_axis.tvalid) begin
                assert (m01_axis.tdata == x01_counter);
                x01_counter <= x01_counter + 1;
            end
        end
    end


    assign s00_axis.tdata  = m00_axis.tdata;
    assign m00_axis.tready = s00_axis.tready;
    assign s00_axis.tvalid = m00_axis.tvalid;

    assign s01_axis.tdata  = m01_axis.tdata;
    assign m01_axis.tready = s01_axis.tready;
    assign s01_axis.tvalid = m01_axis.tvalid;

    ringbuffer_axil #(
        .M00_AXIS_TDATA_WIDTH(M00_AXIS_TDATA_WIDTH),
        .M01_AXIS_TDATA_WIDTH(M01_AXIS_TDATA_WIDTH),
        .S00_AXIS_TDATA_WIDTH(S00_AXIS_TDATA_WIDTH),
        .S01_AXIS_TDATA_WIDTH(S01_AXIS_TDATA_WIDTH),
        .M_AXI_ADDR_WIDTH    (M_AXI_ADDR_WIDTH),
        .M_AXI_DATA_WIDTH    (M_AXI_DATA_WIDTH),
        .M_AXI_ID_WIDTH      (M_AXI_ID_WIDTH)
    ) i_ringbuffer_axil (
        .i_clk         (i_clk),
        .i_reset       (i_rst),
        //
        .o_interrupt   (irq_mei),
        //
        .m00_axis      (m00_axis),
        .m01_axis      (m01_axis),
        .s00_axis      (s00_axis),
        .s01_axis      (s01_axis),
        //
        .s_axil_awaddr (m_axil.awaddr[dport_pkg::AXIL_WIDTH-1:0]),
        .s_axil_awprot (m_axil.awprot),
        .s_axil_awvalid(m_axil.awvalid),
        .s_axil_awready(m_axil.awready),
        .s_axil_wdata  (m_axil.wdata),
        .s_axil_wstrb  (m_axil.wstrb),
        .s_axil_wvalid (m_axil.wvalid),
        .s_axil_wready (m_axil.wready),
        .s_axil_bresp  (m_axil.bresp),
        .s_axil_bvalid (m_axil.bvalid),
        .s_axil_bready (m_axil.bready),
        .s_axil_araddr (m_axil.araddr[dport_pkg::AXIL_WIDTH-1:0]),
        .s_axil_arprot (m_axil.arprot),
        .s_axil_arvalid(m_axil.arvalid),
        .s_axil_arready(m_axil.arready),
        .s_axil_rdata  (m_axil.rdata),
        .s_axil_rresp  (m_axil.rresp),
        .s_axil_rvalid (m_axil.rvalid),
        .s_axil_rready (m_axil.rready),
        //
        .m_axi_arvalid (s_axi_dtcm.arvalid),
        .m_axi_arready (s_axi_dtcm.arready),
        .m_axi_araddr  (s_axi_dtcm.araddr),
        .m_axi_arlen   (s_axi_dtcm.arlen),
        .m_axi_arsize  (s_axi_dtcm.arsize),
        .m_axi_arburst (s_axi_dtcm.arburst),
        .m_axi_arid    (s_axi_dtcm.arid),
        .m_axi_rvalid  (s_axi_dtcm.rvalid),
        .m_axi_rready  (s_axi_dtcm.rready),
        .m_axi_rdata   (s_axi_dtcm.rdata),
        .m_axi_rlast   (s_axi_dtcm.rlast),
        .m_axi_rid     (s_axi_dtcm.rid),
        .m_axi_rresp   (s_axi_dtcm.rresp),
        .m_axi_awvalid (s_axi_dtcm.awvalid),
        .m_axi_awready (s_axi_dtcm.awready),
        .m_axi_awaddr  (s_axi_dtcm.awaddr),
        .m_axi_awlen   (s_axi_dtcm.awlen),
        .m_axi_awsize  (s_axi_dtcm.awsize),
        .m_axi_awburst (s_axi_dtcm.awburst),
        .m_axi_awid    (s_axi_dtcm.awid),
        .m_axi_wvalid  (s_axi_dtcm.wvalid),
        .m_axi_wready  (s_axi_dtcm.wready),
        .m_axi_wdata   (s_axi_dtcm.wdata),
        .m_axi_wstrb   (s_axi_dtcm.wstrb),
        .m_axi_wlast   (s_axi_dtcm.wlast),
        .m_axi_bvalid  (s_axi_dtcm.bvalid),
        .m_axi_bready  (s_axi_dtcm.bready),
        .m_axi_bid     (s_axi_dtcm.bid),
        .m_axi_bresp   (s_axi_dtcm.bresp)
    );




    // ------------------------------------------------------------------------

    function write_itcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            //$display("ITCM: %08X: %08X", addr, data);
            case (addr[1:0])
                2'd0: i_instr_ram.mem[addr/4][7:0] = data;
                2'd1: i_instr_ram.mem[addr/4][15:8] = data;
                2'd2: i_instr_ram.mem[addr/4][23:16] = data;
                2'd3: i_instr_ram.mem[addr/4][31:24] = data;
            endcase
        end
    endfunction
    function [7:0] read_itcm;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[1:0])
                2'd0: read_itcm = i_instr_ram.mem[addr/4][7:0];
                2'd1: read_itcm = i_instr_ram.mem[addr/4][15:8];
                2'd2: read_itcm = i_instr_ram.mem[addr/4][23:16];
                2'd3: read_itcm = i_instr_ram.mem[addr/4][31:24];
            endcase
        end
    endfunction

    function write_dtcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            //$display("DTCM: %08X: %08X", addr, data);
            case (addr[1:0])
                2'd0: i_dport_dtcm.mem[addr/4][7:0] = data;
                2'd1: i_dport_dtcm.mem[addr/4][15:8] = data;
                2'd2: i_dport_dtcm.mem[addr/4][23:16] = data;
                2'd3: i_dport_dtcm.mem[addr/4][31:24] = data;
            endcase
        end
    endfunction
    function [7:0] read_dtcm;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[1:0])
                2'd0: read_dtcm = i_dport_dtcm.mem[addr/4][7:0];
                2'd1: read_dtcm = i_dport_dtcm.mem[addr/4][15:8];
                2'd2: read_dtcm = i_dport_dtcm.mem[addr/4][23:16];
                2'd3: read_dtcm = i_dport_dtcm.mem[addr/4][31:24];
            endcase
        end
    endfunction


    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end

endmodule : tb_cv32e40p
