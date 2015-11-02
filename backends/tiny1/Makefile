all: exe asm.exe sw/test.s.hex model

exe:
	$(MAKE) -C hw/verilator exe

clean:
	$(MAKE) -C hw/verilator clean

-include asm.exe.d
asm.exe: asm.hl top.hl sw/microcode.s
	pfront /c asm top.hl

sw/test.s.hex: sw/test.s asm.exe
	mono ./asm.exe sw/test.s

sw/ice.s.hex: sw/ice.s asm.exe
	mono ./asm.exe sw/ice.s

model:
	$(MAKE) -C sw/model model

test: model exe sw/test.s.hex
	./sw/model/model sw/test.s.hex > testlog1
	./hw/verilator/obj_dir/simx sw/test.s.hex > testlog2
	diff testlog1 testlog2

ice: sw/ice.s.hex
	cp sw/ice.s.v hw/ice/bootram.v
	$(MAKE) -C hw/ice all





