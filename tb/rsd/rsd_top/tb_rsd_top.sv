
`include "SysDeps/XilinxMacros.vh"

import BasicTypes::*;
import CacheSystemTypes::*;
import MemoryTypes::*;
import DebugTypes::*;
import MemoryMapTypes::*;
import IO_UnitTypes::*;

module tb_rsd_top (
    input logic i_clk,
    input logic i_rst
);
    localparam int S_ID_WIDTH = 4;
    localparam int ADDR_WIDTH = 32;
    localparam int DATA_WIDTH = 64;
    localparam int STRB_WIDTH = DATA_WIDTH / 8;
    localparam int AWUSER_WIDTH = 1;
    localparam int WUSER_WIDTH = 1;
    localparam int BUSER_WIDTH = 1;
    localparam int ARUSER_WIDTH = 1;
    localparam int RUSER_WIDTH = 1;
    localparam int AXIL_DATA_WIDTH = 32;
    localparam int AXIL_STRB_WIDTH = AXIL_DATA_WIDTH / 8;

    logic [     S_ID_WIDTH-1:0] s_axi_awid;
    logic [     ADDR_WIDTH-1:0] s_axi_awaddr;
    logic [                7:0] s_axi_awlen;
    logic [                2:0] s_axi_awsize;
    logic [                1:0] s_axi_awburst;
    logic                       s_axi_awlock;
    logic [                3:0] s_axi_awcache;
    logic [                2:0] s_axi_awprot;
    logic [                3:0] s_axi_awqos;
    logic [   AWUSER_WIDTH-1:0] s_axi_awuser;
    logic                       s_axi_awvalid;
    logic                       s_axi_awready;
    logic [     DATA_WIDTH-1:0] s_axi_wdata;
    logic [     STRB_WIDTH-1:0] s_axi_wstrb;
    logic                       s_axi_wlast;
    logic [    WUSER_WIDTH-1:0] s_axi_wuser;
    logic                       s_axi_wvalid;
    logic                       s_axi_wready;
    logic [     S_ID_WIDTH-1:0] s_axi_bid;
    logic [                1:0] s_axi_bresp;
    logic [    BUSER_WIDTH-1:0] s_axi_buser;
    logic                       s_axi_bvalid;
    logic                       s_axi_bready;
    logic [     S_ID_WIDTH-1:0] s_axi_arid;
    logic [     ADDR_WIDTH-1:0] s_axi_araddr;
    logic [                7:0] s_axi_arlen;
    logic [                2:0] s_axi_arsize;
    logic [                1:0] s_axi_arburst;
    logic                       s_axi_arlock;
    logic [                3:0] s_axi_arcache;
    logic [                2:0] s_axi_arprot;
    logic [                3:0] s_axi_arqos;
    logic [   ARUSER_WIDTH-1:0] s_axi_aruser;
    logic                       s_axi_arvalid;
    logic                       s_axi_arready;
    logic [     S_ID_WIDTH-1:0] s_axi_rid;
    logic [     DATA_WIDTH-1:0] s_axi_rdata;
    logic [                1:0] s_axi_rresp;
    logic                       s_axi_rlast;
    logic [    RUSER_WIDTH-1:0] s_axi_ruser;
    logic                       s_axi_rvalid;
    logic                       s_axi_rready;
    logic [     ADDR_WIDTH-1:0] m_axil_awaddr;
    logic [                2:0] m_axil_awprot;
    logic                       m_axil_awvalid;
    logic                       m_axil_awready;
    logic [AXIL_DATA_WIDTH-1:0] m_axil_wdata;
    logic [AXIL_STRB_WIDTH-1:0] m_axil_wstrb;
    logic                       m_axil_wvalid;
    logic                       m_axil_wready;
    logic [                1:0] m_axil_bresp;
    logic                       m_axil_bvalid;
    logic                       m_axil_bready;
    logic [     ADDR_WIDTH-1:0] m_axil_araddr;
    logic [                2:0] m_axil_arprot;
    logic                       m_axil_arvalid;
    logic                       m_axil_arready;
    logic [AXIL_DATA_WIDTH-1:0] m_axil_rdata;
    logic [                1:0] m_axil_rresp;
    logic                       m_axil_rvalid;
    logic                       m_axil_rready;










    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end


    DebugRegister debugRegister;
    Axi4MemoryIF axi4MemoryIF ();

    rsd_wrapper i_rsd_wrapper (
        .i_clk        (i_clk),
        .i_rst        (i_rst),
        .debugRegister(debugRegister),
        .axi4MemoryIF (axi4MemoryIF)
    );

    assign axi4MemoryIF.M_AXI_ACLK = i_clk;
    assign axi4MemoryIF.M_AXI_ARESETN = ~i_rst;
    //initial begin
    //    axi4MemoryIF.M_AXI_AWREADY = 1;
    //    axi4MemoryIF.M_AXI_WREADY = 1;
    //    axi4MemoryIF.M_AXI_BREADY = 1;
    //    axi4MemoryIF.M_AXI_ARREADY = 1;
    //    axi4MemoryIF.M_AXI_RREADY = 1;
    //end


    localparam int RAM_BASE_ADDRESS    = 'h80000000;
    localparam int RAM_ADDR_WIDTH      = 16;
    localparam int PERIPH_BASE_ADDRESS = 'hA0000000;
    localparam int PERIPH_ADDR_WIDTH   = 16;

    rsd_soc_mem #(
        .RAM_BASE_ADDRESS   (RAM_BASE_ADDRESS),
        .RAM_ADDR_WIDTH     (RAM_ADDR_WIDTH),
        .PERIPH_BASE_ADDRESS(PERIPH_BASE_ADDRESS),
        .PERIPH_ADDR_WIDTH  (PERIPH_ADDR_WIDTH)
    ) i_rsd_soc_mem (
        .clk                (i_clk),
        .rst                (i_rst),
        //
        .s_core_axi_awid         (axi4MemoryIF.M_AXI_AWID),
        .s_core_axi_awaddr       (axi4MemoryIF.M_AXI_AWADDR),
        .s_core_axi_awlen        (axi4MemoryIF.M_AXI_AWLEN),
        .s_core_axi_awsize       (axi4MemoryIF.M_AXI_AWSIZE),
        .s_core_axi_awburst      (axi4MemoryIF.M_AXI_AWBURST),
        .s_core_axi_awlock       (axi4MemoryIF.M_AXI_AWLOCK),
        .s_core_axi_awcache      (axi4MemoryIF.M_AXI_AWCACHE),
        .s_core_axi_awprot       (axi4MemoryIF.M_AXI_AWPROT),
        .s_core_axi_awqos        (axi4MemoryIF.M_AXI_AWQOS),
        .s_core_axi_awuser       (axi4MemoryIF.M_AXI_AWUSER),
        .s_core_axi_awvalid      (axi4MemoryIF.M_AXI_AWVALID),
        .s_core_axi_awready      (axi4MemoryIF.M_AXI_AWREADY),
        .s_core_axi_wdata        (axi4MemoryIF.M_AXI_WDATA),
        .s_core_axi_wstrb        (axi4MemoryIF.M_AXI_WSTRB),
        .s_core_axi_wlast        (axi4MemoryIF.M_AXI_WLAST),
        .s_core_axi_wuser        (axi4MemoryIF.M_AXI_WUSER),
        .s_core_axi_wvalid       (axi4MemoryIF.M_AXI_WVALID),
        .s_core_axi_wready       (axi4MemoryIF.M_AXI_WREADY),
        .s_core_axi_bid          (axi4MemoryIF.M_AXI_BID),
        .s_core_axi_bresp        (axi4MemoryIF.M_AXI_BRESP),
        .s_core_axi_buser        (axi4MemoryIF.M_AXI_BUSER),
        .s_core_axi_bvalid       (axi4MemoryIF.M_AXI_BVALID),
        .s_core_axi_bready       (axi4MemoryIF.M_AXI_BREADY),
        .s_core_axi_arid         (axi4MemoryIF.M_AXI_ARID),
        .s_core_axi_araddr       (axi4MemoryIF.M_AXI_ARADDR),
        .s_core_axi_arlen        (axi4MemoryIF.M_AXI_ARLEN),
        .s_core_axi_arsize       (axi4MemoryIF.M_AXI_ARSIZE),
        .s_core_axi_arburst      (axi4MemoryIF.M_AXI_ARBURST),
        .s_core_axi_arlock       (axi4MemoryIF.M_AXI_ARLOCK),
        .s_core_axi_arcache      (axi4MemoryIF.M_AXI_ARCACHE),
        .s_core_axi_arprot       (axi4MemoryIF.M_AXI_ARPROT),
        .s_core_axi_arqos        (axi4MemoryIF.M_AXI_ARQOS),
        .s_core_axi_aruser       (axi4MemoryIF.M_AXI_ARUSER),
        .s_core_axi_arvalid      (axi4MemoryIF.M_AXI_ARVALID),
        .s_core_axi_arready      (axi4MemoryIF.M_AXI_ARREADY),
        .s_core_axi_rid          (axi4MemoryIF.M_AXI_RID),
        .s_core_axi_rdata        (axi4MemoryIF.M_AXI_RDATA),
        .s_core_axi_rresp        (axi4MemoryIF.M_AXI_RRESP),
        .s_core_axi_rlast        (axi4MemoryIF.M_AXI_RLAST),
        .s_core_axi_ruser        (axi4MemoryIF.M_AXI_RUSER),
        .s_core_axi_rvalid       (axi4MemoryIF.M_AXI_RVALID),
        .s_core_axi_rready       (axi4MemoryIF.M_AXI_RREADY),

        .s_axi_awid         (s_axi_awid),
        .s_axi_awaddr       (s_axi_awaddr),
        .s_axi_awlen        (s_axi_awlen),
        .s_axi_awsize       (s_axi_awsize),
        .s_axi_awburst      (s_axi_awburst),
        .s_axi_awlock       (s_axi_awlock),
        .s_axi_awcache      (s_axi_awcache),
        .s_axi_awprot       (s_axi_awprot),
        .s_axi_awqos        (s_axi_awqos),
        .s_axi_awuser       (s_axi_awuser),
        .s_axi_awvalid      (s_axi_awvalid),
        .s_axi_awready      (s_axi_awready),
        .s_axi_wdata        (s_axi_wdata),
        .s_axi_wstrb        (s_axi_wstrb),
        .s_axi_wlast        (s_axi_wlast),
        .s_axi_wuser        (s_axi_wuser),
        .s_axi_wvalid       (s_axi_wvalid),
        .s_axi_wready       (s_axi_wready),
        .s_axi_bid          (s_axi_bid),
        .s_axi_bresp        (s_axi_bresp),
        .s_axi_buser        (s_axi_buser),
        .s_axi_bvalid       (s_axi_bvalid),
        .s_axi_bready       (s_axi_bready),
        .s_axi_arid         (s_axi_arid),
        .s_axi_araddr       (s_axi_araddr),
        .s_axi_arlen        (s_axi_arlen),
        .s_axi_arsize       (s_axi_arsize),
        .s_axi_arburst      (s_axi_arburst),
        .s_axi_arlock       (s_axi_arlock),
        .s_axi_arcache      (s_axi_arcache),
        .s_axi_arprot       (s_axi_arprot),
        .s_axi_arqos        (s_axi_arqos),
        .s_axi_aruser       (s_axi_aruser),
        .s_axi_arvalid      (s_axi_arvalid),
        .s_axi_arready      (s_axi_arready),
        .s_axi_rid          (s_axi_rid),
        .s_axi_rdata        (s_axi_rdata),
        .s_axi_rresp        (s_axi_rresp),
        .s_axi_rlast        (s_axi_rlast),
        .s_axi_ruser        (s_axi_ruser),
        .s_axi_rvalid       (s_axi_rvalid),
        .s_axi_rready       (s_axi_rready),
        .m_axil_awaddr      (m_axil_awaddr),
        .m_axil_awprot      (m_axil_awprot),
        .m_axil_awvalid     (m_axil_awvalid),
        .m_axil_awready     (m_axil_awready),
        .m_axil_wdata       (m_axil_wdata),
        .m_axil_wstrb       (m_axil_wstrb),
        .m_axil_wvalid      (m_axil_wvalid),
        .m_axil_wready      (m_axil_wready),
        .m_axil_bresp       (m_axil_bresp),
        .m_axil_bvalid      (m_axil_bvalid),
        .m_axil_bready      (m_axil_bready),
        .m_axil_araddr      (m_axil_araddr),
        .m_axil_arprot      (m_axil_arprot),
        .m_axil_arvalid     (m_axil_arvalid),
        .m_axil_arready     (m_axil_arready),
        .m_axil_rdata       (m_axil_rdata),
        .m_axil_rresp       (m_axil_rresp),
        .m_axil_rvalid      (m_axil_rvalid),
        .m_axil_rready      (m_axil_rready)
    );

`ifdef verilator
    //-------------------------------------------------------------
    // write: Write byte into memory
    //-------------------------------------------------------------
    function write;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            case (addr[2:0])
                3'd0: i_rsd_soc_mem.i_axi_ram.mem[addr/8][7:0] = data;
                3'd1: i_rsd_soc_mem.i_axi_ram.mem[addr/8][15:8] = data;
                3'd2: i_rsd_soc_mem.i_axi_ram.mem[addr/8][23:16] = data;
                3'd3: i_rsd_soc_mem.i_axi_ram.mem[addr/8][31:24] = data;
                3'd4: i_rsd_soc_mem.i_axi_ram.mem[addr/8][39:32] = data;
                3'd5: i_rsd_soc_mem.i_axi_ram.mem[addr/8][47:40] = data;
                3'd6: i_rsd_soc_mem.i_axi_ram.mem[addr/8][55:48] = data;
                3'd7: i_rsd_soc_mem.i_axi_ram.mem[addr/8][63:56] = data;
            endcase
        end
    endfunction
    //-------------------------------------------------------------
    // read: Read byte from memory
    //-------------------------------------------------------------
    function [7:0] read;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[2:0])
                3'd0: read = i_rsd_soc_mem.i_axi_ram.mem[addr/8][7:0];
                3'd1: read = i_rsd_soc_mem.i_axi_ram.mem[addr/8][15:8];
                3'd2: read = i_rsd_soc_mem.i_axi_ram.mem[addr/8][23:16];
                3'd3: read = i_rsd_soc_mem.i_axi_ram.mem[addr/8][31:24];
                3'd4: read = i_rsd_soc_mem.i_axi_ram.mem[addr/8][39:32];
                3'd5: read = i_rsd_soc_mem.i_axi_ram.mem[addr/8][47:40];
                3'd6: read = i_rsd_soc_mem.i_axi_ram.mem[addr/8][55:48];
                3'd7: read = i_rsd_soc_mem.i_axi_ram.mem[addr/8][63:56];
            endcase
        end
    endfunction
`endif



endmodule : tb_rsd_top
