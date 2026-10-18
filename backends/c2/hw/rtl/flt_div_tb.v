

  module top;


  reg [31:0] fa;
  reg [31:0] fb;
  reg clk;
  reg rst;
  wire [31:0] ret;


  fpdiv div1 (.clk(clk), .rst(rst), .a(fa), .b(fb), .res(ret));


  reg [31:0] counter;
  initial #0 counter <= 0;
  initial #0 clk <= 0;
  initial #0 rst <= 0;
   initial #200 rst <= 1;
   initial #0 fa <= 0;
   initial #0 fb <= 0;
   
   
   always #100 begin clk <= !clk;
   end
   
  always @(posedge clk)
    if (!rst) begin
       counter <= 0;
    end else begin
        counter <= counter + 1;

       if (counter == 2) begin
          fa <= 32'h4048F5C3; // 3.14 / 1.5 = 2.093333
          fb <= 32'h3fc00000;
       end else if (counter == 3) begin
          fa <= 32'h46000000; // 8192/200 = 40.959999
          fb <= 32'h43480000;
          
       end else if (counter == 4) begin
          fa <= 32'h43480000; // 200/8192 = 0.0244140625
          fb <= 32'h46000000;
       end else if (counter == 5) begin
          fa <= 32'h40e33333; // 7.1 / 3.14 = 2.2611464968152863
          fb <= 32'h4048F5C3;
       end else begin
          fa <= 0;
          fb <= 0;
       end
     $display("fa=%h fb=%h ret=%h  counter=%d reset=%d", fa, fb, ret,
                       counter, rst);
  end

   initial #4500 $finish;
   


  endmodule
