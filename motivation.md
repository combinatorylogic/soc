# Why?

Compute acceleration is necessary when your existing hardware, along with your existing programming techniques, simply
cannot fit into your performance or latency requirements. You may want to render a 4k visualisation at a 60FPS rate
consistently and never skipping a frame, or be able to answer to a message received in a UDP packet in under 10us, 
or just want to avoid waiting few weeks for the result of your computational fluid dynamics simulation.

In all such cases, either some general purpose accelerator hardware or domain-specific hardware is used. The most common
case is GPUs. They started as dedicated fixed-pipeline compute accelerators for certain computer graphics problems,
and ended up as fairly generic compute acceleration tools for a wide set of parallelisable problems.

In some cases people have to build very peculiar computer architectures in order to get an acceptable performance - 
see, for example, the `Anton` computer designed for molecular dynamics simulations.

And while GPUs have a lot of potential, they're still limited, and their general purpose nature does not always play
well with power requirements. This is where FPGAs and ASICs come handy - allowing to design arbitrary architectures,
specialised to the very problem you're solving. One big issue that comes naturally with such a flexibility is an unusual
and complicated development process, requiring conflicting sets of skills and backgrounds to play well together. Software
engineers and hardware designers often fail to communicate their needs to each other, making this already complicated
development process even more error prone and costly.

People always dreamed of a way that would open hardware-based compute acceleration to those with a purely
software-oriented mindset. High-Level Synthesis, translating some *programming* language into a hardware description
language, was always appealing, and never really delivered - one must still be highly proficient in hardware design in
order to use HLS with a reasonable efficiency.

OpenCL is another such promise, it hides all the infrastructure required to deal with the hardware-accelerated kernels
away from the user. Unfortunately, it's got an opinionated programming model originating from the GPU peculiarities,
making it very hard (if possible at all) to utilise efficiently on FPGAs.

The goal of this project is to try to fill this void and design an approach that'd require only limited hardware design knowledge
from the end users, eliminates all the boilerplate and ritual that plagues all the existing tools and approaches,
and allows to produce solutions as efficient as highly optimised manually written designs.

## Main benefits

To summarise the benefits of my approach before I go into details:

* Much easier to program without compromising on optimisation quality
* More flexible than the current industry standard techniques (such as OpenCL)
* Not tied to any particular vendor (unlike, say, Xilinx HLS) and proven on a wide range of FPGA platforms
* Very scalable - applicable from the smallest and cheapest FPGA models to the top of the game compute accelerators
* Unlimited abstraction at no performance cost - this approach allows to build very high level domain-specific languages easily
* Self-containted and maintainable: a very limited number of third party dependencies, allowing to customise the entire stack 
  to some specific requirements
* Readily suitable for heterogenous systems (including hard CPUs and GPUs)
* Allows to design accelerated solutions for both latency and throughput (including hard real time)
* Can potentially be used as a back end for higher level specifications (such as Tensorflow, OpenFOAM, etc.)
* Suitable for both FPGA and ASIC designs

# A hybrid approach to compute acceleration


Here I'm proposing an array of hybrid hardware/software co-design based solutions which may be more efficient in certain
application domains than the traditional compute acceleration methods. It's geared primarily towards FPGAs, but can be
applied to ASIC design as well.

It's based on the following components:

## An HLS compiler infrastructure

This compiler is able to convert an LLVM-style IR (enhanced with some hardware-specific features) to
reasonably efficient HDL modules.

Arbitrary wide integer types are supported, as well as 32-bit floats (with parametrised floating point numbers planned).
Functions can be translated into finite state machines for sequential execution, or simple pipelines if there is no
complex control flow (`if` branches are replaced with `select` wherever possible), or, for a special case of a single
loop with a simple control flow inside, a pipeline with a reissue device around it.

Other possible translation modes are easy to add.

## A C-like compiler frontend

It's targeting both HLS and software sides. The unusual part in this language is that it's built
with extensibility in mind, allowing Lisp-style AST macros and unlimited syntax extensions on top of a core C. It can be
literally turned into any language imaginable, while still keeping a powerful optimising backend. For more background on
the power of static metaprogramming see `C-like` documentation.

For example, all of the Verilog inlining, HLS, fixed-point numbers support and workload issue functionality are
implemented using macros and syntax extensions on top of the core language.

## A simple minion CPU core design 

