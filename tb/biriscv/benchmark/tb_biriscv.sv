module tb_biriscv (
    input i_clk,
    input i_rst
);
    parameter bit [31:0] BOOT_ADDRESS = 32'h8000000;
    parameter int HART_ID = 0;

    parameter bit SUPPORT_BRANCH_PREDICTION = 1;
    parameter bit SUPPORT_MULDIV = 1;
    parameter bit SUPPORT_SUPER = 0;
    parameter bit SUPPORT_MMU = 0;
    parameter bit SUPPORT_DUAL_ISSUE = 1;
    parameter bit SUPPORT_LOAD_BYPASS = 1;
    parameter bit SUPPORT_MUL_BYPASS = 1;
    parameter bit SUPPORT_REGFILE_XILINX = 0;
    parameter bit EXTRA_DECODE_STAGE = 0;
    parameter bit [31:0] MEM_CACHE_ADDR_MIN = 32'h80000000;
    parameter bit [31:0] MEM_CACHE_ADDR_MAX = 32'h8fffffff;
    parameter int NUM_BTB_ENTRIES = 32;
    parameter int NUM_BTB_ENTRIES_W = 5;
    parameter int NUM_BHT_ENTRIES = 512;
    parameter int NUM_BHT_ENTRIES_W = 9;
    parameter bit RAS_ENABLE = 1;
    parameter bit GSHARE_ENABLE = 0;
    parameter bit BHT_ENABLE = 1;
    parameter int NUM_RAS_ENTRIES = 8;
    parameter int NUM_RAS_ENTRIES_W = 3;

    logic        mem_i_accept_i;
    logic        mem_i_valid_i;
    logic        mem_i_error_i;
    logic [63:0] mem_i_inst_i;
    logic        mem_i_rd_o;
    logic        mem_i_flush_o;
    logic        mem_i_invalidate_o;
    logic [31:0] mem_i_pc_o;
    logic [31:0] mem_d_data_rd_i;
    logic        mem_d_accept_i;
    logic        mem_d_ack_i;
    logic        mem_d_error_i;
    logic [10:0] mem_d_resp_tag_i;
    logic [31:0] mem_d_addr_o;
    logic [31:0] mem_d_data_wr_o;
    logic        mem_d_rd_o;
    logic [ 3:0] mem_d_wr_o;
    logic        mem_d_cacheable_o;
    logic [10:0] mem_d_req_tag_o;
    logic        mem_d_invalidate_o;
    logic        mem_d_writeback_o;
    logic        mem_d_flush_o;
    logic        clk_i;
    logic        rst_i;
    logic        timer_irq;

    assign clk_i = i_clk;
    assign rst_i = i_rst;

    riscv_core #(
        .MEM_CACHE_ADDR_MIN       (MEM_CACHE_ADDR_MIN),
        .MEM_CACHE_ADDR_MAX       (MEM_CACHE_ADDR_MAX),
        .SUPPORT_BRANCH_PREDICTION(SUPPORT_BRANCH_PREDICTION),
        .SUPPORT_MULDIV           (SUPPORT_MULDIV),
        .SUPPORT_SUPER            (SUPPORT_SUPER),
        .SUPPORT_MMU              (SUPPORT_MMU),
        .SUPPORT_DUAL_ISSUE       (SUPPORT_DUAL_ISSUE),
        .SUPPORT_LOAD_BYPASS      (SUPPORT_LOAD_BYPASS),
        .SUPPORT_MUL_BYPASS       (SUPPORT_MUL_BYPASS),
        .SUPPORT_REGFILE_XILINX   (SUPPORT_REGFILE_XILINX),
        .EXTRA_DECODE_STAGE       (EXTRA_DECODE_STAGE),
        .NUM_BTB_ENTRIES          (NUM_BTB_ENTRIES),
        .NUM_BTB_ENTRIES_W        (NUM_BTB_ENTRIES_W),
        .NUM_BHT_ENTRIES          (NUM_BHT_ENTRIES),
        .NUM_BHT_ENTRIES_W        (NUM_BHT_ENTRIES_W),
        .RAS_ENABLE               (RAS_ENABLE),
        .GSHARE_ENABLE            (GSHARE_ENABLE),
        .BHT_ENABLE               (BHT_ENABLE),
        .NUM_RAS_ENTRIES          (NUM_RAS_ENTRIES),
        .NUM_RAS_ENTRIES_W        (NUM_RAS_ENTRIES_W)
    ) u_core (
        .clk_i             (i_clk),
        .rst_i             (i_rst),
        .intr_i            (timer_irq),
        .reset_vector_i    (BOOT_ADDRESS),
        .cpu_id_i          (HART_ID),
        //
        .mem_i_accept_i    (mem_i_accept_i),
        .mem_i_valid_i     (mem_i_valid_i),
        .mem_i_error_i     (mem_i_error_i),
        .mem_i_inst_i      (mem_i_inst_i),
        .mem_i_rd_o        (mem_i_rd_o),
        .mem_i_pc_o        (mem_i_pc_o),
        .mem_i_flush_o     (),
        .mem_i_invalidate_o(),
        //
        .mem_d_data_rd_i   (mem_d_data_rd_i),
        .mem_d_accept_i    (mem_d_accept_i),
        .mem_d_ack_i       (mem_d_ack_i),
        .mem_d_error_i     (mem_d_error_i),
        .mem_d_addr_o      (mem_d_addr_o),
        .mem_d_data_wr_o   (mem_d_data_wr_o),
        .mem_d_rd_o        (mem_d_rd_o),
        .mem_d_wr_o        (mem_d_wr_o),
        .mem_d_resp_tag_i  (0),
        .mem_d_cacheable_o (),
        .mem_d_req_tag_o   (),
        .mem_d_invalidate_o(),
        .mem_d_writeback_o (),
        .mem_d_flush_o     ()
    );
    assign mem_i_accept_i     = instr_dport.gnt;
    assign instr_dport.req    = mem_i_rd_o;
    assign instr_dport.addr   = mem_i_pc_o;
    assign instr_dport.we     = 0;
    assign instr_dport.be     = 0;
    assign instr_dport.wdata  = 0;
    assign instr_dport.aid    = 0;
    assign instr_dport.rready = 1;
    assign mem_i_valid_i      = instr_dport.rvalid;
    assign mem_i_inst_i       = instr_dport.rdata;
    assign mem_i_error_i      = instr_dport.err;
    //assign instr_dport.rid    = 0;


    assign mem_d_accept_i     = data_dport.gnt;
    assign data_dport.req     = mem_d_rd_o || |mem_d_wr_o;
    assign data_dport.addr    = mem_d_addr_o;
    assign data_dport.we      = |mem_d_wr_o;
    assign data_dport.be      = mem_d_wr_o;
    assign data_dport.wdata   = mem_d_data_wr_o;
    assign data_dport.aid     = 0;
    assign data_dport.rready  = 1;
    assign mem_d_ack_i        = data_dport.rvalid;
    assign mem_d_data_rd_i    = data_dport.rdata;
    assign mem_d_error_i      = data_dport.err;
    //assign data_dport.rid     = 0;


    // ------------------------------------------------------------------------

    obi_if #(.DATA_WIDTH(64)) instr_dport ();
    dport_ram #(
        .ADDR_WIDTH(17)
    ) i_instr_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(instr_dport)
    );

    obi_if data_dport ();
    obi_if segments[dport_pkg::N_SEGMENTS] ();

    dport_mux i_dport_mux (
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
        .intr_o      (timer_irq),
        .clear_intr_i(0)
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
            //$display("ITCM: %08X: %08X", addr, data);
            case (addr[1:0])
                2'd0: i_instr_ram.mem[addr/4][7:0] = data;
                2'd1: i_instr_ram.mem[addr/4][15:8] = data;
                2'd2: i_instr_ram.mem[addr/4][23:16] = data;
                2'd3: i_instr_ram.mem[addr/4][31:24] = data;
            endcase
        end
    endfunction
    function [7:0] read_itcm;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[1:0])
                2'd0: read_itcm = i_instr_ram.mem[addr/4][7:0];
                2'd1: read_itcm = i_instr_ram.mem[addr/4][15:8];
                2'd2: read_itcm = i_instr_ram.mem[addr/4][23:16];
                2'd3: read_itcm = i_instr_ram.mem[addr/4][31:24];
            endcase
        end
    endfunction

    function static void write_dtcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            //$display("DTCM: %08X: %08X", addr, data);
            case (addr[1:0])
                2'd0: i_dport_dtcm.mem[addr/4][7:0] = data;
                2'd1: i_dport_dtcm.mem[addr/4][15:8] = data;
                2'd2: i_dport_dtcm.mem[addr/4][23:16] = data;
                2'd3: i_dport_dtcm.mem[addr/4][31:24] = data;
            endcase
        end
    endfunction
    function [7:0] read_dtcm;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[1:0])
                2'd0: read_dtcm = i_dport_dtcm.mem[addr/4][7:0];
                2'd1: read_dtcm = i_dport_dtcm.mem[addr/4][15:8];
                2'd2: read_dtcm = i_dport_dtcm.mem[addr/4][23:16];
                2'd3: read_dtcm = i_dport_dtcm.mem[addr/4][31:24];
            endcase
        end
    endfunction

    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end



endmodule : tb_biriscv


