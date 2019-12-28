#include <iostream>
#include <chrono>
#include <mutex>
#include <thread>
#include <verilated.h>
#include "Vc2soc.h"

#include <ncurses.h>

Vc2soc *top;

vluint64_t sim_clock = 0;
vluint64_t sys_clock = 0;

typedef unsigned int uint32;

typedef unsigned short ushort;
typedef unsigned int uint;


unsigned char *vgamem;
int vgacounter;

void dumpmem()
{
        FILE *f;
        char fname[50];
        sprintf(fname, "vgadump%04d.xpm", vgacounter);
        vgacounter++;
        f = fopen(fname, "w");
        fprintf(f, "P2\n640 480 32\n");
        for (int i = 0; i < 480; i++) {
                for (int j = 0; j < 640/2; j++) {
                        unsigned char c = vgamem[j + i*(640/2)];
                        fprintf(f, "%d %d ", (c>>4)&0xf, c&0xf);
                }
                fprintf(f, "\n");
        }
        fclose(f);
}


int main(int argc, char **argv, char **env) {
        FILE *fsrc;
        uint *buf;
        uint n, size;
        uint prev_LED = 99999;

        vgacounter = 0;

	// Read hex file
        if (argc!=2) return -1;
        fsrc = fopen(argv[1], "r");
        size = 8192;
        buf = (uint *)malloc(2 * sizeof(uint) * size + 2);
        for (n = 0; n < size; n++) {
                uint tmp;
                if (fscanf(fsrc, "%x\n", &tmp) == EOF) break;
                buf[n] = tmp;
        }
        size = n;

	top = new Vc2soc;		// Create instance of module

	Verilated::commandArgs(argc, argv);
	Verilated::debug(0);
	
	top->sys_clk_in = 0;	 	        // Clock
	top->sys_reset = 0;                  // reset button pressed

        vgamem = top->c2soc__DOT__vga1__DOT__vram1__DOT__mem;
        
	for (n = 0; n < size; n++) {
		top->c2soc__DOT__ram1__DOT__mem[n] = buf[n];
	}
	
	// Warm up in reset
	while(sys_clock < 100) {
		if (sim_clock%4==0) {
			top->sys_clk_in = 1; sys_clock++;
		} else if (sim_clock%4==2) top->sys_clk_in = 0;
		if(sim_clock == 300) {
			top->sys_reset = 1; // Release reset button
		}
		top->eval();
		sim_clock++;
	}
	
	while(!top->FINISH) {
		top->eval();
		top->sys_clk_in = !top->sys_clk_in;
		if (top->sys_clk_in) {
			if (top->uart_wr) {
				printf("%c", top->uart_out);
			}
                        if (top->vga_dump) {
                                dumpmem();
                        }
                        if (top->LED != prev_LED) {
                                printf("LEDS: %x\n", top->LED);
                                prev_LED = top->LED;
                        }
		}
	}
        top->final();
}

