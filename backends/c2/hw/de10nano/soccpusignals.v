
`ifdef VGA4BIT
output 	 vmem_we,
output 	 vmem_re,
output 	 [7:0] vmem_in_data,
input      [7:0] vmem_p1_out_data,
output 	 [19:0] vmem_in_addr,           
output reg vmem_select,
output reg vga_clsrq,
input vga_clsack,
           
input vga_scan,

output reg vmem_bufswap,           
`endif //  `ifdef VGA4BIT
`ifdef BIGMEM
/*
output  [27:0] vbuf_address;
output   [7:0] vbuf_burstcount;
input         vbuf_waitrequest;
input [127:0] vbuf_readdata;
input         vbuf_readdatavalid;
output         vbuf_read;
output [127:0] vbuf_writedata;
output  [15:0] vbuf_byteenable;
output         vbuf_write;
 */

output [28:0] ram1_address,
output [7:0] ram1_burstcount,
input    ram1_waitrequest,
input [63:0] ram1_readdata,
input     ram1_readdatavalid,
output     ram1_read,
output [63:0] ram1_writedata,
output [7:0] ram1_byteenable,
output     ram1_write,

output [1:0] vga_bufid,
input vga_scan,


`endif
