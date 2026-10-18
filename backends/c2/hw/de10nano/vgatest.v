module vga640x480x(input  clk,      // system clock (100-150mhz)
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
   parameter BURST = 8;
   parameter VMEM_END = ((640 * 480 * 3) / 16) - BURST; // 128bit-aligned

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
   //
   // Also, I'm an idiot and we must start this cycle with 16-1.
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
   
   reg  [7:0] 		      vbuf_oddline;
   reg 	[1:0]		      altern;
   
   vmem_in_queue q1 (.inclk(clk),
                     .rst(rst),
                     .in_data(vbuf_readdata),
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

   reg [27:0] 		      vbuf_linecount;
   reg [7:0] 		      burstctr;
   
   
   always @(posedge clk)
     if (~rst) begin
        read_st <= 0;
        
        vbuf_offset <= 0;
        vbuf_read <= 0;
	vbuf_burstcount <= 0;
	vbuf_address <= 0;
	vbuf_readoffset <= 0;
	vbuf_linecount <= 0;
	
	vbuf_oddline <= 0;
	altern <= 0;
	burstctr <= 0;
	
     end else begin
        vbuf_address <= vbuf_address_next;


	if (vbuf_readdatavalid) begin
	   if(altern == 2) altern <= 0;
	   else altern <= altern+1;
	   
	   if(vbuf_readoffset >= ((640 * 480 * 3) / 16) - 1) begin
	      vbuf_readoffset <= 0;
	      vbuf_oddline <= 0;
	      vbuf_linecount <= 0;
	      altern <= 0;
	   end else begin
	      vbuf_readoffset <= vbuf_readoffset + 1;
	      if(vbuf_linecount >= (120 - 1)) begin
		 vbuf_linecount <= 0;
		 if (vbuf_oddline == 30) vbuf_oddline <= 0;
		 else vbuf_oddline <= vbuf_oddline + 1;
	      end else vbuf_linecount <= vbuf_linecount + 1;
	   end
	end
	
        case (read_st)
          0: if (can_start_reading) begin
             vbuf_burstcount <= BURST; // let's see if we can always read in bursts
             // of this length. There are exactly 6075 bursts in total
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
     end

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
   reg       ready, ready0;
   reg [23:0] shifttemp0;
   
   

   // Ok, what to do if we're shifting out of area on this clock cycle, reading
   // on the next but not shifting?
   //
   // read into temp register, use it at the next shift?
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
	 
         shifttemp0 <= 0;
         
      end else begin
	 if (ready0) begin
	    ready0 <= 0;
	    
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
		  ready <= 1;
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
   
   //// bang pixels
   reg [10:0] hcounter;
   
   assign rgb_out = /*(vcounter == 100 || hcounter == 48 || hcounter == 96)?32'hffffffff:*/
		    (s3_shifting?shiftreg3[255:232]:24'h0);

   reg [10:0] vcounter;
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


   parameter hlen = 640;
   parameter hpulse = 96;
   parameter hfp = 16;
   parameter hbp = 48;
   parameter vlen = 480;
   parameter vfp = 10;
   parameter vbp = 33;
   parameter vpulse = 2;

   parameter hlen1 = hlen + hpulse + hfp + hbp;
   parameter vlen1 = vlen + vpulse + vfp + vbp;
   
  
   assign hsync = ~((hcounter > hlen+hfp) & (hcounter < hlen+hfp+hpulse));
   assign vsync = ~((vcounter > vlen+vfp) & (vcounter < vlen+vfp+vpulse));

   assign scan = vcounter == 0;
   
   assign visible = (hcounter < hlen)&&(vcounter < vlen);
   assign dataenable = visible;

   reg [31:0] xxcounter;
   
   always @(posedge clk_vga)
     if (!rst || !ready) begin // only start banging when there are some bits queued already
        vcounter <= 0;
        hcounter <= 0;
        xxcounter <= 0;
     end else begin
        xxcounter <= xxcounter + 1;
        
        
        if (hcounter >= hlen1-1) begin
           hcounter <= 0;
           if (vcounter >= vlen1-1) begin
             vcounter <= 0;
           end
           else
             vcounter <= vcounter + 1;
        end else hcounter <= hcounter + 1;
     end // else: !if(!rst)

   // While in a visible area, keep sucking bits from the fifo, hoping it is being well fed
   // on the other side.
   assign rgb = visible?rgb_out:0;

   
   assign s3_shifting = ((ready0|ready)&visible) | s3_init;
   
endmodule


module vmem_in_queue(input rst,
		     
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
