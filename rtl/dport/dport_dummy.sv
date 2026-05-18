module dport_dummy (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave dport
);
    always_ff @(posedge clk_i) begin : proc_dummy
        dport.gnt   <= 1;
        dport.err   <= 1;
        dport.rdata <= 0;
        dport.rid <= 0;
        if (dport.req) begin
            dport.rvalid <= 1;
            dport.rid <= dport.aid;
        end else begin
            dport.rvalid <= 0;
            dport.rid <= 0;
        end
    end

endmodule : dport_dummy
