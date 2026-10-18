
`timescale 1 ns / 1 ps


// c2soc AXI Lite wrapper:
// Reg 0: reading: status (ACK)
//        writing 0 - start (req)
//        writing 1 - set argument 1
//        writing 2 - set argument 2
//        writing 3 - set argument 3
//        writing 8192 - write to mem (address start with 0 and increments)
//                       reg1 contains a size of the program,
//                       consequent writes to reg3 contain data to be written
// Reg 1: request size N (wr) or command argument, writing to this register just stores data for the next command
// Reg 2: request address, writing to this register initiates smem reading - request size must be set first
// Reg 3: read data (in word increments starting from the original request address), writing to this register does nothing useful

	module c2socx_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

   wire                     clk;
   wire                     rst;
   
   assign clk = s00_axi_aclk;
   assign rst = s00_axi_aresetn;
   
   wire [31:0]              arg1reg;
   wire [31:0]              arg2reg;
   wire [31:0]              arg3reg;
   
   wire                     c2soc_en;
   
   wire                     imem_we;
   wire [31:0]              imem_addr;
   wire [31:0]              imem_data;
   
   wire                     smem_re;
   wire [31:0]              smem_addr;
   wire [31:0]              smem_data;
   
   wire [31:0]              c2soc_status;
   

// Instantiation of Axi Bus Interface S00_AXI
	c2socx_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) c2socx_v1_0_S00_AXI_inst (
                  .arg1(arg1reg),
				  .arg2(arg2reg),
				  .arg3(arg3reg),
				  
				  .enable(c2soc_en),
				  
				  .imem_we(imem_we), 
				  .imem_addr(imem_addr),
				  .imem_data(imem_data),

				  .smem_re(smem_re), 
				  .smem_addr(smem_addr),
				  .smem_data(smem_data),
                                  .c2soc_status(c2soc_status),


		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	c2soc_top c2 (.sys_clk_in (clk),
	              .reset_n(rst),

		      // Things coming from the AXI Lite interface:
		      .arg1(arg1reg),            // Pass some 32-bit arguments to the payload program, may signal a state change
		      .arg2(arg2reg),
		      .arg3(arg3reg),
		      
		      .enable(c2soc_en),         // Stall the C2 subsystem - must be deasserted to access imem and smem
				  
		      .imem_we(imem_we),         // Rewrite instruction memory - may be followed by reset to put PC back to 0
		      .imem_addr(imem_addr),
		      .imem_data(imem_data),
		      
		      .smem_re(smem_re),         // Read data back from scratchpad memory, slowly and painfully, one word at a time
		      .smem_addr(smem_addr),
		      .smem_data(smem_data),
                      .c2soc_status(c2soc_status)
		      );
   

	// User logic ends

	endmodule
