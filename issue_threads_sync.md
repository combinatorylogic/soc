# The `%issue_threads_sync` Macro

This document provides a detailed explanation of the `%issue_threads_sync` macro used in the `soc` project.

## 1. Overview

The `%issue_threads_sync` macro is a custom syntax extension for the `clike` language. It provides a high-level interface for managing the parallel execution of hardware kernels on the C2 CPU core. It is a powerful tool for hardware/software co-design, allowing developers to write C-like code that orchestrates the execution of parallel hardware accelerators.

The macro is defined in the file `backends/c2/sw/runtime_issue.c` using a special syntax that extends the `clike` parser.

## 2. Syntax

The syntax of the `%issue_threads_sync` macro is as follows:

```c
%issue_threads_sync (kernel, cores, {fixed_args}, blitter) {
    // Body of the block
}
```

### 2.1. Arguments

The macro takes four arguments:

1.  **`kernel`**: The name of the hardware kernel to be executed in parallel. This corresponds to a Verilog module that has been processed by the HLS toolchain.
2.  **`cores`**: The number of parallel instances of the kernel to be used.
3.  **`{fixed_args}`**: A list of fixed arguments to be passed to all instances of the kernel. The arguments are specified as `name = value` pairs.
4.  **`blitter`**: The name of a "blitter" core, which is responsible for transferring data to and from the kernels.

### 2.2. Body

The body of the `%issue_threads_sync` block contains code that enqueues tasks for the hardware kernels. The `%emit_task` macro is used for this purpose.

## 3. Implementation

The `%issue_threads_sync` macro is not a simple preprocessor macro. It is a syntax extension that is processed by the `clike` compiler. When the compiler encounters this macro, it performs the following steps:

1.  **Generate a Verilog Wrapper**: The compiler calls the `gen_issue_wrapper` function, which generates a Verilog wrapper module for the specified kernel. This wrapper standardizes the interface to the kernel, making it compatible with the generic thread issue logic. The generated wrapper is placed in a file named `<kernel>_wrapper.v`.

2.  **Generate an Issue Module**: The generated wrapper file also includes the `issue.v` file, which contains the generic logic for issuing and synchronizing threads. This logic is parameterized by the metadata of the kernel, such as pipeline depth and argument lengths.

3.  **Expand the Macro**: The compiler replaces the `%issue_threads_sync` block with a sequence of other macro calls:
    *   `%issue_instance`: Instantiates the issue logic for the kernel.
    *   `%issue_setup_fixargs`: Sets up the fixed arguments for the kernel.
    *   The body of the original block is inserted here.
    *   `%issue_sync_wait`: Waits for all the issued threads to complete.
    *   `%issue_pop`: Cleans up the issue context.

## 4. How it Works

The `%issue_threads_sync` macro provides a seamless way to offload parallel computations to hardware. Here's a high-level overview of the workflow:

1.  A hardware kernel is designed in a high-level language and processed by the HLS toolchain. The toolchain generates Verilog code for the kernel and also produces metadata about the kernel's interface and pipeline structure.

2.  In the C-like application code, the `%issue_threads_sync` macro is used to orchestrate the execution of the kernel.

3.  The `clike` compiler processes the `%issue_threads_sync` block, generates the necessary Verilog wrapper and issue logic, and expands the macro into a sequence of low-level operations.

4.  Inside the body of the `%issue_threads_sync` block, the `%emit_task` macro is used to send tasks to the issue queue. Each task corresponds to one invocation of the kernel with a specific set of arguments.

5.  The issue logic, which is instantiated by the `%issue_instance` macro, dequeues tasks and assigns them to the available kernel instances.

6.  The `%issue_sync_wait` macro stalls the CPU until all the tasks in the queue have been completed by the hardware kernels.

## 5. Example Usage

The following example from `backends/c2/sw/mandfltgfx.c` shows how the `%issue_threads_sync` macro is used to render a Mandelbrot fractal:

```c
%issue_threads_sync(mand_core, 8, {cxstep = dx, ix = 0}, vmem_blit) {
    for (y = 0; y < 240; y++) {
        for (x = 0; x < 320; x++) {
            %emit_task(blit_destination = vmem + y * 320 + x,
                       cy = y_coords[y]);
        }
    }
}
```

In this example:

*   `mand_core` is the name of the Mandelbrot kernel.
*   `8` is the number of parallel cores.
*   `{cxstep = dx, ix = 0}` are the fixed arguments passed to the kernel.
*   `vmem_blit` is the blitter core used for writing to video memory.
*   The nested loops iterate over the pixels of the screen and emit a task for each pixel using the `%emit_task` macro. Each task calculates the color of a single pixel.
*   The `%issue_threads_sync` macro ensures that all the pixel calculations are completed before the program continues.
