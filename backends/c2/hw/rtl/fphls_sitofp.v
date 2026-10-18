module hls_SIToFPFSM(input clk,
                     input         reset,
                     input         req,
                     output        ack,
                  
                     input [31:0]  p0,
                     output [31:0] out);

   int_to_float c1(.clk(clk),
                   .rst(reset),
                   .a(p0),
                   .fl(out));


   tick #(.count(4)) t0 (.clk(clk), .reset(reset), .req(req), .ack(ack));
endmodule // hls_SIToFPFSM


