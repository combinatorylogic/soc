

module top;

   
   localparam MEMORY_SIZE = 8192*4;


   reg wb_rst;
   reg wb_clk;

   reg [31:0] counter;
   initial #0 counter <= 0;
   
 
   
   wire [31:0] wb_adr;
   wire [31:0] wb_dat;
   wire [3:0]  wb_sel;
   wire        wb_we;
   wire        wb_cyc;
   wire        wb_stb;
   wire [2:0]  wb_cti;
   wire [1:0]  wb_bte;
   wire [31:0] wb_rdt;
   wire        wb_ack;

   wire [31:0] ic_data_out;
   reg [31:0]  ic_addr_in;
   wire        ic_ack;

   reg [31:0]  ic_addr_in_prev;


   initial #0 wb_clk <= 1'b0;
   
   initial #0 wb_rst <= 1'b1;

   initial #0 begin
      ic_addr_in <= 1025;
      ic_addr_in_prev <= 1025;
      
   end
   
   initial #200 wb_rst <= 1'b0;
   always #100 wb_clk <= !wb_clk;


   reg flip;

   initial #0 flip <= 0;


   

   always @(posedge wb_clk) begin
      counter <= counter + 1;
      if (ic_ack) begin
         $display("Poo poo out! {%d} - {%d} @ %d", ic_addr_in_prev, ic_data_out, counter);
      end
      if (ic_ready) begin
 //        $display("IC_READY {%d} - {%d} @ %d", ic_addr_in_prev, ic_data_out, counter);
         $display("requesting {%d} @ %d", ic_addr_in + (flip?71:-3), counter);
         
         ic_addr_in_prev <= ic_addr_in;
         ic_addr_in <= ic_addr_in + (flip?71:-3);
         flip = ~flip;
      end

      if (ic_addr_in_prev> MEMORY_SIZE/4) begin
         $finish;
      end
      

   end

   
   wb_ram
     #(.depth (MEMORY_SIZE),
       .memfile ("data.hex"))
   ram
     (// Wishbone interface
      .wb_clk_i (wb_clk),
      .wb_rst_i (wb_rst),
      .wb_adr_i (wb_adr[$clog2(MEMORY_SIZE)-1:0]),
      .wb_stb_i (wb_stb),
      .wb_cyc_i (wb_cyc),
      .wb_cti_i (wb_cti),
      .wb_bte_i (wb_bte),
      .wb_we_i  (wb_we) ,
      .wb_sel_i (wb_sel),
      .wb_dat_i (wb_dat),
      .wb_dat_o (wb_rdt),
      .wb_ack_o (wb_ack),
      .wb_err_o ());

   icache_wb icache(
                    .clk(wb_clk),
                    .rst(~wb_rst),

                    .dbgcounter(counter),
                    
                    .ic_data_out(ic_data_out),
                    .ic_addr_in(ic_addr_in),
                    .ic_ack(ic_ack),
                    .ic_ready(ic_ready),

                    .ic_adr_o(wb_adr),
                    .ic_cyc_o(wb_cyc),
                    .ic_stb_o(wb_stb),
                    .ic_we_o(wb_we),
                    .ic_sel_o(wb_sel),
                    .ic_cti_o(wb_cti),
                    .ic_bte_o(wb_bte),
                    .ic_dat_i(wb_rdt),
                    .ic_ack_i(wb_ack),
                    .ic_err_i(1'b0)
                    );

endmodule
