yosys -l top.rpt top.ys
nextpnr-ecp5 --json top.json --lpf top.lpf --textcfg top.config      --um5g-45k --package CABGA381 --speed 8 --timing-allow-fail  

ecppack top.config --svf top.svf --bit top.bit