module cv32e40p_wrapper #(
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
    input logic        clk_i,
    input logic        rst_i,
    input logic [31:0] irq_i,

    obi_if.master instr_dport,
    obi_if.master data_dport
);

    logic        pulp_clock_en_i;
    logic        scan_cg_en_i;
    logic [31:0] boot_addr_i;
    logic [31:0] mtvec_addr_i;
    logic [31:0] dm_halt_addr_i;
    logic [31:0] hart_id_i;
    logic [31:0] dm_exception_addr_i;
    logic        instr_req_o;
    logic        instr_gnt_i;
    logic        instr_rvalid_i;
    logic [31:0] instr_addr_o;
    logic [31:0] instr_rdata_i;
    logic        data_req_o;
    logic        data_gnt_i;
    logic        data_rvalid_i;
    logic        data_we_o;
    logic [ 3:0] data_be_o;
    logic [31:0] data_addr_o;
    logic [31:0] data_wdata_o;
    logic [31:0] data_rdata_i;

    logic        irq_ack_o;
    logic [ 4:0] irq_id_o;
    logic        debug_req_i;
    logic        debug_havereset_o;
    logic        debug_running_o;
    logic        debug_halted_o;
    logic        fetch_enable_i;
    logic        core_sleep_o;


    assign pulp_clock_en_i     = 0;
    assign scan_cg_en_i        = 1;
    assign debug_req_i         = 0;
    assign fetch_enable_i      = 1;

    assign boot_addr_i         = BOOT_ADDRESS;
    assign mtvec_addr_i        = MTVEC_ADDR;
    assign dm_halt_addr_i      = DM_HALT_ADDR;
    assign dm_exception_addr_i = DM_EXCEPTION_ADDR;

    cv32e40p_top #(
        .COREV_PULP      (COREV_PULP),
        .COREV_CLUSTER   (COREV_CLUSTER),
        .FPU             (FPU),
        .FPU_ADDMUL_LAT  (FPU_ADDMUL_LAT),
        .FPU_OTHERS_LAT  (FPU_OTHERS_LAT),
        .ZFINX           (ZFINX),
        .NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS)
    ) i_cv32e40p_top (
        .clk_i              (clk_i),
        .rst_ni             (~rst_i),
        .pulp_clock_en_i    (pulp_clock_en_i),
        .scan_cg_en_i       (scan_cg_en_i),
        .boot_addr_i        (boot_addr_i),
        .mtvec_addr_i       (mtvec_addr_i),
        .dm_halt_addr_i     (dm_halt_addr_i),
        .hart_id_i          (hart_id_i),
        .dm_exception_addr_i(dm_exception_addr_i),
        .instr_req_o        (instr_req_o),
        .instr_gnt_i        (instr_gnt_i),
        .instr_rvalid_i     (instr_rvalid_i),
        .instr_addr_o       (instr_addr_o),
        .instr_rdata_i      (instr_rdata_i),
        .data_req_o         (data_req_o),
        .data_gnt_i         (data_gnt_i),
        .data_rvalid_i      (data_rvalid_i),
        .data_we_o          (data_we_o),
        .data_be_o          (data_be_o),
        .data_addr_o        (data_addr_o),
        .data_wdata_o       (data_wdata_o),
        .data_rdata_i       (data_rdata_i),
        .irq_i              (irq_i),
        .irq_ack_o          (irq_ack_o),
        .irq_id_o           (irq_id_o),
        .debug_req_i        (debug_req_i),
        .debug_havereset_o  (debug_havereset_o),
        .debug_running_o    (debug_running_o),
        .debug_halted_o     (debug_halted_o),
        .fetch_enable_i     (fetch_enable_i),
        .core_sleep_o       (core_sleep_o)
    );


    assign instr_gnt_i        = instr_dport.gnt;
    assign instr_dport.req    = instr_req_o;
    assign instr_dport.addr   = instr_addr_o;
    assign instr_dport.we     = 0;
    assign instr_dport.be     = 0;
    assign instr_dport.wdata  = 0;
    assign instr_dport.aid    = 0;
    assign instr_dport.rready = 1;
    assign instr_rvalid_i     = instr_dport.rvalid;
    assign instr_rdata_i      = instr_dport.rdata;

    assign data_gnt_i         = data_dport.gnt;
    assign data_dport.req     = data_req_o;
    assign data_dport.addr    = data_req_o ? data_addr_o : 0;
    assign data_dport.we      = data_req_o ? data_we_o : 0;
    assign data_dport.be      = data_req_o ? data_be_o : 0;
    assign data_dport.wdata   = data_req_o ? data_wdata_o : 0;
    assign data_dport.aid     = data_req_o ? 0 : 0;
    assign data_dport.rready  = 1;
    assign data_rvalid_i      = data_dport.rvalid;
    assign data_rdata_i       = data_dport.rvalid ? data_dport.rdata : 0;
endmodule : cv32e40p_wrapper
