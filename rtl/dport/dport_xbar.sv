module obi_xbar #(
    parameter int N_INITIATORS,
    parameter int N_TARGETS
    //, parameter bit CONNECT[N_INITIATORS][N_TARGETS]
) (
    input logic clk_i,
    input logic rst_i,

    obi_if.slave  initiators[N_INITIATORS],
    obi_if.master targets   [   N_TARGETS]
);
    localparam int LGNI = $clog2(N_INITIATORS);
    localparam int LGNT = $clog2(N_TARGETS);

    generate
        if (targets.ID_WIDTH != (initiators.ID_WIDTH + LGNI)) begin : g_id_check
            $error("Mismatched ID Width %d %d", targets.ID_WIDTH, initiators.ID_WIDTH + LGNI);
        end
    endgenerate

    `define CONNECT_BUS(intf_master, intf_slave) \
     assign intf_master.gnt    = intf_slave.gnt;      //input  \
     assign intf_slave.req     = intf_master.req;      //output \
     assign intf_slave.addr    = intf_master.addr;     //output \
     assign intf_slave.we      = intf_master.we;       //output \
     assign intf_slave.be      = intf_master.be;       //output \
     assign intf_slave.wdata   = intf_master.wdata;    //output \
     assign intf_slave.aid     = intf_master.aid;      //output \
     assign intf_slave.rready  = intf_master.rready;   //output \
     assign intf_master.rvalid = intf_slave.rvalid;   //input  \
     assign intf_master.rdata  = intf_slave.rdata;    //input  \
     assign intf_master.err    = intf_slave.err;      //input  \
     assign intf_master.rid    = intf_slave.rid;      //input  \

    obi_if #(
        .DATA_WIDTH(initiators.DATA_WIDTH),
        .ADDR_WIDTH(initiators.ADDR_WIDTH),
        .STRB_WIDTH(initiators.STRB_WIDTH),
        .ID_WIDTH  (initiators.ID_WIDTH)
    ) demux_out[N_INITIATORS*N_TARGETS] ();
    obi_if #(
        .DATA_WIDTH(initiators.DATA_WIDTH),
        .ADDR_WIDTH(initiators.ADDR_WIDTH),
        .STRB_WIDTH(initiators.STRB_WIDTH),
        .ID_WIDTH  (initiators.ID_WIDTH)
    ) mux_in[N_INITIATORS*N_TARGETS] ();

    generate
        for (genvar i = 0; i < N_INITIATORS; i++) begin : g_demux
            obi_demux #(
                .N_SEGMENTS(N_TARGETS),
                .SLAVE_ADDR(obi_pkg::SLAVE_ADDR),
                .SLAVE_MASK(obi_pkg::SLAVE_MASK)
            ) i_demux (
                .clk_i   (clk_i),
                .rst_i   (rst_i),
                .cpu     (initiators[i]),
                .segments(demux_out[(i*N_TARGETS)+:N_TARGETS])
            );
        end
    endgenerate

    generate
        for (genvar i = 0; i < N_INITIATORS; i++) begin : g_connect_outer
            for (genvar j = 0; j < N_TARGETS; j++) begin : g_connect_inner
                `CONNECT_BUS(demux_out[(N_TARGETS*i)+j], mux_in[(N_INITIATORS*j)+i]);
            end
        end
    endgenerate

    generate
        for (genvar i = 0; i < N_TARGETS; i++) begin : g_mux
            obi_mux #(
                .N_SEGMENTS(N_INITIATORS)
            ) i_mux_0 (
                .clk_i     (clk_i),
                .rst_i     (rst_i),
                .initiators(mux_in[(i*N_INITIATORS)+:N_INITIATORS]),
                .target    (targets[i])
            );
        end
    endgenerate

    //obi_demux #(
    //    .N_SEGMENTS(N_TARGETS),
    //    .SLAVE_ADDR(obi_pkg::SLAVE_ADDR),
    //    .SLAVE_MASK(obi_pkg::SLAVE_MASK)
    //) i_demux_0 (
    //    .clk_i   (clk_i),
    //    .rst_i   (rst_i),
    //    .cpu     (initiators[0]),
    //    .segments(demux_0_out[(0*N_TARGETS)+:N_TARGETS])
    //);
    //obi_demux #(
    //    .N_SEGMENTS(N_TARGETS),
    //    .SLAVE_ADDR(obi_pkg::SLAVE_ADDR),
    //    .SLAVE_MASK(obi_pkg::SLAVE_MASK)
    //) i_demux_1 (
    //    .clk_i   (clk_i),
    //    .rst_i   (rst_i),
    //    .cpu     (initiators[1]),
    //    .segments(demux_0_out[(1*N_TARGETS)+:N_TARGETS])
    //);

    //`CONNECT_BUS(demux_0_out[(N_TARGETS*0)+0], mux_0_in[(N_INITIATORS*0)+0]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*0)+1], mux_0_in[(N_INITIATORS*1)+0]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*0)+2], mux_0_in[(N_INITIATORS*2)+0]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*0)+3], mux_0_in[(N_INITIATORS*3)+0]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*0)+4], mux_0_in[(N_INITIATORS*4)+0]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*0)+5], mux_0_in[(N_INITIATORS*5)+0]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*1)+0], mux_0_in[(N_INITIATORS*0)+1]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*1)+1], mux_0_in[(N_INITIATORS*1)+1]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*1)+2], mux_0_in[(N_INITIATORS*2)+1]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*1)+3], mux_0_in[(N_INITIATORS*3)+1]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*1)+4], mux_0_in[(N_INITIATORS*4)+1]);
    //`CONNECT_BUS(demux_0_out[(N_TARGETS*1)+5], mux_0_in[(N_INITIATORS*5)+1]);

    //obi_mux #(
    //    .N_SEGMENTS(N_INITIATORS)
    //) i_mux_0 (
    //    .clk_i   (clk_i),
    //    .rst_i   (rst_i),
    //    .initiators(mux_0_in[(0*N_INITIATORS)+:N_INITIATORS]),
    //    .target    (targets[0])
    //);
    //obi_mux #(
    //    .N_SEGMENTS(N_INITIATORS)
    //) i_mux_1 (
    //    .clk_i   (clk_i),
    //    .rst_i   (rst_i),
    //    .initiators(mux_0_in[(1*N_INITIATORS)+:N_INITIATORS]),
    //    .target    (targets[1])
    //);
    //obi_mux #(
    //    .N_SEGMENTS(N_INITIATORS)
    //) i_mux_2 (
    //    .clk_i   (clk_i),
    //    .rst_i   (rst_i),
    //    .initiators(mux_0_in[(2*N_INITIATORS)+:N_INITIATORS]),
    //    .target    (targets[2])
    //);
    //obi_mux #(
    //    .N_SEGMENTS(N_INITIATORS)
    //) i_mux_3 (
    //    .clk_i   (clk_i),
    //    .rst_i   (rst_i),
    //    .initiators(mux_0_in[(3*N_INITIATORS)+:N_INITIATORS]),
    //    .target    (targets[3])
    //);
    //obi_mux #(
    //    .N_SEGMENTS(N_INITIATORS)
    //) i_mux_4 (
    //    .clk_i   (clk_i),
    //    .rst_i   (rst_i),
    //    .initiators(mux_0_in[(4*N_INITIATORS)+:N_INITIATORS]),
    //    .target    (targets[4])
    //);
    //obi_mux #(
    //    .N_SEGMENTS(N_INITIATORS)
    //) i_mux_5 (
    //    .clk_i   (clk_i),
    //    .rst_i   (rst_i),
    //    .initiators(mux_0_in[(5*N_INITIATORS)+:N_INITIATORS]),
    //    .target    (targets[5])
    //);

endmodule : obi_xbar
