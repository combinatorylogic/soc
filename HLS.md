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


# A more complex example

It's possible to use memories in the synthesised modules. E.g., let's implement
a dumb Eratosthenes sieve:

```C
__hls void primes(int32 stage, int32 prev, int32 *next) {
        int32 buf[1025];
        if (stage == 0) { // Precharge
                for (int i = 0; i < 1025; i++) buf[i] = 0;
                for (int m = 2; m <= 32; m++) {
                        if (!buf[m]) {
                                for (int k = m + m; k <= 1024; k+= m)
                                        buf[k] = 1;
                        }
                }
        } else if (stage == 1) { // Fetch
                for (int i = prev; i < 1025; i++) {
                        if (!buf[i]) {
                                *next = i;
                                return;
                        }
                }
                *next = 0;
                return;
        }
}
```

Please note that semantics of the local array is similar to `static` arrays -
data persists between calls, so we can select a path based on an argument
value. First call of this function will precharge the array, and then we'll use
the consequent calls to this function to fetch the data from this array.

Of course, this approach should be used sparingly - at the moment each
synthesised RAM will occupy FPGA resources and won't be shared with the other
modules.

This example does not exploit any parallelism whatsoever, but is still much
faster than a multi-cycle soft core and occupies much less resources than even a
specialised core, so it's still a useful approach for the single function
co-processors and stuff.

# TODO:

It's planned to add support for:

* Accessing the system memory (including everything mapped)
* Multiplication, division and floating point
* Shared ALU inference
* Explicit vector operations
* Structures (both as registers and as a RAM datatype)
* Arbitrary bit widths
* Accessing the I/O pins directly
* Asynchronous operation of the synthesised modules (i.e., not necessarily driven by `REQ/ACK`)
* Pipeline inference (to be able to generate designs similar to `mand.v` at least)
* Pragmas for a fine control over synthesis
* Explicit parallelism
* A transparent verilog fallback
* Function calls (not necessarily with inlining), but still no recursion

And, of course, there is a lot of optimisations that the HLS compiler can do.


