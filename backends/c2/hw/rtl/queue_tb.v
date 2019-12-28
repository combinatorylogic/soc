module top;
   reg clk;
   reg rst;
   
   reg [31:0] counter;
   initial #0 counter <= 0;
   initial #0 clk <= 0;
   initial #0 rst <= 0;
   initial #500 rst <= 1;
   
   
   always #100 begin clk <= !clk; end

   reg we;
   reg re;
   reg [7:0] idata;
   wire [7:0] wdata;
   wire       oready;
   wire       full;
   wire       empty;

   initial #0 begin
      idata <= 0;
      re <= 0;
      we <= 0;
   end

   gendelayqueue #(.WIDTH(8),.DEPTH(6)) q1 (.clk(clk),
                                            .rst(rst),
                                            .we(we),
                                            .idata(idata),
                                            .re(re),
                                            .wdata(wdata),
                                            .oready(oready),
                                            .full(full),
                                            .empty(empty));
      
   always @(posedge clk)
     if (rst)
     begin
       counter <= counter + 1;
        if(full) $display("FULL AT %d", counter);
        
        
       if (counter == 2) begin
          idata <= 15;
          we <= 1;
       end else if (counter == 3) begin
          idata <= 17;
          we <= 1;
       end else if (counter == 6) begin
          idata <= 20;
          we <= 1;
       end else if (counter == 8) begin
          idata <= 25;
          we <= 1;
       end
       else we <= 0;
    end // always @ (posedge clk)

   always @(posedge clk)
     begin
        if (counter > 30) begin
           if (oready & !re) re <= 1;
           if (!oready & re) re <= 0;
           if (re) begin
              $display("Queue output %d at %d", wdata, counter);
           end
        end
     end

   initial #15500 $finish;
   
endmodule
