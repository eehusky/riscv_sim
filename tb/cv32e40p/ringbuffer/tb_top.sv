module tb_top #(
    parameter bit [31:0] BOOT_ADDRESS      = 32'h8000_0000,
    parameter int        HART_ID           = 0,
    parameter bit [31:0] MTVEC_ADDR        = 32'h8000_1000,
    parameter bit [31:0] DM_HALT_ADDR      = 32'h1A11_0800,
    parameter bit [31:0] DM_EXCEPTION_ADDR = 32'h00000000,
    parameter bit        COREV_PULP        = 0,
    parameter bit        COREV_CLUSTER     = 0,
    parameter bit        FPU               = 1,
    parameter int        FPU_ADDMUL_LAT    = 0,
    parameter int        FPU_OTHERS_LAT    = 0,
    parameter bit        ZFINX             = 0,
    parameter int        NUM_MHPMCOUNTERS  = 29
) (
    input logic clk_i,
    input logic rst_i
);

    localparam int INITIATOR_ID_WIDTH = 1;
    localparam int TARGET_ID_WIDTH = INITIATOR_ID_WIDTH + $clog2(obi_pkg::N_INITIATORS);

    logic [31:0] irq_i;
    obi_if #(.ID_WIDTH(INITIATOR_ID_WIDTH)) initiators[obi_pkg::N_INITIATORS] ();
    obi_if #(.ID_WIDTH(TARGET_ID_WIDTH)) targets[obi_pkg::N_TARGETS] ();

    cv32e40p_wrapper #(
        .BOOT_ADDRESS     (BOOT_ADDRESS),
        .HART_ID          (HART_ID),
        .MTVEC_ADDR       (MTVEC_ADDR),
        .DM_HALT_ADDR     (DM_HALT_ADDR),
        .DM_EXCEPTION_ADDR(DM_EXCEPTION_ADDR),
        .COREV_PULP       (COREV_PULP),
        .COREV_CLUSTER    (COREV_CLUSTER),
        .FPU              (FPU),
        .FPU_ADDMUL_LAT   (FPU_ADDMUL_LAT),
        .FPU_OTHERS_LAT   (FPU_OTHERS_LAT),
        .ZFINX            (ZFINX),
        .NUM_MHPMCOUNTERS (NUM_MHPMCOUNTERS)
    ) i_cv32e40p_wrapper (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .irq_i      (irq_i),
        .instr_dport(initiators[0]),
        .data_dport (initiators[1])
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



    axi_if m_axi_cached ();
    obi2axi i_dport2axi_cached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(targets[4]),
        .m_axi(m_axi_cached)
    );

    axi_ram #(
        .DATA_WIDTH(m_axi_cached.DATA_WIDTH),
        .ADDR_WIDTH(obi_pkg::CACHED_WIDTH),
        .STRB_WIDTH(m_axi_cached.STRB_WIDTH),
        .ID_WIDTH  (m_axi_cached.ID_WIDTH)
    ) i_axi_cached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_cached.awid),
        .s_axi_awaddr (m_axi_cached.awaddr[obi_pkg::CACHED_WIDTH-1:0]),
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
        .s_axi_araddr (m_axi_cached.araddr[obi_pkg::CACHED_WIDTH-1:0]),
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
    obi2axi i_dport2axi_uncached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(targets[5]),
        .m_axi(m_axi_uncached)
    );

    axi_ram #(
        .DATA_WIDTH(m_axi_uncached.DATA_WIDTH),
        .ADDR_WIDTH(obi_pkg::UNCACHED_WIDTH),
        .STRB_WIDTH(m_axi_uncached.STRB_WIDTH),
        .ID_WIDTH  (m_axi_uncached.ID_WIDTH)
    ) i_axi_uncached_ram (
        .clk          (clk_i),
        .rst          (rst_i),
        .s_axi_awid   (m_axi_uncached.awid),
        .s_axi_awaddr (m_axi_uncached.awaddr[obi_pkg::UNCACHED_WIDTH-1:0]),
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
        .s_axi_araddr (m_axi_uncached.araddr[obi_pkg::UNCACHED_WIDTH-1:0]),
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
    obi2axil i_dport2axil (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .dport (targets[6]),
        .m_axil(m_axil)
    );

    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    // ------------------------------------------------------------------------

    localparam int M_AXI_DATA_WIDTH = 32;
    localparam int M_AXI_ADDR_WIDTH = 32;
    localparam int M_AXI_ID_WIDTH = 4;
    localparam int M00_AXIS_TDATA_WIDTH = 8;
    localparam int M01_AXIS_TDATA_WIDTH = 8;
    localparam int S00_AXIS_TDATA_WIDTH = 8;
    localparam int S01_AXIS_TDATA_WIDTH = 8;
    localparam int S_AXIL_DATA_WIDTH    = ringbuffer_addrmap_pkg::RINGBUFFER_ADDRMAP_MIN_ADDR_WIDTH;

    ringbuffer_axis_if #(.TDATA_WIDTH(M00_AXIS_TDATA_WIDTH)) m00_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(M01_AXIS_TDATA_WIDTH)) m01_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(S00_AXIS_TDATA_WIDTH)) s00_axis ();
    ringbuffer_axis_if #(.TDATA_WIDTH(S01_AXIS_TDATA_WIDTH)) s01_axis ();

    logic [M00_AXIS_TDATA_WIDTH-1:0] x00_counter;
    always_ff @(posedge clk_i) begin : proc_x00
        if(rst_i) begin
             x00_counter <= 0;
        end else begin
            if(m00_axis.tready & m00_axis.tvalid) begin
                assert(m00_axis.tdata == x00_counter);
                x00_counter <= x00_counter + 1;
            end
        end
    end

    logic [M01_AXIS_TDATA_WIDTH-1:0] x01_counter;
    always_ff @(posedge clk_i) begin : proc_x01
        if(rst_i) begin
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
        .i_clk         (clk_i),
        .i_reset       (rst_i),
        //
        .o_interrupt   (irq_i[11]),
        //
        .m00_axis      (m00_axis),
        .m01_axis      (m01_axis),
        .s00_axis      (s00_axis),
        .s01_axis      (s01_axis),
        //
        .s_axil_awaddr (m_axil.awaddr[obi_pkg::AXIL_WIDTH-1:0]),
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
        .s_axil_araddr (m_axil.araddr[obi_pkg::AXIL_WIDTH-1:0]),
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


    biriscv_trace_sim i_biriscv_trace_sim(
        .valid_i(i_cv32e40p_wrapper.i_cv32e40p_top.core_i.instr_valid_id),
        .pc_i(i_cv32e40p_wrapper.i_cv32e40p_top.core_i.pc_if),
        .opcode_i(i_cv32e40p_wrapper.i_cv32e40p_top.core_i.instr_rdata_id)
    );

endmodule : tb_top
