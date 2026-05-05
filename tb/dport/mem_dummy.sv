
module mem_dummy #(
    parameter int ADDR_WIDTH      = 32,
    parameter int AXIL_DATA_WIDTH = 32,
    parameter int AXIL_STRB_WIDTH = 8
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

    logic [31:0] mem['hFFFF];


    always_ff @(posedge clk_i) begin : proc_
        if (rst_i) begin
            mem_data_rd_o <= 0;
            mem_accept_o  <= 0;
            mem_ack_o     <= 0;
        end else begin
            if (mem_rd_i) begin
                mem_data_rd_o <= mem[mem_addr_i[15:0]];
                mem_ack_o     <= 1;
            end else if (|mem_wr_i) begin
                mem[mem_addr_i[15:0]] <= mem_data_wr_i;
                mem_ack_o             <= 1;
            end else begin
                mem_ack_o     <= 0;
                mem_accept_o  <= 1;
                mem_data_rd_o <= 0;
            end
        end
    end





endmodule : mem_dummy
