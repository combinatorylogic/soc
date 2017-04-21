#include <iostream>
#include <chrono>
#include <mutex>
#include <thread>
#include <verilated.h>
#include "Vtiny1_soc.h"

#include <ncurses.h>

Vtiny1_soc *top;

vluint64_t sim_clock = 0;
vluint64_t sys_clock = 0;

typedef unsigned int uint32;

typedef unsigned short ushort;
typedef unsigned int uint;

int main(int argc, char **argv, char **env) {
        FILE *fsrc;
        ushort *buf;
        uint n, size;

	// Read hex file
        if (argc!=2) return -1;
        fsrc = fopen(argv[1], "r");
        
        fscanf(fsrc, "%x\n", &size);
        buf = (ushort *)malloc(2 * size + 2);
        for (n = 0; n < size; n++) {
                uint tmp;
                fscanf(fsrc, "%x\n", &tmp);
                buf[n] = tmp;
        }

	top = new Vtiny1_soc;		// Create instance of module

	Verilated::commandArgs(argc, argv);
	Verilated::debug(0);
	
	top->clk = 0;	 	        // Clock
	top->rst = 0;                  // reset button pressed
	
	for (n = 0; n < size; n++) {
		top->tiny1_soc__DOT__ram__DOT__RAM[n] = buf[n];
	}
	
	// Warm up in reset
	while(sys_clock < 100) {
		if (sim_clock%4==0) {
			top->clk = 1; sys_clock++;
		} else if (sim_clock%4==2) top->clk = 0;
		if(sim_clock == 300) {
			top->rst = 1; // Release reset button
		}
		top->eval();
		sim_clock++;
	}
	
	for(;;) {
		top->eval();
		top->clk = !top->clk;
		if (top->clk) {
			if (top->uart_out_ready) {
				printf("%c", top->uart_out);
			}
			if (top->just_die_already) {
				top->final();
				exit(0);
			}
		}
	}
}

