module tb_ibex (
    input logic i_clk,
    input logic i_rst
);
    parameter bit [31:0] BOOT_ADDRESS = 32'h8000_0000;
    parameter int HART_ID = 0;
    parameter bit [31:0] DM_BASE_ADDR = 32'h0010_0000;
    parameter bit [31:0] DM_ADDR_MASK = 32'h0000_0003;
    parameter bit [31:0] DM_HALT_ADDR = 32'h0010_0000;
    parameter bit [31:0] DM_EXCEPTION_ADDR = 32'h0010_0000;
    parameter bit SecureIbex = 1'b0;
    parameter int unsigned LockstepOffset = 1;
    parameter bit ICacheScramble = 1'b0;
    parameter bit PMPEnable = 1'b0;
    parameter int unsigned PMPGranularity = 0;
    parameter int unsigned PMPNumRegions = 4;
    parameter int unsigned MHPMCounterNum = 0;
    parameter int unsigned MHPMCounterWidth = 40;
    parameter bit RV32E = 1'b0;
    parameter ibex_pkg::rv32m_e RV32M = ibex_pkg::RV32MSingleCycle;
    parameter ibex_pkg::rv32b_e RV32B = ibex_pkg::RV32BFull;
    parameter ibex_pkg::rv32zc_e RV32ZC = ibex_pkg::RV32ZcaZcbZcmp;
    parameter ibex_pkg::regfile_e RegFile = ibex_pkg::RegFileFF;
    parameter bit BranchTargetALU = 1'b1;
    parameter bit WritebackStage = 1'b1;
    parameter bit ICache = 1'b0;
    parameter bit DbgTriggerEn = 1'b0;
    parameter bit ICacheECC = 1'b0;
    parameter bit ICacheTweakInfection = 1'b0;
    parameter bit BranchPredictor = 1'b1;


    logic [31:0] irq_i;
    obi_if instr_dport ();
    obi_if data_dport ();

    ibex_wrapper #(
        .BOOT_ADDRESS        (BOOT_ADDRESS),
        .HART_ID             (HART_ID),
        .DM_BASE_ADDR        (DM_BASE_ADDR),
        .DM_ADDR_MASK        (DM_ADDR_MASK),
        .DM_HALT_ADDR        (DM_HALT_ADDR),
        .DM_EXCEPTION_ADDR   (DM_EXCEPTION_ADDR),
        .SecureIbex          (SecureIbex),
        .LockstepOffset      (LockstepOffset),
        .ICacheScramble      (ICacheScramble),
        .PMPEnable           (PMPEnable),
        .PMPGranularity      (PMPGranularity),
        .PMPNumRegions       (PMPNumRegions),
        .MHPMCounterNum      (MHPMCounterNum),
        .MHPMCounterWidth    (MHPMCounterWidth),
        .RV32E               (RV32E),
        .RV32M               (RV32M),
        .RV32B               (RV32B),
        .RV32ZC              (RV32ZC),
        .RegFile             (RegFile),
        .BranchTargetALU     (BranchTargetALU),
        .WritebackStage      (WritebackStage),
        .ICache              (ICache),
        .DbgTriggerEn        (DbgTriggerEn),
        .ICacheECC           (ICacheECC),
        .ICacheTweakInfection(ICacheTweakInfection),
        .BranchPredictor     (BranchPredictor)
    ) i_ibex_wrapper (
        .clk_i      (i_clk),
        .rst_i      (i_rst),
        .irq_i      (irq_i),
        .instr_dport(instr_dport),
        .data_dport (data_dport)
    );


    // ------------------------------------------------------------------------
    logic clk_i;
    logic rst_i;
    assign clk_i = i_clk;
    assign rst_i = i_rst;

    obi_if segments[obi_pkg::N_TARGETS] ();

    obi_demux #(
        .N_TARGETS(obi_pkg::N_TARGETS),
        .SLAVE_ADDR(obi_pkg::SLAVE_ADDR),
        .SLAVE_MASK(obi_pkg::SLAVE_MASK)
    ) i_obi_demux (
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
        .intr_o      (irq_i[7]),
        .clear_intr_i(0)
    );

    // ------------------------------------------------------------------------

    sim_ctrl i_sim_ctrl (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[1])
    );

    // ------------------------------------------------------------------------

    obi_ram #(
        .ADDR_WIDTH(17)
    ) i_instr_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(instr_dport)
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
        .dport(segments[3]),
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
endmodule : tb_ibex