This core (called `c2` for no good reason whatsoever) is used in multiple parts of this compute
acceleration infrastructure.  The core itself is small, features a custom ISA designed for a large extended
instructions space. Such CPUs can be arranged into an on-chip network, communicating via FIFOs and common memory blocks.
CPU cores can run in different clock domains (depending on timing constraints of the compute accelerators they carry).

It's a typical 5-stage RISC, with 29 general purpose addressable registers (R0 and R1 are hardwired to 0 and 1, and R31
is hardwired to PC). There is a 10-bit encoding space for single word extended instructions, i.e., up to 1022 simple
3-address extended instructions per core.

## A C-like compiler backend for this ISA

A backend featuring another unusual tool - Verilog inlining. Just like one would inline
assembly into high level C code with `asm {...}`, this compiler allows to inline Verilog statements. It sounds weird,
but makes all the rest of this system very easy. For example, when one want to make a custom instruction that swaps low
and high halfs of a byte, it can be done as:

```C

  int a = inline verilog exec(b) return ({b[3:0],b[7:4]});

```

A corresponding Verilog code will be added to the current target CPU core, and an extended instruction will be used to
access it.

It's possible to instantiate modules, define module-level entities, define multi-cycle instructions or pipelined
instructions of an arbitrary depth (but they should not utilise the same writeback stage as the rest of this 5-stage CPU
pipeline, of course, so you'd need to define your own domain-specific register files for such instructions). It was
never so easy to extend your CPU with hardware-accelerated instructions.

Now, the best part is that this feature is combined with an HLS compiler. Turning a function into a hardware-accelerated
extended instruction can be as easy as just annotating it with an `__hls` attribute.

Of course, HLS itself is rather limited. One can accelerate a tight inner loop which is easy to parallelise, but if
there is a lot of data-driven divergence, if a diverse memory access is required, a pipeline-level parallelisation won't
work well on its own.

It'd apply to some very common problems like, say, raytracing, or computing a signed distance function, or solving ODEs
on a lattice, etc.

For this class of problems there is another component in this hybrid system:

## A wide-issue, massively multi-threaded extensible CPU core

It's built around the same principles (and implementing the
same `c2` ISA).  This design resembles some GPUs, in a way that it's built for throughput rather than latency. It allows
an arbitrary number of execution units, some of which are just the normal `c2` pipelines without instruction fetch and
forwarding, and all the other implement extended instructions. There is a thread issue stage, made of a number of
parallel FIFOs. Each FIFO carry an instruction, its thread ID, its PC and two "immediate" register values (because the
extended execution units cannot access register files directly).

Once an instruction is retired, a next instruction in its thread (and modifications it made to the immediate registers),
along with a thread ID and a next PC value, is added to a retirement FIFO (and there can be, obviously, more retirement
FIFOs than issue FIFOs).  They converge back into re-issue FIFOs, potentially stalling corresponding execution units if
their target retirement FIFOs are full. This way, every thread will progress rather slowly, spending a considerable
number of clock cycles on each instruction, but if there is a sufficient number of parallel threads, keeping many
execution units busy, a throughput will be much better than in a single-threaded optimised OoO CPU.

These immediate registers are a main tool for communicating between the general purpose execution units and the
domain-specific execution units that may have no register files at all or have their own register files.

This approach invokes a programming model similar to OpenCL, but does not suffer from divergence requirements of most of
the modern GPUs and allows considerably more flexibility in what kernels can do and how they can communicate.  Threads
can diverge as much as they want, as long as there is enough execution units to maintain a steady close to maximum
instruction issue rate.

Threads can be partitioned by their thread number, e.g., all the odd threads are served by a generic `c2` execution unit
`1`, and all the even threads are served by an execution unit `2`. Register files (both generic and execution-unit-specific)
are also partitioned by a thread number, and this partitioning is the only practical limitation on the number of
parallel threads executied by this accelerator module (or, in the OpenCL parlance, a "local workgroup" size).

And, of course, this approach beats GPUs by allowing arbitrarily complex extended execution units. Such unit can compute
an entire step of an ODE approximation in floating point, with probably a very high latency (due to a large number of
pipeline steps), but if most threads spend their time performing this step in their inner loops, this long pipeline will
stay sufficiently occupied for a high throughput.

For example, this architecture implementing a signed distance function computation contains the following execution
units, each featuring its own pipeline, all of different depths:

* Dot product
* Vector x matrix multiplication
* Floating point square root
* Distance to a cube
* Distance to a sphere
* Distance to a thorus
* ... an arbitrary number of other distance primitives
* 3D clamping
* Vector addition
* Cached DDR load/store (allowing multiple caches for different thread partition groups)

