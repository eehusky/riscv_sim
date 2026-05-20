module ibex_debug (
    input  logic         clk_i,
    input  logic         rst_ni,
    output  logic  [0:0]   debug_req_o,
    output logic         ndmreset_no,
           obi_if.slave  target,
           obi_if.master initiator
);
    localparam dm::hartinfo_t HARTINFO = {8'h0, 4'h2, 3'b0, 1'b1, dm::DataCount, dm::DataAddr};
    localparam int NrHarts = 1;

    logic                        testmode;
    logic                        ndmreset;  // non-debug module reset
    logic                        dmactive;  // debug module is active
    logic          [NrHarts-1:0] debug_req;  // async debug request
    logic          [NrHarts-1:0] unavailable;

    logic                        dmi_rst;
    logic                        dmi_req_valid;
    logic                        dmi_req_ready;
    dm::dmi_req_t                dmi_req;
    logic                        dmi_resp_valid;
    logic                        dmi_resp_ready;
    dm::dmi_resp_t               dmi_resp;

    assign unavailable          = 0;
    assign initiators[2].rready = 1;

    // reset handling with ndmreset
    rstgen i_rstgen_main (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni & (~ndmreset)),
        .test_mode_i('0),
        .rst_no     (ndmreset_no),
        .init_no    ()
    );

    dm_obi_top #(
        .MIdWidth       (initiator.ID_WIDTH),
        .SIdWidth       (target.ID_WIDTH),
        .NrHarts        (1),
        .BusWidth       (32),
        .DmBaseAddress  (obi_pkg::DEBUG_ADDR),
        .SelectableHarts({NrHarts{1'b1}})
    ) i_dm_obi_top (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .testmode_i   (testmode),
        .ndmreset_o   (ndmreset),
        .dmactive_o   (dmactive),
        .debug_req_o  (debug_req_o),
        .unavailable_i(unavailable),
        .hartinfo_i   (HARTINFO),

        .slave_req_i   (target.req),
        .slave_gnt_o   (target.gnt),
        .slave_we_i    (target.we),
        .slave_addr_i  (target.addr),
        .slave_be_i    (target.be),
        .slave_wdata_i (target.wdata),
        .slave_aid_i   (target.aid),
        .slave_rvalid_o(target.rvalid),
        .slave_rdata_o (target.rdata),
        .slave_rid_o   (target.rid),

        .master_req_o      (initiator.req),
        .master_addr_o     (initiator.addr),
        .master_we_o       (initiator.we),
        .master_wdata_o    (initiator.wdata),
        .master_be_o       (initiator.be),
        .master_gnt_i      (initiator.gnt),
        .master_rvalid_i   (initiator.rvalid),
        .master_err_i      (initiator.err),
        .master_other_err_i(0),
        .master_rdata_i    (initiator.rdata),

        .dmi_rst_ni      (rst_ni),
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
        .rst_ni          (rst_ni),          // Asynchronous reset active low
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
        .rst_ni     (rst_ni),
        .jtag_tck   (jtag_tck),
        .jtag_tms   (jtag_tms),
        .jtag_tdi   (jtag_tdi),
        .jtag_tdo   (jtag_tdo),
        .jtag_trst_n(jtag_trst_n),
        .jtag_srst_n(jtag_srst_n)
    );


endmodule : ibex_debug
