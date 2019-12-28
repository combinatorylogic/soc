
// Assuming normalised inputs
module fp_mul(input clk,
              input         rst,

              input [31:0]  a0,
              input [31:0]  b0,

              output [31:0] ret);

   reg [31:0]               a;
   reg [31:0]               b;
   

   wire [22:0]              fa = a[22:0];
   wire [22:0]              fb = b[22:0];
   wire [7:0]               ea = a[30:23];
   wire [7:0]               eb = b[30:23];
   wire                     sa = a[31];
   wire                     sb = b[31];

   wire [47:0]              fab;

   // Multiply fractions
   /*mul23x23 M(.clk(clk),
              .rst(rst),
              .a(fa),
              .b(fb),
              .ret(fab));*/
   assign fab = {1'b1,fa} * {1'b1,fb};
   
   // Exps
   wire [8:0]               eab;
   assign eab = ea + eb;

   wire [47:0]              fab2n;

   assign fab2n = fab1 << nzeros;

   assign ret = {sab2, eab2, fab2};
   always @(posedge clk)
     begin
        // Stage 1: Register inputs
        a <= a0;
        b <= b0;
        // Stage 2+N: Get the exponents, get the multiplication output
        eab1 <= eab - 127;
        sab1 <= sa ^ sb;
        fab1 <= fab;
        // Stage 4+N: normalise the output
        fab2 <= fab2n[47:24];
        eab2 <= eab1 - nzeros;
        sab2 <= sab1;
     end
   
   

endmodule
