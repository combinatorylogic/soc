# `hls_pipeline_loop` Kernels

This document provides a detailed explanation of how `hls_pipeline_loop` kernels work in the `soc` project, including the translation strategy and semantics.

## 1. Overview

The `hls_pipeline_loop` pragma is a feature of the `clike` language that allows developers to synthesize a pipelined hardware implementation of a loop. This is a form of High-Level Synthesis (HLS) that can significantly accelerate loop-based computations.

The implementation of this feature is located in the `verilog/` directory, with the main driver being `verilog/ll-hls-driver.hl`.

## 2. Syntax

The `hls_pipeline_loop` pragma is used as follows:

```c
__hls __nowrap void my_kernel(...) {
    ::pragma hls_pipeline_loop(threadId, threadStep, output);

    for ( ... ) {
        // Loop body
    }
    
    *output = ...;
}
```

### 2.1. Arguments

The pragma takes three arguments:

1.  **`threadId`**: A variable that is used as a thread identifier. It is incremented by `threadStep` for each concurrent thread in the pipeline.
2.  **`threadStep`**: The step value for the `threadId`.
3.  **`output`**: The output variable of the kernel.

### 2.2. Restrictions

There are several restrictions on the loops that can be pipelined using `hls_pipeline_loop`:

*   **No memory access**: The loop body cannot access memory (this is a planned feature).
*   **Single-exit loop**: The loop must have a single exit at its entry basic block (e.g., a `for` or `while` loop). `do-while` loops are not supported.
*   **No complex logic before the loop**: Variables should be initialized to constants or argument values.
*   **No loop-invariant code**: The compiler does not currently move loop-invariant code outside the loop.
*   **Output registers**: The output registers must not be accessed from inside the loop. The result should be accumulated after the loop exits.

## 3. Translation Strategy

The `clike` compiler translates a `hls_pipeline_loop` kernel into a pipelined Verilog module. This process is managed by the `ll_to_hls_driver` function in `verilog/ll-hls-driver.hl`, which implements a multi-pass transformation pipeline.

The translation strategy can be summarized as follows:

1.  **Loop Body as a Dataflow Graph**: The compiler treats the body of the loop as a dataflow graph. Each operation in the loop is a node in the graph, and the data dependencies between the operations are the edges.

2.  **Pipeline Scheduling**: The compiler schedules the operations in the dataflow graph into a pipeline. Operations that are independent of each other can be scheduled in the same pipeline stage, while dependent operations are placed in different stages. The goal is to maximize the throughput of the pipeline.

3.  **Pipeline Registers**: The compiler inserts registers between the pipeline stages to store the intermediate results. These registers are essential for pipelining, as they allow multiple iterations of the loop to be in flight at the same time.

4.  **Thread Management**: The `threadId` and `threadStep` arguments are used to manage the concurrent threads in the pipeline. The `threadId` is passed to each pipeline stage, allowing the logic in that stage to perform thread-specific operations.

5.  **Verilog Generation**: The final step is to generate a Verilog module that implements the pipeline. This module has a standardized interface that allows it to be controlled by the thread issue logic.

## 4. Semantics

The `hls_pipeline_loop` pragma transforms a sequential loop into a parallel, pipelined hardware implementation. The semantics of the transformed loop are as follows:

*   **Pipelined Execution**: The loop is executed in a pipelined manner, with multiple iterations of the loop executing concurrently in the hardware. The number of concurrent threads is determined by the depth of the pipeline.

*   **Synchronous Execution**: The execution of the pipelined loop is synchronous. When a `hls_pipeline_loop` kernel is invoked (e.g., using the `%issue_threads_sync` macro), the CPU is stalled until all the threads have completed their execution.

*   **Thread Identification**: The `threadId` variable allows the code inside the loop to be aware of which thread it is currently executing. This is useful for accessing thread-specific data or for performing thread-specific control flow.

*   **Output**: The final result of the computation is available in the `output` variable after all the threads have completed.

## 5. Example

The `mand_core` function from `HLS.md` is a good example of a `hls_pipeline_loop` kernel:

```c
__hls
__nowrap
void mand_core(int32 cx, int32 cxstep, int32 cy, int.7 *v_out)
{
  ::pragma hls_pipeline_loop(cx, cxstep, v_out);

  int32 i;
  int32 vx = 0;
  int32 vy = 0;
  // ...
  
  for (i = -1; (i < 99) & cnd; i++) {
    // ... loop body ...
  }
  *v_out = (i+cnd);
  return;
}
```

In this example, the `for` loop computes one pixel of the Mandelbrot set. The `::pragma hls_pipeline_loop` tells the compiler to create a pipelined hardware implementation of this loop. When this kernel is invoked, multiple pixels are computed in parallel in the hardware pipeline, leading to a significant performance improvement.
