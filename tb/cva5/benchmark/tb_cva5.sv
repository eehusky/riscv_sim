module tb_cva5 (
    input logic i_clk,
    input logic i_rst
);
    import cva5_config::*;
    import cva5_types::*;

    logic clk_i;
    logic rst_i;
    assign clk_i = i_clk;
    assign rst_i = i_rst;

    //CPU connections
    local_memory_interface data_bram();
    local_memory_interface instruction_bram();
    axi_interface m_axi();
    avalon_interface m_avalon(); //Unused
    wishbone_interface dwishbone(); //Unused
    wishbone_interface iwishbone(); //Unused
    mem_interface mem();
    logic[63:0] mtime;
    interrupt_t s_interrupt; //Unused
    interrupt_t m_interrupt; //Unused

    ////////////////////////////////////////////////////
    //Implementation
    //Instantiates a CVA5 processor using local memory
    //Program start address 0x8000_0000
    //Local memory space from 0x8000_0000 through 0x80FF_FFFF
    //Peripheral bus from 0x6000_0000 through 0x6FFF_FFFF

    localparam wb_group_config_t WB_CPU_CONFIG = '{
        0 : '{0: ALU_ID, default : NON_WRITEBACK_ID},
        1 : '{0: LS_ID, default : NON_WRITEBACK_ID},
        2 : '{0: MUL_ID, 1: DIV_ID, 2: CSR_ID, 3: FPU_ID, 4: CUSTOM_ID, default : NON_WRITEBACK_ID},
        default : '{default : NON_WRITEBACK_ID}
    };

    localparam cpu_config_t CPU_CONFIG = '{
        //ISA options
        MODES : M,
        INCLUDE_UNIT : '{
            MUL : 1,
            DIV : 1,
            CSR : 1,
            FPU : 0,
            CUSTOM : 0,
            default: '0
        },
        INCLUDE_IFENCE : 0,
        INCLUDE_AMO : 0,
        INCLUDE_CBO : 0,
        //CSR constants
        CSRS : '{
            MACHINE_IMPLEMENTATION_ID : 0,
            CPU_ID : 0,
            RESET_VEC : 32'h80000000,
            RESET_TVEC : 32'h90000000,
            MCONFIGPTR : '0,
            INCLUDE_ZICNTR : 1,
            INCLUDE_ZIHPM : 0,
            INCLUDE_SSTC : 0,
            INCLUDE_SMSTATEEN : 0
        },
        //Memory Options
        SQ_DEPTH : 4,
        INCLUDE_FORWARDING_TO_STORES : 1,
        AMO_UNIT : '{
            LR_WAIT : 32,
            RESERVATION_WORDS : 8
        },
        INCLUDE_ICACHE : 0,
        ICACHE_ADDR : '{
            L: 32'h80000000,
            H: 32'h8FFFFFFF
        },
        ICACHE : '{
            LINES : 512,
            LINE_W : 4,
            WAYS : 2,
            USE_EXTERNAL_INVALIDATIONS : 0,
            USE_NON_CACHEABLE : 0,
            NON_CACHEABLE : '{
                L: 32'h70000000,
                H: 32'h7FFFFFFF
            }
        },
        ITLB : '{
            WAYS : 2,
            DEPTH : 64
        },
        INCLUDE_DCACHE : 0,
        DCACHE_ADDR : '{
            L: 32'h80000000,
            H: 32'h8FFFFFFF
        },
        DCACHE : '{
            LINES : 512,
            LINE_W : 4,
            WAYS : 2,
            USE_EXTERNAL_INVALIDATIONS : 0,
            USE_NON_CACHEABLE : 0,
            NON_CACHEABLE : '{
                L: 32'h70000000,
                H: 32'h7FFFFFFF
            }
        },
        DTLB : '{
            WAYS : 2,
            DEPTH : 64
        },
        INCLUDE_ILOCAL_MEM : 1,
        ILOCAL_MEM_ADDR : '{
            L : 32'h80000000,
            H : 32'h8001FFFF
        },
        INCLUDE_DLOCAL_MEM : 1,
        DLOCAL_MEM_ADDR : '{
            L : 32'h80020000,
            H : 32'h8003FFFF
        },
        INCLUDE_IBUS : 0,
        IBUS_ADDR : '{
            L : 32'h80000000,
            H : 32'h8FFFFFFF
        },
        INCLUDE_PERIPHERAL_BUS : 0,
        PERIPHERAL_BUS_ADDR : '{
            L : 32'h00000000,
            H : 32'h00010000
        },
        PERIPHERAL_BUS_TYPE : AXI_BUS,
        //Branch Predictor Options
        INCLUDE_BRANCH_PREDICTOR : 1,
        BP : '{
            WAYS : 2,
            ENTRIES : 512,
            RAS_ENTRIES : 8
        },
        //Writeback Options
        NUM_WB_GROUPS : 3,
        WB_GROUP : WB_CPU_CONFIG
    };

    cva5 #(
        .CONFIG(CPU_CONFIG)
    ) cpu(
        .clk(i_clk),
        .rst(i_rst),
        .instruction_bram(instruction_bram),
        .data_bram(data_bram),
        .m_axi(m_axi),
        .m_avalon(m_avalon),
        .dwishbone(dwishbone),
        .iwishbone(iwishbone),
        .mem(mem),
        .mtime(mtime),
        .s_interrupt(s_interrupt),
        .m_interrupt(m_interrupt)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst)
            mtime <= '0;
        else
            mtime <= mtime + 1;
    end

    assign s_interrupt = '{default: '0};
    assign m_interrupt = '{default: '0};


    // ------------------------------------------------------------------------

    obi_if instr_dport ();
    assign instr_dport.addr = {instruction_bram.addr,2'b0};
    assign instr_dport.req = instruction_bram.en;
    assign instr_dport.be = instruction_bram.be;
    assign instr_dport.wdata = instruction_bram.data_out;
    assign instruction_bram.data_in = instr_dport.rdata;

    //assign instr_dport.addr = iwishbone.adr;
    //assign instr_dport.req = iwishbone.stb;
    ////assign instr_dport.be = instruction_bram.be;
    ////assign instr_dport.wdata = instruction_bram.data_out;
    //assign iwishbone.dat_r = instr_dport.rdata;
    //assign iwishbone.ack = instr_dport.rvalid;

    //assign instr_gnt_i        = instr_dport.gnt;
    //assign instr_dport.req    = instr_req_o;
    //assign instr_dport.addr   = instr_addr_o;
    //assign instr_dport.we     = 0;
    //assign instr_dport.be     = 0;
    //assign instr_dport.wdata  = 0;
    //assign instr_dport.aid    = 0;
    //assign instr_dport.rready = 1;
    //assign instr_rvalid_i     = instr_dport.rvalid;
    //assign instr_rdata_i      = instr_dport.rdata;
    dport_bram #(
        .ADDR_WIDTH(17)
    ) i_instr_ram (
        .clk_i(i_clk),
        .rst_i(i_rst),
        .dport(instr_dport)
    );

    obi_if data_dport ();
    //assign data_dport.addr = {data_bram.addr,2'b0};
    //assign data_dport.req = data_bram.en;
    //assign data_dport.be = data_bram.be;
    //assign data_dport.wdata = data_bram.data_out;
    //assign data_bram.data_in = data_dport.rdata;

    //assign data_gnt_i        = data_dport.gnt;
    //assign data_dport.req    = data_req_o;
    //assign data_dport.addr   = data_req_o ? data_addr_o : 0;
    //assign data_dport.we     = data_req_o ? data_we_o : 0;
    //assign data_dport.be     = data_req_o ? data_be_o : 0;
    //assign data_dport.wdata  = data_req_o ? data_wdata_o : 0;
    //assign data_dport.aid    = data_req_o ? 0 : 0;
    //assign data_dport.rready = 1;
    //assign data_rvalid_i     = data_dport.rvalid;
    //assign data_rdata_i      = data_dport.rvalid ? data_dport.rdata : 0;
    //data_dport.err;
    //data_dport.rid;

    obi_if segments[dport_pkg::N_SEGMENTS] ();

    dport_mux i_dport_mux (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .cpu     (data_dport),
        .segments(segments)
    );

    // ------------------------------------------------------------------------

    mtime32 i_mtime (
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .dport       (segments[0]),
        .intr_o      (m_interrupt.timer),
        .clear_intr_i(0)
    );

    // ------------------------------------------------------------------------

    sim_ctrl i_sim_ctrl (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(segments[1])
    );

    // ------------------------------------------------------------------------

    axi_if s_axi_dtcm ();
    dport_dtcm #(
        .DATA_WIDTH       (s_axi_dtcm.DATA_WIDTH),
        .ADDR_WIDTH       (dport_pkg::DTCM_WIDTH),
        .STRB_WIDTH       (s_axi_dtcm.STRB_WIDTH),
        .ID_WIDTH         (s_axi_dtcm.ID_WIDTH),
        .B_PIPELINE_OUTPUT(0),
        .B_INTERLEAVE     (0)
    ) i_dport_dtcm (
        .a_clk(clk_i),
        .a_rst(rst_i),
        .dport(segments[2]),
        .s_axi(s_axi_dtcm)
    );

    // ------------------------------------------------------------------------

    function static void write_itcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            //$display("ITCM: %08X: %08X", addr, data);
            case (addr[1:0])
                2'd0: i_instr_ram.mem[addr/4][7:0] = data;
                2'd1: i_instr_ram.mem[addr/4][15:8] = data;
                2'd2: i_instr_ram.mem[addr/4][23:16] = data;
                2'd3: i_instr_ram.mem[addr/4][31:24] = data;
            endcase
        end
    endfunction
    function [7:0] read_itcm;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[1:0])
                2'd0: read_itcm = i_instr_ram.mem[addr/4][7:0];
                2'd1: read_itcm = i_instr_ram.mem[addr/4][15:8];
                2'd2: read_itcm = i_instr_ram.mem[addr/4][23:16];
                2'd3: read_itcm = i_instr_ram.mem[addr/4][31:24];
            endcase
        end
    endfunction

    function static void write_dtcm;  /*verilator public*/
        input [31:0] addr;
        input [7:0] data;
        begin
            //$display("DTCM: %08X: %08X", addr, data);
            case (addr[1:0])
                2'd0: i_dport_dtcm.mem[addr/4][7:0] = data;
                2'd1: i_dport_dtcm.mem[addr/4][15:8] = data;
                2'd2: i_dport_dtcm.mem[addr/4][23:16] = data;
                2'd3: i_dport_dtcm.mem[addr/4][31:24] = data;
            endcase
        end
    endfunction
    function [7:0] read_dtcm;  /*verilator public*/
        input [31:0] addr;
        begin
            case (addr[1:0])
                2'd0: read_dtcm = i_dport_dtcm.mem[addr/4][7:0];
                2'd1: read_dtcm = i_dport_dtcm.mem[addr/4][15:8];
                2'd2: read_dtcm = i_dport_dtcm.mem[addr/4][23:16];
                2'd3: read_dtcm = i_dport_dtcm.mem[addr/4][31:24];
            endcase
        end
    endfunction

//`ifdef VM_TRACE
    initial begin
        $dumpfile("dump.fst");
        $dumpvars(0);
        $dumpon;
    end
//`endif
endmodule : tb_cva5


module dport_bram #(
    parameter int ADDR_WIDTH = 16
) (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave dport
);
    localparam WORD_ADDR_WIDTH = ADDR_WIDTH - $clog2(4);

    logic   [WORD_ADDR_WIDTH-1:0] word_addr;
    logic   [               31:0] mem       [(2**WORD_ADDR_WIDTH)-1];
    integer                       i;

    assign word_addr = dport.addr[ADDR_WIDTH-1:ADDR_WIDTH-WORD_ADDR_WIDTH];

    //generate
    //for (genvar i = 0; i < 4; i = i + 1) begin
    //    if (dport.be[i]) begin
    //        assign mem[word_addr][8*i+:8] = dport.wdata[8*i+:8];
    //    end
    //end
    //endgenerate
    assign dport.rdata  = mem[word_addr];
    assign dport.gnt = 1;
    assign dport.err = 0;
    assign dport.rvalid = dport.req;
    assign dport.rid    = dport.aid;


endmodule : dport_bram
