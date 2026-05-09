interface axi_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH / 8),
    parameter ID_WIDTH   = 8
) ();
    logic [  ID_WIDTH-1:0] awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [           7:0] awlen;
    logic [           2:0] awsize;
    logic [           1:0] awburst;
    logic                  awlock;
    logic [           3:0] awcache;
    logic [           2:0] awprot;
    logic [           3:0] awqos;
    logic [           3:0] awregion;
    logic                  awvalid;
    logic                  awready;
    logic [DATA_WIDTH-1:0] wdata;
    logic [STRB_WIDTH-1:0] wstrb;
    logic                  wlast;
    logic                  wvalid;
    logic                  wready;
    logic [  ID_WIDTH-1:0] bid;
    logic [           1:0] bresp;
    logic                  bvalid;
    logic                  bready;
    logic [  ID_WIDTH-1:0] arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [           7:0] arlen;
    logic [           2:0] arsize;
    logic [           1:0] arburst;
    logic                  arlock;
    logic [           3:0] arcache;
    logic [           2:0] arprot;
    logic [           3:0] arqos;
    logic [           3:0] arregion;
    logic                  arvalid;
    logic                  arready;
    logic [  ID_WIDTH-1:0] rid;
    logic [DATA_WIDTH-1:0] rdata;
    logic [           1:0] rresp;
    logic                  rlast;
    logic                  rvalid;
    logic                  rready;

    modport master(
    output awid,
    output awaddr,
    output awlen,
    output awsize,
    output awburst,
    output awlock,
    output awcache,
    output awprot,
    output awqos,
    output awregion,
    output awvalid,
    input awready,
    output wdata,
    output wstrb,
    output wlast,
    output wvalid,
    input wready,
    input bid,
    input bresp,
    input bvalid,
    output bready,
    output arid,
    output araddr,
    output arlen,
    output arsize,
    output arburst,
    output arlock,
    output arcache,
    output arprot,
    output arqos,
    output arregion,
    output arvalid,
    input arready,
    input rid,
    input rdata,
    input rresp,
    input rlast,
    input rvalid,
    output rready
    );

    modport slave(
    input awid,
    input awaddr,
    input awlen,
    input awsize,
    input awburst,
    input awlock,
    input awcache,
    input awprot,
    input awqos,
    input awregion,
    input awvalid,
    output awready,
    input wdata,
    input wstrb,
    input wlast,
    input wvalid,
    output wready,
    output bid,
    output bresp,
    output bvalid,
    input bready,
    input arid,
    input araddr,
    input arlen,
    input arsize,
    input arburst,
    input arlock,
    input arcache,
    input arprot,
    input arqos,
    input arregion,
    input arvalid,
    output arready,
    output rid,
    output rdata,
    output rresp,
    output rlast,
    output rvalid,
    input rready
    );

endinterface
