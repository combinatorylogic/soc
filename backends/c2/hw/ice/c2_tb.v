`timescale 1 ns / 1 ps
module testbench;


   reg clk = 1;
   always #5 clk = ~clk;


   wire LED1, LED2, LED3, LED4, LED5, LED6, LED7, LED8;

   wire [7:0] LEDS;

   assign LEDS = {LED8, LED7, LED6, LED5, LED4, LED3, LED2, LED1};
   

   wire dummy;
   reg  rdummy;
   reg  rst;
   
   always @(posedge clk) rdummy <= dummy;

   reg [31:0] clkcounter;
   reg [7:0]  prev_LED;
   
   always @(posedge clk)
     if (rst) clkcounter <= clkcounter + 1; else clkcounter <= 0;
   
   top soc ( .sys_clk_in(clk),
	     .LED1(LED1),
	     .LED2(LED2),
	     .LED3(LED3),
	     .LED4(LED4),
	     .LED5(LED5),
	     .LED6(LED6),
	     .LED7(LED7),
	     .LED8(LED8),
             .RX(1'b0),
             .TX(dummy),
             .sys_reset(rst)
             );
   

   	initial begin
           rst <= 0;
           prev_LED <= 0;
           
           repeat (50) @(posedge clk);
           rst <= 1;
	end

   always @(posedge clk)
     if (rst) begin
        if (LEDS != prev_LED) begin
           $display("LED=%b @ %d", LEDS, clkcounter);
           prev_LED <= LEDS;
        end
        if (clkcounter > 1000) $finish;
        
     end

endmodule
