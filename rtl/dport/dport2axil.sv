module dport2axil #(
    parameter int ADDR_WIDTH = 32
) (
    input logic clk_i,
    input logic rst_i,

    dport_if.slave dport,
    axil_if.master m_axil

    //output logic [ADDR_WIDTH-1:0] araddr,
    //output logic [           2:0] arprot,
    //input  logic                  arready,
    //output logic                  arvalid,
    //output logic [ADDR_WIDTH-1:0] awaddr,
    //output logic [           2:0] awprot,
    //input  logic                  awready,
    //output logic                  awvalid,
    //output logic                  bready,
    //input  logic [           1:0] bresp,
    //input  logic                  bvalid,
    //input  logic [          31:0] rdata,
    //output logic                  rready,
    //input  logic [           1:0] rresp,
    //input  logic                  rvalid,
    //output logic [          31:0] wdata,
    //input  logic                  wready,
    //output logic [           3:0] wstrb,
    //output logic                  wvalid
);

    axi_if axi ();

    assign axi.arready    = m_axil.arready;
    assign m_axil.arvalid = axi.arvalid;
    assign m_axil.araddr  = axi.araddr;
    //assign axi.arid       = 0;
    //assign axi.arlen      = 0;
    //assign axi.arsize     = 0;
    //assign axi.arburst    = 0;
    //assign axi.arlock     = 0;
    //assign axi.arcache    = 0;
    //assign axi.arqos      = 0;

    assign m_axil.rready = axi.rready;
    assign axi.rvalid     = m_axil.rvalid;
    assign axi.rdata      = m_axil.rdata;
    assign axi.rresp      = m_axil.rresp;
    //assign axi.rid        = 0;
    //assign axi.rlast      = 0;

    assign axi.awready    = m_axil.awready;
    assign m_axil.awvalid = axi.awvalid;
    assign m_axil.awaddr  = axi.awaddr;
    //assign axi.awid       = 0;
    //assign axi.awlen      = 0;
    //assign axi.awsize     = 0;
    //assign axi.awburst    = 0;
    //assign axi.awlock     = 0;
    //assign axi.awcache    = 0;
    //assign axi.awqos      = 0;

    assign axi.wready     = m_axil.wready;
    assign m_axil.wdata   = axi.wdata;
    assign m_axil.wstrb   = axi.wstrb;
    assign m_axil.wvalid  = axi.wvalid;
    //assign axi.wlast      = 0;

    assign m_axil.bready = axi.bready;
    assign axi.bresp      = m_axil.bresp;
    assign axi.bvalid     = m_axil.bvalid;
    //assign axi.bid        = 0;

    dport2axi #(
    //.AXI_ADDR_W(ADDR_WIDTH),
    //.AXI_DATA_W(32),
    //.AXI_ID_W  (1),
    //.AXI_LEN_W (1)
    ) i_dport2axil (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(dport),
        .m_axi(axi)
        //
        //.axi_arready_i(arready),
        //.axi_arvalid_o(arvalid),
        //.axi_araddr_o (araddr),
        //.axi_arid_o   (),
        //.axi_arlen_o  (),
        //.axi_arsize_o (),
        //.axi_arburst_o(),
        //.axi_arlock_o (),
        //.axi_arcache_o(),
        //.axi_arqos_o  (),
        ////
        //.axi_rready_o (rready),
        //.axi_rvalid_i (rvalid),
        //.axi_rdata_i  (rdata),
        //.axi_rresp_i  (rresp),
        //.axi_rid_i    (0),
        //.axi_rlast_i  (0),
        ////
        //.axi_awready_i(awready),
        //.axi_awvalid_o(awvalid),
        //.axi_awaddr_o (awaddr),
        //.axi_awid_o   (),
        //.axi_awlen_o  (),
        //.axi_awsize_o (),
        //.axi_awburst_o(),
        //.axi_awlock_o (),
        //.axi_awcache_o(),
        //.axi_awqos_o  (),
        ////
        //.axi_wready_i (wready),
        //.axi_wdata_o  (wdata),
        //.axi_wstrb_o  (wstrb),
        //.axi_wvalid_o (wvalid),
        //.axi_wlast_o  (),
        ////
        //.axi_bready_o (bready),
        //.axi_bresp_i  (bresp),
        //.axi_bvalid_i (bvalid),
        //.axi_bid_i    (0)
    );

    assign m_axil.arprot = 0;
    assign m_axil.awprot = 0;

endmodule : dport2axil
