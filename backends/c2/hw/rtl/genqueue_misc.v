module genqueue (input clk,
                     input              rst,
                     input [WIDTH-1:0]  queue_data_in,
                     input              queue_we,
                     output             queue_available,
                     output             queue_empty,
                     output             queue_oready,
                     output [WIDTH-1:0] queue_data_out,
                     input              queue_re);
   parameter WIDTH = 8;
   
   

endmodule

module widegenqueue (input clk,
                     input              rst,
                     input [WIDTH-1:0]  queue_data_in,
                     input              queue_we,
                     output             queue_available,
                     output             queue_empty,
                     output             queue_oready,
                     output [WIDTH-1:0] queue_data_out,
                     input              queue_re);

   parameter WIDTH=64;
   parameter DEPTH=4;
   parameter INPUT                      =0;
   

   wire                                 queue_full;

   assign queue_available = ~queue_full;

   gendelayqueue #(.WIDTH(WIDTH),
                   .DEPTH(DEPTH), .INPUT(INPUT)) q
     (.clk(clk),
      .rst(rst),
      .we(queue_we),
      .idata(queue_data_in),
      .re(queue_re),
      .wdata(queue_data_out),
      .oready(queue_oready),
      .full(queue_full),
      .empty(queue_empty));

endmodule
