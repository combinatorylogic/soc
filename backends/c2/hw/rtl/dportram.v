/* Duplicate the BRAM ports by running at 2x the speed */



/* clk2x:   |********        ********        ********        ********        ********        ********        | */
/* clk:     |****************                ****************                ****************                | */
/*          |                                                                                                | */
/*          |Writing:                                                                                        | */
/*          |                                                                                                | */
/*          |ip1_addr = p2_addr,                                                                             | */
/*          |ip1_we = p2_we,                                                                                 | */
/*          |ip1_datain = p2_datain,                                                                         | */
/*          |                                                                                                | */
/*          |Reading p0:                                                                                     | */
/*          |                                                                                                | */
/*          |ip0_addr = p0_addr,                                                                             | */
/*          |                                                                                                | */
/*          |Reading p1:                                                                                     | */
/*          |                                                                                                | */
/*          |                ip0_addr = p1_addr                                                              | */
/*          |                p0_data <= ip0_data                                                             | */
/*          |                                                                                                | */
/*          |                                p1_data = ip0_data                                              | */

module bram2x(input clk2x,
              input         clk, // clock-divided from clk2x
              input         rst,

              //2x Read ports
              input [31:0]  p0_addr,
              output reg [31:0] p0_data,

              input [31:0]  p1_addr,
              output [31:0] p1_data,

              //1x Write port
              input [31:0]  p2_addr,
              input         p2_we,
              input [31:0]  p2_datain
              );
   
   parameter RAM_DEPTH = 20;
   parameter INIT_FILE = "ram.hex";
   
   wire [31:0]              ip0_addr;
   assign ip0_addr = clk?p0_addr:p1_addr;
   
   wire [31:0]              ip0_data;

   wire [31:0]              ip1_addr;
   assign ip1_addr = p2_addr;

   wire                     ip1_we;
   assign ip1_we = clk?p2_we:0;

   wire [31:0]              ip1_datain;
   assign ip1_datain = p2_datain;
   assign p1_data = ip0_data;
   

   innerdpram #(.RAM_DEPTH(RAM_DEPTH),
                .INIT_FILE(INIT_FILE)) dp (.clk(clk2x),
                  .rst(rst),
                  // Read port
                  .ip0_addr(ip0_addr),
                  .ip0_data(ip0_data),

                  // Write port
                  .ip1_addr(ip1_addr),
                  .ip1_we(ip1_we),
                  .ip1_datain(ip1_datain));

   always @(posedge clk2x)
     if (!rst) begin
        p0_data <= 0;
     end else begin
        if ( ~clk ) begin
           p0_data <= ip0_data;
        end
     end

   

endmodule
              
