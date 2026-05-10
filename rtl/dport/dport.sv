module dport (
    input logic          rst_i,
    input logic          clk_i,
          obi_if.slave   cpu,
          obi_if.master  periph,
          obi_if.master  dtcm,
          axi_if.master  m_axi_cached,
          axi_if.master  m_axi_uncached,
          axil_if.master m_axil
);
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

    dport2axil i_dport2axil (
        .clk_i (clk_i),
        .rst_i (rst_i),
        .dport (axil),
        .m_axil(m_axil)
    );
endmodule : dport
