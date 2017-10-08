module uartmm(input clk,
              input             rst,

              input             RX,
              output            TX,
              
              output reg [31:0] data_b,
              output reg        strobe_b,
              input [31:0]      addr_b,
              input [31:0]      data_b_in,
              input [31:0]      data_b_we);

   reg [7:0]                uart_din_r;
   reg                      uart_valid_r;
   reg                      uart_ready_r;
   
   reg [7:0]                input_axis_tdata;
   reg                      input_axis_tvalid;
   wire                     input_axis_tready;
   
   
   wire [7:0]               output_axis_tdata;
   wire                     output_axis_tvalid;
   reg                      output_axis_tready;
   
   uart _uart (
               .clk(clk),
               .rst(~rst),
               
               .rxd(RX),
               .txd(TX),

               .input_axis_tdata(input_axis_tdata),
               .input_axis_tvalid(input_axis_tvalid),
               .input_axis_tready(input_axis_tready),

               .output_axis_tdata(output_axis_tdata),
               .output_axis_tvalid(output_axis_tvalid),
               .output_axis_tready(output_axis_tready),
               
               //  90MHz
               .prescale(90000000/(115200*8)));
   
   assign strobe_b_next = (addr_b == 65537) | (addr_b == 65538) | (addr_b == 65539);
   assign data_b_next = (addr_b == 65537)?uart_valid_r:
                        (addr_b == 65538)?uart_ready_r:
                        (addr_b == 65539)?uart_din_r:0;

   always @(posedge clk)
     if (~rst) begin
        uart_din_r <= 0;
        uart_valid_r <= 0;
        uart_ready_r <= 0;
        input_axis_tdata <= 0;
        input_axis_tvalid <= 0;
        output_axis_tready <= 0;
     end else begin

        data_b <= data_b_next;
        strobe_b <= strobe_b_next;
        
        if (input_axis_tvalid) begin
           input_axis_tvalid <= 0;
        end
        
        if (output_axis_tvalid & ~output_axis_tready) begin
           output_axis_tready <= 1;
        end

        uart_ready_r <= input_axis_tready; // delay

        if (output_axis_tvalid) begin
           output_axis_tready <= 0;
           uart_din_r <= output_axis_tdata;
           uart_valid_r <= 1;
        end else if ((addr_b == 65539) & ~data_b_we & uart_valid_r) begin
           uart_valid_r <= 0;
        end else if ((addr_b == 65539) & data_b_we & input_axis_tready & ~input_axis_tvalid) begin
           input_axis_tdata <= data_b[7:0];
           input_axis_tvalid <= 1;
        end
     end
   

endmodule

module ledwriter (input clk,
                  input rst,

                  output reg [15:0] LED,
                  
                  input [31:0]     addr_b,
                  input [31:0]     data_b_in,
                  input [31:0]     data_b_we);

   always @(posedge clk)
     if (~rst) begin
        LED <= 0;
     end else begin
        if (addr_b == 65540)
          LED <= data_b_in[15:0];
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
              input [31:0]      data_b_we);

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

endmodule



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

   reg [31:0]                p0t;
   reg [31:0]                p1t;
   reg [31:0]                tmp1;
   reg [31:0]                tmp2;
   reg [31:0]                tmp3;
   reg [31:0]                tmp4;
   assign out = tmp4;

   generic_mul #(.size(32),.level(3)) mul1 (.clk(clk),
                                            .a(p0),
                                            .b(p1),
                                            .pdt(out));
endmodule



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


