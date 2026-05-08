`include "config.vh"

import cvw::*;

module tb_wally (
    input logic i_clk,
    input logic i_rst
);

    `include "parameter-defs.vh"

    // input
    logic                 clk;
    logic                 reset;
    logic                 MTimerInt;
    logic                 MExtInt;
    logic                 SExtInt;
    logic                 MSwInt;
    logic [         63:0] MTIME_CLINT;
    logic [   P.AHBW-1:0] HRDATA;
    logic                 HREADY;
    logic                 ExternalStall;
    // output
    logic                 HRESP;
    logic                 HCLK;
    logic                 HRESETn;
    logic [P.PA_BITS-1:0] HADDR;
    logic [   P.AHBW-1:0] HWDATA;
    logic [ P.XLEN/8-1:0] HWSTRB;
    logic                 HWRITE;
    logic [          2:0] HSIZE;
    logic [          2:0] HBURST;
    logic [          3:0] HPROT;
    logic [          1:0] HTRANS;
    logic                 HMASTLOCK;

    logic [   P.AHBW-1:0] HRDATAEXT;
    logic HREADYEXT, HRESPEXT;
    //logic [P.AHBW-1:0]    HRDATA;
    //logic                 HREADY, HRESP;
    logic        HSELEXT;

    //logic                 MTimerInt;         // Timer and software interrupts from CLINT
    //logic                 MSwInt;         // Timer and software interrupts from CLINT
    //logic                 MExtInt;          // External interrupts from PLIC
    //logic                 SExtInt;          // External interrupts from PLIC
    //logic [63:0]          MTIME_CLINT;               // MTIME, from CLINT
    logic [31:0] GPIOIN;  // GPIO pin input value
    logic [31:0] GPIOOUT;  // GPIO pin output value and enable
    logic [31:0] GPIOEN;  // GPIO pin output value and enable
    logic        UARTSin;  // UART serial input
    logic        UARTSout;  // UART serial output
    logic        SPIIn;
    logic        SPIOut;
    logic [ 3:0] SPICS;
    logic        SPICLK;
    logic        TIMECLK;
    logic        SDCIn;
    logic        SDCCmd;
    logic [ 3:0] SDCCS;
    logic        SDCCLK;


    assign clk           = i_clk;
    assign TIMECLK       = i_clk;
    assign reset         = i_rst;
    assign MTimerInt     = 0;
    assign MExtInt       = 0;
    assign SExtInt       = 0;
    assign MSwInt        = 0;
    //assign MTIME_CLINT = 0;
    //assign HRDATA = 0;
    //assign HREADY = 1;
    assign ExternalStall = 0;

    //always_ff @(posedge i_clk) begin : proc_
    //    if (i_rst) begin
    //        MTIME_CLINT <= 0;
    //    end else begin
    //        MTIME_CLINT <= MTIME_CLINT + 1;
    //    end
    //end

    wallypipelinedcore #(
        .P(P)
    ) i_wallypipelinedcore (
        .clk          (clk),
        .reset        (reset),
        .MTimerInt    (MTimerInt),
        .MExtInt      (MExtInt),
        .SExtInt      (SExtInt),
        .MSwInt       (MSwInt),
        .MTIME_CLINT  (MTIME_CLINT),
        .HRDATA       (HRDATA),
        .HREADY       (HREADY),
        .HRESP        (HRESP),
        .HCLK         (HCLK),
        .HRESETn      (HRESETn),
        .HADDR        (HADDR),
        .HWDATA       (HWDATA),
        .HWSTRB       (HWSTRB),
        .HWRITE       (HWRITE),
        .HSIZE        (HSIZE),
        .HBURST       (HBURST),
        .HPROT        (HPROT),
        .HTRANS       (HTRANS),
        .HMASTLOCK    (HMASTLOCK),
        .ExternalStall(ExternalStall)
    );

    uncore #(P) i_uncore (
        .HCLK,
        .HRESETn,
        .TIMECLK,
        .HADDR,
        .HWDATA,
        .HWSTRB,
        .HWRITE,
        .HSIZE,
        .HBURST,
        .HPROT,
        .HTRANS,
        .HMASTLOCK,
        .HRDATAEXT,
        .HREADYEXT,
        .HRESPEXT,
        .HRDATA,
        .HREADY,
        .HRESP,
        .HSELEXT,
        .MTimerInt,
        .MSwInt,
        .MExtInt,
        .SExtInt,
        .GPIOIN,
        .GPIOOUT,
        .GPIOEN,
        .UARTSin,
        .UARTSout,
        .MTIME_CLINT,
        .SPIIn,
        .SPIOut,
        .SPICS,
        .SPICLK,
        .SDCIn,
        .SDCCmd,
        .SDCCS,
        .SDCCLK
    );

    /*
    //logic                 HSELRam;
    //logic [P.PA_BITS-1:0] HADDR;
    //logic                 HWRITE;
    //logic                 HREADY;
    //logic [1:0]           HTRANS;
    //logic [P.XLEN-1:0]    HWDATA;
    //logic [P.XLEN/8-1:0]  HWSTRB;
    logic [P.XLEN-1:0]    HREADRam;
    //logic                 HRESPRam;
    //logic                 HREADYRam;

    assign HSELRam = 1;

    //logic [11:0]                 HSELRegions;
  logic [11:0]                 HSELRegions;
  logic                        HSELDTIM, HSELIROM, HSELRam, HSELCLINT, HSELPLIC, HSELGPIO, HSELUART,HSELSDC, HSELSPI;
  logic                        HSELDTIMD, HSELIROMD, HSELEXTD, HSELRamD, HSELCLINTD, HSELPLICD, HSELGPIOD, HSELUARTD, HSELSDCD, HSELSPID;
  logic                        HRESPRam,  HRESPSDC;
  logic                        HREADYRam, HRESPSDCD;
  logic [P.XLEN-1:0]           HREADBootRom;
  logic                        HSELBootRom, HSELBootRomD, HRESPBootRom, HREADYBootRom, HREADYSDC;
  logic                        HSELNoneD;
  logic                        UARTIntr,GPIOIntr, SPIIntr;
  logic                        SDCIntM;
  logic                        HSELEXT;


    assign {HSELSPI, HSELSDC, HSELPLIC, HSELUART, HSELGPIO, HSELCLINT, HSELRam, HSELBootRom, HSELEXT, HSELIROM, HSELDTIM} = HSELRegions[11:1];

    adrdecs #(P) adrdecs(HADDR, 1'b1, 1'b1, 1'b1, HSIZE[1:0], HSELRegions);
    ram_ahb #(
        .P(P),
        .RANGE(65535)
    )i_ram_ahb (
      .HCLK(HCLK),
      .HRESETn(HRESETn),
      .HSELRam(HSELRam),
      .HADDR(HADDR),
      .HWRITE(HWRITE),
      .HREADY(HREADY),
      .HTRANS(HTRANS),
      .HWDATA(HWDATA),
      .HWSTRB(HWSTRB),
      //
      .HREADRam(HREADRam),
      .HRESPRam(HRESPRam),
      .HREADYRam(HREADYRam)
    );
    */

