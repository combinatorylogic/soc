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
   parameter DEPTH=4;
   parameter XDEPTH=4;
   parameter INPUT                      =0;
   

   reg [WIDTH:0]                   q1;
   wire [WIDTH:0]                  qn1;
   reg [WIDTH:0]                   q2;
   wire [WIDTH:0]                  qn2;
   reg [WIDTH:0]                   q3;
   wire [WIDTH:0]                  qn3;
   reg [WIDTH:0]                   q4;
   wire [WIDTH:0]                  qn4;
   
   

   wire                          qm1, qm2, qm3, qm4;
   
   wire [XDEPTH-1:0]                tags;

   assign wdata = q4[WIDTH-1:0];
   
                
   
   assign full = q1[WIDTH];
   assign oready = qn4[WIDTH];
   
   // Moving N if N+1 is empty or moving
   assign qn1 = we?(qm1?{1'b1, idata}:q1):(qm1?0:q1); // up to the user not to write if full

   assign qm1 = qm2|(~q2[WIDTH])|(~q1[WIDTH]);
   assign qm2 = qm3|(~q3[WIDTH])|(~q2[WIDTH]);
   assign qm3 = qm4|(~q4[WIDTH])|(~q3[WIDTH]);
   
   assign tags[1-1] = q1[WIDTH];
   assign tags[2-1] = q2[WIDTH];
   assign tags[3-1] = q3[WIDTH];
   assign tags[4-1] = q4[WIDTH];

   assign empty = tags==0;
   
   assign qn2 = qm2?q1:q2;
   assign qn3 = qm3?q2:q3;


   
   assign qm4 = re|~q4[WIDTH];
   assign qn4 = re?q3:(q4[WIDTH]?q4:q3);

   integer stage1;

   reg [31:0] clkcounter;
   
   
   always @(posedge clk)
     if (!rst) begin
        clkcounter <= 0;
        
        q1 <= 0;
        q2 <= 0;
        q3 <= 0;
        q4 <= 0;
     end // if (!rst)
     else begin
        clkcounter <= clkcounter + 1;
 
        q1 <= qn1;
        q2 <= qn2;
        q3 <= qn3;
        q4 <= qn4;
     end // else: !if(!rst)


   reg  [5:0]       prevfull;


      
   always @(posedge clk)
     if (!rst) begin
        prevfull <= 0;
     end // if (!rst)
     else if (INPUT) begin
        `ifdef DEBUGOUT
        if (re|we) begin
           $display("QUEUE MOVING: {%b} we=%d re=%d @ %d", tags, we, re, clkcounter);
        end
        if (oready&~re) begin
           $display("QUEUE READY STALL: {%b} we=%d re=%d @ %d", tags, we, re, clkcounter);
        end
        if (full) begin
           $display("QUEUE FULL: {%b} @ %d", tags, clkcounter);
           prevfull <= 3;
        end
        if (prevfull>0) begin
           $display("QUEUE WAS FULL: {%b} @ %d", tags, clkcounter);
           prevfull <= prevfull - 1;
        end
        /*

        if (~empty) begin
           $display("QUEUE CONTENT @ %d:", clkcounter);
           
           if(q1[WIDTH]) $display("QT1 {%x}", q1[WIDTH-1:WIDTH-19]);
           if(q2[WIDTH]) $display("QT2 {%x}", q2[WIDTH-1:WIDTH-19]);
           if(q3[WIDTH]) $display("QT3 {%x}", q3[WIDTH-1:WIDTH-19]);
           if(q4[WIDTH]) $display("QT4 {%x}", q4[WIDTH-1:WIDTH-19]);
           $display("=============");
           
        end
         */
        `endif
     end // else: !if(!rst)

endmodule
                  
