
module mem2axi_glue #(
    parameter int AXI_ADDR_W,
    parameter int AXI_DATA_W,
    parameter int AXI_ID_W,
    parameter int AXI_LEN_W
) (
    input logic clk_i,
    input logic rst_i,

    mem_if.slave dport,

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
    output logic                    axi_rready_o,
    input  logic                    axi_rvalid_i,
    input  logic [  AXI_DATA_W-1:0] axi_rdata_i,
    input  logic [           2-1:0] axi_rresp_i,
    input  logic [    AXI_ID_W-1:0] axi_rid_i,
    input  logic                    axi_rlast_i,
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
    input  logic                    axi_wready_i,
    output logic [  AXI_DATA_W-1:0] axi_wdata_o,
    output logic [AXI_DATA_W/8-1:0] axi_wstrb_o,
    output logic                    axi_wvalid_o,
    output logic                    axi_wlast_o,
    output logic                    axi_bready_o,
    input  logic [           2-1:0] axi_bresp_i,
    input  logic                    axi_bvalid_i,
    input  logic [    AXI_ID_W-1:0] axi_bid_i
);
    localparam int LGREQ = 1;
    localparam int LGRSP = LGREQ + 1;

    // ------------------------------------------------------------------------

    logic ar_ack;
    logic aw_ack;
    logic r_ack;
    logic w_ack;
    logic b_ack;

    assign ar_ack = axi_arready_i && axi_arvalid_o;
    assign aw_ack = axi_awready_i && axi_awvalid_o;
    assign r_ack  = axi_rready_o && axi_rvalid_i;
    assign w_ack  = axi_wready_i && axi_wvalid_o;
    assign b_ack  = axi_bready_o && axi_bvalid_i;

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

    assign mem_req_push = (dport.rd || |dport.wr) && dport.accept;
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
        .i_data ({dport.addr, dport.rd, |dport.wr}),
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

    assign wdata_push = |dport.wr && dport.accept;
    assign wdata_pop  = w_ack;

    ringbuffer_sfifo #(
        .BW               ($size(wdata_t)),
        .LGFLEN           (LGREQ),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_wdata_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({dport.data_wr, dport.wr}),
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
    assign mem_rsp_pop  = r_ack || b_ack;

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

    assign axi_araddr_o  = axi_arvalid_o ? mem_req_data_out.addr : 0;
    assign axi_arvalid_o = ~mem_req_empty && mem_req_data_out.rd;
    assign axi_rready_o  = ~mem_rsp_empty && mem_rsp_data_out.rd;

    assign axi_awaddr_o  = axi_awvalid_o ? mem_req_data_out.addr : 0;
    assign axi_awvalid_o = ~mem_req_empty && mem_req_data_out.wr;

    assign axi_wvalid_o  = ~wdata_empty && |wdata_data_out.wr;
    assign axi_wlast_o   = axi_wvalid_o;
    assign axi_wdata_o   = axi_wvalid_o ? wdata_data_out.data_wr : 0;
    assign axi_wstrb_o   = axi_wvalid_o ? wdata_data_out.wr : 0;
    assign axi_bready_o  = ~mem_rsp_empty && mem_rsp_data_out.wr;

    assign dport.data_rd = (r_ack && mem_rsp_data_out.rd) ? axi_rdata_i : 0;
    assign dport.accept  = ~mem_req_full && ~wdata_full && ~mem_rsp_full;
    assign dport.ack     = mem_rsp_pop;
    assign dport.error   = mem_rsp_pop && (axi_rresp_i[1] || axi_bresp_i[1]);

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


    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(mem_req_push && mem_req_full));
        assert (~(mem_req_pop && mem_req_empty));
        assert (~(wdata_push && wdata_full));
        assert (~(wdata_pop && wdata_empty));
        assert (~(mem_rsp_push && mem_rsp_full));
        assert (~(mem_rsp_pop && mem_rsp_empty));
    end

endmodule : mem2axi_glue
