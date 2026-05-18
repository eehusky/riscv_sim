module obi_rsp_queue #(
    parameter int LGDEPTH = 3
) (
    input logic         clk_i,
    input logic         rst_i,
          obi_if.master in,
          obi_if.slave  out
);

    typedef struct packed {
        logic                     rvalid;
        logic [in.DATA_WIDTH-1:0] rdata;
        logic                     err;
        logic [in.ID_WIDTH-1:0]   rid;
    } rsp_data_t;

    rsp_data_t             rsp_data_out;
    logic      [LGDEPTH:0] rsp_fill;
    logic                  rsp_empty;
    logic                  rsp_full;
    logic                  rsp_push;
    logic                  rsp_pop;

    assign rsp_push = in.rvalid;
    assign rsp_pop  = out.rready && ~rsp_empty;

    sfifo #(
        .BW               ($size(rsp_data_t)),
        .LGFLEN           (LGDEPTH),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(1)
    ) i_rsp_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({in.rvalid, in.rdata, in.err, in.rid}),
        .i_wr   (rsp_push),
        .i_rd   (rsp_pop),
        .o_full (rsp_full),
        .o_fill (rsp_fill),
        .o_data (rsp_data_out),
        .o_empty(rsp_empty)
    );

    assign out.rvalid = rsp_data_out.rvalid && ~rsp_empty;
    assign out.rdata  = rsp_data_out.rdata;
    assign out.err    = rsp_data_out.err;
    assign out.rid    = rsp_data_out.rid;
    assign in.rready  = ~rsp_full;

    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(rsp_push && rsp_full));
        assert (~(rsp_pop && rsp_empty));
    end


endmodule : obi_rsp_queue

