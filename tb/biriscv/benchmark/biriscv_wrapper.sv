module biriscv_wrapper #(
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
    input logic        i_clk,
    input logic        i_rst,
    input logic [31:0] i_irq,

    obi_if.master instr_dport,
    obi_if.master data_dport
);
    logic        mem_i_accept_i;
    logic        mem_i_valid_i;
    logic        mem_i_error_i;
    logic [63:0] mem_i_inst_i;
    logic        mem_i_rd_o;
    logic        mem_i_flush_o;
    logic        mem_i_invalidate_o;
    logic [31:0] mem_i_pc_o;
    //
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
        .intr_i            (i_irq[7]),
        .reset_vector_i    (BOOT_ADDRESS),
        .cpu_id_i          (HART_ID),
        //
        .mem_i_accept_i    (mem_i_accept_i),
        .mem_i_valid_i     (mem_i_valid_i),
        .mem_i_error_i     (mem_i_error_i),
        .mem_i_inst_i      (mem_i_inst_i),
        .mem_i_rd_o        (mem_i_rd_o),
        .mem_i_pc_o        (mem_i_pc_o),
        .mem_i_flush_o     (mem_i_flush_o),
        .mem_i_invalidate_o(mem_i_invalidate_o),
        //
        .mem_d_data_rd_i   (mem_d_data_rd_i),
        .mem_d_accept_i    (mem_d_accept_i),
        .mem_d_ack_i       (mem_d_ack_i),
        .mem_d_error_i     (mem_d_error_i),
        .mem_d_addr_o      (mem_d_addr_o),
        .mem_d_data_wr_o   (mem_d_data_wr_o),
        .mem_d_rd_o        (mem_d_rd_o),
        .mem_d_wr_o        (mem_d_wr_o),
        .mem_d_resp_tag_i  (mem_d_resp_tag_i),
        .mem_d_cacheable_o (mem_d_cacheable_o),
        .mem_d_req_tag_o   (mem_d_req_tag_o),
        .mem_d_invalidate_o(mem_d_invalidate_o),
        .mem_d_writeback_o (mem_d_writeback_o),
        .mem_d_flush_o     (mem_d_flush_o)
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
    assign mem_d_resp_tag_i   = 0;


endmodule : biriscv_wrapper
