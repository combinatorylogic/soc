
`ifdef VGA4BIT
.vmem_we(vmem_we),
.vmem_re(vmem_re),
.vmem_in_data(vmem_in_data),
.vmem_p1_out_data(vmem_p1_out_data),
.vmem_in_addr(vmem_in_addr),
.vmem_select(vmem_select),

.vga_clsrq(vga_clsrq),
.vga_clsack(vga_clsack),

.vga_scan(vga_scan),
.vmem_bufswap(vmem_bufswap),

`endif //  `ifdef VGA4BIT
`ifdef BIGMEM
.ram1_address(ram1_address),
.ram1_burstcount(ram1_burstcount),
.ram1_waitrequest(ram1_waitrequest),
.ram1_readdata(ram1_readdata),
.ram1_readdatavalid(ram1_readdatavalid),
.ram1_read(ram1_read),
.ram1_writedata(ram1_writedata),
.ram1_byteenable(ram1_byteenable),
.ram1_write(ram1_write),
.vga_bufid(vga_bufid),
.vga_scan(vga_scan),
`endif
  
