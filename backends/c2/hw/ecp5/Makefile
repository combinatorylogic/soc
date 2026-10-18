SIMCELLS ?= $(HOME)/priv/yosys/share/yosys/ice40/cells_sim.v
EXTRA ?=
BITNAME ?= c2_soc
PROG_NAME ?= custom_ice
INIT_FILE_PATH ?= ../../$(PROG_NAME)

SOURCES = ecp.v 3rdparty.v ../rtl/core.v ../rtl/soctop.v ../rtl/regfile.v
SOURCES1 = ecp.v 3rdparty.v core.v ../rtl/soctop.v ../rtl/regfile.v
FLASH_MODE=qspi
FLASH_FREQ=38.8 #MHz


all: c2_soc.bit

c2_soc.json: c2soc.lpf $(SOURCES)  $(INIT_FILE_PATH).hex
	yosys -p "synth_ecp5 -json c2_soc.json -top c2soc"  -f "verilog -I$(INIT_FILE_PATH)_out $(EXTRA) -DICE=1 -DENABLE_EXT=1 -DENABLE_LONG_EXT=1 -DDISABLE_MICROOPS=1 -DENABLE_UART=1 -DDISABLE_MEMQUEUE=1 -DDISABLE_BARREL_SHIFTER=1 -DICEFREQ=44000000 -DINIT_FILE_PATH=$(INIT_FILE_PATH).hex"  $(SOURCES)


c2_soc.config: c2_soc.json
	nextpnr-ecp5 --json c2_soc.json --lpf c2soc.lpf --textcfg $@ --um-45k --freq 50 --package CABGA381

c2_soc.bit: c2_soc.config
	ecppack --svf-rowsize 100000 \
		--svf c2_soc.svf --input $< --bit $@

$(PROJ).svf: $(PROJ).bit

