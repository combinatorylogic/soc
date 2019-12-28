/* It's not actually a real blit at the moment as it does not handle rectangular shapes yet.
   Still have to think on how to do it properly. Rectangle width must be multiples of COMPUTE_OUT_FULL_WIDTH / BLIT_WIDTH. 
 */


/*  Common parameters for all blit cores:
 COMPUTE_OUT_FULL_WIDTH
 BLIT_ADDR_WIDTH
 BLIT_WIDTH
 */

module vmem_blit(input clk,
                 input                              rst,

                 input                              req,
                 input [COMPUTE_OUT_FULL_WIDTH-1:0] data_in,
                 input [BLIT_ADDR_WIDTH-1:0]        data_addr,

                 output reg                         ready,

                 input                              w_ready,
                 output reg [BLIT_WIDTH-1:0]        data_out,
                 output reg [BLIT_ADDR_WIDTH-1:0]   addr_out,
                 output reg                         we,
                 input [7:0]                        burst_count,
                 input                              extrain,
                 output                             extraout                            );

   parameter COMPUTE_OUT_FULL_WIDTH = 64;
   parameter BLIT_ADDR_WIDTH = 16;
   parameter BLIT_WIDTH = 8;

   parameter STEPS = COMPUTE_OUT_FULL_WIDTH / BLIT_WIDTH;
   parameter STEPS_COUNT = STEPS;

   reg [15:0]                                       steps;
   reg [COMPUTE_OUT_FULL_WIDTH-1:0]                 data_temp;

   reg [31:0]                                       clkcounter;

   always @(posedge clk)
     if (~rst) clkcounter <= 0;
     else clkcounter <= clkcounter + 1;
   
   

   /*
    
    On req, if w_ready - send the first word to the destination and
    shift the input data into a temp register, or copy input data into 
    a temp register if w_ready is not set. Set address register accordingly.
    
    When writing, send and shift temp register every cycle w_ready is set,
    incrementing the address. Once done, set ready to 1 again.
    
    */
   always @(posedge clk) 
     if (~rst) begin
        ready <= 1;
        we <= 0;
        data_out <= 0;
        addr_out <= 0;
        steps <= 0;
     end else begin
        if (ready & req) begin
           `ifdef DEBUGOUT
           $display("BLIT STARTED @ %d", clkcounter);
           `endif
           
           ready <= 0;
           if (w_ready) begin
              `ifdef DEBUGOUTX
              $display("BLIT STEP 0: {%b} / %d", data_in[COMPUTE_OUT_FULL_WIDTH-1:COMPUTE_OUT_FULL_WIDTH-1-BLIT_WIDTH], BLIT_WIDTH);
              `endif
 
              data_out <= data_in[COMPUTE_OUT_FULL_WIDTH-1:COMPUTE_OUT_FULL_WIDTH-1-BLIT_WIDTH];
              addr_out <= data_addr;
              data_temp <= data_in[COMPUTE_OUT_FULL_WIDTH-1-BLIT_WIDTH:0] << BLIT_WIDTH;
              we <= 1;
              steps <= 1;
           end else begin
              data_temp <= data_in;
              steps <= 0;
           end
        end else if (~ready) begin // if (ready & req)
           // writing
           if (w_ready) begin
              `ifdef DEBUGOUTX
              $display("BLIT STEP {%d/%d -%d,%d} {%x} {%b}", steps, STEPS_COUNT,
                       COMPUTE_OUT_FULL_WIDTH, BLIT_WIDTH,
                       addr_out,
                       data_temp[COMPUTE_OUT_FULL_WIDTH-1:COMPUTE_OUT_FULL_WIDTH-1-BLIT_WIDTH]);
              `endif
              we <= 1;
              
              data_out <= data_temp[COMPUTE_OUT_FULL_WIDTH-1:COMPUTE_OUT_FULL_WIDTH-1-BLIT_WIDTH];
              addr_out <= addr_out + 1; // Do we need a custom increment here?
              data_temp <= data_temp[COMPUTE_OUT_FULL_WIDTH-1-BLIT_WIDTH:0] << BLIT_WIDTH;
              steps <= steps + 1;

              if (steps == STEPS_COUNT) begin
                 ready <= 1;
              end
           end else begin // otherwise wait for w_ready
              we <= 0;
           end
        end else begin // if (~ready)
           we <= 0;
           data_out <= 0;
           addr_out <= 0;
           steps <= 0;
        end
     end

endmodule

