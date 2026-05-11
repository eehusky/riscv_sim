module dport_mux2 #(
    parameter N_SEGMENTS = dport_pkg::N_SEGMENTS,
    parameter SLAVE_ADDR = dport_pkg::SLAVE_ADDR,
    parameter SLAVE_MASK = dport_pkg::SLAVE_MASK
) (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave  cpu,
    obi_if.master segments[N_SEGMENTS]
);
    localparam int NS = N_SEGMENTS;


    obi_if dummy ();

    dport_dummy i_dport_dummy(
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

    decode_data_t     decode_data;
    logic             decode_stall;
    logic             decode_valid;
    logic      [31:0] decode_addr;
    logic      [NS:0] req_grant;

    dport_addrdecode #(
        .AW            (32),
        .DW            ($size(decode_data_t)),
        .NS            (NS),
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
    typedef struct packed {
        logic                      gnt;
        logic                      req;
        logic [cpu.ADDR_WIDTH-1:0] addr;
        logic                      we;
        logic [cpu.STRB_WIDTH-1:0] be;
        logic [cpu.DATA_WIDTH-1:0] wdata;
        logic [cpu.ID_WIDTH-1:0]   aid;
    } obi_req_t;


    // move interfaces into local struct array and append
    // our no decode dummy device
    obi_req_t req_data[NS+1];
    for (genvar i = 0; i < NS; i++) begin : g_channel_data
        assign segments[i].req   = req_data[i].req;
        assign segments[i].addr  = req_data[i].addr;
        assign segments[i].we    = req_data[i].we;
        assign segments[i].be    = req_data[i].be;
        assign segments[i].wdata = req_data[i].wdata;
        assign segments[i].aid   = req_data[i].aid;
        assign req_data[i].gnt   = segments[i].gnt;
    end
    assign dummy.req   = req_data[NS].req;
    assign dummy.addr  = req_data[NS].addr;
    assign dummy.we    = req_data[NS].we;
    assign dummy.be    = req_data[NS].be;
    assign dummy.wdata = req_data[NS].wdata;
    assign dummy.aid   = req_data[NS].aid;
    assign req_data[NS].gnt   = dummy.gnt;

    always_comb begin
        decode_stall = 0;
        for (int i = 0; i < NS + 1; i++) begin
            req_data[i].req   = 0;
            req_data[i].addr  = 0;
            req_data[i].we    = 0;
            req_data[i].be    = 0;
            req_data[i].wdata = 0;
            req_data[i].aid   = 0;
        end
        for (int i = 0; i < NS + 1; i++) begin
            if (req_grant == 1 << i) begin
                req_data[i].req   = decode_valid;
                req_data[i].addr  = decode_addr;
                req_data[i].we    = decode_data.we;
                req_data[i].be    = decode_data.be;
                req_data[i].wdata = decode_data.wdata;
                req_data[i].aid   = decode_data.aid;
                decode_stall      = req_data[i].gnt;
            end
        end
    end

    /*
    always_comb begin : proc_decode
        segments[0].req   = 0;
        segments[0].addr  = 0;
        segments[0].we    = 0;
        segments[0].be    = 0;
        segments[0].wdata = 0;
        segments[0].aid   = 0;
        segments[1].req   = 0;
        segments[1].addr  = 0;
        segments[1].we    = 0;
        segments[1].be    = 0;
        segments[1].wdata = 0;
        segments[1].aid   = 0;
        segments[2].req   = 0;
        segments[2].addr  = 0;
        segments[2].we    = 0;
        segments[2].be    = 0;
        segments[2].wdata = 0;
        segments[2].aid   = 0;
        segments[3].req   = 0;
        segments[3].addr  = 0;
        segments[3].we    = 0;
        segments[3].be    = 0;
        segments[3].wdata = 0;
        segments[3].aid   = 0;
        segments[4].req   = 0;
        segments[4].addr  = 0;
        segments[4].we    = 0;
        segments[4].be    = 0;
        segments[4].wdata = 0;
        segments[4].aid   = 0;
        dummy.req         = 0;
        dummy.addr        = 0;
        dummy.we          = 0;
        dummy.be          = 0;
        dummy.wdata       = 0;
        dummy.aid         = 0;
        decode_stall      = 0;
        case (req_grant)
            6'b000001: begin
                segments[0].req   = decode_valid;
                segments[0].addr  = decode_addr;
                segments[0].we    = decode_data.we;
                segments[0].be    = decode_data.be;
                segments[0].wdata = decode_data.wdata;
                segments[0].aid   = decode_data.aid;
                decode_stall      = segments[0].gnt;
            end
            6'b000010: begin
                segments[1].req   = decode_valid;
                segments[1].addr  = decode_addr;
                segments[1].we    = decode_data.we;
                segments[1].be    = decode_data.be;
                segments[1].wdata = decode_data.wdata;
                segments[1].aid   = decode_data.aid;
                decode_stall      = segments[1].gnt;
            end
            6'b000100: begin
                segments[2].req   = decode_valid;
                segments[2].addr  = decode_addr;
                segments[2].we    = decode_data.we;
                segments[2].be    = decode_data.be;
                segments[2].wdata = decode_data.wdata;
                segments[2].aid   = decode_data.aid;
                decode_stall      = segments[2].gnt;
            end
            6'b001000: begin
                segments[3].req   = decode_valid;
                segments[3].addr  = decode_addr;
                segments[3].we    = decode_data.we;
                segments[3].be    = decode_data.be;
                segments[3].wdata = decode_data.wdata;
                segments[3].aid   = decode_data.aid;
                decode_stall      = segments[3].gnt;
            end
            6'b010000: begin
                segments[4].req   = decode_valid;
                segments[4].addr  = decode_addr;
                segments[4].we    = decode_data.we;
                segments[4].be    = decode_data.be;
                segments[4].wdata = decode_data.wdata;
                segments[4].aid   = decode_data.aid;
                decode_stall      = segments[4].gnt;
            end
            6'b100000: begin
                dummy.req    = decode_valid;
                dummy.addr   = decode_addr;
                dummy.we     = decode_data.we;
                dummy.be     = decode_data.be;
                dummy.wdata  = decode_data.wdata;
                dummy.aid    = decode_data.aid;
                decode_stall = dummy.gnt;
            end
            default: begin
                segments[0].req   = 0;
                segments[0].addr  = 0;
                segments[0].we    = 0;
                segments[0].be    = 0;
                segments[0].wdata = 0;
                segments[0].aid   = 0;
                segments[1].req   = 0;
                segments[1].addr  = 0;
                segments[1].we    = 0;
                segments[1].be    = 0;
                segments[1].wdata = 0;
                segments[1].aid   = 0;
                segments[2].req   = 0;
                segments[2].addr  = 0;
                segments[2].we    = 0;
                segments[2].be    = 0;
                segments[2].wdata = 0;
                segments[2].aid   = 0;
                segments[3].req   = 0;
                segments[3].addr  = 0;
                segments[3].we    = 0;
                segments[3].be    = 0;
                segments[3].wdata = 0;
                segments[3].aid   = 0;
                segments[4].req   = 0;
                segments[4].addr  = 0;
                segments[4].we    = 0;
                segments[4].be    = 0;
                segments[4].wdata = 0;
                segments[4].aid   = 0;
                dummy.req         = 0;
                dummy.addr        = 0;
                dummy.we          = 0;
                dummy.be          = 0;
                dummy.wdata       = 0;
                dummy.aid         = 0;
                decode_stall      = 0;
            end
        endcase
    end
    */


    localparam int LGRSP = 3;

    typedef struct packed {logic [NS:0] decode;} rsp_data_t;

    rsp_data_t           rsp_data_out;
    logic      [LGRSP:0] rsp_fill;
    logic                rsp_empty;
    logic                rsp_full;
    logic                rsp_push;
    logic                rsp_pop;

    assign rsp_push = decode_valid && decode_stall;
    assign rsp_pop  = |rsp_ack && cpu.rready;

    ringbuffer_sfifo #(
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

    logic [NS:0] rsp_ready;
    logic [NS:0] rsp_ack;
    logic [NS:0] rsp_grant;

    obi_if segment_rsp[NS+1] ();
    assign rsp_grant = rsp_data_out.decode;
    assign rsp_ack = rsp_ready & rsp_grant;

    for (genvar i = 0; i < NS+1; i++) begin : g_rspack
        assign rsp_ready[i] = segment_rsp[i].rvalid;
        assign segment_rsp[i].rready = rsp_ack[i];
    end

    //assign rsp_ready = {
    //    segment_rsp[5].rvalid,
    //    segment_rsp[4].rvalid,
    //    segment_rsp[3].rvalid,
    //    segment_rsp[2].rvalid,
    //    segment_rsp[1].rvalid,
    //    segment_rsp[0].rvalid
    //};
    //assign segment_rsp[0].rready = rsp_ack[0];
    //assign segment_rsp[1].rready = rsp_ack[1];
    //assign segment_rsp[2].rready = rsp_ack[2];
    //assign segment_rsp[3].rready = rsp_ack[3];
    //assign segment_rsp[4].rready = rsp_ack[4];
    //assign segment_rsp[5].rready = rsp_ack[5];

    for (genvar i = 0; i < NS; i++) begin : g_segrspq
        dport_rsp_queue i_dport_rsp_queue_periph (
            .clk_i(clk_i),
            .rst_i(rst_i),
            .in   (segments[i]),
            .out  (segment_rsp[i])
        );
    end
    dport_rsp_queue i_dport_rsp_queue_periph (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .in   (dummy),
        .out  (segment_rsp[NS])
    );

    typedef struct packed {
        logic                      rready;
        logic                      rvalid;
        logic [cpu.DATA_WIDTH-1:0] rdata;
        logic                      err;
        logic [cpu.ID_WIDTH-1:0]   rid;
    } obi_rsp_t;

    obi_rsp_t rsp_data[NS+1];
    for (genvar i = 0; i < NS+1; i++) begin : g_rsp_data
        assign rsp_data[i].rvalid = segment_rsp[i].rvalid;
        assign rsp_data[i].rdata = segment_rsp[i].rdata;
        assign rsp_data[i].err = segment_rsp[i].err;
        assign rsp_data[i].rid = segment_rsp[i].rid;
        //assign segment_rsp[i].rready = rsp_data[i].rready;
    end

    always_comb begin
        cpu.rvalid = 0;
        cpu.rdata = 0;
        cpu.err = 0;
        cpu.rid = 0;
        for (int i = 0; i < NS + 1; i++) begin
            if (rsp_ack == 1 << i) begin
                cpu.rvalid = rsp_data[i].rvalid;
                cpu.rdata  = rsp_data[i].rdata;
                cpu.err    = rsp_data[i].err;
                cpu.rid    = rsp_data[i].rid;
            end
        end
    end

    /*
    always_comb begin : proc_ack
        case (rsp_ack)
            6'b000001: begin
                cpu.rvalid = segment_rsp[0].rvalid;
                cpu.rdata  = segment_rsp[0].rdata;
                cpu.err    = segment_rsp[0].err;
                cpu.rid    = segment_rsp[0].rid;
            end
            6'b000010: begin
                cpu.rvalid = segment_rsp[1].rvalid;
                cpu.rdata  = segment_rsp[1].rdata;
                cpu.err    = segment_rsp[1].err;
                cpu.rid    = segment_rsp[1].rid;
            end
            6'b000100: begin
                cpu.rvalid = segment_rsp[2].rvalid;
                cpu.rdata  = segment_rsp[2].rdata;
                cpu.err    = segment_rsp[2].err;
                cpu.rid    = segment_rsp[2].rid;
            end
            6'b001000: begin
                cpu.rvalid = segment_rsp[3].rvalid;
                cpu.rdata  = segment_rsp[3].rdata;
                cpu.err    = segment_rsp[3].err;
                cpu.rid    = segment_rsp[3].rid;
            end
            6'b010000: begin
                cpu.rvalid = segment_rsp[4].rvalid;
                cpu.rdata  = segment_rsp[4].rdata;
                cpu.err    = segment_rsp[4].err;
                cpu.rid    = segment_rsp[4].rid;
            end
            6'b100000: begin
                cpu.rvalid = segment_rsp[5].rvalid;
                cpu.rdata  = segment_rsp[5].rdata;
                cpu.err    = segment_rsp[5].err;
                cpu.rid    = segment_rsp[5].rid;
            end
            default: begin
                cpu.rvalid = 0;
                cpu.rdata  = 0;
                cpu.err    = 0;
                cpu.rid    = 0;
            end
        endcase
    end
    */

    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(rsp_push && rsp_full));
        assert (~(rsp_pop && rsp_empty));
        assert ((decode_valid && |req_grant) || ~decode_valid);
    end

endmodule : dport_mux2

