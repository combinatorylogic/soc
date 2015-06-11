PFRONT := pfront
MONO := mono

all: clikecc.exe

-include clikecc.exe.d
clikecc.exe: clike/CLikeSCore.dll
	cp clike/CLikeSCore.dll ./
	$(PFRONT) /c clikecc ./cc.hl

clike/CLikeSCore.dll:
	$(MAKE) -C clike CLikeSCore.dll

simx: backends/small1/hw/soc/logipi/verilated/obj_dir/simx

backends/small1/hw/soc/logipi/verilated/obj_dir/simx:
	$(MAKE) -C backends/small1/hw/soc/logipi/verilated exe

hwtests: backends/small1/hw/soc/logipi/verilated/obj_dir/simx clikecc.exe
	$(MAKE) -C backends/small1/sw/tests runtests

hdltests: backends/small1/hw/soc/logipi/verilated/obj_dir/simx clikecc.exe
	$(MAKE) -C backends/small1/sw/hdltests runtests

logipi:
	$(MAKE) -C backends/small1/hw/soc/logipi

atlys:
	$(MAKE) -C backends/small1/hw/soc/atlys

