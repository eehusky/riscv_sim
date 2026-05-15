module tb_rsd_soc_top #() ();

    localparam S_ID_WIDTH = 4;
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 64;
    localparam STRB_WIDTH = DATA_WIDTH / 8;
    localparam AWUSER_WIDTH = 1;
    localparam WUSER_WIDTH = 1;
    localparam BUSER_WIDTH = 1;
    localparam ARUSER_WIDTH = 1;
    localparam RUSER_WIDTH = 1;
    localparam AXIL_DATA_WIDTH = 32;
    localparam AXIL_STRB_WIDTH = AXIL_DATA_WIDTH / 8;

    logic                       i_clk;
    logic                       i_reset;

    logic [     S_ID_WIDTH-1:0] s_core_axi_awid;
    logic [     ADDR_WIDTH-1:0] s_core_axi_awaddr;
    logic [                7:0] s_core_axi_awlen;
    logic [                2:0] s_core_axi_awsize;
    logic [                1:0] s_core_axi_awburst;
    logic                       s_core_axi_awlock;
    logic [                3:0] s_core_axi_awcache;
    logic [                2:0] s_core_axi_awprot;
    logic [                3:0] s_core_axi_awqos;
    logic [   AWUSER_WIDTH-1:0] s_core_axi_awuser;
    logic                       s_core_axi_awvalid;
    logic                       s_core_axi_awready;
    logic [     DATA_WIDTH-1:0] s_core_axi_wdata;
    logic [     STRB_WIDTH-1:0] s_core_axi_wstrb;
    logic                       s_core_axi_wlast;
    logic [    WUSER_WIDTH-1:0] s_core_axi_wuser;
    logic                       s_core_axi_wvalid;
    logic                       s_core_axi_wready;
    logic [     S_ID_WIDTH-1:0] s_core_axi_bid;
    logic [                1:0] s_core_axi_bresp;
    logic [    BUSER_WIDTH-1:0] s_core_axi_buser;
    logic                       s_core_axi_bvalid;
    logic                       s_core_axi_bready;
    logic [     S_ID_WIDTH-1:0] s_core_axi_arid;
    logic [     ADDR_WIDTH-1:0] s_core_axi_araddr;
    logic [                7:0] s_core_axi_arlen;
    logic [                2:0] s_core_axi_arsize;
    logic [                1:0] s_core_axi_arburst;
    logic                       s_core_axi_arlock;
    logic [                3:0] s_core_axi_arcache;
    logic [                2:0] s_core_axi_arprot;
    logic [                3:0] s_core_axi_arqos;
    logic [   ARUSER_WIDTH-1:0] s_core_axi_aruser;
    logic                       s_core_axi_arvalid;
    logic                       s_core_axi_arready;
    logic [     S_ID_WIDTH-1:0] s_core_axi_rid;
    logic [     DATA_WIDTH-1:0] s_core_axi_rdata;
    logic [                1:0] s_core_axi_rresp;
    logic                       s_core_axi_rlast;
    logic [    RUSER_WIDTH-1:0] s_core_axi_ruser;
    logic                       s_core_axi_rvalid;
    logic                       s_core_axi_rready;

    logic [     S_ID_WIDTH-1:0] s_axi_awid;
    logic [     ADDR_WIDTH-1:0] s_axi_awaddr;
    logic [                7:0] s_axi_awlen;
    logic [                2:0] s_axi_awsize;
    logic [                1:0] s_axi_awburst;
    logic                       s_axi_awlock;
    logic [                3:0] s_axi_awcache;
    logic [                2:0] s_axi_awprot;
    logic [                3:0] s_axi_awqos;
    logic [   AWUSER_WIDTH-1:0] s_axi_awuser;
    logic                       s_axi_awvalid;
    logic                       s_axi_awready;
    logic [     DATA_WIDTH-1:0] s_axi_wdata;
    logic [     STRB_WIDTH-1:0] s_axi_wstrb;
    logic                       s_axi_wlast;
    logic [    WUSER_WIDTH-1:0] s_axi_wuser;
    logic                       s_axi_wvalid;
    logic                       s_axi_wready;
    logic [     S_ID_WIDTH-1:0] s_axi_bid;
    logic [                1:0] s_axi_bresp;
    logic [    BUSER_WIDTH-1:0] s_axi_buser;
    logic                       s_axi_bvalid;
    logic                       s_axi_bready;
    logic [     S_ID_WIDTH-1:0] s_axi_arid;
    logic [     ADDR_WIDTH-1:0] s_axi_araddr;
    logic [                7:0] s_axi_arlen;
    logic [                2:0] s_axi_arsize;
    logic [                1:0] s_axi_arburst;
    logic                       s_axi_arlock;
    logic [                3:0] s_axi_arcache;
    logic [                2:0] s_axi_arprot;
    logic [                3:0] s_axi_arqos;
    logic [   ARUSER_WIDTH-1:0] s_axi_aruser;
    logic                       s_axi_arvalid;
    logic                       s_axi_arready;
    logic [     S_ID_WIDTH-1:0] s_axi_rid;
    logic [     DATA_WIDTH-1:0] s_axi_rdata;
    logic [                1:0] s_axi_rresp;
    logic                       s_axi_rlast;
    logic [    RUSER_WIDTH-1:0] s_axi_ruser;
    logic                       s_axi_rvalid;
    logic                       s_axi_rready;
    logic [     ADDR_WIDTH-1:0] m_axil_awaddr;
    logic [                2:0] m_axil_awprot;
    logic                       m_axil_awvalid;
    logic                       m_axil_awready;
    logic [AXIL_DATA_WIDTH-1:0] m_axil_wdata;
    logic [AXIL_STRB_WIDTH-1:0] m_axil_wstrb;
    logic                       m_axil_wvalid;
    logic                       m_axil_wready;
    logic [                1:0] m_axil_bresp;
    logic                       m_axil_bvalid;
    logic                       m_axil_bready;
    logic [     ADDR_WIDTH-1:0] m_axil_araddr;
    logic [                2:0] m_axil_arprot;
    logic                       m_axil_arvalid;
    logic                       m_axil_arready;
    logic [AXIL_DATA_WIDTH-1:0] m_axil_rdata;
    logic [                1:0] m_axil_rresp;
    logic                       m_axil_rvalid;
    logic                       m_axil_rready;


    rsd_soc_mem i_rsd_soc_mem (
        .clk                (i_clk),
        .rst                (i_reset),
        .s_core_axi_awid(s_core_axi_awid),
        .s_core_axi_awaddr(s_core_axi_awaddr),
        .s_core_axi_awlen(s_core_axi_awlen),
        .s_core_axi_awsize(s_core_axi_awsize),
        .s_core_axi_awburst(s_core_axi_awburst),
        .s_core_axi_awlock(s_core_axi_awlock),
        .s_core_axi_awcache(s_core_axi_awcache),
        .s_core_axi_awprot(s_core_axi_awprot),
        .s_core_axi_awqos(s_core_axi_awqos),
        .s_core_axi_awuser(s_core_axi_awuser),
        .s_core_axi_awvalid(s_core_axi_awvalid),
        .s_core_axi_awready(s_core_axi_awready),
        .s_core_axi_wdata(s_core_axi_wdata),
        .s_core_axi_wstrb(s_core_axi_wstrb),
        .s_core_axi_wlast(s_core_axi_wlast),
        .s_core_axi_wuser(s_core_axi_wuser),
        .s_core_axi_wvalid(s_core_axi_wvalid),
        .s_core_axi_wready(s_core_axi_wready),
        .s_core_axi_bid(s_core_axi_bid),
        .s_core_axi_bresp(s_core_axi_bresp),
        .s_core_axi_buser(s_core_axi_buser),
        .s_core_axi_bvalid(s_core_axi_bvalid),
        .s_core_axi_bready(s_core_axi_bready),
        .s_core_axi_arid(s_core_axi_arid),
        .s_core_axi_araddr(s_core_axi_araddr),
        .s_core_axi_arlen(s_core_axi_arlen),
        .s_core_axi_arsize(s_core_axi_arsize),
        .s_core_axi_arburst(s_core_axi_arburst),
        .s_core_axi_arlock(s_core_axi_arlock),
        .s_core_axi_arcache(s_core_axi_arcache),
        .s_core_axi_arprot(s_core_axi_arprot),
        .s_core_axi_arqos(s_core_axi_arqos),
        .s_core_axi_aruser(s_core_axi_aruser),
        .s_core_axi_arvalid(s_core_axi_arvalid),
        .s_core_axi_arready(s_core_axi_arready),
        .s_core_axi_rid(s_core_axi_rid),
        .s_core_axi_rdata(s_core_axi_rdata),
        .s_core_axi_rresp(s_core_axi_rresp),
        .s_core_axi_rlast(s_core_axi_rlast),
        .s_core_axi_ruser(s_core_axi_ruser),
        .s_core_axi_rvalid(s_core_axi_rvalid),
        .s_core_axi_rready(s_core_axi_rready),

        .s_axi_awid         (s_axi_awid),
        .s_axi_awaddr       (s_axi_awaddr),
        .s_axi_awlen        (s_axi_awlen),
        .s_axi_awsize       (s_axi_awsize),
        .s_axi_awburst      (s_axi_awburst),
        .s_axi_awlock       (s_axi_awlock),
        .s_axi_awcache      (s_axi_awcache),
        .s_axi_awprot       (s_axi_awprot),
        .s_axi_awqos        (s_axi_awqos),
        .s_axi_awuser       (s_axi_awuser),
        .s_axi_awvalid      (s_axi_awvalid),
        .s_axi_awready      (s_axi_awready),
        .s_axi_wdata        (s_axi_wdata),
        .s_axi_wstrb        (s_axi_wstrb),
        .s_axi_wlast        (s_axi_wlast),
        .s_axi_wuser        (s_axi_wuser),
        .s_axi_wvalid       (s_axi_wvalid),
        .s_axi_wready       (s_axi_wready),
        .s_axi_bid          (s_axi_bid),
        .s_axi_bresp        (s_axi_bresp),
        .s_axi_buser        (s_axi_buser),
        .s_axi_bvalid       (s_axi_bvalid),
        .s_axi_bready       (s_axi_bready),
        .s_axi_arid         (s_axi_arid),
        .s_axi_araddr       (s_axi_araddr),
        .s_axi_arlen        (s_axi_arlen),
        .s_axi_arsize       (s_axi_arsize),
        .s_axi_arburst      (s_axi_arburst),
        .s_axi_arlock       (s_axi_arlock),
        .s_axi_arcache      (s_axi_arcache),
        .s_axi_arprot       (s_axi_arprot),
        .s_axi_arqos        (s_axi_arqos),
        .s_axi_aruser       (s_axi_aruser),
        .s_axi_arvalid      (s_axi_arvalid),
        .s_axi_arready      (s_axi_arready),
        .s_axi_rid          (s_axi_rid),
        .s_axi_rdata        (s_axi_rdata),
        .s_axi_rresp        (s_axi_rresp),
        .s_axi_rlast        (s_axi_rlast),
        .s_axi_ruser        (s_axi_ruser),
        .s_axi_rvalid       (s_axi_rvalid),
        .s_axi_rready       (s_axi_rready),
        .m_axil_awaddr      (m_axil_awaddr),
        .m_axil_awprot      (m_axil_awprot),
        .m_axil_awvalid     (m_axil_awvalid),
        .m_axil_awready     (m_axil_awready),
        .m_axil_wdata       (m_axil_wdata),
        .m_axil_wstrb       (m_axil_wstrb),
        .m_axil_wvalid      (m_axil_wvalid),
        .m_axil_wready      (m_axil_wready),
        .m_axil_bresp       (m_axil_bresp),
        .m_axil_bvalid      (m_axil_bvalid),
        .m_axil_bready      (m_axil_bready),
        .m_axil_araddr      (m_axil_araddr),
        .m_axil_arprot      (m_axil_arprot),
        .m_axil_arvalid     (m_axil_arvalid),
        .m_axil_arready     (m_axil_arready),
        .m_axil_rdata       (m_axil_rdata),
        .m_axil_rresp       (m_axil_rresp),
        .m_axil_rvalid      (m_axil_rvalid),
        .m_axil_rready      (m_axil_rready)
    );


endmodule : tb_rsd_soc_top

