module obi2axil (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave dport,
    axil_if.master m_axil
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

    obi2axi i_dport2axil (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(dport),
        .m_axi(axi)
    );

    assign m_axil.arprot = 0;
    assign m_axil.awprot = 0;

endmodule : obi2axil
