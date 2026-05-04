module tb_iobcache #(
    parameter FE_ADDR_W     = 24,
    parameter FE_DATA_W     = 32,
    parameter BE_ADDR_W     = 24,
    parameter BE_DATA_W     = 32,
    parameter NWAYS_W       = 1,
    parameter NLINES_W      = 7,
    parameter WORD_OFFSET_W = 3,
    parameter WTBUF_DEPTH_W = 4,
    parameter REP_POLICY    = 0,
    parameter WRITE_POL     = 0,
    parameter USE_CTRL      = 0,
    parameter USE_CTRL_CNT  = 0,
    parameter AXI_ID_W      = 1,
    parameter AXI_ID        = 0,
    parameter AXI_LEN_W     = 8,
    parameter AXI_ADDR_W    = BE_ADDR_W,
    parameter AXI_DATA_W    = BE_DATA_W,
    parameter VERSION       = 24'h008100,
    parameter FE_NBYTES     = FE_DATA_W / 8,
    parameter FE_NBYTES_W   = $clog2(FE_NBYTES),
    parameter BE_NBYTES     = BE_DATA_W / 8,
    parameter BE_NBYTES_W   = $clog2(BE_NBYTES),
    parameter LINE2BE_W     = WORD_OFFSET_W - $clog2(BE_DATA_W / FE_DATA_W),
    parameter ADDR_W        = USE_CTRL + FE_ADDR_W,
    parameter DATA_W        = FE_DATA_W
) ();

    logic i_reset;
    logic rst_i;
    logic i_clk;
    logic clk_i;
    logic cke_i;
    logic arst_i;

    assign clk_i  = i_clk;
    assign cke_i  = 1;
    assign arst_i = i_reset;
    assign rst_i  = i_reset;

    logic [            31:0] mem_addr_i;
    logic [            31:0] mem_data_wr_i;
    logic                    mem_rd_i;
    logic [             3:0] mem_wr_i;
    logic [            31:0] mem_data_rd_o;
    logic                    mem_accept_o;
    logic                    mem_ack_o;
    // AXI bus to connect Cache back end to memory
    wire  [  AXI_ADDR_W-1:0] be_axi_araddr;
    wire                     be_axi_arvalid;
    wire                     be_axi_arready;
    wire  [  AXI_DATA_W-1:0] be_axi_rdata;
    wire  [           2-1:0] be_axi_rresp;
    wire                     be_axi_rvalid;
    wire                     be_axi_rready;
    wire  [    AXI_ID_W-1:0] be_axi_arid;
    wire  [   AXI_LEN_W-1:0] be_axi_arlen;
    wire  [           3-1:0] be_axi_arsize;
    wire  [           2-1:0] be_axi_arburst;
    wire                     be_axi_arlock;
    wire  [           4-1:0] be_axi_arcache;
    wire  [           4-1:0] be_axi_arqos;
    wire  [    AXI_ID_W-1:0] be_axi_rid;
    wire                     be_axi_rlast;
    wire  [  AXI_ADDR_W-1:0] be_axi_awaddr;
    wire                     be_axi_awvalid;
    wire                     be_axi_awready;
    wire  [  AXI_DATA_W-1:0] be_axi_wdata;
    wire  [AXI_DATA_W/8-1:0] be_axi_wstrb;
    wire                     be_axi_wvalid;
    wire                     be_axi_wready;
    wire  [           2-1:0] be_axi_bresp;
    wire                     be_axi_bvalid;
    wire                     be_axi_bready;
    wire  [    AXI_ID_W-1:0] be_axi_awid;
    wire  [   AXI_LEN_W-1:0] be_axi_awlen;
    wire  [           3-1:0] be_axi_awsize;
    wire  [           2-1:0] be_axi_awburst;
    wire                     be_axi_awlock;
    wire  [           4-1:0] be_axi_awcache;
    wire  [           4-1:0] be_axi_awqos;
    wire                     be_axi_wlast;
    wire  [    AXI_ID_W-1:0] be_axi_bid;



    mem2axi_glue #(
        .AXI_ID_W  (AXI_ID_W),
        .AXI_LEN_W (AXI_LEN_W),
        .AXI_ADDR_W(AXI_ADDR_W),
        .AXI_DATA_W(AXI_DATA_W)
    ) i_glue (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .mem_addr_i   (mem_addr_i),
        .mem_data_wr_i(mem_data_wr_i),
        .mem_rd_i     (mem_rd_i),
        .mem_wr_i     (mem_wr_i),
        .mem_data_rd_o(mem_data_rd_o),
        .mem_accept_o (mem_accept_o),
        .mem_ack_o    (mem_ack_o),
        .axi_arready_i(be_axi_arready),
        .axi_arvalid_o(be_axi_arvalid),
        .axi_araddr_o (be_axi_araddr),
        .axi_arid_o   (be_axi_arid),
        .axi_arlen_o  (be_axi_arlen),
        .axi_arsize_o (be_axi_arsize),
        .axi_arburst_o(be_axi_arburst),
        .axi_arlock_o (be_axi_arlock),
        .axi_arcache_o(be_axi_arcache),
        .axi_arqos_o  (be_axi_arqos),
        .axi_rready_o (be_axi_rready),
        .axi_rvalid_i (be_axi_rvalid),
        .axi_rdata_i  (be_axi_rdata),
        .axi_rresp_i  (be_axi_rresp),
        .axi_rid_i    (be_axi_rid),
        .axi_rlast_i  (be_axi_rlast),
        .axi_awready_i(be_axi_awready),
        .axi_awvalid_o(be_axi_awvalid),
        .axi_awaddr_o (be_axi_awaddr),
        .axi_awid_o   (be_axi_awid),
        .axi_awlen_o  (be_axi_awlen),
        .axi_awsize_o (be_axi_awsize),
        .axi_awburst_o(be_axi_awburst),
        .axi_awlock_o (be_axi_awlock),
        .axi_awcache_o(be_axi_awcache),
        .axi_awqos_o  (be_axi_awqos),
        .axi_wready_i (be_axi_wready),
        .axi_wdata_o  (be_axi_wdata),
        .axi_wstrb_o  (be_axi_wstrb),
        .axi_wvalid_o (be_axi_wvalid),
        .axi_wlast_o  (be_axi_wlast),
        .axi_bready_o (be_axi_bready),
        .axi_bresp_i  (be_axi_bresp),
        .axi_bvalid_i (be_axi_bvalid),
        .axi_bid_i    (be_axi_bid)
    );




