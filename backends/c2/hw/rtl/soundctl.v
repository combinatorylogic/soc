

module soundctl (input clk,
                 input        rst,

                 output       sound_clr_full,
                 input [15:0] sound_clr_sample,
                 input [15:0] sound_clr_rate,
                 input        sound_clr_req,
                 output reg   pwm_out
);


   wire [15:0]                fifo_out;
   wire                       fifo_empty;
   reg                        fifo_rd;

   smallfifo16 fifo1(.rst(rst),
                   
                     .clk_in(clk),
                     .fifo_in(sound_clr_sample),
                     .fifo_en(sound_clr_req),
                     .fifo_full(sound_clr_full),
                     
                     .clk_out(clk),
                     .fifo_out(fifo_out),
                     .fifo_empty(fifo_empty),
                     .fifo_rd(fifo_rd));

   reg [15:0]                 counter;
   reg [8:0]                 sample;
   
   always @(posedge clk)
    if (~rst) begin
       fifo_rd <= 0;
       counter <= 0;
       pwm_out <= 0;
       have_sample <= 0;
       sample <= 255;  // 50% duty cycle default level
    end else begin
       pwm_out <= (counter < sample)?1:0;
       if (fifo_rd) begin
          sample <= fifo_out;
          fifo_rd <= 0;
       end 
       else if (counter >= sound_clr_rate) begin
          counter <= 0;
          if (~fifo_empty) fifo_rd <= 1; else  begin
             fifo_rd <= 0;
             sample <= 255;
          end
       end else begin
          fifo_rd <= 0;
          counter <= counter + 1;
       end
    end
   

endmodule
