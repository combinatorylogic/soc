EXTRA ?=
BITNAME ?= c2_soc
PROG_NAME ?= custom_ice
INIT_FILE_PATH ?= ../../$(PROG_NAME)
SOURCES = ice.v 3rdparty.v ../rtl/core.v ../rtl/soctop.v ../rtl/regfile.v

all: $(BITNAME).bin

$(BITNAME).blif: blackice.pcf $(SOURCES)
	yosys -p "synth_ice40 -top c2soc -blif $(BITNAME).blif"  -f "verilog -I$(INIT_FILE_PATH)_out $(EXTRA) -DICE=1 -DENABLE_EXT=1 -DENABLE_LONG_EXT=1 -DDISABLE_MICROOPS=1 -DINIT_FILE_PATH=$(INIT_FILE_PATH).hex"  $(SOURCES)

$(BITNAME).txt: $(BITNAME).blif blackice.pcf
	arachne-pnr -m 500 -s 2323 -d 8k -P tq144:4k -p blackice.pcf $(BITNAME).blif -o $(BITNAME).txt

$(BITNAME).bin: $(BITNAME).txt
	icepack $(BITNAME).txt $(BITNAME).bin
	icetime -d hx8k $(BITNAME).txt

