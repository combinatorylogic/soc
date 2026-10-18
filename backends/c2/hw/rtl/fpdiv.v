`include "mkdelay.v"
`include "fprecip.v"

module fpdiv
	(
	input         clk,
	input         rst,
        input [31:0]  a,
        input [31:0]  b,
	output [31:0] res
	);
   // res = 1/b * a, using a table-based reciprocal approximation

   wire [31:0]          a7;
   wire [31:0]          quot;
   
   mkdelay #(.WIDTH(32),
             .DEPTH(6)) p(.clk(clk),
                          .rst(rst),
                          .in(a), 
                          .out(a7));

   fprecip r(.clk(clk),
             .rst(rst),
             .denom(b), 
             .recip(quot));
   
   fpmult m(.clk(clk),
            .rst(rst),
            .a(a7),
            .b(quot),
            .res(res));
   
endmodule
	
