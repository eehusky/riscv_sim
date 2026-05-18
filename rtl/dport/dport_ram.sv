module dport_ram #(
    parameter int ADDR_WIDTH = 16
) (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave dport
);
    localparam STRB_WIDTH = dport.STRB_WIDTH;
    localparam WORD_ADDR_WIDTH = ADDR_WIDTH - $clog2(dport.STRB_WIDTH);

    logic   [WORD_ADDR_WIDTH-1:0] word_addr;
    logic   [ dport.DATA_WIDTH-1:0] mem       [(2**WORD_ADDR_WIDTH)-1];
    integer                       i;

    assign word_addr = dport.addr[ADDR_WIDTH-1:ADDR_WIDTH-WORD_ADDR_WIDTH];

    always_ff @(posedge clk_i) begin : proc_
        if (rst_i) begin
            dport.gnt    <= 0;
            dport.rvalid <= 0;
            dport.rdata  <= 0;
            dport.rid    <= 0;
            dport.err    <= 0;
        end else begin
            dport.gnt <= dport.rready;
            dport.err <= 0;
            if (dport.req && ~dport.we) begin
                dport.rvalid <= 1;
                dport.rid    <= dport.aid;
                dport.rdata  <= mem[word_addr];
            end else if (dport.req && dport.we) begin
                dport.rvalid <= 1;
                dport.rdata  <= 0;
                dport.rid    <= dport.aid;
                for (i = 0; i < dport.STRB_WIDTH; i = i + 1) begin
                    if (dport.be[i]) begin
                        mem[word_addr][8*i+:8] <= dport.wdata[8*i+:8];
                    end
                end
            end else begin
                dport.rvalid <= 0;
                dport.rdata  <= 0;
                dport.rid    <= 0;
            end
        end
    end

    localparam LGSTRB_WIDTH = $clog2(dport.STRB_WIDTH);

    function static void write;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            for (int i = 0; i < STRB_WIDTH; i++) begin
                if (addr[LGSTRB_WIDTH-1:0] == LGSTRB_WIDTH'(i)) begin
                    mem[addr/STRB_WIDTH][(i*8)+:8] = data;
                end
            end
        end
    endfunction
    function static bit [7:0] read;  /*verilator public*/
        input [31:0] addr;
        begin
            for (int i = 0; i < STRB_WIDTH; i++) begin
                if (addr[LGSTRB_WIDTH-1:0] == LGSTRB_WIDTH'(i)) begin
                    read = mem[addr/STRB_WIDTH][(i*8)+:8];
                end
            end
        end
    endfunction

endmodule : dport_ram
