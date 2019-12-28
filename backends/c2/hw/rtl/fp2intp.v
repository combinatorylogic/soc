module flt2int32(
                 input             clk,
                 input             rst,
                 input [31:0]      a,
                 output reg [31:0] z);
   
   wire [31:0] a_m;
   wire [8:0]  a_e;
   wire        a_s;
   reg         a_s1;
   
   assign a_m[31:8] = {1'b1, a[22 : 0]};
   assign a_m[7:0] = 0;
   assign a_e = a[30 : 23] - 127;
   assign a_s = a[31];

   wire        specialcase;
   
   wire [31:0] specialcase_z;
   wire [31:0] a_m_next;
   
   assign       a_m_next = a_m >> ($signed(31) - $signed(a_e));

   assign specialcase = ($signed(a_e) == -127) | ($signed(a_e)>31);
   assign specialcase_z = ($signed(a_e)>31)?32'h80000000:0;
   reg [31:0]  specialcase_z1;
   reg         specialcase1;
   
   reg [31:0]  a_m1;
   

   always @(posedge clk)
     if (~rst) begin
        a_m1 <= 0;
        specialcase_z1 <= 0;
        a_s1 <= 0;
        z <= 0;
     end else begin
        a_m1 <= a_m_next;
        specialcase_z1 <= specialcase_z;
        specialcase1 <= specialcase;
        
        a_s1 <= a_s;
        
        if (specialcase1) z<= specialcase_z1;
        else if (a_m1[31]) z <= 32'h80000000;
        else z <= a_s1? -a_m1 : a_m1;
     end

endmodule
