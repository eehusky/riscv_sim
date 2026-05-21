module picorv32_wrapper #(
    parameter bit [31:0] BOOT_ADDRESS         = 32'h8000_0000,
    parameter bit [31:0] IRQ_ADDRESS          = 32'h8000_0000,
    //
    parameter bit        ENABLE_COUNTERS      = 1,
    parameter bit        ENABLE_COUNTERS64    = 1,
    parameter bit        ENABLE_REGS_16_31    = 1,
    parameter bit        ENABLE_REGS_DUALPORT = 1,
    parameter bit        LATCHED_MEM_RDATA    = 0,
    parameter bit        TWO_STAGE_SHIFT      = 1,
    parameter bit        BARREL_SHIFTER       = 0,
    parameter bit        TWO_CYCLE_COMPARE    = 0,
    parameter bit        TWO_CYCLE_ALU        = 0,
    parameter bit        COMPRESSED_ISA       = 0,
    parameter bit        CATCH_MISALIGN       = 1,
    parameter bit        CATCH_ILLINSN        = 1,
    parameter bit        ENABLE_PCPI          = 0,
    parameter bit        ENABLE_MUL           = 0,
    parameter bit        ENABLE_FAST_MUL      = 0,
    parameter bit        ENABLE_DIV           = 0,
    parameter bit        ENABLE_IRQ           = 0,
    parameter bit        ENABLE_IRQ_QREGS     = 1,
    parameter bit        ENABLE_IRQ_TIMER     = 1,
    parameter bit        ENABLE_TRACE         = 0,
    parameter bit        REGS_INIT_ZERO       = 0,
    parameter bit [31:0] MASKED_IRQ           = 32'h0000_0000,
    parameter bit [31:0] LATCHED_IRQ          = 32'hffff_ffff,
    parameter bit [31:0] PROGADDR_RESET       = BOOT_ADDRESS,
    parameter bit [31:0] PROGADDR_IRQ         = IRQ_ADDRESS,
    parameter bit [31:0] STACKADDR            = 32'hffff_ffff
) (
    input logic        clk_i,
    input logic        rst_i,
    input logic [31:0] irq_i,

    input logic         debug_req_i,
          obi_if.master instr_dport,
          obi_if.master data_dport
);

    logic        trap;
    logic        mem_valid;
    logic        mem_instr;
    logic        mem_ready;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [ 3:0] mem_wstrb;
    logic [31:0] mem_rdata;
    // Look-Ahead Interface
    logic        mem_la_read;
    logic        mem_la_write;
    logic [31:0] mem_la_addr;
    logic [31:0] mem_la_wdata;
    logic [ 3:0] mem_la_wstrb;
    //// Pico Co-Processor Interface (PCPI)
    //logic        pcpi_valid;
    //logic [31:0] pcpi_insn;
    //logic [31:0] pcpi_rs1;
    //logic [31:0] pcpi_rs2;
    //logic        pcpi_wr;
    //logic [31:0] pcpi_rd;
    //logic        pcpi_wait;
    //logic        pcpi_ready;
    // IRQ Interface
    //logic [31:0] irq;
    logic [31:0] eoi;
    logic        trace_valid;
    logic [35:0] trace_data;

    picorv32 #(
        .ENABLE_COUNTERS     (ENABLE_COUNTERS),
        .ENABLE_COUNTERS64   (ENABLE_COUNTERS64),
        .ENABLE_REGS_16_31   (ENABLE_REGS_16_31),
        .ENABLE_REGS_DUALPORT(ENABLE_REGS_DUALPORT),
        .LATCHED_MEM_RDATA   (LATCHED_MEM_RDATA),
        .TWO_STAGE_SHIFT     (TWO_STAGE_SHIFT),
        .BARREL_SHIFTER      (BARREL_SHIFTER),
        .TWO_CYCLE_COMPARE   (TWO_CYCLE_COMPARE),
        .TWO_CYCLE_ALU       (TWO_CYCLE_ALU),
        .COMPRESSED_ISA      (COMPRESSED_ISA),
        .CATCH_MISALIGN      (CATCH_MISALIGN),
        .CATCH_ILLINSN       (CATCH_ILLINSN),
        .ENABLE_PCPI         (ENABLE_PCPI),
        .ENABLE_MUL          (ENABLE_MUL),
        .ENABLE_FAST_MUL     (ENABLE_FAST_MUL),
        .ENABLE_DIV          (ENABLE_DIV),
        .ENABLE_IRQ          (ENABLE_IRQ),
        .ENABLE_IRQ_QREGS    (ENABLE_IRQ_QREGS),
        .ENABLE_IRQ_TIMER    (ENABLE_IRQ_TIMER),
        .ENABLE_TRACE        (ENABLE_TRACE),
        .REGS_INIT_ZERO      (REGS_INIT_ZERO),
        .MASKED_IRQ          (MASKED_IRQ),
        .LATCHED_IRQ         (LATCHED_IRQ),
        .PROGADDR_RESET      (PROGADDR_RESET),
        .PROGADDR_IRQ        (PROGADDR_IRQ),
        .STACKADDR           (STACKADDR)
    ) i_picorv32 (
        .clk         (clk_i),        //input
        .resetn      (~rst_i),       //input
        .trap        (trap),         //output
        .mem_valid   (mem_valid),    //output
        .mem_instr   (mem_instr),    //output
        .mem_ready   (mem_ready),    //input
        .mem_addr    (mem_addr),     //output
        .mem_wdata   (mem_wdata),    //output
        .mem_wstrb   (mem_wstrb),    //output
        .mem_rdata   (mem_rdata),    //input
        .mem_la_read (mem_la_read),  //output
        .mem_la_write(mem_la_write), //output
        .mem_la_addr (mem_la_addr),  //output
        .mem_la_wdata(mem_la_wdata), //output
        .mem_la_wstrb(mem_la_wstrb), //output
        .pcpi_valid  (),             //output
        .pcpi_insn   (),             //output
        .pcpi_rs1    (),             //output
        .pcpi_rs2    (),             //output
        .pcpi_wr     (0),            //input
        .pcpi_rd     (0),            //input
        .pcpi_wait   (0),            //input
        .pcpi_ready  (0),            //input
        .irq         (irq_i),        //input
        .eoi         (eoi),          //output
        .trace_valid (trace_valid),  //output
        .trace_data  (trace_data)    //output
    );

    assign mem_ready         = data_dport.rvalid;
    assign data_dport.req    = mem_la_read|| mem_la_write;
    assign data_dport.addr   = mem_la_addr;
    assign data_dport.we     = mem_la_write;
    assign data_dport.be     = mem_la_wstrb;
    assign data_dport.wdata  = mem_la_wdata;
    assign data_dport.aid    = 0;
    assign data_dport.rready = 1;
    assign mem_rdata         = data_dport.rdata;


endmodule : picorv32_wrapper
