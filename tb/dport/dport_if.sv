interface dport_if();
    logic        accept;
    logic        rd;
    logic [ 3:0] wr;
    logic [31:0] addr;
    logic [31:0] data_wr;
    //
    logic        ack;
    logic [31:0] data_rd;
    logic        error;

    modport slave(
        output accept,
        input  rd,
        input  wr,
        input  addr,
        input  data_wr,

        output ack,
        output data_rd,
        output error
    );

    modport master(
        input  accept,
        output rd,
        output wr,
        output addr,
        output data_wr,

        input  ack,
        input  data_rd,
        input  error
    );
endinterface
