module tb_cv32e40p #(
    parameter bit [31:0] BOOT_ADDRESS      = 32'h8000_0000,
    parameter int        HART_ID           = 0,
    parameter bit [31:0] MTVEC_ADDR        = 32'h8000_1000,
    parameter bit [31:0] DM_HALT_ADDR      = 32'h1A11_0800,
    parameter bit [31:0] DM_EXCEPTION_ADDR = 32'h00000000,
    parameter bit        COREV_PULP        = 0,
    parameter bit        COREV_CLUSTER     = 0,
    parameter bit        FPU               = 0,
    parameter int        FPU_ADDMUL_LAT    = 0,
    parameter int        FPU_OTHERS_LAT    = 0,
    parameter bit        ZFINX             = 0,
    parameter int        NUM_MHPMCOUNTERS  = 1
) (
    input logic clk_i,
    input logic rst_i
);

    localparam int INITIATOR_ID_WIDTH = 1;
    localparam int TARGET_ID_WIDTH = INITIATOR_ID_WIDTH + $clog2(obi_pkg::N_INITIATORS);

    logic [31:0] irq_i;
    obi_if #(.ID_WIDTH(INITIATOR_ID_WIDTH)) initiators[obi_pkg::N_INITIATORS] ();
    obi_if #(.ID_WIDTH(TARGET_ID_WIDTH)) targets[obi_pkg::N_TARGETS] ();

    cv32e40p_wrapper #(
        .BOOT_ADDRESS     (BOOT_ADDRESS),
        .HART_ID          (HART_ID),
        .MTVEC_ADDR       (MTVEC_ADDR),
        .DM_HALT_ADDR     (DM_HALT_ADDR),
        .DM_EXCEPTION_ADDR(DM_EXCEPTION_ADDR),
        .COREV_PULP       (COREV_PULP),
        .COREV_CLUSTER    (COREV_CLUSTER),
        .FPU              (FPU),
        .FPU_ADDMUL_LAT   (FPU_ADDMUL_LAT),
        .FPU_OTHERS_LAT   (FPU_OTHERS_LAT),
        .ZFINX            (ZFINX),
        .NUM_MHPMCOUNTERS (NUM_MHPMCOUNTERS)
    ) i_cv32e40p_wrapper (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .irq_i      (irq_i),
        .instr_dport(initiators[0]),
        .data_dport (initiators[1])
    );

    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------

    obi_xbar #(
        .N_INITIATORS(obi_pkg::N_INITIATORS),
        .N_TARGETS   (obi_pkg::N_TARGETS)
    ) i_obi_xbar (
        .rst_i,
        .clk_i,
        .initiators(initiators),
        .targets   (targets)
    );

    // ------------------------------------------------------------------------

    mtime32 i_mtime (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .dport       (targets[0]),
        .intr_o      (irq_i[7]),
        .clear_intr_i(0)
    );

    // ------------------------------------------------------------------------

    sim_ctrl i_sim_ctrl (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(targets[1])
    );

    // ------------------------------------------------------------------------

    obi_ram #(
        .ADDR_WIDTH(obi_pkg::ITCM_WIDTH)
    ) i_instr_ram (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(targets[2])
    );

    // ------------------------------------------------------------------------

    axi_if s_axi_dtcm ();
    obi_dtcm #(
        .DATA_WIDTH       (s_axi_dtcm.DATA_WIDTH),
        .ADDR_WIDTH       (obi_pkg::DTCM_WIDTH),
        .STRB_WIDTH       (s_axi_dtcm.STRB_WIDTH),
        .ID_WIDTH         (s_axi_dtcm.ID_WIDTH),
        .B_PIPELINE_OUTPUT(0),
        .B_INTERLEAVE     (0)
    ) i_obi_dtcm (
        .a_clk(clk_i),
        .a_rst(rst_i),
        .dport(targets[3]),
        .s_axi(s_axi_dtcm)
    );

    // ------------------------------------------------------------------------

    function static void write_itcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            i_instr_ram.write(addr, data);
        end
    endfunction
    function static bit [7:0] read_itcm;  /*verilator public*/
        input [31:0] addr;
        begin
            read_itcm = i_instr_ram.read(addr);
        end
    endfunction

    function static void write_dtcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            i_obi_dtcm.write(addr, data);
        end
    endfunction
    function static bit [7:0] read_dtcm;  /*verilator public*/
        input [31:0] addr;
        begin
            read_dtcm = i_obi_dtcm.read(addr);
        end
    endfunction

    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end
endmodule : tb_cv32e40p
