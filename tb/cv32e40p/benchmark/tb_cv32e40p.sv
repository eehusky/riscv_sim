module tb_cv32e40p (
    input logic i_clk,
    input logic i_rst
);

    parameter bit [31:0] BOOT_ADDRESS      = 32'h8000_0000;
    parameter int        HART_ID           = 0;
    parameter bit [31:0] MTVEC_ADDR        = 32'h8000_1000;
    parameter bit [31:0] DM_HALT_ADDR      = 32'h1A11_0800;
    parameter bit [31:0] DM_EXCEPTION_ADDR = 32'h00000000;
    parameter bit        COREV_PULP        = 0;
    parameter bit        COREV_CLUSTER     = 0;
    parameter bit        FPU               = 0;
    parameter int        FPU_ADDMUL_LAT    = 0;
    parameter int        FPU_OTHERS_LAT    = 0;
    parameter bit        ZFINX             = 0;
    parameter int        NUM_MHPMCOUNTERS  = 1;


    logic        clk_i;
    logic        rst_i;

    logic [31:0] irq_i;

    obi_if instr_dport ();
    obi_if data_dport ();

    assign clk_i         = i_clk;
    assign rst_i         = i_rst;


    cv32e40p_wrapper #(
        .BOOT_ADDRESS(BOOT_ADDRESS),
        .HART_ID(HART_ID),
        .MTVEC_ADDR(MTVEC_ADDR),
        .DM_HALT_ADDR(DM_HALT_ADDR),
        .DM_EXCEPTION_ADDR(DM_EXCEPTION_ADDR),
        .COREV_PULP(COREV_PULP),
        .COREV_CLUSTER(COREV_CLUSTER),
        .FPU(FPU),
        .FPU_ADDMUL_LAT(FPU_ADDMUL_LAT),
        .FPU_OTHERS_LAT(FPU_OTHERS_LAT),
        .ZFINX(ZFINX),
        .NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS)
    ) i_cv32e40p_wrapper (
        .clk_i      (i_clk),
        .rst_i      (i_rst),
        .irq_i      (irq_i),
        .instr_dport(instr_dport),
        .data_dport (data_dport)
    );


    logic        irq_mei;
    logic        irq_msi;
    logic        irq_mti;
    logic        irq_mti_clear;
    logic        irq_msi_clear;
    logic        irq_mei_clear;


    assign irq_i[2:0]    = 3'b0;
    assign irq_i[3]      = irq_msi;
    assign irq_i[6:4]    = 3'b0;
    assign irq_i[7]      = irq_mti;
    assign irq_i[10:8]   = 3'b0;
    assign irq_i[11]     = irq_mei;
    assign irq_i[15:12]  = 3'b0;

    //assign irq_mti_clear = irq_ack_o && irq_id_o == 3;
    //assign irq_msi_clear = irq_ack_o && irq_id_o == 7;
    //assign irq_mei_clear = irq_ack_o && irq_id_o == 11;


    dport_ram #(
        .ADDR_WIDTH(17)
    ) i_instr_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(instr_dport)
    );

    obi_if segments[dport_pkg::N_SEGMENTS] ();

    dport_demux i_dport_demux (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .cpu     (data_dport),
        .segments(segments)
    );

    // ------------------------------------------------------------------------

    mtime32 i_mtime (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .dport       (segments[0]),
        .intr_o      (irq_mti),
        .clear_intr_i(irq_mti_clear)
    );

    // ------------------------------------------------------------------------

    sim_ctrl i_sim_ctrl (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[1])
    );

    // ------------------------------------------------------------------------

    axi_if s_axi_dtcm ();
    dport_dtcm #(
        .DATA_WIDTH       (s_axi_dtcm.DATA_WIDTH),
        .ADDR_WIDTH       (dport_pkg::DTCM_WIDTH),
        .STRB_WIDTH       (s_axi_dtcm.STRB_WIDTH),
        .ID_WIDTH         (s_axi_dtcm.ID_WIDTH),
        .B_PIPELINE_OUTPUT(0),
        .B_INTERLEAVE     (0)
    ) i_dport_dtcm (
        .a_clk(clk_i),
        .a_rst(rst_i),
        .dport(segments[2]),
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
            i_dport_dtcm.write(addr, data);
        end
    endfunction
    function static bit [7:0] read_dtcm;  /*verilator public*/
        input [31:0] addr;
        begin
            read_dtcm = i_dport_dtcm.read(addr);
        end
    endfunction

    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end
endmodule : tb_cv32e40p
