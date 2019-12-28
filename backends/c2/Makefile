all: test mandgfxtest mandtest ice icecustom

ram.hex: asmcli.exe sw/icetest.s
	mono ./asmcli.exe sw/icetest.s > ram.hex

asmcli.exe: asmcli.hl asm.hl
	pfront /c asmcli asmcli.hl

test: sw/bigtest.c sw/ftest.c ../../clikecc.exe
	make -C hw/verilator
	mono ../../clikecc.exe /arch c2 /o+ sw/bigtest.c
	./hw/verilator/obj_dir/simx test.hex | grep -av ">>" > test.out
	diff -a test.out sw/test.ref
	mono ../../clikecc.exe /arch c2 /out ftest /o+ sw/ftest.c
	./hw/verilator/obj_dir/simx ftest.hex  | grep -av ">>"  > ftest.out
	diff -a ftest.out sw/ftest.ref

mandtest: sw/mand.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/mand.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex | grep -av ">>>" > mand.out
	diff -a mand.out sw/mand.ref

ramxtest: sw/ramdebug.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/ramdebug.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex

songtest: sw/sound3.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/sound3.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex 

sinetest: sw/test99.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/test99.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex | grep -av ">>>" > sine.out
	diff -a mand.out sw/mand.ref

divtest: sw/test1.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/test1.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex

mandgfxtest: sw/mand2gfx.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /subarch artix7 /o+ sw/mand2gfx.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex
	compare -verbose -metric mae vgadump0000.xpm sw/mand2gfx.ref mandgfx_diff.png

mandflttest: sw/mandfltalt.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /subarch artix7 /o+ sw/mandfltalt.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex
	compare -verbose -metric mae vgadump0000.xpm sw/mandfltgfx.ref mandflt_diff.png

ballsflttest: sw/metaballsram.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /subarch artix7 /o+ sw/metaballsram.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex


altera: sw/altera.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /subarch artix7 /o+ sw/altera.c /out custom

alteraflt: sw/mandfltalt.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /subarch artix7 /c2barrel /c2cmpops /o+ sw/mandfltalt.c /out custom

alteraram: sw/mandramalt.c sw/runtime_hls.c sw/runtime_ram.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /subarch artix7 /c2ram 16300 /c2barrel /c2cmpops /o+ sw/mandramalt.c /out custom


vgatest1: sw/vgatest1.c sw/runtime_hls.c sw/vgagfx.c sw/vgagfx2.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /subarch artix7 /o+ sw/vgatest1.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex

mandgfxtest8: sw/mand4gfx.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/mand4gfx.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex
	diff -a vgadump0000.xpm sw/mand2gfx.ref

ice: ram.hex
	cp ram.hex hw/ice/
	make -C hw/ice c2_route.exe
	make -C hw/ice c2_route_test

icecustom: sw/icetest.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o+ sw/icetest.c /out custom_ice	
	make -C hw/ice c2_route_c.exe
	make -C hw/ice c2_route_test_c

blackicemand: sw/icemand.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o+ sw/icemand.c /c2barrel /c2cmpops /out icemand
	rm -f hw/blackice/c2_soc_mandslow.txt hw/blackice/c2_soc_mandslow.blif
	make -C hw/blackice EXTRA=" -DENABLE_BARREL_SHIFTER=1 " BITNAME=c2_soc_mandslow PROG_NAME=icemand

blackicemusic: sw/sound.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o+ sw/sound.c /c2barrel /c2cmpops /out icemusic
	rm -f hw/blackice/c2_soc_icemusic.txt hw/blackice/c2_soc_icemusic.blif
	make -C hw/blackice EXTRA=" -DENABLE_BARREL_SHIFTER=1 " BITNAME=c2_soc_icemusic PROG_NAME=icemusic

blackicemandhls: sw/icemand1.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o+ sw/icemand1.c /c2barrel- /c2cmpops /out icemand1
	rm -f hw/blackice/c2_soc_mandhls.txt hw/blackice/c2_soc_mandhls.blif
	make -C hw/blackice EXTRA=" " BITNAME=c2_soc_mandhls PROG_NAME=icemand1


# this one should be built without optimisations (instruction scheduler cannot accomodate for
#  the lack of the memqueue registers
blackicemandpipe: sw/icemand2.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o- sw/icemand2.c /c2barrel- /c2cmpops /out icemand2
	rm -f hw/blackice/c2_soc_mandpipe.txt hw/blackice/c2_soc_mandpipe.blif
	make -C hw/blackice EXTRA="  -DDISABLE_MEMQUEUE=1 " BITNAME=c2_soc_mandpipe PROG_NAME=icemand2

blackicemandpipe2: sw/icemand3.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o- sw/icemand3.c /c2barrel- /c2cmpops /out icemand3
	rm -f hw/blackice/c2_soc_mandpipe2.txt hw/blackice/c2_soc_mandpipe2.blif
	make -C hw/blackice EXTRA="  -DDISABLE_MEMQUEUE=1  " BITNAME=c2_soc_mandpipe2 PROG_NAME=icemand3
blackice2mand: sw/icemand.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o+ sw/icemand.c /c2barrel /c2cmpops /out icemand
	rm -f hw/blackice2/c2_soc_mandslow.txt hw/blackice2/c2_soc_mandslow.blif
	make -C hw/blackice2 EXTRA=" -DENABLE_BARREL_SHIFTER=1 " BITNAME=c2_soc_mandslow PROG_NAME=icemand

blackice2mandhls: sw/icemand1.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o+ sw/icemand1.c /c2barrel- /c2cmpops /out icemand1
	rm -f hw/blackice2/c2_soc_mandhls.txt hw/blackice2/c2_soc_mandhls.blif
	make -C hw/blackice2 EXTRA=" " BITNAME=c2_soc_mandhls PROG_NAME=icemand1


# this one should be built without optimisations (instruction scheduler cannot accomodate for
#  the lack of the memqueue registers
blackice2mandpipe: sw/icemand2.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o- sw/icemand2.c /c2barrel- /c2cmpops /out icemand2
	rm -f hw/blackice2/c2_soc_mandpipe.txt hw/blackice2/c2_soc_mandpipe.blif
	make -C hw/blackice2 EXTRA="  -DDISABLE_MEMQUEUE=1 " BITNAME=c2_soc_mandpipe PROG_NAME=icemand2

blackice2mandpipe2: sw/icemand3.c
	mono ../../clikecc.exe /arch c2 /subarch ice40 /o- sw/icemand3.c /c2barrel- /c2cmpops /out icemand3
	rm -f hw/blackice2/c2_soc_mandpipe2.txt hw/blackice2/c2_soc_mandpipe2.blif
	make -C hw/blackice2 EXTRA="  -DDISABLE_MEMQUEUE=1  " BITNAME=c2_soc_mandpipe2 PROG_NAME=icemand3

