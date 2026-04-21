module tb_biriscv_idcache_top (
    input logic i_clk,
    input logic i_rst
);
    localparam int S_ID_WIDTH = 4;
    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 32;
    localparam int STRB_WIDTH = DATA_WIDTH / 8;
    localparam int AWUSER_WIDTH = 1;
    localparam int WUSER_WIDTH = 1;
    localparam int BUSER_WIDTH = 1;
    localparam int ARUSER_WIDTH = 1;
    localparam int RUSER_WIDTH = 1;
    localparam int AXIL_DATA_WIDTH = 32;
    localparam int AXIL_STRB_WIDTH = AXIL_DATA_WIDTH / 8;
    localparam int RAM_BASE_ADDRESS = 'h80000000;
    localparam int RAM_ADDR_WIDTH = 17;
    localparam int PERIPH_BASE_ADDRESS = 'hA0000000;
    localparam int PERIPH_ADDR_WIDTH = 16;
    localparam int PERIPH_ADDR_MIN = PERIPH_BASE_ADDRESS;
    localparam int PERIPH_ADDR_MAX = PERIPH_BASE_ADDRESS + ((1 << PERIPH_ADDR_WIDTH) - 1);
    localparam int MEM_ADDR_MIN = RAM_BASE_ADDRESS;
    localparam int MEM_ADDR_MAX = RAM_BASE_ADDRESS + ((1 << RAM_ADDR_WIDTH) - 1);
    localparam int MEM_CACHE_ADDR_MIN = RAM_BASE_ADDRESS;
    localparam int MEM_CACHE_ADDR_MAX = RAM_BASE_ADDRESS + ((1 << (RAM_ADDR_WIDTH - 1)) - 1);
    localparam int RESET_VECTOR = RAM_BASE_ADDRESS;

    logic                       i_intr;
    logic [               31:0] i_reset_vector;
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


    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end

    initial begin
        i_intr              = 0;
        i_reset_vector      = RESET_VECTOR;
        s_data_axi_araddr   = 0;
        s_data_axi_arburst  = 0;
        s_data_axi_arid     = 0;
        s_data_axi_arlen    = 0;
        s_data_axi_arvalid  = 0;
        s_data_axi_awaddr   = 0;
        s_data_axi_awburst  = 0;
        s_data_axi_awid     = 0;
        s_data_axi_awlen    = 0;
        s_data_axi_awvalid  = 0;
        s_data_axi_bready   = 0;
        s_data_axi_rready   = 0;
        s_data_axi_wdata    = 0;
        s_data_axi_wlast    = 0;
        s_data_axi_wstrb    = 0;
        s_data_axi_wvalid   = 0;
        s_instr_axi_araddr  = 0;
        s_instr_axi_arburst = 0;
        s_instr_axi_arid    = 0;
        s_instr_axi_arlen   = 0;
        s_instr_axi_arvalid = 0;
        s_instr_axi_awaddr  = 0;
        s_instr_axi_awburst = 0;
        s_instr_axi_awid    = 0;
        s_instr_axi_awlen   = 0;
        s_instr_axi_awvalid = 0;
        s_instr_axi_bready  = 0;
        s_instr_axi_rready  = 0;
        s_instr_axi_wdata   = 0;
        s_instr_axi_wlast   = 0;
        s_instr_axi_wstrb   = 0;
        s_instr_axi_wvalid  = 0;
        s_data_axi_arsize   = 2;
        s_data_axi_awsize   = 2;
        s_instr_axi_arsize  = 2;
        s_instr_axi_awsize  = 2;
        s_axi_awid          = 0;
        s_axi_awaddr        = 0;
        s_axi_awlen         = 0;
        s_axi_awsize        = 0;
        s_axi_awburst       = 0;
        s_axi_awlock        = 0;
        s_axi_awcache       = 0;
        s_axi_awprot        = 0;
        s_axi_awqos         = 0;
        s_axi_awuser        = 0;
        s_axi_awvalid       = 0;
        s_axi_wdata         = 0;
        s_axi_wstrb         = 0;
        s_axi_wlast         = 0;
        s_axi_wuser         = 0;
        s_axi_wvalid        = 0;
        s_axi_bready        = 0;
        s_axi_arid          = 0;
        s_axi_araddr        = 0;
        s_axi_arlen         = 0;
        s_axi_arsize        = 0;
        s_axi_arburst       = 0;
        s_axi_arlock        = 0;
        s_axi_arcache       = 0;
        s_axi_arprot        = 0;
        s_axi_arqos         = 0;
        s_axi_aruser        = 0;
        s_axi_arvalid       = 0;
        s_axi_rready        = 0;
        m_axil_awready      = 0;
        m_axil_wready       = 0;
        m_axil_bresp        = 0;
        m_axil_bvalid       = 0;
        m_axil_arready      = 0;
        m_axil_rdata        = 0;
        m_axil_rresp        = 0;
        m_axil_rvalid       = 0;
    end

    biriscv_idcache_top #(
        .ICACHE_AXI_ID     (0),
        .DCACHE_AXI_ID     (1),
        .MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN),
        .MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX)
    ) i_riscv_top_wrapper (
        .i_clk              (i_clk),
        .i_rst              (i_rst),
        .i_intr             (i_intr),
        .i_reset_vector     (i_reset_vector),
        .s_data_axi_araddr  (s_data_axi_araddr),
        .s_data_axi_arburst (s_data_axi_arburst),
        .s_data_axi_arid    (s_data_axi_arid),
        .s_data_axi_arlen   (s_data_axi_arlen),
        .s_data_axi_arready (s_data_axi_arready),
        .s_data_axi_arvalid (s_data_axi_arvalid),
        .s_data_axi_awaddr  (s_data_axi_awaddr),
        .s_data_axi_awburst (s_data_axi_awburst),
        .s_data_axi_awid    (s_data_axi_awid),
        .s_data_axi_awlen   (s_data_axi_awlen),
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
        .s_instr_axi_arready(s_instr_axi_arready),
        .s_instr_axi_arvalid(s_instr_axi_arvalid),
        .s_instr_axi_awaddr (s_instr_axi_awaddr),
        .s_instr_axi_awburst(s_instr_axi_awburst),
        .s_instr_axi_awid   (s_instr_axi_awid),
        .s_instr_axi_awlen  (s_instr_axi_awlen),
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
        .s_instr_axi_wvalid (s_instr_axi_wvalid)
    );




    soc_mem #(
        .RAM_BASE_ADDRESS   (RAM_BASE_ADDRESS),
        .RAM_ADDR_WIDTH     (RAM_ADDR_WIDTH),
        .PERIPH_BASE_ADDRESS(PERIPH_BASE_ADDRESS),
        .PERIPH_ADDR_WIDTH  (PERIPH_ADDR_WIDTH)
    ) i_soc_mem (
        .clk                (i_clk),
        .rst                (i_rst),
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

    localparam int M_AXI_DATA_WIDTH = 32;
    localparam int M_AXI_ADDR_WIDTH = 32;
    localparam int M_AXI_ID_WIDTH = S_ID_WIDTH;
    localparam int M00_AXIS_TDATA_WIDTH = 8;
    localparam int M01_AXIS_TDATA_WIDTH = 16;
    localparam int S00_AXIS_TDATA_WIDTH = 8;
    localparam int S01_AXIS_TDATA_WIDTH = 16;
    localparam int S_AXIL_DATA_WIDTH    = ringbuffer_addrmap_pkg::RINGBUFFER_ADDRMAP_MIN_ADDR_WIDTH;

    ringbuffer_axis_if #(.TDATA_WIDTH(M00_AXIS_TDATA_WIDTH)) m00_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(M01_AXIS_TDATA_WIDTH)) m01_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(S00_AXIS_TDATA_WIDTH)) s00_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(S01_AXIS_TDATA_WIDTH)) s01_axis ();

    initial begin
        m00_axis.tready = 1;
        m01_axis.tready = 1;
        s00_axis.tvalid = 0;
        s01_axis.tvalid = 0;
    end

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
        .o_interrupt   (i_intr),
        //
        .m00_axis      (m00_axis),
        .m01_axis      (m01_axis),
        .s00_axis      (s00_axis),
        .s01_axis      (s01_axis),
        //
        .s_axil_awready(m_axil_awready),
        .s_axil_awvalid(m_axil_awvalid),
        .s_axil_awaddr (m_axil_awaddr[S_AXIL_DATA_WIDTH-1:0]),
        .s_axil_awprot (m_axil_awprot),
        .s_axil_wready (m_axil_wready),
        .s_axil_wvalid (m_axil_wvalid),
        .s_axil_wdata  (m_axil_wdata),
        .s_axil_wstrb  (m_axil_wstrb),
        .s_axil_bready (m_axil_bready),
        .s_axil_bvalid (m_axil_bvalid),
        .s_axil_bresp  (m_axil_bresp),
        .s_axil_arready(m_axil_arready),
        .s_axil_arvalid(m_axil_arvalid),
        .s_axil_araddr (m_axil_araddr[S_AXIL_DATA_WIDTH-1:0]),
        .s_axil_arprot (m_axil_arprot),
        .s_axil_rready (m_axil_rready),
        .s_axil_rvalid (m_axil_rvalid),
        .s_axil_rdata  (m_axil_rdata),
        .s_axil_rresp  (m_axil_rresp),
        //
        .m_axi_arvalid (s_axi_arvalid),
        .m_axi_arready (s_axi_arready),
        .m_axi_araddr  (s_axi_araddr),
        .m_axi_arlen   (s_axi_arlen),
        .m_axi_arsize  (s_axi_arsize),
        .m_axi_arburst (s_axi_arburst),
        .m_axi_arid    (s_axi_arid),
        .m_axi_rvalid  (s_axi_rvalid),
        .m_axi_rready  (s_axi_rready),
        .m_axi_rdata   (s_axi_rdata),
        .m_axi_rlast   (s_axi_rlast),
        .m_axi_rid     (s_axi_rid),
        .m_axi_rresp   (s_axi_rresp),
        .m_axi_awvalid (s_axi_awvalid),
        .m_axi_awready (s_axi_awready),
        .m_axi_awaddr  (s_axi_awaddr),
        .m_axi_awlen   (s_axi_awlen),
        .m_axi_awsize  (s_axi_awsize),
        .m_axi_awburst (s_axi_awburst),
        .m_axi_awid    (s_axi_awid),
        .m_axi_wvalid  (s_axi_wvalid),
        .m_axi_wready  (s_axi_wready),
        .m_axi_wdata   (s_axi_wdata),
        .m_axi_wstrb   (s_axi_wstrb),
        .m_axi_wlast   (s_axi_wlast),
        .m_axi_bvalid  (s_axi_bvalid),
        .m_axi_bready  (s_axi_bready),
        .m_axi_bid     (s_axi_bid),
        .m_axi_bresp   (s_axi_bresp)
    );



