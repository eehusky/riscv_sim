module mem_dport_mux (
    input logic clk_i,
    input logic rst_i,

    dport_if.slave  cpu,
    dport_if.master periph,
    dport_if.master dtcm,
    dport_if.master cached,
    dport_if.master uncached,
    dport_if.master axil
);
    localparam int NS = 5;

    dport_if dummy ();

    typedef struct packed {
        logic [31:0] data_wr;
        logic        rd;
        logic [3:0]  wr;
    } mem_data_t;

    mem_data_t        decode_data;
    logic             decode_stall;
    logic             decode_valid;
    logic             decode_stall_o;
    logic      [31:0] decode_addr;
    logic      [NS:0] req_grant;


    addrdecode #(
        .NS            (NS),
        .AW            (32),
        .DW            ($size(mem_data_t)),
        .SLAVE_ADDR    ({32'hB000_0000, 32'hA000_0000, 32'h9000_0000, 32'h8002_0000, 32'h0000_0000}),
        .SLAVE_MASK    ({32'hFFFE_0000, 32'hFFFE_0000, 32'hFFFE_0000, 32'hFFFE_0000, 32'hFFFF_0000}),
        .ACCESS_ALLOWED(-1),
        .OPT_REGISTERED(0),
        .OPT_LOWPOWER  (1)
    ) i_addrdecode (
        .i_clk   (clk_i),
        .i_reset (rst_i),
        //
        .i_valid (cpu.rd || |cpu.wr),
        .o_stall (cpu.accept),
        .i_addr  (cpu.addr),
        .i_data  ({cpu.data_wr, cpu.rd, cpu.wr}),
        //
        .o_valid (decode_valid),
        .i_stall (decode_stall),
        .o_addr  (decode_addr),
        .o_data  (decode_data),
        //
        .o_decode(req_grant)
    );

    always_comb begin : proc_decode
        periph.addr      = 0;
        periph.data_wr   = 0;
        periph.rd        = 0;
        periph.wr        = 0;
        dtcm.addr        = 0;
        dtcm.data_wr     = 0;
        dtcm.rd          = 0;
        dtcm.wr          = 0;
        cached.addr      = 0;
        cached.data_wr   = 0;
        cached.rd        = 0;
        cached.wr        = 0;
        uncached.addr    = 0;
        uncached.data_wr = 0;
        uncached.rd      = 0;
        uncached.wr      = 0;
        axil.addr        = 0;
        axil.data_wr     = 0;
        axil.rd          = 0;
        axil.wr          = 0;
        dummy.addr       = 0;
        dummy.data_wr    = 0;
        dummy.rd         = 0;
        dummy.wr         = 0;
        decode_stall     = 0;
        case (req_grant)
            6'b000001: begin
                periph.addr    = decode_addr;
                periph.data_wr = decode_data.data_wr;
                periph.rd      = decode_data.rd;
                periph.wr      = decode_data.wr;
                decode_stall   = periph.accept;
            end
            6'b000010: begin
                dtcm.addr    = decode_addr;
                dtcm.data_wr = decode_data.data_wr;
                dtcm.rd      = decode_data.rd;
                dtcm.wr      = decode_data.wr;
                decode_stall = dtcm.accept;
            end
            6'b000100: begin
                cached.addr    = decode_addr;
                cached.data_wr = decode_data.data_wr;
                cached.rd      = decode_data.rd;
                cached.wr      = decode_data.wr;
                decode_stall   = cached.accept;
            end
            6'b001000: begin
                uncached.addr    = decode_addr;
                uncached.data_wr = decode_data.data_wr;
                uncached.rd      = decode_data.rd;
                uncached.wr      = decode_data.wr;
                decode_stall     = uncached.accept;
            end
            6'b010000: begin
                axil.addr    = decode_addr;
                axil.data_wr = decode_data.data_wr;
                axil.rd      = decode_data.rd;
                axil.wr      = decode_data.wr;
                decode_stall = axil.accept;
            end
            6'b100000: begin
                dummy.addr    = decode_addr;
                dummy.data_wr = decode_data.data_wr;
                dummy.rd      = decode_data.rd;
                dummy.wr      = decode_data.wr;
                decode_stall  = dummy.accept;
            end
            default: begin
                periph.addr      = 0;
                periph.data_wr   = 0;
                periph.rd        = 0;
                periph.wr        = 0;
                dtcm.addr        = 0;
                dtcm.data_wr     = 0;
                dtcm.rd          = 0;
                dtcm.wr          = 0;
                cached.addr      = 0;
                cached.data_wr   = 0;
                cached.rd        = 0;
                cached.wr        = 0;
                uncached.addr    = 0;
                uncached.data_wr = 0;
                uncached.rd      = 0;
                uncached.wr      = 0;
                axil.addr        = 0;
                axil.data_wr     = 0;
                axil.rd          = 0;
                axil.wr          = 0;
                dummy.addr       = 0;
                dummy.data_wr    = 0;
                dummy.rd         = 0;
                dummy.wr         = 0;
                decode_stall     = 0;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin : proc_dummy
        dummy.accept  <= 1;
        dummy.error   <= 1;
        dummy.data_rd <= 0;
        if (dummy.rd || |dummy.wr) begin
            dummy.ack <= 1;
        end else begin
            dummy.ack <= 0;
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

    assign rsp_ready = {dummy.ack, axil_rsp.ack, uncached_rsp.ack, cached_rsp.ack, dtcm_rsp.ack, periph_rsp.ack};
    assign rsp_grant = rsp_data_out.decode;
    assign rsp_ack   = rsp_ready & rsp_grant;

    always_comb begin : proc_ack
        case (rsp_ack)
            6'b000001: begin
                cpu.ack     = periph_rsp.ack;
                cpu.data_rd = periph_rsp.data_rd;
                cpu.error   = periph_rsp.error;
            end
            6'b000010: begin
                cpu.ack     = dtcm_rsp.ack;
                cpu.data_rd = dtcm_rsp.data_rd;
                cpu.error   = dtcm_rsp.error;
            end
            6'b000100: begin
                cpu.ack     = cached_rsp.ack;
                cpu.data_rd = cached_rsp.data_rd;
                cpu.error   = cached_rsp.error;
            end
            6'b001000: begin
                cpu.ack     = uncached_rsp.ack;
                cpu.data_rd = uncached_rsp.data_rd;
                cpu.error   = uncached_rsp.error;
            end
            6'b010000: begin
                cpu.ack     = axil_rsp.ack;
                cpu.data_rd = axil_rsp.data_rd;
                cpu.error   = axil_rsp.error;
            end
            6'b100000: begin
                cpu.ack     = dummy.ack;
                cpu.data_rd = dummy.data_rd;
                cpu.error   = dummy.error;
            end
            default: begin
                cpu.ack     = 0;
                cpu.data_rd = 0;
                cpu.error   = 0;
            end
        endcase
    end

    dport_if periph_rsp ();
    dport_if dtcm_rsp ();
    dport_if cached_rsp ();
    dport_if uncached_rsp ();
    dport_if axil_rsp ();

    mem_rsp_queue i_mem_rsp_periph (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .pop_i    (rsp_ack[0]),
        .ack_i    (periph.ack),
        .data_rd_i(periph.data_rd),
        .error_i  (periph.error),
        .ack_o    (periph_rsp.ack),
        .data_rd_o(periph_rsp.data_rd),
        .error_o  (periph_rsp.error)
    );
    mem_rsp_queue i_mem_rsp_dtcm (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .pop_i    (rsp_ack[1]),
        .ack_i    (dtcm.ack),
        .data_rd_i(dtcm.data_rd),
        .error_i  (dtcm.error),
        .ack_o    (dtcm_rsp.ack),
        .data_rd_o(dtcm_rsp.data_rd),
        .error_o  (dtcm_rsp.error)
    );
    mem_rsp_queue i_mem_rsp_cached (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .pop_i    (rsp_ack[2]),
        .ack_i    (cached.ack),
        .data_rd_i(cached.data_rd),
        .error_i  (cached.error),
        .ack_o    (cached_rsp.ack),
        .data_rd_o(cached_rsp.data_rd),
        .error_o  (cached_rsp.error)
    );
    mem_rsp_queue i_mem_rsp_uncached (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .pop_i    (rsp_ack[3]),
        .ack_i    (uncached.ack),
        .data_rd_i(uncached.data_rd),
        .error_i  (uncached.error),
        .ack_o    (uncached_rsp.ack),
        .data_rd_o(uncached_rsp.data_rd),
        .error_o  (uncached_rsp.error)
    );
    mem_rsp_queue i_mem_rsp_axil (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .pop_i    (rsp_ack[4]),
        .ack_i    (axil.ack),
        .data_rd_i(axil.data_rd),
        .error_i  (axil.error),
        .ack_o    (axil_rsp.ack),
        .data_rd_o(axil_rsp.data_rd),
        .error_o  (axil_rsp.error)
    );

    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(rsp_push && rsp_full));
        assert (~(rsp_pop && rsp_empty));
        assert ((decode_valid && |req_grant) || ~decode_valid);
    end

endmodule : mem_dport_mux


module mem_rsp_queue #(
    parameter int LGDEPTH = 3
) (
    input  logic        clk_i,
    input  logic        rst_i,
    //
    input  logic        ack_i,
    input  logic [31:0] data_rd_i,
    input  logic        error_i,
    //
    input  logic        pop_i,
    //
    output logic        ack_o,
    output logic [31:0] data_rd_o,
    output logic        error_o
);

    typedef struct packed {
        logic        ack;
        logic [31:0] data_rd;
        logic        error;
    } rsp_data_t;

    rsp_data_t             rsp_data_out;
    logic      [LGDEPTH:0] rsp_fill;
    logic                  rsp_empty;
    logic                  rsp_full;
    logic                  rsp_push;
    logic                  rsp_pop;

    assign rsp_push = ack_i;
    assign rsp_pop  = pop_i && ~rsp_empty;

    ringbuffer_sfifo #(
        .BW               ($size(rsp_data_t)),
        .LGFLEN           (LGDEPTH),
        .OPT_ASYNC_READ   (1),
        .OPT_WRITE_ON_FULL(0),
        .OPT_READ_ON_EMPTY(1)
    ) i_rsp_fifo (
        .i_clk  (clk_i),
        .i_reset(rst_i),
        .i_data ({ack_i, data_rd_i, error_i}),
        .i_wr   (rsp_push),
        .i_rd   (rsp_pop),
        .o_full (rsp_full),
        .o_fill (rsp_fill),
        .o_data (rsp_data_out),
        .o_empty(rsp_empty)
    );

    assign ack_o     = rsp_data_out.ack && ~rsp_empty;
    assign data_rd_o = rsp_data_out.data_rd;
    assign error_o   = rsp_data_out.error;

    always_ff @(posedge clk_i) begin : proc_assert
        assert (~(rsp_push && rsp_full));
        assert (~(rsp_pop && rsp_empty));
    end


endmodule : mem_rsp_queue

