
module mem2axil_glue #(
    parameter int ADDR_WIDTH      = 32,
    parameter int AXIL_DATA_WIDTH = 32,
    parameter int AXIL_STRB_WIDTH = 4
) (
    input  logic                       clk_i,
    input  logic                       rst_i,
    //
    input  logic [               31:0] mem_addr_i,
    input  logic [               31:0] mem_data_wr_i,
    input  logic                       mem_rd_i,
    input  logic [                3:0] mem_wr_i,
    output logic [               31:0] mem_data_rd_o,
    output logic                       mem_accept_o,
    output logic                       mem_error_o,
    output logic                       mem_ack_o,
    //
    output logic [     ADDR_WIDTH-1:0] araddr,
    output logic [                2:0] arprot,
    input  logic                       arready,
    output logic                       arvalid,
    output logic [     ADDR_WIDTH-1:0] awaddr,
    output logic [                2:0] awprot,
    input  logic                       awready,
    output logic                       awvalid,
    output logic                       bready,
    input  logic [                1:0] bresp,
    input  logic                       bvalid,
    input  logic [AXIL_DATA_WIDTH-1:0] rdata,
    output logic                       rready,
    input  logic [                1:0] rresp,
    input  logic                       rvalid,
    output logic [AXIL_DATA_WIDTH-1:0] wdata,
    input  logic                       wready,
    output logic [AXIL_STRB_WIDTH-1:0] wstrb,
    output logic                       wvalid
);


endmodule : mem2axil_glue
