
module mem2axil_glue #(
    parameter int ADDR_WIDTH = 32
) (
    input  logic                  clk_i,
    input  logic                  rst_i,
    //
    input  logic [          31:0] mem_addr_i,
    input  logic [          31:0] mem_data_wr_i,
    input  logic                  mem_rd_i,
    input  logic [           3:0] mem_wr_i,
    output logic [          31:0] mem_data_rd_o,
    output logic                  mem_accept_o,
    output logic                  mem_error_o,
    output logic                  mem_ack_o,
    //
    output logic [ADDR_WIDTH-1:0] araddr,
    output logic [           2:0] arprot,
    input  logic                  arready,
    output logic                  arvalid,
    output logic [ADDR_WIDTH-1:0] awaddr,
    output logic [           2:0] awprot,
    input  logic                  awready,
    output logic                  awvalid,
    output logic                  bready,
    input  logic [           1:0] bresp,
    input  logic                  bvalid,
    input  logic [          31:0] rdata,
    output logic                  rready,
    input  logic [           1:0] rresp,
    input  logic                  rvalid,
    output logic [          31:0] wdata,
    input  logic                  wready,
    output logic [           3:0] wstrb,
    output logic                  wvalid
);

    localparam int LGREQ = 1;
    localparam int LGRSP = LGREQ + 1;

    // ------------------------------------------------------------------------

    logic ar_ack;
    logic aw_ack;
    logic r_ack;
    logic w_ack;
    logic b_ack;

    assign ar_ack = arready && arvalid;
    assign aw_ack = awready && awvalid;
    assign r_ack  = rready && rvalid;
    assign w_ack  = wready && wvalid;
    assign b_ack  = bready && bvalid;

    // ------------------------------------------------------------------------

    typedef struct packed {
        logic [31:0] addr;
        logic        rd;
        logic        wr;
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
        .i_data ({mem_addr_i, mem_rd_i, |mem_wr_i}),
        .i_wr   (mem_req_push),
        .o_full (mem_req_full),
        .o_fill (mem_req_fill),
        .i_rd   (mem_req_pop),
        .o_data (mem_req_data_out),
        .o_empty(mem_req_empty)
    );

    // ------------------------------------------------------------------------

    typedef struct packed {
        logic [31:0] data_wr;
        logic [3:0]  wr;
    } wdata_t;

    wdata_t           wdata_data_out;
    logic   [LGREQ:0] wdata_fill;
    logic             wdata_empty;
    logic             wdata_full;
    logic             wdata_push;
    logic             wdata_pop;

    assign wdata_push = mem_req_push;
    assign wdata_pop  = ar_ack || w_ack;

    ringbuffer_sfifo #(
        .BW               ($size(wdata_t)),
        .LGFLEN           (LGREQ),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_wdata_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({mem_data_wr_i, mem_wr_i}),
        .i_wr   (wdata_push),
        .o_full (wdata_full),
        .o_fill (wdata_fill),
        .i_rd   (wdata_pop),
        .o_data (wdata_data_out),
        .o_empty(wdata_empty)
    );

    // ------------------------------------------------------------------------

    typedef struct packed {
        logic rd;
        logic wr;
    } mem_rsp_t;

    mem_rsp_t           mem_rsp_data_out;
    logic     [LGRSP:0] mem_rsp_fill;
    logic               mem_rsp_empty;
    logic               mem_rsp_full;
    logic               mem_rsp_push;
    logic               mem_rsp_pop;

    assign mem_rsp_push = mem_req_pop;
    assign mem_rsp_pop  = ((r_ack && mem_rsp_data_out.rd) || (b_ack && mem_rsp_data_out.wr)) && ~mem_rsp_empty;

    ringbuffer_sfifo #(
        .BW               ($size(mem_rsp_t)),
        .LGFLEN           (LGRSP),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_mem_rsp_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({mem_req_data_out.rd, mem_req_data_out.wr}),
        .i_wr   (mem_rsp_push),
        .o_full (mem_rsp_full),
        .o_fill (mem_rsp_fill),
        .i_rd   (mem_rsp_pop),
        .o_data (mem_rsp_data_out),
        .o_empty(mem_rsp_empty)
    );

    // ------------------------------------------------------------------------

    assign araddr        = arvalid ? mem_req_data_out.addr : 0;
    assign arvalid       = ~mem_req_empty && mem_req_data_out.rd;
    assign rready        = mem_rsp_data_out.rd;

    assign awaddr        = awvalid ? mem_req_data_out.addr : 0;
    assign awvalid       = ~mem_req_empty && mem_req_data_out.wr;

    assign wvalid        = ~wdata_empty && |wdata_data_out.wr;
    assign wdata         = wvalid ? wdata_data_out.data_wr : 0;
    assign wstrb         = wvalid ? wdata_data_out.wr : 0;
    assign bready        = mem_rsp_data_out.wr;

    assign mem_data_rd_o = (r_ack && mem_rsp_data_out.rd) ? rdata : 0;
    assign mem_accept_o  = ~mem_req_full;
    assign mem_ack_o     = mem_rsp_pop;
    assign mem_error_o   = mem_rsp_pop && (rresp[1] || bresp[1]);

    // constants
    assign arprot        = 0;
    assign awprot        = 0;
endmodule : mem2axil_glue
