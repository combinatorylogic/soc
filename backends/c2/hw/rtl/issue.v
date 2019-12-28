
// QUEUE_PACKET includes the blit addr at the beginning, the rest is some arbitrary
// payload.


/*
 
              {  software task activation assembly  }
                         |
                         |
                         |
         +---------------+-------------------------+
         |                                         |
         |                                         |
         |  Task activation queue                  |
         |   Activating one core per cycle         |
         |                                         |
         +--------/----------+----------+------\---+
                 /           |          |       \-
               -/            |           \        \-
              /             /            |          \-
      +------/----+    +----+-----+ +----+-----+ +----\-----+
      |           |    |          | |          | |          |
      | Compute   |    | Compute  | |  Compute | | Compute  |
      |           |    |          | |          | |          |
      +-------\---+    +------/---+ +------/---+ +----------+
               \             /           -/     ----/
          +-----\-----------/-----------/------/-+
          |                                      |
          |   Compute results queue              |
          |                                      |
          |   One result per cycle               |
          |                                      |
          |                                      |
          +----------------+---------------------+
                           |
          +----------------+---------------------+
          |                                      |
          |   BLIT engine                        |
          |                                      |
          |                                      |
          |                                      |
          +--------------------------------------+

*/



// Macros to be defined before including this file:
// ISSUENAME - name of the issuer module
// COMPUTE_CORE - name of the compute core module
// BLITTER - name of the blitter module
//
//  A typical use would be:
//
// `define COMPUTE_CORE mand_core_wrapper
// `define BLITTER vram_blit
//   `include "mand_core.v"
//   `include "mand_core_wrapper.v"
//   `include "issue.v"
// `undef COMPUTE_CORE
// `undef BLITTER
//
//
// The rest goes as module parameters:
//  -- NUMBER_OF_CORES - number of compute cores to be instantiated
//  -- QUEUE_PACKET_LEN - a whole input data packet length, BLIT_WIDTH included
//  -- COMMON_ARGS_LEN - a length of a common args vector (shared between all
//                          cores and all task instances)
//  -- BLIT_ADDR_WIDTH - a width of a blitter output address bus
//  -- COMPUTE_OUT_WIDTH - a width of a single task output
//  -- COMPUTE_OUT_STAGES - a number of pipeline stages in the compute core (i.e.,
//                           a number of threads running in parallel in a
//                           single core)
//  -- INPUT_QUEUE_DEPTH - optional, depth of the input task queue
//  -- OUTPUT_QUEUE_DEPTH - optional, depth of the blitter queue

// Few thoughts:
//   - We cannot make blit parallel, in most cases, unless memory is neatly banked.
//     For the latter case, need to think more
//   - We're queueing some potentially very wide bit vectors. The output queue
//     must not be based on rams, but instead can be a chain of wide resigters
//     (see delay.v for example).
//   - Need to think how to expose custom inputs and outputs for the compute
//     cores and the blitter (e.g., for accessing common memory, etc.)
//     Most likely will go the same way as with the CPU extensions - via include
//     files, and, therefore, a separate preprocessor pass (e.g., Altera tools
//     do not support the SystemVerilog preprocessor features).

