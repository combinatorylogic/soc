module offsetit64(
                input             clk,
                input             rst,
                input [23:0]      rgb,
                input [3:0]       offset,
                output reg [63:0] data,
                output reg [63:0] mask);

   always @(posedge clk)
     if (~rst) begin
        data <= 0;
        mask <= 0;
     end else begin
        case (offset)
          0: begin
             data <= rgb;
             mask <=           64'hffffff;
          end
          1: begin
             data <= {rgb, 8'h00};
             mask <=         64'hffffff00;
          end
          2: begin
             data <= {rgb, 16'h00};
             mask <=       64'hffffff0000;
          end
          3: begin
             data <= {rgb, 24'h00};
             mask <=     64'hffffff000000;
          end
          4: begin
             data <= {rgb, 24'h00,8'h00};
             mask <=   64'hffffff00000000;
          end
          5: begin
             data <= {rgb, 24'h00,16'h00};
             mask <= 64'hffffff0000000000;
          end
          6: begin
             data <= {rgb[15:0], 24'h00,24'h00};
             mask <= 64'hffff000000000000;
          end
          7: begin
             data <= {rgb[7:0], 24'h00,24'h00, 8'h00};
             mask <= 64'hff00000000000000;
          end

          // Virtual offsets, high l-word parts for offsets 6 and 7:
          8: begin
             data <= rgb[23:8];
             mask <=             64'hffff;
          end
          9: begin
             data <= rgb[23:16];
             mask <=               64'hff;
          end
        endcase
     end

endmodule
  
   
