// A parametric delay "queue" which does not use block rams
module gendelayqueue(input clk,
                     input              rst,
                     
                     input              we,
                     input [WIDTH-1:0]  idata,

                     input              re,
                     output [WIDTH-1:0] wdata,

                     output             oready,
                     output             full,
                     output             empty);

   parameter WIDTH=8;
   parameter DEPTH=10;
   parameter INPUT                      =0;
   


   generate genvar st;
      for (st = 1; st <= DEPTH; st = st + 1) begin : qs
         wire   qm;
         reg [WIDTH:0] q;
         wire [WIDTH:0] qn;
      end
   endgenerate
   wire [DEPTH-1:0]                tags;
   wire [DEPTH-1:0]                ntags;
   wire [DEPTH-1:0]                qvec;

   assign wdata = qs[DEPTH].q[WIDTH-1:0];
   
                
   
   assign full = qs[1].q[WIDTH];
   assign oready = qs[DEPTH].q[WIDTH];
   
   // Moving N if N+1 is empty or moving
   assign qs[1].qn = we?(qs[1].qm?{1'b1, idata}:qs[1].q):(qs[1].qm?0:qs[1].q); // up to the user not to write if full

   generate
      genvar                       stage;
      for (stage = 1; stage < DEPTH-1; stage=stage+1) begin
         // Move this stage to the next one if the next one is moving or
         // empty.
         assign qs[stage].qm = qs[stage+1].qm|(~qs[stage+1].q[WIDTH])|(~qs[stage].q[WIDTH]);
      end
   endgenerate


   generate
      genvar stage2;
       for (stage2 = 1; stage2 < DEPTH; stage2=stage2+1) begin
         assign qvec[stage2-1] = qs[stage2].qm;
      end
   endgenerate

   generate
      genvar stagex;
      for (stagex = 1; stagex <= DEPTH; stagex=stagex+1) begin
         assign tags[stagex-1] = qs[stagex].q[WIDTH];
         assign ntags[stagex-1] = qs[stagex].qn[WIDTH];
      end
   endgenerate
   assign empty = tags==0;
   
   generate
      genvar stage4;
      
      for (stage4 = 2; stage4 < DEPTH; stage4=stage4+1) begin
         // MOVE or stall
         assign qs[stage4].qn = qs[stage4].qm?qs[stage4-1].q:qs[stage4].q;
      end
   endgenerate

   assign qs[DEPTH-1].qm = re|~qs[DEPTH].q[WIDTH];
   assign qs[DEPTH].qn = re?qs[DEPTH-1].q:(qs[DEPTH].q[WIDTH]?qs[DEPTH].q:qs[DEPTH-1].q);

   integer stage1;

   reg [31:0] clkcounter;
   
   reg  [5:0]       prevfull;


   generate
      genvar        stage3;
      for (stage3 = 1; stage3 <= DEPTH; stage3=stage3+1) begin
         always @(posedge clk)
           if (!rst) begin
              qs[stage3].q <= 0;
           end else begin
              qs[stage3].q <= qs[stage3].qn;
           end
      end
   endgenerate
   
   always @(posedge clk)
     if (!rst) begin
        clkcounter <= 0;
        prevfull <= 0;
     end // if (!rst)
     else begin
        clkcounter <= clkcounter + 1;
        if (re|we) begin
           $display("QUEUE MOVING: {%b} we=%d re=%d @ %d", tags, we, re, clkcounter);
        end
        if (oready&~re) begin
           $display("QUEUE READY STALL: {%b || %b} we=%d re=%d @ %d", tags, ntags, we, re, clkcounter);
        end
        if (full) begin
           $display("QUEUE FULL: {%b} @ %d", tags, clkcounter);
           prevfull <= 3;
        end
        if (prevfull>0) begin
           $display("QUEUE WAS FULL: {%b} @ %d", tags, clkcounter);
           prevfull <= prevfull - 1;
        end
     end // else: !if(!rst)
endmodule
                  
