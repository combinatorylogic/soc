module top;


   reg [31:0] clkcounter;
   initial #0 clkcounter <= 0;
   
 
   reg rst;
   wire inqueue_empty = 0;
   
   reg clk_vga;
   initial #0 rst <= 0;
   initial #200 rst <= 1;
   

   initial #0 clk_vga <= 0;
   
   always #50 begin clk_vga <= !clk_vga; end

   reg [127:0] inqueue_data;
   reg 	       inqueue_re;
   reg [15:0]  xypos;
   
   initial #0 inqueue_data <= {128'h0};

   reg [3:0]   ord;
   
   always @(posedge clk_vga)
     if(~rst) begin
	xypos <= 1;
	
	inqueue_data <= {16'h0, 112'h0};
	clkcounter <= 0;
	ord <= 0;
	
     end else begin
	clkcounter <= clkcounter + 1;
	
	if (inqueue_re) begin
	   inqueue_data <=
			  ord==0?128'heb0000eb0001eb0002eb0003eb0004eb:
			  ord==1?128'h0005eb0006eb0007eb0008eb0009eb00:
			  128'h0aeb000beb000ceb000deb000eeb000f;

	   if (ord == 2) ord <= 0;
	   else if (ord == 1) ord <= 2;
	   else if (ord == 0) ord <= 1;

	   if (xypos >= (57600-1)) xypos <= 0;
	   else xypos <= xypos + 1;

	end
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

   wire [23:0] 	rgb;
   
   wire [23:0]  rgb_out;
   reg          s3_init;
   reg          s3_first;
   reg          s3_tmp;
   reg      ready0, ready;
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
         
      end else begin // if (~rst)
	 if (ready0) begin
	    ready0 <= 0;

	    ready <= 1;
	    
	 end
         if (s3_first) begin
            if (~inqueue_empty) begin
               s3_first <= 0;
               s3_init <= 1;
	       inqueue_re <= 1;
	       //$display("INIT %d", clkcounter);
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
		  $display("shiftreg3[%d] [%5d] = %x %x %x %x" , s3_counter, clkcounter,
			   shiftreg3[63+64*3:0+64*3],
			   shiftreg3[63+64+64:0+64+64],
			   shiftreg3[63+64:0+64], 
			   shiftreg3[63:0]
			   );
		  $display("shiftreg3_next[%d] [%5d] = %x %x %x %x" , s3_counter, clkcounter,
			   shiftreg3_in_next[63+64*3:0+64*3],
			   shiftreg3_in_next[63+64+64:0+64+64],
			   shiftreg3_in_next[63+64:0+64], 
			   shiftreg3_in_next[63:0]
			   );
		  shiftreg3[143:0] <= shiftreg3_in_next;
		  /*
		  $display("First 64 bits = %x", shiftreg3_in_next[63:0]);
		  $display(" next 64 bits = %x", shiftreg3_in_next[63+64:0+64]);
		  $display(" next n bits = %x", shiftreg3_in_next[143:64+64]);
		   */
		  
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
		  $display("READY");
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
   
   assign rgb_out = (shiftreg3[128+24:128]);

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
   reg [31:0] pagecounter;
   
   
   always @(posedge clk_vga)
     if (!rst || !ready) begin // only start banging when there are some bits queued already
        vcounter <= 0;
        hcounter <= 0;
        xxcounter <= 0;
	pagecounter <= 0;
	
     end else begin
        xxcounter <= xxcounter + 1;
        
        
        if (hcounter >= hlen1-1) begin
           hcounter <= 0;
           if (vcounter >= vlen1-1) begin
             vcounter <= 0;
	      pagecounter <= pagecounter + 1;
	      $write("\n\n\n");
	      if (pagecounter == 2)
		$finish;
	      
           end
           else
             vcounter <= vcounter + 1;
        end else hcounter <= hcounter + 1;
     end // else: !if(!rst)

   // While in a visible area, keep sucking bits from the fifo, hoping it is being well fed
   // on the other side.
   assign rgb = visible?rgb_out:0;

   
   assign s3_shifting = ((ready0|ready)&visible) | s3_init;


   always @(posedge clk_vga)
     if (pagecounter == 0) begin
	if (ready&visible && hcounter == 0)
	  $write("\n");
	if ((ready)&visible) begin
	   $display("displaying shiftreg3[%3d][%5d] = %x %x %x %x" , s3_counter, clkcounter,
			   shiftreg3[63+64*3:0+64*3],
			   shiftreg3[63+64+64:0+64+64],
			   shiftreg3[63+64:0+64], 
			   shiftreg3[63:0]
			   );
	   $display("out = %x",rgb); 
//	   $write("|%x",rgb_out[23:0]);
	end


     end
   
endmodule
