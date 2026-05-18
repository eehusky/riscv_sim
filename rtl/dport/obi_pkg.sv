package obi_pkg;

    localparam int N_TARGETS = 8;
    //
    localparam bit [31:0] MTIME_ADDR = 32'h0000_2000;
    localparam bit [31:0] MTIME_SIZE = 32'h0000_1000;
    localparam bit [31:0] MTIME_WIDTH = $clog2(MTIME_SIZE);
    localparam bit [31:0] MTIME_MASK = ~(MTIME_SIZE - 1);
    //
    localparam bit [31:0] SIMCTRL_ADDR = 32'h0000_3000;
    localparam bit [31:0] SIMCTRL_SIZE = 32'h0000_1000;
    localparam bit [31:0] SIMCTRL_WIDTH = $clog2(SIMCTRL_SIZE);
    localparam bit [31:0] SIMCTRL_MASK = ~(SIMCTRL_SIZE - 1);
    //
    localparam bit [31:0] ITCM_ADDR = 32'h8000_0000;
    localparam bit [31:0] ITCM_SIZE = 32'h0002_0000;
    localparam bit [31:0] ITCM_WIDTH = $clog2(ITCM_SIZE);
    localparam bit [31:0] ITCM_MASK = ~(ITCM_SIZE - 1);
    //
    localparam bit [31:0] DTCM_ADDR = 32'h8002_0000;
    localparam bit [31:0] DTCM_SIZE = 32'h0002_0000;
    localparam bit [31:0] DTCM_WIDTH = $clog2(DTCM_SIZE);
    localparam bit [31:0] DTCM_MASK = ~(DTCM_SIZE - 1);
    //
    localparam bit [31:0] CACHED_ADDR = 32'h9000_0000;
    localparam bit [31:0] CACHED_SIZE = 32'h0002_0000;
    localparam bit [31:0] CACHED_WIDTH = $clog2(CACHED_SIZE);
    localparam bit [31:0] CACHED_MASK = ~(CACHED_SIZE - 1);
    //
    localparam bit [31:0] UNCACHED_ADDR = 32'hA000_0000;
    localparam bit [31:0] UNCACHED_SIZE = 32'h0002_0000;
    localparam bit [31:0] UNCACHED_WIDTH = $clog2(UNCACHED_SIZE);
    localparam bit [31:0] UNCACHED_MASK = ~(UNCACHED_SIZE - 1);
    //
    localparam bit [31:0] AXIL_ADDR = 32'hB000_0000;
    localparam bit [31:0] AXIL_SIZE = 32'h0002_0000;
    localparam bit [31:0] AXIL_WIDTH = $clog2(AXIL_SIZE);
    localparam bit [31:0] AXIL_MASK = ~(AXIL_SIZE - 1);
    //
    localparam bit [31:0] DEBUG_ADDR = 32'hC000_0000;
    localparam bit [31:0] DEBUG_SIZE = 32'h0002_0000;
    localparam bit [31:0] DEBUG_WIDTH = $clog2(DEBUG_SIZE);
    localparam bit [31:0] DEBUG_MASK = ~(DEBUG_SIZE - 1);
    //
    //

    localparam ITCM     = 1'b1;
    localparam MTIME    = 1'b1;
    localparam SIMCTRL  = 1'b1;
    localparam DTCM     = 1'b1;
    localparam CACHED   = 1'b1;
    localparam UNCACHED = 1'b1;
    localparam AXIL     = 1'b1;
    localparam DEBUG    = 1'b1;

    localparam int N_INITIATORS = 4;
    localparam bit [N_INITIATORS-1:0][N_TARGETS-1:0] CONNECTIONS = {
        { 1'b0,    1'b0, ITCM, 1'b0,   1'b0,     1'b0, 1'b0, DEBUG}, // instruction fetch
        {MTIME, SIMCTRL, 1'b0, DTCM, CACHED, UNCACHED, AXIL, DEBUG}, // data fetch
        {MTIME, SIMCTRL, ITCM, DTCM, CACHED, UNCACHED, AXIL,  1'b0}, // debug
        {MTIME, SIMCTRL, ITCM, DTCM,   1'b0,     1'b0, 1'b0, DEBUG}  // external
    };


    localparam bit [N_TARGETS*32-1:0] SLAVE_ADDR = {
        DEBUG_ADDR, AXIL_ADDR, UNCACHED_ADDR, CACHED_ADDR, DTCM_ADDR,ITCM_ADDR, SIMCTRL_ADDR, MTIME_ADDR
    };
    localparam bit [N_TARGETS*32-1:0] SLAVE_MASK = {
        DEBUG_MASK, AXIL_MASK, UNCACHED_MASK, CACHED_MASK, DTCM_MASK,ITCM_MASK, SIMCTRL_MASK, MTIME_MASK
    };


endpackage : obi_pkg
