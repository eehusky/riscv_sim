module tb_cv32e40p (
    input logic i_clk,
    input logic i_rst
);

    logic        clk_i;
    logic        rst_i;
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
    logic        irq_mei;
    logic        irq_msi;
    logic        irq_mti;
    logic        irq_mti_clear;
    logic        irq_msi_clear;
    logic        irq_mei_clear;

    initial begin
        pulp_clock_en_i     = 0;  // PULP clock enable (only used if COREV_CLUSTER = 1)
        scan_cg_en_i        = 1;  // Enable all clock gates for testing
        boot_addr_i         = 32'h8000_0000;
        mtvec_addr_i        = 32'h8000_1000;
        dm_halt_addr_i      = 32'h1A11_0800;
        hart_id_i           = 0;
        dm_exception_addr_i = 0;
        irq_i               = 0;
        debug_req_i         = 0;
        fetch_enable_i      = 1;  // make the core start fetching instruction immediately
    end

    assign clk_i         = i_clk;
    assign rst_ni        = ~i_rst;
    assign rst_i         = i_rst;
    assign irq_i[2:0]    = 3'b0;
    assign irq_i[3]      = irq_msi;
    assign irq_i[6:4]    = 3'b0;
    assign irq_i[7]      = irq_mti;
    assign irq_i[10:8]   = 3'b0;
    assign irq_i[11]     = irq_mei;
    assign irq_i[15:12]  = 3'b0;

    assign irq_mti_clear = irq_ack_o && irq_id_o == 3;
    assign irq_msi_clear = irq_ack_o && irq_id_o == 7;
    assign irq_mei_clear = irq_ack_o && irq_id_o == 11;

    cv32e40p_top #(
        .COREV_PULP      (0),  // PULP ISA Extension (incl. custom CSRs and hardware loop, excl. cv.elw)
        .COREV_CLUSTER   (0),  // PULP Cluster interface (incl. cv.elw)
        .FPU             (0),  // Floating Point Unit (interfaced via APU interface)
        .FPU_ADDMUL_LAT  (0),  // Floating-Point ADDition/MULtiplication computing lane pipeline registers number
        .FPU_OTHERS_LAT  (0),  // Floating-Point COMParison/CONVersion computing lanes pipeline registers number
        .ZFINX           (0),  // Float-in-General Purpose registers
        .NUM_MHPMCOUNTERS(0)
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

    obi_if instr_dport ();
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
    dport_ram #(
        .ADDR_WIDTH(17)
    ) i_instr_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(instr_dport)
    );

    obi_if data_dport ();
    assign data_gnt_i        = data_dport.gnt;
    assign data_dport.req    = data_req_o;
    assign data_dport.addr   = data_req_o ? data_addr_o : 0;
    assign data_dport.we     = data_req_o ? data_we_o : 0;
    assign data_dport.be     = data_req_o ? data_be_o : 0;
    assign data_dport.wdata  = data_req_o ? data_wdata_o : 0;
    assign data_dport.aid    = data_req_o ? 0 : 0;
    assign data_dport.rready = 1;
    assign data_rvalid_i     = data_dport.rvalid;
    assign data_rdata_i      = data_dport.rvalid ? data_dport.rdata : 0;
    //data_dport.err;
    //data_dport.rid;

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
endmodule : tb_cv32e40p
