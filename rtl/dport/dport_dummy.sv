module dport_dummy (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave dport
);
    always_ff @(posedge clk_i) begin : proc_dummy
        dport.gnt   <= 1;
        dport.err   <= 1;
        dport.rdata <= 0;
        dport.rvalid <= dport.req;
        dport.rid <= dport.aid;
    end

endmodule : dport_dummy
