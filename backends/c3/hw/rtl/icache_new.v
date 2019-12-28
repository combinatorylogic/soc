
// This cache relies on burst reads, therefore cache line width must be a multiple
// of a burst length (8, for all practical purposes).
//
// I.e., filling one cache line requires 8 bursts.

`define IC_WIDTH_BITS 4
`define IC_LINES_BITS 6
`define IC_WIDTH_ZERO 4'b0000
`define IC_WIDTH_ONES 4'b1111

`define IC_WIDTH (1<<`IC_WIDTH_BITS)
`define IC_LINES (1<<`IC_LINES_BITS)

`define BURST_LENGTH 8
`define BURSTS_PER_LINE 2




module icache_wb(input clk,
                 input             rst,

                 input [31:0]      dbgcounter,

                 // CPU interface, assuming continuous requests, so no need
                 // for a REQ
                 output reg [31:0] ic_data_out,
                 input [31:0]      ic_addr_in,
                 output            ic_ack, // an output is valid for the previous ic_addr_in value
                 output            ic_ready, // ready to accept a new ic_addr_in value (and the ic_ack will arrive the next clock cycle, promise)

                 // WB SDRAM interface
                 output reg [31:0] ic_adr_o,
                 output reg        ic_cyc_o,
                 output reg        ic_stb_o,
                 output reg        ic_we_o,
                 output reg [3:0]  ic_sel_o,
                 output reg [2:0]  ic_cti_o,
                 output reg [1:0]  ic_bte_o,
                 input [31:0]      ic_dat_i,
                 input             ic_ack_i,
                 input             ic_err_i

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
   
   reg [31-`IC_WIDTH_BITS+1:0]     ictags[0:`IC_LINES-1];
   reg [31:0]                      cacheram[0:`IC_LINES*`IC_WIDTH-1];
   
   wire [31-`IC_WIDTH_BITS:0]      addrtag;
   
   assign addrtag = ic_addr_in[31:`IC_WIDTH_BITS];
   
   reg [31-`IC_WIDTH_BITS:0]     filladdrtag;
   
   reg [2:0]                       ic_state;
   localparam S_IDLE = 0;
   localparam S_FILL = 1;
   localparam S_SKIP  = 2;
   localparam S_ZERO = 3;
   localparam S_DELAY = 4;
   
   
   
   reg [3:0]                       ic_fill_counter; // burst counter
   reg [3:0]                       ic_burst_counter; // n of bursts
   reg [`IC_WIDTH_BITS-1:0] ic_line_counter;
   wire [`IC_WIDTH_BITS-1:0] ic_line_counter_next;
   assign ic_line_counter_next = ic_line_counter + 1;
   
      
   wire [31-`IC_WIDTH_BITS+1:0]            ictagsout;
   
   // Watch out for timing here, gonna be shitty.
   // Also, no chance a block ram is inferred for tags.
   assign ictagsout =
      ictags[ic_addr_in[`IC_WIDTH_BITS+`IC_LINES_BITS-1:`IC_WIDTH_BITS]];

   wire                                    ic_ack_w;
   reg                                     ic_ack_r;
   
   assign ic_ack = ic_ack_r;
   assign ic_ready = ic_ack_w;
   
   assign ic_ack_w = (ictagsout == {1'b1, addrtag}) || (addrtag == filladdrtag && ic_addr_in[`IC_WIDTH_BITS+`IC_LINES_BITS-1:0] < ic_line_counter);
   
                   

   
   always @(posedge clk)
     if (!rst) begin
        ic_data_out <= 0;
        ic_ack_r <= 0;
     end else begin
        // TODO: at the moment we do not terminate the cache line filling even if 
        // it's going to be eviced by the current request.
        
        if (ic_ack_w)
          begin
             //$display("ACK@%d for %d", dbgcounter, ic_addr_in);
             
             ic_data_out <= cacheram[ic_addr_in[`IC_WIDTH_BITS+`IC_LINES_BITS-1:0]];
          end
        else begin
           //$display("not ack {%d}{%d} @ %d -- %d", ictagsout, addrtag, dbgcounter, ic_addr_in[`IC_WIDTH_BITS+`IC_LINES_BITS-1:`IC_WIDTH_BITS]);
           
        end

        ic_ack_r <= ic_ack_w;
     end

   reg [31:0] ic_zero_ctr;
   

   always @(posedge clk)
     if (!rst) begin
        ic_adr_o <= 0;
        ic_cyc_o <= 0;
        ic_stb_o <= 0;
        ic_we_o <= 0;
        ic_sel_o <= 0;

        ic_cti_o <= CTI_INC_BURST;
        ic_bte_o <= BTE_LINEAR;

        ic_state <= S_ZERO;
        filladdrtag <= 0;

        saved_addr <= 0;
        ic_line_counter <= 0;

        ic_fill_counter <= 0;
        ic_burst_counter <= 0;
        
                            
        ic_zero_ctr <= 0;
        
     end else begin // if (!rst)
        //$display("tagsout1[%d]=%b vs %b {%b}!", ic_addr_in[`IC_WIDTH_BITS+`IC_LINES_BITS-1:`IC_WIDTH_BITS], ictagsout, {1'b1, addrtag}, ictagsout != {1'b1, addrtag});
        begin // cache miss
           // Either this line is empty, occupied by something else, or being
           // already filled at this moment

           case (ic_state)
             S_ZERO: begin // fill tag memory with 0s
                if (ic_zero_ctr == `IC_LINES) ic_state <= S_IDLE;
                else begin
                   ictags[ic_zero_ctr] <= 0;
                   ic_zero_ctr <= ic_zero_ctr + 1;
                end
             end
             S_IDLE: 
               // That's a new miss, must invalidate the line and start filling
               if (ictagsout != {1'b1, addrtag}) begin
                  ic_state <= S_FILL;
                  // Invalidate the cache line
                  saved_addr <= ic_addr_in;
                  
                  ictags[ic_addr_in[`IC_WIDTH_BITS+`IC_LINES_BITS-1:`IC_WIDTH_BITS]] <= 3;
                  filladdrtag <= addrtag; // filling this line now
                  ic_line_counter <= 0; // no words received so far
                  
                  // Act as a true Wishbone master from now on
                  // set the addr at the beginning of line
                  ic_adr_o <= {ic_addr_in[31:`IC_WIDTH_BITS],`IC_WIDTH_ZERO}<<2;
                  ic_stb_o <= 1;
                  ic_cyc_o <= 1;
                  ic_sel_o <= 4'b1111;
                  ic_cti_o <= CTI_INC_BURST;
                  //$display("S_IDLE for %d-%d; ictagsout=%b, addrtag=%b", ic_addr_in, addrtag, ictagsout, addrtag);
                  
               end
             S_FILL:
               // We're waiting for an ack to start a burst
               if (ic_ack_i) begin
                  //$display("S_FILL got ack for %d, filling %d (%d): %d - %d", ic_addr_in, ic_line_counter, ic_fill_counter, filladdrtag, saved_addr);
                  /*
                  $display("cache[%d:%d] for %d <= %d {%d}   [%d,%d,%d] @ %d / %b", {saved_addr[`IC_LINES_BITS+`IC_WIDTH_BITS-1:`IC_WIDTH_BITS], ic_line_counter[`IC_WIDTH_BITS-1:0]}, saved_addr, {saved_addr[31:`IC_WIDTH_BITS],`IC_WIDTH_ZERO} + ic_line_counter, ic_dat_i, ic_adr_o + ic_line_counter,
                           ic_line_counter, ic_fill_counter, ic_burst_counter, dbgcounter, ic_cti_o
                           );
                   */
                  
                  // This is where cache lines are filled
                  cacheram[{saved_addr[`IC_LINES_BITS+`IC_WIDTH_BITS-1:`IC_WIDTH_BITS], ic_line_counter}] <= ic_dat_i;
                  if (ic_fill_counter == `BURST_LENGTH - 2) begin
                     ic_cti_o <= CTI_END_OF_BURST;
                     ic_fill_counter <= ic_fill_counter + 1;
                     ic_line_counter <= ic_line_counter_next;
                  end else
                  if (ic_fill_counter == `BURST_LENGTH - 1) begin
                     if (ic_burst_counter < `BURSTS_PER_LINE - 1) begin
                        ic_state <= S_DELAY;
                        ic_cti_o <= CTI_INC_BURST;
                        ic_burst_counter <= ic_burst_counter + 1;
                        ic_fill_counter <= 0;
                        ic_line_counter <= ic_line_counter_next;
                        ic_adr_o <= {saved_addr[31:`IC_WIDTH_BITS], ic_line_counter_next[`IC_WIDTH_BITS-1:0]}<<2;
                     end else begin
                        // done here, may probably waste a cycle until we actually handle the next cache miss
                        ic_stb_o <= 0;
                        ic_cyc_o <= 0;
                        ic_sel_o <= 0;
                        // Mark the cache line valid
                        ictags[saved_addr[`IC_WIDTH_BITS+`IC_LINES_BITS-1:`IC_WIDTH_BITS]] <= {1'b1, filladdrtag};
                        
                        //$display("ITAGS [%d] <= %b", saved_addr[`IC_WIDTH_BITS+`IC_LINES_BITS-1:`IC_WIDTH_BITS], {1'b1, filladdrtag});
                        
                        ic_line_counter <= 0;
                        ic_fill_counter <= 0;
                        ic_burst_counter <= 0;
                        ic_state <= S_SKIP;
                        filladdrtag <= 0;
                     end
                  end else begin // if (ic_fill_counter == `BURST_LENGTH - 1)
                     ic_fill_counter <= ic_fill_counter + 1;
                     ic_line_counter <= ic_line_counter_next;
                  end
               end // if (ic_ack_i)
             // TODO: handle WB error / retry states
             S_SKIP: ic_state <= S_IDLE;
             S_DELAY: ic_state <= S_FILL;
             
           endcase // case (ic_state)
        end // if (ictagsout != {1'b1, addrtag} || ic_state == S_FILL)
     end

endmodule