`ifdef verilator
    //-------------------------------------------------------------
    // write: Write byte into memory
    //-------------------------------------------------------------
    function write;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            case (addr[1:0])
                2'd0: i_soc_mem.i_axi_ram.mem[addr/4][7:0] = data;
                2'd1: i_soc_mem.i_axi_ram.mem[addr/4][15:8] = data;
                2'd2: i_soc_mem.i_axi_ram.mem[addr/4][23:16] = data;
                2'd3: i_soc_mem.i_axi_ram.mem[addr/4][31:24] = data;
                //3'd4: i_axi_ram.mem[addr/8][39:32] = data;
                //3'd5: i_axi_ram.mem[addr/8][47:40] = data;
                //3'd6: i_axi_ram.mem[addr/8][55:48] = data;
                //3'd7: i_axi_ram.mem[addr/8][63:56] = data;
            endcase
        end
    endfunction
    //-------------------------------------------------------------
    // read: Read byte from memory
    //-------------------------------------------------------------
    function [7:0] read;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[1:0])
                2'd0: read = i_soc_mem.i_axi_ram.mem[addr/4][7:0];
                2'd1: read = i_soc_mem.i_axi_ram.mem[addr/4][15:8];
                2'd2: read = i_soc_mem.i_axi_ram.mem[addr/4][23:16];
                2'd3: read = i_soc_mem.i_axi_ram.mem[addr/4][31:24];
                //3'd4: read = i_axi_ram.mem[addr/8][39:32];
                //3'd5: read = i_axi_ram.mem[addr/8][47:40];
                //3'd6: read = i_axi_ram.mem[addr/8][55:48];
                //3'd7: read = i_axi_ram.mem[addr/8][63:56];
            endcase
        end
    endfunction
`endif


endmodule : tb_biriscv_idcache_top
