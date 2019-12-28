// A parametric delay "queue" which does not use block rams
module gendelayqueue(input clk,
                  input                  rst,
                  
                  input                  we,
                  input [WIDTH-1:0]      idata,

                  input                  re,
                  output reg [WIDTH-1:0] wdata,

                  output                 oready,
                  output                 full,
                  output                 empty);
   parameter WIDTH = 8;
   parameter DEPTH=1;
   
   
   
   reg [WIDTH:0]                   q1,q2,q3,q4,q5,q6,q7,q8,q9,q10;
   wire [WIDTH:0]                  q1n,q2n,q3n,q4n,q5n,q6n,q7n,q8n,q9n,q10n;

   
   wire                            q1m,q2m,q3m,q4m,q5m,q6m,q7m,q8m,q9m;

   assign full = q1[WIDTH];
   assign oready = q1m|!q1[WIDTH];
   
   // Moving N if N+1 is empty or moving
   assign q1n = we?{1'b1, idata}:(q1m?0:q1); // up to the user not to write if full

   assign q1m = q2m|!q2[WIDTH]; assign q2m = q3m|!q3[WIDTH]; assign q3m = q4m|!q4[WIDTH];
   assign q4m = q5m|!q5[WIDTH]; assign q5m = q6m|!q6[WIDTH]; assign q6m = q7m|!q7[WIDTH];
   assign q7m = q8m|!q8[WIDTH]; assign q8m = q9m|!q9[WIDTH]; assign q9m = re|!q10[WIDTH];
 
   assign q2n = q2m?q1:q2; assign q3n = q3m?q2:q3;  assign q4n = q4m?q3:q4;
   assign q5n = q5m?q4:q5; assign q6n = q6m?q5:q6;  assign q7n = q7m?q6:q7;
   assign q8n = q8m?q7:q8; assign q9n = q9m?q8:q9;  assign q10n = re?q9:q10;
   
   always @(posedge clk)
     if (!rst) begin
        q1 <=  0; q2 <=  0;  q3 <=  0; q4 <=  0;
        q5 <=  0; q6 <=  0;  q7 <=  0; q8 <=  0;
        q9 <=  0; q10 <=  0;
     end // if (!rst)
     else begin
        q1 <= q1n; q2 <= q2n; q3 <= q3n; q4 <= q4n; q5 <= q5n; q6 <= q6n;
        q7 <= q7n; q8 <= q8n; q9 <= q9n; q10 <= q10n;
        if (re) begin
           wdata <= q10[WIDTH-1:0];
        end
     end
endmodule
                  
