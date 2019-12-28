
module hls_FMulFSM(input clk,
                   input         reset,
                   input         req,
                   output        ack,
                  
                   input [31:0]  p0,
                   input [31:0]  p1,
                   output [31:0] out);

   fpmult_m2 mul1(.clk(clk),
                  .rst(reset),
                  .a(p0),
                  .b(p1),
                  .res(out));

   tick #(.count(3)) t0 (.clk(clk), .reset(reset), .req(req), .ack(ack));

endmodule // hls_FMulFSM

