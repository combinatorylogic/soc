`timescale 1 ns / 1 ps
module testbench;


   reg clk = 1;
   always #5 clk = ~clk;


   wire LED1, LED2, LED3, LED4, LED5, LED6, LED7, LED8;

   wire dummy;
   reg  rdummy;
   always @(posedge clk) rdummy <= dummy;
   
   top soc ( .clk(clk),
	     .LED1(LED1),
	     .LED2(LED2),
	     .LED3(LED3),
	     .LED4(LED4),
	     .LED5(LED5),
	     .LED6(LED6),
	     .LED7(LED7),
	     .LED8(LED8),
             .RXD(1'b0),
             .TXD(dummy),
             .rst(1'b0)
             );
   

   	initial begin
	   $monitor(LED8, LED7, LED6, LED5, LED4, LED3, LED2, LED1);
	   repeat (100000) @(posedge clk);
	   $finish;
	end

endmodule
