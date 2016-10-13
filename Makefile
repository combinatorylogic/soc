PFRONT ?= pfront
MONO ?= mono

all: clikecc.exe icetest

-include clikecc.exe.d
clikecc.exe: CLikeSCore.dll
	$(MAKE) -C clike CLikeSCore.dll
	$(PFRONT) /c clikecc ./cc.hl


-include clike/CLikeSCore.dll.d
CLikeSCore.dll:
	$(MAKE) -C clike CLikeSCore.dll
	cp clike/CLikeSCore.dll ./


simx: backends/small1/hw/soc/logipi/verilated/obj_dir/simx

backends/small1/hw/soc/logipi/verilated/obj_dir/simx:
	$(MAKE) -C backends/small1/hw/soc/logipi/verilated exe

hwtests: backends/small1/hw/soc/logipi/verilated/obj_dir/simx clikecc.exe
	$(MAKE) -C backends/small1/sw/tests runtests

hdltests: backends/small1/hw/soc/logipi/verilated/obj_dir/simx clikecc.exe
	$(MAKE) -C backends/small1/sw/hdltests runtests

longtests: backends/small1/hw/soc/logipi/verilated/obj_dir/simx clikecc.exe
	$(MAKE) -C backends/small1/sw/long_tests runtests
	$(MAKE) -C backends/small1/sw/long_hdltests runtests

logipi:
	$(MAKE) -C backends/small1/hw/soc/logipi

atlys:
	$(MAKE) -C backends/small1/hw/soc/atlys


icetest:
	$(MAKE) -C backends/tiny1/ test

ice:
	$(MAKE) -C backends/tiny1/ ice

