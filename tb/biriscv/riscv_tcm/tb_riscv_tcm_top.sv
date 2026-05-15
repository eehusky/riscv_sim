module tb_riscv_tcm_top #(
    parameter BOOT_VECTOR               = 32'h80000000,
    parameter CORE_ID                   = 0,
    parameter TCM_MEM_BASE              = 32'h80000000,
    parameter SUPPORT_BRANCH_PREDICTION = 1,
    parameter SUPPORT_MULDIV            = 1,
    parameter SUPPORT_SUPER             = 0,
    parameter SUPPORT_MMU               = 0,
    parameter SUPPORT_DUAL_ISSUE        = 1,
    parameter SUPPORT_LOAD_BYPASS       = 1,
    parameter SUPPORT_MUL_BYPASS        = 1,
    parameter SUPPORT_REGFILE_XILINX    = 0,
    parameter EXTRA_DECODE_STAGE        = 0,
    parameter MEM_CACHE_ADDR_MIN        = 32'h80000000,
    parameter MEM_CACHE_ADDR_MAX        = 32'h8fffffff,
    parameter NUM_BTB_ENTRIES           = 32,
    parameter NUM_BTB_ENTRIES_W         = 5,
    parameter NUM_BHT_ENTRIES           = 512,
    parameter NUM_BHT_ENTRIES_W         = 9,
    parameter RAS_ENABLE                = 1,
    parameter GSHARE_ENABLE             = 0,
    parameter BHT_ENABLE                = 1,
    parameter NUM_RAS_ENTRIES           = 8,
    parameter NUM_RAS_ENTRIES_W         = 3
) (
    input logic i_clk,
    input logic i_rst,
    input logic i_rst_cpu
);

    logic [31:0] i_intr;
    logic        s_axi_awvalid;
    logic [31:0] s_axi_awaddr;
    logic [ 3:0] s_axi_awid;
    logic [ 7:0] s_axi_awlen;
    logic [ 1:0] s_axi_awburst;
    logic        s_axi_wvalid;
    logic [31:0] s_axi_wdata;
    logic [ 3:0] s_axi_wstrb;
    logic        s_axi_wlast;
    logic        s_axi_bready;
    logic        s_axi_arvalid;
    logic [31:0] s_axi_araddr;
    logic [ 3:0] s_axi_arid;
    logic [ 7:0] s_axi_arlen;
    logic [ 1:0] s_axi_arburst;
    logic        s_axi_rready;
    logic        s_axi_awready;
    logic        s_axi_wready;
    logic        s_axi_bvalid;
    logic [ 1:0] s_axi_bresp;
    logic [ 3:0] s_axi_bid;
    logic        s_axi_arready;
    logic        s_axi_rvalid;
    logic [31:0] s_axi_rdata;
    logic [ 1:0] s_axi_rresp;
    logic [ 3:0] s_axi_rid;
    logic        s_axi_rlast;
    logic        m_axil_awready;
    logic        m_axil_awvalid;
    logic [31:0] m_axil_awaddr;
    logic        m_axil_wready;
    logic        m_axil_wvalid;
    logic [31:0] m_axil_wdata;
    logic [ 3:0] m_axil_wstrb;
    logic        m_axil_bready;
    logic        m_axil_bvalid;
    logic [ 1:0] m_axil_bresp;
    logic        m_axil_arvalid;
    logic        m_axil_arready;
    logic [31:0] m_axil_araddr;
    logic        m_axil_rvalid;
    logic [31:0] m_axil_rdata;
    logic [ 1:0] m_axil_rresp;
    logic        m_axil_rready;

