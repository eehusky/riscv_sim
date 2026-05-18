//import dport_pkg::*;
module tb_dport ();
    localparam bit [31:0] N_SEGMENTS = dport_pkg::N_SEGMENTS;
    localparam bit [31:0] LGN_SEGMENTS = $clog2(dport_pkg::N_SEGMENTS);
    //
    localparam bit [31:0] MTIME_ADDR = dport_pkg::MTIME_ADDR;
    localparam bit [31:0] MTIME_SIZE = dport_pkg::MTIME_SIZE;
    localparam bit [31:0] MTIME_WIDTH = dport_pkg::MTIME_WIDTH;
    localparam bit [31:0] MTIME_MASK = dport_pkg::MTIME_MASK;
    localparam bit [31:0] SIMCTRL_ADDR = dport_pkg::SIMCTRL_ADDR;
    localparam bit [31:0] SIMCTRL_SIZE = dport_pkg::SIMCTRL_SIZE;
    localparam bit [31:0] SIMCTRL_WIDTH = dport_pkg::SIMCTRL_WIDTH;
    localparam bit [31:0] SIMCTRL_MASK = dport_pkg::SIMCTRL_MASK;
    //
    localparam bit [31:0] DTCM_ADDR = dport_pkg::DTCM_ADDR;
    localparam bit [31:0] DTCM_SIZE = dport_pkg::DTCM_SIZE;
    localparam bit [31:0] DTCM_WIDTH = dport_pkg::DTCM_WIDTH;
    localparam bit [31:0] DTCM_MASK = dport_pkg::DTCM_MASK;
    //
    localparam bit [31:0] CACHED_ADDR = dport_pkg::CACHED_ADDR;
    localparam bit [31:0] CACHED_SIZE = dport_pkg::CACHED_SIZE;
    localparam bit [31:0] CACHED_WIDTH = dport_pkg::CACHED_WIDTH;
    localparam bit [31:0] CACHED_MASK = dport_pkg::CACHED_MASK;
    localparam bit [31:0] UNCACHED_ADDR = dport_pkg::UNCACHED_ADDR;
    localparam bit [31:0] UNCACHED_SIZE = dport_pkg::UNCACHED_SIZE;
    localparam bit [31:0] UNCACHED_WIDTH = dport_pkg::UNCACHED_WIDTH;
    localparam bit [31:0] UNCACHED_MASK = dport_pkg::UNCACHED_MASK;
    localparam bit [31:0] AXIL_ADDR = dport_pkg::AXIL_ADDR;
    localparam bit [31:0] AXIL_SIZE = dport_pkg::AXIL_SIZE;
    localparam bit [31:0] AXIL_WIDTH = dport_pkg::AXIL_WIDTH;
    localparam bit [31:0] AXIL_MASK = dport_pkg::AXIL_MASK;

    logic rst_i;
    logic clk_i;


    obi_if #(.ID_WIDTH(2)) initiators[3] ();
    obi_if #(.ID_WIDTH(2+3-1)) target ();
    dport_mux #(3) i_dport_mux (
        .rst_i,
        .clk_i,
        .initiators,
        .target
    );
    dport_ram #(
        .ADDR_WIDTH(dport_pkg::MTIME_WIDTH)
    ) i_mux_dummy_ram (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(target)
    );


    obi_if #(.ID_WIDTH(2)) initiator ();
    obi_if #(.ID_WIDTH(2)) segments[N_SEGMENTS] ();

    dport_demux i_dport_demux (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .cpu     (initiator),
        .segments(segments)
    );

    // ------------------------------------------------------------------------

    dport_ram #(
        .ADDR_WIDTH(dport_pkg::MTIME_WIDTH)
    ) i_dport_mtime (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[0])
    );

    // ------------------------------------------------------------------------

    dport_ram #(
        .ADDR_WIDTH(dport_pkg::SIMCTRL_WIDTH)
    ) i_dport_simctrl (
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

    axil_ram #(
        .DATA_WIDTH     (m_axil.DATA_WIDTH),
        .ADDR_WIDTH     (dport_pkg::AXIL_WIDTH),
        .STRB_WIDTH     (m_axil.STRB_WIDTH),
        .PIPELINE_OUTPUT(0)
    ) i_axil_ram (
        .clk           (clk_i),
        .rst           (rst_i),
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
        .s_axil_rready (m_axil.rready)
    );
endmodule : tb_dport