module `ISSUENAME
  (input clk,
   input                             rst,

   input [COMMON_ARGS_LEN-1:0]       common_args,
   input [RAMFILL_ARGS_LEN-1:0]      ramfill_args,

   input [QUEUE_PACKET_LEN-1:0]      queue_data_in,
   input                             queue_we,
   output                            queue_available,

   output [BLIT_WIDTH-1:0]           blit_data_out,
   output [BLIT_ADDR_WIDTH-1:0]      blit_addr_out,
   output [7:0]                      blit_burst_count, // bursting buses only
   output                            blit_we,
   input                             blit_available,
   input [BLIT_EXTRA_IN_WIDTH-1:0]   blit_extrain,
   output [BLIT_EXTRA_OUT_WIDTH-1:0] blit_extraout,

   output                            idle
   );

   wire                         queue_empty;
   wire                         queue_oready;
   wire [QUEUE_PACKET_LEN-1:0]  queue_data_out;
   reg                          queue_re;

   parameter BLIT_EXTRA_IN_WIDTH = 1;
   parameter BLIT_EXTRA_OUT_WIDTH = 1;
   parameter NUMBER_OF_CORES = 4;
   parameter COMMON_ARGS_LEN = 64;
   parameter RAMFILL_ARGS_LEN = 1;
   parameter QUEUE_PACKET_LEN = 64;
   parameter BLIT_WIDTH = 8;
   parameter BLIT_ADDR_WIDTH = 19;
   parameter COMPUTE_OUT_WIDTH = 4;
   parameter COMPUTE_OUT_STAGES = 9;
   parameter INPUT_QUEUE_DEPTH = 4;
   parameter OUTPUT_QUEUE_DEPTH = NUMBER_OF_CORES;

   widegenqueue #(.WIDTH(QUEUE_PACKET_LEN),.DEPTH(INPUT_QUEUE_DEPTH), .INPUT(1)) input_q
     (.clk(clk),
      .rst(rst),

      .queue_data_in(queue_data_in),
      .queue_we(queue_we),
      .queue_available(queue_available),

      .queue_empty(queue_empty),
      .queue_oready(queue_oready),
      .queue_data_out(queue_data_out),
      .queue_re(queue_re));


   parameter COMPUTE_OUT_FULL_WIDTH = COMPUTE_OUT_WIDTH * COMPUTE_OUT_STAGES;

   reg                                       is_req;
   reg [7:0]                                 is_req_num;


   reg [BLIT_ADDR_WIDTH-1:0]                 core_blitdst [NUMBER_OF_CORES];
   reg [QUEUE_PACKET_LEN - BLIT_ADDR_WIDTH -1:0] core_arg [NUMBER_OF_CORES];
   reg                                       core_req [NUMBER_OF_CORES];
   wire                                      core_ack [NUMBER_OF_CORES];
   wire [COMPUTE_OUT_FULL_WIDTH -1:0]        core_out [NUMBER_OF_CORES];
   reg [COMPUTE_OUT_FULL_WIDTH -1:0]         core_out_r [NUMBER_OF_CORES];
   reg                                       core_ack_r [NUMBER_OF_CORES];
   

   reg [NUMBER_OF_CORES:0]                   core_in_use;


   generate genvar corenum;
      for(corenum = 0; corenum < NUMBER_OF_CORES; corenum = corenum + 1)
        begin : generate_compute_cores
           ///// Core instances go here.
           ///// Each compute core is wrapped into a module which combines
           ///// all variable and fixed arguments into two long bit vectors.
           `COMPUTE_CORE core (.clk(clk),
                               .rst(rst),
                               .vararg(core_arg[corenum]),
                               .fixarg(common_args),
                               .ramfillarg(ramfill_args),
                               .req(core_req[corenum]),
                               .ack(core_ack[corenum]),
                               .out(core_out[corenum])
                               );
        end
   endgenerate

   //// Generating available core ID
   wire core_available;
   wire [7:0]                           next_core_id;
   generate
      for (corenum = 0; corenum < NUMBER_OF_CORES; corenum = corenum + 1) begin : next_core_ids
         wire[7:0] i;
      end
   endgenerate

   assign next_core_ids[0].i = core_in_use[0]?0:1;
   generate
      for (corenum = 1; corenum < NUMBER_OF_CORES; corenum = corenum + 1) begin : generate_next_core_id
         assign next_core_ids[corenum].i =
                                          (next_core_ids[corenum-1].i!=0)?
                                          next_core_ids[corenum-1].i:
                                          (core_in_use[corenum]?0:(corenum+1));
      end
   endgenerate
   /// Note that the ID is shifted by 1, 0 meaning no cores available
