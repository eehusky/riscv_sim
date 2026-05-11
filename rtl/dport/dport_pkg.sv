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
    //
    localparam bit [31:0] ITCM_ADDR = 32'h8000_0000;
    localparam bit [31:0] ITCM_SIZE = 32'h0002_0000;
    localparam bit [31:0] ITCM_WIDTH = $clog2(ITCM_SIZE);
    localparam bit [31:0] ITCM_MASK = ~(ITCM_SIZE - 1);

    localparam int N_SEGMENTS = 6;
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
    localparam bit [N_SEGMENTS*32-1:0] SLAVE_ADDR = {
        AXIL_ADDR, UNCACHED_ADDR, CACHED_ADDR, DTCM_ADDR, SIMCTRL_ADDR, MTIME_ADDR
    };
    localparam bit [N_SEGMENTS*32-1:0] SLAVE_MASK = {
        AXIL_MASK, UNCACHED_MASK, CACHED_MASK, DTCM_MASK, SIMCTRL_MASK, MTIME_MASK
    };


endpackage : dport_pkg
