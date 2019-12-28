module ram1_blit(input clk,
                 input                              rst,

                 input                              req,
                 input [COMPUTE_OUT_FULL_WIDTH-1:0] data_in,
                 input [BLIT_ADDR_WIDTH-1:0]        data_addr,

                 output reg                         ready,

                 output [28:0]                      ram1_address,
                 output [7:0]                       ram1_burstcount,
                 input                              ram1_waitrequest,
                 input [63:0]                       ram1_readdata,
                 input                              ram1_readdatavalid,
                 output                             ram1_read,
                 output [63:0]                      ram1_writedata,
                 output [7:0]                       ram1_byteenable,
                                                    outp ut ram1_write
                 );

   parameter COMPUTE_OUT_FULL_WIDTH = 64;
   parameter BLIT_ADDR_WIDTH = 16;
   parameter BLIT_WIDTH = 8;

   parameter STEPS = COMPUTE_OUT_FULL_WIDTH / BLIT_WIDTH;
   parameter STEPS_COUNT = STEPS;

   reg [15:0]                                       steps;
   reg [COMPUTE_OUT_FULL_WIDTH-1:0]                 data_temp;

   reg [31:0]                                       clkcounter;
