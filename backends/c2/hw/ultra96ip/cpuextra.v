
reg [31:0] c2soc_status_reg;

assign c2soc_status = c2soc_status_reg;

// 0. Stall when enable signal is deasserted

assign stall_extra = ~c2soc_en;
  
// 1. Scratchpad memory, external reading.
// User extensions must do something with both scram ports (at least short them).

wire [31:0] scram_data_in_a;
wire [31:0] scram_data_in_b;
wire [31:0] scram_addr_in_a;
wire [31:0] xscram_addr_in_b;
wire [31:0] xscram_data_out_b;
wire xscram_we_out;

wire [31:0] scram_addr_in_b;
wire [31:0] scram_data_out_b;
wire scram_we_out;

scratchram ram2(.clk(clk),
                .rst(rst),

                .data_a(scram_data_in_a),
                .addr_a(scram_addr_in_a),
                
                .data_b(scram_data_in_b),
                .addr_b(xscram_addr_in_b),
                .data_b_in(xscram_data_out_b),
                .data_b_we(xscram_we_out)
                );

// Not enabling any external writing to scratchpad memory yet, may need it
// later.
assign xscram_addr_in_b = smem_re?scram_addr_in_b:smem_addr;
assign xscram_data_out_b = scram_data_out_b;
assign xscram_we_out = smem_re?0:scram_we_out; // just a precaution
assign smem_data = scram_data_in_b;

// 2. Enable external writing to imem when external stall is asserted

assign ram_data_in_b = xram_data_in_b;
assign xram_addr_in_b = c2soc_en?ram_addr_in_b:imem_addr;

assign xram_data_out_b = c2soc_en?ram_data_out_b:imem_data;
assign xram_we_out = c2soc_en?ram_we_out_b:imem_we;