`ifdef IOB
    // Internal signals for cache invalidate and write-trough buffer IO chain
    wire              invalidate_i_int;
    wire              invalidate_o_int;
    wire              wtb_empty_i_int;
    wire              wtb_empty_o_int;
    // Testbench cache front-end bus
    wire              iob_valid;
    wire [ADDR_W-1:0] iob_addr;
    wire [    32-1:0] iob_wdata;
    wire [  32/8-1:0] iob_wstrb;
    wire              iob_rvalid;
    wire [    32-1:0] iob_rdata;
    wire              iob_ready;

    mem2iob_glue #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W)
    ) i_glue (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .mem_addr_i   (mem_addr_i),
        .mem_data_wr_i(mem_data_wr_i),
        .mem_rd_i     (mem_rd_i),
        .mem_wr_i     (mem_wr_i),
        .mem_data_rd_o(mem_data_rd_o),
        .mem_accept_o (mem_accept_o),
        .mem_ack_o    (mem_ack_o),
        .iob_valid_o  (iob_valid),
        .iob_addr_o   (iob_addr),
        .iob_wdata_o  (iob_wdata),
        .iob_wstrb_o  (iob_wstrb),
        .iob_rvalid_i (iob_rvalid),
        .iob_rdata_i  (iob_rdata),
        .iob_ready_i  (iob_ready)
    );

    assign invalidate_i_int = 1'b0;
    assign wtb_empty_i_int  = 1'b1;

    // Unit Under Test (UUT) Cache instance with 'axi' back end interface.
    iob_cache_axi #(
        .FE_ADDR_W    (FE_ADDR_W),
        .FE_DATA_W    (FE_DATA_W),
        .BE_ADDR_W    (BE_ADDR_W),
        .BE_DATA_W    (BE_DATA_W),
        .NWAYS_W      (NWAYS_W),
        .NLINES_W     (NLINES_W),
        .WORD_OFFSET_W(WORD_OFFSET_W),
        .WTBUF_DEPTH_W(WTBUF_DEPTH_W),
        .REP_POLICY   (REP_POLICY),
        .WRITE_POL    (WRITE_POL),
        .USE_CTRL     (USE_CTRL),
        .USE_CTRL_CNT (USE_CTRL_CNT),
        .FE_NBYTES    (FE_NBYTES),
        .FE_NBYTES_W  (FE_NBYTES_W),
        .BE_NBYTES    (BE_NBYTES),
        .BE_NBYTES_W  (BE_NBYTES_W),
        .LINE2BE_W    (LINE2BE_W),
        .ADDR_W       (ADDR_W),
        .DATA_W       (DATA_W),
        .AXI_ID_W     (AXI_ID_W),
        .AXI_ID       (AXI_ID),
        .AXI_LEN_W    (AXI_LEN_W),
        .AXI_ADDR_W   (AXI_ADDR_W),
        .AXI_DATA_W   (AXI_DATA_W)
    ) cache (
        // clk_en_rst_s port: Clock, clock enable and reset
        .clk_i        (clk_i),
        .cke_i        (cke_i),
        .arst_i       (arst_i),
        // iob_s port: Front-end interface, when selecting the IOb FE interface.
        .iob_valid_i  (iob_valid),
        .iob_addr_i   (iob_addr),
        .iob_wdata_i  (iob_wdata),
        .iob_wstrb_i  (iob_wstrb),
        .iob_rvalid_o (iob_rvalid),
        .iob_rdata_o  (iob_rdata),
        .iob_ready_o  (iob_ready),
        // axi_m port: Back-end interface, when selecting the AXI4 BE interface.
        .axi_araddr_o (be_axi_araddr),
        .axi_arvalid_o(be_axi_arvalid),
        .axi_arready_i(be_axi_arready),
        .axi_rdata_i  (be_axi_rdata),
        .axi_rresp_i  (be_axi_rresp),
        .axi_rvalid_i (be_axi_rvalid),
        .axi_rready_o (be_axi_rready),
        .axi_arid_o   (be_axi_arid),
        .axi_arlen_o  (be_axi_arlen),
        .axi_arsize_o (be_axi_arsize),
        .axi_arburst_o(be_axi_arburst),
        .axi_arlock_o (be_axi_arlock),
        .axi_arcache_o(be_axi_arcache),
        .axi_arqos_o  (be_axi_arqos),
        .axi_rid_i    (be_axi_rid),
        .axi_rlast_i  (be_axi_rlast),
        .axi_awaddr_o (be_axi_awaddr),
        .axi_awvalid_o(be_axi_awvalid),
        .axi_awready_i(be_axi_awready),
        .axi_wdata_o  (be_axi_wdata),
        .axi_wstrb_o  (be_axi_wstrb),
        .axi_wvalid_o (be_axi_wvalid),
        .axi_wready_i (be_axi_wready),
        .axi_bresp_i  (be_axi_bresp),
        .axi_bvalid_i (be_axi_bvalid),
        .axi_bready_o (be_axi_bready),
        .axi_awid_o   (be_axi_awid),
        .axi_awlen_o  (be_axi_awlen),
        .axi_awsize_o (be_axi_awsize),
        .axi_awburst_o(be_axi_awburst),
        .axi_awlock_o (be_axi_awlock),
        .axi_awcache_o(be_axi_awcache),
        .axi_awqos_o  (be_axi_awqos),
        .axi_wlast_o  (be_axi_wlast),
        .axi_bid_i    (be_axi_bid),
        // ie_io port: Cache invalidate and write-trough buffer IO chain
        .invalidate_i (invalidate_i_int),
        .invalidate_o (invalidate_o_int),
        .wtb_empty_i  (wtb_empty_i_int),
        .wtb_empty_o  (wtb_empty_o_int)
    );
`endif
endmodule : tb_iobcache

