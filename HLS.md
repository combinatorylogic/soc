# Usage

In order to trigger a HLS custom instructions code generation, just mark a function with an `__hls` attribute.

HLS is supported in both Small1 and C2 backends, and is not necessarily compatible.

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

# A manually optimised example

The same function can be translated into just few clock cycles by enforcing a
loop unrolling and removing an early return. Since the compiler is not too 
smart (yet), we have to help it a bit:

```C
__hls void ctzopt(int32 n, int32 *ret) {
        int32 tmp = n;
        int32 count = 0;
        int32 done = 1;
        
        ::pragma unroll_all();
        for (int32 i = 0; i < 32 ; i++) {
                count += (!(tmp&1))&done;
                done = done?((tmp&1)?0:1):0;
                tmp >>= 1;
        }
        *ret = count;
}
```


# A more complex example

It's possible to use memories in the synthesised modules. E.g., let's implement
a dumb Eratosthenes sieve:

```C
__hls void primes(int32 stage, int32 prev, int32 *next) {
        int.1 buf[1025]; // a 1-bit array
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

# Pipelined HLS kernels

In some cases it's possible to exploit parallelism more fully by generating a pipeline
instead of an FSM, and feeding it with easily predictable input values. For example,
if we're computing the same simple inner loop for a 2-dimensional array, and the
inner loop body translates into a pipeline of a depth `N`, we can issue `N` threads at a time
computing the kernel for `[x,y], [x+1, y], ..., [x+N-1, y]`. This way, if one inner loop
runs in `M * N` clock cycles, `N` threads will finish in `M * N + N` cycles, instead of
`M * N * N` for a sequential FSM implementation. This can be parallelised further by
instantiating as many pipelined cores as we like.

There are two kinds of pipelined HLS functions supported at the moment. One is a simple
sequential CFG without any loops inside. It must be marked with a pragma in the beginning of
the function:

```C
  ::pragma hls_pipeline(threadId, threadStep, output);
```

Here, `threadId` is a register to be incremented by `threadStep` for each consequent thread issue.
`output` is an output register that will be widened to accomodate `N` threads output values.


The other kind of a pipelined function can be more complex - it must contain a simple linear CFG
inside a single-exit loop. The other restrictions include:

* No memory access (yet)
* Loop exit must be at its entry basic block (i.e., it should be a C `for` or `while` loop, as `do ... while` is not supported yet).
* No complex logic prior to the loop entry (i.e., no computation - variables must be initialised to constants or argument values)
* There must not be a possibility to move a loop invariant outside (TODO: just rematerialise everything back into the loop body)
* Output registers must not be accessed from inside the loop. The result must be accumulated after the loop exit

It is indicated by the following pragma:

```C
  ::pragma hls_pipeline_loop(threadId, threadStep, output)
```


A complete example for the latter case (a fixed-point Mandelbrot kernel, using macros defined in `demos/arith.c`):

```C
__hls
__nowrap
void mand_core(int32 cx, int32 cxstep, int32 cy, int.7 *v_out)
{
  ::pragma hls_pipeline_loop(cx, cxstep, v_out);

  int32 i;
  int32 vx = 0;
  int32 vy = 0;
  int32 dvx = 0; int32 dvy = 0;
  int32 cnd = 1;
  
  for (i = -1; (i < 99) & cnd; i++) {
    int32 vx1 = dvx - dvy + cx;
    int32 vy1 = ((vx * vy)>> (.wf - 1)) + cy;
    vx = vx1; vy = vy1;
    dvx = (vx * vx)>> .wf;
    dvy = (vy * vy)>> .wf;
    int32 r = dvx+dvy;
    if ( r > .f 4.0) {
            cnd = 0;
    }
  }
  *v_out = (i+cnd);
  return;
}
```

With a 5-stage 32-bit multiplier pipeline (e.g., the one suitable for a Xilinx
DSP48 implementation) the loop body of this kernel expands into an 11-stage
pipeline (or 11 FSM stages).  The outer loop therefore takes up to 1100 clock
cycles for a single thread, or up to 1111 clock cycles for 11 threads, making it
`10.9` times faster than a single FSM implementation. E.g., for a real time 25hz
640x480 rendering you will only need 8 instances of this core, if the base clock
is 100MHz, which is quite an efficient resource and power utilisation vs., say,
a GPU running exactly the same kernel.

You can see a 4-core version of it (suitable for the Nexys4 DDR board) in `demos/mand2gfx.c`.

# RANT

HLS has a very limited use indeed and we're not subscribing in any way to an
idea of replacing RTL with any imperative control-flow based HLS. The only
acceptable use of such a tool is a compute acceleration - like what OpenCL does
but with a fine grained control. For anything else better stick to the RTL
level - ideally enhanced with some nice features like explicit FSMs and
pipelines and implicit bus protocol specs.

# Implementation details

High-level synthesis (i.e., compiling C or any other control-flow centric
language into a behavioural RTL) is built on top of the Verilog inlining
functionality. There are currently two translation modes. One is the most
primitive and obvious conversion of the original code basic blocks into FSM
stages, producing an IP core that executes one FSM stage in one clock cycle,
potentially exploiting some natural parallelism within the basic blocks.

A more advanced translation mode is producing a linear pipeline out of a single
function body or a loop body. But, to use such an IP core efficiently one must
ensure it is fed with a continuous stream of input values, which is not always
possible.

# TODO:

It's planned to add support for:

* Accessing the system memory (including everything mapped)
* Floating point (pipelined and FSM)
* Shared ALU inference (FSM only)
* Arbitrary bit widths arithmetic (part done, need a cost model and parametric complex ops)
* Explicit vector operations
* Structures (both as registers and as a RAM datatype)
* Accessing the I/O pins directly
* Accessing block RAMs in pipelines
* Asynchronous operation of the synthesised modules (i.e., not necessarily driven by `REQ/ACK`)
* More pragmas for a fine control over synthesis
* Explicit parallelism
* Special handling for the entry level `if` chains - e.g., to be able to have both a prefill FSM and a pipeline in a single kernel.
* A transparent verilog fallback - reuse the existing inline functionality here.
* Function calls (not necessarily with inlining), but still no recursion
* Change the scheduling priorities - move everything as much down as possible to avoid needless pipeline registers propagation. This applies to things like loop induction variables, for example, if they're not used inside the loop body.

And, of course, there is a lot of optimisations that the HLS compiler can do.

# NoC:

Another vector of attack on parallelism is to utilise the Network-on-Chip pattern. The translation is, roughly, following:

* Inferred or explicitly specified concurrent processes in the source code are converted into dedicated CPU cores, each with its own set of extended instructions
* Communications channels between the concurrent processes are identified and implemented using whatever is suitable - in some cases it can be a single register, in the others it may be a FIFO or anything else.
* Each concurrent process code is compiled independently for its own CPU (besides different extensions, in theory even the basic ISAs can be different)
* The whole thing is synthesised, with compiled code for each of the CPU burned into a ROM.

So, the low level primitives for NoC synthesis are a communicating concurrent process and a communication channel. We can extend the source language with explicit means of expressing 
such primitives.

Following the old C tradition, a process primitive is represented as a function. 
