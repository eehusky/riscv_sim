module tb_top #(
    parameter bit [31:0] BOOT_ADDRESS         = 32'h8000_0000,
    parameter bit [31:0] IRQ_ADDRESS          = 32'h1000_0000,
    //
    parameter bit        ENABLE_COUNTERS      = 1,
    parameter bit        ENABLE_COUNTERS64    = 1,
    parameter bit        ENABLE_REGS_16_31    = 1,
    parameter bit        ENABLE_REGS_DUALPORT = 1,
    parameter bit        LATCHED_MEM_RDATA    = 0,
    parameter bit        TWO_STAGE_SHIFT      = 0,
    parameter bit        BARREL_SHIFTER       = 1,
    parameter bit        TWO_CYCLE_COMPARE    = 0,
    parameter bit        TWO_CYCLE_ALU        = 0,
    parameter bit        COMPRESSED_ISA       = 1,
    parameter bit        CATCH_MISALIGN       = 1,
    parameter bit        CATCH_ILLINSN        = 1,
    parameter bit        ENABLE_PCPI          = 1,
    parameter bit        ENABLE_MUL           = 1,
    parameter bit        ENABLE_FAST_MUL      = 1,
    parameter bit        ENABLE_DIV           = 1,
    parameter bit        ENABLE_IRQ           = 0,
    parameter bit        ENABLE_IRQ_QREGS     = 1,
    parameter bit        ENABLE_IRQ_TIMER     = 1,
    parameter bit        ENABLE_TRACE         = 1,
    parameter bit        REGS_INIT_ZERO       = 0,
    parameter bit [31:0] MASKED_IRQ           = 32'h0000_0000,
    parameter bit [31:0] LATCHED_IRQ          = 32'hffff_ffff
) (
    input logic clk_i,
    input logic rst_i
);
    localparam int INITIATOR_ID_WIDTH = 1;
    localparam int TARGET_ID_WIDTH = INITIATOR_ID_WIDTH + $clog2(obi_pkg::N_INITIATORS);

    logic [31:0] irq;
    obi_if #(.ID_WIDTH(INITIATOR_ID_WIDTH)) initiators[obi_pkg::N_INITIATORS] ();
    obi_if #(.ID_WIDTH(TARGET_ID_WIDTH)) targets[obi_pkg::N_TARGETS] ();


    picorv32_wrapper #(
        .BOOT_ADDRESS(BOOT_ADDRESS),
        .IRQ_ADDRESS(IRQ_ADDRESS),
        .ENABLE_COUNTERS(ENABLE_COUNTERS),
        .ENABLE_COUNTERS64(ENABLE_COUNTERS64),
        .ENABLE_REGS_16_31(ENABLE_REGS_16_31),
        .ENABLE_REGS_DUALPORT(ENABLE_REGS_DUALPORT),
        .LATCHED_MEM_RDATA(LATCHED_MEM_RDATA),
        .TWO_STAGE_SHIFT(TWO_STAGE_SHIFT),
        .BARREL_SHIFTER(BARREL_SHIFTER),
        .TWO_CYCLE_COMPARE(TWO_CYCLE_COMPARE),
        .TWO_CYCLE_ALU(TWO_CYCLE_ALU),
        .COMPRESSED_ISA(COMPRESSED_ISA),
        .CATCH_MISALIGN(CATCH_MISALIGN),
        .CATCH_ILLINSN(CATCH_ILLINSN),
        .ENABLE_PCPI(ENABLE_PCPI),
        .ENABLE_MUL(ENABLE_MUL),
        .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
        .ENABLE_DIV(ENABLE_DIV),
        .ENABLE_IRQ(ENABLE_IRQ),
        .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS),
        .ENABLE_IRQ_TIMER(ENABLE_IRQ_TIMER),
        .ENABLE_TRACE(ENABLE_TRACE),
        .REGS_INIT_ZERO(REGS_INIT_ZERO),
        .MASKED_IRQ(MASKED_IRQ),
        .LATCHED_IRQ(LATCHED_IRQ)

    ) i_picorv32_wrapper (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .irq_i(0),
        .debug_req_i(0),
        .instr_dport(initiators[0]),
        .data_dport(initiators[1])
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
        .intr_o      (irq[7]),
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
endmodule : tb_top
