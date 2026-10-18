/* Memory mapped modules */

wire clk2x;
wire clkin;
// suplly it with a 4x clock, to ensure clk and clk2x are synchronized
reg [1:0] clkdiv;
assign clk = clkdiv[1];
assign clk2x = clkdiv[0];

initial begin
   clkdiv <= 0;
end
   

always @(posedge clkin)
  if (~sys_reset) clkdiv <= 0;
  else begin
     clkdiv[1:0] <= clkdiv + 1;
  end

`ifdef ICE_DEBUG
wire [7:0] PCdebug;

assign PCdebug1 = PCdebug[0];
assign PCdebug2 = PCdebug[1];
assign PCdebug3 = PCdebug[2];
assign PCdebug4 = PCdebug[3];
assign PCdebug5 = PCdebug[4];
assign PCdebug6 = PCdebug[5];
assign PCdebug7 = PCdebug[6];
assign PCdebug8 = PCdebug[7];
`endif //  `ifdef ICE_DEBUG
   

// We cannot simulate PLL:
`ifdef ICE_ROUTED_SIM
   assign clkin = sys_clk_in;
`else
SB_PLL40_CORE #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0000),		// DIVR =  0
		.DIVF(7'b0111111),	// DIVF = 63
		.DIVQ(3'b011),		// DIVQ =  3
		.FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(sys_clk_in),
		.PLLOUTCORE(clkin)
		);
`endif

reg [17:0] resetcounter;

initial begin
   resetcounter <= 0;
end

   always @(posedge clk)
     if (~sys_reset) resetcounter <= 0;
     else
     if (!rst) resetcounter <= resetcounter + 1;
   
   assign rst = resetcounter[2];
   
   wire [7:0]           LED;
   wire [7:0]           LEDr;

   outpin led0 (.clk(clk), .we(1'b1), .pin(LED1), .wd(LED[0]), .rd(LEDr[0]));
   outpin led1 (.clk(clk), .we(1'b1), .pin(LED2), .wd(LED[1]), .rd(LEDr[1]));
   outpin led2 (.clk(clk), .we(1'b1), .pin(LED3), .wd(LED[2]), .rd(LEDr[2]));
   outpin led3 (.clk(clk), .we(1'b1), .pin(LED4), .wd(LED[3]), .rd(LEDr[3]));
   outpin led4 (.clk(clk), .we(1'b1), .pin(LED5), .wd(LED[4]), .rd(LEDr[4]));
   outpin led5 (.clk(clk), .we(1'b1), .pin(LED6), .wd(LED[5]), .rd(LEDr[5]));
   outpin led6 (.clk(clk), .we(1'b1), .pin(LED7), .wd(LED[6]), .rd(LEDr[6]));
   outpin led7 (.clk(clk), .we(1'b1), .pin(LED8), .wd(LED[7]), .rd(LEDr[7]));

`ifdef ICE_STEPPERS
wire [3:0] STEPPER1;
wire [3:0] STEPPER2;
wire [3:0] STEPPER3;
wire [3:0] STEPPER4;

   outpin2 st10 (.clk(clk), .we(1'b1), .pin(STEPPERX1[0]), .wd(STEPPER1[0]) );
   outpin2 st11 (.clk(clk), .we(1'b1), .pin(STEPPERX1[1]), .wd(STEPPER1[1]) );
   outpin2 st12 (.clk(clk), .we(1'b1), .pin(STEPPERX1[2]), .wd(STEPPER1[2]) );
   outpin2 st13 (.clk(clk), .we(1'b1), .pin(STEPPERX1[3]), .wd(STEPPER1[3]) );

   outpin2 st20 (.clk(clk), .we(1'b1), .pin(STEPPERX2[0]), .wd(STEPPER2[0]) );
   outpin2 st21 (.clk(clk), .we(1'b1), .pin(STEPPERX2[1]), .wd(STEPPER2[1]) );
   outpin2 st22 (.clk(clk), .we(1'b1), .pin(STEPPERX2[2]), .wd(STEPPER2[2]) );
   outpin2 st23 (.clk(clk), .we(1'b1), .pin(STEPPERX2[3]), .wd(STEPPER2[3]) );

   outpin2 st30 (.clk(clk), .we(1'b1), .pin(STEPPERX3[0]), .wd(STEPPER3[0]) );
   outpin2 st31 (.clk(clk), .we(1'b1), .pin(STEPPERX3[1]), .wd(STEPPER3[1]) );
   outpin2 st32 (.clk(clk), .we(1'b1), .pin(STEPPERX3[2]), .wd(STEPPER3[2]) );
   outpin2 st33 (.clk(clk), .we(1'b1), .pin(STEPPERX3[3]), .wd(STEPPER3[3]) );

   outpin2 st40 (.clk(clk), .we(1'b1), .pin(STEPPERX4[0]), .wd(STEPPER4[0]) );
   outpin2 st41 (.clk(clk), .we(1'b1), .pin(STEPPERX4[1]), .wd(STEPPER4[1]) );
   outpin2 st42 (.clk(clk), .we(1'b1), .pin(STEPPERX4[2]), .wd(STEPPER4[2]) );
   outpin2 st43 (.clk(clk), .we(1'b1), .pin(STEPPERX4[3]), .wd(STEPPER4[3]) );


`endif

   ledwriter ledwr1 (.clk(clk),
                     .rst(rst),
                     
                     .LED(LED),
                     
                     .addr_b(ram_addr_in_b),
                     .data_b_in(ram_data_out_b),
                     .data_b_we(ram_we_out));


   wire [31:0]     data_bus_in_uart;
   wire            data_bus_strobe_uart;

`ifdef ENABLE_UART

   uartmm uart1(.clk(clk),
                .rst(rst),

                // Module external signals: TODO: generate?
                .TX(TX),
                .RX(RX),
                //////////
                
                .data_b(data_bus_in_uart),
                .addr_b(ram_addr_in_b),
                .strobe_b(data_bus_strobe_uart),
                .data_b_in(ram_data_out_b),
                .data_b_we(ram_we_out)
                );
`else // !`ifdef ENABLE_UART

   assign data_bus_strobe_uart = 0;

`endif


