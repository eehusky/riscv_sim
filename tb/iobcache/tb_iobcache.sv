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
    logic                    mem_error_o;
    logic                    mem_ack_o;
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

    wire  [  AXI_ADDR_W-1:0] be_iob_araddr;
    wire                     be_iob_arvalid;
    wire                     be_iob_arready;
    wire  [  AXI_DATA_W-1:0] be_iob_rdata;
    wire  [           2-1:0] be_iob_rresp;
    wire                     be_iob_rvalid;
    wire                     be_iob_rready;
    wire  [    AXI_ID_W-1:0] be_iob_arid;
    wire  [   AXI_LEN_W-1:0] be_iob_arlen;
    wire  [           3-1:0] be_iob_arsize;
    wire  [           2-1:0] be_iob_arburst;
    wire                     be_iob_arlock;
    wire  [           4-1:0] be_iob_arcache;
    wire  [           4-1:0] be_iob_arqos;
    wire  [    AXI_ID_W-1:0] be_iob_rid;
    wire                     be_iob_rlast;
    wire  [  AXI_ADDR_W-1:0] be_iob_awaddr;
    wire                     be_iob_awvalid;
    wire                     be_iob_awready;
    wire  [  AXI_DATA_W-1:0] be_iob_wdata;
    wire  [AXI_DATA_W/8-1:0] be_iob_wstrb;
    wire                     be_iob_wvalid;
    wire                     be_iob_wready;
    wire  [           2-1:0] be_iob_bresp;
    wire                     be_iob_bvalid;
    wire                     be_iob_bready;
    wire  [    AXI_ID_W-1:0] be_iob_awid;
    wire  [   AXI_LEN_W-1:0] be_iob_awlen;
    wire  [           3-1:0] be_iob_awsize;
    wire  [           2-1:0] be_iob_awburst;
    wire                     be_iob_awlock;
    wire  [           4-1:0] be_iob_awcache;
    wire  [           4-1:0] be_iob_awqos;
    wire                     be_iob_wlast;
    wire  [    AXI_ID_W-1:0] be_iob_bid;


    typedef struct packed {
        logic [31:0] data_wr;
        logic        rd;
        logic [3:0]  wr;
    } mem_data_t;

    mem_data_t        decode_data;
    logic             decode_stall;
    logic             decode_valid;
    logic             decode_stall_o;
    logic      [31:0] decode_addr;
    logic      [ 2:0] o_decode;


    addrdecode #(
        .NS            (2),
        .AW            (32),
        .DW            (32 + 4 + 1),
        .SLAVE_ADDR    ({32'h80000000, 32'hA0000000}),
        .SLAVE_MASK    ({32'hE0000000, 32'hE0000000}),
        .ACCESS_ALLOWED(-1),
        .OPT_REGISTERED(0),
        .OPT_LOWPOWER  (1)
    ) i_addrdecode (
        .i_clk   (i_clk),
        .i_reset (i_reset),
        //
        .i_valid (mem_rd_i || |mem_wr_i),
        .o_stall (mem_accept_o),
        .i_addr  (mem_addr_i),
        .i_data  ({mem_data_wr_i, mem_rd_i, mem_wr_i}),
        //
        .o_valid (decode_valid),
        .i_stall (decode_stall),
        .o_addr  (decode_addr),
        .o_data  (decode_data),
        //
        .o_decode(o_decode)
    );

    always_comb begin : proc_decode
        case (o_decode)
            3'b001: begin
                mem_iob_addr_i    = {3'b0, decode_addr[28:0]};
                mem_iob_data_wr_i = decode_data.data_wr;
                mem_iob_rd_i      = decode_data.rd;
                mem_iob_wr_i      = decode_data.wr;
                mem_error_o       = 0;
                decode_stall      = mem_iob_accept_o;
            end
            3'b010: begin
                mem_axi_addr_i    = {3'b0, decode_addr[28:0]};
                mem_axi_data_wr_i = decode_data.data_wr;
                mem_axi_rd_i      = decode_data.rd;
                mem_axi_wr_i      = decode_data.wr;
                mem_error_o       = 0;
                decode_stall      = mem_axi_accept_o;
            end
            3'b100: begin

            end
            default: begin
                mem_axi_addr_i    = 0;
                mem_axi_data_wr_i = 0;
                mem_axi_rd_i      = 0;
                mem_axi_wr_i      = 0;
                mem_iob_addr_i    = 0;
                mem_iob_data_wr_i = 0;
                mem_iob_rd_i      = 0;
                mem_iob_wr_i      = 0;
                decode_stall      = 0;
                mem_error_o       = 1;
            end
        endcase
    end

    always_comb begin : proc_ack
        case ({
            1'b0, mem_axi_ack_o, mem_iob_ack_o
        })
            3'b001: begin
                mem_data_rd_o = mem_iob_data_rd_o;
                mem_ack_o     = mem_iob_ack_o;
            end
            3'b010: begin
                mem_data_rd_o = mem_axi_data_rd_o;
                mem_ack_o     = mem_axi_ack_o;
            end
            3'b100: begin

            end
            default: begin
                mem_data_rd_o = 0;
                mem_ack_o     = 0;
            end
        endcase
    end



    `define AXI
`ifdef AXI
    logic [31:0] mem_axi_addr_i;
    logic [31:0] mem_axi_data_wr_i;
    logic        mem_axi_rd_i;
    logic [ 3:0] mem_axi_wr_i;
    logic [31:0] mem_axi_data_rd_o;
    logic        mem_axi_accept_o;
    logic        mem_axi_ack_o;

    mem2axi_glue #(
        .AXI_ID_W  (AXI_ID_W),
        .AXI_LEN_W (AXI_LEN_W),
        .AXI_ADDR_W(AXI_ADDR_W),
        .AXI_DATA_W(AXI_DATA_W)
    ) i_mem2axi_glue (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .mem_addr_i   (mem_axi_addr_i),
        .mem_data_wr_i(mem_axi_data_wr_i),
        .mem_rd_i     (mem_axi_rd_i),
        .mem_wr_i     (mem_axi_wr_i),
        .mem_data_rd_o(mem_axi_data_rd_o),
        .mem_accept_o (mem_axi_accept_o),
        .mem_ack_o    (mem_axi_ack_o),
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
`endif

    `define IOB
`ifdef IOB
    logic [      31:0] mem_iob_addr_i;
    logic [      31:0] mem_iob_data_wr_i;
    logic              mem_iob_rd_i;
    logic [       3:0] mem_iob_wr_i;
    logic [      31:0] mem_iob_data_rd_o;
    logic              mem_iob_accept_o;
    logic              mem_iob_ack_o;


    // Internal signals for cache invalidate and write-trough buffer IO chain
    wire               invalidate_i_int;
    wire               invalidate_o_int;
    wire               wtb_empty_i_int;
    wire               wtb_empty_o_int;
    // Testbench cache front-end bus
    wire               iob_valid;
    wire  [ADDR_W-1:0] iob_addr;
    wire  [    32-1:0] iob_wdata;
    wire  [  32/8-1:0] iob_wstrb;
    wire               iob_rvalid;
    wire  [    32-1:0] iob_rdata;
    wire               iob_ready;

    mem2iob_glue #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W)
    ) i_mem2iob_glue (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .mem_addr_i   (mem_iob_addr_i),
        .mem_data_wr_i(mem_iob_data_wr_i),
        .mem_rd_i     (mem_iob_rd_i),
        .mem_wr_i     (mem_iob_wr_i),
        .mem_data_rd_o(mem_iob_data_rd_o),
        .mem_accept_o (mem_iob_accept_o),
        .mem_ack_o    (mem_iob_ack_o),
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
        .axi_araddr_o (be_iob_araddr),
        .axi_arvalid_o(be_iob_arvalid),
        .axi_arready_i(be_iob_arready),
        .axi_rdata_i  (be_iob_rdata),
        .axi_rresp_i  (be_iob_rresp),
        .axi_rvalid_i (be_iob_rvalid),
        .axi_rready_o (be_iob_rready),
        .axi_arid_o   (be_iob_arid),
        .axi_arlen_o  (be_iob_arlen),
        .axi_arsize_o (be_iob_arsize),
        .axi_arburst_o(be_iob_arburst),
        .axi_arlock_o (be_iob_arlock),
        .axi_arcache_o(be_iob_arcache),
        .axi_arqos_o  (be_iob_arqos),
        .axi_rid_i    (be_iob_rid),
        .axi_rlast_i  (be_iob_rlast),
        .axi_awaddr_o (be_iob_awaddr),
        .axi_awvalid_o(be_iob_awvalid),
        .axi_awready_i(be_iob_awready),
        .axi_wdata_o  (be_iob_wdata),
        .axi_wstrb_o  (be_iob_wstrb),
        .axi_wvalid_o (be_iob_wvalid),
        .axi_wready_i (be_iob_wready),
        .axi_bresp_i  (be_iob_bresp),
        .axi_bvalid_i (be_iob_bvalid),
        .axi_bready_o (be_iob_bready),
        .axi_awid_o   (be_iob_awid),
        .axi_awlen_o  (be_iob_awlen),
        .axi_awsize_o (be_iob_awsize),
        .axi_awburst_o(be_iob_awburst),
        .axi_awlock_o (be_iob_awlock),
        .axi_awcache_o(be_iob_awcache),
        .axi_awqos_o  (be_iob_awqos),
        .axi_wlast_o  (be_iob_wlast),
        .axi_bid_i    (be_iob_bid),
        // ie_io port: Cache invalidate and write-trough buffer IO chain
        .invalidate_i (invalidate_i_int),
        .invalidate_o (invalidate_o_int),
        .wtb_empty_i  (wtb_empty_i_int),
        .wtb_empty_o  (wtb_empty_o_int)
    );
`endif
endmodule : tb_iobcache
