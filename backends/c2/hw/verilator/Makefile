all: exe

prep:
	verilator --autoflush -Mdir obj_dir -Wno-WIDTH -DICE -DDISABLE_MICROOPS -DSIMULATION -DENABLE_EXT -DENABLE_LONG_EXT -DRAM_REGISTERED_OUT=1 --top-module c2soc -O2 --cc vmisc.v vgatopsim.v ../rtl/soctop.v ../rtl/core.v ../rtl/regfile.v -I../rtl -I. -I../dummy

exe:  prep
	cd obj_dir; make -f ../Makefile_obj

prepcustom: ../../custom_out/c2_custom_pipeline.v
	verilator --autoflush -Mdir custom_dir -Wno-WIDTH -DICE -DDISABLE_MICROOPS -DSIMULATION -DENABLE_EXT -DENABLE_LONG_EXT -DRAM_REGISTERED_OUT=1 --top-module c2soc -O2 --cc vmisc.v vgatopsim.v ../rtl/soctop.v ../rtl/core.v ../rtl/regfile.v -I../rtl -I. -I../../custom_out

exe:  prep
	cd obj_dir; make -f ../Makefile_obj

execustom:  prepcustom
	cd custom_dir; make -f ../Makefile_obj

clean:
	rm -rf obj_dir custom_dir