In a way, it's like a domain-specific GPU with a very large number of special functions implemented in hardware, and
without any divergence penalty.

All such accelerated cores can be orchestrated by simpler, linear `c2` minion cores, which, in turn, are all driven by a
single master core that communicates with an external world (via PCIe, Ethernet, etc.), accessing DDR, allowing
interrupts from the I/O devices, etc.

Individual accelerated cores can have their own access to DDR in order to write back the results of computation, they
can have exclusive ownership of some I/O devices. One SoC can contain multiple different wide-issue accelerator cores,
along with linear accelerated cores, organised into an arbirarily complex network of units communicating via FIFOs and
common RAM blocks. An FPGA or ASIC area budget is the only limitation to this complexity.


With this heterogenous multi-core parallelism with highly specialised pipeline-level parallelism, it's possible to
achieve a considerably higher efficiency than with any general purpose compute architecture. And high-end FPGAs are now
more accessible than ever, with AWS F1 instances and relatively (vs. corresponding high-end GPUs) cheap PCIe FPGA
accelerator boards available.

Also, this approach is scalable: a minimal `c2` setup with few acceleration modules is still viable on something as
small as ICE40 8k - see the BlackIce HLS Mandelbrot demo for example.


# Current state of affairs

This proposal is backed by a working demonstration of most of the components listed above. The wide-issue core is almost
complete, and all the other components are done and tested.

There is a number of demos available:

* A 1080p 30FPS floating point Mandelbrot set animation (Terasic DE10-Nano)
* 640x480 15FPS fixed point Mandelbrot set animation on BlackIce board (ICE40 8k)
* A FullHD 60FPS metaballs animation (demonstrating HLS cores with local block rams)
* Sound synthesis demo on Nexys4 DDR - demonstrating a mixture of HLS and inline Verilog for accessing custom hardware
* Implementing instructions such as integer division purely in HLS


More demos are a work in progress:
* Hardware accelerated signed-distance function computation - ray marching, collision detection, mechanical simulation
* Solving a thermal ODE on a 2D lattice
* A toy Lisp OS with a GUI, with multiple parts accelerated in hardware

## Supported (tested) FPGA boards

* ICEstick (ICE40 1k) - `c2` core does not fit, but individual HLS modules can. An alternative tiny CPU core is available.
* BlackIce I or II (ICE40 8k) - `c2` and HLS work, along with a 640x480 4bit VGA
* Digilent Nexys4 DDR (Artix 7)
* Terasic DE10-Nano (Cyclone V)
* Terasic DE0-Nano (Cyclone IV)
* LogiPi + Raspberry Pi 2 or 3 (Spartan 6)
* Digilent Atlys (Spartan 6)

Of the above, reasonable amount of resources is only available on Nexys4 DDR and DE10-Nano, so it's recommended to use
one of those to fiddle with compute acceleration aspect of this project.


# Why not RISC-V (or MIPS or OpenRisc or whatever else with a GCC support)?

Of course it should have been possible to re-use RISC-V ISA for the `c2` minion core. Yet, even the smallest meaningful
subset, RV32I, is still bigger and harder to implement than the anemic `c2` ISA. Also, extended instructions space in
RISC-V requires multi-word instructions, which is unacceptable for our purposes.

Since we had to implement our own compiler backend anyway for all the extended instructions support and for Verilog
inlining, there was no benefit whatsoever in implementing some existing well-supported ISA.


# More details

Thanks to the extensible nature of the underlying language, we can bind all pieces together nicely and provide high
level programming interface for no extra runtime cost. E.g., this is how a work unit issue loop looks like in a
Mandelbrot set demo:

```C
        int32 width = %kernel_width(mand_core); // it's a macro
        int32 halfwidth = width/2;
        float dx19 = dx * (float)width;
        
        %issue_threads_sync(mand_core, 8, {cxstep = dx, ix = 0}, vmem_blit) // and this is a macro too
        {
          int32 rpos, xpos;
          rpos = 0;
          for (int32 y = 0; y < 480; y++) {
                  cx = x0;
                  xpos = 0;
                  for (int32 x = 0; x < 640; x+= width) {
                          xpos = xpos + halfwidth;
                          int32 dst = rpos + xpos;
                          %emit_task( cx0 = cx, cy = cy,         // another syntax macro
                                      blit_destination = dst );
                          cx = cx + dx19;
                  }
                  cy = cy + dy;
                  rpos = rpos + 320;
          }
        }


```

