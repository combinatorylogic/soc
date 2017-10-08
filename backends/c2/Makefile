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

mandgfxtest: sw/mand2gfx.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/mand2gfx.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex
	diff -a vgadump0000.xpm sw/mand2gfx.ref

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
	mono ../../clikecc.exe /arch c2 /o+ sw/icetest.c /out custom_ice	
	make -C hw/ice c2_route_c.exe
	make -C hw/ice c2_route_test_c

blackicemand: sw/icemand.c
	mono ../../clikecc.exe /arch c2 /o+ sw/icemand.c /c2barrel /c2cmpops /out custom_ice
	rm -f hw/blackice/*.txt hw/blackice/*.blif
	make -C hw/blackice EXTRA=" -DENABLE_BARREL_SHIFTER=1 "

blackicemandhls: sw/icemand1.c
	mono ../../clikecc.exe /arch c2 /o+ sw/icemand1.c /c2barrel- /c2cmpops /out custom_ice
	rm -f hw/blackice/*.txt hw/blackice/*.blif
	make -C hw/blackice EXTRA=" "

