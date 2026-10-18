module fpmult
	(
	 input             clk,
	 input             rst,
	 input [31:0]      a,
	 input [31:0]      b,
	 output reg [31:0] res
	 );
   
   // Pipeline stage 0: multiply mantissas (in one stage), find sign and exponent
   reg [47:0]              m_0;
   reg                     sign_0;
   reg [7:0]               exp_0;
   reg                     zero_0;

   wire [47:0]             m_0_next;
   assign m_0_next = {1'b1,a[22:0]} * {1'b1,b[22:0]};

   always @(posedge clk)
     if(!rst) begin
	m_0    <= 0;
	sign_0 <= 0;
	exp_0  <= 0;
	zero_0 <= 0;
     end else begin
	m_0    <= m_0_next;
	sign_0 <= a[31] ^ b[31];
	exp_0  <= a[30:23] + b[30:23] - 8'h7e;
	// Test if a or b == 0
	if (!a[30:0] || !b[30:0])
          zero_0 <= 1'b1;
	else 
          zero_0 <= 1'b0;
     end

   // Pipeline stage 1: normalise mantissa
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
	exp_1  <= exp_0;	
	sign_1 <= sign_0;	
	zero_1 <= zero_0;
	mh_1   <= m_0[47];
	if (m_0[47])
          mn_1 <= m_0[47:24] + m_0[23];
	else
 	  mn_1 <= m_0[47:23] + m_0[22];
     end // else: !if(!rst)
   
   // Pipeline stage 2: store the result
   always @(posedge clk)
     if (!rst) begin
	res <= 0;
     end else begin
	if (zero_1) 
          res <= 32'h0;
	else 
          res <= {sign_1,(exp_1 - nmh_1),mn_1[22:0]};
     end
   
endmodule

