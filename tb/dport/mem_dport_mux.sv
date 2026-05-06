module mem_dport_mux #(

) (
    input logic i_reset,
    input logic i_clk,

    mem_if.slave  cpu,
    mem_if.master periph,
    mem_if.master dtcm,
    mem_if.master cached,
    mem_if.master uncached,
    mem_if.master axil
);
    localparam int NS = 5;

    mem_if dummy ();

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
        .i_clk   (i_clk),
        .i_reset (i_reset),
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

    always_ff @(posedge i_clk) begin : proc_dummy
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
        .i_clk  (i_clk),
        .i_reset(i_reset),
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

    assign rsp_ready = {dummy.ack, axil.ack, uncached.ack, cached.ack, dtcm.ack, periph.ack};
    assign rsp_grant = rsp_data_out.decode;
    assign rsp_ack   = rsp_ready & rsp_grant;

    always_comb begin : proc_ack
        case (rsp_ack)
            6'b000001: begin
                cpu.data_rd = periph.data_rd;
                cpu.ack     = periph.ack;
                cpu.error   = periph.error;
            end
            6'b000010: begin
                cpu.data_rd = dtcm.data_rd;
                cpu.ack     = dtcm.ack;
                cpu.error   = dtcm.error;
            end
            6'b000100: begin
                cpu.data_rd = cached.data_rd;
                cpu.ack     = cached.ack;
                cpu.error   = cached.error;
            end
            6'b001000: begin
                cpu.data_rd = uncached.data_rd;
                cpu.ack     = uncached.ack;
                cpu.error   = uncached.error;
            end
            6'b010000: begin
                cpu.data_rd = axil.data_rd;
                cpu.ack     = axil.ack;
                cpu.error   = axil.error;
            end
            6'b100000: begin
                cpu.data_rd = dummy.data_rd;
                cpu.ack     = dummy.ack;
                cpu.error   = dummy.error;
            end
            default: begin
                cpu.data_rd = 0;
                cpu.ack     = 0;
                cpu.error   = 0;
            end
        endcase
    end

    always_ff @(posedge i_clk) begin : proc_assert
        assert (~(rsp_push && rsp_full));
        assert (~(rsp_pop && rsp_empty));
        assert ((decode_valid && |req_grant) || ~decode_valid);
    end

endmodule : mem_dport_mux
