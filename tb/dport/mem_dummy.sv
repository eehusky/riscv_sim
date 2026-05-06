module mem_dummy #(
    parameter int ADDR_WIDTH = 16
) (
    input  logic        clk_i,
    input  logic        rst_i,
    //
    output logic        mem_accept_o,
    output logic        mem_ack_o,
    input  logic [31:0] mem_addr_i,
    output logic [31:0] mem_data_rd_o,
    input  logic [31:0] mem_data_wr_i,
    output logic        mem_error_o,
    input  logic        mem_rd_i,
    input  logic [ 3:0] mem_wr_i
);
    localparam WORD_ADDR_WIDTH = ADDR_WIDTH - $clog2(4);

    logic   [WORD_ADDR_WIDTH-1:0] word_addr;
    logic   [               31:0] mem       [(2**WORD_ADDR_WIDTH)-1];
    integer                       i;

    assign word_addr = mem_addr_i[ADDR_WIDTH-1:ADDR_WIDTH-WORD_ADDR_WIDTH];

    always_ff @(posedge clk_i) begin : proc_
        if (rst_i) begin
            mem_accept_o  <= 0;
            mem_ack_o     <= 0;
            mem_data_rd_o <= 0;
        end else begin
            mem_accept_o  <= 1;
            if (mem_rd_i) begin
                mem_ack_o     <= 1;
                mem_data_rd_o <= mem[word_addr];
            end else if (|mem_wr_i) begin
                mem_ack_o <= 1;
                mem_data_rd_o <= 0;
                for (i = 0; i < 4; i = i + 1) begin
                    if (mem_wr_i[i]) begin
                        mem[word_addr][8*i+:8] <= mem_data_wr_i[8*i+:8];
                    end
                end
            end else begin
                mem_ack_o     <= 0;
                mem_data_rd_o <= 0;
            end
        end
    end
endmodule : mem_dummy
