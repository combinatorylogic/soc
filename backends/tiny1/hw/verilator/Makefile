all: exe

prep:
	verilator --autoflush -Wno-WIDTH -DSIMULATION  --top-module tiny1_soc --cc vtop.v ../rtl/core.v

exe:  prep
	cd obj_dir; make -f ../Makefile_obj

clean:
	rm -rf obj_dir

