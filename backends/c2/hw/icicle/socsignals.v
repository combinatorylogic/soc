
              input uart_rx,
              output uart_tx,

              input [31:0] prog_addr,
              input [31:0] prog_data,
              input prog_req,
              output prog_ack,

              output [31:0] out_mem_addr,
              output [31:0] out_mem_data_w,
              output out_mem_req_w,
              input  out_mem_ack_w,

              input [31:0] out_mem_data_r,
              output out_mem_req_r,
              input  out_mem_ack_r,
                            


