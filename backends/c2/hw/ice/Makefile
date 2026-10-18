SIMCELLS ?= $(HOME)/priv/yosys/share/yosys/ice40/cells_sim.v
EXTRA ?=
BITNAME ?= c2_soc
PROG_NAME ?= custom_ice
INIT_FILE_PATH ?= ../../$(PROG_NAME)

SOURCES = ice.v 3rdparty.v ../rtl/core.v ../rtl/soctop.v ../rtl/regfile.v
SOURCES1 = ice.v 3rdparty.v core.v ../rtl/soctop.v ../rtl/regfile.v

all: c2_soc.bin

c2_soc.blif: 8k.pcf $(SOURCES) ram.hex
	yosys -p "synth_ice40 -top c2soc -blif c2_soc.blif  -DICEFREQ=24000000 " $(SOURCES)

c2_soc.txt: c2_soc.blif 8k.pcf
	arachne-pnr -m 500 -s 2323 -d 8k -p 8k.pcf c2_soc.blif -o c2_soc.txt

c2_soc.bin: c2_soc.txt
	icepack c2_soc.txt c2_soc_tmp.bin
	icemulti -p0 c2_soc_tmp.bin > c2_soc.bin


camrig.json: 8k.pcf $(SOURCES) $(INIT_FILE_PATH).hex
	yosys -p "synth_ice40 -top c2soc -json camrig.json"  -f "verilog -I$(INIT_FILE_PATH)_out $(EXTRA) -DICE=1 -DENABLE_EXT=1 -DENABLE_LONG_EXT=1 -DDISABLE_MICROOPS=1 -DENABLE_UART=1 -DICEFREQ=24000000 -DCLK2X=1 -DICE_STEPPERS=1 -DINIT_FILE_PATH=$(INIT_FILE_PATH).hex"  $(SOURCES)

camrig.txt: camrig.json 8kstep.pcf $(INIT_FILE_PATH).hex
	# arachne-pnr -m 500 -s 2323 -d 8k -p 8k.pcf camrig.blif -o camrig.txt
	nextpnr-ice40 --freq 32 --hx8k --pcf 8kstep.pcf --json camrig.json --asc camrig.txt

camrig.bin: camrig.txt
	icepack camrig.txt camrig_tmp.bin
	icemulti -p0 camrig_tmp.bin > camrig.bin

c2_soc_sim.blif: 8kdebug.pcf $(SOURCES) ram.hex
	yosys -p "synth_ice40 -top c2soc -blif c2_soc_sim.blif" -f "verilog -DICE_DEBUG=1 -DDISABLE_CMPOPS=1 -DICE_ROUTED_SIM=1 -DICE=1  -DICEFREQ=24000000 "  $(SOURCES)

core.v: ../rtl/core.v 
	yosys -p "read_verilog -I../../custom_out -I../rtl/ -I. -ppdump ../rtl/core.v" > core_tmp.v
	sed -n '/-- Verilog code after preprocessor --/,/-- END OF DUMP --/p' core_tmp.v > core_tmp1.v
	tail -n +2 core_tmp1.v > core_tmp2.v
	head -n -1 core_tmp2.v > core_tmp3.v
	grep -v '`' core_tmp3.v > core.v

c2_i.exe: $(SOURCES) ram.hex core.v
	iverilog -o c2_i.exe -s testbench  -DICE_DEBUG=1 -DDISABLE_CMPOPS=1 -DICE_ROUTED_SIM=1 -DICE=1  -DICEFREQ=24000000 $(SOURCES1) c2_soc_tb.v  $(SIMCELLS)

c2_soc_sim.txt: c2_soc_sim.blif 8kdebug.pcf
	arachne-pnr -m 500 -s 2323 -d 8k -p 8kdebug.pcf c2_soc_sim.blif -o c2_soc_sim.txt


c2_soc_sim_c.blif: 8kdebug.pcf $(SOURCES) ../../custom_ice.hex
	yosys -p "synth_ice40 -top c2soc -blif c2_soc_sim_c.blif" -f "verilog -I../../custom_ice_out  -DICE_DEBUG=1 -DDISABLE_CMPOPS=1 -DICE=1 -DICE_ROUTED_SIM=1 -DENABLE_EXT=1  -DICEFREQ=24000000  -DENABLE_LONG_EXT=1"  $(SOURCES)

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
