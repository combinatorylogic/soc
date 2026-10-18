module stepperctl (input clk,
                   input            rst,
                   // Unipolar configuration: orange,yellow,pink,blue
                   output reg [3:0] ctl, // Should it be inverted?
                   output reg       ready,
                   
                   input            req,
                   input [31:0]     nsteps,
                   input            dir);

   // Using system clock frequency for timers
   parameter SOCFREQ=`ICEFREQ;
   parameter CFREQ=1000; // 1667 Hz max step frequency, 24RPM
   localparam ONESTEP = SOCFREQ/CFREQ;

   reg [2:0]                    step;
   reg [31:0]                    stepcount;
   reg [31:0]                    nsteps_r;
   reg                          dir_r;

   reg [23:0]                   timerr;
   wire                         stepready;
   assign stepready = timerr >= ONESTEP;
   
   always @(posedge clk)
     if (!rst) begin
        step <= 0;
        stepcount <= 0;
        ready <= 1;
        nsteps_r <= 0;
        dir_r <= 0;
        ctl <= 4'b0111;
        timerr <= 0;
     end else begin
        if (!ready) begin
           if (stepready) begin
              timerr <= 0;
              if (stepcount == nsteps_r) begin
                 ready <= 1;
                 stepcount <= 0;
              end else
                stepcount <= stepcount + 1;
              
              case (step) // 8-phase half-stepping
                0: ctl <= ~4'b0111;
                1: ctl <= ~4'b0011;
                2: ctl <= ~4'b1011;
                3: ctl <= ~4'b1001;
                4: ctl <= ~4'b1101;
                5: ctl <= ~4'b1100;
                6: ctl <= ~4'b1110;
                7: ctl <= ~4'b0110;
              endcase // case (step)
              
              if (dir)
                step <= step + 1;
              else
                step <= step - 1;
           end else begin // if (stepready)
              timerr <= timerr + 1;
           end
        end else begin// if (!ready)
           if (req) begin
              ready <= 0;
              nsteps_r <= nsteps;
              dir_r <= dir;
              timerr <= 0;
           end
        end // else: !if(!ready)
     end // else: !if(!rst)
   
        

endmodule // stepperctl

