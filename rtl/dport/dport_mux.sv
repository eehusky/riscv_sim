module dport_mux (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave  cpu,
    obi_if.master periph,
    obi_if.master dtcm,
    obi_if.master cached,
    obi_if.master uncached,
    obi_if.master axil
);
    import dport_pkg::*;
    localparam int NS = N_SEGMENTS;

    obi_if dummy ();

    typedef struct packed {
        logic                      we;
        logic [cpu.STRB_WIDTH-1:0] be;
        logic [cpu.DATA_WIDTH-1:0] wdata;
        logic [cpu.ID_WIDTH-1:0]   aid;
    } mem_data_t;

    mem_data_t        decode_data;
    logic             decode_stall;
    logic             decode_valid;
    logic             decode_stall_o;
    logic      [31:0] decode_addr;
    logic      [NS:0] req_grant;

    dport_addrdecode #(
        .AW            (32),
        .DW            ($size(mem_data_t)),
        //.NS            (NS),
        //.SLAVE_ADDR    ({32'hB000_0000, 32'hA000_0000, 32'h9000_0000, 32'h8002_0000, 32'h0000_0000}),
        //.SLAVE_MASK    ({32'hFFFE_0000, 32'hFFFE_0000, 32'hFFFE_0000, 32'hFFFE_0000, 32'hFFFF_0000}),
        .NS(N_SEGMENTS),
        .SLAVE_ADDR(SLAVE_ADDR),
        .SLAVE_MASK(SLAVE_MASK),
        .ACCESS_ALLOWED(-1),
        .OPT_REGISTERED(0),
        .OPT_LOWPOWER  (1)
    ) i_addrdecode (
        .i_clk   (clk_i),
        .i_reset (rst_i),
        //
        .i_valid (cpu.req),
        .o_stall (cpu.gnt),
        .i_addr  (cpu.addr),
        .i_data  ({cpu.we, cpu.be, cpu.wdata, cpu.aid}),
        //
        .o_valid (decode_valid),
        .i_stall (decode_stall),
        .o_addr  (decode_addr),
        .o_data  (decode_data),
        //
        .o_decode(req_grant)
    );

    always_comb begin : proc_decode
        periph.req     = 0;
        periph.addr    = 0;
        periph.we      = 0;
        periph.be      = 0;
        periph.wdata   = 0;
        periph.aid     = 0;
        dtcm.req       = 0;
        dtcm.addr      = 0;
        dtcm.we        = 0;
        dtcm.be        = 0;
        dtcm.wdata     = 0;
        dtcm.aid       = 0;
        cached.req     = 0;
        cached.addr    = 0;
        cached.we      = 0;
        cached.be      = 0;
        cached.wdata   = 0;
        cached.aid     = 0;
        uncached.req   = 0;
        uncached.addr  = 0;
        uncached.we    = 0;
        uncached.be    = 0;
        uncached.wdata = 0;
        uncached.aid   = 0;
        axil.req       = 0;
        axil.addr      = 0;
        axil.we        = 0;
        axil.be        = 0;
        axil.wdata     = 0;
        axil.aid       = 0;
        dummy.req      = 0;
        dummy.addr     = 0;
        dummy.we       = 0;
        dummy.be       = 0;
        dummy.wdata    = 0;
        dummy.aid      = 0;
        decode_stall   = 0;
        case (req_grant)
            6'b000001: begin
                periph.req   = decode_valid;
                periph.addr  = decode_addr;
                periph.we    = decode_data.we;
                periph.be    = decode_data.be;
                periph.wdata = decode_data.wdata;
                periph.aid   = decode_data.aid;
                decode_stall = periph.gnt;
            end
            6'b000010: begin
                dtcm.req     = decode_valid;
                dtcm.addr    = decode_addr;
                dtcm.we      = decode_data.we;
                dtcm.be      = decode_data.be;
                dtcm.wdata   = decode_data.wdata;
                dtcm.aid     = decode_data.aid;
                decode_stall = dtcm.gnt;
            end
            6'b000100: begin
                cached.req   = decode_valid;
                cached.addr  = decode_addr;
                cached.we    = decode_data.we;
                cached.be    = decode_data.be;
                cached.wdata = decode_data.wdata;
                cached.aid   = decode_data.aid;
                decode_stall = cached.gnt;
            end
            6'b001000: begin
                uncached.req   = decode_valid;
                uncached.addr  = decode_addr;
                uncached.we    = decode_data.we;
                uncached.be    = decode_data.be;
                uncached.wdata = decode_data.wdata;
                uncached.aid   = decode_data.aid;
                decode_stall   = uncached.gnt;
            end
            6'b010000: begin
                axil.req     = decode_valid;
                axil.addr    = decode_addr;
                axil.we      = decode_data.we;
                axil.be      = decode_data.be;
                axil.wdata   = decode_data.wdata;
                axil.aid     = decode_data.aid;
                decode_stall = axil.gnt;
            end
            6'b100000: begin
                dummy.req    = decode_valid;
                dummy.addr   = decode_addr;
                dummy.we     = decode_data.we;
                dummy.be     = decode_data.be;
                dummy.wdata  = decode_data.wdata;
                dummy.aid    = decode_data.aid;
                decode_stall = dummy.gnt;
            end
            default: begin
                periph.req     = 0;
                periph.addr    = 0;
                periph.we      = 0;
                periph.be      = 0;
                periph.wdata   = 0;
                periph.aid     = 0;
                dtcm.req       = 0;
                dtcm.addr      = 0;
                dtcm.we        = 0;
                dtcm.be        = 0;
                dtcm.wdata     = 0;
                dtcm.aid       = 0;
                cached.req     = 0;
                cached.addr    = 0;
                cached.we      = 0;
                cached.be      = 0;
                cached.wdata   = 0;
                cached.aid     = 0;
                uncached.req   = 0;
                uncached.addr  = 0;
                uncached.we    = 0;
                uncached.be    = 0;
                uncached.wdata = 0;
                uncached.aid   = 0;
                axil.req       = 0;
                axil.addr      = 0;
                axil.we        = 0;
                axil.be        = 0;
                axil.wdata     = 0;
                axil.aid       = 0;
                dummy.req      = 0;
                dummy.addr     = 0;
                dummy.we       = 0;
                dummy.be       = 0;
                dummy.wdata    = 0;
                dummy.aid      = 0;
                decode_stall   = 0;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin : proc_dummy
        dummy.gnt   <= 1;
        dummy.err   <= 1;
        dummy.rdata <= 0;
        if (dummy.req) begin
            dummy.rvalid <= 1;
        end else begin
            dummy.rvalid <= 0;
        end
    end

    localparam int LGRSP = 3;

    typedef struct packed {logic [NS:0] decode;} rsp_data_t;

    rsp_data_t           rsp_data_out;
    logic      [LGRSP:0] rsp_fill;
    logic                rsp_empty;
    logic                rsp_full;
    logic                rsp_push;
    logic                rsp_pop;

    assign rsp_push = decode_valid && decode_stall;
    assign rsp_pop  = |rsp_ack;

    ringbuffer_sfifo #(
        .BW               ($size(rsp_data_t)),
        .LGFLEN           (LGRSP),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(0)
    ) i_rsp_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({req_grant}),
        .i_wr   (rsp_push),
        .i_rd   (rsp_pop),
        .o_full (rsp_full),
        .o_fill (rsp_fill),
        .o_data (rsp_data_out),
        .o_empty(rsp_empty)
    );

    logic [NS:0] rsp_ready;
    logic [NS:0] rsp_ack;
    logic [NS:0] rsp_grant;
    obi_if periph_rsp ();
    obi_if dtcm_rsp ();
    obi_if cached_rsp ();
    obi_if uncached_rsp ();
    obi_if axil_rsp ();

    assign rsp_ready = {
        dummy.rvalid, axil_rsp.rvalid, uncached_rsp.rvalid, cached_rsp.rvalid, dtcm_rsp.rvalid, periph_rsp.rvalid
    };
    assign rsp_grant = rsp_data_out.decode;
    assign rsp_ack = rsp_ready & rsp_grant;

    assign periph_rsp.rready = rsp_ack[0];
    assign dtcm_rsp.rready = rsp_ack[1];
    assign cached_rsp.rready = rsp_ack[2];
    assign uncached_rsp.rready = rsp_ack[3];
    assign axil_rsp.rready = rsp_ack[4];

    dport_rsp_queue i_dport_rsp_queue_periph (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .in   (periph),
        .out  (periph_rsp)
    );
    dport_rsp_queue i_dport_rsp_queue_dtcm (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .in   (dtcm),
        .out  (dtcm_rsp)
    );
    dport_rsp_queue i_dport_rsp_queue_cached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .in   (cached),
        .out  (cached_rsp)
    );
    dport_rsp_queue i_dport_rsp_queue_uncached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .in   (uncached),
        .out  (uncached_rsp)
    );
    dport_rsp_queue i_dport_rsp_queue_axil (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .in   (axil),
        .out  (axil_rsp)
    );

    always_comb begin : proc_ack
        case (rsp_ack)
            6'b000001: begin
                cpu.rvalid = periph_rsp.rvalid;
                cpu.rdata  = periph_rsp.rdata;
                cpu.err    = periph_rsp.err;
                cpu.rid    = periph_rsp.rid;
            end
            6'b000010: begin
                cpu.rvalid = dtcm_rsp.rvalid;
                cpu.rdata  = dtcm_rsp.rdata;
                cpu.err    = dtcm_rsp.err;
                cpu.rid    = dtcm_rsp.rid;
            end
            6'b000100: begin
                cpu.rvalid = cached_rsp.rvalid;
                cpu.rdata  = cached_rsp.rdata;
                cpu.err    = cached_rsp.err;
                cpu.rid    = cached_rsp.rid;
            end
            6'b001000: begin
                cpu.rvalid = uncached_rsp.rvalid;
                cpu.rdata  = uncached_rsp.rdata;
                cpu.err    = uncached_rsp.err;
                cpu.rid    = uncached_rsp.rid;
            end
            6'b010000: begin
                cpu.rvalid = axil_rsp.rvalid;
                cpu.rdata  = axil_rsp.rdata;
                cpu.err    = axil_rsp.err;
                cpu.rid    = axil_rsp.rid;
            end
            6'b100000: begin
                cpu.rvalid = dummy.rvalid;
                cpu.rdata  = dummy.rdata;
                cpu.err    = dummy.err;
                cpu.rid    = dummy.rid;
            end
            default: begin
                cpu.rvalid = 0;
                cpu.rdata  = 0;
                cpu.err    = 0;
                cpu.rid    = 0;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(rsp_push && rsp_full));
        assert (~(rsp_pop && rsp_empty));
        assert ((decode_valid && |req_grant) || ~decode_valid);
    end

endmodule : dport_mux

