module mem_dport_mux #(

) (
    input  logic        i_reset,
    input  logic        i_clk,
    //
    output logic        mem_accept_o,
    output logic        mem_ack_o,
    input  logic [31:0] mem_addr_i,
    output logic [31:0] mem_data_rd_o,
    input  logic [31:0] mem_data_wr_i,
    output logic        mem_error_o,
    input  logic        mem_rd_i,
    input  logic [ 3:0] mem_wr_i,
    //
    input  logic        periph_accept_i,
    input  logic        periph_ack_i,
    output logic [31:0] periph_addr_o,
    input  logic [31:0] periph_data_rd_i,
    output logic [31:0] periph_data_wr_o,
    input  logic        periph_error_i,
    output logic        periph_rd_o,
    output logic [ 3:0] periph_wr_o,
    //
    input  logic        dtcm_accept_i,
    input  logic        dtcm_ack_i,
    output logic [31:0] dtcm_addr_o,
    input  logic [31:0] dtcm_data_rd_i,
    output logic [31:0] dtcm_data_wr_o,
    input  logic        dtcm_error_i,
    output logic        dtcm_rd_o,
    output logic [ 3:0] dtcm_wr_o,
    //
    input  logic        cached_accept_i,
    input  logic        cached_ack_i,
    output logic [31:0] cached_addr_o,
    input  logic [31:0] cached_data_rd_i,
    output logic [31:0] cached_data_wr_o,
    input  logic        cached_error_i,
    output logic        cached_rd_o,
    output logic [ 3:0] cached_wr_o,
    //
    input  logic        uncached_accept_i,
    input  logic        uncached_ack_i,
    output logic [31:0] uncached_addr_o,
    input  logic [31:0] uncached_data_rd_i,
    output logic [31:0] uncached_data_wr_o,
    input  logic        uncached_error_i,
    output logic        uncached_rd_o,
    output logic [ 3:0] uncached_wr_o,
    //
    input  logic        axil_accept_i,
    input  logic        axil_ack_i,
    output logic [31:0] axil_addr_o,
    input  logic [31:0] axil_data_rd_i,
    output logic [31:0] axil_data_wr_o,
    input  logic        axil_error_i,
    output logic        axil_rd_o,
    output logic [ 3:0] axil_wr_o
);

    logic        dummy_accept;
    logic        dummy_ack;
    logic [31:0] dummy_addr;
    logic [31:0] dummy_data_rd;
    logic [31:0] dummy_data_wr;
    logic        dummy_error;
    logic        dummy_rd;
    logic [ 3:0] dummy_wr;

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
    logic      [ 5:0] o_decode;


    addrdecode #(
        .NS            (5),
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
        .i_valid (mem_rd_i || |mem_wr_i),
        .o_stall (mem_accept_o),
        .i_addr  (mem_addr_i),
        .i_data  ({mem_data_wr_i, mem_rd_i, mem_wr_i}),
        //
        .o_valid (decode_valid),
        .i_stall (decode_stall),
        .o_addr  (decode_addr),
        .o_data  (decode_data),
        //
        .o_decode(o_decode)
    );

    always_comb begin : proc_decode
        periph_addr_o      = 0;
        periph_data_wr_o   = 0;
        periph_rd_o        = 0;
        periph_wr_o        = 0;
        dtcm_addr_o        = 0;
        dtcm_data_wr_o     = 0;
        dtcm_rd_o          = 0;
        dtcm_wr_o          = 0;
        cached_addr_o      = 0;
        cached_data_wr_o   = 0;
        cached_rd_o        = 0;
        cached_wr_o        = 0;
        uncached_addr_o    = 0;
        uncached_data_wr_o = 0;
        uncached_rd_o      = 0;
        uncached_wr_o      = 0;
        axil_addr_o        = 0;
        axil_data_wr_o     = 0;
        axil_rd_o          = 0;
        axil_wr_o          = 0;
        dummy_addr         = 0;
        dummy_data_wr      = 0;
        dummy_rd           = 0;
        dummy_wr           = 0;
        decode_stall       = 0;
        case (o_decode)
            6'b000001: begin
                periph_addr_o    = decode_addr;
                periph_data_wr_o = decode_data.data_wr;
                periph_rd_o      = decode_data.rd;
                periph_wr_o      = decode_data.wr;
                decode_stall     = periph_accept_i;
            end
            6'b000010: begin
                dtcm_addr_o    = decode_addr;
                dtcm_data_wr_o = decode_data.data_wr;
                dtcm_rd_o      = decode_data.rd;
                dtcm_wr_o      = decode_data.wr;
                decode_stall   = dtcm_accept_i;
            end
            6'b000100: begin
                cached_addr_o    = decode_addr;
                cached_data_wr_o = decode_data.data_wr;
                cached_rd_o      = decode_data.rd;
                cached_wr_o      = decode_data.wr;
                decode_stall     = cached_accept_i;
            end
            6'b001000: begin
                uncached_addr_o    = decode_addr;
                uncached_data_wr_o = decode_data.data_wr;
                uncached_rd_o      = decode_data.rd;
                uncached_wr_o      = decode_data.wr;
                decode_stall       = uncached_accept_i;
            end
            6'b010000: begin
                axil_addr_o    = decode_addr;
                axil_data_wr_o = decode_data.data_wr;
                axil_rd_o      = decode_data.rd;
                axil_wr_o      = decode_data.wr;
                decode_stall   = axil_accept_i;
            end
            6'b100000: begin
                dummy_addr    = decode_addr;
                dummy_data_wr = decode_data.data_wr;
                dummy_rd      = decode_data.rd;
                dummy_wr      = decode_data.wr;
                decode_stall  = dummy_accept;
            end
            default: begin
                periph_addr_o      = 0;
                periph_data_wr_o   = 0;
                periph_rd_o        = 0;
                periph_wr_o        = 0;
                dtcm_addr_o        = 0;
                dtcm_data_wr_o     = 0;
                dtcm_rd_o          = 0;
                dtcm_wr_o          = 0;
                cached_addr_o      = 0;
                cached_data_wr_o   = 0;
                cached_rd_o        = 0;
                cached_wr_o        = 0;
                uncached_addr_o    = 0;
                uncached_data_wr_o = 0;
                uncached_rd_o      = 0;
                uncached_wr_o      = 0;
                axil_addr_o        = 0;
                axil_data_wr_o     = 0;
                axil_rd_o          = 0;
                axil_wr_o          = 0;
                dummy_addr         = 0;
                dummy_data_wr      = 0;
                dummy_rd           = 0;
                dummy_wr           = 0;
                decode_stall       = 0;
            end
        endcase
    end

    always_ff @(posedge i_clk) begin : proc_
        dummy_accept  <= 1;
        dummy_error   <= 1;
        dummy_data_rd <= 0;
        if (dummy_rd || |dummy_wr) begin
            dummy_ack <= 1;
        end else begin
            dummy_ack <= 0;
        end
    end

    always_comb begin : proc_ack
        case ({
            dummy_ack, axil_ack_i, uncached_ack_i, cached_ack_i, dtcm_ack_i, periph_ack_i
        })
            6'b000001: begin
                mem_data_rd_o = periph_data_rd_i;
                mem_ack_o     = periph_ack_i;
                mem_error_o   = periph_error_i;
            end
            6'b000010: begin
                mem_data_rd_o = dtcm_data_rd_i;
                mem_ack_o     = dtcm_ack_i;
                mem_error_o   = dtcm_error_i;
            end
            6'b000100: begin
                mem_data_rd_o = cached_data_rd_i;
                mem_ack_o     = cached_ack_i;
                mem_error_o   = cached_error_i;
            end
            6'b001000: begin
                mem_data_rd_o = uncached_data_rd_i;
                mem_ack_o     = uncached_ack_i;
                mem_error_o   = uncached_error_i;
            end
            6'b010000: begin
                mem_data_rd_o = axil_data_rd_i;
                mem_ack_o     = axil_ack_i;
                mem_error_o   = axil_error_i;
            end
            6'b100000: begin
                mem_data_rd_o = dummy_data_rd;
                mem_ack_o     = dummy_ack;
                mem_error_o   = dummy_error;
            end
            default: begin
                mem_data_rd_o = 0;
                mem_ack_o     = 0;
                mem_error_o   = 0;
            end
        endcase
    end

endmodule : mem_dport_mux
