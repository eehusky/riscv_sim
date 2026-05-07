module dport_rsp_queue #(
    parameter int LGDEPTH = 3
) (
    input  logic        clk_i,
    input  logic        rst_i,
    //
    input  logic        ack_i,
    input  logic [31:0] data_rd_i,
    input  logic        error_i,
    //
    input  logic        pop_i,
    //
    output logic        ack_o,
    output logic [31:0] data_rd_o,
    output logic        error_o
);

    typedef struct packed {
        logic        ack;
        logic [31:0] data_rd;
        logic        error;
    } rsp_data_t;

    rsp_data_t             rsp_data_out;
    logic      [LGDEPTH:0] rsp_fill;
    logic                  rsp_empty;
    logic                  rsp_full;
    logic                  rsp_push;
    logic                  rsp_pop;

    assign rsp_push = ack_i;
    assign rsp_pop  = pop_i && ~rsp_empty;

    ringbuffer_sfifo #(
        .BW               ($size(rsp_data_t)),
        .LGFLEN           (LGDEPTH),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(1)
    ) i_rsp_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({ack_i, data_rd_i, error_i}),
        .i_wr   (rsp_push),
        .i_rd   (rsp_pop),
        .o_full (rsp_full),
        .o_fill (rsp_fill),
        .o_data (rsp_data_out),
        .o_empty(rsp_empty)
    );

    assign ack_o     = rsp_data_out.ack && ~rsp_empty;
    assign data_rd_o = rsp_data_out.data_rd;
    assign error_o   = rsp_data_out.error;

    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(rsp_push && rsp_full));
        assert (~(rsp_pop && rsp_empty));
    end


endmodule : dport_rsp_queue