module mem2iob_glue #(
    parameter int ADDR_W,
    parameter int DATA_W
) (
    input  logic                clk_i,
    input  logic                rst_i,
    input  logic [        31:0] mem_addr_i,
    input  logic [        31:0] mem_data_wr_i,
    input  logic                mem_rd_i,
    input  logic [         3:0] mem_wr_i,
    output logic [        31:0] mem_data_rd_o,
    output logic                mem_accept_o,
    output logic                mem_ack_o,
    output logic                iob_valid_o,
    output logic [  ADDR_W-1:0] iob_addr_o,
    output logic [  DATA_W-1:0] iob_wdata_o,
    output logic [DATA_W/8-1:0] iob_wstrb_o,
    input  logic                iob_rvalid_i,
    input  logic [  DATA_W-1:0] iob_rdata_i,
    input  logic                iob_ready_i
);
    localparam int LGREQ = 1;
    localparam int LGRSP = LGREQ + 1;

    logic              iob_rvalid;
    logic [DATA_W-1:0] iob_rdata;
    logic              iob_ready;

    //always_ff @(posedge clk_i) begin : proc_
    //    iob_rvalid <= iob_rvalid_i;
    //    iob_rdata <= iob_rdata_i;
    //    iob_ready <= iob_ready_i;
    //end
    assign iob_rvalid = iob_rvalid_i;
    assign iob_rdata  = iob_rdata_i;
    assign iob_ready  = iob_ready_i;

    // ------------------------------------------------------------------------
    typedef struct packed {
        logic [31:0] addr;
        logic [31:0] data_wr;
        logic        rd;
        logic [3:0]  wr;
    } mem_req_t;

    mem_req_t           mem_req_data_out;
    logic     [LGREQ:0] mem_req_fill;
    logic               mem_req_empty;
    logic               mem_req_full;
    logic               mem_req_push;
    logic               mem_req_pop;

    assign mem_req_push = (mem_rd_i || |mem_wr_i) && ~mem_req_full;
    assign mem_req_pop  = iob_ready && ~mem_req_empty;

    ringbuffer_sfifo #(
        .BW               ($size(mem_req_t)),
        .LGFLEN           (LGREQ),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_mem_req_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({mem_addr_i, mem_data_wr_i, mem_rd_i, mem_wr_i}),
        .i_wr   (mem_req_push),
        .o_full (mem_req_full),
        .o_fill (mem_req_fill),
        .i_rd   (mem_req_pop),
        .o_data (mem_req_data_out),
        .o_empty(mem_req_empty)
    );

    // ------------------------------------------------------------------------
    typedef struct packed {logic wr;} mem_rsp_t;

    mem_rsp_t           mem_rsp_data_out;
    logic     [LGRSP:0] mem_rsp_fill;
    logic               mem_rsp_empty;
    logic               mem_rsp_full;
    logic               mem_rsp_push;
    logic               mem_rsp_pop;

    assign mem_rsp_push = mem_req_push;
    assign mem_rsp_pop  = (iob_rvalid || mem_rsp_data_out.wr) && ~mem_rsp_empty;

    ringbuffer_sfifo #(
        .BW               ($size(mem_rsp_t)),
        .LGFLEN           (LGRSP),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_mem_rsp_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({|mem_wr_i}),
        .i_wr   (mem_rsp_push),
        .o_full (mem_rsp_full),
        .o_fill (mem_rsp_fill),
        .i_rd   (mem_rsp_pop),
        .o_data (mem_rsp_data_out),
        .o_empty(mem_rsp_empty)
    );
    // ------------------------------------------------------------------------

    assign mem_accept_o  = ~mem_req_full;
    assign mem_data_rd_o = iob_rvalid ? iob_rdata : 0;
    assign mem_ack_o     = mem_rsp_pop;

    assign iob_valid_o   = ~mem_req_empty && iob_ready;
    assign iob_addr_o    = mem_req_data_out.addr[24:0];
    assign iob_wdata_o   = mem_req_data_out.data_wr;
    assign iob_wstrb_o   = mem_req_data_out.wr;
