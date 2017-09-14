SIMCELLS ?= $(HOME)/priv/yosys/share/yosys/ice40/cells_sim.v

SOURCES = ice.v 3rdparty.v ../rtl/core.v ../rtl/soctop.v ../rtl/regfile.v

all: c2_soc.bin

c2_soc.blif: 8k.pcf $(SOURCES) ram.hex
	yosys -p "synth_ice40 -top c2soc -blif c2_soc.blif" $(SOURCES)

c2_soc.txt: c2_soc.blif 8k.pcf
	arachne-pnr -m 500 -s 2323 -d 8k -p 8k.pcf c2_soc.blif -o c2_soc.txt

c2_soc.bin: c2_soc.txt
	icepack c2_soc.txt c2_soc_tmp.bin
	icemulti -p0 c2_soc_tmp.bin > c2_soc.bin

c2_soc_sim.blif: 8kdebug.pcf $(SOURCES) ram.hex
	yosys -p "synth_ice40 -top c2soc -blif c2_soc_sim.blif" -f "verilog -DICE_DEBUG=1 -DDISABLE_CMPOPS=1 -DICE_ROUTED_SIM=1 -DICE=1"  $(SOURCES)

c2_soc_sim.txt: c2_soc_sim.blif 8kdebug.pcf
	arachne-pnr -m 500 -s 2323 -d 8k -p 8kdebug.pcf c2_soc_sim.blif -o c2_soc_sim.txt


c2_soc_sim_c.blif: 8kdebug.pcf $(SOURCES) ../../custom_ice.hex
	yosys -p "synth_ice40 -top c2soc -blif c2_soc_sim_c.blif" -f "verilog -I../../custom_ice_out  -DICE_DEBUG=1 -DDISABLE_CMPOPS=1 -DICE=1 -DICE_ROUTED_SIM=1 -DENABLE_EXT=1 -DENABLE_LONG_EXT=1"  $(SOURCES)

c2_soc_sim_c.txt: c2_soc_sim_c.blif 8kdebug.pcf
	arachne-pnr -m 500 -s 2323 -d 8k -p 8kdebug.pcf c2_soc_sim_c.blif -o c2_soc_sim_c.txt

c2_route.v: c2_soc_sim.txt
	icebox_vlog -L -n top -sp 8kdebug.pcf c2_soc_sim.txt > c2_route.v

c2_route.exe: c2_route.v c2_tb.v
	iverilog -o c2_route.exe -s testbench c2_route.v c2_tb.v $(SIMCELLS)
	chmod +x c2_route.exe

c2_route_test: c2_route.exe
	vvp -n c2_route.exe  | grep -v ">>>"  > c2_route.out
	diff c2_route.out c2_route.ref


c2_route_c.v: c2_soc_sim_c.txt
	icebox_vlog -L -n top -sp 8kdebug.pcf c2_soc_sim_c.txt > c2_route_c.v

c2_route_c.exe: c2_route_c.v c2_tb.v
	iverilog -o c2_route_c.exe -s testbench c2_route_c.v c2_tb.v $(SIMCELLS)
	chmod +x c2_route_c.exe

c2_route_test_c: c2_route_c.exe
	vvp -n c2_route_c.exe | grep -v ">>>" > c2_route_c.out
	diff c2_route_c.out c2_route_c.ref
