module mkdelay (
	        input              clk,
                input              rst,
	        input [WIDTH-1:0]  in,
	        output [WIDTH-1:0] out
	        );

   parameter WIDTH   = 16;
   parameter DEPTH   = 2;

   reg [WIDTH-1:0]                 rs [DEPTH-1:0];
   assign out = rs[DEPTH-1];

   reg [15:0]                      n;
   always @(posedge clk)
     if (!rst) begin
	for(n=0; n<DEPTH; n=n+1)
	  rs[n] <= 0;
     end else begin
	rs[0] <= in;
	for(n=DEPTH-1; n!=0; n=n-1)
	  rs[n] <= rs[n-1];
     end

endmodule
