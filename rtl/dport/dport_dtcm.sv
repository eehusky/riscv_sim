/**
 * Original File: https://github.com/alexforencich/verilog-axi/blob/master/rtl/axi_dp_ram.v
 * Modified For: Instead of a dual port AXI ram...this is a dualport direct memory/AXI ram
 *               for low latency DTCM usage while still allowing external DMA engines to reach it.
 * */

/*

Copyright (c) 2019 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

module dport_dtcm #(
    // Width of data bus in bits
    parameter DATA_WIDTH        = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH        = 16,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH        = (DATA_WIDTH / 8),
    // Width of ID signal
    parameter ID_WIDTH          = 8,
    // Extra pipeline register on output port B
    parameter B_PIPELINE_OUTPUT = 0,
    // Interleave read and write burst cycles on port B
    parameter B_INTERLEAVE      = 0
) (
    input wire a_clk,
    input wire a_rst,

    obi_if.slave dport,
    axi_if.slave s_axi
);

    parameter VALID_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH);
    parameter WORD_WIDTH = STRB_WIDTH;
    parameter WORD_SIZE = DATA_WIDTH / WORD_WIDTH;

    // bus width assertions
    initial begin
        if (WORD_SIZE * STRB_WIDTH != DATA_WIDTH) begin
            $error("Error: AXI data width not evenly divisble (instance %m)");
            $finish;
        end

        if (2 ** $clog2(WORD_WIDTH) != WORD_WIDTH) begin
            $error("Error: AXI word width must be even power of two (instance %m)");
            $finish;
        end
    end


    wire [  ID_WIDTH-1:0] ram_b_cmd_id;
    wire [ADDR_WIDTH-1:0] ram_b_cmd_addr;
    wire [DATA_WIDTH-1:0] ram_b_cmd_wr_data;
    wire [STRB_WIDTH-1:0] ram_b_cmd_wr_strb;
    wire                  ram_b_cmd_wr_en;
    wire                  ram_b_cmd_rd_en;
    wire                  ram_b_cmd_last;
    wire                  ram_b_cmd_ready;
    reg  [  ID_WIDTH-1:0] ram_b_rd_resp_id_reg;
    reg  [DATA_WIDTH-1:0] ram_b_rd_resp_data_reg;
    reg                   ram_b_rd_resp_last_reg;
    reg                   ram_b_rd_resp_valid_reg;
    wire                  ram_b_rd_resp_ready;

    initial begin
        ram_b_rd_resp_id_reg    = {ID_WIDTH{1'b0}};
        ram_b_rd_resp_data_reg  = {DATA_WIDTH{1'b0}};
        ram_b_rd_resp_last_reg  = 1'b0;
        ram_b_rd_resp_valid_reg = 1'b0;
    end


    axi_ram_wr_rd_if #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .STRB_WIDTH     (STRB_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .AWUSER_ENABLE  (0),
        .WUSER_ENABLE   (0),
        .BUSER_ENABLE   (0),
        .ARUSER_ENABLE  (0),
        .RUSER_ENABLE   (0),
        .PIPELINE_OUTPUT(B_PIPELINE_OUTPUT),
        .INTERLEAVE     (B_INTERLEAVE)
    ) b_if (
        .clk(a_clk),
        .rst(a_rst),

        /*
     * AXI slave interface
     */
        .s_axi_awid    (s_axi.awid),
        .s_axi_awaddr  (s_axi.awaddr[ADDR_WIDTH-1:0]),
        .s_axi_awlen   (s_axi.awlen),
        .s_axi_awsize  (s_axi.awsize),
        .s_axi_awburst (s_axi.awburst),
        .s_axi_awlock  (s_axi.awlock),
        .s_axi_awcache (s_axi.awcache),
        .s_axi_awprot  (s_axi.awprot),
        .s_axi_awqos   (4'd0),
        .s_axi_awregion(4'd0),
        .s_axi_awuser  (0),
        .s_axi_awvalid (s_axi.awvalid),
        .s_axi_awready (s_axi.awready),
        .s_axi_wdata   (s_axi.wdata),
        .s_axi_wstrb   (s_axi.wstrb),
        .s_axi_wlast   (s_axi.wlast),
        .s_axi_wuser   (0),
        .s_axi_wvalid  (s_axi.wvalid),
        .s_axi_wready  (s_axi.wready),
        .s_axi_bid     (s_axi.bid),
        .s_axi_bresp   (s_axi.bresp),
        .s_axi_buser   (),
        .s_axi_bvalid  (s_axi.bvalid),
        .s_axi_bready  (s_axi.bready),
        .s_axi_arid    (s_axi.arid),
        .s_axi_araddr  (s_axi.araddr[ADDR_WIDTH-1:0]),
        .s_axi_arlen   (s_axi.arlen),
        .s_axi_arsize  (s_axi.arsize),
        .s_axi_arburst (s_axi.arburst),
        .s_axi_arlock  (s_axi.arlock),
        .s_axi_arcache (s_axi.arcache),
        .s_axi_arprot  (s_axi.arprot),
        .s_axi_arqos   (4'd0),
        .s_axi_arregion(4'd0),
        .s_axi_aruser  (0),
        .s_axi_arvalid (s_axi.arvalid),
        .s_axi_arready (s_axi.arready),
        .s_axi_rid     (s_axi.rid),
        .s_axi_rdata   (s_axi.rdata),
        .s_axi_rresp   (s_axi.rresp),
        .s_axi_rlast   (s_axi.rlast),
        .s_axi_ruser   (),
        .s_axi_rvalid  (s_axi.rvalid),
        .s_axi_rready  (s_axi.rready),

        /*
     * RAM interface
     */
        .ram_cmd_id       (ram_b_cmd_id),
        .ram_cmd_addr     (ram_b_cmd_addr),
        .ram_cmd_lock     (),
        .ram_cmd_cache    (),
        .ram_cmd_prot     (),
        .ram_cmd_qos      (),
        .ram_cmd_region   (),
        .ram_cmd_auser    (),
        .ram_cmd_wr_data  (ram_b_cmd_wr_data),
        .ram_cmd_wr_strb  (ram_b_cmd_wr_strb),
        .ram_cmd_wr_user  (),
        .ram_cmd_wr_en    (ram_b_cmd_wr_en),
        .ram_cmd_rd_en    (ram_b_cmd_rd_en),
        .ram_cmd_last     (ram_b_cmd_last),
        .ram_cmd_ready    (ram_b_cmd_ready),
        .ram_rd_resp_id   (ram_b_rd_resp_id_reg),
        .ram_rd_resp_data (ram_b_rd_resp_data_reg),
        .ram_rd_resp_last (ram_b_rd_resp_last_reg),
        .ram_rd_resp_user (0),
        .ram_rd_resp_valid(ram_b_rd_resp_valid_reg),
        .ram_rd_resp_ready(ram_b_rd_resp_ready)
    );

    // (* RAM_STYLE="BLOCK" *)
    reg  [      DATA_WIDTH-1:0] mem         [(2**VALID_ADDR_WIDTH)-1];

    wire [VALID_ADDR_WIDTH-1:0] word_addr_a;
    assign word_addr_a = dport.addr[ADDR_WIDTH-1:ADDR_WIDTH-VALID_ADDR_WIDTH];
    wire [VALID_ADDR_WIDTH-1:0] word_addr_b;
    assign word_addr_b = ram_b_cmd_addr[ADDR_WIDTH-1:ADDR_WIDTH-VALID_ADDR_WIDTH];

    integer i, j;

    initial begin
        // two nested loops for smaller number of iterations per loop
        // workaround for synthesizer complaints about large loop counts
        for (i = 0; i < 2 ** VALID_ADDR_WIDTH; i = i + 2 ** (VALID_ADDR_WIDTH / 2)) begin
            for (j = i; j < i + 2 ** (VALID_ADDR_WIDTH / 2); j = j + 1) begin
                mem[j] = 0;
            end
        end
    end

    always_ff @(posedge a_clk) begin : proc_
        if (a_rst) begin
            dport.gnt    <= 0;
            dport.rvalid <= 0;
            dport.rdata  <= 0;
        end else begin
            dport.gnt <= 1;
            if (dport.req && ~dport.we) begin
                dport.rvalid <= 1;
                dport.rdata  <= mem[word_addr_a];
            end else if (dport.req && dport.we) begin
                dport.rvalid <= 1;
                dport.rdata  <= 0;
                for (i = 0; i < 4; i = i + 1) begin
                    if (dport.be[i]) begin
                        mem[word_addr_a][8*i+:8] <= dport.wdata[8*i+:8];
                    end
                end
            end else begin
                dport.rvalid <= 0;
                dport.rdata  <= 0;
            end
        end
    end

    assign ram_b_cmd_ready = !ram_b_rd_resp_valid_reg || ram_b_rd_resp_ready;

    always @(posedge a_clk) begin
        ram_b_rd_resp_valid_reg <= ram_b_rd_resp_valid_reg && !ram_b_rd_resp_ready;

        if (ram_b_cmd_rd_en && ram_b_cmd_ready) begin
            ram_b_rd_resp_id_reg    <= ram_b_cmd_id;
            ram_b_rd_resp_data_reg  <= mem[word_addr_b];
            ram_b_rd_resp_last_reg  <= ram_b_cmd_last;
            ram_b_rd_resp_valid_reg <= 1'b1;
        end else if (ram_b_cmd_wr_en && ram_b_cmd_ready) begin
            for (i = 0; i < WORD_WIDTH; i = i + 1) begin
                if (ram_b_cmd_wr_strb[i]) begin
                    mem[word_addr_b][WORD_SIZE*i+:WORD_SIZE] <= ram_b_cmd_wr_data[WORD_SIZE*i+:WORD_SIZE];
                end
            end
        end

        if (a_rst) begin
            ram_b_rd_resp_valid_reg <= 1'b0;
        end
    end

endmodule : dport_dtcm


