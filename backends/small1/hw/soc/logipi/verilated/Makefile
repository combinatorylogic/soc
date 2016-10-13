prep:
	verilator --autoflush -Wno-WIDTH -DSYNCSTACK -DSIMULATION -DLOGIPI --cc -f input.vc ../top.v ../spi.v ../../../rtl/stack.v ../../../rtl/core.v ../../../rtl/cpu.v ../../../rtl/3rdparty/fifo.v   ../../../rtl/icache.v ../../../rtl/3rdparty/arbiter.v ../../../rtl/3rdparty/vgafifo.v ../../../rtl/vgatop.v ../../../rtl/vga640x480.v 


exe:  prep
	cd obj_dir; make -f ../Makefile_obj

clean:
	rm -rf obj_dir
