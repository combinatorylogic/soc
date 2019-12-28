
module hls_FDivFSM(input clk,
                   input         reset,
                   input         req,
                   output        ack,
                  
                   input [31:0]  p0,
                   input [31:0]  p1,
                   output [31:0] out);

   wire [63:0]                   nd;
   assign nd = {p0, p1};

   fpdiv d1(.clk(clk),
            .rst(reset),
            .a(p0),
            .b(p1),
            .res(out));


   tick #(.count(8)) t0 (.clk(clk), .reset(reset), .req(req), .ack(ack));
endmodule // hls_FDivFSM

