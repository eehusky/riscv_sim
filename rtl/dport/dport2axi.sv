module dport2axi #(
) (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave  dport,
    axi_if.master m_axi
);
    localparam int LGREQ = 1;
    localparam int LGRSP = LGREQ + 1;

    // ------------------------------------------------------------------------

    logic ar_ack;
    logic aw_ack;
    logic r_ack;
    logic w_ack;
    logic b_ack;

    assign ar_ack = m_axi.arready && m_axi.arvalid;
    assign aw_ack = m_axi.awready && m_axi.awvalid;
    assign r_ack  = m_axi.rready && m_axi.rvalid;
    assign w_ack  = m_axi.wready && m_axi.wvalid;
    assign b_ack  = m_axi.bready && m_axi.bvalid;

    // ------------------------------------------------------------------------

    typedef struct packed {
        logic [dport.ADDR_WIDTH-1:0] addr;
        logic                        we;
        logic [dport.STRB_WIDTH-1:0] be;
        logic [dport.DATA_WIDTH-1:0] wdata;
        logic [dport.ID_WIDTH-1:0]   aid;
    } mem_req_t;

    mem_req_t           mem_req_data_out;
    logic     [LGREQ:0] mem_req_fill;
    logic               mem_req_empty;
    logic               mem_req_full;
    logic               mem_req_push;
    logic               mem_req_pop;

    assign mem_req_push = dport.req && dport.gnt;
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
        .i_data ({dport.addr, dport.we, dport.be, dport.wdata, dport.aid}),
        .i_wr   (mem_req_push),
        .o_full (mem_req_full),
        .o_fill (mem_req_fill),
        .i_rd   (mem_req_pop),
        .o_data (mem_req_data_out),
        .o_empty(mem_req_empty)
    );

    // ------------------------------------------------------------------------

    typedef struct packed {
        logic [dport.STRB_WIDTH-1:0] be;
        logic [dport.DATA_WIDTH-1:0] wdata;
    } wdata_t;

    wdata_t           wdata_data_out;
    logic   [LGREQ:0] wdata_fill;
    logic             wdata_empty;
    logic             wdata_full;
    logic             wdata_push;
    logic             wdata_pop;

    assign wdata_push = dport.we && dport.req && dport.gnt;
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
        .i_data ({dport.be, dport.wdata}),
        .i_wr   (wdata_push),
        .o_full (wdata_full),
        .o_fill (wdata_fill),
        .i_rd   (wdata_pop),
        .o_data (wdata_data_out),
        .o_empty(wdata_empty)
    );

    // ------------------------------------------------------------------------

    typedef struct packed {logic we;} mem_rsp_t;

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
        .i_data ({mem_req_data_out.we}),
        .i_wr   (mem_rsp_push),
        .o_full (mem_rsp_full),
        .o_fill (mem_rsp_fill),
        .i_rd   (mem_rsp_pop),
        .o_data (mem_rsp_data_out),
        .o_empty(mem_rsp_empty)
    );

    // ------------------------------------------------------------------------

    assign m_axi.araddr  = m_axi.arvalid ? mem_req_data_out.addr : 0;
    assign m_axi.arvalid = ~mem_req_empty && ~mem_req_data_out.we;
    assign m_axi.rready  = ~mem_rsp_empty && ~mem_rsp_data_out.we;

    assign m_axi.awaddr  = m_axi.awvalid ? mem_req_data_out.addr : 0;
    assign m_axi.awvalid = ~mem_req_empty && mem_req_data_out.we;

    assign m_axi.wvalid  = ~wdata_empty;
    assign m_axi.wlast   = m_axi.wvalid;
    assign m_axi.wdata   = m_axi.wvalid ? wdata_data_out.wdata : 0;
    assign m_axi.wstrb   = m_axi.wvalid ? wdata_data_out.be : 0;
    assign m_axi.bready  = ~mem_rsp_empty && mem_rsp_data_out.we;

    assign dport.rdata   = (r_ack && ~mem_rsp_data_out.we) ? m_axi.rdata : 0;
    assign dport.gnt     = ~mem_req_full && ~wdata_full && ~mem_rsp_full;
    assign dport.rvalid  = mem_rsp_pop;
    assign dport.err     = mem_rsp_pop && (m_axi.rresp[1] || m_axi.bresp[1]);

    // constants
    assign m_axi.arid    = 0;
    assign m_axi.arlen   = 0;
    assign m_axi.arsize  = 2;
    assign m_axi.arburst = 0;
    assign m_axi.arlock  = 0;
    assign m_axi.arcache = 0;
    assign m_axi.arqos   = 0;
    assign m_axi.awid    = 0;
    assign m_axi.awlen   = 0;
    assign m_axi.awsize  = 2;
    assign m_axi.awburst = 0;
    assign m_axi.awlock  = 0;
    assign m_axi.awcache = 0;
    assign m_axi.awqos   = 0;


    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(mem_req_push && mem_req_full));
        assert (~(mem_req_pop && mem_req_empty));
        assert (~(wdata_push && wdata_full));
        assert (~(wdata_pop && wdata_empty));
        assert (~(mem_rsp_push && mem_rsp_full));
        assert (~(mem_rsp_pop && mem_rsp_empty));
    end

endmodule : dport2axi
