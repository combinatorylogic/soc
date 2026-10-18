create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_0
set_property -dict [list \
                        CONFIG.PRIMITIVE {PLL} \
                        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
                        CONFIG.RESET_TYPE {ACTIVE_HIGH} \
                        CONFIG.CLKOUT1_DRIVES {BUFG} \
                        CONFIG.MMCM_DIVCLK_DIVIDE {1} \
                        CONFIG.MMCM_CLKFBOUT_MULT_F {10} \
                        CONFIG.MMCM_COMPENSATION {ZHOLD} \
                        CONFIG.MMCM_CLKOUT0_DIVIDE_F {5} \
                        CONFIG.RESET_PORT {resetn} \
                        CONFIG.CLKOUT1_JITTER {114.829} \
                        CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
                        CONFIG.CLKOUT2_DRIVES {BUFG} \
                        CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {100.000} \
                        CONFIG.CLKOUT2_USED {1} \
                        CONFIG.CLKOUT3_DRIVES {BUFG} \
                        CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {25.000} \
                        CONFIG.CLKOUT3_USED {1} ] \
    [get_ips clk_wiz_0]
