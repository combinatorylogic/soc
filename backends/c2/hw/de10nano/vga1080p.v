module vga1080p   (input  clk,      // system clock (100-150mhz)
                   input 	     rst,
                   input [1:0] 	     bufid,
                
                   input 	     clk_vga, // vga pixel clock (148.50MHz)
                
                   output reg [27:0] vbuf_address,
                   output reg [7:0]  vbuf_burstcount,
                   input 	     vbuf_waitrequest,
                   input [127:0]     vbuf_readdata,
                   input 	     vbuf_readdatavalid,
                   output reg 	     vbuf_read,

                   output 	     scan,

                   output [7:0]      LED,
              
              // VGA pins
                   output 	     hsync,
                   output 	     vsync,
                   output 	     dataenable,
                   output [23:0]     rgb // 8bit colour RGB
                );

   // vbuf memory port is 128 bit wide, with an up to 64x burst
   wire [27:0]                vbuf_start;
   assign vbuf_start = {6'b10, bufid, 19'h0};
   
   wire [27:0]                vbuf_address_next;
   reg [27:0]                 vbuf_offset;
   parameter BURST = 16;
   parameter VMEM_END = ((1920 * 1080 * 3) / 16) - BURST; // 128bit-aligned

   reg [27:0] 		      vbuf_readoffset;
   
   
   
   assign vbuf_address_next = vbuf_start + vbuf_offset;
   // vbuf bus is Avalon, so reading sequence is following:
   // 1. Set vbuf_address to a start of a burst, set burstcount and
   //    vbuf_read.
   // 2. Wait for vbuf_waitrequest to be deasserted, then release vbuf_read.
   // 3. Wait for burstcount number of vbuf_readdatavalid, every time
   //    reading 128 bits from the bus and pushing them into the queue.
   //
   // We can only initiate the read when there is enough space in the queue (is half empty any good?)
   //
   // On the other side of the queue we're reading 128bit as soon as they're
   // available AND there are 128bit empty at the end of the shift register.
   // Shift register moves left by 3 bytes each pixel clock cycle, so we need
   // to alternate, reading into bytes 15-0, then after the read counter is > 15,
   // read 17-2, then after the read counter is agaoun > 15, read 16-1,
   // and then again after the read counter is > 15 return to 15-0.

   // ... must start this cycle with 16-1.
   //
   // Every time we shift by 3 bytes, the left read counter is increased by 3 and
   // the right read counter is increased by 3.
   //
   // A useful observation - queue read events happen every 6-7 pixel clock cycles.

   wire [127:0]               inqueue_data;
   reg                        inqueue_re;
   wire                       inqueue_empty;
   wire                       inqueue_full;
   wire                       inqueue_hfull;

   vmem_in_queue1080p q1 (.inclk(clk),
                     .rst(rst),
                     .in_data({vbuf_readdata[63:0],vbuf_readdata[127:64]}),
                     .in_we(vbuf_readdatavalid),
		     
                     .outclk(clk_vga),
                     .out_data(inqueue_data),
                     .out_re(inqueue_re),

                     .empty(inqueue_empty),
                     .hfull(inqueue_hfull),
                     .full(inqueue_full)
                     );

   wire                       can_start_reading;

   assign can_start_reading = ~inqueue_hfull;
   reg [2:0]                  read_st;

   reg [7:0] 		      burstctr;
   
   
   always @(posedge clk)
     if (~rst) begin
        read_st <= 0;
        
        vbuf_offset <= 0;
        vbuf_read <= 0;
	vbuf_burstcount <= 0;
	vbuf_address <= 0;

	burstctr <= 0;
	
     end else begin
        vbuf_address <= vbuf_address_next;
        case (read_st)
          0: if (can_start_reading) begin
             vbuf_burstcount <= BURST; // let's see if we can always read in bursts
             // of this length. There are exactly 48600 bursts of 8 in total
             // for reading one 1920x1080x24b frame buffer.
             vbuf_read <= 1;
             read_st <= 1;
          end
          1: if (~vbuf_waitrequest) begin
             // Avalon request acknowledged, deassert vbuf_read
             vbuf_read <= 0;
             read_st <= 2;
	     burstctr <= 0;
	     
             if (vbuf_offset >= VMEM_END - 1)
               vbuf_offset <= 0;
             else
               vbuf_offset <= vbuf_offset + BURST;
          end
	  2: if (vbuf_readdatavalid) begin // do not start the next transaction until the data is starting to come
	     if (burstctr >= (BURST/2+1)) 
	       read_st <= 0;
	     else
	       burstctr <= burstctr + 1;
	  end
        endcase
     end // else: !if(~rst)



   // Now, the weird shift register on the other side of the queue
   reg [255:0] 		      shiftreg3;
   reg [1:0]   s3_cyc;
   reg [7:0]   s3_counter;
   reg [143:0] shiftreg3_tmp;
   
   wire         s3_shifting;
   wire [143:0] shiftreg3_in_next;
   wire [143:0] shiftreg3_in_next0;
   wire [143:0] shiftreg3_in_next2;
   wire [143:0] shiftreg3_in_next1;
   wire [143:0] shiftreg3_in_next_shift;

   assign shiftreg3_in_next = (s3_cyc==0)?shiftreg3_in_next0:
                              (s3_cyc==2)?shiftreg3_in_next2:
                              shiftreg3_in_next1;
 
   
   assign shiftreg3_in_next0 =
                              {shiftreg3[119:104], inqueue_data[127:0]};
   assign shiftreg3_in_next2 =
                              {inqueue_data[127:0], 16'b0};
   assign shiftreg3_in_next1 =
                              {shiftreg3[119:112], inqueue_data[127:0], 8'b0};

   assign shiftreg3_in_next_shift = {shiftreg3[119:0], 24'b0};

   wire [23:0]  rgb_out;
   reg          s3_init;
   reg          s3_first;
   reg          s3_tmp;
   reg       ready, ready0,ready1;
   reg [23:0] shifttemp0;
   
   always @(posedge clk_vga) begin
      if (~rst) begin
         shiftreg3 <= 0;
         s3_cyc <= 1;
         s3_counter <= 0;
         inqueue_re <= 0;
         s3_tmp <= 0;
         s3_init <= 0;
         s3_first <= 1;
         ready <= 0;
	 ready0 <= 0;
	 ready1 <= 0;
	 
         shifttemp0 <= 0;
         
      end else begin
	 if (ready0) begin
	    ready0 <= 0;
	    
	    ready1 <= 1;
	    
	 end
	 if (ready1) begin
	    ready1 <= 0;

	    ready <= 1;
	    
	 end
	 
         if (s3_first) begin
            if (~inqueue_empty) begin
               s3_first <= 0;
               s3_init <= 1;
	       inqueue_re <= 1;
            end
         end
            
         if (!s3_shifting & inqueue_re) begin // data arrived when we're not shifting (not in a visible area)
            inqueue_re <= 0;
            shiftreg3_tmp <= shiftreg3_in_next;
            s3_tmp <= 1;
         end
	 
	 if (s3_shifting) begin // if (inqueue_re)
            
            shiftreg3[255:144] <= shiftreg3[231:120];
            if (s3_tmp) begin
               // Read from the queue previously but did not shift,
               // so moving it into the register now
               shiftreg3[143:0] <= shiftreg3_tmp;
               s3_tmp <= 0;
            end else begin
	       if (inqueue_re) begin
		  inqueue_re <= 0;
		  shiftreg3[143:0] <= shiftreg3_in_next;
		  if (s3_init) begin
		     s3_cyc <= 1;
		     s3_counter <= 1;
		  end
	       end else begin
		  shiftreg3[143:0] <= shiftreg3_in_next_shift;
	       end
	    end
            
            // Rotate the shift read offset
            if (s3_counter > 9) begin
               inqueue_re <= 1;

	       if (s3_init) begin
		   s3_init <= 0;
		  ready0 <= 1;
	       end
	       
               shifttemp0 <= shifttemp0 + 1;
               if (s3_cyc==1) begin
                  s3_cyc <= 0;
		  s3_counter <= 0;
	       end else if (s3_cyc==0) begin
                  s3_cyc <= 2;
		  s3_counter <= 2;
	       end else if (s3_cyc==2) begin
                  s3_cyc <= 1;
		  s3_counter <= 1;
	       end
            end // if (s3_counter > 12)
	    else if (~inqueue_re) begin
               s3_counter <= s3_counter + 3;
	    end else if (inqueue_re) s3_counter <= s3_cyc;
	    
         end // if (s3_shifting)
      end // else: !if(~rst)
   end // always @ (posedge clk_vga)
   
   assign rgb_out = (s3_shifting?shiftreg3[128+24:128]:24'h0);
   wire      visible;

   /*
Active Pixels       1920
Front Porch           88
Sync Width            44
Back Porch           148
Blanking Total       280
Total Pixels        2200
Sync Polarity        pos

Vertical Timings
Active Lines        1080
Front Porch            4
Sync Width             5
Back Porch            36
Blanking Total        45
Total Lines         1125
Sync Polarity        pos
    */

   wire      hdmi_clk;
   
   assign hdmi_clk = clk_vga;

   reg [11:0] h_total = 12'd2199, h_sync = 12'd43, h_start = 12'd189, h_end = 12'd2109; 
   reg [11:0] v_total = 12'd1124, v_sync = 12'd4, v_start = 12'd40, v_end = 12'd1120; 
   reg [11:0] right = 12'd1920, bottom = 12'd1080; 
   
   reg        pre_vga_de =	1'b0;
   
   reg        v_act = 1'b0;
   reg        v_act_d = 1'b0;
   reg [11:0] v_count = 12'b0;
   
   reg        h_act = 1'b0;
   reg        h_act_d = 1'b0;
   reg [11:0] h_count = 12'b0;
   
   wire       h_max, hs_end, hr_start, hr_end;
   wire       v_max, vs_end, vr_start, vr_end;
   
   assign h_max = h_count == h_total;
   assign hs_end = h_count >= h_sync;
   assign hr_start = h_count == h_start; 
   assign hr_end = h_count == h_end;
   assign v_max = v_count == v_total;
   assign vs_end = v_count >= v_sync;
   assign vr_start = v_count == v_start; 
   assign vr_end = v_count == v_end;
   assign next_frame = h_max && v_max;
   
   
   reg        vga_hs;
   reg        vga_vs;
   reg [24:0] rgb_r;
   reg        vga_de;
   assign hsync = vga_hs;
   assign vsync = vga_vs;
   assign dataenable = vga_de;
   assign rgb =  rgb_r;
   wire       reset_n;
   assign reset_n = rst;
   
   
   always @ (posedge hdmi_clk)
     if (!reset_n)
       begin
	  h_act		<=	1'b0;
	  h_act_d	<=	1'b0;
	  h_count	<=	12'b0;
	  vga_hs	<=	1'b1;
       end
     else
       if (ready) begin
	  h_act_d	<=	h_act;
	  
	  if (h_max)
	    h_count	<=	12'b0;
	  else
	    h_count	<=	h_count + 12'b1;
          
	  if (hs_end && !h_max)
	    vga_hs	<=	1'b1;
	  else
	    vga_hs	<=	1'b0;
          
	  if (hr_start)
	    h_act <=	1'b1;
	  else if (hr_end)
	    h_act <=	1'b0;
       end
   
   always@(posedge hdmi_clk)
     if(!reset_n)
       begin
	  v_act			<= 1'b0;
	  v_act_d		<=	1'b0;
	  v_count		<=	12'b0;
	  vga_vs		<=	1'b1;
       end
     else
       if (ready) begin		
	  if (h_max)
	    begin		 
	       v_act_d	  <=	v_act;		
	       
	       if (v_max)
		 v_count	<=	12'b0;
	       else
		 v_count	<=	v_count + 12'b1;
	       
	       if (vs_end && !v_max)
		 vga_vs	<=	1'b1;
	       else
		 vga_vs	<=	1'b0;
	       
	       if (vr_start)
		 v_act <=	1'b1;
	       else if (vr_end)
		 v_act <=	1'b0;
	    end
       end
   
   assign visible = h_act && v_act;
   assign s3_shifting = ((ready0|ready1|ready)&visible) | s3_init;
   
   always@(posedge hdmi_clk)
     if(!reset_n)
       begin
          rgb_r <= 0;
	  vga_de  <= 1'b0;
	  pre_vga_de <=	1'b0;	
       end
     else if(ready) begin
	vga_de		<=	pre_vga_de;
	pre_vga_de	<=	v_act && h_act;
	rgb_r <= (h_count[4:0] == 5'b10000 || v_count[4:0]==5'b10000)?24'hffffff:rgb_out;
     end
   
endmodule


module vmem_in_queue1080p(input rst,
		     
		     input          inclk,
		     input [127:0]  in_data,
		     input          in_we,

		     output         full,
                     output         hfull,

		     input          outclk,
		     output [127:0] out_data,
		     output         empty,
		     input          out_re);


   vga_fifo_dc#(.AWIDTH(7),.DWIDTH(128)) 
   fifo0(.rclk (outclk),
         .wclk (inclk),
         .rclr (~rst),
         .wclr (~rst),
         .wreq (in_we),
         .d (in_data),
         .rreq (out_re),
         .q (out_data),
         .empty (empty),
         .full (full),
         .hfull (hfull));
   
endmodule
