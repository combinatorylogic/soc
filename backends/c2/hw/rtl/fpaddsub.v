module FAddSubFSM(input clk,
                  input         reset,
                  input         subp,
                  input         req,
                  output        ack,
                  
                  input [31:0]  p0,
                  input [31:0]  p1,
                  output [31:0] out);
   
    fpadd_sub a(.clk(clk),
                .rst(reset),
                .sub(subp),
                .a(p0),
                .b(p1),
                .res(out));

   tick #(.count(3)) t0 (.clk(clk), .reset(reset), .req(req), .ack(ack));

endmodule
