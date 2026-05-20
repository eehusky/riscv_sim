module ibex_wrapper #(
    parameter bit                 [31:0] BOOT_ADDRESS         = 32'h8000_0000,
    parameter int                        HART_ID              = 0,
    parameter bit                 [31:0] DM_BASE_ADDR         = 32'h0010_0000,
    parameter bit                 [31:0] DM_ADDR_MASK         = 32'h0000_0003,
    parameter bit                 [31:0] DM_HALT_ADDR         = 32'h0010_0000,
    parameter bit                 [31:0] DM_EXCEPTION_ADDR    = 32'h0010_0000,
    parameter bit                        SecureIbex           = 1'b0,
    parameter int unsigned               LockstepOffset       = 1,
    parameter bit                        ICacheScramble       = 1'b0,
    parameter bit                        PMPEnable            = 1'b0,
    parameter int unsigned               PMPGranularity       = 0,
    parameter int unsigned               PMPNumRegions        = 4,
    parameter int unsigned               MHPMCounterNum       = 0,
    parameter int unsigned               MHPMCounterWidth     = 40,
    parameter bit                        RV32E                = 1'b0,
    parameter ibex_pkg::rv32m_e          RV32M                = ibex_pkg::RV32MSingleCycle,
    parameter ibex_pkg::rv32b_e          RV32B                = ibex_pkg::RV32BFull,
    parameter ibex_pkg::rv32zc_e         RV32ZC               = ibex_pkg::RV32ZcaZcbZcmp,
    parameter ibex_pkg::regfile_e        RegFile              = ibex_pkg::RegFileFF,
    parameter bit                        BranchTargetALU      = 1'b1,
    parameter bit                        WritebackStage       = 1'b1,
    parameter bit                        ICache               = 1'b0,
    parameter bit                        DbgTriggerEn         = 1'b0,
    parameter bit                        ICacheECC            = 1'b0,
    parameter bit                        ICacheTweakInfection = 1'b0,
    parameter bit                        BranchPredictor      = 1'b1
) (
    input logic        clk_i,
    input logic        rst_i,
    input logic [31:0] irq_i,

    input logic        debug_req_i,
    obi_if.master instr_dport,
    obi_if.master data_dport
);
    // enable all clock gates for testing
    //logic                         test_en_i;
    //logic                         scan_rst_ni;

    // Interrupt inputs
    logic                         irq_software;
    logic                         irq_timer;
    logic                         irq_external;
    logic                  [14:0] irq_fast;
    logic                         irq_nm;

    // CPU Control Signals
    logic                         core_sleep;

    logic                         debug_req;
    ibex_pkg::crash_dump_t        crash_dump;

    // irq_nm_i         31      Non-maskable interrupt (NMI)
    // irq_fast_i[14:0] 30:16   15 fast, local interrupts
    // irq_external_i   11      Connected to platform-level interrupt controller
    // irq_timer_i      7       Connected to timer module
    // irq_software_i   3       Connected to memory-mapped (inter-processor) interrupt register
    assign irq_nm           = irq_i[31];
    assign irq_fast         = irq_i[30:16];
    assign irq_external     = irq_i[11];
    assign irq_timer        = irq_i[7];
    assign irq_software     = irq_i[3];

    assign data_dport.rready  = 1;
    assign instr_dport.rready = 1;

    ibex_top #(
        .SecureIbex          (SecureIbex),
        .LockstepOffset      (LockstepOffset),
        .ICacheScramble      (ICacheScramble),
        .PMPEnable           (PMPEnable),
        .PMPGranularity      (PMPGranularity),
        .PMPNumRegions       (PMPNumRegions),
        .MHPMCounterNum      (MHPMCounterNum),
        .MHPMCounterWidth    (MHPMCounterWidth),
        .RV32E               (RV32E),
        .RV32M               (RV32M),
        .RV32B               (RV32B),
        .RV32ZC              (RV32ZC),
        .RegFile             (RegFile),
        .BranchTargetALU     (BranchTargetALU),
        .ICache              (ICache),
        .ICacheECC           (ICacheECC),
        .ICacheTweakInfection(ICacheTweakInfection),
        .WritebackStage      (WritebackStage),
        .BranchPredictor     (BranchPredictor),
        .DbgTriggerEn        (DbgTriggerEn),
        .DmBaseAddr          (DM_BASE_ADDR),
        .DmAddrMask          (DM_ADDR_MASK),
        .DmHaltAddr          (DM_HALT_ADDR),
        .DmExceptionAddr     (DM_EXCEPTION_ADDR)
    ) u_top (
        .clk_i                    (clk_i),
        .rst_ni                   (~rst_i),
        //
        .test_en_i                (rst_i),
        .scan_rst_ni              (~rst_i),
        .ram_cfg_icache_tag_i     (prim_ram_1p_pkg::RAM_1P_CFG_DEFAULT),
        .ram_cfg_rsp_icache_tag_o (),
        .ram_cfg_icache_data_i    (prim_ram_1p_pkg::RAM_1P_CFG_DEFAULT),
        .ram_cfg_rsp_icache_data_o(),
        //
        .hart_id_i                (HART_ID),
        .boot_addr_i              (BOOT_ADDRESS),
        //
        .instr_req_o              (instr_dport.req),
        .instr_gnt_i              (instr_dport.gnt),
        .instr_rvalid_i           (instr_dport.rvalid),
        .instr_addr_o             (instr_dport.addr),
        .instr_rdata_i            (instr_dport.rdata),
        .instr_rdata_intg_i       (0),
        .instr_err_i              (instr_dport.err),
        //
        .data_req_o               (data_dport.req),
        .data_gnt_i               (data_dport.gnt),
        .data_rvalid_i            (data_dport.rvalid),
        .data_we_o                (data_dport.we),
        .data_be_o                (data_dport.be),
        .data_addr_o              (data_dport.addr),
        .data_wdata_o             (data_dport.wdata),
        .data_wdata_intg_o        (),
        .data_rdata_i             (data_dport.rdata),
        .data_rdata_intg_i        (0),
        .data_err_i               (data_dport.err),
        //
        .irq_software_i           (irq_software),
        .irq_timer_i              (irq_timer),
        .irq_external_i           (irq_external),
        .irq_fast_i               (irq_fast),
        .irq_nm_i                 (irq_nm),
        //
        .scramble_key_valid_i     ('0),
        .scramble_key_i           ('0),
        .scramble_nonce_i         ('0),
        .scramble_req_o           (),
        //
        .debug_req_i              (debug_req_i),
        .crash_dump_o             (crash_dump),
        .double_fault_seen_o      (),
        //
        .fetch_enable_i           (ibex_pkg::IbexMuBiOn),
        .alert_minor_o            (),
        .alert_major_internal_o   (),
        .alert_major_bus_o        (),
        .core_sleep_o             (core_sleep),
        //
        .lockstep_cmp_en_o        (),
        .data_req_shadow_o        (),
        .data_we_shadow_o         (),
        .data_be_shadow_o         (),
        .data_addr_shadow_o       (),
        .data_wdata_shadow_o      (),
        .data_wdata_intg_shadow_o (),
        .instr_req_shadow_o       (),
        .instr_addr_shadow_o      ()
    );



endmodule : ibex_wrapper