endmodule : mem2iob_glue



module mem2axi_glue #(
    parameter int AXI_ADDR_W,
    parameter int AXI_DATA_W,
    parameter int AXI_ID_W,
    parameter int AXI_LEN_W
) (
    input  logic                    clk_i,
    input  logic                    rst_i,
    //
    input  logic [            31:0] mem_addr_i,
    input  logic [            31:0] mem_data_wr_i,
    input  logic                    mem_rd_i,
    input  logic [             3:0] mem_wr_i,
    output logic [            31:0] mem_data_rd_o,
    output logic                    mem_accept_o,
    output logic                    mem_ack_o,
    //
    input  logic                    axi_arready_i,
    output logic                    axi_arvalid_o,
    output logic [  AXI_ADDR_W-1:0] axi_araddr_o,
    output logic [    AXI_ID_W-1:0] axi_arid_o,
    output logic [   AXI_LEN_W-1:0] axi_arlen_o,
    output logic [           3-1:0] axi_arsize_o,
    output logic [           2-1:0] axi_arburst_o,
    output logic                    axi_arlock_o,
    output logic [           4-1:0] axi_arcache_o,
    output logic [           4-1:0] axi_arqos_o,
    //
    output logic                    axi_rready_o,
    input  logic                    axi_rvalid_i,
    input  logic [  AXI_DATA_W-1:0] axi_rdata_i,
    input  logic [           2-1:0] axi_rresp_i,
    input  logic [    AXI_ID_W-1:0] axi_rid_i,
    input  logic                    axi_rlast_i,
    //
    input  logic                    axi_awready_i,
    output logic                    axi_awvalid_o,
    output logic [  AXI_ADDR_W-1:0] axi_awaddr_o,
    output logic [    AXI_ID_W-1:0] axi_awid_o,
    output logic [   AXI_LEN_W-1:0] axi_awlen_o,
    output logic [           3-1:0] axi_awsize_o,
    output logic [           2-1:0] axi_awburst_o,
    output logic                    axi_awlock_o,
    output logic [           4-1:0] axi_awcache_o,
    output logic [           4-1:0] axi_awqos_o,
    //
    input  logic                    axi_wready_i,
    output logic [  AXI_DATA_W-1:0] axi_wdata_o,
    output logic [AXI_DATA_W/8-1:0] axi_wstrb_o,
    output logic                    axi_wvalid_o,
    output logic                    axi_wlast_o,
    //
    output logic                    axi_bready_o,
    input  logic [           2-1:0] axi_bresp_i,
    input  logic                    axi_bvalid_i,
    input  logic [    AXI_ID_W-1:0] axi_bid_i
);
    localparam int LGREQ = 1;
    localparam int LGRSP = LGREQ + 1;

    typedef struct packed {
        logic [31:0] addr;
        logic [31:0] data_wr;
        logic        rd;
        logic [3:0]  wr;
    } mem_req_t;

    mem_req_t           mem_req_data_out;
    logic     [LGREQ:0] mem_req_fill;
    logic               mem_req_empty;
    logic               mem_req_full;
    logic               mem_req_push;
    logic               mem_req_pop;

    assign mem_req_push = (mem_rd_i || |mem_wr_i) && ~mem_req_full;
    assign mem_req_pop  = ar_ack || aw_ack;

    ringbuffer_sfifo #(
        .BW               ($size(mem_req_t)),
        .LGFLEN           (LGREQ),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_mem_req_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({mem_addr_i, mem_data_wr_i, mem_rd_i, mem_wr_i}),
        .i_wr   (mem_req_push),
        .o_full (mem_req_full),
        .o_fill (mem_req_fill),
        .i_rd   (mem_req_pop),
        .o_data (mem_req_data_out),
        .o_empty(mem_req_empty)
    );

    // ------------------------------------------------------------------------
    typedef struct packed {
        logic [31:0] addr;
        logic [31:0] data_wr;
        logic        rd;
        logic [3:0]  wr;
    } mem_rsp_t;


    mem_rsp_t           mem_rsp_data_out;
    logic     [LGRSP:0] mem_rsp_fill;
    logic               mem_rsp_empty;
    logic               mem_rsp_full;
    logic               mem_rsp_push;
    logic               mem_rsp_pop;

    assign mem_rsp_push = mem_req_pop;
    assign mem_rsp_pop  = ((r_ack && mem_rsp_data_out.rd) || (b_ack && |mem_rsp_data_out.wr)) && ~mem_rsp_empty;

    ringbuffer_sfifo #(
        .BW               ($size(mem_rsp_t)),
        .LGFLEN           (LGRSP),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_mem_rsp_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data (mem_req_data_out),
        .i_wr   (mem_rsp_push),
        .o_full (mem_rsp_full),
        .o_fill (mem_rsp_fill),
        .i_rd   (mem_rsp_pop),
        .o_data (mem_rsp_data_out),
        .o_empty(mem_rsp_empty)
    );
    // ------------------------------------------------------------------------


    logic ar_ack;
    logic aw_ack;
    logic r_ack;
    logic w_ack;
    logic b_ack;

    assign ar_ack        = axi_arready_i && axi_arvalid_o;
    assign aw_ack        = axi_awready_i && axi_awvalid_o;
    assign r_ack         = axi_rready_o && axi_rvalid_i;
    assign w_ack         = axi_wready_i && axi_wvalid_o;
    assign b_ack         = axi_bready_o && axi_bvalid_i;

    assign axi_rready_o  = mem_rsp_data_out.rd;
    assign axi_bready_o  = |mem_rsp_data_out.wr;
    assign axi_arvalid_o = ~mem_req_empty && mem_req_data_out.rd;
    assign axi_awvalid_o = ~mem_req_empty && |mem_req_data_out.wr;
    assign axi_wvalid_o  = ~mem_req_empty && |mem_req_data_out.wr;
    assign axi_wlast_o   = axi_awvalid_o;

    assign axi_araddr_o  = axi_arvalid_o ? mem_req_data_out.addr : 0;
    assign axi_awaddr_o  = axi_awvalid_o ? mem_req_data_out.addr : 0;
    assign axi_wdata_o   = axi_wvalid_o ? mem_req_data_out.data_wr : 0;
    assign axi_wstrb_o   = axi_wvalid_o ? mem_req_data_out.wr : 0;

    assign mem_data_rd_o = (r_ack && mem_rsp_data_out.rd) ? axi_rdata_i : 0;
    assign mem_accept_o  = ~mem_req_full;
    assign mem_ack_o     = mem_rsp_pop;

    // constants
    assign axi_arid_o    = 0;
    assign axi_arlen_o   = 0;
    assign axi_arsize_o  = 2;
    assign axi_arburst_o = 0;
    assign axi_arlock_o  = 0;
    assign axi_arcache_o = 0;
    assign axi_arqos_o   = 0;
    assign axi_awid_o    = 0;
    assign axi_awlen_o   = 0;
    assign axi_awsize_o  = 2;
    assign axi_awburst_o = 0;
    assign axi_awlock_o  = 0;
    assign axi_awcache_o = 0;
    assign axi_awqos_o   = 0;

endmodule : mem2axi_glue
