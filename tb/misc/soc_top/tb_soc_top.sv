module tb_soc_top #() ();

    localparam S_ID_WIDTH = 4;
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
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
    logic [               31:0] s_data_axi_araddr;
    logic [                1:0] s_data_axi_arburst;
    logic [     S_ID_WIDTH-1:0] s_data_axi_arid;
    logic [                7:0] s_data_axi_arlen;
    logic [                2:0] s_data_axi_arsize;
    logic                       s_data_axi_arready;
    logic                       s_data_axi_arvalid;
    logic [               31:0] s_data_axi_awaddr;
    logic [                1:0] s_data_axi_awburst;
    logic [     S_ID_WIDTH-1:0] s_data_axi_awid;
    logic [                7:0] s_data_axi_awlen;
    logic [                2:0] s_data_axi_awsize;
    logic                       s_data_axi_awready;
    logic                       s_data_axi_awvalid;
    logic [     S_ID_WIDTH-1:0] s_data_axi_bid;
    logic                       s_data_axi_bready;
    logic [                1:0] s_data_axi_bresp;
    logic                       s_data_axi_bvalid;
    logic [               31:0] s_data_axi_rdata;
    logic [     S_ID_WIDTH-1:0] s_data_axi_rid;
    logic                       s_data_axi_rlast;
    logic                       s_data_axi_rready;
    logic [                1:0] s_data_axi_rresp;
    logic                       s_data_axi_rvalid;
    logic [               31:0] s_data_axi_wdata;
    logic                       s_data_axi_wlast;
    logic                       s_data_axi_wready;
    logic [                3:0] s_data_axi_wstrb;
    logic                       s_data_axi_wvalid;
    logic [               31:0] s_instr_axi_araddr;
    logic [                1:0] s_instr_axi_arburst;
    logic [     S_ID_WIDTH-1:0] s_instr_axi_arid;
    logic [                7:0] s_instr_axi_arlen;
    logic [                2:0] s_instr_axi_arsize;
    logic                       s_instr_axi_arready;
    logic                       s_instr_axi_arvalid;
    logic [               31:0] s_instr_axi_awaddr;
    logic [                1:0] s_instr_axi_awburst;
    logic [     S_ID_WIDTH-1:0] s_instr_axi_awid;
    logic [                7:0] s_instr_axi_awlen;
    logic [                2:0] s_instr_axi_awsize;
    logic                       s_instr_axi_awready;
    logic                       s_instr_axi_awvalid;
    logic [     S_ID_WIDTH-1:0] s_instr_axi_bid;
    logic                       s_instr_axi_bready;
    logic [                1:0] s_instr_axi_bresp;
    logic                       s_instr_axi_bvalid;
    logic [               31:0] s_instr_axi_rdata;
    logic [     S_ID_WIDTH-1:0] s_instr_axi_rid;
    logic                       s_instr_axi_rlast;
    logic                       s_instr_axi_rready;
    logic [                1:0] s_instr_axi_rresp;
    logic                       s_instr_axi_rvalid;
    logic [               31:0] s_instr_axi_wdata;
    logic                       s_instr_axi_wlast;
    logic                       s_instr_axi_wready;
    logic [                3:0] s_instr_axi_wstrb;
    logic                       s_instr_axi_wvalid;
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


    soc_mem i_soc_mem (
        .clk                (i_clk),
        .rst                (i_reset),
        .s_data_axi_araddr  (s_data_axi_araddr),
        .s_data_axi_arburst (s_data_axi_arburst),
        .s_data_axi_arid    (s_data_axi_arid),
        .s_data_axi_arlen   (s_data_axi_arlen),
        .s_data_axi_arsize  (s_data_axi_arsize),
        .s_data_axi_arready (s_data_axi_arready),
        .s_data_axi_arvalid (s_data_axi_arvalid),
        .s_data_axi_awaddr  (s_data_axi_awaddr),
        .s_data_axi_awburst (s_data_axi_awburst),
        .s_data_axi_awid    (s_data_axi_awid),
        .s_data_axi_awlen   (s_data_axi_awlen),
        .s_data_axi_awsize  (s_data_axi_awsize),
        .s_data_axi_awready (s_data_axi_awready),
        .s_data_axi_awvalid (s_data_axi_awvalid),
        .s_data_axi_bid     (s_data_axi_bid),
        .s_data_axi_bready  (s_data_axi_bready),
        .s_data_axi_bresp   (s_data_axi_bresp),
        .s_data_axi_bvalid  (s_data_axi_bvalid),
        .s_data_axi_rdata   (s_data_axi_rdata),
        .s_data_axi_rid     (s_data_axi_rid),
        .s_data_axi_rlast   (s_data_axi_rlast),
        .s_data_axi_rready  (s_data_axi_rready),
        .s_data_axi_rresp   (s_data_axi_rresp),
        .s_data_axi_rvalid  (s_data_axi_rvalid),
        .s_data_axi_wdata   (s_data_axi_wdata),
        .s_data_axi_wlast   (s_data_axi_wlast),
        .s_data_axi_wready  (s_data_axi_wready),
        .s_data_axi_wstrb   (s_data_axi_wstrb),
        .s_data_axi_wvalid  (s_data_axi_wvalid),
        .s_instr_axi_araddr (s_instr_axi_araddr),
        .s_instr_axi_arburst(s_instr_axi_arburst),
        .s_instr_axi_arid   (s_instr_axi_arid),
        .s_instr_axi_arlen  (s_instr_axi_arlen),
        .s_instr_axi_arsize (s_instr_axi_arsize),
        .s_instr_axi_arready(s_instr_axi_arready),
        .s_instr_axi_arvalid(s_instr_axi_arvalid),
        .s_instr_axi_awaddr (s_instr_axi_awaddr),
        .s_instr_axi_awburst(s_instr_axi_awburst),
        .s_instr_axi_awid   (s_instr_axi_awid),
        .s_instr_axi_awlen  (s_instr_axi_awlen),
        .s_instr_axi_awsize (s_instr_axi_awsize),
        .s_instr_axi_awready(s_instr_axi_awready),
        .s_instr_axi_awvalid(s_instr_axi_awvalid),
        .s_instr_axi_bid    (s_instr_axi_bid),
        .s_instr_axi_bready (s_instr_axi_bready),
        .s_instr_axi_bresp  (s_instr_axi_bresp),
        .s_instr_axi_bvalid (s_instr_axi_bvalid),
        .s_instr_axi_rdata  (s_instr_axi_rdata),
        .s_instr_axi_rid    (s_instr_axi_rid),
        .s_instr_axi_rlast  (s_instr_axi_rlast),
        .s_instr_axi_rready (s_instr_axi_rready),
        .s_instr_axi_rresp  (s_instr_axi_rresp),
        .s_instr_axi_rvalid (s_instr_axi_rvalid),
        .s_instr_axi_wdata  (s_instr_axi_wdata),
        .s_instr_axi_wlast  (s_instr_axi_wlast),
        .s_instr_axi_wready (s_instr_axi_wready),
        .s_instr_axi_wstrb  (s_instr_axi_wstrb),
        .s_instr_axi_wvalid (s_instr_axi_wvalid),
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


endmodule : tb_soc_top

