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
        .FPU             (1),  // Floating Point Unit (interfaced via APU interface)
        .FPU_ADDMUL_LAT  (3),  // Floating-Point ADDition/MULtiplication computing lane pipeline registers number
        .FPU_OTHERS_LAT  (3),  // Floating-Point COMParison/CONVersion computing lanes pipeline registers number
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




    /*
    Level sensistive active high interrupt inputs.
    Not all interrupt inputs can be used on CV32E40P.
    Specifically
        irq_i[15:12]
        irq_i[10:8]
        irq_i[6:4]
        irq_i[2:0]
    shall be tied to 0 externally as they are reserved for future standard use
    (or for cores which are not Machine mode only) in the RISC-V Privileged specification.

    MEI: irq_i[11]
    MTI: irq_i[7]
    MSI: irq_i[3]
    correspond to the Machine External Interrupt (MEI), Machine Timer Interrupt (MTI), and Machine Software Interrupt (MSI) respectively.

    The irq_i[31:16] interrupts are a CV32E40P specific extension to the RISC-V Basic (a.k.a. CLINT) interrupt scheme.
    */

    // req         Master Slave    Address transfer request. req=1 signals the availability of valid address phase signals.
    // gnt         Slave  Master   Grant. Ready to accept address transfer. Address transfer is accepted on rising clk with req=1 and gnt=1.
    // addr[]      Master Slave    Address
    // we          Master Slave    Write Enable, high for writes, low for reads.
    // be[]        Master Slave    Byte Enable. Is set for the bytes to write/read.
    // wdata[]     Master Slave    Write data. Only valid for write transactions. Undefined for read transactions

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

    axi_if m_axi_cached ();
    dport2axi i_dport2axi_cached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[3]),
        .m_axi(m_axi_cached)
    );

    axi_ram #(
        .DATA_WIDTH(m_axi_cached.DATA_WIDTH),
        .ADDR_WIDTH(dport_pkg::CACHED_WIDTH),
        .STRB_WIDTH(m_axi_cached.STRB_WIDTH),
        .ID_WIDTH  (m_axi_cached.ID_WIDTH)
    ) i_axi_cached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_cached.awid),
        .s_axi_awaddr (m_axi_cached.awaddr[dport_pkg::CACHED_WIDTH-1:0]),
        .s_axi_awlen  (m_axi_cached.awlen),
        .s_axi_awsize (m_axi_cached.awsize),
        .s_axi_awburst(m_axi_cached.awburst),
        .s_axi_awlock (m_axi_cached.awlock),
        .s_axi_awcache(m_axi_cached.awcache),
        .s_axi_awprot (m_axi_cached.awprot),
        .s_axi_awvalid(m_axi_cached.awvalid),
        .s_axi_awready(m_axi_cached.awready),
        .s_axi_wdata  (m_axi_cached.wdata),
        .s_axi_wstrb  (m_axi_cached.wstrb),
        .s_axi_wlast  (m_axi_cached.wlast),
        .s_axi_wvalid (m_axi_cached.wvalid),
        .s_axi_wready (m_axi_cached.wready),
        .s_axi_bid    (m_axi_cached.bid),
        .s_axi_bresp  (m_axi_cached.bresp),
        .s_axi_bvalid (m_axi_cached.bvalid),
        .s_axi_bready (m_axi_cached.bready),
        .s_axi_arid   (m_axi_cached.arid),
        .s_axi_araddr (m_axi_cached.araddr[dport_pkg::CACHED_WIDTH-1:0]),
        .s_axi_arlen  (m_axi_cached.arlen),
        .s_axi_arsize (m_axi_cached.arsize),
        .s_axi_arburst(m_axi_cached.arburst),
        .s_axi_arlock (m_axi_cached.arlock),
        .s_axi_arcache(m_axi_cached.arcache),
        .s_axi_arprot (m_axi_cached.arprot),
        .s_axi_arvalid(m_axi_cached.arvalid),
        .s_axi_arready(m_axi_cached.arready),
        .s_axi_rid    (m_axi_cached.rid),
        .s_axi_rdata  (m_axi_cached.rdata),
        .s_axi_rresp  (m_axi_cached.rresp),
        .s_axi_rlast  (m_axi_cached.rlast),
        .s_axi_rvalid (m_axi_cached.rvalid),
        .s_axi_rready (m_axi_cached.rready)
    );

    // ------------------------------------------------------------------------

    axi_if m_axi_uncached ();
    dport2axi i_dport2axi_uncached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[4]),
        .m_axi(m_axi_uncached)
    );

    axi_ram #(
        .DATA_WIDTH(m_axi_uncached.DATA_WIDTH),
        .ADDR_WIDTH(dport_pkg::UNCACHED_WIDTH),
        .STRB_WIDTH(m_axi_uncached.STRB_WIDTH),
        .ID_WIDTH  (m_axi_uncached.ID_WIDTH)
    ) i_axi_uncached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_uncached.awid),
        .s_axi_awaddr (m_axi_uncached.awaddr[dport_pkg::UNCACHED_WIDTH-1:0]),
        .s_axi_awlen  (m_axi_uncached.awlen),
        .s_axi_awsize (m_axi_uncached.awsize),
        .s_axi_awburst(m_axi_uncached.awburst),
        .s_axi_awlock (m_axi_uncached.awlock),
        .s_axi_awcache(m_axi_uncached.awcache),
        .s_axi_awprot (m_axi_uncached.awprot),
        .s_axi_awvalid(m_axi_uncached.awvalid),
        .s_axi_awready(m_axi_uncached.awready),
        .s_axi_wdata  (m_axi_uncached.wdata),
        .s_axi_wstrb  (m_axi_uncached.wstrb),
        .s_axi_wlast  (m_axi_uncached.wlast),
        .s_axi_wvalid (m_axi_uncached.wvalid),
        .s_axi_wready (m_axi_uncached.wready),
        .s_axi_bid    (m_axi_uncached.bid),
        .s_axi_bresp  (m_axi_uncached.bresp),
        .s_axi_bvalid (m_axi_uncached.bvalid),
        .s_axi_bready (m_axi_uncached.bready),
        .s_axi_arid   (m_axi_uncached.arid),
        .s_axi_araddr (m_axi_uncached.araddr[dport_pkg::UNCACHED_WIDTH-1:0]),
        .s_axi_arlen  (m_axi_uncached.arlen),
        .s_axi_arsize (m_axi_uncached.arsize),
        .s_axi_arburst(m_axi_uncached.arburst),
        .s_axi_arlock (m_axi_uncached.arlock),
        .s_axi_arcache(m_axi_uncached.arcache),
        .s_axi_arprot (m_axi_uncached.arprot),
        .s_axi_arvalid(m_axi_uncached.arvalid),
        .s_axi_arready(m_axi_uncached.arready),
        .s_axi_rid    (m_axi_uncached.rid),
        .s_axi_rdata  (m_axi_uncached.rdata),
        .s_axi_rresp  (m_axi_uncached.rresp),
        .s_axi_rlast  (m_axi_uncached.rlast),
        .s_axi_rvalid (m_axi_uncached.rvalid),
        .s_axi_rready (m_axi_uncached.rready)
    );

    // ------------------------------------------------------------------------

    axil_if m_axil ();
    dport2axil i_dport2axil (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .dport (segments[5]),
        .m_axil(m_axil)
    );

    //axil_ram #(
    //    .DATA_WIDTH     (m_axil.DATA_WIDTH),
    //    .ADDR_WIDTH     (dport_pkg::AXIL_WIDTH),
    //    .STRB_WIDTH     (m_axil.STRB_WIDTH),
    //    .PIPELINE_OUTPUT(0)
    //) i_axil_ram (
    //    .clk           (clk_i),
    //    .rst           (rst_i),
    //    .s_axil_awaddr (m_axil.awaddr[dport_pkg::AXIL_WIDTH-1:0]),
    //    .s_axil_awprot (m_axil.awprot),
    //    .s_axil_awvalid(m_axil.awvalid),
    //    .s_axil_awready(m_axil.awready),
    //    .s_axil_wdata  (m_axil.wdata),
    //    .s_axil_wstrb  (m_axil.wstrb),
    //    .s_axil_wvalid (m_axil.wvalid),
    //    .s_axil_wready (m_axil.wready),
    //    .s_axil_bresp  (m_axil.bresp),
    //    .s_axil_bvalid (m_axil.bvalid),
    //    .s_axil_bready (m_axil.bready),
    //    .s_axil_araddr (m_axil.araddr[dport_pkg::AXIL_WIDTH-1:0]),
    //    .s_axil_arprot (m_axil.arprot),
    //    .s_axil_arvalid(m_axil.arvalid),
    //    .s_axil_arready(m_axil.arready),
    //    .s_axil_rdata  (m_axil.rdata),
    //    .s_axil_rresp  (m_axil.rresp),
    //    .s_axil_rvalid (m_axil.rvalid),
    //    .s_axil_rready (m_axil.rready)
    //);



    localparam int M_AXI_DATA_WIDTH = 32;
    localparam int M_AXI_ADDR_WIDTH = 32;
    localparam int M_AXI_ID_WIDTH = 4;
    localparam int M00_AXIS_TDATA_WIDTH = 8;
    localparam int M01_AXIS_TDATA_WIDTH = 16;
    localparam int S00_AXIS_TDATA_WIDTH = 8;
    localparam int S01_AXIS_TDATA_WIDTH = 16;
    localparam int S_AXIL_DATA_WIDTH    = ringbuffer_addrmap_pkg::RINGBUFFER_ADDRMAP_MIN_ADDR_WIDTH;

    ringbuffer_axis_if #(.TDATA_WIDTH(M00_AXIS_TDATA_WIDTH)) m00_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(M01_AXIS_TDATA_WIDTH)) m01_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(S00_AXIS_TDATA_WIDTH)) s00_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(S01_AXIS_TDATA_WIDTH)) s01_axis ();

    logic [M00_AXIS_TDATA_WIDTH-1:0] x00_counter;
    always_ff @(posedge i_clk) begin : proc_x00
        if(i_rst) begin
             x00_counter <= 0;
        end else begin
            if(m00_axis.tready & m00_axis.tvalid) begin
                assert(m00_axis.tdata == x00_counter);
                x00_counter <= x00_counter + 1;
            end
        end
    end

    logic [M01_AXIS_TDATA_WIDTH-1:0] x01_counter;
    always_ff @(posedge i_clk) begin : proc_x01
        if(i_rst) begin
             x01_counter <= 0;
        end else begin
            if(m01_axis.tready & m01_axis.tvalid) begin
                assert(m01_axis.tdata == x01_counter);
                x01_counter <= x01_counter + 1;
            end
        end
    end


    assign s00_axis.tdata =  m00_axis.tdata;
    assign m00_axis.tready = s00_axis.tready;
    assign s00_axis.tvalid = m00_axis.tvalid;

    assign s01_axis.tdata = m01_axis.tdata;
    assign m01_axis.tready = s01_axis.tready;
    assign s01_axis.tvalid = m01_axis.tvalid;

    ringbuffer_axil #(
        .M00_AXIS_TDATA_WIDTH(M00_AXIS_TDATA_WIDTH),
        .M01_AXIS_TDATA_WIDTH(M01_AXIS_TDATA_WIDTH),
        .S00_AXIS_TDATA_WIDTH(S00_AXIS_TDATA_WIDTH),
        .S01_AXIS_TDATA_WIDTH(S01_AXIS_TDATA_WIDTH),
        .M_AXI_ADDR_WIDTH    (M_AXI_ADDR_WIDTH),
        .M_AXI_DATA_WIDTH    (M_AXI_DATA_WIDTH),
        .M_AXI_ID_WIDTH      (M_AXI_ID_WIDTH)
    ) i_ringbuffer_axil (
        .i_clk         (i_clk),
        .i_reset       (i_rst),
        //
        .o_interrupt   (irq_mei),
        //
        .m00_axis      (m00_axis),
        .m01_axis      (m01_axis),
        .s00_axis      (s00_axis),
        .s01_axis      (s01_axis),
        //
        .s_axil_awaddr (m_axil.awaddr[dport_pkg::AXIL_WIDTH-1:0]),
        .s_axil_awprot (m_axil.awprot),
        .s_axil_awvalid(m_axil.awvalid),
        .s_axil_awready(m_axil.awready),
        .s_axil_wdata  (m_axil.wdata),
        .s_axil_wstrb  (m_axil.wstrb),
        .s_axil_wvalid (m_axil.wvalid),
        .s_axil_wready (m_axil.wready),
        .s_axil_bresp  (m_axil.bresp),
        .s_axil_bvalid (m_axil.bvalid),
        .s_axil_bready (m_axil.bready),
        .s_axil_araddr (m_axil.araddr[dport_pkg::AXIL_WIDTH-1:0]),
        .s_axil_arprot (m_axil.arprot),
        .s_axil_arvalid(m_axil.arvalid),
        .s_axil_arready(m_axil.arready),
        .s_axil_rdata  (m_axil.rdata),
        .s_axil_rresp  (m_axil.rresp),
        .s_axil_rvalid (m_axil.rvalid),
        .s_axil_rready (m_axil.rready),
        //
        .m_axi_arvalid (s_axi_dtcm.arvalid),
        .m_axi_arready (s_axi_dtcm.arready),
        .m_axi_araddr  (s_axi_dtcm.araddr),
        .m_axi_arlen   (s_axi_dtcm.arlen),
        .m_axi_arsize  (s_axi_dtcm.arsize),
        .m_axi_arburst (s_axi_dtcm.arburst),
        .m_axi_arid    (s_axi_dtcm.arid),
        .m_axi_rvalid  (s_axi_dtcm.rvalid),
        .m_axi_rready  (s_axi_dtcm.rready),
        .m_axi_rdata   (s_axi_dtcm.rdata),
        .m_axi_rlast   (s_axi_dtcm.rlast),
        .m_axi_rid     (s_axi_dtcm.rid),
        .m_axi_rresp   (s_axi_dtcm.rresp),
        .m_axi_awvalid (s_axi_dtcm.awvalid),
        .m_axi_awready (s_axi_dtcm.awready),
        .m_axi_awaddr  (s_axi_dtcm.awaddr),
        .m_axi_awlen   (s_axi_dtcm.awlen),
        .m_axi_awsize  (s_axi_dtcm.awsize),
        .m_axi_awburst (s_axi_dtcm.awburst),
        .m_axi_awid    (s_axi_dtcm.awid),
        .m_axi_wvalid  (s_axi_dtcm.wvalid),
        .m_axi_wready  (s_axi_dtcm.wready),
        .m_axi_wdata   (s_axi_dtcm.wdata),
        .m_axi_wstrb   (s_axi_dtcm.wstrb),
        .m_axi_wlast   (s_axi_dtcm.wlast),
        .m_axi_bvalid  (s_axi_dtcm.bvalid),
        .m_axi_bready  (s_axi_dtcm.bready),
        .m_axi_bid     (s_axi_dtcm.bid),
        .m_axi_bresp   (s_axi_dtcm.bresp)
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
