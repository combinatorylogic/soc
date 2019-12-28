module fpmult_m2
	(
	 input             clk,
	 input             rst,
	 input [31:0]      a,
	 input [31:0]      b,
	 output reg [31:0] res
	 );
   
   reg                     sign_0;
   reg [7:0]               exp_0;
   reg                     zero_0;
   
   wire [47:0]             m_0x_next;
   
   mul23 m0 (.clk(clk),
             .a({1'b1,a[22:0]}),
             .b({1'b1,b[22:0]}),
             .o(m_0x_next));

   always @(posedge clk)
     if(!rst) begin
	sign_0 <= 0;
	exp_0  <= 0;
	zero_0 <= 0;
     end else begin
	// Pipeline stage 0: start multiplication, find sign and exponent
	sign_0 <= a[31] ^ b[31];
	exp_0  <= a[30:23] + b[30:23] - 8'h7E;
	// Test if a or b == 0
	if (!a[30:0] || !b[30:0])
          zero_0 <= 1'b1;
	else 
          zero_0 <= 1'b0;
     end // else: !if(!rst)

   reg                     sign_0x;
   reg [7:0]               exp_0x;
   reg                     zero_0x;
   reg [47:0]              m_0x;
   always @(posedge clk)
     if (!rst) begin
        m_0x    <= 0;
        exp_0x  <= 0;
        zero_0x <= 0;
        sign_0x <= 0;
     end else begin
        // Pipeline stage 0x: get the multiplication result, pass the rest
	m_0x    <= m_0x_next;
        exp_0x  <= exp_0;
        zero_0x <= zero_0;
        sign_0x <= sign_0;
     end


   reg                     sign_1;
   reg [7:0]               exp_1;
   reg                     zero_1;
   reg                     mh_1;
   reg [24:0]              mn_1;
   wire                    nmh_1;
   assign nmh_1 = (~mh_1 & ~mn_1[24]);

   always @(posedge clk)
     if (!rst) begin
	exp_1  <= 0;
	sign_1 <= 0;
	zero_1 <= 0;
	mh_1   <= 0;
	mn_1   <= 0;
     end else begin
	// Pipeline stage 1: normalise mantissa
	exp_1  <= exp_0x;	
	sign_1 <= sign_0x;	
	zero_1 <= zero_0x;
	mh_1   <= m_0x[47];
	if (m_0x[47])
          mn_1 <= m_0x[47:24] + m_0x[23];
	else
 	  mn_1 <= m_0x[47:23] + m_0x[22];
     end // else: !if(!rst)
   
   always @(posedge clk)
     if (!rst) begin
	res <= 0;
     end else begin
	// Pipeline stage 2: store the result
	if (zero_1) 
          res <= 32'h0;
	else 
          res <= {sign_1,(exp_1 - nmh_1),mn_1[22:0]};
     end
   
endmodule



module mul23(input clk,
             input [23:0]      a,
             input [23:0]      b,
             output reg [47:0] o);

   always @(posedge clk)
     begin
        o <= a * b;
     end

endmodule
