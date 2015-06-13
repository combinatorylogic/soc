.PRECIOUS: %.c.hex

%.c.hex: %.c ../runtime.c ../../../../clikecc.exe
	mono ../../../../clikecc.exe /out $< $< > $<.log

%.c.tst: %.c.hex ../../hw/soc/logipi/verilated/obj_dir/simx 
	../../hw/soc/logipi/verilated/obj_dir/simx --batch $< | grep -v "^>>" > $@
	diff $@ $@.ref

runtests: runtests.sh
	./runtests.sh



