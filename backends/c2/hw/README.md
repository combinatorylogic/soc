# Using a C2 SoC top module

In order to instantiate a C2 SoC with any additional modules, one have to create the following files:

- `socsignals.v` - a list of the top level SoC module ports. The only two ports always defined by the
  SoC top module are `sys_clk_in` and `sys_reset`.
  
- `socmodules.v` - a file included inside the top SoC module. At the very least it must define `clk` and
  `rst` signals (which may or may not be somehow derived from the input `sys_clk_in` and `sys_reset`).
  Add your memory-mapped devices and other module instances here.
  
- `socdata.v` - a file included in the memory output select expression. Add the output of any memory mapped
  devices added to socmodules.v
  
- `soccpusignals.v` - a list of the ports added to the CPU module
- `soccpusignalsin.v` - connect something to these extra ports

Also, it's expected that the following modules are defined elsewhere:

- `socram` - a 2-port RAM module for both code and data
- `hls_Mul` - a multiplier for the HLS-generated modules
- `hlsblockram` - a parametric single-port RAM for the HLS-generated modules

# Connecting memory-mapped devices

A typical write-only memory mapped device module should look like this:

```
module ledwriter (input clk,
                  input rst,

                  output reg [7:0] LED,
                  
                  input [31:0]     addr_b,
                  input [31:0]     data_b_in,
                  input [31:0]     data_b_we);

   always @(posedge clk)
     if (~rst) begin
        LED <= 0;
     end else begin
        if (addr_b == 65540)
          LED <= data_b_in[7:0];
     end

endmodule
```

Then just connect the second RAM port wires as follows:

```
  .addr_b(ram_addr_in_b),
  .data_b_in(ram_data_out_b),
  .data_b_we(ram_we_out)
```


# Minion C2 CPU instances

In order to create additional C2 CPU instances for an NoC, one must include
`core.v` with a `CPUNAME` macro definedto anything but `cpu`, also defining a
`CPUPREFIX` macro to a path to where the extended instructions include files for
this CPU instance are located (and make sure to avoid the path clash with the
main CPU instance includes). Connect clock, reset, two RAM ports, external stall
and any additional ports (including the NoC comms).


