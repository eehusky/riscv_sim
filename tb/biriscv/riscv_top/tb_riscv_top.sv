module tb_riscv_top (
    input logic i_clk,
    input logic i_rst
);
    logic        i_intr;
    logic [31:0] i_reset_vector;
    logic [31:0] s_data_axi_araddr;
    logic [ 1:0] s_data_axi_arburst;
    logic [ 3:0] s_data_axi_arid;
    logic [ 7:0] s_data_axi_arlen;
    logic        s_data_axi_arready;
    logic        s_data_axi_arvalid;
    logic [31:0] s_data_axi_awaddr;
    logic [ 1:0] s_data_axi_awburst;
    logic [ 3:0] s_data_axi_awid;
    logic [ 7:0] s_data_axi_awlen;
    logic        s_data_axi_awready;
    logic        s_data_axi_awvalid;
    logic [ 3:0] s_data_axi_bid;
    logic        s_data_axi_bready;
    logic [ 1:0] s_data_axi_bresp;
    logic        s_data_axi_bvalid;
    logic [31:0] s_data_axi_rdata;
    logic [ 3:0] s_data_axi_rid;
    logic        s_data_axi_rlast;
    logic        s_data_axi_rready;
    logic [ 1:0] s_data_axi_rresp;
    logic        s_data_axi_rvalid;
    logic [31:0] s_data_axi_wdata;
    logic        s_data_axi_wlast;
    logic        s_data_axi_wready;
    logic [ 3:0] s_data_axi_wstrb;
    logic        s_data_axi_wvalid;
    logic [31:0] s_instr_axi_araddr;
    logic [ 1:0] s_instr_axi_arburst;
    logic [ 3:0] s_instr_axi_arid;
    logic [ 7:0] s_instr_axi_arlen;
    logic        s_instr_axi_arready;
    logic        s_instr_axi_arvalid;
    logic [31:0] s_instr_axi_awaddr;
    logic [ 1:0] s_instr_axi_awburst;
    logic [ 3:0] s_instr_axi_awid;
    logic [ 7:0] s_instr_axi_awlen;
    logic        s_instr_axi_awready;
    logic        s_instr_axi_awvalid;
    logic [ 3:0] s_instr_axi_bid;
    logic        s_instr_axi_bready;
    logic [ 1:0] s_instr_axi_bresp;
    logic        s_instr_axi_bvalid;
    logic [31:0] s_instr_axi_rdata;
    logic [ 3:0] s_instr_axi_rid;
    logic        s_instr_axi_rlast;
    logic        s_instr_axi_rready;
    logic [ 1:0] s_instr_axi_rresp;
    logic        s_instr_axi_rvalid;
    logic [31:0] s_instr_axi_wdata;
    logic        s_instr_axi_wlast;
    logic        s_instr_axi_wready;
    logic [ 3:0] s_instr_axi_wstrb;
    logic        s_instr_axi_wvalid;

    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end

    initial begin
        i_intr              = 0;
        i_reset_vector      = 0;
        s_data_axi_araddr   = 0;
        s_data_axi_arburst  = 0;
        s_data_axi_arid     = 0;
        s_data_axi_arlen    = 0;
        s_data_axi_arvalid  = 0;
        s_data_axi_awaddr   = 0;
        s_data_axi_awburst  = 0;
        s_data_axi_awid     = 0;
        s_data_axi_awlen    = 0;
        s_data_axi_awvalid  = 0;
        s_data_axi_bready   = 0;
        s_data_axi_rready   = 0;
        s_data_axi_wdata    = 0;
        s_data_axi_wlast    = 0;
        s_data_axi_wstrb    = 0;
        s_data_axi_wvalid   = 0;
        s_instr_axi_araddr  = 0;
        s_instr_axi_arburst = 0;
        s_instr_axi_arid    = 0;
        s_instr_axi_arlen   = 0;
        s_instr_axi_arvalid = 0;
        s_instr_axi_awaddr  = 0;
        s_instr_axi_awburst = 0;
        s_instr_axi_awid    = 0;
        s_instr_axi_awlen   = 0;
        s_instr_axi_awvalid = 0;
        s_instr_axi_bready  = 0;
        s_instr_axi_rready  = 0;
        s_instr_axi_wdata   = 0;
        s_instr_axi_wlast   = 0;
        s_instr_axi_wstrb   = 0;
        s_instr_axi_wvalid  = 0;
    end

    riscv_top_wrapper i_riscv_top_wrapper (
        .i_clk              (i_clk),
        .i_rst              (i_rst),
        .i_intr             (i_intr),
        .i_reset_vector     (i_reset_vector),
        .s_data_axi_araddr  (s_data_axi_araddr),
        .s_data_axi_arburst (s_data_axi_arburst),
        .s_data_axi_arid    (s_data_axi_arid),
        .s_data_axi_arlen   (s_data_axi_arlen),
        .s_data_axi_arready (s_data_axi_arready),
        .s_data_axi_arvalid (s_data_axi_arvalid),
        .s_data_axi_awaddr  (s_data_axi_awaddr),
        .s_data_axi_awburst (s_data_axi_awburst),
        .s_data_axi_awid    (s_data_axi_awid),
        .s_data_axi_awlen   (s_data_axi_awlen),
        .s_data_axi_awready (s_data_axi_awready),
        .s_data_axi_awvalid (s_data_axi_awvalid),
        .s_data_axi_bid     (s_data_axi_bid),
        .s_data_axi_bready  (s_data_axi_bready),
        .s_data_axi_bresp   (s_data_axi_bresp),
        .s_data_axi_bvalid  (s_data_axi_bvalid),
        .s_data_axi_rdata   (s_data_axi_rdata),
        .s_data_axi_rid     (s_data_axi_rid),
        .s_data_axi_rlast   (s_data_axi_rlast),
        .s_data_axi_rready  (s_data_axi_rready),
        .s_data_axi_rresp   (s_data_axi_rresp),
        .s_data_axi_rvalid  (s_data_axi_rvalid),
        .s_data_axi_wdata   (s_data_axi_wdata),
        .s_data_axi_wlast   (s_data_axi_wlast),
        .s_data_axi_wready  (s_data_axi_wready),
        .s_data_axi_wstrb   (s_data_axi_wstrb),
        .s_data_axi_wvalid  (s_data_axi_wvalid),
        .s_instr_axi_araddr (s_instr_axi_araddr),
        .s_instr_axi_arburst(s_instr_axi_arburst),
        .s_instr_axi_arid   (s_instr_axi_arid),
        .s_instr_axi_arlen  (s_instr_axi_arlen),
        .s_instr_axi_arready(s_instr_axi_arready),
        .s_instr_axi_arvalid(s_instr_axi_arvalid),
        .s_instr_axi_awaddr (s_instr_axi_awaddr),
        .s_instr_axi_awburst(s_instr_axi_awburst),
        .s_instr_axi_awid   (s_instr_axi_awid),
        .s_instr_axi_awlen  (s_instr_axi_awlen),
        .s_instr_axi_awready(s_instr_axi_awready),
        .s_instr_axi_awvalid(s_instr_axi_awvalid),
        .s_instr_axi_bid    (s_instr_axi_bid),
        .s_instr_axi_bready (s_instr_axi_bready),
        .s_instr_axi_bresp  (s_instr_axi_bresp),
        .s_instr_axi_bvalid (s_instr_axi_bvalid),
        .s_instr_axi_rdata  (s_instr_axi_rdata),
        .s_instr_axi_rid    (s_instr_axi_rid),
        .s_instr_axi_rlast  (s_instr_axi_rlast),
        .s_instr_axi_rready (s_instr_axi_rready),
        .s_instr_axi_rresp  (s_instr_axi_rresp),
        .s_instr_axi_rvalid (s_instr_axi_rvalid),
        .s_instr_axi_wdata  (s_instr_axi_wdata),
        .s_instr_axi_wlast  (s_instr_axi_wlast),
        .s_instr_axi_wready (s_instr_axi_wready),
        .s_instr_axi_wstrb  (s_instr_axi_wstrb),
        .s_instr_axi_wvalid (s_instr_axi_wvalid)
    );

endmodule : tb_riscv_top
