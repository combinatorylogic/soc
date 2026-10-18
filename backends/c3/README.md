# C3 CPU Core

The C3 CPU core is a more complex CPU design derived from the C2 core. It is intended to be a central CPU, rather than a minion in an NoC.

## Key Features

*   **C2 Core**: The C3 core is based on the C2 core, a 5-stage RISC architecture.
*   **Instruction and Data Caches**: The C3 core has separate instruction and data caches (I$ and D$) to improve memory access performance.
*   **AXI4-Master Interface**: The C3 core has an AXI4-Master interface for accessing a large external memory.
*   **Stall on Cache Miss**: The C2 core's pipeline is stalled on cache misses, allowing the cache controller to fetch the required data from the external memory.

## Design

The C3 core integrates the C2 core with I$ and D$ caches and an AXI4-Master interface. The `c3_top.v` file in `backends/c3/hw/rtl` shows the top-level design.

### Block Diagram

```
+-------------------------------------------------------------------+
| C3 Core                                                           |
|                                                                   |
|  +---------------------------+      +---------------------------+ |
|  |      Instruction Cache    |      |        Data Cache         | |
|  |         (I$)              |      |          (D$)             | |
|  +---------------------------+      +---------------------------+ |
|      |                  ^              |         ^               |
|      | I-Fetch Req/Addr | I-Fill Data  | D-Access| D-Fill/WB     |
|      v                  |              v         | Data          |
|  +-------------------------------------------------------------+ |
|  | C2 Core (with stall support)                                | |
|  +-------------------------------------------------------------+ |
|      ^                  |              ^         |               |
|      | Stall Signal     |              | Stall   |               |
|      | (on miss)        |              | Signal  |               |
|      v                  v              v         v               |
|  +-------------------------------------------------------------+ |
|  |                  Cache Controller                           | |
|  +-------------------------------------------------------------+ |
|      |                  ^              |         ^               |
|      | Miss Req/Addr    | Fill Data    | Miss    | Fill/WB Data  |
|      v                  |              v         |               |
|  +-------------------------------------------------------------+ |
|  |                    AXI4-Master Interface                    | |
|  +-------------------------------------------------------------+ |
|                           |                                       |
|                           v AXI4 Bus                              |
|                      External Memory                              |
+-------------------------------------------------------------------+
```

### Implementation

*   **`c3_core.v`**: A copy of the C2 core, used as the main processing unit.
*   **`c3_top.v`**: The top-level module that integrates the C3 core with the caches and the AXI4 interface.
*   **`i_cache.v` and `d_cache.v`**: These files will contain the implementation of the instruction and data caches. The current `c3_top.v` contains dummy modules for now.

This skeleton provides a starting point for a more complex CPU design based on the C2 core. A full implementation would require designing and implementing the caches and the AXI4 interface.
