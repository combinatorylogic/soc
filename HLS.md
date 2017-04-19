# Usage

In order to trigger a HLS custom instructions code generation, just mark a function with an `__hls` attribute.

There is a number of limitations:

* Do not ever call things `clk`, `reset`, `ACK` and `REQ`
* Do not call labels `IDLE` and `entry`
* Do not use structures, only arrays of simple types are allowed
* Only integer and integer pointer function arguments are allowed, with pointer arguments treated as 
  function outputs.
* No function calls, direct or indirect
* Functions must return void
* Every local array is translated into a 2-port registered Verilog memory (and is likely to be synthesised on
  block rams on an FPGA). Access to different arrays is considered independent and can be parallelised.
* No floating point numbers
* No integer division

Code generated from this HLS inference should be used the same way as any other inlined Verilog - e.g.:

```bash
   mono /path/to/soc/clikecc.exe /out hlstest1.hex ./hlstest1.c
   cp *.v hlstest1_out/*.v /path/to/soc/backends/small1/hw/custom/
   (cd /path/to/soc; make logipi) # or whatever board you're using
```

The resulting bitfile can only be used with the corresponding `hlstest1.hex` file (otherwise custom instructions
encoding may be different).

# Example

Let's write a functon that counts trailing zeroes in a 32-bit number:

```C
__hls void ctz(int32 n, int32 *ret) {
    int32 msk = 1;
    for (int32 i = 0; i < 32; i++,
                              msk <<= 1)
        if (!(n & msk)) {
            *ret = i;
            return;
        }
    *ret = 32;
    return;
}
```

Now it can be used as follows:

```C
    int32 ret;
    ctz(16, &ret);
```

Just for a reference, compiler will generate a Verilog module with a following interface for this function:

```Verilog
  module ctz(input  clk,
             input  reset,
             input [31:0] n,
             output [31:0] ret,
             input  REQ,
             output  ACK);
             
 //  ...
 
endmodule
```

And a number of access custom instructions are inferred automatically behind the inlined `ctz` function call.


