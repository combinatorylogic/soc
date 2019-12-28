module int_to_float(
                    input         clk,
                    input         rst,
                    input [31:0]  a,
                    output [31:0] fl
                    );

   reg [31:0]                     a_0;
   reg [31:0]                     value_0;
   reg                            sign_0;
   reg [31:0]                     value_1;
   reg [7:0]                      exp_1;
   wire [22:0]                    mnt_1;
   wire [7:0]                     r_1;
   
   assign mnt_1 = value_1[31:8];
   assign r_1   = value_1[7:0];
   
   wire                           guard, round_bit, sticky;
   
   assign guard = r_1[7];
   assign round_bit = r_1[6];
   assign sticky = r_1[5:0] != 0;
   
   reg [7:0]                      exp_2;
   reg [22:0]                     mnt_2;
   reg                            sign_1;
   reg                            sign_2;
   

   assign fl = {sign_2, exp_2, mnt_2};

   wire [31:0]                    value_0_v;

   assign value_0_v = a[31]?-a:a;
   wire [4:0]                     zeroes_0_v;
   reg [4:0]                      zeroes_0;

   count_zeroes z0 (.value(value_0_v),
                    .result(zeroes_0_v));

   always @(posedge clk)
     if (!rst) begin
        a_0 <= 0;
        value_0 <= 0;
        zeroes_0 <= 0;
        sign_0 <= 0;
        exp_1 <= 0;
        value_1 <= 0;
        sign_1 <= 0;
        mnt_2 <= 0;
        exp_2 <= 0;
        sign_2 <= 0;
     end else begin
       
       // Pipe 0
       a_0 <= a;
       value_0 <= value_0_v;
       sign_0 <= a[31];
       zeroes_0 <= zeroes_0_v;
        

       // Pipe 1
       exp_1 <= $signed(127) + $signed((31 - zeroes_0));
       value_1 <= value_0 << zeroes_0;
       sign_1 <= sign_0;

       // Pipe 2
       sign_2 <= sign_1;
       if (guard && (round_bit || sticky || mnt_1[0])) begin
          mnt_2 <= mnt_1 + 1;
          if (mnt_1 == 24'hfffffe)
            exp_2 <= exp_1 + 1;
          else
            exp_2 <= exp_1;
       end else begin
          mnt_2 <= mnt_1;
          exp_2 <= exp_1;
       end

     end

                                                  
endmodule


module count_zeroes(input [31:0] value,
                    output [4:0] result);

   wire [15:0]                    val16;
   wire [7:0]                     val8;
   wire [3:0]                     val4;
   wire                           result4, result3, result2, result1, result0;
   assign result = {result4, result3, result2, result1, result0};
   

   assign result4 = (value[31:16] == 16'b0);
   assign val16     = result4 ? value[15:0] : value[31:16];
   assign result3 = (val16[15:8] == 8'b0);
   assign val8      = result3 ? val16[7:0] : val16[15:8];
   assign result2 = (val8[7:4] == 4'b0);
   assign val4      = result2 ? val8[3:0] : val8[7:4];
   assign result1 = (val4[3:2] == 2'b0);
   assign result0 = result1 ? ~val4[1] : ~val4[3];

endmodule
