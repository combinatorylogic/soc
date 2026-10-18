`include "defines.v"

`default_nettype none

`define CLKFREQ   `ICEFREQ    // frequency of incoming signal 'clk'



// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters
module pll_100_50
(
    input clki, // 100 MHz, 0 deg
    output clko // 44 MHz, 0 deg
);
(* FREQUENCY_PIN_CLKI="100" *)
(* FREQUENCY_PIN_CLKOP="44" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(25),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(14),
        .CLKOP_CPHASE(6),
        .CLKOP_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(11)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clki),
        .CLKOP(clko),
        .CLKFB(clko),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
	);
endmodule


/*

Copyright (c) 2014-2017 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * AXI4-Stream UART
 */
module uart_tx #
(
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   rst,

    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,

    /*
     * UART interface
     */
    output wire                   txd,

    /*
     * Status
     */
    output wire                   busy,

    /*
     * Configuration
     */
    input  wire [15:0]            prescale
);

reg s_axis_tready_reg = 0;

reg txd_reg = 1;

reg busy_reg = 0;

reg [DATA_WIDTH:0] data_reg = 0;
reg [18:0]      prescale_copy;
reg [18:0]   prescale_d1;
reg [18:0]   prescale_d2;

wire [18:0] prescale_d1n;
assign prescale_d1n = (prescale_copy << 3)-1;
wire [18:0]  prescale_d2n;
assign prescale_d2n = (prescale_copy << 3);
   
   
   
reg [18:0]      prescale_reg = 0;
reg [3:0] bit_cnt = 0;

assign s_axis_tready = s_axis_tready_reg;
assign txd = txd_reg;

assign busy = busy_reg;

always @(posedge clk) begin
    if (rst) begin
        s_axis_tready_reg <= 0;
        txd_reg <= 1;
        prescale_reg <= 0;
        prescale_copy <= prescale;
        prescale_d1 <= 0;
        prescale_d2 <= 0;
        bit_cnt <= 0;
        busy_reg <= 0;
    end else begin
        prescale_copy <= prescale;
        prescale_d1 <= prescale_d1n;
        prescale_d2 <= prescale_d2n;
        if (prescale_reg > 0) begin
            s_axis_tready_reg <= 0;
            prescale_reg <= prescale_reg - 1;
        end else if (bit_cnt == 0) begin
            s_axis_tready_reg <= 1;
            busy_reg <= 0;

            if (s_axis_tvalid) begin
                s_axis_tready_reg <= !s_axis_tready_reg;
                prescale_reg <= prescale_d1;
                bit_cnt <= DATA_WIDTH+1;
                data_reg <= {1'b1, s_axis_tdata};
                txd_reg <= 0;
                busy_reg <= 1;
            end
        end else begin
            if (bit_cnt > 1) begin
                bit_cnt <= bit_cnt - 1;
                prescale_reg <= prescale_d1;
                {data_reg, txd_reg} <= {1'b0, data_reg};
            end else if (bit_cnt == 1) begin
                bit_cnt <= bit_cnt - 1;
                prescale_reg <= prescale_d2;
                txd_reg <= 1;
            end
        end
    end
end

endmodule


/*

Copyright (c) 2014-2017 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * AXI4-Stream UART
 */
module uart_rx #
(
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   rst,

    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,

    /*
     * UART interface
     */
    input  wire                   rxd,

    /*
     * Status
     */
    output wire                   busy,
    output wire                   overrun_error,
    output wire                   frame_error,

    /*
     * Configuration
     */
    input  wire [15:0]            prescale

);

reg [18:0]      prescale_copy;
reg [DATA_WIDTH-1:0] m_axis_tdata_reg = 0;
reg m_axis_tvalid_reg = 0;

reg rxd_reg = 1;

reg busy_reg = 0;
reg overrun_error_reg = 0;
reg frame_error_reg = 0;

reg [DATA_WIDTH-1:0] data_reg = 0;
reg [18:0] prescale_reg = 0;
reg [3:0] bit_cnt = 0;

assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;

assign busy = busy_reg;
assign overrun_error = overrun_error_reg;
assign frame_error = frame_error_reg;

always @(posedge clk) begin
    if (rst) begin
        m_axis_tdata_reg <= 0;
        m_axis_tvalid_reg <= 0;
        rxd_reg <= 1;
        prescale_reg <= 0;
        bit_cnt <= 0;
        busy_reg <= 0;
        overrun_error_reg <= 0;
        frame_error_reg <= 0;
        prescale_copy <= prescale;
        
    end else begin
        rxd_reg <= rxd;
        overrun_error_reg <= 0;
        frame_error_reg <= 0;
        prescale_copy <= prescale;
       

        if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid_reg <= 0;
        end

        if (prescale_reg > 0) begin
            prescale_reg <= prescale_reg - 1;
        end else if (bit_cnt > 0) begin
            if (bit_cnt > DATA_WIDTH+1) begin
                if (!rxd_reg) begin
                    bit_cnt <= bit_cnt - 1;
                    prescale_reg <= (prescale_copy << 3)-1;
                end else begin
                    bit_cnt <= 0;
                    prescale_reg <= 0;
                end
            end else if (bit_cnt > 1) begin
                bit_cnt <= bit_cnt - 1;
                prescale_reg <= (prescale_copy << 3)-1;
                data_reg <= {rxd_reg, data_reg[DATA_WIDTH-1:1]};
            end else if (bit_cnt == 1) begin
                bit_cnt <= bit_cnt - 1;
                if (rxd_reg) begin
                    m_axis_tdata_reg <= data_reg;
                    m_axis_tvalid_reg <= 1;
                    overrun_error_reg <= m_axis_tvalid_reg;
                end else begin
                    frame_error_reg <= 1;
                end
            end
        end else begin
            busy_reg <= 0;
            if (!rxd_reg) begin
                prescale_reg <= (prescale_copy << 2)-2;
                bit_cnt <= DATA_WIDTH+2;
                data_reg <= 0;
                busy_reg <= 1;
            end
        end
    end
end

endmodule


/*

Copyright (c) 2014-2017 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * AXI4-Stream UART
 */
module uart #
(
    parameter DATA_WIDTH = 8
)
(
    input  wire                   clk,
    input  wire                   rst,

    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,

    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,

    /*
     * UART interface
     */
    input  wire                   rxd,
    output wire                   txd,

    /*
     * Status
     */
    output wire                   tx_busy,
    output wire                   rx_busy,
    output wire                   rx_overrun_error,
    output wire                   rx_frame_error,

    /*
     * Configuration
     */
    input  wire [15:0]            prescale

);

uart_tx #(
    .DATA_WIDTH(DATA_WIDTH)
)
uart_tx_inst (
    .clk(clk),
    .rst(rst),
    // axi input
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    // output
    .txd(txd),
    // status
    .busy(tx_busy),
    // configuration
    .prescale(prescale)
);

uart_rx #(
    .DATA_WIDTH(DATA_WIDTH)
)
uart_rx_inst (
    .clk(clk),
    .rst(rst),
    // axi output
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    // input
    .rxd(rxd),
    // status
    .busy(rx_busy),
    .overrun_error(rx_overrun_error),
    .frame_error(rx_frame_error),
    // configuration
    .prescale(prescale)
);

