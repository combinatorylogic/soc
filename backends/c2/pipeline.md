# A pipeline-level parallelism in compute acceleration

For the software-leaning people it's easy to intuitively comprehend the idea of
the multi-core parallelism. If one core is doing its job in a unit of time, then
10 cores, without communication/synchronisation overhead will do 10 times more
work in the same unit of time.

It's a bit more tricky to understand the very important hardware concept of the
pipeline-level parallelism. This is exactly the reason why dedicated hardware 
(or even a reconfigurable hardware like FPGAs) can be so much more efficient than any
general-purpose compute hardware.

We'll concentrate on a specific kind of algorithms here - everything that can be
expressed as a single tight loop with a linear (non-looping, but probably
branching) control flow in the loop body.

Let's take a very simple example - computing Mandelbrot set. It's one of
those "embarrasingly parallel" problems where every point of the result is fully
independent. Because we're concocting a hardware implementation here, we'll
convert all the computation into fixed point representation. Sure we could use 
floating point too, but that would mean more restrictive hardware requirements, 
while with this fixed point implementation we can target tiny ICE40 chips. 

The inner loop will be the following:

```
for (i = 0; i < 100; i++) {
                int32 vx1 = dvx - dvy + cx;
                int32 vy1 = ((vx * vy)>>(.wf - 1)) + cy;
                vx = vx1; vy = vy1;
                dvx = (vx * vx)>> .wf;
                dvy = (vy * vy)>> .wf;
                int32 r = dvx+dvy;
                if ( r > .f 4.0 ) {
                        return i;
                }
        }
```

Quite a number of computations happening in every loop iteration: 4 additions, 3
multiplications, 3 right shifts and one comparison. On a CPU, each of this
operations will be an instruction. 11 instructions in total. Even on a very
large and complex out-of-order CPU core these 11 instructions will get retired
in more than 1 clock cycles (likely, no more than 3 instructions a cycle). But
what if we could build a custom hardware core for this inner loop? There are
some genuinely independent operations here that can all be done in parallel, but
also a lot of sequential dependency. `vx1` and `vy1` can be evaluated in
parallel, but `dvx` and `dvy` depend on both, and each 32-bit multiplication
takes some (let's say 3) clock cycles to complete. `r` also depends on `dvx` and
`dvy`.

So, how can we absorb the delay of all these dependencies? The answer is to
*pipeline* the computation, and have N threads in flight, with one thread
retiring and being reissued back into the beginning of the pipeline each clock
cycle. This way, with the most efficient OoO CPU (or an FSM hardware
implementation) finishing the computation in N * M clock cycles (with M being a
number of iterations in the loop), the pipelined version will complete N
computations in N * M clock cycles, or, effectively, each computation in M clock
cycles, completely absorbing the depth of the pipeline. No matter how long the
inner linear loop body is, all the computation in it can be absorbed with a
little overhead, making a single compute core work as efficiently as if there
were N compute cores. 

The main source of overhead in this approach is pipeline stage registers. In
most of the FPGAs, compute resources (such as multipliers) are already pipelined
anyway, so it is less wasteful than an ad hoc multi-core version.

Let's see in detail what happens in our example.

The loop body code above was compiled into the following unoptimised IR (not
much different from the LLVM IR):

```
   Z1079025 = (call () ir2-binop:Sub (var Z1079301) (var Z1079302))
   Z1079026 = (call () ir2-binop:Add (var Z1079025) (var cx))
   Z1079029 = (call () ir2-binop:Mul (var Z1079299) (var Z1079300))
   Z1079030 = (call () ir2-binop:Sub (const (ir2const) (integer 13 i32)) (const (ir2const) (integer 1 i32)))
   Z1079031 = (call () ir2-binop:AShr (var Z1079029) (var Z1079030))
   Z1079032 = (call () ir2-binop:Add (var Z1079031) (var cy))
   Z1079037 = (call () ir2-binop:Mul (var Z1079026) (var Z1079026))
   Z1079038 = (call () ir2-binop:AShr (var Z1079037) (const (ir2const) (integer 13 i32)))
   Z1079041 = (call () ir2-binop:Mul (var Z1079032) (var Z1079032))
   Z1079042 = (call () ir2-binop:AShr (var Z1079041) (const (ir2const) (integer 13 i32)))
   Z1079045 = (call () ir2-binop:Add (var Z1079038) (var Z1079042))
   Z1079047 = (call () ir2-icmp:SGT (var Z1079045) (const (ir2const) (integer 32768 i32)))
```

The compiler have synthesised the following 7-stage pipeline out of it:

* Start two multiplications and compute two additions and one subtraction (note that it worth doing these cheap
  operations as early as possible as it reduces the number of registers in the consequent pipeline stages)
* Wait
* Wait
* Complete both multiplications, compute two shifts, one addition and start a third multiplication
* Wait
* Wait
* Compute addition and comparison

Right after the 7th thread is issued, the first one will complete an iteration
and will get re-issued into the first pipeline stage. This way all the compute
resources of this pipeline are fully utilised all the time (unless threads exit
prematurely). This is a much greater efficiency than anything achievable with
any generic compute architectures (such as CPUs and GPUs), utilising a tiny
area.

Of course, such an ideal use of area and power is only possible for the
non-branching control flow. If we had branches in the linear inner loop body,
we'd have to employ a *predication*, i.e. compute all branches in parallel and
only select the result of the active path. If compiler can prove that certain
paths are mutually exclusive, it can try to share the compute resources between
both paths (e.g., if both compute paths invoke a multiplication, it will try to
align the multipliers to the same pipeline stage and merge them into one).

When area is precious, it's possible to employ a combined approach - split the
long inner loop body into two pipelines which would share the common "ALU" and
be stalled in a lock step, effectively taking 2 clock cycles per iteration (or 3
or whatever).

It also worth mentioning that certain operations can make piplines unbearably
long. For example, an integer 32-bit division is a 17-stage pipeline (or, if
you're tight on timing, even a 33-stage pipeline). Same for the square root and
floating-point operations.

Of course our example above is laughably simplistic. But, there is a very wide
range of other tasks that can be expressed as tight loops with nearly-linear
inner bodies, and all of them can benefit from this approach. To name a few:

* cryptographic algorithms
* ray tracing / ray marching
* CSG operations (e.g., computing signed distance functions)
* Numeric simulations
* Image processing

These days it's easy to get an access to very high end FPGAs (e.g., Amazon
F1 instances), so even with all the area-killing limitations listed above, it is
still a viable approach vs. GPUs and CPUs.

A 32-bit floating point version of the example above translates into a 19-stage pipeline,
and it's still possible to comfortably instantiate 8 such compute cores on a Cyclone-V 
device, giving an over 25 frames per second rendering at 800x600 resolution.

