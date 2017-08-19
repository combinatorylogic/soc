PFRONT ?= pfront
MONO ?= mono

all: prep clikecc.exe c2 icetest

-include clikecc.exe.d
clikecc.exe: CCSmall1.dll cc.hl
	$(PFRONT) /c clikecc ./cc.hl


-include CCSmall1.dll.d
CCSmall1.dll: CLikeSCore.dll cc1.hl
	$(MAKE) -C clike CLikeSCore.dll
	$(PFRONT) /d CCSmall1 ./cc1.hl


-include clike/CLikeSCore.dll.d
CLikeSCore.dll:
	$(MAKE) -C clike CLikeSCore.dll
	cp clike/CLikeSCore.dll ./

simx: backends/small1/hw/soc/logipi/verilated/obj_dir/simx prep

backends/small1/hw/soc/logipi/verilated/obj_dir/simx:
	$(MAKE) -C backends/small1/hw/soc/logipi/verilated exe

hwtests: backends/small1/hw/soc/logipi/verilated/obj_dir/simx clikecc.exe
	$(MAKE) -C backends/small1/sw/tests runtests

hdltests: backends/small1/hw/soc/logipi/verilated/obj_dir/simx clikecc.exe
	$(MAKE) -C backends/small1/sw/hdltests runtests

longtests: backends/small1/hw/soc/logipi/verilated/obj_dir/simx clikecc.exe
	$(MAKE) -C backends/small1/sw/long_tests runtests
	$(MAKE) -C backends/small1/sw/long_hdltests runtests

longhdltests: clikecc.exe
	$(MAKE) -C backends/small1/sw/long_hdltests runtests

logipi: prep
	$(MAKE) -C backends/small1/hw/soc/logipi

atlys: prep
	$(MAKE) -C backends/small1/hw/soc/atlys

icetest:
	$(MAKE) -C backends/tiny1/ test

ice:
	$(MAKE) -C backends/tiny1/ ice

c2:	clikecc.exe
	$(MAKE) -C backends/c2


prep: backends/small1/hw/custom/custom_exec.v

backends/small1/hw/custom/custom_exec.v:
	mkdir -p backends/small1/hw/custom/
	touch backends/small1/hw/custom/custom_exec.v
	touch backends/small1/hw/custom/custom_hoisted.v
	touch backends/small1/hw/custom/custom_include.v
	touch backends/small1/hw/custom/custom_reset.v
	touch backends/small1/hw/custom/custom_wait.v

