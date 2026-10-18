
../hw/verilator/obj_dir/simx:
	make -C ../hw/verilator

%.c.hex: %.c ../../../clikecc.exe
	mono ../../../clikecc.exe /arch c2 /out $< /o+ $< > $<.log

%.c.out: %.c.hex ../hw/verilator/obj_dir/simx
	../hw/verilator/obj_dir/simx $< | grep -av ">>" > $@

