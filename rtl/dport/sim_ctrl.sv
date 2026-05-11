module sim_ctrl (
    input logic          clk_i,
    input logic          rst_i,
          obi_if.slave dport
);
    localparam logic [7:0] CHAR_OUT_ADDR = 8'h00;
    localparam logic [7:0] SIM_CTRL_ADDR = 8'h04;

    logic [7:0] ctrl_addr;
    logic req_rd;
    logic req_wr;
    logic [7:0] serial_data_o;
    logic serial_valid_o;

    assign req_rd = dport.req & ~dport.we;
    assign req_wr = dport.req & dport.we;
    assign ctrl_addr = dport.addr[7:0];

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            dport.rvalid <= 0;
            dport.rdata <= 0;
            dport.gnt <= 0;
        end else begin
            dport.gnt <= 1;
            dport.rvalid <= dport.req;
            if (req_wr) begin
                dport.rdata <= 0;
                case (ctrl_addr)
                    CHAR_OUT_ADDR: begin
                        if (dport.be[0]) begin
                            $write("%c", dport.wdata[7:0]);
                            serial_data_o<=dport.wdata[7:0];
                            serial_valid_o<=1;
                            //$flush();
                        end
                    end
                    SIM_CTRL_ADDR: begin
                        serial_data_o<=0;
                        serial_valid_o<=0;
                        case(dport.wdata)
                            32'h00000000: begin
                                $display("\033[32m Terminating simulation by software request. \033[0m");
                                $finish;
                            end
                            default begin
                                $error("\033[31m Terminating simulation with SW error code 0x%08h. \033[0m", dport.wdata);
                                //$stop;
                            end
                        endcase // dport.wdata

                    end
                    default begin
                        serial_data_o<=0;
                        serial_valid_o<=0;
                    end
                endcase
            end else begin
                serial_data_o<=0;
                serial_valid_o<=0;
            end
        end
    end
endmodule : sim_ctrl
