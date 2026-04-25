module rsd_soc_mem #(
    parameter int S_ID_WIDTH          = 4,
    parameter int ADDR_WIDTH          = 32,
    parameter int DATA_WIDTH          = 64,
    parameter int STRB_WIDTH          = DATA_WIDTH / 8,
    parameter int AWUSER_WIDTH        = 1,
    parameter int WUSER_WIDTH         = 1,
    parameter int BUSER_WIDTH         = 1,
    parameter int ARUSER_WIDTH        = 1,
    parameter int RUSER_WIDTH         = 1,
    parameter int AXIL_DATA_WIDTH     = 32,
    parameter int AXIL_STRB_WIDTH     = AXIL_DATA_WIDTH / 8,
    parameter int RAM_BASE_ADDRESS    = 'h80000000,
    parameter int RAM_ADDR_WIDTH      = 16,
    parameter int PERIPH_BASE_ADDRESS = 'hA0000000,
    parameter int PERIPH_ADDR_WIDTH   = 16
) (
    input                              clk,
    input                              rst,
    //
    input  logic [     S_ID_WIDTH-1:0] s_core_axi_awid,
    input  logic [     ADDR_WIDTH-1:0] s_core_axi_awaddr,
    input  logic [                7:0] s_core_axi_awlen,
    input  logic [                2:0] s_core_axi_awsize,
    input  logic [                1:0] s_core_axi_awburst,
    input  logic                       s_core_axi_awlock,
    input  logic [                3:0] s_core_axi_awcache,
    input  logic [                2:0] s_core_axi_awprot,
    input  logic [                3:0] s_core_axi_awqos,
    input  logic [   AWUSER_WIDTH-1:0] s_core_axi_awuser,
    input  logic                       s_core_axi_awvalid,
    output logic                       s_core_axi_awready,
    input  logic [     DATA_WIDTH-1:0] s_core_axi_wdata,
    input  logic [     STRB_WIDTH-1:0] s_core_axi_wstrb,
    input  logic                       s_core_axi_wlast,
    input  logic [    WUSER_WIDTH-1:0] s_core_axi_wuser,
    input  logic                       s_core_axi_wvalid,
    output logic                       s_core_axi_wready,
    output logic [     S_ID_WIDTH-1:0] s_core_axi_bid,
    output logic [                1:0] s_core_axi_bresp,
    output logic [    BUSER_WIDTH-1:0] s_core_axi_buser,
    output logic                       s_core_axi_bvalid,
    input  logic                       s_core_axi_bready,
    input  logic [     S_ID_WIDTH-1:0] s_core_axi_arid,
    input  logic [     ADDR_WIDTH-1:0] s_core_axi_araddr,
    input  logic [                7:0] s_core_axi_arlen,
    input  logic [                2:0] s_core_axi_arsize,
    input  logic [                1:0] s_core_axi_arburst,
    input  logic                       s_core_axi_arlock,
    input  logic [                3:0] s_core_axi_arcache,
    input  logic [                2:0] s_core_axi_arprot,
    input  logic [                3:0] s_core_axi_arqos,
    input  logic [   ARUSER_WIDTH-1:0] s_core_axi_aruser,
    input  logic                       s_core_axi_arvalid,
    output logic                       s_core_axi_arready,
    output logic [     S_ID_WIDTH-1:0] s_core_axi_rid,
    output logic [     DATA_WIDTH-1:0] s_core_axi_rdata,
    output logic [                1:0] s_core_axi_rresp,
    output logic                       s_core_axi_rlast,
    output logic [    RUSER_WIDTH-1:0] s_core_axi_ruser,
    output logic                       s_core_axi_rvalid,
    input  logic                       s_core_axi_rready,
    //

    //
    input  logic [     S_ID_WIDTH-1:0] s_axi_awid,
    input  logic [     ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic [                7:0] s_axi_awlen,
    input  logic [                2:0] s_axi_awsize,
    input  logic [                1:0] s_axi_awburst,
    input  logic                       s_axi_awlock,
    input  logic [                3:0] s_axi_awcache,
    input  logic [                2:0] s_axi_awprot,
    input  logic [                3:0] s_axi_awqos,
    input  logic [   AWUSER_WIDTH-1:0] s_axi_awuser,
    input  logic                       s_axi_awvalid,
    output logic                       s_axi_awready,
    input  logic [     DATA_WIDTH-1:0] s_axi_wdata,
    input  logic [     STRB_WIDTH-1:0] s_axi_wstrb,
    input  logic                       s_axi_wlast,
    input  logic [    WUSER_WIDTH-1:0] s_axi_wuser,
    input  logic                       s_axi_wvalid,
    output logic                       s_axi_wready,
    output logic [     S_ID_WIDTH-1:0] s_axi_bid,
    output logic [                1:0] s_axi_bresp,
    output logic [    BUSER_WIDTH-1:0] s_axi_buser,
    output logic                       s_axi_bvalid,
    input  logic                       s_axi_bready,
    input  logic [     S_ID_WIDTH-1:0] s_axi_arid,
    input  logic [     ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic [                7:0] s_axi_arlen,
    input  logic [                2:0] s_axi_arsize,
    input  logic [                1:0] s_axi_arburst,
    input  logic                       s_axi_arlock,
    input  logic [                3:0] s_axi_arcache,
    input  logic [                2:0] s_axi_arprot,
    input  logic [                3:0] s_axi_arqos,
    input  logic [   ARUSER_WIDTH-1:0] s_axi_aruser,
    input  logic                       s_axi_arvalid,
    output logic                       s_axi_arready,
    output logic [     S_ID_WIDTH-1:0] s_axi_rid,
    output logic [     DATA_WIDTH-1:0] s_axi_rdata,
    output logic [                1:0] s_axi_rresp,
    output logic                       s_axi_rlast,
    output logic [    RUSER_WIDTH-1:0] s_axi_ruser,
    output logic                       s_axi_rvalid,
    input  logic                       s_axi_rready,
    //
    output logic [     ADDR_WIDTH-1:0] m_axil_awaddr,
    output logic [                2:0] m_axil_awprot,
    output logic                       m_axil_awvalid,
    input  logic                       m_axil_awready,
    output logic [AXIL_DATA_WIDTH-1:0] m_axil_wdata,
    output logic [AXIL_STRB_WIDTH-1:0] m_axil_wstrb,
    output logic                       m_axil_wvalid,
    input  logic                       m_axil_wready,
    input  logic [                1:0] m_axil_bresp,
    input  logic                       m_axil_bvalid,
    output logic                       m_axil_bready,
    output logic [     ADDR_WIDTH-1:0] m_axil_araddr,
    output logic [                2:0] m_axil_arprot,
    output logic                       m_axil_arvalid,
    input  logic                       m_axil_arready,
    input  logic [AXIL_DATA_WIDTH-1:0] m_axil_rdata,
    input  logic [                1:0] m_axil_rresp,
    input  logic                       m_axil_rvalid,
    output logic                       m_axil_rready
);
    localparam int S_COUNT = 2;
    localparam int M_ID_WIDTH = S_ID_WIDTH + $clog2(S_COUNT);

    logic [  M_ID_WIDTH-1:0] m00_to_ram_axi_awid;
    logic [  ADDR_WIDTH-1:0] m00_to_ram_axi_awaddr;
    logic [             7:0] m00_to_ram_axi_awlen;
    logic [             2:0] m00_to_ram_axi_awsize;
    logic [             1:0] m00_to_ram_axi_awburst;
    logic                    m00_to_ram_axi_awlock;
    logic [             3:0] m00_to_ram_axi_awcache;
    logic [             2:0] m00_to_ram_axi_awprot;
    logic [             3:0] m00_to_ram_axi_awqos;
    logic [             3:0] m00_to_ram_axi_awregion;
    logic [AWUSER_WIDTH-1:0] m00_to_ram_axi_awuser;
    logic                    m00_to_ram_axi_awvalid;
    logic                    m00_to_ram_axi_awready;
    logic [  DATA_WIDTH-1:0] m00_to_ram_axi_wdata;
    logic [  STRB_WIDTH-1:0] m00_to_ram_axi_wstrb;
    logic                    m00_to_ram_axi_wlast;
    logic [ WUSER_WIDTH-1:0] m00_to_ram_axi_wuser;
    logic                    m00_to_ram_axi_wvalid;
    logic                    m00_to_ram_axi_wready;
    logic [  M_ID_WIDTH-1:0] m00_to_ram_axi_bid;
    logic [             1:0] m00_to_ram_axi_bresp;
    logic [ BUSER_WIDTH-1:0] m00_to_ram_axi_buser;
    logic                    m00_to_ram_axi_bvalid;
    logic                    m00_to_ram_axi_bready;
    logic [  M_ID_WIDTH-1:0] m00_to_ram_axi_arid;
    logic [  ADDR_WIDTH-1:0] m00_to_ram_axi_araddr;
    logic [             7:0] m00_to_ram_axi_arlen;
    logic [             2:0] m00_to_ram_axi_arsize;
    logic [             1:0] m00_to_ram_axi_arburst;
    logic                    m00_to_ram_axi_arlock;
    logic [             3:0] m00_to_ram_axi_arcache;
    logic [             2:0] m00_to_ram_axi_arprot;
    logic [             3:0] m00_to_ram_axi_arqos;
    logic [             3:0] m00_to_ram_axi_arregion;
    logic [ARUSER_WIDTH-1:0] m00_to_ram_axi_aruser;
    logic                    m00_to_ram_axi_arvalid;
    logic                    m00_to_ram_axi_arready;
    logic [  M_ID_WIDTH-1:0] m00_to_ram_axi_rid;
    logic [  DATA_WIDTH-1:0] m00_to_ram_axi_rdata;
    logic [             1:0] m00_to_ram_axi_rresp;
    logic                    m00_to_ram_axi_rlast;
    logic [ RUSER_WIDTH-1:0] m00_to_ram_axi_ruser;
    logic                    m00_to_ram_axi_rvalid;
    logic                    m00_to_ram_axi_rready;

    logic [  M_ID_WIDTH-1:0] m01_to_axil_axi_awid;
    logic [  ADDR_WIDTH-1:0] m01_to_axil_axi_awaddr;
    logic [             7:0] m01_to_axil_axi_awlen;
    logic [             2:0] m01_to_axil_axi_awsize;
    logic [             1:0] m01_to_axil_axi_awburst;
    logic                    m01_to_axil_axi_awlock;
    logic [             3:0] m01_to_axil_axi_awcache;
    logic [             2:0] m01_to_axil_axi_awprot;
    logic [             3:0] m01_to_axil_axi_awqos;
    logic [             3:0] m01_to_axil_axi_awregion;
    logic [AWUSER_WIDTH-1:0] m01_to_axil_axi_awuser;
    logic                    m01_to_axil_axi_awvalid;
    logic                    m01_to_axil_axi_awready;
    logic [  DATA_WIDTH-1:0] m01_to_axil_axi_wdata;
    logic [  STRB_WIDTH-1:0] m01_to_axil_axi_wstrb;
    logic                    m01_to_axil_axi_wlast;
    logic [ WUSER_WIDTH-1:0] m01_to_axil_axi_wuser;
    logic                    m01_to_axil_axi_wvalid;
    logic                    m01_to_axil_axi_wready;
    logic [  M_ID_WIDTH-1:0] m01_to_axil_axi_bid;
    logic [             1:0] m01_to_axil_axi_bresp;
    logic [ BUSER_WIDTH-1:0] m01_to_axil_axi_buser;
    logic                    m01_to_axil_axi_bvalid;
    logic                    m01_to_axil_axi_bready;
    logic [  M_ID_WIDTH-1:0] m01_to_axil_axi_arid;
    logic [  ADDR_WIDTH-1:0] m01_to_axil_axi_araddr;
    logic [             7:0] m01_to_axil_axi_arlen;
    logic [             2:0] m01_to_axil_axi_arsize;
    logic [             1:0] m01_to_axil_axi_arburst;
    logic                    m01_to_axil_axi_arlock;
    logic [             3:0] m01_to_axil_axi_arcache;
    logic [             2:0] m01_to_axil_axi_arprot;
    logic [             3:0] m01_to_axil_axi_arqos;
    logic [             3:0] m01_to_axil_axi_arregion;
    logic [ARUSER_WIDTH-1:0] m01_to_axil_axi_aruser;
    logic                    m01_to_axil_axi_arvalid;
    logic                    m01_to_axil_axi_arready;
    logic [  M_ID_WIDTH-1:0] m01_to_axil_axi_rid;
    logic [  DATA_WIDTH-1:0] m01_to_axil_axi_rdata;
    logic [             1:0] m01_to_axil_axi_rresp;
    logic                    m01_to_axil_axi_rlast;
    logic [ RUSER_WIDTH-1:0] m01_to_axil_axi_ruser;
    logic                    m01_to_axil_axi_rvalid;
    logic                    m01_to_axil_axi_rready;


    axi_ram #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (RAM_ADDR_WIDTH),
        .STRB_WIDTH     ((DATA_WIDTH / 8)),
        .ID_WIDTH       (M_ID_WIDTH),
        .PIPELINE_OUTPUT(0)
    ) i_axi_ram (
        .clk          (clk),
        .rst          (rst),
        .s_axi_awid   (m00_to_ram_axi_awid),
        .s_axi_awaddr (m00_to_ram_axi_awaddr[RAM_ADDR_WIDTH-1:0]),
        .s_axi_awlen  (m00_to_ram_axi_awlen),
        .s_axi_awsize (m00_to_ram_axi_awsize),
        .s_axi_awburst(m00_to_ram_axi_awburst),
        .s_axi_awlock (m00_to_ram_axi_awlock),
        .s_axi_awcache(m00_to_ram_axi_awcache),
        .s_axi_awprot (m00_to_ram_axi_awprot),
        //.s_axi_awqos(m00_to_ram_axi_awqos),
        //.s_axi_awregion(m00_to_ram_axi_awregion),
        //.s_axi_awuser(m00_to_ram_axi_awuser),
        .s_axi_awvalid(m00_to_ram_axi_awvalid),
        .s_axi_awready(m00_to_ram_axi_awready),
        .s_axi_wdata  (m00_to_ram_axi_wdata),
        .s_axi_wstrb  (m00_to_ram_axi_wstrb),
        .s_axi_wlast  (m00_to_ram_axi_wlast),
        //.s_axi_wuser(m00_to_ram_axi_wuser),
        .s_axi_wvalid (m00_to_ram_axi_wvalid),
        .s_axi_wready (m00_to_ram_axi_wready),
        .s_axi_bid    (m00_to_ram_axi_bid),
        .s_axi_bresp  (m00_to_ram_axi_bresp),
        //.s_axi_buser(m00_to_ram_axi_buser),
        .s_axi_bvalid (m00_to_ram_axi_bvalid),
        .s_axi_bready (m00_to_ram_axi_bready),
        .s_axi_arid   (m00_to_ram_axi_arid),
        .s_axi_araddr (m00_to_ram_axi_araddr[RAM_ADDR_WIDTH-1:0]),
        .s_axi_arlen  (m00_to_ram_axi_arlen),
        .s_axi_arsize (m00_to_ram_axi_arsize),
        .s_axi_arburst(m00_to_ram_axi_arburst),
        .s_axi_arlock (m00_to_ram_axi_arlock),
        .s_axi_arcache(m00_to_ram_axi_arcache),
        .s_axi_arprot (m00_to_ram_axi_arprot),
        //.s_axi_arqos(m00_to_ram_axi_arqos),
        //.s_axi_arregion(m00_to_ram_axi_arregion),
        //.s_axi_aruser(m00_to_ram_axi_aruser),
        .s_axi_arvalid(m00_to_ram_axi_arvalid),
        .s_axi_arready(m00_to_ram_axi_arready),
        .s_axi_rid    (m00_to_ram_axi_rid),
        .s_axi_rdata  (m00_to_ram_axi_rdata),
        .s_axi_rresp  (m00_to_ram_axi_rresp),
        .s_axi_rlast  (m00_to_ram_axi_rlast),
        //.s_axi_ruser(m00_to_ram_axi_ruser),
        .s_axi_rvalid (m00_to_ram_axi_rvalid),
        .s_axi_rready (m00_to_ram_axi_rready)
    );

    axi_crossbar_wrap_2x2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .S_ID_WIDTH       (S_ID_WIDTH),
        //
        .M00_BASE_ADDR    (RAM_BASE_ADDRESS),
        .M00_ADDR_WIDTH   (RAM_ADDR_WIDTH),
        .M00_CONNECT_READ (2'b11),
        .M00_CONNECT_WRITE(2'b11),
        //
        .M01_BASE_ADDR    (PERIPH_BASE_ADDRESS),
        .M01_ADDR_WIDTH   (PERIPH_ADDR_WIDTH),
        .M01_CONNECT_READ (2'b11),
        .M01_CONNECT_WRITE(2'b11),
        //
        .S00_AW_REG_TYPE  (2),           //0
        .S00_W_REG_TYPE   (2),           //0
        .S00_B_REG_TYPE   (2),           //1
        .S00_AR_REG_TYPE  (2),           //0
        .S00_R_REG_TYPE   (2),           //2
        .S01_AW_REG_TYPE  (2),           //0
        .S01_W_REG_TYPE   (2),           //0
        .S01_B_REG_TYPE   (2),           //1
        .S01_AR_REG_TYPE  (2),           //0
        .S01_R_REG_TYPE   (2),           //2
        //.S02_AW_REG_TYPE  (2),           //0
        //.S02_W_REG_TYPE   (2),           //0
        //.S02_B_REG_TYPE   (2),           //1
        //.S02_AR_REG_TYPE  (2),           //0
        //.S02_R_REG_TYPE   (2),           //2
        .M00_AW_REG_TYPE  (2),           //1
        .M00_W_REG_TYPE   (2),           //2
        .M00_B_REG_TYPE   (2),           //0
        .M00_AR_REG_TYPE  (2),           //1
        .M00_R_REG_TYPE   (2),           //0
        .M01_AW_REG_TYPE  (2),           //1
        .M01_W_REG_TYPE   (2),           //2
        .M01_B_REG_TYPE   (2),           //0
        .M01_AR_REG_TYPE  (2),           //1
        .M01_R_REG_TYPE   (2)            //0
    ) i_axi_crossbar_wrap_3x2 (
        .clk             (clk),
        .rst             (rst),
        //
        .s00_axi_awid    (s_core_axi_awid),
        .s00_axi_awaddr  (s_core_axi_awaddr),
        .s00_axi_awlen   (s_core_axi_awlen),
        .s00_axi_awsize  (s_core_axi_awsize),
        .s00_axi_awburst (s_core_axi_awburst),
        .s00_axi_awlock  (s_core_axi_awlock),
        .s00_axi_awcache (s_core_axi_awcache),
        .s00_axi_awprot  (s_core_axi_awprot),
        .s00_axi_awqos   (s_core_axi_awqos),
        .s00_axi_awuser  (s_core_axi_awuser),
        .s00_axi_awvalid (s_core_axi_awvalid),
        .s00_axi_awready (s_core_axi_awready),
        .s00_axi_wdata   (s_core_axi_wdata),
        .s00_axi_wstrb   (s_core_axi_wstrb),
        .s00_axi_wlast   (s_core_axi_wlast),
        .s00_axi_wuser   (s_core_axi_wuser),
        .s00_axi_wvalid  (s_core_axi_wvalid),
        .s00_axi_wready  (s_core_axi_wready),
        .s00_axi_bid     (s_core_axi_bid),
        .s00_axi_bresp   (s_core_axi_bresp),
        .s00_axi_buser   (s_core_axi_buser),
        .s00_axi_bvalid  (s_core_axi_bvalid),
        .s00_axi_bready  (s_core_axi_bready),
        .s00_axi_arid    (s_core_axi_arid),
        .s00_axi_araddr  (s_core_axi_araddr),
        .s00_axi_arlen   (s_core_axi_arlen),
        .s00_axi_arsize  (s_core_axi_arsize),
        .s00_axi_arburst (s_core_axi_arburst),
        .s00_axi_arlock  (s_core_axi_arlock),
        .s00_axi_arcache (s_core_axi_arcache),
        .s00_axi_arprot  (s_core_axi_arprot),
        .s00_axi_arqos   (s_core_axi_arqos),
        .s00_axi_aruser  (s_core_axi_aruser),
        .s00_axi_arvalid (s_core_axi_arvalid),
        .s00_axi_arready (s_core_axi_arready),
        .s00_axi_rid     (s_core_axi_rid),
        .s00_axi_rdata   (s_core_axi_rdata),
        .s00_axi_rresp   (s_core_axi_rresp),
        .s00_axi_rlast   (s_core_axi_rlast),
        .s00_axi_ruser   (s_core_axi_ruser),
        .s00_axi_rvalid  (s_core_axi_rvalid),
        .s00_axi_rready  (s_core_axi_rready),
        //
        .s01_axi_awid    (s_axi_awid),
        .s01_axi_awaddr  (s_axi_awaddr),
        .s01_axi_awlen   (s_axi_awlen),
        .s01_axi_awsize  (s_axi_awsize),
        .s01_axi_awburst (s_axi_awburst),
        .s01_axi_awlock  (s_axi_awlock),
        .s01_axi_awcache (s_axi_awcache),
        .s01_axi_awprot  (s_axi_awprot),
        .s01_axi_awqos   (s_axi_awqos),
        .s01_axi_awuser  (s_axi_awuser),
        .s01_axi_awvalid (s_axi_awvalid),
        .s01_axi_awready (s_axi_awready),
        .s01_axi_wdata   (s_axi_wdata),
        .s01_axi_wstrb   (s_axi_wstrb),
        .s01_axi_wlast   (s_axi_wlast),
        .s01_axi_wuser   (s_axi_wuser),
        .s01_axi_wvalid  (s_axi_wvalid),
        .s01_axi_wready  (s_axi_wready),
        .s01_axi_bid     (s_axi_bid),
        .s01_axi_bresp   (s_axi_bresp),
        .s01_axi_buser   (s_axi_buser),
        .s01_axi_bvalid  (s_axi_bvalid),
        .s01_axi_bready  (s_axi_bready),
        .s01_axi_arid    (s_axi_arid),
        .s01_axi_araddr  (s_axi_araddr),
        .s01_axi_arlen   (s_axi_arlen),
        .s01_axi_arsize  (s_axi_arsize),
        .s01_axi_arburst (s_axi_arburst),
        .s01_axi_arlock  (s_axi_arlock),
        .s01_axi_arcache (s_axi_arcache),
        .s01_axi_arprot  (s_axi_arprot),
        .s01_axi_arqos   (s_axi_arqos),
        .s01_axi_aruser  (s_axi_aruser),
        .s01_axi_arvalid (s_axi_arvalid),
        .s01_axi_arready (s_axi_arready),
        .s01_axi_rid     (s_axi_rid),
        .s01_axi_rdata   (s_axi_rdata),
        .s01_axi_rresp   (s_axi_rresp),
        .s01_axi_rlast   (s_axi_rlast),
        .s01_axi_ruser   (s_axi_ruser),
        .s01_axi_rvalid  (s_axi_rvalid),
        .s01_axi_rready  (s_axi_rready),
        //
        .m00_axi_awid    (m00_to_ram_axi_awid),
        .m00_axi_awaddr  (m00_to_ram_axi_awaddr),
        .m00_axi_awlen   (m00_to_ram_axi_awlen),
        .m00_axi_awsize  (m00_to_ram_axi_awsize),
        .m00_axi_awburst (m00_to_ram_axi_awburst),
        .m00_axi_awlock  (m00_to_ram_axi_awlock),
        .m00_axi_awcache (m00_to_ram_axi_awcache),
        .m00_axi_awprot  (m00_to_ram_axi_awprot),
        .m00_axi_awqos   (m00_to_ram_axi_awqos),
        .m00_axi_awregion(m00_to_ram_axi_awregion),
        .m00_axi_awuser  (m00_to_ram_axi_awuser),
        .m00_axi_awvalid (m00_to_ram_axi_awvalid),
        .m00_axi_awready (m00_to_ram_axi_awready),
        .m00_axi_wdata   (m00_to_ram_axi_wdata),
        .m00_axi_wstrb   (m00_to_ram_axi_wstrb),
        .m00_axi_wlast   (m00_to_ram_axi_wlast),
        .m00_axi_wuser   (m00_to_ram_axi_wuser),
        .m00_axi_wvalid  (m00_to_ram_axi_wvalid),
        .m00_axi_wready  (m00_to_ram_axi_wready),
        .m00_axi_bid     (m00_to_ram_axi_bid),
        .m00_axi_bresp   (m00_to_ram_axi_bresp),
        .m00_axi_buser   (m00_to_ram_axi_buser),
        .m00_axi_bvalid  (m00_to_ram_axi_bvalid),
        .m00_axi_bready  (m00_to_ram_axi_bready),
        .m00_axi_arid    (m00_to_ram_axi_arid),
        .m00_axi_araddr  (m00_to_ram_axi_araddr),
        .m00_axi_arlen   (m00_to_ram_axi_arlen),
        .m00_axi_arsize  (m00_to_ram_axi_arsize),
        .m00_axi_arburst (m00_to_ram_axi_arburst),
        .m00_axi_arlock  (m00_to_ram_axi_arlock),
        .m00_axi_arcache (m00_to_ram_axi_arcache),
        .m00_axi_arprot  (m00_to_ram_axi_arprot),
        .m00_axi_arqos   (m00_to_ram_axi_arqos),
        .m00_axi_arregion(m00_to_ram_axi_arregion),
        .m00_axi_aruser  (m00_to_ram_axi_aruser),
        .m00_axi_arvalid (m00_to_ram_axi_arvalid),
        .m00_axi_arready (m00_to_ram_axi_arready),
        .m00_axi_rid     (m00_to_ram_axi_rid),
        .m00_axi_rdata   (m00_to_ram_axi_rdata),
        .m00_axi_rresp   (m00_to_ram_axi_rresp),
        .m00_axi_rlast   (m00_to_ram_axi_rlast),
        .m00_axi_ruser   (m00_to_ram_axi_ruser),
        .m00_axi_rvalid  (m00_to_ram_axi_rvalid),
        .m00_axi_rready  (m00_to_ram_axi_rready),
        //
        .m01_axi_awid    (m01_to_axil_axi_awid),
        .m01_axi_awaddr  (m01_to_axil_axi_awaddr),
        .m01_axi_awlen   (m01_to_axil_axi_awlen),
        .m01_axi_awsize  (m01_to_axil_axi_awsize),
        .m01_axi_awburst (m01_to_axil_axi_awburst),
        .m01_axi_awlock  (m01_to_axil_axi_awlock),
        .m01_axi_awcache (m01_to_axil_axi_awcache),
        .m01_axi_awprot  (m01_to_axil_axi_awprot),
        .m01_axi_awqos   (m01_to_axil_axi_awqos),
        .m01_axi_awregion(m01_to_axil_axi_awregion),
        .m01_axi_awuser  (m01_to_axil_axi_awuser),
        .m01_axi_awvalid (m01_to_axil_axi_awvalid),
        .m01_axi_awready (m01_to_axil_axi_awready),
        .m01_axi_wdata   (m01_to_axil_axi_wdata),
        .m01_axi_wstrb   (m01_to_axil_axi_wstrb),
        .m01_axi_wlast   (m01_to_axil_axi_wlast),
        .m01_axi_wuser   (m01_to_axil_axi_wuser),
        .m01_axi_wvalid  (m01_to_axil_axi_wvalid),
        .m01_axi_wready  (m01_to_axil_axi_wready),
        .m01_axi_bid     (m01_to_axil_axi_bid),
        .m01_axi_bresp   (m01_to_axil_axi_bresp),
        .m01_axi_buser   (m01_to_axil_axi_buser),
        .m01_axi_bvalid  (m01_to_axil_axi_bvalid),
        .m01_axi_bready  (m01_to_axil_axi_bready),
        .m01_axi_arid    (m01_to_axil_axi_arid),
        .m01_axi_araddr  (m01_to_axil_axi_araddr),
        .m01_axi_arlen   (m01_to_axil_axi_arlen),
        .m01_axi_arsize  (m01_to_axil_axi_arsize),
        .m01_axi_arburst (m01_to_axil_axi_arburst),
        .m01_axi_arlock  (m01_to_axil_axi_arlock),
        .m01_axi_arcache (m01_to_axil_axi_arcache),
        .m01_axi_arprot  (m01_to_axil_axi_arprot),
        .m01_axi_arqos   (m01_to_axil_axi_arqos),
        .m01_axi_arregion(m01_to_axil_axi_arregion),
        .m01_axi_aruser  (m01_to_axil_axi_aruser),
        .m01_axi_arvalid (m01_to_axil_axi_arvalid),
        .m01_axi_arready (m01_to_axil_axi_arready),
        .m01_axi_rid     (m01_to_axil_axi_rid),
        .m01_axi_rdata   (m01_to_axil_axi_rdata),
        .m01_axi_rresp   (m01_to_axil_axi_rresp),
        .m01_axi_rlast   (m01_to_axil_axi_rlast),
        .m01_axi_ruser   (m01_to_axil_axi_ruser),
        .m01_axi_rvalid  (m01_to_axil_axi_rvalid),
        .m01_axi_rready  (m01_to_axil_axi_rready)
    );

    axi_axil_adapter #(
        .ADDR_WIDTH          (ADDR_WIDTH),
        .AXI_DATA_WIDTH      (DATA_WIDTH),
        .AXI_STRB_WIDTH      ((DATA_WIDTH / 8)),
        .AXI_ID_WIDTH        (M_ID_WIDTH),
        .AXIL_DATA_WIDTH     (AXIL_DATA_WIDTH),
        .AXIL_STRB_WIDTH     ((AXIL_DATA_WIDTH / 8)),
        .CONVERT_BURST       (1),
        .CONVERT_NARROW_BURST(0)
    ) i_axi_axil_adapter (
        .clk           (clk),
        .rst           (rst),
        .s_axi_awid    (m01_to_axil_axi_awid),
        .s_axi_awaddr  (m01_to_axil_axi_awaddr),
        .s_axi_awlen   (m01_to_axil_axi_awlen),
        .s_axi_awsize  (m01_to_axil_axi_awsize),
        .s_axi_awburst (m01_to_axil_axi_awburst),
        .s_axi_awlock  (m01_to_axil_axi_awlock),
        .s_axi_awcache (m01_to_axil_axi_awcache),
        .s_axi_awprot  (m01_to_axil_axi_awprot),
        //.s_axi_awqos   (m01_to_axil_axi_awqos),
        //.s_axi_awregion(m01_to_axil_axi_awregion),
        //.s_axi_awuser  (m01_to_axil_axi_awuser),
        .s_axi_awvalid (m01_to_axil_axi_awvalid),
        .s_axi_awready (m01_to_axil_axi_awready),
        .s_axi_wdata   (m01_to_axil_axi_wdata),
        .s_axi_wstrb   (m01_to_axil_axi_wstrb),
        .s_axi_wlast   (m01_to_axil_axi_wlast),
        //.s_axi_wuser   (m01_to_axil_axi_wuser),
        .s_axi_wvalid  (m01_to_axil_axi_wvalid),
        .s_axi_wready  (m01_to_axil_axi_wready),
        .s_axi_bid     (m01_to_axil_axi_bid),
        .s_axi_bresp   (m01_to_axil_axi_bresp),
        //.s_axi_buser   (m01_to_axil_axi_buser),
        .s_axi_bvalid  (m01_to_axil_axi_bvalid),
        .s_axi_bready  (m01_to_axil_axi_bready),
        .s_axi_arid    (m01_to_axil_axi_arid),
        .s_axi_araddr  (m01_to_axil_axi_araddr),
        .s_axi_arlen   (m01_to_axil_axi_arlen),
        .s_axi_arsize  (m01_to_axil_axi_arsize),
        .s_axi_arburst (m01_to_axil_axi_arburst),
        .s_axi_arlock  (m01_to_axil_axi_arlock),
        .s_axi_arcache (m01_to_axil_axi_arcache),
        .s_axi_arprot  (m01_to_axil_axi_arprot),
        //.s_axi_arqos   (m01_to_axil_axi_arqos),
        //.s_axi_arregion(m01_to_axil_axi_arregion),
        //.s_axi_aruser  (m01_to_axil_axi_aruser),
        .s_axi_arvalid (m01_to_axil_axi_arvalid),
        .s_axi_arready (m01_to_axil_axi_arready),
        .s_axi_rid     (m01_to_axil_axi_rid),
        .s_axi_rdata   (m01_to_axil_axi_rdata),
        .s_axi_rresp   (m01_to_axil_axi_rresp),
        .s_axi_rlast   (m01_to_axil_axi_rlast),
        //.s_axi_ruser   (m01_to_axil_axi_ruser),
        .s_axi_rvalid  (m01_to_axil_axi_rvalid),
        .s_axi_rready  (m01_to_axil_axi_rready),
        .m_axil_awaddr (m_axil_awaddr),
        .m_axil_awprot (m_axil_awprot),
        .m_axil_awvalid(m_axil_awvalid),
        .m_axil_awready(m_axil_awready),
        .m_axil_wdata  (m_axil_wdata),
        .m_axil_wstrb  (m_axil_wstrb),
        .m_axil_wvalid (m_axil_wvalid),
        .m_axil_wready (m_axil_wready),
        .m_axil_bresp  (m_axil_bresp),
        .m_axil_bvalid (m_axil_bvalid),
        .m_axil_bready (m_axil_bready),
        .m_axil_araddr (m_axil_araddr),
        .m_axil_arprot (m_axil_arprot),
        .m_axil_arvalid(m_axil_arvalid),
        .m_axil_arready(m_axil_arready),
        .m_axil_rdata  (m_axil_rdata),
        .m_axil_rresp  (m_axil_rresp),
        .m_axil_rvalid (m_axil_rvalid),
        .m_axil_rready (m_axil_rready)
    );


endmodule : rsd_soc_mem
