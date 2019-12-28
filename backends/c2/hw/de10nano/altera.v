
module ledwriter (input clk,
                  input            rst,

                  output [7:0] LED,
                  
                  input [31:0]     addr_b,
                  input [31:0]     data_b_in,
                  input            data_b_we);

						
   reg [7:0]                       counter;


   assign LED = counter;
   
   always @(posedge clk)
     if (~rst) begin
		  counter <= 0;
     end else begin
        if (addr_b == 65540)
          counter <= data_b_in[15:0];
     end

endmodule


module socram(input clk,
              input             rst,

              output reg [31:0] data_a,
              input [31:0]      addr_a,
              
              output reg [31:0] data_b,
              output reg        strobe_b,
              input [31:0]      addr_b,
              input [31:0]      data_b_in,
              input             data_b_we);

   parameter RAM_DEPTH = 8192 * 2;
   parameter INIT_FILE = "../../custom.hex";
   
   reg [31:0]                   mem [0:RAM_DEPTH-1];

   initial begin
      if (INIT_FILE != "")
         $readmemh(INIT_FILE, mem);
   end
    
   always @(posedge clk)
     begin
        if (data_b_we & (addr_b[31:16] == 0)) begin
           mem[addr_b] <= data_b_in;
        end
        data_a <= mem[addr_a];
        data_b <= mem[addr_b];
        strobe_b <= (addr_b[31:16] == 0);
     end

endmodule // socram


module generic_mul ( a, b, clk, pdt);
   parameter size = 32, level = 5;
   input [size-1 : 0] a;
   input [size-1 : 0] b;
   input              clk;
   output [2*size-1 : 0] pdt;
   reg [size-1 : 0]      a_int, b_int;
   reg [2*size-1 : 0]    pdt_int [level-1 : 0];
   integer               i;
   
   assign pdt = pdt_int [level-1];
   
   always @ (posedge clk)
     begin
        a_int <= a;
        b_int <= b;
        pdt_int[0] <= a_int * b_int;
        for(i =1;i <level;i =i +1)
          pdt_int [i] <= pdt_int [i-1];
     end
endmodule

module hls_Mul(input clk,
               input reset,

               input [31:0]  p0,
               input [31:0]  p1,
               output [31:0] out);

   generic_mul #(.size(32),.level(3)) mul1 (.clk(clk),
                                            .a(p0),
                                            .b(p1),
                                            .pdt(out));
endmodule


module mul16x16 (input [15:0]      a,
                 input [15:0]      b,
                 output [31:0] o);

   assign o = a * b;
   
endmodule // mul16x16



`include "../rtl/mul.v"


module hls_MulFSM(input clk,
                  input         reset,
                  input         req,
                  output        ack,
                  
                  input [31:0]  p0,
                  input [31:0]  p1,
                  output [31:0] out);

    mul32x32_fsm S(.clk(clk),
                   .rst(reset),
                   .req(req),
                   .ack(ack),
                   .p0(p0),
                   .p1(p1),
                   .out(out));

endmodule // hls_MulFSM

module hlsblockram (input         clk,
                    
                    input [ABITWIDTH-1:0]      readaddr1,
                    output reg [BITWIDTH-1:0] readout1,
                    input [ABITWIDTH-1:0]      writeaddr1,
                    input [BITWIDTH-1:0]      writein1,
                    input                     we
                    );
   

   parameter SIZE = 32;
   parameter BITWIDTH = 32;
   parameter ABITWIDTH = 32;
   
   reg [BITWIDTH-1:0] mem [0:SIZE-1];
 
   // Expect 2-port (1ro+1wo) to be inferred
   always @(posedge clk)
     begin
        if (we) begin
           mem[writeaddr1] = writein1;
        end
        readout1 <= mem[readaddr1];
     end

endmodule // toyblockram



`include "../rtl/fpmult.v"
`include "../rtl/fpmult_m2.v"
`include "../rtl/fpint_3.v"
`include "../rtl/fpadd_sub.v"
`include "../rtl/fpdiv.v"
`include "../rtl/fp2intp.v"

/// fpmult_m2 for a 1 cycle longer version
`define FMUL_MODULE fpmult


