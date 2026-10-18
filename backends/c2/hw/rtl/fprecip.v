/*
 
 Algorithm is explained here: 
    http://www.acsel-lab.com/arithmetic/arith9/papers/ARITH9_Fowler.pdf
 
 X[i+1] = X[i]*(2 - B*X[i]):
 
 X[0] = LUT[B[22:16]]
 X[1] = X[0]*(2 - B*X[0])
 X[2] = X[1]*(2 - B*X[1])
 
 or,
 
 Xx[1] = 2-B*X[0]
 X[1] = X[0] * Xx[1]
 Xx[2] = 2-B*X[1]
 X[2] = X[1]*Xx[2]
 Res_m = X[2]

 X[0] LUT is defined in fprecip_rom.v; 
 Generate fprecip_rom.v with mk.c
 
 The default LUT index is 7 bit, X0 is 8 bits.
*/


`include "fprecip_rom.v"

module fprecip(
               input         clk,
               input         rst,
               input [31:0]  denom,

               output [31:0] recip
               );

   wire [7:0]                X0;
   
   fprecip_rom r
     (
      .clk(clk),
      .v(denom[22:16]),
      .out(X0)
      );
   
   fprecip_newton i
     (
      .clk(clk),
      .rst(rst),
      .X0(X0),
      .denom(denom),
      .recip(recip)
      );
   
endmodule

module fprecip_newton
   (
    input             clk,
    input             rst,
    input [7:0]       X0,
    input [31:0]      denom,
    output reg [31:0] recip
   );

      
   // Pipeline stage 0:
   reg		 sign0;
   reg [30:23]   exp0;
   reg [22:0]	 B0;
   always @(posedge clk)
     if (!rst) begin
        sign0 <= 0;
        exp0 <= 0;
        B0 <= 0;
     end else begin
   	sign0 <= denom[31];
   	exp0  <= denom[30:23];
   	B0    <= denom[22:0];
     end

   // Pipeline stage 1: First Newton-Raphson iteration (B * X[0])
   reg  [32:0]	 BX0m;
   reg [7:0]	 X0r;
   reg           sign1;
   reg [30:23]   exp1;
   reg [22:0]	 B1;
   always @(posedge clk)
     if (!rst) begin
   	BX0m  <= 0;
	X0r <= 0;
	sign1  <= 0;
	exp1   <= 0;
	B1     <= 0;
     end else begin
   	BX0m  <= ({1'b1,B0} * {1'b1,X0}); // X0 is 8 bit only
	X0r <= X0;
	sign1  <= sign0;
	exp1   <= 8'hfe - exp0;
	B1     <= B0;
     end

   // Pipeline stage 2: First Newton-Raphson iteration, X[1] = X[0] * (2 - B*X[0])
   wire [32:8]	 BX0r;
   wire [24:0]	 BX02c;
   assign BX0r = BX0m[32:8] + BX0m[7]; // B - 23bit, X0 - 8 bit
   assign BX02c =  (~BX0r) + 25'b1;    // 2-complement
   
   reg [34:0]    X1m;
   reg [30:23]   exp2;
   reg		 sign2;
   reg [22:0]    B2;
   always @(posedge clk)
     if (!rst) begin
	X1m  <= 0;
	exp2  <= 0;
	sign2 <= 0;
	B2    <= 0;
     end else begin
	X1m  <= (BX02c * {1'b1,X0r});
	exp2  <= exp1;
	sign2 <= sign1;
	B2    <= B1;
     end

   // Pipeline stage 3: Second Newton-Raphson iteration, B * X[1]
   reg  [41:0]	 BX1m;
   reg [17:0]    X1r;
   reg		 sign3;
   reg [30:23]   exp3;
   always @(posedge clk) 
     if (!rst) begin
   	BX1m <= 0;
	sign3 <= 0;
	exp3 <= 0;
	X1r <= 0;
     end else begin
   	BX1m <= ({1'b1,B2} * X1m[33:16]);
	sign3 <= sign2;
	exp3 <= exp2;
	X1r <= X1m[33:16];
     end

   // Pipeline stage 4: Second Newton-Raphson iteration,
   //           X[2] = X[1] * (2 - B*X[1])
   wire [25:0]	 BX1r;
   wire [25:0]	 BX12c;
   
   assign BX1r = BX1m[40:15] + BX1m[14];
   assign BX12c = ~(BX1r) + 26'b1;

   reg  [43:0]	 X2;
   reg [30:23]   exp4;
   reg		 sign4;
   always @(posedge clk)
     if (!rst) begin
	sign4 <= 0;
	exp4  <= 0;
        X2 <= 0;
     end else begin
        X2 <= (X1r * BX12c);
	exp4  <= exp3;
	sign4 <= sign3;
     end

   // Pipeline stage 5: rounding, normalisation and truncation
   wire [24:0]	 X2rd;
   assign X2rd = X2[41:18] + X2[17];

   wire [30:23]	 nexp;
   assign nexp = exp4 - !X2rd[24];

   wire [23:0]   X2rdn;
   assign X2rdn = X2rd[24]?X2rd[24:1]:X2rd[23:0];
   always @(posedge clk)
     if (!rst) begin
        recip <= 0;
     end else begin
        recip <= {sign4,nexp,X2rdn[22:0]};
     end

endmodule

