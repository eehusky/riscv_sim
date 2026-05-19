module tb_biriscv #(
    parameter bit [31:0] BOOT_ADDRESS              = 32'h80000000,
    parameter int        HART_ID                   = 0,
    parameter bit        SUPPORT_BRANCH_PREDICTION = 1,
    parameter bit        SUPPORT_MULDIV            = 1,
    parameter bit        SUPPORT_SUPER             = 0,
    parameter bit        SUPPORT_MMU               = 0,
    parameter bit        SUPPORT_DUAL_ISSUE        = 1,
    parameter bit        SUPPORT_LOAD_BYPASS       = 1,
    parameter bit        SUPPORT_MUL_BYPASS        = 1,
    parameter bit        SUPPORT_REGFILE_XILINX    = 0,
    parameter bit        EXTRA_DECODE_STAGE        = 0,
    parameter bit [31:0] MEM_CACHE_ADDR_MIN        = 32'h80000000,
    parameter bit [31:0] MEM_CACHE_ADDR_MAX        = 32'h8fffffff,
    parameter int        NUM_BTB_ENTRIES           = 32,
    parameter int        NUM_BTB_ENTRIES_W         = $clog2(NUM_BTB_ENTRIES),
    parameter bit        BHT_ENABLE                = 1,
    parameter int        NUM_BHT_ENTRIES           = 512,
    parameter int        NUM_BHT_ENTRIES_W         = $clog2(NUM_BHT_ENTRIES),
    parameter bit        GSHARE_ENABLE             = 0,
    parameter bit        RAS_ENABLE                = 1,
    parameter int        NUM_RAS_ENTRIES           = 8,
    parameter int        NUM_RAS_ENTRIES_W         = $clog2(NUM_RAS_ENTRIES)
) (
    input clk_i,
    input rst_i
);

    logic [31:0] irq_i;

    obi_if #(.DATA_WIDTH(64)) instr_dport ();
    obi_if data_dport ();

    biriscv_wrapper #(
        .BOOT_ADDRESS             (BOOT_ADDRESS),
        .HART_ID                  (HART_ID),
        .SUPPORT_BRANCH_PREDICTION(SUPPORT_BRANCH_PREDICTION),
        .SUPPORT_MULDIV           (SUPPORT_MULDIV),
        .SUPPORT_SUPER            (SUPPORT_SUPER),
        .SUPPORT_MMU              (SUPPORT_MMU),
        .SUPPORT_DUAL_ISSUE       (SUPPORT_DUAL_ISSUE),
        .SUPPORT_LOAD_BYPASS      (SUPPORT_LOAD_BYPASS),
        .SUPPORT_MUL_BYPASS       (SUPPORT_MUL_BYPASS),
        .SUPPORT_REGFILE_XILINX   (SUPPORT_REGFILE_XILINX),
        .EXTRA_DECODE_STAGE       (EXTRA_DECODE_STAGE),
        .MEM_CACHE_ADDR_MIN       (MEM_CACHE_ADDR_MIN),
        .MEM_CACHE_ADDR_MAX       (MEM_CACHE_ADDR_MAX),
        .NUM_BTB_ENTRIES          (NUM_BTB_ENTRIES),
        .NUM_BTB_ENTRIES_W        (NUM_BTB_ENTRIES_W),
        .BHT_ENABLE               (BHT_ENABLE),
        .NUM_BHT_ENTRIES          (NUM_BHT_ENTRIES),
        .NUM_BHT_ENTRIES_W        (NUM_BHT_ENTRIES_W),
        .GSHARE_ENABLE            (GSHARE_ENABLE),
        .RAS_ENABLE               (RAS_ENABLE),
        .NUM_RAS_ENTRIES          (NUM_RAS_ENTRIES),
        .NUM_RAS_ENTRIES_W        (NUM_RAS_ENTRIES_W)
    ) i_biriscv_wrapper (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .irq_i      (irq_i),
        .instr_dport(instr_dport),
        .data_dport (data_dport)
    );

    // ------------------------------------------------------------------------


    obi_if targets[obi_pkg::N_TARGETS] ();

    obi_demux #(
        .N_TARGETS (obi_pkg::N_TARGETS),
        .SLAVE_ADDR(obi_pkg::SLAVE_ADDR),
        .SLAVE_MASK(obi_pkg::SLAVE_MASK)
    ) i_obi_demux (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .initiator     (data_dport),
        .targets(targets)
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
        .ADDR_WIDTH(17)
    ) i_instr_ram (
        .clk_i(clk_i),
        .rst_i(rst_i),
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
endmodule : tb_biriscv


