module mul32x32_fsm(input clk,
                    input             rst,
                    input             req,
               
                    input [31:0]      p0,
                    input [31:0]      p1,
                    output reg        ack,
                    output reg [31:0] out);

   // Low 32 bits of the product, computed in one cycle from the operands sampled at req. The
   // request/acknowledge protocol is unchanged (ack one cycle after req), but the operands are
   // no longer read after the request cycle: an HLS FSM may already present the next iteration's
   // values on p0/p1 while a multi-stage multiplier is still working, which corrupted the high
   // half of the previous version's result. A DSP48 multiply is single-cycle at these widths too.
   wire [31:0]               product = p0 * p1;

   always @(posedge clk) begin
      if (req) begin
         out <= product;
         ack <= 1;
      end else begin
         ack <= 0;
      end
   end
endmodule // mul32x32_fsm


