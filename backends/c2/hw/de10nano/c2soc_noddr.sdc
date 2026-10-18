create_clock -name "sys_clk_in" -period 20.000ns [get_ports sys_clk_in]
create_clock -name "i2c_20k_clock" -period 50000.000ns [get_keepers *mI2C_CTRL_CLK]
#create_clock -name "clk100mhz" -period "150.0 MHz" [get_pins *|clk100mhz]
#create_clock -name "clk25mhz" -period "25 MHz" [get_pins *|clk_vga]
#derive_pll_clocks 

derive_pll_clocks -create_base_clocks
derive_clock_uncertainty
