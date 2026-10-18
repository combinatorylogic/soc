openocd -f ecp5-versa5g.cfg -c 'transport select jtag; init; svf quiet progress "c2_soc.svf"; exit'