`ifdef VM_TRACE
    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end
`endif

    initial begin
        i_intr         = 0;

        s_axi_awvalid  = 0;
        s_axi_awaddr   = 0;
        s_axi_awid     = 0;
        s_axi_awlen    = 0;
        s_axi_awburst  = 0;
        s_axi_wvalid   = 0;
        s_axi_wdata    = 0;
        s_axi_wstrb    = 0;
        s_axi_wlast    = 0;
        s_axi_bready   = 0;
        s_axi_arvalid  = 0;
        s_axi_araddr   = 0;
        s_axi_arid     = 0;
        s_axi_arlen    = 0;
        s_axi_arburst  = 0;
        s_axi_rready   = 0;

        m_axil_awready = 0;
        m_axil_awvalid = 0;
        m_axil_awaddr  = 0;
        m_axil_wready  = 0;
        m_axil_wvalid  = 0;
        m_axil_wdata   = 0;
        m_axil_wstrb   = 0;
        m_axil_bready  = 0;
        m_axil_bvalid  = 0;
        m_axil_bresp   = 0;
        m_axil_arvalid = 0;
        m_axil_arready = 0;
        m_axil_araddr  = 0;
        m_axil_rvalid  = 0;
        m_axil_rdata   = 0;
        m_axil_rresp   = 0;
        m_axil_rready  = 0;
    end

    riscv_tcm_top_wrapper #(
        .BOOT_VECTOR              (BOOT_VECTOR),
        .CORE_ID                  (CORE_ID),
        .TCM_MEM_BASE             (TCM_MEM_BASE),
        .SUPPORT_BRANCH_PREDICTION(SUPPORT_BRANCH_PREDICTION),
        .SUPPORT_MULDIV           (SUPPORT_MULDIV),
        .SUPPORT_SUPER            (SUPPORT_SUPER),
        .SUPPORT_MMU              (SUPPORT_MMU),
        .SUPPORT_DUAL_ISSUE       (SUPPORT_DUAL_ISSUE),
        .SUPPORT_LOAD_BYPASS      (SUPPORT_LOAD_BYPASS),
        .SUPPORT_MUL_BYPASS       (SUPPORT_MUL_BYPASS),
        .SUPPORT_REGFILE_XILINX   (SUPPORT_REGFILE_XILINX),
        .EXTRA_DECODE_STAGE       (EXTRA_DECODE_STAGE),
        .MEM_CACHE_ADDR_MIN       (MEM_CACHE_ADDR_MIN),
        .MEM_CACHE_ADDR_MAX       (MEM_CACHE_ADDR_MAX),
        .NUM_BTB_ENTRIES          (NUM_BTB_ENTRIES),
        .NUM_BTB_ENTRIES_W        (NUM_BTB_ENTRIES_W),
        .NUM_BHT_ENTRIES          (NUM_BHT_ENTRIES),
        .NUM_BHT_ENTRIES_W        (NUM_BHT_ENTRIES_W),
        .RAS_ENABLE               (RAS_ENABLE),
        .GSHARE_ENABLE            (GSHARE_ENABLE),
        .BHT_ENABLE               (BHT_ENABLE),
        .NUM_RAS_ENTRIES          (NUM_RAS_ENTRIES),
        .NUM_RAS_ENTRIES_W        (NUM_RAS_ENTRIES_W)
    ) i_riscv_tcm_top (
        .i_clk         (i_clk),
        .i_rst         (i_rst),
        .i_rst_cpu     (i_rst_cpu),
        .i_intr        (i_intr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awid    (s_axi_awid),
        .s_axi_awlen   (s_axi_awlen),
        .s_axi_awburst (s_axi_awburst),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wlast   (s_axi_wlast),
        .s_axi_bready  (s_axi_bready),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arid    (s_axi_arid),
        .s_axi_arlen   (s_axi_arlen),
        .s_axi_arburst (s_axi_arburst),
        .s_axi_rready  (s_axi_rready),
        .s_axi_awready (s_axi_awready),
        .s_axi_wready  (s_axi_wready),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bid     (s_axi_bid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rid     (s_axi_rid),
        .s_axi_rlast   (s_axi_rlast),
        .m_axil_awready(m_axil_awready),
        .m_axil_awvalid(m_axil_awvalid),
        .m_axil_awaddr (m_axil_awaddr),
        .m_axil_wready (m_axil_wready),
        .m_axil_wvalid (m_axil_wvalid),
        .m_axil_wdata  (m_axil_wdata),
        .m_axil_wstrb  (m_axil_wstrb),
        .m_axil_bready (m_axil_bready),
        .m_axil_bvalid (m_axil_bvalid),
        .m_axil_bresp  (m_axil_bresp),
        .m_axil_arvalid(m_axil_arvalid),
        .m_axil_arready(m_axil_arready),
        .m_axil_araddr (m_axil_araddr),
        .m_axil_rvalid (m_axil_rvalid),
        .m_axil_rdata  (m_axil_rdata),
        .m_axil_rresp  (m_axil_rresp),
        .m_axil_rready (m_axil_rready)
    );

endmodule : tb_riscv_tcm_top
