EXTRA ?=
SOURCES = ice.v 3rdparty.v ../rtl/core.v ../rtl/soctop.v ../rtl/regfile.v

all: c2_soc.bin

c2_soc.blif: blackice.pcf $(SOURCES)
	yosys -p "synth_ice40 -top c2soc -blif c2_soc.blif"  -f "verilog -I../../custom_ice_out $(EXTRA) -DICE=1 -DENABLE_EXT=1 -DENABLE_LONG_EXT=1 -DDISABLE_MICROOPS=1"  $(SOURCES)

c2_soc.txt: c2_soc.blif blackice.pcf
	arachne-pnr -m 500 -s 2323 -d 8k -P tq144:4k -p blackice.pcf c2_soc.blif -o c2_soc.txt

c2_soc.bin: c2_soc.txt
	icepack c2_soc.txt c2_soc.bin

