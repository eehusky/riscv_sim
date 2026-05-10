interface obi_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = (DATA_WIDTH / 8),
    parameter ID_WIDTH   = 1
);
    logic                  req;
    logic                  gnt;
    logic [ADDR_WIDTH-1:0] addr;
    logic                  we;
    logic [STRB_WIDTH-1:0] be;
    logic [DATA_WIDTH-1:0] wdata;
    logic [  ID_WIDTH-1:0] aid;

    logic                  rready;
    logic                  rvalid;
    logic [DATA_WIDTH-1:0] rdata;
    logic                  err;
    logic [  ID_WIDTH-1:0] rid;

    modport master(
    input gnt,
    output req,
    output addr,
    output we,
    output be,
    output wdata,
    output aid,

    output rready,
    input rvalid,
    input rdata,
    input err,
    input rid
    );

    modport slave(
    output gnt,
    input req,
    input addr,
    input we,
    input be,
    input wdata,
    input aid,

    input rready,
    output rvalid,
    output rdata,
    output err,
    output rid
    );

endinterface
