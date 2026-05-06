module tb_dport ();
    parameter int AXI_ADDR_W = 32;
    parameter int AXI_DATA_W = 32;
    parameter int AXI_ID_W = 4;
    parameter int AXI_LEN_W = 8;
    parameter int AXIL_DATA_WIDTH = 32;
    parameter int AXIL_STRB_WIDTH = 4;

    logic                       rst_i;
    logic                       clk_i;
    logic                       mem_accept_o;
    logic                       mem_ack_o;
    logic [               31:0] mem_data_rd_o;
    logic [               31:0] mem_addr_i;
    logic [               31:0] mem_data_wr_i;
    logic                       mem_error_o;
    logic                       mem_rd_i;
    logic [                3:0] mem_wr_i;
    logic [               10:0] mem_req_tag_i;
    logic [               10:0] mem_resp_tag_o;
    logic                       mem_cacheable_i;
    logic                       mem_invalidate_i;
    logic                       mem_writeback_i;
    logic                       mem_flush_i;
    logic                       periph_accept_i;
    logic                       periph_ack_i;
    logic [               31:0] periph_data_rd_i;
    logic [               31:0] periph_addr_o;
    logic [               31:0] periph_data_wr_o;
    logic                       periph_error_i;
    logic                       periph_rd_o;
    logic [                3:0] periph_wr_o;
    logic [     AXI_ADDR_W-1:0] s_axi_dtcm_araddr;
    logic [                1:0] s_axi_dtcm_arburst;
    logic [                3:0] s_axi_dtcm_arcache;
    logic [       AXI_ID_W-1:0] s_axi_dtcm_arid;
    logic [      AXI_LEN_W-1:0] s_axi_dtcm_arlen;
    logic                       s_axi_dtcm_arlock;
    logic [                2:0] s_axi_dtcm_arprot;
    logic                       s_axi_dtcm_arready;
    logic [                2:0] s_axi_dtcm_arsize;
    logic                       s_axi_dtcm_arvalid;
    logic [     AXI_ADDR_W-1:0] s_axi_dtcm_awaddr;
    logic [                1:0] s_axi_dtcm_awburst;
    logic [                3:0] s_axi_dtcm_awcache;
    logic [       AXI_ID_W-1:0] s_axi_dtcm_awid;
    logic [      AXI_LEN_W-1:0] s_axi_dtcm_awlen;
    logic                       s_axi_dtcm_awlock;
    logic [                2:0] s_axi_dtcm_awprot;
    logic                       s_axi_dtcm_awready;
    logic [                2:0] s_axi_dtcm_awsize;
    logic                       s_axi_dtcm_awvalid;
    logic [       AXI_ID_W-1:0] s_axi_dtcm_bid;
    logic                       s_axi_dtcm_bready;
    logic [                1:0] s_axi_dtcm_bresp;
    logic                       s_axi_dtcm_bvalid;
    logic [     AXI_DATA_W-1:0] s_axi_dtcm_rdata;
    logic [       AXI_ID_W-1:0] s_axi_dtcm_rid;
    logic                       s_axi_dtcm_rlast;
    logic                       s_axi_dtcm_rready;
    logic [                1:0] s_axi_dtcm_rresp;
    logic                       s_axi_dtcm_rvalid;
    logic [     AXI_DATA_W-1:0] s_axi_dtcm_wdata;
    logic                       s_axi_dtcm_wlast;
    logic                       s_axi_dtcm_wready;
    logic [   AXI_DATA_W/8-1:0] s_axi_dtcm_wstrb;
    logic                       s_axi_dtcm_wvalid;
    logic [     AXI_ADDR_W-1:0] m_axi_cached_araddr;
    logic [              2-1:0] m_axi_cached_arburst;
    logic [              4-1:0] m_axi_cached_arcache;
    logic [                2:0] m_axi_cached_arprot;
    logic [       AXI_ID_W-1:0] m_axi_cached_arid;
    logic [      AXI_LEN_W-1:0] m_axi_cached_arlen;
    logic                       m_axi_cached_arlock;
    logic [              4-1:0] m_axi_cached_arqos;
    logic                       m_axi_cached_arready;
    logic [              3-1:0] m_axi_cached_arsize;
    logic                       m_axi_cached_arvalid;
    logic [     AXI_ADDR_W-1:0] m_axi_cached_awaddr;
    logic [              2-1:0] m_axi_cached_awburst;
    logic [              4-1:0] m_axi_cached_awcache;
    logic [                2:0] m_axi_cached_awprot;
    logic [       AXI_ID_W-1:0] m_axi_cached_awid;
    logic [      AXI_LEN_W-1:0] m_axi_cached_awlen;
    logic                       m_axi_cached_awlock;
    logic [              4-1:0] m_axi_cached_awqos;
    logic                       m_axi_cached_awready;
    logic [              3-1:0] m_axi_cached_awsize;
    logic                       m_axi_cached_awvalid;
    logic [       AXI_ID_W-1:0] m_axi_cached_bid;
    logic                       m_axi_cached_bready;
    logic [              2-1:0] m_axi_cached_bresp;
    logic                       m_axi_cached_bvalid;
    logic [     AXI_DATA_W-1:0] m_axi_cached_rdata;
    logic [       AXI_ID_W-1:0] m_axi_cached_rid;
    logic                       m_axi_cached_rlast;
    logic                       m_axi_cached_rready;
    logic [              2-1:0] m_axi_cached_rresp;
    logic                       m_axi_cached_rvalid;
    logic [     AXI_DATA_W-1:0] m_axi_cached_wdata;
    logic                       m_axi_cached_wlast;
    logic                       m_axi_cached_wready;
    logic [   AXI_DATA_W/8-1:0] m_axi_cached_wstrb;
    logic                       m_axi_cached_wvalid;
    logic [     AXI_ADDR_W-1:0] m_axi_uncached_araddr;
    logic [              2-1:0] m_axi_uncached_arburst;
    logic [              4-1:0] m_axi_uncached_arcache;
    logic [                2:0] m_axi_uncached_arprot;
    logic [       AXI_ID_W-1:0] m_axi_uncached_arid;
    logic [      AXI_LEN_W-1:0] m_axi_uncached_arlen;
    logic                       m_axi_uncached_arlock;
    logic [              4-1:0] m_axi_uncached_arqos;
    logic                       m_axi_uncached_arready;
    logic [              3-1:0] m_axi_uncached_arsize;
    logic                       m_axi_uncached_arvalid;
    logic [     AXI_ADDR_W-1:0] m_axi_uncached_awaddr;
    logic [              2-1:0] m_axi_uncached_awburst;
    logic [              4-1:0] m_axi_uncached_awcache;
    logic [                2:0] m_axi_uncached_awprot;
    logic [       AXI_ID_W-1:0] m_axi_uncached_awid;
    logic [      AXI_LEN_W-1:0] m_axi_uncached_awlen;
    logic                       m_axi_uncached_awlock;
    logic [              4-1:0] m_axi_uncached_awqos;
    logic                       m_axi_uncached_awready;
    logic [              3-1:0] m_axi_uncached_awsize;
    logic                       m_axi_uncached_awvalid;
    logic [       AXI_ID_W-1:0] m_axi_uncached_bid;
    logic                       m_axi_uncached_bready;
    logic [              2-1:0] m_axi_uncached_bresp;
    logic                       m_axi_uncached_bvalid;
    logic [     AXI_DATA_W-1:0] m_axi_uncached_rdata;
    logic [       AXI_ID_W-1:0] m_axi_uncached_rid;
    logic                       m_axi_uncached_rlast;
    logic                       m_axi_uncached_rready;
    logic [              2-1:0] m_axi_uncached_rresp;
    logic                       m_axi_uncached_rvalid;
    logic [     AXI_DATA_W-1:0] m_axi_uncached_wdata;
    logic                       m_axi_uncached_wlast;
    logic                       m_axi_uncached_wready;
    logic [   AXI_DATA_W/8-1:0] m_axi_uncached_wstrb;
    logic                       m_axi_uncached_wvalid;
    logic [     AXI_ADDR_W-1:0] m_axil_araddr;
    logic [                2:0] m_axil_arprot;
    logic                       m_axil_arready;
    logic                       m_axil_arvalid;
    logic [     AXI_ADDR_W-1:0] m_axil_awaddr;
    logic [                2:0] m_axil_awprot;
    logic                       m_axil_awready;
    logic                       m_axil_awvalid;
    logic                       m_axil_bready;
    logic [                1:0] m_axil_bresp;
    logic                       m_axil_bvalid;
    logic [AXIL_DATA_WIDTH-1:0] m_axil_rdata;
    logic                       m_axil_rready;
    logic [                1:0] m_axil_rresp;
    logic                       m_axil_rvalid;
    logic [AXIL_DATA_WIDTH-1:0] m_axil_wdata;
    logic                       m_axil_wready;
    logic [AXIL_STRB_WIDTH-1:0] m_axil_wstrb;
    logic                       m_axil_wvalid;


    mem_dport_axi i_mem_dport_axi (
        .rst_i                 (rst_i),
        .clk_i                 (clk_i),
        .mem_accept_o          (mem_accept_o),
        .mem_ack_o             (mem_ack_o),
        .mem_data_rd_o         (mem_data_rd_o),
        .mem_addr_i            (mem_addr_i),
        .mem_data_wr_i         (mem_data_wr_i),
        .mem_error_o           (mem_error_o),
        .mem_rd_i              (mem_rd_i),
        .mem_wr_i              (mem_wr_i),
        .mem_req_tag_i         (mem_req_tag_i),
        .mem_resp_tag_o        (mem_resp_tag_o),
        .mem_cacheable_i       (mem_cacheable_i),
        .mem_invalidate_i      (mem_invalidate_i),
        .mem_writeback_i       (mem_writeback_i),
        .mem_flush_i           (mem_flush_i),
        .periph_accept_i       (periph_accept_i),
        .periph_ack_i          (periph_ack_i),
        .periph_data_rd_i      (periph_data_rd_i),
        .periph_addr_o         (periph_addr_o),
        .periph_data_wr_o      (periph_data_wr_o),
        .periph_error_i        (periph_error_i),
        .periph_rd_o           (periph_rd_o),
        .periph_wr_o           (periph_wr_o),
        .s_axi_dtcm_araddr     (s_axi_dtcm_araddr),
        .s_axi_dtcm_arburst    (s_axi_dtcm_arburst),
        .s_axi_dtcm_arcache    (s_axi_dtcm_arcache),
        .s_axi_dtcm_arid       (s_axi_dtcm_arid),
        .s_axi_dtcm_arlen      (s_axi_dtcm_arlen),
        .s_axi_dtcm_arlock     (s_axi_dtcm_arlock),
        .s_axi_dtcm_arprot     (s_axi_dtcm_arprot),
        .s_axi_dtcm_arready    (s_axi_dtcm_arready),
        .s_axi_dtcm_arsize     (s_axi_dtcm_arsize),
        .s_axi_dtcm_arvalid    (s_axi_dtcm_arvalid),
        .s_axi_dtcm_awaddr     (s_axi_dtcm_awaddr),
        .s_axi_dtcm_awburst    (s_axi_dtcm_awburst),
        .s_axi_dtcm_awcache    (s_axi_dtcm_awcache),
        .s_axi_dtcm_awid       (s_axi_dtcm_awid),
        .s_axi_dtcm_awlen      (s_axi_dtcm_awlen),
        .s_axi_dtcm_awlock     (s_axi_dtcm_awlock),
        .s_axi_dtcm_awprot     (s_axi_dtcm_awprot),
        .s_axi_dtcm_awready    (s_axi_dtcm_awready),
        .s_axi_dtcm_awsize     (s_axi_dtcm_awsize),
        .s_axi_dtcm_awvalid    (s_axi_dtcm_awvalid),
        .s_axi_dtcm_bid        (s_axi_dtcm_bid),
        .s_axi_dtcm_bready     (s_axi_dtcm_bready),
        .s_axi_dtcm_bresp      (s_axi_dtcm_bresp),
        .s_axi_dtcm_bvalid     (s_axi_dtcm_bvalid),
        .s_axi_dtcm_rdata      (s_axi_dtcm_rdata),
        .s_axi_dtcm_rid        (s_axi_dtcm_rid),
        .s_axi_dtcm_rlast      (s_axi_dtcm_rlast),
        .s_axi_dtcm_rready     (s_axi_dtcm_rready),
        .s_axi_dtcm_rresp      (s_axi_dtcm_rresp),
        .s_axi_dtcm_rvalid     (s_axi_dtcm_rvalid),
        .s_axi_dtcm_wdata      (s_axi_dtcm_wdata),
        .s_axi_dtcm_wlast      (s_axi_dtcm_wlast),
        .s_axi_dtcm_wready     (s_axi_dtcm_wready),
        .s_axi_dtcm_wstrb      (s_axi_dtcm_wstrb),
        .s_axi_dtcm_wvalid     (s_axi_dtcm_wvalid),
        .m_axi_cached_araddr   (m_axi_cached_araddr),
        .m_axi_cached_arburst  (m_axi_cached_arburst),
        .m_axi_cached_arcache  (m_axi_cached_arcache),
        .m_axi_cached_arid     (m_axi_cached_arid),
        .m_axi_cached_arlen    (m_axi_cached_arlen),
        .m_axi_cached_arlock   (m_axi_cached_arlock),
        .m_axi_cached_arqos    (m_axi_cached_arqos),
        .m_axi_cached_arready  (m_axi_cached_arready),
        .m_axi_cached_arsize   (m_axi_cached_arsize),
        .m_axi_cached_arvalid  (m_axi_cached_arvalid),
        .m_axi_cached_awaddr   (m_axi_cached_awaddr),
        .m_axi_cached_awburst  (m_axi_cached_awburst),
        .m_axi_cached_awcache  (m_axi_cached_awcache),
        .m_axi_cached_awid     (m_axi_cached_awid),
        .m_axi_cached_awlen    (m_axi_cached_awlen),
        .m_axi_cached_awlock   (m_axi_cached_awlock),
        .m_axi_cached_awqos    (m_axi_cached_awqos),
        .m_axi_cached_awready  (m_axi_cached_awready),
        .m_axi_cached_awsize   (m_axi_cached_awsize),
        .m_axi_cached_awvalid  (m_axi_cached_awvalid),
        .m_axi_cached_bid      (m_axi_cached_bid),
        .m_axi_cached_bready   (m_axi_cached_bready),
        .m_axi_cached_bresp    (m_axi_cached_bresp),
        .m_axi_cached_bvalid   (m_axi_cached_bvalid),
        .m_axi_cached_rdata    (m_axi_cached_rdata),
        .m_axi_cached_rid      (m_axi_cached_rid),
        .m_axi_cached_rlast    (m_axi_cached_rlast),
        .m_axi_cached_rready   (m_axi_cached_rready),
        .m_axi_cached_rresp    (m_axi_cached_rresp),
        .m_axi_cached_rvalid   (m_axi_cached_rvalid),
        .m_axi_cached_wdata    (m_axi_cached_wdata),
        .m_axi_cached_wlast    (m_axi_cached_wlast),
        .m_axi_cached_wready   (m_axi_cached_wready),
        .m_axi_cached_wstrb    (m_axi_cached_wstrb),
        .m_axi_cached_wvalid   (m_axi_cached_wvalid),
        .m_axi_uncached_araddr (m_axi_uncached_araddr),
        .m_axi_uncached_arburst(m_axi_uncached_arburst),
        .m_axi_uncached_arcache(m_axi_uncached_arcache),
        .m_axi_uncached_arid   (m_axi_uncached_arid),
        .m_axi_uncached_arlen  (m_axi_uncached_arlen),
        .m_axi_uncached_arlock (m_axi_uncached_arlock),
        .m_axi_uncached_arqos  (m_axi_uncached_arqos),
        .m_axi_uncached_arready(m_axi_uncached_arready),
        .m_axi_uncached_arsize (m_axi_uncached_arsize),
        .m_axi_uncached_arvalid(m_axi_uncached_arvalid),
        .m_axi_uncached_awaddr (m_axi_uncached_awaddr),
        .m_axi_uncached_awburst(m_axi_uncached_awburst),
        .m_axi_uncached_awcache(m_axi_uncached_awcache),
        .m_axi_uncached_awid   (m_axi_uncached_awid),
        .m_axi_uncached_awlen  (m_axi_uncached_awlen),
        .m_axi_uncached_awlock (m_axi_uncached_awlock),
        .m_axi_uncached_awqos  (m_axi_uncached_awqos),
        .m_axi_uncached_awready(m_axi_uncached_awready),
        .m_axi_uncached_awsize (m_axi_uncached_awsize),
        .m_axi_uncached_awvalid(m_axi_uncached_awvalid),
        .m_axi_uncached_bid    (m_axi_uncached_bid),
        .m_axi_uncached_bready (m_axi_uncached_bready),
        .m_axi_uncached_bresp  (m_axi_uncached_bresp),
        .m_axi_uncached_bvalid (m_axi_uncached_bvalid),
        .m_axi_uncached_rdata  (m_axi_uncached_rdata),
        .m_axi_uncached_rid    (m_axi_uncached_rid),
        .m_axi_uncached_rlast  (m_axi_uncached_rlast),
        .m_axi_uncached_rready (m_axi_uncached_rready),
        .m_axi_uncached_rresp  (m_axi_uncached_rresp),
        .m_axi_uncached_rvalid (m_axi_uncached_rvalid),
        .m_axi_uncached_wdata  (m_axi_uncached_wdata),
        .m_axi_uncached_wlast  (m_axi_uncached_wlast),
        .m_axi_uncached_wready (m_axi_uncached_wready),
        .m_axi_uncached_wstrb  (m_axi_uncached_wstrb),
        .m_axi_uncached_wvalid (m_axi_uncached_wvalid),
        .m_axil_araddr         (m_axil_araddr),
        .m_axil_arprot         (m_axil_arprot),
        .m_axil_arready        (m_axil_arready),
        .m_axil_arvalid        (m_axil_arvalid),
        .m_axil_awaddr         (m_axil_awaddr),
        .m_axil_awprot         (m_axil_awprot),
        .m_axil_awready        (m_axil_awready),
        .m_axil_awvalid        (m_axil_awvalid),
        .m_axil_bready         (m_axil_bready),
        .m_axil_bresp          (m_axil_bresp),
        .m_axil_bvalid         (m_axil_bvalid),
        .m_axil_rdata          (m_axil_rdata),
        .m_axil_rready         (m_axil_rready),
        .m_axil_rresp          (m_axil_rresp),
        .m_axil_rvalid         (m_axil_rvalid),
        .m_axil_wdata          (m_axil_wdata),
        .m_axil_wready         (m_axil_wready),
        .m_axil_wstrb          (m_axil_wstrb),
        .m_axil_wvalid         (m_axil_wvalid)
    );

    localparam CACHED_ADDR_W = 17;
    localparam UNCACHED_ADDR_W = 17;
    localparam AXIL_ADDR_W = 16;

    axi_ram #(
        .ADDR_WIDTH(CACHED_ADDR_W),
        .ID_WIDTH  (AXI_ID_W)
    ) i_axi_cached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_cached_awid),
        .s_axi_awaddr (m_axi_cached_awaddr[CACHED_ADDR_W-1:0]),
        .s_axi_awlen  (m_axi_cached_awlen),
        .s_axi_awsize (m_axi_cached_awsize),
        .s_axi_awburst(m_axi_cached_awburst),
        .s_axi_awlock (m_axi_cached_awlock),
        .s_axi_awcache(m_axi_cached_awcache),
        .s_axi_awprot (m_axi_cached_awprot),
        .s_axi_awvalid(m_axi_cached_awvalid),
        .s_axi_awready(m_axi_cached_awready),
        .s_axi_wdata  (m_axi_cached_wdata),
        .s_axi_wstrb  (m_axi_cached_wstrb),
        .s_axi_wlast  (m_axi_cached_wlast),
        .s_axi_wvalid (m_axi_cached_wvalid),
        .s_axi_wready (m_axi_cached_wready),
        .s_axi_bid    (m_axi_cached_bid),
        .s_axi_bresp  (m_axi_cached_bresp),
        .s_axi_bvalid (m_axi_cached_bvalid),
        .s_axi_bready (m_axi_cached_bready),
        .s_axi_arid   (m_axi_cached_arid),
        .s_axi_araddr (m_axi_cached_araddr[CACHED_ADDR_W-1:0]),
        .s_axi_arlen  (m_axi_cached_arlen),
        .s_axi_arsize (m_axi_cached_arsize),
        .s_axi_arburst(m_axi_cached_arburst),
        .s_axi_arlock (m_axi_cached_arlock),
        .s_axi_arcache(m_axi_cached_arcache),
        .s_axi_arprot (m_axi_cached_arprot),
        .s_axi_arvalid(m_axi_cached_arvalid),
        .s_axi_arready(m_axi_cached_arready),
        .s_axi_rid    (m_axi_cached_rid),
        .s_axi_rdata  (m_axi_cached_rdata),
        .s_axi_rresp  (m_axi_cached_rresp),
        .s_axi_rlast  (m_axi_cached_rlast),
        .s_axi_rvalid (m_axi_cached_rvalid),
        .s_axi_rready (m_axi_cached_rready)
    );

    axi_ram #(
        .ADDR_WIDTH(UNCACHED_ADDR_W),
        .ID_WIDTH  (AXI_ID_W)
    ) i_axi_uncached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_uncached_awid),
        .s_axi_awaddr (m_axi_uncached_awaddr[UNCACHED_ADDR_W-1:0]),
        .s_axi_awlen  (m_axi_uncached_awlen),
        .s_axi_awsize (m_axi_uncached_awsize),
        .s_axi_awburst(m_axi_uncached_awburst),
        .s_axi_awlock (m_axi_uncached_awlock),
        .s_axi_awcache(m_axi_uncached_awcache),
        .s_axi_awprot (m_axi_uncached_awprot),
        .s_axi_awvalid(m_axi_uncached_awvalid),
        .s_axi_awready(m_axi_uncached_awready),
        .s_axi_wdata  (m_axi_uncached_wdata),
        .s_axi_wstrb  (m_axi_uncached_wstrb),
        .s_axi_wlast  (m_axi_uncached_wlast),
        .s_axi_wvalid (m_axi_uncached_wvalid),
        .s_axi_wready (m_axi_uncached_wready),
        .s_axi_bid    (m_axi_uncached_bid),
        .s_axi_bresp  (m_axi_uncached_bresp),
        .s_axi_bvalid (m_axi_uncached_bvalid),
        .s_axi_bready (m_axi_uncached_bready),
        .s_axi_arid   (m_axi_uncached_arid),
        .s_axi_araddr (m_axi_uncached_araddr[UNCACHED_ADDR_W-1:0]),
        .s_axi_arlen  (m_axi_uncached_arlen),
        .s_axi_arsize (m_axi_uncached_arsize),
        .s_axi_arburst(m_axi_uncached_arburst),
        .s_axi_arlock (m_axi_uncached_arlock),
        .s_axi_arcache(m_axi_uncached_arcache),
        .s_axi_arprot (m_axi_uncached_arprot),
        .s_axi_arvalid(m_axi_uncached_arvalid),
        .s_axi_arready(m_axi_uncached_arready),
        .s_axi_rid    (m_axi_uncached_rid),
        .s_axi_rdata  (m_axi_uncached_rdata),
        .s_axi_rresp  (m_axi_uncached_rresp),
        .s_axi_rlast  (m_axi_uncached_rlast),
        .s_axi_rvalid (m_axi_uncached_rvalid),
        .s_axi_rready (m_axi_uncached_rready)
    );

    axil_ram #(
        .ADDR_WIDTH     (AXIL_ADDR_W),
        .PIPELINE_OUTPUT(0)
    ) i_axil_ram (
        .clk           (clk_i),
        .rst           (rst_i),
        .s_axil_awaddr (m_axil_awaddr[AXIL_ADDR_W-1:0]),
        .s_axil_awprot (m_axil_awprot),
        .s_axil_awvalid(m_axil_awvalid),
        .s_axil_awready(m_axil_awready),
        .s_axil_wdata  (m_axil_wdata),
        .s_axil_wstrb  (m_axil_wstrb),
        .s_axil_wvalid (m_axil_wvalid),
        .s_axil_wready (m_axil_wready),
        .s_axil_bresp  (m_axil_bresp),
        .s_axil_bvalid (m_axil_bvalid),
        .s_axil_bready (m_axil_bready),
        .s_axil_araddr (m_axil_araddr[AXIL_ADDR_W-1:0]),
        .s_axil_arprot (m_axil_arprot),
        .s_axil_arvalid(m_axil_arvalid),
        .s_axil_arready(m_axil_arready),
        .s_axil_rdata  (m_axil_rdata),
        .s_axil_rresp  (m_axil_rresp),
        .s_axil_rvalid (m_axil_rvalid),
        .s_axil_rready (m_axil_rready)
    );
endmodule : tb_dport
