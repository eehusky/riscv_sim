module dport #(
    parameter int AXI_ADDR_W      = 32,
    parameter int AXI_DATA_W      = 32,
    parameter int AXI_ID_W        = 8,
    parameter int AXI_LEN_W       = 8,
    parameter int AXIL_DATA_WIDTH = 32,
    parameter int AXIL_STRB_WIDTH = 4,
    parameter int DTCM_ADDR_W     = 17,
    parameter int PERIPH_ADDR_W   = 16
) (
    input logic          rst_i,
    input logic          clk_i,
          obi_if.slave   cpu,
          axi_if.slave   s_axi_dtcm,
          axi_if.master  m_axi_cached,
          axi_if.master  m_axi_uncached,
          axil_if.master m_axil
);
    obi_if periph ();
    obi_if dtcm ();
    obi_if cached ();
    obi_if uncached ();
    obi_if axil ();

    dport_mux i_dport_mux (
        .clk_i   (clk_i),
        .rst_i   (rst_i),
        .cpu     (cpu),
        .periph  (periph),
        .dtcm    (dtcm),
        .cached  (cached),
        .uncached(uncached),
        .axil    (axil)
    );

    dport_ram i_dport_ram (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(periph)
    );

    dport_dtcm #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(DTCM_ADDR_W),
        .STRB_WIDTH(4),
        .ID_WIDTH  (AXI_ID_W)
    ) i_dport_dtcm (
        .a_clk(clk_i),
        .a_rst(rst_i),
        .dport(dtcm),
        .s_axi(s_axi_dtcm)
    );

    dport2axi i_dport2axi_cached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(cached),
        .m_axi(m_axi_cached)
    );

    dport2axi i_dport2axi_uncached (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .dport(uncached),
        .m_axi(m_axi_uncached)
    );

    dport2axil #(
        .ADDR_WIDTH(AXI_ADDR_W)
    ) i_dport2axil (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .dport (axil),
        .m_axil(m_axil)
    );
endmodule : dport
