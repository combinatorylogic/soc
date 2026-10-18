
// This cache relies on burst reads, therefore cache line width must be a multiple
// of a burst length (8, for all practical purposes).
//
// I.e., filling one cache line requires 8 bursts.

`define DC_WIDTH_BITS 4
`define DC_LINES_BITS 6
`define DC_WIDTH_ZERO 4'b0000
`define DC_WIDTH_ONES 4'b1111

`define DC_WIDTH (1<<`DC_WIDTH_BITS)
`define DC_LINES (1<<`DC_LINES_BITS)

`define BURST_LENGTH 8
`define BURSTS_PER_LINE 2

// 


module dcache_wb(input clk,
                 input             rst,

                 input [31:0]      dbgcounter,

                 // CPU interface, assuming continuous requests, so no need
                 // for a REQ
                 output reg [31:0] dc_data_out,
                 input [31:0]      dc_data_in,
                 input [31:0]      dc_addr_in,
                 input             dc_re, // N.B. - only RE or WE can be set!
                 input             dc_we,
                 output            dc_ack, // an output is valid for the previous ic_addr_in value
                 output            dc_ready, // ready to accept a new ic_addr_in value (and the ic_ack will arrive the next clock cycle, promise)

                 // WB SDRAM interface
                 output reg [31:0] dc_adr_o,
                 output reg        dc_cyc_o,
                 output reg        dc_stb_o,
                 output reg        dc_we_o,
                 output reg [3:0]  dc_sel_o,
                 output reg [2:0]  dc_cti_o,
                 output reg [1:0]  dc_bte_o,
                 output reg [31:0] dc_dat_o,
                 input [31:0]      dc_dat_i,
                 input             dc_ack_i,
                 input             dc_err_i

                 );


   localparam [2:0]
     CTI_CLASSIC      = 3'b000,
     CTI_CONST_BURST  = 3'b001,
     CTI_INC_BURST    = 3'b010,
     CTI_END_OF_BURST = 3'b111;
   
   localparam [1:0]
     BTE_LINEAR  = 2'd0,
     BTE_WRAP_4  = 2'd1,
     BTE_WRAP_8  = 2'd2,
     BTE_WRAP_16 = 2'd3;

   reg [31:0] saved_addr;
   
   reg [31-`DC_WIDTH_BITS+1:0]     dctags[0:`DC_LINES-1];
   reg [31:0]                      cacheram[0:`DC_LINES*`DC_WIDTH-1];
   
   wire [31-`DC_WIDTH_BITS:0]      addrtag;
   
   assign addrtag = dc_addr_in[31:`DC_WIDTH_BITS];
   
   reg [31-`DC_WIDTH_BITS:0]     filladdrtag;
   
   reg [3:0]                       dc_state;
   localparam S_IDLE = 0;
   localparam S_FILL = 1;
   localparam S_SKIP  = 2;
   localparam S_ZERO = 3;
   localparam S_DELAY = 4;

   localparam S_WRITECACHE = 5;
   localparam S_WRITEMEM = 6;

   // Write-through logic is following:
   // if writing hits an existing cache line, we save the write, we go to S_WRITECACHE and then S_WRITEMEM 
   // (of course we could do it in parallel, maybe later)
   // if it's a cache miss, we go to S_WRITEMEM.
   // if writing hits a cache line currently being filled, we save the writing state in a register and won't 
   // raise dc_ready until writing is complete.
   
   reg [3:0]                       dc_fill_counter; // burst counter
   reg [3:0]                       dc_burst_counter; // n of bursts
   reg [`DC_WIDTH_BITS-1:0] dc_line_counter;
   wire [`DC_WIDTH_BITS-1:0] dc_line_counter_next;
   assign dc_line_counter_next = dc_line_counter + 1;
   
      
   wire [31-`DC_WIDTH_BITS+1:0]            dctagsout;
   
   // Watch out for timing here, gonna be shitty.
   // Also, no chance a block ram is inferred for tags.
   assign dctagsout =
      dctags[dc_addr_in[`DC_WIDTH_BITS+`DC_LINES_BITS-1:`DC_WIDTH_BITS]];

   wire                                    dc_ack_w;
   reg                                     dc_ack_r;
   
   assign dc_ack = dc_ack_r;
   assign dc_ready = dc_ack_w;

   // ACKing logic:
   // -  If RE is up, we ACK if it's a direct cache hit or a hit while filling
   // -  if WE is up, we ACK immediately regardless of what's going on,
   //    but only raise READY if:
   //     - Writing was not a cache hit
   //     - Writing was a cache hit in a full cache line, and S_WRITECACHE run
   //       is complete.
   //     - Writing was a cache hit in an incomplete cache line, so S_WRITECACHE
   //       was delayed and READY is raised when it's done.
   //    In other words, no cache hit -> READY
   //    Had cache hit - READY after S_WRITECACHE is complete.

   wire                                    dc_ack_w_re;
   
   assign dc_ack_w_re = (dctagsout == {1'b1, addrtag}) || (addrtag == filladdrtag && dc_addr_in[`DC_WIDTH_BITS+`DC_LINES_BITS-1:0] < dc_line_counter);
   
   
   assign dc_ack_w = (dc_re && dc_ack_w_re && ~dc_delay_wr) | ... ;
   
                    

   
   always @(posedge clk)
     if (!rst) begin
        dc_data_out <= 0;
        dc_ack_r <= 0;
     end else begin
        // TODO: at the moment we do not terminate the cache line filling even if 
        // it's going to be eviced by the current request.

        
        if (dc_re && dc_ack_w_re && ~dc_delay_wr)
          begin
             //$display("ACK@%d for %d", dbgcounter, dc_addr_in);
             
             dc_data_out <= cacheram[dc_addr_in[`DC_WIDTH_BITS+`DC_LINES_BITS-1:0]];
          end
        else begin
           //$display("not ack {%d}{%d} @ %d -- %d", ictagsout, addrtag, dbgcounter, ic_addr_in[`DC_WIDTH_BITS+`DC_LINES_BITS-1:`DC_WIDTH_BITS]);
           
        end

        dc_ack_r <= dc_ack_w;
     end

   reg [31:0] dc_zero_ctr;
   

   always @(posedge clk)
     if (!rst) begin
        dc_adr_o <= 0;
        dc_cyc_o <= 0;
        dc_stb_o <= 0;
        dc_we_o <= 0;
        dc_sel_o <= 0;

        dc_cti_o <= CTI_INC_BURST;
        dc_bte_o <= BTE_LINEAR;

        dc_state <= S_ZERO;
        filladdrtag <= 0;

        saved_addr <= 0;
        dc_line_counter <= 0;

        dc_fill_counter <= 0;
        dc_burst_counter <= 0;
        
                            
        dc_zero_ctr <= 0;
        
     end else begin // if (!rst)
        begin
           // cache miss:
           // Either this line is empty, occupied by something else, or being
           // already filled at this moment

           case (dc_state)
             S_ZERO: begin // fill tag memory with 0s
                if (dc_zero_ctr == `DC_LINES) dc_state <= S_IDLE;
                else begin
                   dctags[dc_zero_ctr] <= 0;
                   dc_zero_ctr <= dc_zero_ctr + 1;
                end
             end
             S_IDLE: 
               // That's a new miss, must invalidate the line and start filling
               if (dc_re) begin
                  if (dctagsout != {1'b1, addrtag}) begin
                     dc_state <= S_FILL;
                     // Invalidate the cache line
                     saved_addr <= dc_addr_in;
                     
                     dctags[dc_addr_in[`DC_WIDTH_BITS+`DC_LINES_BITS-1:`DC_WIDTH_BITS]] <= 3;
                     filladdrtag <= addrtag; // filling this line now
                     dc_line_counter <= 0; // no words received so far
                     
                     // Act as a true Wishbone master from now on
                     // set the addr at the beginning of line
                     dc_adr_o <= {dc_addr_in[31:`DC_WIDTH_BITS],`DC_WIDTH_ZERO}<<2;
                     dc_stb_o <= 1;
                     dc_cyc_o <= 1;
                     dc_sel_o <= 4'b1111;
                     dc_cti_o <= CTI_INC_BURST;
                     //$display("S_IDLE for %d-%d; dctagsout=%b, addrtag=%b", dc_addr_in, addrtag, dctagsout, addrtag);
                     
                  end // if (dctagsout != {1'b1, addrtag})
               end else if (dc_we) begin // if (dc_re)
                  dc_w_ack <= 1;
                  if (dctagsout == {1'b1, addrtag}) begin
                     // It's a cache hit
                     dc_wr_addr <= dc_addr_in;
                     dc_wr_value <= dc_data_in;
                     dc_state <= S_WRITECACHE;
                  end else begin // cannot hit partially filled when IDLE
                     dc_w_ready <= 1;
                     
                     // Not a hit - writing to low mem directly,
                     // raising READY and ACK.
                     dc_adr_o <= dc_addr_in;
                     dc_sel_o <= 4'b1111;
                     dc_dat_o <= dc_data_in;
                     dc_we_o  <= 1;
                     dc_cti_o <= CTI_CLASSIC;
                     dc_state <= S_WRITEMEM;
                  end
               end // if (dc_we)

             S_WRITECACHE: begin
                cacheram[dc_wr_addr[`DC_LINES_BITS+`DC_WIDTH_BITS-1:0]] <= dc_wr_value;
                dc_w_ready <= 1;
                     
                // Not a hit - writing to low mem directly,
                // raising READY and ACK.
                dc_adr_o <= dc_wr_addr;
                dc_sel_o <= 4'b1111;
                dc_dat_o <= dc_wr_value;
                dc_we_o  <= 1;
                dc_cti_o <= CTI_CLASSIC;
                dc_state <= S_WRITEMEM;
             end
               
             S_WRITEMEM: // wait for ack
               if (dc_ack_i) begin
                  dc_state <= S_IDLE;
                  dc_adr_o <= 0;
                  dc_cyc_o <= 0;
                  dc_stb_o <= 0;
                  dc_we_o <= 0;
                  dc_sel_o <= 0;
                  
                  dc_cti_o <= CTI_INC_BURST;
                  dc_bte_o <= BTE_LINEAR;
                  dc_w_ready <= 1; // if only finished now
               end
             S_FILL:
               // If writing while filling:
               if (dc_we && ~dc_delay_wr) begin
                  dc_delay_wr <= 1;
                  dc_wr_addr <= dc_addr_in;
                  dc_wr_value <= dc_data_in;
                  dc_w_ack <= 1; // ack but not ready!
               end
               
               // We're waiting for an ack to start a burst
               if (dc_ack_i) begin
                  //$display("S_FILL got ack for %d, filling %d (%d): %d - %d", dc_addr_in, dc_line_counter, dc_fill_counter, filladdrtag, saved_addr);
                  /*
                  $display("cache[%d:%d] for %d <= %d {%d}   [%d,%d,%d] @ %d / %b", {saved_addr[`DC_LINES_BITS+`DC_WIDTH_BITS-1:`DC_WIDTH_BITS], dc_line_counter[`DC_WIDTH_BITS-1:0]}, saved_addr, {saved_addr[31:`DC_WIDTH_BITS],`DC_WIDTH_ZERO} + dc_line_counter, dc_dat_i, dc_adr_o + dc_line_counter,
                           dc_line_counter, dc_fill_counter, dc_burst_counter, dbgcounter, dc_cti_o
                           );
                   */
                  
                  // This is where cache lines are filled
                  cacheram[{saved_addr[`DC_LINES_BITS+`DC_WIDTH_BITS-1:`DC_WIDTH_BITS], dc_line_counter}] <= dc_dat_i;
                  if (dc_fill_counter == `BURST_LENGTH - 2) begin
                     dc_cti_o <= CTI_END_OF_BURST;
                     dc_fill_counter <= dc_fill_counter + 1;
                     dc_line_counter <= dc_line_counter_next;
                  end else
                  if (dc_fill_counter == `BURST_LENGTH - 1) begin
                     if (dc_burst_counter < `BURSTS_PER_LINE - 1) begin
                        dc_state <= S_DELAY;
                        dc_cti_o <= CTI_INC_BURST;
                        dc_burst_counter <= dc_burst_counter + 1;
                        dc_fill_counter <= 0;
                        dc_line_counter <= dc_line_counter_next;
                        dc_adr_o <= {saved_addr[31:`DC_WIDTH_BITS], dc_line_counter_next[`DC_WIDTH_BITS-1:0]}<<2;
                     end else begin
                        // done here, may probably waste a cycle until we actually handle the next cache miss
                        dc_stb_o <= 0;
                        dc_cyc_o <= 0;
                        dc_sel_o <= 0;
                        // Mark the cache line valid
                        dctags[saved_addr[`DC_WIDTH_BITS+`DC_LINES_BITS-1:`DC_WIDTH_BITS]] <= {1'b1, filladdrtag};
                        
                        //$display("ITAGS [%d] <= %b", saved_addr[`DC_WIDTH_BITS+`DC_LINES_BITS-1:`DC_WIDTH_BITS], {1'b1, filladdrtag});
                        
                        dc_line_counter <= 0;
                        dc_fill_counter <= 0;
                        dc_burst_counter <= 0;
                        dc_state <= S_SKIP;
                        filladdrtag <= 0;
                     end
                  end else begin // if (dc_fill_counter == `BURST_LENGTH - 1)
                     dc_fill_counter <= dc_fill_counter + 1;
                     dc_line_counter <= dc_line_counter_next;
                  end
               end // if (dc_ack_i)
             // TODO: handle WB error / retry states
             S_SKIP: begin
                if (dc_delay_wr) begin
                   // We have a delayed cache write in waiting
                   dc_state <= S_WRITECACHE;
                end else dc_state <= S_IDLE;
             end
             S_DELAY: dc_state <= S_FILL;
             
           endcase // case (dc_state)
        end // if (dctagsout != {1'b1, addrtag} || dc_state == S_FILL)
     end

endmodule

