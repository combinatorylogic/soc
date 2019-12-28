module fpadd_sub
  (
   input             clk,
   input             rst,
   input             sub,
   input [31:0]      a,
   input [31:0]      b,
   output reg [31:0] res
   );

   // Pipeline stage 0 - set equality/zero flags, normalize mantissas to
   //   new exponent
   reg [24:0]        am_0;		// mantisa A
   reg [24:0]        bm_0;		// mantisa B
   reg 		     sub_0;             // sub? stage 0
   reg [7:0]         exp_0;		// exponent A
   reg [31:0]        a_0;             // Stage 0 copy of a
   reg [31:0]        b_0;             // Stahe 0 copy of b
   reg 		     a_b_equal_0;
   reg 		     a_zero_0;
   reg 		     b_zero_0;

   
   wire              a_b_equal_p;
   assign a_b_equal_p = (a[30:0] == b[30:0]) &
		            ((~sub & (a[31] ^ b[31])) 
                             | (sub & (a[31] ~^ b[31])));

   wire [8:0]        agb_0;
   wire [8:0]        bga_0;

   assign agb_0 = b[30:23] - a[30:23];
   assign bga_0 = a[30:23] - b[30:23];
   
   always @(posedge clk)
     if (!rst) begin
        sub_0       <= 0;
        a_0         <= 0;
        b_0         <= 0;
        a_b_equal_0 <= 0;
        a_zero_0    <= 0;
        b_zero_0    <= 0;
        bm_0        <= 0;
        am_0        <= 0;
        exp_0       <= 0;
     end else begin
        sub_0       <= sub;
        a_0         <= a;
        b_0         <= b;
        a_b_equal_0 <= a_b_equal_p;
        a_zero_0 <= ~|a[30:0] ;
        b_zero_0 <= ~|b[30:0];
        if(agb_0[8]) // exp A > exp B
          begin
	     bm_0   <= {(sub ^ b[31]), ({1'b1,b[22:0]} >> (bga_0[7:0]))};
	     am_0   <= {a[31], {1'b1,a[22:0]}};
	     exp_0  <= a[30:23];
	  end
        else // exp B > exp A
          begin
	     am_0   <= {a[31], ({1'b1,a[22:0]} >> (agb_0[7:0]))};
	     exp_0  <= b[30:23];
	     bm_0   <= {(sub ^ b[31]), {1'b1,b[22:0]}};
          end
     end

   // Pipeline stage 1 - produce a sum of A and B mantissas, 
   // calculate a required shift
   wire [24:0]        n_am_0;		// normalised mantissa A
   wire [24:0]        n_bm_0;		// normalised mantissa B

   assign n_am_0 = ({am_0[24],bm_0[24]} ==2'b00)?am_0:
                   (({am_0[24],bm_0[24]}==2'b11)?{1'b0,am_0[23:0]}:
                    (({am_0[24],bm_0[24]}==2'b10)?{am_0[24],~am_0[23:0]}:
                     (({am_0[24],bm_0[24]}==2'b01)?am_0:am_0)));
   
   assign n_bm_0 = ({am_0[24],bm_0[24]} ==2'b00)?bm_0:
                   (({am_0[24],bm_0[24]}==2'b11)?{1'b0,bm_0[23:0]}:
                    (({am_0[24],bm_0[24]}==2'b10)?bm_0:
                     (({am_0[24],bm_0[24]}==2'b01)?{bm_0[24],~bm_0[23:0]}:bm_0)));

   
   wire [24:0]        msum_0;	
   assign msum_0 = n_am_0 + n_bm_0;

   wire [2:0]         nmsel;
   assign nmsel = {am_0[24],bm_0[24],msum_0[24]};


   wire [24:0]        nmsum_0;
   wire [23:0]        nmsum_0_tmp1;
   assign nmsum_0_tmp1 = msum_0[23:0]+24'b1;
   

   assign nmsum_0 =
                   (nmsel[2:1]==2'b00||nmsel[2:1]==2'b11)?msum_0:
                   (nmsel==3'b100 ?{1'b0, nmsum_0_tmp1}:
                   (nmsel==3'b101 ?{1'b0, ~msum_0[23:0]}:
                   (nmsel==3'b010 ?{1'b0, nmsum_0_tmp1}:
                   (nmsel==3'b011 ?{1'b0, ~msum_0[23:0]}:msum_0))));

   // Assign stage 1 registers
   reg [24:0]        nmsum_1;	
   reg 		     sub_1;
   reg 		     a_b_equal_1;
   reg 		     a_zero_1;
   reg 		     b_zero_1;
   reg [7:0]         exp_1;	      
   reg 		     sign_1;	     
   reg [31:0]        a_1;
   reg [31:0]        b_1;
   reg [7:0]         shift_1;

   // Calculate mantissa shift
   wire [4:0]        nzeros_1;
   
   count_zeroes z0(.value({7'b0,nmsum_0}),
                   .result(nzeros_1));
   
   always @(posedge clk)
     if (!rst) begin
        sub_1       <= 0;
        a_zero_1    <= 0;
        b_zero_1    <= 0;
        a_b_equal_1 <= 0;
        exp_1       <= 0;
        a_1         <= 0;
        b_1         <= 0;
        nmsum_1     <= 0;
        sign_1      <= 0;
        shift_1     <= 0;
     end else begin
        // Pass from stage 0
        sub_1       <= sub_0; 
        a_zero_1    <= a_zero_0; 
        b_zero_1    <= b_zero_0; 
        a_b_equal_1 <= a_b_equal_0;
        exp_1       <= exp_0;
        a_1         <= a_0;
        b_1         <= b_0;

        // Sum
        nmsum_1     <= nmsum_0;

        // Sign

        if ((!am_0[24] & bm_0[24] & msum_0[24])
            || (am_0[24] & bm_0[24])
            || (am_0[24] & !bm_0[24] & msum_0[24]))
          sign_1    <= 1;
        else sign_1 <= 0;
        
        // Shift
        shift_1     <= nzeros_1 - 8;
     end

   
   // Pipeline stage 2 - shift mantissa, choose an answer
   wire [24:0]       nm_1;
   assign nm_1 = (nmsum_1[24])?
                 (nmsum_1 >> 1):
                 (nmsum_1 << shift_1);

   wire [7:0]         nexp_1;
   assign nexp_1 = (nmsum_1[24])?
                   (exp_1+8'h1):
                   (exp_1 - shift_1);

   always @(posedge clk)
     if (!rst) begin
        res      <= 0;
     end else begin
        if (sub_1) begin // Subtraction
           if (a_b_equal_1)
             res <= 0; // A == B, res = 0
           else
             res <= {sign_1,nexp_1,nm_1[22:0]};
        end else begin // Addition
           if (a_zero_1 & b_zero_1)
             res <= 0;
           else if (a_zero_1)
             res <= b_1;
           else if (b_zero_1)
             res <= a_1;
           else
             res <= {sign_1,nexp_1,nm_1[22:0]};
        end
     end

endmodule
