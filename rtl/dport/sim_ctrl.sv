module sim_ctrl (
    input logic          clk_i,
    input logic          rst_i,
          dport_if.slave dport
);
    localparam logic [7:0] CHAR_OUT_ADDR = 8'h0;
    localparam logic [7:0] SIM_CTRL_ADDR = 8'h4;

    logic [7:0] ctrl_addr;

    assign ctrl_addr = dport.addr[9:2];

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            dport.rvalid <= 0;
        end else begin
            dport.rvalid <= dport.req;
            if (dport.req & dport.we) begin
                case (ctrl_addr)
                    CHAR_OUT_ADDR: begin
                        if (dport.be[0]) begin
                            $fwrite(0, "%c", dport.wdata[7:0]);
                            $fflush(0);
                        end
                    end
                    SIM_CTRL_ADDR: begin
                        if ((dport.be[0] & dport.wdata[0])) begin
                            $display("Terminating simulation by software request.");
                            $finish;
                        end
                    end
                    default: ;
                endcase
            end
        end
    end

    assign dport.rdata = '0;
endmodule : sim_ctrl
