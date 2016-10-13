
SIMCELLS ?= $(HOME)/priv/yosys/share/yosys/ice40/cells_sim.v

SOURCES = ice40mem.v 3rdparty.v initram.v bootram.v ../rtl/core.v

all: tiny1_soc.bin tiny1_soc_stick.bin

tiny1_soc.blif: 8k.pcf $(SOURCES) top.v
	yosys -p "synth_ice40 -top tiny1_soc -blif tiny1_soc.blif" top.v $(SOURCES)

tiny1_soc_stick.blif: stick.pcf $(SOURCES) top.v
	yosys -p "synth_ice40 -top tiny1_soc -blif tiny1_soc_stick.blif" -f "verilog -DICESTICK=1" top.v $(SOURCES)

tiny1_soc.txt: tiny1_soc.blif 8k.pcf
	arachne-pnr -r -d 8k -p 8k.pcf tiny1_soc.blif -o tiny1_soc.txt

tiny1_soc_stick.txt: tiny1_soc_stick.blif stick.pcf
	arachne-pnr -r -d 1k -p stick.pcf tiny1_soc_stick.blif -o tiny1_soc_stick.txt

tiny1_soc.bin: tiny1_soc.txt
	icepack tiny1_soc.txt tiny1_soc_tmp.bin
	icemulti -p0 tiny1_soc_tmp.bin > tiny1_soc.bin

tiny1_soc_stick.bin: tiny1_soc_stick.txt
	icepack tiny1_soc_stick.txt tiny1_soc_stick_tmp.bin
	icemulti -p0 tiny1_soc_stick_tmp.bin > tiny1_soc_stick.bin

tiny1_route.v: tiny1_soc.txt
	icebox_vlog -L -n top -sp 8k.pcf tiny1_soc.txt > tiny1_route.v


tiny1_route.exe: tiny1_route.v tiny1_tb.v
	iverilog -o tiny1_route.exe -s testbench tiny1_route.v tiny1_tb.v $(SIMCELLS)
	chmod +x tiny1_route.exe

