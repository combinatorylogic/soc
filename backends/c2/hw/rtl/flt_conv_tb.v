

  module top;


  reg [31:0] fa;
  reg clk;
  reg rst;
  wire [31:0] ret;


  flt2int32 c1 (.clk(clk), .a(fa), .z(ret));


  reg [31:0] counter;
  initial #0 counter <= 0;
  initial #0 clk <= 0;
  initial #0 rst <= 0;
  initial #200 rst <= 1;
   initial #0 fa <= 0;
   
   
   always #100 begin clk <= !clk;
   end
   
  always @(posedge clk)
    begin
        counter <= counter + 1;

       if (counter == 2) begin
           fa <= 32'h4048F5C3; // 3.14
       end else if (counter == 3) begin
          fa <= 32'h3fc00000; // 1.5
       end else if (counter == 4) begin
          fa <= 32'h41000000; // 8
       end else if (counter == 5) begin
          fa <= 32'h44003f5c; // 512.99 
       end else if (counter == 6) begin
          fa <= 32'h4048F5C3; // 3.14
       end else if (counter == 7) begin
          fa <= 32'hc25d0000; // -55.25
       end else begin
          fa <= 0;
       end
     $display("fa=%h ret=%d  counter=%d reset=%d", fa, $signed(ret),
                       counter, rst);
  end

   initial #2500 $finish;
   


  endmodule