endmodule



module smallfifo8x(input rst,
                   
                   input        clk_in,
                   input [7:0]  fifo_in,
                   input        fifo_en,

                   output       fifo_full,

                   input        clk_out,
                   output [7:0] fifo_out,
                   output       fifo_empty,
                   input        fifo_rd);


   fifo_dc#(.AWIDTH(6),.DWIDTH(8)) 
   fifo0(.rclk (clk_out),
         .wclk (clk_in),
         .rclr (~rst),
         .wclr (~rst),
         .wreq (fifo_en),
         .d (fifo_in),
         .rreq (fifo_rd),
         .q (fifo_out),
         .empty (fifo_empty),
         .full (fifo_full));
   
   
endmodule



module fifo_dc (rclk, wclk, rclr, wclr, wreq, d, rreq, q, empty, full, hfull);

   // parameters
   parameter AWIDTH = 7;  //128 entries
   parameter DWIDTH = 16; //16bit databus

   // inputs & outputs
   input rclk;             // read clock
   input wclk;             // write clock
   input rclr;             // active high synchronous clear, synchronous to read clock
   input wclr;             // active high synchronous clear, synchronous to write clock
   input wreq;             // write request
   input [DWIDTH -1:0] d;  // data input
   input               rreq;             // read request
   output [DWIDTH -1:0] q; // data output

   output               empty;           // FIFO is empty, synchronous to read clock
   reg                  empty;
   output               full;            // FIFO is full, synchronous to write clock
   reg                  full;
   output               hfull;
   reg                  hfull;
   

   // variable declarations
   reg                  rrst, wrst, srclr, ssrclr, swclr, sswclr;
   reg [AWIDTH -1:0]    rptr, wptr;
   reg [AWIDTH -1:0]  rptr_gray, wptr_gray;

   //
   // module body
   //


   function [AWIDTH:1] bin2gray;
      input [AWIDTH:1]  bin;
      integer           n;
      begin
	 for (n=1; n<AWIDTH; n=n+1)
	   bin2gray[n] = bin[n+1] ^ bin[n];

	 bin2gray[AWIDTH] = bin[AWIDTH];
      end
   endfunction

   function [AWIDTH:1] gray2bin;
      input [AWIDTH:1] gray;
      begin
	 // same logic as bin2gray
	 gray2bin = bin2gray(gray);
      end
   endfunction

   //
   // Pointers
   //

   // generate synchronized resets
   always @(posedge rclk)
     begin
	swclr  <= #1 wclr;
	sswclr <= #1 swclr;
	rrst   <= #1 rclr | sswclr;
     end

   always @(posedge wclk)
     begin
	srclr  <= #1 rclr;
	ssrclr <= #1 srclr;
	wrst   <= #1 wclr | ssrclr;
     end


   // read pointer
   always @(posedge rclk)
     if (rrst) begin
	rptr      <= #1 0;
	rptr_gray <= #1 0;
     end else if (rreq) begin
	rptr      <= #1 rptr +1'h1;
	rptr_gray <= #1 bin2gray(rptr +1'h1);
     end

   // write pointer
   always @(posedge wclk)
     if (wrst) begin
	wptr      <= #1 0;
	wptr_gray <= #1 0;
     end else if (wreq) begin
	wptr      <= #1 wptr +1'h1;
	wptr_gray <= #1 bin2gray(wptr +1'h1);
     end

   //
   // status flags
   //
   (* ASYNC_REG = "TRUE" *) reg [AWIDTH-1:0] srptr_gray, ssrptr_gray;
   (* ASYNC_REG = "TRUE" *) reg [AWIDTH-1:0] swptr_gray, sswptr_gray;

   // from one clock domain, to the other
   always @(posedge rclk)
     begin
	swptr_gray  <= #1 wptr_gray;
	sswptr_gray <= #1 swptr_gray;
     end

   always @(posedge wclk)
     begin
	srptr_gray  <= #1 rptr_gray;
	ssrptr_gray <= #1 srptr_gray;
     end

   // EMPTY
   // WC: wptr did not increase
   always @(posedge rclk)
     if (rrst)
       empty <= #1 1'b1;
     else if (rreq)
       empty <= #1 bin2gray(rptr +1'h1) == sswptr_gray;
     else
       empty <= #1 empty & (rptr_gray == sswptr_gray);


   // FULL
   // WC: rptr did not increase
   always @(posedge wclk)
     if (wrst)
       full <= #1 1'b0;
     else if (wreq)
       full <= #1 bin2gray(wptr +2'h2) == ssrptr_gray;
     else
       full <= #1 full & (bin2gray(wptr + 2'h1) == ssrptr_gray);

   wire [AWIDTH -1:0] ssrptr_bin = gray2bin(ssrptr_gray);
   
   always @(posedge wclk)
     if (wrst)
       hfull <= 1'b0;
     else if (wptr > ssrptr_bin) begin
        // ......RQQQQQW......
        hfull <= ((wptr - ssrptr_bin) > ((1<<(AWIDTH-1))-1));
     end else begin
        // QQQQQQW......RQQQQQ
        hfull <= ((ssrptr_bin - wptr)  < ((1<<(AWIDTH-1))-1));
     end
   

   // hookup generic dual ported memory
