module obi_demux #(
    parameter N_TARGETS,
    parameter SLAVE_ADDR,
    parameter SLAVE_MASK
) (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave  cpu,
    obi_if.master segments[N_TARGETS]
);
    obi_if #(
        .DATA_WIDTH(cpu.DATA_WIDTH),
        .ADDR_WIDTH(cpu.ADDR_WIDTH),
        .STRB_WIDTH(cpu.STRB_WIDTH),
        .ID_WIDTH  (cpu.ID_WIDTH)
    ) dummy ();

    obi_dummy i_obi_dummy (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(dummy)
    );

    typedef struct packed {
        logic                      we;
        logic [cpu.STRB_WIDTH-1:0] be;
        logic [cpu.DATA_WIDTH-1:0] wdata;
        logic [cpu.ID_WIDTH-1:0]   aid;
    } decode_data_t;

    decode_data_t               decode_data;
    logic                       decode_stall;
    logic                       decode_valid;
    logic         [       31:0] decode_addr;
    logic         [N_TARGETS:0] req_grant;

    obi_addrdecode #(
        .AW            (32),
        .DW            ($size(decode_data_t)),
        .NS            (N_TARGETS),
        .SLAVE_ADDR    (SLAVE_ADDR),
        .SLAVE_MASK    (SLAVE_MASK),
        .ACCESS_ALLOWED(-1),
        .OPT_REGISTERED(0),
        .OPT_LOWPOWER  (1)
    ) i_addrdecode (
        .i_clk   (clk_i),
        .i_reset (rst_i),
        //
        .i_valid (cpu.req),
        .o_stall (cpu.gnt),
        .i_addr  (cpu.addr),
        .i_data  ({cpu.we, cpu.be, cpu.wdata, cpu.aid}),
        //
        .o_valid (decode_valid),
        .i_stall (decode_stall),
        .o_addr  (decode_addr),
        .o_data  (decode_data),
        //
        .o_decode(req_grant)
    );
    typedef struct packed {logic gnt;} obi_req_t;


    // move interfaces into local struct array and append
    // our no decode dummy device
    obi_req_t               req_data[N_TARGETS+1];
    logic     [N_TARGETS:0] request;

    always_comb begin
        decode_stall = 1;
        for (int i = 0; i < N_TARGETS + 1; i++) begin
            if (req_grant == 1 << i) begin
                decode_stall = req_data[i].gnt;
            end
        end
    end

    for (genvar i = 0; i < N_TARGETS; i++) begin : g_channel_data
        assign segments[i].req   = decode_valid && req_grant[i];
        assign segments[i].addr  = decode_addr;
        assign segments[i].we    = decode_data.we;
        assign segments[i].be    = decode_data.be;
        assign segments[i].wdata = decode_data.wdata;
        assign segments[i].aid   = decode_data.aid;
        assign req_data[i].gnt   = segments[i].gnt;
    end
    assign dummy.req               = decode_valid && req_grant[N_TARGETS];
    assign dummy.addr              = decode_addr;
    assign dummy.we                = decode_data.we;
    assign dummy.be                = decode_data.be;
    assign dummy.wdata             = decode_data.wdata;
    assign dummy.aid               = decode_data.aid;
    assign req_data[N_TARGETS].gnt = dummy.gnt;


    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------


    localparam int LGRSP = 3;

    typedef struct packed {logic [N_TARGETS:0] decode;} rsp_data_t;

    rsp_data_t           rsp_data_out;
    logic      [LGRSP:0] rsp_fill;
    logic                rsp_empty;
    logic                rsp_full;
    logic                rsp_push;
    logic                rsp_pop;

    assign rsp_push = decode_valid && decode_stall;
    assign rsp_pop  = |rsp_ack && cpu.rready;

    sfifo #(
        .BW               ($size(rsp_data_t)),
        .LGFLEN           (LGRSP),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_pending_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({req_grant}),
        .i_wr   (rsp_push),
        .i_rd   (rsp_pop),
        .o_full (rsp_full),
        .o_fill (rsp_fill),
        .o_data (rsp_data_out),
        .o_empty(rsp_empty)
    );

    logic [N_TARGETS:0] rsp_ready;
    logic [N_TARGETS:0] rsp_ack;
    logic [N_TARGETS:0] rsp_grant;

    obi_if #(
        .DATA_WIDTH(cpu.DATA_WIDTH),
        .ADDR_WIDTH(cpu.ADDR_WIDTH),
        .STRB_WIDTH(cpu.STRB_WIDTH),
        .ID_WIDTH  (cpu.ID_WIDTH)
    ) segment_rsp[N_TARGETS+1] ();
    assign rsp_grant = rsp_data_out.decode;
    assign rsp_ack   = rsp_ready & rsp_grant;

    for (genvar i = 0; i < N_TARGETS + 1; i++) begin : g_rspack
        assign rsp_ready[i]          = segment_rsp[i].rvalid;
        assign segment_rsp[i].rready = rsp_ack[i];
    end

    for (genvar i = 0; i < N_TARGETS; i++) begin : g_segrspq
        obi_rsp_queue i_obi_rsp_queue_periph (
            .clk_i(clk_i),
            .rst_i(rst_i),
            .in   (segments[i]),
            .out  (segment_rsp[i])
        );
    end
    obi_rsp_queue i_obi_rsp_queue_periph (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .in   (dummy),
        .out  (segment_rsp[N_TARGETS])
    );

    typedef struct packed {
        logic                      rready;
        logic                      rvalid;
        logic [cpu.DATA_WIDTH-1:0] rdata;
        logic                      err;
        logic [cpu.ID_WIDTH-1:0]   rid;
    } obi_rsp_t;

    obi_rsp_t rsp_data[N_TARGETS+1];
    for (genvar i = 0; i < N_TARGETS + 1; i++) begin : g_rsp_data
        assign rsp_data[i].rvalid = segment_rsp[i].rvalid;
        assign rsp_data[i].rdata  = segment_rsp[i].rdata;
        assign rsp_data[i].err    = segment_rsp[i].err;
        assign rsp_data[i].rid    = segment_rsp[i].rid;
    end

    always_comb begin
        cpu.rvalid = 0;
        cpu.rdata  = 0;
        cpu.err    = 0;
        cpu.rid    = 0;
        for (int i = 0; i < N_TARGETS + 1; i++) begin
            if (rsp_ack == 1 << i) begin
                cpu.rvalid = rsp_data[i].rvalid;
                cpu.rdata  = rsp_data[i].rdata;
                cpu.err    = rsp_data[i].err;
                cpu.rid    = rsp_data[i].rid;
            end
        end
    end

    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(rsp_push && rsp_full));
        assert (~(rsp_pop && rsp_empty));
        assert ((decode_valid && |req_grant) || ~decode_valid);
    end

endmodule : obi_demux

