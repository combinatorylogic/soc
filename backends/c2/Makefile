all: test mandtest mandgfxtest

ram.hex: asmcli.exe sw/icetest.s
	mono ./asmcli.exe sw/icetest.s > ram.hex

asmcli.exe: asmcli.hl asm.hl
	pfront /c asmcli asmcli.hl

test: sw/bigtest.c sw/ftest.c ../../clikecc.exe
	make -C hw/verilator
	mono ../../clikecc.exe /arch c2 /o+ sw/bigtest.c
	./hw/verilator/obj_dir/simx test.hex | grep -v ">>" > test.out
	diff test.out sw/test.ref
	mono ../../clikecc.exe /arch c2 /out ftest /o+ sw/ftest.c
	./hw/verilator/obj_dir/simx ftest.hex  | grep -v ">>"  > ftest.out
	diff ftest.out sw/ftest.ref

mandtest: sw/mand.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/mand.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex > mand.out
	diff mand.out sw/mand.ref

mandgfxtest: sw/mand2gfx.c sw/runtime_hls.c ../../clikecc.exe
	rm -rf custom_out hw/verilator/custom_dir
	mono ../../clikecc.exe /arch c2 /o+ sw/mand2gfx.c /out custom
	make -C hw/verilator execustom
	./hw/verilator/custom_dir/simx custom.hex
	diff vgadump0000.xpm sw/mand2gfx.ref

ice: ram.hex
	cp ram.hex hw/ice/
	make -C hw/ice c2_route.exe
	make -C hw/ice c2_route_test