// 4 clock cycles to result
module hls_FMul(input clk,
                 input         reset,
                 input [31:0]  p0,
                 input [31:0]  p1,
                 output [31:0] out);

   `FMUL_MODULE mul1(.clk(clk),
                     .rst(reset),
                     .a(p0),
                     .b(p1),
                     .res(out));
   
endmodule // hls_FPMul

// 3 clock cycles to result
module hls_FAdd(input clk,
                 input         reset,
                 input [31:0]  p0,
                 input [31:0]  p1,
                 output [31:0] out);

   fpadd_sub a(.clk(clk),
               .rst(reset),
               .sub(1'b0),
               .a(p0),
               .b(p1),
               .res(out));
   
endmodule // hls_FPAdd

// 3 clock cycles
module hls_FSub(input clk,
                 input         reset,
                 input [31:0]  p0,
                 input [31:0]  p1,
                 output [31:0] out);

   fpadd_sub a(.clk(clk),
               .rst(reset),
               .sub(1'b1),
               .a(p0),
               .b(p1),
               .res(out));
   
endmodule // hls_FPAdd


// combinatorial fp comp, immediate result

module hls_OGT(input clk,
                 input        reset,
                 input [31:0] p0,
                 input [31:0] p1,
                 output       out);

   wire [30:0]                 m_p0;
   wire [30:0]                 m_p1;
   wire                        s_p0;
   wire                        s_p1;
   wire                        gr;
   

   assign s_p0 = p0[31];
   assign m_p0 = p0[30:0];

   assign s_p1 = p1[31];
   assign m_p1 = p1[30:0];

    
   assign gr = m_p0 > m_p1; // we don't care about equivalence?

   assign out = (s_p0&s_p1)?~gr:
                (s_p0)?0:
                (s_p1)?1:gr;
      
endmodule // hls_OGT


module hls_FDiv(input clk,
                 input         reset,
                 input [31:0]  p0,
                 input [31:0]  p1,
                 output [31:0] out);

   fpdiv div1(.clk(clk),
              .rstn(reset),
              .numer_denom({p0, p1}),
              .div_result(out));
   
endmodule // hls_FDiv


// 3 cycle int to float converter
module hls_SIToFP(input clk,
                  input         reset,
                  input [31:0]  p0,
                  output [31:0] out);

   int_to_float a(.clk(clk),
                  .rst(reset),
                  .a(p0),
                  .fl(out));

endmodule
  

 
module hls_FPToSI(input clk,
                  input         reset,
                  input [31:0]  p0,
                  output [31:0] out);

   flt2int32 a(.clk(clk),
               .rst(reset),
               .a(p0),
               .z(out));

endmodule
  


module hls_FAddFSM(input clk,
               input         reset,
               input         req,
               output        ack,
                  
               input [31:0]  p0,
               input [31:0]  p1,
               output [31:0] out);

    fpadd_sub a(.clk(clk),
                .rst(reset),
                .sub(1'b0),
                .a(p0),
                .b(p1),
                .res(out));

   tick #(.count(3)) t0 (.clk(clk), .reset(reset), .req(req), .ack(ack));

endmodule


module hls_FSubFSM(input clk,
               input         reset,
               input         req,
               output        ack,
                  
               input [31:0]  p0,
               input [31:0]  p1,
               output [31:0] out);

    fpadd_sub a(.clk(clk),
                .rst(reset),
                .sub(1'b1),
                .a(p0),
                .b(p1),
                .res(out));

   tick #(.count(3)) t0 (.clk(clk), .reset(reset), .req(req), .ack(ack));

endmodule


module tick (input clk,
             input      reset,
             input      req,
             output reg ack);
   parameter count = 4;

   reg [4:0]       ccounter;

   always @(posedge clk) begin
      if (~reset) begin
         ccounter <= 0;
         ack <= 0;
      end else if (req) begin
         ccounter <= 1; ack <= 0;
      end else if (ccounter) begin
         ccounter <= ccounter + 1;
         if (ccounter == count) begin
            ccounter <= 0;
            ack <= 1;
         end
      end else ack <= 0;
   end

endmodule
