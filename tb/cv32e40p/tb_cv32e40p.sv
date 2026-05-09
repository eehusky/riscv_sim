module tb_cv32e40p (
    input logic i_clk,
    input logic i_rst
);

    logic        clk_i;
    logic        rst_ni;
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
    logic [31:0] irq_i;
    logic        irq_ack_o;
    logic [ 4:0] irq_id_o;
    logic        debug_req_i;
    logic        debug_havereset_o;
    logic        debug_running_o;
    logic        debug_halted_o;
    logic        fetch_enable_i;
    logic        core_sleep_o;

    initial begin
        pulp_clock_en_i     = 0;  // PULP clock enable (only used if COREV_CLUSTER = 1)
        scan_cg_en_i        = 1;  // Enable all clock gates for testing
        boot_addr_i         = 32'h8000_0000;
        mtvec_addr_i        = 0;
        dm_halt_addr_i      = 32'h1A110800;
        hart_id_i           = 0;
        dm_exception_addr_i = 0;
        irq_i               = 0;
        debug_req_i         = 0;
        fetch_enable_i      = 1;  // make the core start fetching instruction immediately
    end

    assign clk_i  = i_clk;
    assign rst_ni = ~i_rst;

    cv32e40p_top #(
        .COREV_PULP      (0),  // PULP ISA Extension (incl. custom CSRs and hardware loop, excl. cv.elw)
        .COREV_CLUSTER   (0),  // PULP Cluster interface (incl. cv.elw)
        .FPU             (0),  // Floating Point Unit (interfaced via APU interface)
        .FPU_ADDMUL_LAT  (0),  // Floating-Point ADDition/MULtiplication computing lane pipeline registers number
        .FPU_OTHERS_LAT  (0),  // Floating-Point COMParison/CONVersion computing lanes pipeline registers number
        .ZFINX           (0),  // Float-in-General Purpose registers
        .NUM_MHPMCOUNTERS(32)
    ) i_cv32e40p_top (
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
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

    // req         Master Slave    Address transfer request. req=1 signals the availability of valid address phase signals.
    // gnt         Slave  Master   Grant. Ready to accept address transfer. Address transfer is accepted on rising clk with req=1 and gnt=1.
    // addr[]      Master Slave    Address
    // we          Master Slave    Write Enable, high for writes, low for reads.
    // be[]        Master Slave    Byte Enable. Is set for the bytes to write/read.
    // wdata[]     Master Slave    Write data. Only valid for write transactions. Undefined for read transactions

    dport_if instr_dport ();
    obi_if instr_obi ();
    obi2dport i_instr_cnvt (
        .obi  (instr_obi),
        .dport(instr_dport)
    );
    assign instr_obi.req   = instr_req_o;
    assign instr_obi.we    = 0;
    assign instr_obi.wdata = 0;
    assign instr_obi.be    = 0;
    assign instr_obi.addr  = instr_addr_o;
    assign instr_gnt_i     = instr_obi.gnt;
    assign instr_rvalid_i  = instr_obi.rvalid;
    assign instr_rdata_i   = instr_obi.rdata;

    dport_ram i_instr_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(instr_dport)
    );

    dport_if data_dport ();
    obi_if data_obi ();
    obi2dport i_data_cnvt (
        .obi  (data_obi),
        .dport(data_dport)
    );
    assign data_obi.req   = data_req_o;
    assign data_obi.we    = data_we_o;
    assign data_obi.wdata = data_wdata_o;
    assign data_obi.be    = data_be_o;
    assign data_obi.addr  = data_addr_o;
    assign data_gnt_i     = data_obi.gnt;
    assign data_rvalid_i  = data_obi.rvalid;
    assign data_rdata_i   = data_obi.rdata;

    dport_ram i_data_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(data_dport)
    );

`ifdef verilator
    //-------------------------------------------------------------
    // write: Write byte into memory
    //-------------------------------------------------------------
    function write;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            case (addr[1:0])
                2'd0: i_instr_ram.mem[addr/4][7:0] = data;
                2'd1: i_instr_ram.mem[addr/4][15:8] = data;
                2'd2: i_instr_ram.mem[addr/4][23:16] = data;
                2'd3: i_instr_ram.mem[addr/4][31:24] = data;
                //3'd4: i_uncore.ram.ram.memory.ram.RAM[addr/8][39:32] = data;
                //3'd5: i_uncore.ram.ram.memory.ram.RAM[addr/8][47:40] = data;
                //3'd6: i_uncore.ram.ram.memory.ram.RAM[addr/8][55:48] = data;
                //3'd7: i_uncore.ram.ram.memory.ram.RAM[addr/8][63:56] = data;
            endcase
        end
    endfunction
    //-------------------------------------------------------------
    // read: Read byte from memory
    //-------------------------------------------------------------
    function [7:0] read;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[1:0])
                2'd0: read = i_instr_ram.mem[addr/4][7:0];
                2'd1: read = i_instr_ram.mem[addr/4][15:8];
                2'd2: read = i_instr_ram.mem[addr/4][23:16];
                2'd3: read = i_instr_ram.mem[addr/4][31:24];
                //3'd4: read = i_axi_ram.mem[addr/8][39:32];
                //3'd5: read = i_axi_ram.mem[addr/8][47:40];
                //3'd6: read = i_axi_ram.mem[addr/8][55:48];
                //3'd7: read = i_axi_ram.mem[addr/8][63:56];
            endcase
        end
    endfunction
`endif





    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end

endmodule : tb_cv32e40p


module obi2dport (
    obi_if.slave    obi,
    dport_if.master dport
);
    assign obi.rvalid    = dport.ack;
    assign obi.rdata     = dport.data_rd;
    assign obi.gnt       = dport.accept;
    assign dport.rd      = obi.req && ~obi.we;
    assign dport.wr      = obi.req && obi.we ? obi.be : 0;
    assign dport.addr    = obi.req ? obi.addr : 0;
    assign dport.data_wr = obi.wdata;

endmodule : obi2dport
