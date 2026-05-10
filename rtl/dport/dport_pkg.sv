package dport_pkg;


    //    class dport_config;
    //        string        name;
    //        bit    [31:0] addr;
    //        bit    [31:0] size;
    //        bit    [31:0] width;
    //        bit    [31:0] mask;
    //
    //        function new(string name, bit [31:0] a = 0, bit [31:0] s = 0);
    //            this.name  = name;
    //            this.addr  = a;
    //            this.size  = s;
    //            this.width = $clog2(s);
    //            this.mask  = ~(s - 1);
    //        endfunction
    //
    //        function void display();
    //            $display("%8s: Addr: %08H, Size: %08H, Mask: %08H, Width: %0d", this.name, this.addr, this.size, this.mask,
    //                     this.width);
    //        endfunction
    //    endclass
    //    class addrspace_config #(
    //        int N_SEMGENTS = 5
    //    );
    //        dport_config                     segments   [N_SEMGENTS];
    //        bit          [N_SEMGENTS*32-1:0] SLAVE_ADDR;
    //        bit          [N_SEMGENTS*32-1:0] SLAVE_MASK;
    //        function new(dport_config segments[N_SEMGENTS]);
    //            this.segments = segments;
    //            foreach (this.segments[i]) begin
    //                this.SLAVE_ADDR[i*32+:32] = this.segments[i].addr;
    //                this.SLAVE_MASK[i*32+:32] = this.segments[i].mask;
    //            end
    //        endfunction
    //        function void display();
    //            $display("%d", this.N_SEMGENTS);
    //            foreach (this.segments[i]) begin
    //                segments[i].display();
    //            end
    //        endfunction
    //    endclass
    //    dport_config local_cfg = new("local", 32'h0000_0000, 32'h0000_1000);
    //    dport_config dtcm_cfg = new("dtcm", 32'h8002_0000, 32'h0002_0000);
    //    dport_config cached_cfg = new("cached", 32'h9000_0000, 32'h0002_0000);
    //    dport_config uncached_cfg = new("uncached", 32'hA000_0000, 32'h0002_0000);
    //    dport_config axil_cfg = new("axil", 32'hB000_0000, 32'h0002_0000);
    //    dport_config segments[5] = {local_cfg, dtcm_cfg, cached_cfg, uncached_cfg, axil_cfg};
    //    addrspace_config addr_cfg = new(segments);

    localparam int N_SEGMENTS = 5;
    localparam bit [31:0] LOCAL_ADDR = 32'h0000_0000;
    localparam bit [31:0] LOCAL_SIZE = 32'h0001_0000;
    localparam bit [31:0] LOCAL_WIDTH = $clog2(LOCAL_SIZE);
    localparam bit [31:0] LOCAL_MASK = ~(LOCAL_SIZE - 1);
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

    typedef struct packed {
        bit [31:0] ADDR;
        bit [31:0] SIZE;
        bit [31:0] WIDTH;
        bit [31:0] MASK;
    } segcfg_t;

    localparam segcfg_t LOCAL_CFG = '{
    ADDR: LOCAL_ADDR,
    SIZE: LOCAL_SIZE,
    WIDTH: $clog2(LOCAL_SIZE),
    MASK: ~(LOCAL_SIZE - 1)
    };
    localparam segcfg_t DTCM_CFG = '{
    ADDR: DTCM_ADDR,
    SIZE: DTCM_SIZE,
    WIDTH: $clog2(DTCM_SIZE),
    MASK: ~(DTCM_SIZE - 1)
    };
    localparam segcfg_t CACHED_CFG = '{
    ADDR: CACHED_ADDR,
    SIZE: CACHED_SIZE,
    WIDTH: $clog2(CACHED_SIZE),
    MASK: ~(CACHED_SIZE - 1)
    };
    localparam segcfg_t UNCACHED_CFG = '{
    ADDR: UNCACHED_ADDR,
    SIZE: UNCACHED_SIZE,
    WIDTH: $clog2(UNCACHED_SIZE),
    MASK: ~(UNCACHED_SIZE - 1)
    };
    localparam segcfg_t AXIL_CFG = '{
    ADDR: AXIL_ADDR,
    SIZE: AXIL_SIZE,
    WIDTH: $clog2(AXIL_SIZE),
    MASK: ~(AXIL_SIZE - 1)
    };

    localparam segcfg_t _SEGMENTS[N_SEGMENTS] = {
        LOCAL_CFG,
        DTCM_CFG,
        CACHED_CFG,
        UNCACHED_CFG,
        AXIL_CFG
    };

    localparam bit [N_SEGMENTS*32-1:0] SLAVE_ADDR = {
        AXIL_CFG.ADDR, UNCACHED_CFG.ADDR, CACHED_CFG.ADDR, DTCM_CFG.ADDR, LOCAL_CFG.ADDR
    };
    localparam bit [N_SEGMENTS*32-1:0] SLAVE_MASK = {
        AXIL_CFG.MASK, UNCACHED_CFG.MASK, CACHED_CFG.MASK, DTCM_CFG.MASK, LOCAL_CFG.MASK
    };


endpackage : dport_pkg
