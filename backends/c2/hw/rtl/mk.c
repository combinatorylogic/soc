// LUT for X0 approximation:
//
//  X0 = 1/(b' + 2^N) + 2^(N+1), where N = number of b' bits + 1
//
//   In our case, b' is 7 bits and X0 - 8 bits
//
// See http://www.acsel-lab.com/arithmetic/arith9/papers/ARITH9_Fowler.pdf
// for more details.


#include <stdio.h>
#include <stdlib.h>

int main()
{
        float v = 1.0;
        printf("module fprecip_rom(");
        printf("input clk, input [6:0] v, output reg [7:0] out);\n");
        printf("always @(posedge clk)\n");
        printf("  case (v) // synopsys full_case parallel_case\n");
        unsigned int t = *((unsigned int *)(&v));
        unsigned int t1 = t - (t & 0x7fffff); // remove mantissa
        for (int i = 0; i < 128; i++) {
                unsigned int t2 = t1 | ((i&0x7f)<<16) | (1<<15);
                float v1 = *((float *)(&t2));
                float v2 = 1.0/v1 + 1.0/(1<<9);
                unsigned int t3 = *((unsigned int *)(&v2));
                unsigned int t4 = (t3&0x7fffff) >> 15;
                // printf("// %d %f - %f %x %x -- %x\n", i, v1, v2, t2, t3&0x7fffff, t4);
                printf("   7'h%x: out <= 8'h%x;\n", i, t4);
        }
        printf("  endcase\n\n");
        printf("endmodule\n");
}

