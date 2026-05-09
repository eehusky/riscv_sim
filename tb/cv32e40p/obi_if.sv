interface obi_if();
    logic        gnt;
    logic        req;
    logic        we;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [ 3:0] be;
    //
    logic        rvalid;
    logic [31:0] rdata;
    logic        error;

    modport slave(
        output gnt,
        input  req,
        input  we,
        input  addr,
        input  wdata,
        input  be,

        output rvalid,
        output rdata,
        output error
    );

    modport master(
        input  gnt,
        output req,
        output we,
        output addr,
        output wdata,
        output be,

        input  rvalid,
        input  rdata,
        input  error
    );
endinterface