//   assign next_core_id = next_core_id_i[NUMBER_OF_CORES-1];
   assign next_core_id = next_core_ids[NUMBER_OF_CORES-1].i;
   assign core_available = next_core_id!=0;
   /////////////////////


   reg [7:0] core_released_id;

   reg [31:0] clkcounter;

   integer    corenum1;
   
   
   // Core issuer, one queue element at a time, meaning cores start at best
   // in a lock step (not counting the queue filling latency)
   always @(posedge clk)
     if (!rst) begin
        clkcounter <= 0;
        
        queue_re <= 0;
        is_req <= 0;
        is_req_num <= 0;

        for (corenum1 = 0; corenum1 < NUMBER_OF_CORES; corenum1 = corenum1 + 1) begin
           core_req[corenum1] <= 0;
           core_blitdst[corenum1] <= 0;
           core_arg[corenum1] <= 0;
           core_in_use[corenum1] <= 0;
        end

     end else begin // if (!rst)
        clkcounter <= clkcounter + 1;

        if (queue_oready && core_available && ~queue_re) begin
           `ifdef DEBUGOUT
           $display("Queue ready, core available: %b  - %d @ %d", core_in_use, next_core_id, clkcounter);
           `endif
           queue_re <= 1;
        end else queue_re <= 0;
        
        if (is_req) begin
           for (corenum1 = 0; corenum1 < NUMBER_OF_CORES; corenum1 = corenum1 + 1) begin
              if (is_req_num == corenum1) begin
                 core_req[corenum1] <= 0;
              end
           end
           if (!(queue_oready && core_available)) begin
              is_req <= 0;
           end
        end

        /*
        if (queue_re & !(queue_oready && core_available)) begin
           queue_re <= 0; // stop reading from the queue
        end else begin
        end */

        `ifdef DEBUGOUT
        if (queue_oready) begin
           $display("QUEUE OREADY {%b} @ %d", core_in_use, clkcounter);
        end
        `endif


        if (queue_re) begin
           `ifdef DEBUGOUT
           $display("QUEUE RE=1 @ %d", clkcounter);
           `endif
           
           // get an activation record from the queue, pass it to the available core, REQ it, store the BLIT destination address
           for (corenum1 = 0; corenum1 < NUMBER_OF_CORES; corenum1 = corenum1 + 1) begin
              
              if (next_core_id == (corenum1+1)) begin
                 `ifdef DEBUGOUT
                 $display("ISSUE INTO CORE %d (%d) (%d) DST={%x} @ %d", next_core_id, core_ack[corenum1], queue_oready, queue_data_out[QUEUE_PACKET_LEN - 1:
                                                         QUEUE_PACKET_LEN -
                                                         BLIT_ADDR_WIDTH], clkcounter);
                 $display("Activation vector=%x", queue_data_out);
                 `endif
                 
                 core_arg[corenum1] <= queue_data_out[QUEUE_PACKET_LEN - BLIT_ADDR_WIDTH - 1: 0];
                 core_req[corenum1] <= 1;
                 core_in_use[corenum1] <= 1;
                 is_req <= 1;
                 is_req_num <= corenum1;
                 core_blitdst[corenum1] <= queue_data_out[QUEUE_PACKET_LEN - 1:
                                                         QUEUE_PACKET_LEN -
                                                         BLIT_ADDR_WIDTH];
              end
           end
        end
        
        begin // if (queue_re)
           for (corenum1 = 0; corenum1 < NUMBER_OF_CORES; corenum1 = corenum1 + 1) begin
              if (core_released_id == corenum1 + 1) begin
                 `ifdef DEBUGOUT
                 $display("RETIRING CORE %d (%b) @ %d", corenum1+1, core_in_use, clkcounter);
                 `endif
                 core_in_use[corenum1] <= 0;
              end
           end
        end
        
     end

   //// Output queue between compute cores and blitter

   reg  [COMPUTE_OUT_FULL_WIDTH + BLIT_ADDR_WIDTH - 1: 0] out_queue_data_in;
   reg                                 out_queue_we;
   wire                                out_queue_available;
   wire [COMPUTE_OUT_FULL_WIDTH + BLIT_ADDR_WIDTH - 1: 0] out_queue_data_out;
   wire                                 out_queue_empty;
   wire                                 out_queue_oready;
   reg                                  out_queue_re;


   widegenqueue #(.WIDTH(COMPUTE_OUT_FULL_WIDTH+BLIT_ADDR_WIDTH), 
                  .DEPTH(OUTPUT_QUEUE_DEPTH)) output_q
     (.clk(clk),
      .rst(rst),

      .queue_data_in(out_queue_data_in),
      .queue_we(out_queue_we),
      .queue_available(out_queue_available),

      .queue_empty(out_queue_empty),
      .queue_oready(out_queue_oready),
      .queue_data_out(out_queue_data_out),
      .queue_re(out_queue_re));

   //// An exceptionally perverted way to generate acked core ids
   wire                                 one_core_acked;
   wire [7:0]                           acked_core_id;
   generate
      for (corenum = 0; corenum <= NUMBER_OF_CORES; corenum = corenum + 1) begin : acked_core_ids
         wire[7:0] i;
      end
   endgenerate
 
   wire [NUMBER_OF_CORES-1:0]           ack_vector;
   generate
      for (corenum = 0; corenum < NUMBER_OF_CORES; corenum = corenum + 1) begin : b1
         assign ack_vector[corenum] = core_ack_r[corenum];
      end
   endgenerate

   assign acked_core_ids[0].i = ack_vector[0];
   generate
      for (corenum = 1; corenum < NUMBER_OF_CORES; corenum = corenum + 1) begin : b2
         assign acked_core_ids[corenum].i =
                                          acked_core_ids[corenum-1].i?
                                          acked_core_ids[corenum-1].i:
                                          (ack_vector[corenum]?(corenum+1):0);
      end
   endgenerate

   // Note that ID is shifted by 1, with id==0 meaning no cores acked
   assign acked_core_id = acked_core_ids[NUMBER_OF_CORES-1].i;
   assign one_core_acked = ack_vector != 0;

   //// Feeding the ACKed core output into the output queue, one at a time,
   //// expecting the compute cores to hold ACKs until a new req is issued
   always @(posedge clk)
     if (!rst) begin
        out_queue_data_in <= 0;
        out_queue_we <= 0;
        core_released_id <= 0;
        for (corenum1 = 0; corenum1 < NUMBER_OF_CORES; corenum1 = corenum1 + 1) begin
           core_out_r[corenum1] <= 0;
           core_ack_r[corenum1] <= 0;
        end
     end else begin
        for (corenum1 = 0; corenum1 < NUMBER_OF_CORES; corenum1 = corenum1 + 1) begin
           if (core_ack[corenum1]) begin
              `ifdef DEBUGOUT
              $display("CORE ACKED, COPYING {%d}  [%b] @ %d", corenum1+1, ack_vector, clkcounter);
              `endif
              core_out_r[corenum1] <= core_out[corenum1];
              core_ack_r[corenum1] <= 1;
           end
        end
        // Queue is available and core ACKed
        if (!(out_queue_available & one_core_acked) & out_queue_we) begin
           out_queue_we <= 0;
        end
        if (out_queue_available & one_core_acked) begin
           for (corenum1 = 0; corenum1 < NUMBER_OF_CORES; corenum1 = corenum1 + 1) begin
              if (acked_core_id == (corenum1+1)) begin
                 `ifdef DEBUGOUT
                 $display("CORE ACKED %d {%b/%b} {DST=%x} {OUT=%x} @ %d", acked_core_id, ack_vector, core_in_use, core_blitdst[corenum1], core_out_r[corenum1], clkcounter);
                 `endif
                 // Move this core output into the queue
                 out_queue_data_in <= {core_blitdst[corenum1],core_out_r[corenum1]};
                 out_queue_we <= 1;
                 core_ack_r[corenum1] <= 0;
                 core_released_id <= corenum1 + 1;
              end
           end
        end else begin
           core_released_id <= 0; // if (out_queue_available & one_core_acked)
        end
        
     end // else: !if(!rst)


   //// Output queue into blitter

   reg blitter_req;
   wire blitter_ready;

   `BLITTER #(.BLIT_ADDR_WIDTH(BLIT_ADDR_WIDTH),
              .COMPUTE_OUT_FULL_WIDTH(COMPUTE_OUT_FULL_WIDTH),
              .BLIT_WIDTH(BLIT_WIDTH)) blit0
     (.clk(clk),
      .rst(rst),
      .ready(blitter_ready),
      .req(blitter_req),
      .data_out(blit_data_out),
      .addr_out(blit_addr_out),
      .burst_count(blit_burst_count),
      .we(blit_we),
      .w_ready(blit_available),
      .extrain(blit_extrain),
      .extraout(blit_extraout),
      .data_in(out_queue_data_out[COMPUTE_OUT_FULL_WIDTH -1:0]),
      .data_addr(out_queue_data_out[COMPUTE_OUT_FULL_WIDTH+BLIT_ADDR_WIDTH-1:
                                    COMPUTE_OUT_FULL_WIDTH]));

   always @(posedge clk)
     if (!rst) begin
        out_queue_re <= 0;
        blitter_req <= 0;
     end else begin
        if (out_queue_oready & blitter_ready & ~out_queue_re) begin
           out_queue_re <= 1;
           blitter_req <= 1;
        end
        if (out_queue_re|blitter_req) begin
          `ifdef DEBUGOUT

           $display("BLIT ENQUEUED {%x} DST={%x}", out_queue_data_out[COMPUTE_OUT_FULL_WIDTH -1:0],
                    out_queue_data_out[COMPUTE_OUT_FULL_WIDTH+BLIT_ADDR_WIDTH-1:
                                       COMPUTE_OUT_FULL_WIDTH]);
           
           `endif
           out_queue_re <= 0;
           blitter_req <= 0;
        end
     end // else: !if(!rst)

   // The issue machine is idle if there is nothing in the input queue,
   // nothing in the output queue, no compute cores running and blitter is idle.
   assign idle = queue_empty & out_queue_empty & core_in_use==0 & blitter_ready;


endmodule
