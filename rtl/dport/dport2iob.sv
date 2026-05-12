module dport2iob #(
    parameter int ADDR_W,
    parameter int DATA_W
) (
    input  logic                clk_i,
    input  logic                rst_i,
    //
    input  logic [        31:0] mem_addr_i,
    input  logic [        31:0] mem_data_wr_i,
    input  logic                mem_rd_i,
    input  logic [         3:0] mem_wr_i,
    output logic [        31:0] mem_data_rd_o,
    output logic                mem_accept_o,
    output logic                mem_ack_o,
    //
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

    sfifo #(
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

    sfifo #(
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
endmodule : dport2iob


