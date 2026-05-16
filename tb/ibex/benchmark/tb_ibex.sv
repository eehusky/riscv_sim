module tb_ibex (
    input logic i_clk,
    input logic i_rst
);
    import ibex_pkg::*;
    parameter bit SecureIbex = 1'b0;
    parameter int unsigned LockstepOffset = 1;
    parameter bit ICacheScramble = 1'b0;
    parameter bit PMPEnable = 1'b0;
    parameter int unsigned PMPGranularity = 0;
    parameter int unsigned PMPNumRegions = 4;
    parameter int unsigned MHPMCounterNum = 0;
    parameter int unsigned MHPMCounterWidth = 40;
    parameter bit RV32E = 1'b0;
    parameter ibex_pkg::rv32m_e RV32M = ibex_pkg::RV32MSingleCycle;
    parameter ibex_pkg::rv32b_e RV32B = ibex_pkg::RV32BFull;
    parameter ibex_pkg::rv32zc_e RV32ZC = ibex_pkg::RV32ZcaZcbZcmp;
    parameter ibex_pkg::regfile_e RegFile = ibex_pkg::RegFileFF;
    parameter bit BranchTargetALU = 1'b1;
    parameter bit WritebackStage = 1'b1;
    parameter bit ICache = 1'b0;
    parameter bit DbgTriggerEn = 1'b0;
    parameter bit ICacheECC = 1'b0;
    parameter bit ICacheTweakInfection = 1'b0;
    parameter bit BranchPredictor = 1'b1;
    parameter SRAMInitFile = "";

    // M(ultiply) extension select:
    //     “ibex_pkg::RV32MNone”: No M-extension
    //     “ibex_pkg::RV32MSlow”: Slow multi-cycle multiplier, iterative divider
    //     “ibex_pkg::RV32MFast”: 3-4 cycle multiplier, iterative divider
    //     “ibex_pkg::RV32MSingleCycle”: 1-2 cycle multiplier, iterative divider

    // Clock and Reset
    logic                                                              clk_i;
    logic                                                              rst_i;

    // enable all clock gates for testing
    logic                                                              test_en_i;
    logic                                                              scan_rst_ni;
    prim_ram_1p_pkg::ram_1p_cfg_t                                      ram_cfg_icache_tag_i;
    prim_ram_1p_pkg::ram_1p_cfg_rsp_t [     ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_rsp_icache_tag_o;
    prim_ram_1p_pkg::ram_1p_cfg_t                                      ram_cfg_icache_data_i;
    prim_ram_1p_pkg::ram_1p_cfg_rsp_t [     ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_rsp_icache_data_o;


    logic                             [                          31:0] hart_id_i;
    logic                             [                          31:0] boot_addr_i;

    // Instruction memory interface
    logic                                                              instr_req_o;
    logic                                                              instr_gnt_i;
    logic                                                              instr_rvalid_i;
    logic                             [                          31:0] instr_addr_o;
    logic                             [                          31:0] instr_rdata_i;
    logic                             [                           6:0] instr_rdata_intg_i;
    logic                                                              instr_err_i;

    // Data memory interface
    logic                                                              data_req_o;
    logic                                                              data_gnt_i;
    logic                                                              data_rvalid_i;
    logic                                                              data_we_o;
    logic                             [                           3:0] data_be_o;
    logic                             [                          31:0] data_addr_o;
    logic                             [                          31:0] data_wdata_o;
    logic                             [                           6:0] data_wdata_intg_o;
    logic                             [                          31:0] data_rdata_i;
    logic                             [                           6:0] data_rdata_intg_i;
    logic                                                              data_err_i;

    // Interrupt inputs
    logic                                                              irq_software_i;
    logic                                                              irq_timer_i;
    logic                                                              irq_external_i;
    logic                             [                          14:0] irq_fast_i;
    // non-maskable interrupt
    logic                                                              irq_nm_i;

    // Scrambling Interface
    logic                                                              scramble_key_valid_i;
    logic                             [  ibex_pkg::SCRAMBLE_KEY_W-1:0] scramble_key_i;
    logic                             [ibex_pkg::SCRAMBLE_NONCE_W-1:0] scramble_nonce_i;
    logic                                                              scramble_req_o;

    // Debug Interface
    logic                                                              debug_req_i;
    crash_dump_t                                                       crash_dump_o;
    logic                                                              double_fault_seen_o;

    // CPU Control Signals
    ibex_mubi_t                                                        fetch_enable_i;
    logic                                                              alert_minor_o;
    logic                                                              alert_major_internal_o;
    logic                                                              alert_major_bus_o;
    logic                                                              core_sleep_o;

    // Lockstep signals
    ibex_mubi_t                                                        lockstep_cmp_en_o;

    // Shadow core data interface outputs
    logic                                                              data_req_shadow_o;
    logic                                                              data_we_shadow_o;
    logic                             [                           3:0] data_be_shadow_o;
    logic                             [                          31:0] data_addr_shadow_o;
    logic                             [                          31:0] data_wdata_shadow_o;
    logic                             [                           6:0] data_wdata_intg_shadow_o;

    // Shadow core instruction interface outputs
    logic                                                              instr_req_shadow_o;
    logic                             [                          31:0] instr_addr_shadow_o;

    logic                                                              timer_irq;
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
        .DmBaseAddr          (32'h00100000),
        .DmAddrMask          (32'h00000003),
        .DmHaltAddr          (32'h00100000),
        .DmExceptionAddr     (32'h00100000)
    ) u_top (
        .clk_i (i_clk),
        .rst_ni(~i_rst),

        .test_en_i                (i_rst),
        .scan_rst_ni              (~i_rst),
        .ram_cfg_icache_tag_i     (prim_ram_1p_pkg::RAM_1P_CFG_DEFAULT),
        .ram_cfg_rsp_icache_tag_o (),
        .ram_cfg_icache_data_i    (prim_ram_1p_pkg::RAM_1P_CFG_DEFAULT),
        .ram_cfg_rsp_icache_data_o(),

        .hart_id_i  (32'b0),
        // First instruction executed is at 0x0 + 0x80
        .boot_addr_i(32'h80000000),

        .instr_req_o       (instr_dport.req),
        .instr_gnt_i       (instr_dport.gnt),
        .instr_rvalid_i    (instr_dport.rvalid),
        .instr_addr_o      (instr_dport.addr),
        .instr_rdata_i     (instr_dport.rdata),
        .instr_rdata_intg_i(0),
        .instr_err_i       (instr_dport.err),

        .data_req_o       (data_dport.req),
        .data_gnt_i       (data_dport.gnt),
        .data_rvalid_i    (data_dport.rvalid),
        .data_we_o        (data_dport.we),
        .data_be_o        (data_dport.be),
        .data_addr_o      (data_dport.addr),
        .data_wdata_o     (data_dport.wdata),
        .data_wdata_intg_o(),
        .data_rdata_i     (data_dport.rdata),
        .data_rdata_intg_i(0),
        .data_err_i       (data_dport.err),

        .irq_software_i(1'b0),
        .irq_timer_i   (0),
        .irq_external_i(1'b0),
        .irq_fast_i    (15'b0),
        .irq_nm_i      (1'b0),

        .scramble_key_valid_i('0),
        .scramble_key_i      ('0),
        .scramble_nonce_i    ('0),
        .scramble_req_o      (),

        .debug_req_i        (1'b0),
        .crash_dump_o       (),
        .double_fault_seen_o(),

        .fetch_enable_i        (ibex_pkg::IbexMuBiOn),
        .alert_minor_o         (),
        .alert_major_internal_o(),
        .alert_major_bus_o     (),
        .core_sleep_o          (),

        .lockstep_cmp_en_o(),

        .data_req_shadow_o       (),
        .data_we_shadow_o        (),
        .data_be_shadow_o        (),
        .data_addr_shadow_o      (),
        .data_wdata_shadow_o     (),
        .data_wdata_intg_shadow_o(),

        .instr_req_shadow_o (),
        .instr_addr_shadow_o()
    );

    assign clk_i             = i_clk;
    assign rst_i             = i_rst;
    assign data_dport.rready = 1;


    // ------------------------------------------------------------------------

    obi_if instr_dport ();
    dport_ram #(
        .ADDR_WIDTH(17)
    ) i_instr_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(instr_dport)
    );

    obi_if data_dport ();
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
        .intr_o      (timer_irq),
        .clear_intr_i(0)
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

    function static void write_itcm;  /*verilator public*/
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

    function static void write_dtcm;  /*verilator public*/
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
endmodule : tb_ibex
