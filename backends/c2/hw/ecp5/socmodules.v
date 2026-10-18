/* Memory mapped modules */

pll_100_50 pll(
    .clki(sys_clk_in),
    .clko(clk)
);

always @(posedge clk)
  arst <= sys_reset;
   
assign rst = sys_reset;
   
wire [7:0]           LEDr;

ledwriter ledwr1 (.clk(clk),
                  .rst(rst),
                  
                  .LED(LED),
                  
                  .addr_b(ram_addr_in_b),
                  .data_b_in(ram_data_out_b),
                  .data_b_we(ram_we_out));


wire [31:0]     data_bus_in_uart;
wire            data_bus_strobe_uart;

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

