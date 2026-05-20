module tb_ibex #(
    parameter bit                 [31:0] BOOT_ADDRESS         = 32'h8000_0000,
    parameter int                        HART_ID              = 0,
    //parameter bit                 [31:0] DM_BASE_ADDR         = 32'h0010_0000,
    //parameter bit                 [31:0] DM_ADDR_MASK         = 32'h0000_0003,
    //parameter bit                 [31:0] DM_HALT_ADDR         = 32'h0010_0000,
    //parameter bit                 [31:0] DM_EXCEPTION_ADDR    = 32'h0010_0000,
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
    parameter bit                        DbgTriggerEn         = 1'b1,
    parameter bit                        ICacheECC            = 1'b0,
    parameter bit                        ICacheTweakInfection = 1'b0,
    parameter bit                        BranchPredictor      = 1'b1
) (
    input logic clk_i,
    input logic rst_i
);
    localparam int INITIATOR_ID_WIDTH = 1;
    localparam int TARGET_ID_WIDTH = INITIATOR_ID_WIDTH + $clog2(obi_pkg::N_INITIATORS);

    logic                        ndmreset_n;
    logic [31:0] irq_i;
    obi_if #(.ID_WIDTH(INITIATOR_ID_WIDTH)) initiators[obi_pkg::N_INITIATORS] ();
    obi_if #(.ID_WIDTH(TARGET_ID_WIDTH)) targets[obi_pkg::N_TARGETS] ();

    ibex_wrapper #(
        .BOOT_ADDRESS        (BOOT_ADDRESS),
        .HART_ID             (HART_ID),
        .DM_BASE_ADDR        (obi_pkg::DEBUG_ADDR),
        //.DM_ADDR_MASK        (),
        .DM_HALT_ADDR        (obi_pkg::DEBUG_ADDR+dm::HaltAddress),
        .DM_EXCEPTION_ADDR   (obi_pkg::DEBUG_ADDR+dm::ExceptionAddress),
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
        .WritebackStage      (WritebackStage),
        .ICache              (ICache),
        .DbgTriggerEn        (DbgTriggerEn),
        .ICacheECC           (ICacheECC),
        .ICacheTweakInfection(ICacheTweakInfection),
        .BranchPredictor     (BranchPredictor)
    ) i_ibex_wrapper (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .irq_i      (irq_i),
        .debug_req_i      (debug_req),
        .instr_dport(initiators[0]),
        .data_dport (initiators[1])
    );
    `ifdef edfqwef
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    localparam int NrHarts = 1;
    logic                        testmode;
    logic                        ndmreset;  // non-debug module reset
    logic                        dmactive;  // debug module is active
    logic          [NrHarts-1:0] debug_req;  // async debug request
    logic          [NrHarts-1:0] unavailable;
    dm::hartinfo_t [NrHarts-1:0] hartinfo;

    logic                        dmi_rst;
    logic                        dmi_req_valid;
    logic                        dmi_req_ready;
    dm::dmi_req_t                dmi_req;
    logic                        dmi_resp_valid;
    logic                        dmi_resp_ready;
    dm::dmi_resp_t               dmi_resp;

    localparam dm::hartinfo_t HARTINFO = {8'h0, 4'h2, 3'b0, 1'b1, dm::DataCount, dm::DataAddr};
    assign unavailable          = 0;
    assign hartinfo             = HARTINFO;
    assign initiators[2].rready = 1;

    // reset handling with ndmreset
    rstgen i_rstgen_main (
        .clk_i      (clk_i),
        .rst_ni     (~rst_i & (~ndmreset)),
        .test_mode_i('0),
        .rst_no     (ndmreset_n),
        .init_no    ()
    );


    dm_obi_top #(
        .MIdWidth       (INITIATOR_ID_WIDTH),
        .SIdWidth       (TARGET_ID_WIDTH),
        .NrHarts        (1),
        .BusWidth       (32),
        .DmBaseAddress  (obi_pkg::DEBUG_ADDR),
        .SelectableHarts({NrHarts{1'b1}})
    ) i_dm_obi_top (
        .clk_i        (clk_i),
        .rst_ni       (~rst_i),
        .testmode_i   (testmode),
        .ndmreset_o   (ndmreset),
        .dmactive_o   (dmactive),
        .debug_req_o  (debug_req),
        .unavailable_i(unavailable),
        .hartinfo_i   (hartinfo),

        .slave_req_i   (targets[7].req),
        .slave_gnt_o   (targets[7].gnt),
        .slave_we_i    (targets[7].we),
        .slave_addr_i  (targets[7].addr),
        .slave_be_i    (targets[7].be),
        .slave_wdata_i (targets[7].wdata),
        .slave_aid_i   (targets[7].aid),
        .slave_rvalid_o(targets[7].rvalid),
        .slave_rdata_o (targets[7].rdata),
        .slave_rid_o   (targets[7].rid),

        .master_req_o      (initiators[2].req),
        .master_addr_o     (initiators[2].addr),
        .master_we_o       (initiators[2].we),
        .master_wdata_o    (initiators[2].wdata),
        .master_be_o       (initiators[2].be),
        .master_gnt_i      (initiators[2].gnt),
        .master_rvalid_i   (initiators[2].rvalid),
        .master_err_i      (initiators[2].err),
        .master_other_err_i(0),
        .master_rdata_i    (initiators[2].rdata),

        .dmi_rst_ni      (~rst_i),
        .dmi_req_valid_i (dmi_req_valid),
        .dmi_req_ready_o (dmi_req_ready),
        .dmi_req_i       (dmi_req),
        .dmi_resp_valid_o(dmi_resp_valid),
        .dmi_resp_ready_i(dmi_resp_ready),
        .dmi_resp_o      (dmi_resp)
    );


    logic jtag_tck;  // JTAG test clock pad
    logic jtag_tms;  // JTAG test mode select pad
    logic jtag_trst_n;  // JTAG test reset pad
    logic jtag_srst_n;  // JTAG test reset pad
    logic jtag_tdi;  // JTAG test data input pad
    logic jtag_tdo;  // JTAG test data output pad
    logic jtag_tdo_oe;  // Data out output enable

    dmi_jtag #(
        .IdcodeValue(32'h249511C3)
    ) i_dmi_jtag (
        .clk_i           (clk_i),           // DMI Clock
        .rst_ni          (~rst_i),          // Asynchronous reset active low
        .testmode_i      (testmode),
        .dmi_rst_no      (dmi_rst),
        .dmi_req_o       (dmi_req),
        .dmi_req_valid_o (dmi_req_valid),
        .dmi_req_ready_i (dmi_req_ready),
        .dmi_resp_i      (dmi_resp),
        .dmi_resp_ready_o(dmi_resp_ready),
        .dmi_resp_valid_i(dmi_resp_valid),
        .tck_i           (jtag_tck),        // JTAG test clock pad
        .tms_i           (jtag_tms),        // JTAG test mode select pad
        .trst_ni         (jtag_trst_n),     // JTAG test reset pad
        .td_i            (jtag_tdi),        // JTAG test data input pad
        .td_o            (jtag_tdo),        // JTAG test data output pad
        .tdo_oe_o        (jtag_tdo_oe)      // Data out output enable
    );

    jtagdpi #(
        .Name      ("jtag0"),
        .ListenPort(44853)
    ) i_jtagdpi (
        .clk_i      (clk_i),
        .rst_ni     (~rst_i),
        .jtag_tck   (jtag_tck),
        .jtag_tms   (jtag_tms),
        .jtag_tdi   (jtag_tdi),
        .jtag_tdo   (jtag_tdo),
        .jtag_trst_n(jtag_trst_n),
        .jtag_srst_n(jtag_srst_n)
    );
    `endif

    logic          [0:0] debug_req;  // async debug request
    ibex_debug i_ibex_debug (
        .clk_i      (clk_i),
        .rst_ni      (~rst_i),
        .debug_req_o      (debug_req),
        .ndmreset_no(ndmreset_n),
        .target     (targets[7]),
        .initiator  (initiators[2])
    );


    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------

    obi_xbar #(
        .N_INITIATORS(obi_pkg::N_INITIATORS),
        .N_TARGETS   (obi_pkg::N_TARGETS)
    ) i_obi_xbar (
        .rst_i,
        .clk_i,
        .initiators(initiators),
        .targets   (targets)
    );

    // ------------------------------------------------------------------------

    mtime32 i_mtime (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .dport       (targets[0]),
        .intr_o      (irq_i[7]),
        .clear_intr_i(0)
    );

    // ------------------------------------------------------------------------

    sim_ctrl i_sim_ctrl (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(targets[1])
    );

    // ------------------------------------------------------------------------

    obi_ram #(
        .ADDR_WIDTH(obi_pkg::ITCM_WIDTH)
    ) i_instr_ram (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(targets[2])
    );

    // ------------------------------------------------------------------------

    axi_if s_axi_dtcm ();
    obi_dtcm #(
        .DATA_WIDTH       (s_axi_dtcm.DATA_WIDTH),
        .ADDR_WIDTH       (obi_pkg::DTCM_WIDTH),
        .STRB_WIDTH       (s_axi_dtcm.STRB_WIDTH),
        .ID_WIDTH         (s_axi_dtcm.ID_WIDTH),
        .B_PIPELINE_OUTPUT(0),
        .B_INTERLEAVE     (0)
    ) i_obi_dtcm (
        .a_clk(clk_i),
        .a_rst(rst_i),
        .dport(targets[3]),
        .s_axi(s_axi_dtcm)
    );


    axi_if m_axi_cached ();
    obi2axi i_dport2axi_cached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(targets[4]),
        .m_axi(m_axi_cached)
    );

    axi_ram #(
        .DATA_WIDTH(m_axi_cached.DATA_WIDTH),
        .ADDR_WIDTH(obi_pkg::CACHED_WIDTH),
        .STRB_WIDTH(m_axi_cached.STRB_WIDTH),
        .ID_WIDTH  (m_axi_cached.ID_WIDTH)
    ) i_axi_cached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_cached.awid),
        .s_axi_awaddr (m_axi_cached.awaddr[obi_pkg::CACHED_WIDTH-1:0]),
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
        .s_axi_araddr (m_axi_cached.araddr[obi_pkg::CACHED_WIDTH-1:0]),
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
    obi2axi i_dport2axi_uncached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(targets[5]),
        .m_axi(m_axi_uncached)
    );

    axi_ram #(
        .DATA_WIDTH(m_axi_uncached.DATA_WIDTH),
        .ADDR_WIDTH(obi_pkg::UNCACHED_WIDTH),
        .STRB_WIDTH(m_axi_uncached.STRB_WIDTH),
        .ID_WIDTH  (m_axi_uncached.ID_WIDTH)
    ) i_axi_uncached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_uncached.awid),
        .s_axi_awaddr (m_axi_uncached.awaddr[obi_pkg::UNCACHED_WIDTH-1:0]),
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
        .s_axi_araddr (m_axi_uncached.araddr[obi_pkg::UNCACHED_WIDTH-1:0]),
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
    obi2axil i_dport2axil (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .dport (targets[6]),
        .m_axil(m_axil)
    );

    axil_ram #(
        .DATA_WIDTH     (m_axil.DATA_WIDTH),
        .ADDR_WIDTH     (obi_pkg::AXIL_WIDTH),
        .STRB_WIDTH     (m_axil.STRB_WIDTH),
        .PIPELINE_OUTPUT(0)
    ) i_axil_ram (
        .clk           (clk_i),
        .rst           (rst_i),
        .s_axil_awaddr (m_axil.awaddr[obi_pkg::AXIL_WIDTH-1:0]),
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
        .s_axil_araddr (m_axil.araddr[obi_pkg::AXIL_WIDTH-1:0]),
        .s_axil_arprot (m_axil.arprot),
        .s_axil_arvalid(m_axil.arvalid),
        .s_axil_arready(m_axil.arready),
        .s_axil_rdata  (m_axil.rdata),
        .s_axil_rresp  (m_axil.rresp),
        .s_axil_rvalid (m_axil.rvalid),
        .s_axil_rready (m_axil.rready)
    );



    // ------------------------------------------------------------------------

    function static void write_itcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            i_instr_ram.write(addr, data);
        end
    endfunction
    function static bit [7:0] read_itcm;  /*verilator public*/
        input [31:0] addr;
        begin
            read_itcm = i_instr_ram.read(addr);
        end
    endfunction

    function static void write_dtcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            i_obi_dtcm.write(addr, data);
        end
    endfunction
    function static bit [7:0] read_dtcm;  /*verilator public*/
        input [31:0] addr;
        begin
            read_dtcm = i_obi_dtcm.read(addr);
        end
    endfunction

    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end
endmodule : tb_ibex
