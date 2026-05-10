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

    assign req_rd = dport.req & ~dport.we;
    assign req_wr = dport.req & dport.we;
    assign ctrl_addr = dport.addr[9:2];

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            dport.rvalid <= 0;
            dport.rdata <= 0;
        end else begin
            dport.rvalid <= dport.req;
            if (req_wr) begin
                dport.rdata <= 0;
                case (ctrl_addr)
                    CHAR_OUT_ADDR: begin
                        if (dport.be[0]) begin
                            $fwrite(0, "%c", dport.wdata[7:0]);
                            $fflush(0);
                        end
                    end
                    SIM_CTRL_ADDR: begin
                        case(dport.wdata)
                            32'h00000000: begin
                                $display("Terminating simulation by software request.");
                                $finish;
                            end
                            default begin
                                $error("Terminating simulation with error code 0x%08h.",dport.wdata);
                                $abort;
                            end
                        endcase // dport.wdata

                    end
                    default: ;
                endcase
            end
        end
    end
endmodule : sim_ctrl
