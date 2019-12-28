mk: mk.c
	gcc -o mk mk.c

fprecip_rom.v: mk
	./mk > fprecip_rom.v

synth.v: core.v synth.ys
	yosys -qv3 -l synth.log synth.ys
