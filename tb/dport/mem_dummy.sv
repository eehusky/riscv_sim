module mem_dummy #(
    parameter int ADDR_WIDTH = 16
) (
    input logic clk_i,
    input logic rst_i,

    dport_if.slave dport
);
    localparam WORD_ADDR_WIDTH = ADDR_WIDTH - $clog2(4);

    logic   [WORD_ADDR_WIDTH-1:0] word_addr;
    logic   [               31:0] mem       [(2**WORD_ADDR_WIDTH)-1];
    integer                       i;

    assign word_addr = dport.addr[ADDR_WIDTH-1:ADDR_WIDTH-WORD_ADDR_WIDTH];

    always_ff @(posedge clk_i) begin : proc_
        if (rst_i) begin
            dport.accept  <= 0;
            dport.ack     <= 0;
            dport.data_rd <= 0;
        end else begin
            dport.accept <= 1;
            if (dport.rd) begin
                dport.ack     <= 1;
                dport.data_rd <= mem[word_addr];
            end else if (|dport.wr) begin
                dport.ack     <= 1;
                dport.data_rd <= 0;
                for (i = 0; i < 4; i = i + 1) begin
                    if (dport.wr[i]) begin
                        mem[word_addr][8*i+:8] <= dport.data_wr[8*i+:8];
                    end
                end
            end else begin
                dport.ack     <= 0;
                dport.data_rd <= 0;
            end
        end
    end
endmodule : mem_dummy