/*
   mybram #(.C_DATA_WIDTH(DWIDTH),
          .C_DATA_DEPTH(1<<AWIDTH),
          .C_ADDR_WIDTH(AWIDTH))
   fifo_dc_mem (.aclk(rclk),
                .aaddr(rptr),
                .adin(0),
                .adout(q),
                .awe(1'b0),
                .aen(1'b1),
                
                .bclk(wclk),
                .baddr(wptr),
                .bdin(d),
                .bdout (),
                .bwe(wreq),
                .ben(1'b1)
                );
   
*/   
   
   generic_dpram #(AWIDTH, DWIDTH) fifo_dc_mem(
		                               .rclk(rclk),
		                               .rrst(1'b0),
		                               .rce(1'b1),
		                               .oe(1'b1),
		                               .raddr(rptr),
		                               .dout(q),
		                               .wclk(wclk),
		                               .wrst(1'b0),
		                               .wce(1'b1),
		                               .we(wreq),
		                               .waddr(wptr),
		                               .di(d)
	                                       );

endmodule

module generic_dpram(
	             // Generic synchronous dual-port RAM interface
	             rclk, rrst, rce, oe, raddr, dout,
	             wclk, wrst, wce, we, waddr, di
                     );

   //
   // Default address and data buses width
   //
   parameter aw = 5;  // number of bits in address-bus
   parameter dw = 16; // number of bits in data-bus

   //
   // Generic synchronous double-port RAM interface
   //
   // read port
   input           rclk;  // read clock, rising edge trigger
   input           rrst;  // read port reset, active high
   input           rce;   // read port chip enable, active high
   input           oe;	   // output enable, active high
   input [aw-1:0]  raddr; // read address
   output [dw-1:0] dout;    // data output

   // write port
   input           wclk;  // write clock, rising edge trigger
   input           wrst;  // write port reset, active high
   input           wce;   // write port chip enable, active high
   input           we;    // write enable, active high
   input [aw-1:0]  waddr; // write address
   input [dw-1:0]  di;    // data input

   //
   // Module body
   //

   //
   // Instantiation synthesizeable FPGA memory
   //
   // This code has been tested using LeonardoSpectrum and Synplicity.
   // The code correctly instantiates Altera EABs and Xilinx BlockRAMs.
   //

   // NOTE:
   // 'synthesis syn_ramstyle="block_ram"' is a Synplify attribute.
   // It instructs Synplify to map to BlockRAMs instead of the default SelectRAMs

   reg [dw-1:0]    mem [(1<<aw) -1:0] /* synthesis syn_ramstyle="block_ram" */;
   reg [aw-1:0]    ra;                // register read address

   // read operation
   always @(posedge rclk)
     if (rce)
       ra <= #1 raddr;

   assign dout = mem[ra];

   // write operation
   always @(posedge wclk)
     if (we && wce)
       mem[waddr] <= #1 di;

endmodule

