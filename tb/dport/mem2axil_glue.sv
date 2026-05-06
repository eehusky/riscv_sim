
module mem2axil_glue #(
    parameter int ADDR_WIDTH = 32
) (
    input logic clk_i,
    input logic rst_i,

    mem_if.slave dport,

    output logic [ADDR_WIDTH-1:0] araddr,
    output logic [           2:0] arprot,
    input  logic                  arready,
    output logic                  arvalid,
    output logic [ADDR_WIDTH-1:0] awaddr,
    output logic [           2:0] awprot,
    input  logic                  awready,
    output logic                  awvalid,
    output logic                  bready,
    input  logic [           1:0] bresp,
    input  logic                  bvalid,
    input  logic [          31:0] rdata,
    output logic                  rready,
    input  logic [           1:0] rresp,
    input  logic                  rvalid,
    output logic [          31:0] wdata,
    input  logic                  wready,
    output logic [           3:0] wstrb,
    output logic                  wvalid
);

    mem2axi_glue #(
        .AXI_ADDR_W(ADDR_WIDTH),
        .AXI_DATA_W(32),
        .AXI_ID_W  (1),
        .AXI_LEN_W (1)
    ) i_mem2axil_convert (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .dport        (dport),
        //
        .axi_arready_i(arready),
        .axi_arvalid_o(arvalid),
        .axi_araddr_o (araddr),
        .axi_arid_o   (),
        .axi_arlen_o  (),
        .axi_arsize_o (),
        .axi_arburst_o(),
        .axi_arlock_o (),
        .axi_arcache_o(),
        .axi_arqos_o  (),
        //
        .axi_rready_o (rready),
        .axi_rvalid_i (rvalid),
        .axi_rdata_i  (rdata),
        .axi_rresp_i  (rresp),
        .axi_rid_i    (0),
        .axi_rlast_i  (0),
        //
        .axi_awready_i(awready),
        .axi_awvalid_o(awvalid),
        .axi_awaddr_o (awaddr),
        .axi_awid_o   (),
        .axi_awlen_o  (),
        .axi_awsize_o (),
        .axi_awburst_o(),
        .axi_awlock_o (),
        .axi_awcache_o(),
        .axi_awqos_o  (),
        //
        .axi_wready_i (wready),
        .axi_wdata_o  (wdata),
        .axi_wstrb_o  (wstrb),
        .axi_wvalid_o (wvalid),
        .axi_wlast_o  (),
        //
        .axi_bready_o (bready),
        .axi_bresp_i  (bresp),
        .axi_bvalid_i (bvalid),
        .axi_bid_i    (0)
    );

    assign arprot = 0;
    assign awprot = 0;

endmodule : mem2axil_glue