`ifdef verilator
    //-------------------------------------------------------------
    // write: Write byte into memory
    //-------------------------------------------------------------
    function write;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            case (addr[2:0])
                3'd0: i_uncore.ram.ram.memory.ram.RAM[addr/8][7:0] = data;
                3'd1: i_uncore.ram.ram.memory.ram.RAM[addr/8][15:8] = data;
                3'd2: i_uncore.ram.ram.memory.ram.RAM[addr/8][23:16] = data;
                3'd3: i_uncore.ram.ram.memory.ram.RAM[addr/8][31:24] = data;
                3'd4: i_uncore.ram.ram.memory.ram.RAM[addr/8][39:32] = data;
                3'd5: i_uncore.ram.ram.memory.ram.RAM[addr/8][47:40] = data;
                3'd6: i_uncore.ram.ram.memory.ram.RAM[addr/8][55:48] = data;
                3'd7: i_uncore.ram.ram.memory.ram.RAM[addr/8][63:56] = data;
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
                2'd0: read = i_uncore.ram.ram.memory.ram.RAM[addr/4][7:0];
                2'd1: read = i_uncore.ram.ram.memory.ram.RAM[addr/4][15:8];
                2'd2: read = i_uncore.ram.ram.memory.ram.RAM[addr/4][23:16];
                2'd3: read = i_uncore.ram.ram.memory.ram.RAM[addr/4][31:24];
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

endmodule : tb_wally