In the example above, 8 pipelined compute cores are instantiated, with each serving 19 parallel "threads" at a time
(pipeline depth is 19 stages, but we don't really need to know it).  We're using the `x` coordinate as a thread ID
here. New workgroups are enqueued in software (with the `%emit_task` macro), and the result is accumulated using a
dedicated BLIT core `vmem_blit`.

This task enqueue loop is synchronous, i.e., at the end it waits for all enqueued tasks to complete.

Implementing all of it manually, on a lower level, would have been quite tedious (for a reference, have a look at the
impressive but insanely complicated Terasic Mandelbrot demo). In this case, combining the power of an extensible
language with a flexibility of Verilog inlining and an inline HLS, everything is done in just a few lines of mostly C
code.

The macros in this example unroll into the inlined Verilog statements, which would have been really hard to write
manually correctly. It's an example of how useful staged metaprogramming is, and, contrary to the common opinion, much
less error prone than an ad hoc boilerplate code.

As for performance, each of the 8 cores is retiring one iteration step in one clock cycle (after the initial 19 cycles),
so for 100 loop steps of 19 threads (i.e., 19 output pixels) one core takes 1919 clock cycles, or merely 101 clock cycle
per pixel. With 8 cores running in parallel, it's only 12 clock cycles per pixel at most (again, in terms of throughput,
not latency). In other words, we have a 100% ALU occupancy here. No general purpose CPU or GPU would ever be able to
achieve a comparable efficiency for the same task with the same number of ALUs. To give more numbers here, each
`mand_core` contain 12 floating point operations (1 SItoFP, 5 FAdds, 4 FMuls and one OGT), i.e., 1.8GFLOPs per compute
core at 150MHz or 14.4GFLOPs for 8 cores. It's possible to comfortably fit 16 such cores on DE10-Nano (along with `c2`
and all the infrastructure), or 28.8GFLOPs for a mid-range FPGA, which is not bad - remember, it's the actual GFLOPs,
not the unrealistic theoretical peak GFLOPs of the GPU specs. For comparison, a VC4 GPU found in Raspberry Pi runs at
400MHz with a peak performance of 24GFLOPs (and a much lower realistic throughput for this particular task).

Leaving it to the reader to assess the performance of an ASIC accelerator generated from this infrastructure, if it
contains few dozens of cores and runs at around 600MHz (which is quite realistic for even a 120nm node process).

# Communication

An accelerator can communicate with a host using a number of ways:

* Shared DDR for a SoC configuration (such as CycloneV)
* FIFOs in and out on a SoC (e.g., using a lightweight FPGA2HPS interface on CycloneV)
* PCIe for the typical compute accelerator boards (work in progress for AWS F1 and other SDAccel platforms)
* SPI (e.g., on the LogiPi board)

# Compiler frontend and backend

It may not be immediately clear from the explanation above, but this whole thing is built on top of the `clike`
project - an extensible compiler for a language superficially resembling C, but featuring proper compile time AST macros
and PEG-based syntax extensions.

The `clike` frontend is generating an LLVM-like IR (in fact, it can target LLVM directly for x86 and ARM platforms), and
it's using the Abstract SSA library from the `mbase` project to implement its own middle-layer and backend optimisations
for this IR.

Supported optimisations include (but not limited to):

* Constant folding
* Branch constraint folding
* Inlining
* Loop unrolling
* Loop strength reduction
* Loop invariant motion
* Common expression elimination
* ADCE
* Control flow simplification, `select` detection (the latter is extremely important for the HLS backend)
* Instcombine (algebraic transforms)

The optimisation and analysis passes are very flexible and reusable. It's possible to alter the sequence and insert your
own passes from your `Clike` code, without even rebuilding the compiler.

It's relatively easy to implement your own backends for this compiler infrastructure (certainly much easier than for
LLVM or GCC, for example). This project includes a backend for `c2` ISA, of course, along with another, stack-based ISA
(`small1`), and Verilog-targeting (may also target FIR RTL in the future) HLS backend. Everything is built on top of the
`mbase` framework, no LLVM components are used at the moment (may include it at a later stage though).

`mbase` itself provides a set of tools for implementing compilers, an embedded language used to write AST macros in the
`Clike` code, and pretty much all the other functionality. It's a small Lisp-like language (of course, with an
extensible PEG-based syntax) designed specifically for implementing compilers. All of this project components that are
not written in `Clike` or Verilog are implemented in `mbase`.

