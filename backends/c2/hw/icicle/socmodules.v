/* Memory mapped modules */

   assign clk = sys_clk_in;
   assign rst = sys_reset;


   wire [31:0]     data_bus_in_uart;
   wire            data_bus_strobe_uart;

   uartmm uart1(.clk(clk),
                .rst(rst),

                .TX(uart_tx),
                .RX(uart_rx),
                
                .data_b(data_bus_in_uart),
                .addr_b(ram_addr_in_b),
                .strobe_b(data_bus_strobe_uart),
                .data_b_in(ram_data_out_b),
                .data_b_we(ram_we_out)
                );

