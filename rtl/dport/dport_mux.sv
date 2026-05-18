module dport_mux #(
    parameter N_SEGMENTS = dport_pkg::N_SEGMENTS
) (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave  initiators[N_SEGMENTS],
    obi_if.master target
);
    localparam int NS = N_SEGMENTS;
    localparam int LGNS = $clog2(N_SEGMENTS);

    generate
        if (target.ID_WIDTH != (initiators.ID_WIDTH + LGNS))begin: g_id_check
            $error("Mismatched ID Width %d %d", target.ID_WIDTH, initiators.ID_WIDTH + LGNS);
        end
    endgenerate

    typedef struct packed {
        logic [initiators.ADDR_WIDTH-1:0] addr;
        logic                             we;
        logic [initiators.STRB_WIDTH-1:0] be;
        logic [initiators.DATA_WIDTH-1:0] wdata;
        logic [initiators.ID_WIDTH-1:0]   aid;
    } obi_addr_t;

    obi_addr_t          addr_data     [NS];
    logic      [NS-1:0] addr_requests;
    logic      [NS-1:0] addr_acks;
    for (genvar i = 0; i < NS; i++) begin : g_addr
        assign addr_data[i].addr  = initiators[i].addr;
        assign addr_data[i].we    = initiators[i].we;
        assign addr_data[i].be    = initiators[i].be;
        assign addr_data[i].wdata = initiators[i].wdata;
        assign addr_data[i].aid   = initiators[i].aid;
        assign addr_requests[i]   = initiators[i].req;
        assign addr_acks[i]       = addr_requests[i] && addr_grant[i] && addr_grant_valid && target.gnt;
        assign initiators[i].gnt  = addr_acks[i];
    end

    logic            addr_grant_valid;
    logic [  NS-1:0] addr_grant;
    logic [LGNS-1:0] addr_grant_encoded;
    priority_encoder #(NS) i_priority_encoder (
        .req          (addr_requests),
        .grant        (addr_grant),
        .grant_encoded(addr_grant_encoded),
        .valid        (addr_grant_valid)
    );


    always_comb begin
        target.addr  = 0;
        target.we    = 0;
        target.be    = 0;
        target.wdata = 0;
        target.aid   = 0;
        target.req   = 0;
        for (int i = 0; i < NS; i++) begin
            if (addr_acks[i]) begin
                target.req   = 1;
                target.addr  = addr_data[i].addr;
                target.we    = addr_data[i].we;
                target.be    = addr_data[i].be;
                target.wdata = addr_data[i].wdata;
                target.aid   = {addr_grant_encoded, addr_data[i].aid};
            end
        end
    end

    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    assign target.rready = 1;

    //typedef struct packed {
    //logic [initiators.DATA_WIDTH-1:0] rdata;
    //logic                  err;
    //logic [  initiators.ID_WIDTH-1:0] rid;
    //} obi_rsp_t;
    //for (genvar i = 0; i < NS; i++) begin : g_rsp
    //    assign rsp_data[i].rdata= initiators[i].rdata;
    //    assign rsp_data[i].err= initiators[i].err;
    //    assign rsp_data[i].rid= initiators[i].rid;
    //end
    //obi_rsp_t          rsp_data[NS];
    //obi_rsp_t          rsp_buf[NS];

    //skidbuffer #(
    //) i_skidbuffer(
    //    .i_clk(clk_i),
    //    .i_reset(rst_i),
    //    .i_valid(target.rvalid),
    //    .o_ready(),
    //    .i_data(rsp_data),
    //    .o_valid(),
    //    .i_ready(),
    //    .o_data(rsp_buf)
    //);

    logic [LGNS-1:0] rid;
    logic [initiators.ID_WIDTH-1:0] target_rid;
    assign rid = target.rid[target.ID_WIDTH-1-:LGNS];
    assign target_rid = target.rid[initiators.ID_WIDTH-1:0];
    generate
        for (genvar i = 0; i < NS; i++) begin : g_resp
            assign initiators[i].rvalid = target.rvalid && rid == LGNS'(i);
            assign initiators[i].rdata  = initiators[i].rvalid ? target.rdata : 0;
            assign initiators[i].err    = initiators[i].rvalid ? target.err : 0;
            assign initiators[i].rid    = initiators[i].rvalid ? target_rid : 0;
        end
    endgenerate
endmodule : dport_mux


module priority_encoder #(
    parameter int WIDTH = 8  // Number of input bits
) (
    input  wire [        WIDTH-1:0] req,            // Input requests
    output reg  [        WIDTH-1:0] grant,          // Encoded output index
    output reg  [$clog2(WIDTH)-1:0] grant_encoded,  // Encoded output index
    output reg                      valid           // High if any req is active
);

    integer i;

    always_comb begin
        grant         = 0;  // Default value
        valid         = 1'b0;  // Default: no request active
        grant_encoded = 'b0;  // Default: no request active

        // Loop from LSB to MSB. Higher indices overwrite lower ones (MSB Priority).
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (req[i]) begin
                grant         = 1 << i;
                grant_encoded = ($clog2(WIDTH))'(i);
                valid         = 1'b1;
            end
        end
    end

endmodule


