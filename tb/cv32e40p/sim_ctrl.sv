module sim_ctrl (
    input clk_i,
    input rst_i,

    input               req_i,
    input               we_i,
    input        [ 3:0] be_i,
    input        [31:0] addr_i,
    input        [31:0] wdata_i,
    output logic        rvalid_o,
    output logic [31:0] rdata_o
);
    localparam logic [7:0] CHAR_OUT_ADDR = 8'h0;
    localparam logic [7:0] SIM_CTRL_ADDR = 8'h4;

    logic   [7:0] ctrl_addr;
    logic   [2:0] sim_finish;

    integer       log_fd;

    assign ctrl_addr = addr_i[9:2];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_i) begin
            rvalid_o   <= 0;
            sim_finish <= 'b0;
        end else begin
            // Immediately respond to any request
            rvalid_o <= req_i;

            if (req_i & we_i) begin
                case (ctrl_addr)
                    CHAR_OUT_ADDR: begin
                        if (be_i[0]) begin
                            $fwrite(0, "%c", wdata_i[7:0]);
                            $fflush(0);
                        end
                    end
                    SIM_CTRL_ADDR: begin
                        if ((be_i[0] & wdata_i[0]) && (sim_finish == 'b0)) begin
                            $display("Terminating simulation by software request.");
                            $finish;
                        end
                    end
                    default: ;
                endcase
            end
        end
    end

    assign rdata_o = '0;
endmodule : sim_ctrl
