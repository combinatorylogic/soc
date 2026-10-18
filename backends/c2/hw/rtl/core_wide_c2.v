module `C2_WIDE_UNIT_NAME(input clk,
                          input                   rst,

                          input [IFDATAWIDTH]     if_out,
                          //...

                          output reg [QDATAWIDTH] out_next);
   
   wire [31:0]                          fetch_PC;
                          
   wire               if0_r0wb;
   wire [THRIDWIDTH-1:0]  if0_thrid;
   wire [PCWIDTH-1:0]     if0_pc;
   wire [INSNWIDTH01:0]   if0_insn;
   wire [NIMMEDREGS * REGWIDTH-1:0] if0_immeds;

   assign if0_out_r0wb = if_out[R0WBWIDTH-1:0];
   assign if0_immeds = if_out[R0WBWIDTH + NIMMEDREGS*REGWIDTH - 1 : R0WBWIDTH];
   assign if0_insn = if_out[R0WBWIDTH + NIMMEDREGS*REGWIDTH + INSNWIDTH - 1 : R0WBWIDTH + NIMMEDREGS*REGWIDTH];
   assign if0_pc = if_out[R0WBWIDTH + NIMMEDREGS*REGWIDTH + INSNWIDTH + PCWIDTH - 1 :
                          R0WBWIDTH + NIMMEDREGS*REGWIDTH + INSNWIDTH];
   assign if0_thrid = if_out[R0WBWIDTH + NIMMEDREGS*REGWIDTH + INSNWIDTH + PCWIDTH + THRIDWIDTH - 1:
                             R0WBWIDTH + NIMMEDREGS*REGWIDTH + INSNWIDTH + PCWIDTH];

   wire [31:0]    decode0_Instr; // Instruction as of beginning of DECODE0
   assign decode0_Instr = if0_insn;

   assign fetch_PC = if0_pc;
   
   reg [31:0]     decode0_Instr_r;
   reg            stall_r;
   
   wire [4:0]     decode0_reg1addr_next;
   wire [4:0]     decode0_reg2addr_next;
   reg [4:0]      decode_reg1addr;
   reg [4:0]      decode_reg2addr;
   reg [NIMMEDREGS * REGWIDTH] decode_immeds;
   reg [NIMMEDREGS * REGWIDTH] exec_immeds;
   reg [NIMMEDREGS * REGWIDTH] mem_immeds;
   reg [NIMMEDREGS * REGWIDTH] wb_immeds;
   
   
   wire           decode0_typea;
   wire           decode0_typeb1;
   wire           decode0_typeb2;
   wire           decode0_typei;
   wire           decode0_typee;
   wire           decode0_typem;

   assign decode0_typea = decode0_Instr[2:0] == 0; // also true for type E and type EE
   assign decode0_typeb1 = decode0_Instr[1:0] == 2'b01;
   assign decode0_typeb2 = decode0_Instr[1:0] == 2'b11;
   assign decode0_typei = decode0_Instr[1:0] == 2'b10;
   assign decode0_typem = decode0_Instr[2:0] == 3'b100;
   assign decode0_typee = decode0_Instr[6:0] == 7'b1111000;
   
   wire [31:0]    decode0_reg1addr_next1;
   wire [31:0]    decode0_reg2addr_next1;
   
   assign decode0_reg1addr_next = decode0_typea?decode0_Instr[16:12]:
                                  decode0_typeb2?decode0_Instr[7:3]:
                                  decode0_typem?decode0_Instr[9:5]:0;

   assign decode0_reg2addr_next = decode0_typea?decode0_Instr[21:17]:
                                  decode0_typeb2?decode0_Instr[12:8]:
                                  decode0_typem?decode0_Instr[14:10]:0;

   assign decode0_branch_override1 = decode_ready?decode0_typeb1:0;

   // Forwarding the simple branching PC value - 0 delay slots
   wire [31:0]    decode0_simmed29;
   assign decode0_simmed29 = {{3{decode0_Instr[31]}},decode0_Instr[31:3]};
   
   assign decode0_PC_next = decode0_typeb1?
                            (decode0_Instr[2]?(fetch_PC + decode0_simmed29):decode0_Instr[31:3]):
                            (fetch_PC + 1);

   reg [31:0]     decode_Instr;
   reg [31:0]     decode_PC;


   assign decode0_reg1addr_next1 = stall?decode_reg1addr:decode0_reg1addr_next;
   assign decode0_reg2addr_next1 = stall?decode_reg2addr:decode0_reg2addr_next;
   reg [R0WBWIDTH-1:0] decode_r0wb;
   reg [THRIDWIDTH-1:0] decode_thrid;
   reg [THRIDWIDTH-1:0] exec_thrid;
   reg [THRIDWIDTH-1:0] mem_thrid;
   reg [THRIDWIDTH-1:0] wb_thrid;

   always @(posedge clk)
     if (~rst) begin
        decode_reg1addr <= 0;
        decode_reg2addr <= 0;
        
        decode_PC <= 0;
        decode_Instr <= 0;
        // Stall logic:
        decode0_Instr_r <= 0;
        stall_r <= 0;
        decode_r0wb <= 0;
        decode_immeds <= 0;
        decode_thrid <= 0;
     end else begin
        decode_reg1addr <= decode0_reg1addr_next1;
        decode_reg2addr <= decode0_reg2addr_next1;
        decode_PC <= stall?decode_PC:decode0_PC;
        decode_Instr <= stall?decode_Instr:decode0_Instr;
        decode0_Instr_r <= decode0_Instr;
        decode_r0wb <= stall?decode_r0wb:if0_r0wb;
        decode_immeds <= stall?decode_immeds:if0_immeds;
        decode_thrid <= stall?decode_thrid:if0_thrid;
        
        stall_r <= stall;
     end // else: !if(~rst)

   //------------------------------------------------
   //--4. DECODE logic-------------------------------
   //------------------------------------------------

   wire [31:0]    decode_arg1_next;
   wire [31:0]    decode_arg2_next;

   // Register values returned from the regfile (as requested by the DECODE0 stage)
   wire [31:0]    decode_arg1_out;
   wire [31:0]    decode_arg2_out;
   reg [31:0]    decode_arg1_out_r;
   reg [31:0]    decode_arg2_out_r;

   wire [31:0]   decode_arg1_out_s = (unstall)?decode_arg1_out_r:decode_arg1_out;
   wire [31:0]   decode_arg2_out_s = (unstall)?decode_arg2_out_r:decode_arg2_out;
   
   // Register argument values, no forwarding in the WIDE core
   assign decode_arg1_next =  decode_arg1_out_s;
   assign decode_arg2_next =  decode_arg2_out_s;

   reg [31:0]     exec_Instr;
   reg [31:0]     exec_PC;
   reg [31:0]     exec_arg1_r;
   reg [31:0]     exec_arg2_r;
   reg [4:0]      exec_reg1addr;
   reg [4:0]      exec_reg2addr;
   reg [R0WBWIDTH-1:0] exec_r0wb;
   
   always @(posedge clk)
     if (~rst) begin
        exec_Instr <= 0;
        exec_PC <= 0;
        exec_arg1_r <= 0;
        exec_arg2_r <= 0;
        exec_reg1addr <= 0;
        exec_reg2addr <= 0;
        decode_arg1_out_r <= 0;
        decode_arg2_out_r <= 0;
        exec_r0wb <= 0;
        exec_immeds <= 0;
        exec_thrid <= 0;
     end else begin
        exec_Instr <= stall?exec_Instr:decode_Instr;
        exec_PC <= stall?exec_PC:decode_PC;
        exec_arg1_r <= stall?exec_arg1:decode_arg1_next;
        exec_arg2_r <= stall?exec_arg2:decode_arg2_next;
        exec_reg1addr <= stall?exec_reg1addr:decode_reg1addr;
        exec_reg2addr <= stall?exec_reg2addr:decode_reg2addr;
        exec_r0wb <= stall?exec_r0wb:decode_r0wb;
        exec_immeds <= stall?exec_immeds:decode_immeds;
        decode_arg1_out_r <= decode_arg1_out_s;
        decode_arg2_out_r <= decode_arg2_out_s;
     end // else: !if(~rst)

   //------------------------------------------------
   //--5. EXEC logic---------------------------------
   //------------------------------------------------
   wire [31:0] exec_arg1;
   wire [31:0] exec_arg2;

   assign exec_arg1 = exec_arg1_r;
   assign exec_arg2 = exec_arg2_r;
   
   wire        exec_typei;
   
   assign exec_typei = exec_Instr[1:0] == 2'b10;
   wire [3:0]  exec_opcode_typeA;
   assign exec_opcode_typeA = exec_Instr[6:3];
   
   wire        exec_typee;
   wire        exec_typeee;
   wire        exec_isext;
   wire        exec_typeb2;
   wire        exec_typem;
   wire        exec_typea;

   reg         mem_typee;
   reg         mem_typei;
   reg         mem_typem;
   reg         mem_typea;

   assign exec_typea = exec_Instr[2:0] == 0;

   wire        exec_ext_hasout;
   assign exec_ext_hasout = exec_typee;
   
   assign exec_isext = exec_typee;
   assign exec_typeb2 = exec_Instr[1:0] == 2'b11;
   assign exec_typem = exec_Instr[2:0] == 3'b100;
   assign exec_typee = exec_Instr[6:0] == 7'b1111000;
   assign exec_typeee = exec_typee & ( exec_Instr[31:22] == 10'b1111111111 );

   localparam OPC_AND = 1;
   localparam OPC_ADD = 2;
   localparam OPC_SUB = 3;
   localparam OPC_OR = 4;
   localparam OPC_NOT = 5;
   localparam OPC_SHL = 6;
   localparam OPC_SHR = 7;
   localparam OPC_XOR = 8;
   localparam OPC_EQ = 9;
   localparam OPC_NE = 10;
   localparam OPC_CMP = 11;
   localparam OPC_ASHR = 12;
   
   localparam OPC_SELECT = 14;
   
   localparam CMP_SLT = 0;
   localparam CMP_SGT = 1;
   localparam CMP_SLE = 2;
   localparam CMP_SGE = 3;
   localparam CMP_ULT = 4;
   localparam CMP_UGT = 5;
   localparam CMP_ULE = 6;
   localparam CMP_UGE = 7;
   
   wire [9:0]  exec_immed10;
   wire [31:0] exec_immed_signext;
   assign exec_immed10 = exec_Instr[31:22];

   assign exec_immed_signext = {{22{exec_Instr[31]}},exec_Instr[31:22]};
   wire [31:0]   exec_immed25_signext;
   assign exec_immed25_signext = {{7{exec_Instr[31]}},exec_Instr[31:7]};
   
   wire [31:0] exec_out_cmp;
   assign exec_out_cmp = (exec_immed10[2:0] == CMP_SLT)?($signed(exec_arg1)<$signed(exec_arg2)):
                         (exec_immed10[2:0] == CMP_SGT)?($signed(exec_arg1)>$signed(exec_arg2)):
`ifndef DISABLE_CMPOPS
                         (exec_immed10[2:0] == CMP_SLE)?($signed(exec_arg1)<=$signed(exec_arg2)):
                         (exec_immed10[2:0] == CMP_SGE)?($signed(exec_arg1)>=$signed(exec_arg2)):
                         (exec_immed10[2:0] == CMP_ULT)?(exec_arg1<exec_arg2):
                         (exec_immed10[2:0] == CMP_UGT)?(exec_arg1>exec_arg2):
                         (exec_immed10[2:0] == CMP_ULE)?(exec_arg1<=exec_arg2):
                         (exec_immed10[2:0] == CMP_UGE)?(exec_arg1>=exec_arg2):
`endif
                         0;

   wire [31:0] exec_out_next_alu;
   assign exec_out_next_alu = (exec_opcode_typeA == OPC_ADD)?
                              (exec_arg1 + exec_arg2):
                              (exec_opcode_typeA == OPC_SUB)?
                              (exec_arg1 - exec_arg2):
                              (exec_opcode_typeA == OPC_AND)?
                              (exec_arg1 & exec_arg2):
                              (exec_opcode_typeA == OPC_OR)?
                              (exec_arg1 | exec_arg2):
                              (exec_opcode_typeA == OPC_XOR)?
                              (exec_arg1 ^ exec_arg2):
                              (exec_opcode_typeA == OPC_NOT)?
                              (~exec_arg1):
`ifdef ENABLE_BARREL_SHIFTER
                              (exec_opcode_typeA == OPC_SHL)?(exec_arg1 << exec_arg2):
                              (exec_opcode_typeA == OPC_SHR)?(exec_arg1 >> exec_arg2):
                              (exec_opcode_typeA == OPC_ASHR)?$signed($signed(exec_arg1) >>> exec_arg2):
`else
                              (exec_opcode_typeA == OPC_SHL)?(exec_arg1 << 1):
                              (exec_opcode_typeA == OPC_SHR)?(exec_arg1>>1):
                              (exec_opcode_typeA == OPC_ASHR)?({exec_arg1[31],exec_arg1[31:1]}):
`endif
                              (exec_opcode_typeA == OPC_EQ)?
                              (exec_arg1 == 
                               ((exec_immed_signext == 0)?
                                exec_arg2:exec_immed_signext)):
                              (exec_opcode_typeA == OPC_NE)?
                              (exec_arg1 != exec_arg2):
                              (exec_opcode_typeA == OPC_CMP)?
                              (exec_out_cmp):
                              (exec_opcode_typeA == OPC_SELECT)?
                              (exec_r0wb?exec_arg1:exec_arg2):0;
   
   wire [1:0]  exec_opcode_typeM;
   assign exec_opcode_typeM = exec_Instr[4:3];
   localparam OPC_LOAD = 0;
   localparam OPC_LOADR = 2;
   localparam OPC_STORE = 1;
   localparam OPC_STOREI = 3;

   ///
   // EXEC memory address logic
   ///
   reg [31:0]  exec_ram_addr_b;
   wire [31:0] exec_ram_addr_b_next;
   reg [31:0]  exec_ram_data_out_b;
   
   wire [31:0] exec_ram_data_out_b_next;
   reg         exec_ram_we_out;
   wire        exec_ram_we_out_next;
   
   assign ram_addr_in_b = exec_ram_addr_b;
   assign ram_data_out_b = exec_ram_data_out_b;
   assign ram_we_out = exec_ram_we_out;

   wire [31:0] exec_simmed17;
   assign exec_simmed17 = {{15{exec_Instr[31]}},exec_Instr[31:15]};


   wire        exec_isstore;

   assign exec_isstore = exec_Instr[3];
   assign exec_ram_addr_b_next 
     =
      exec_typem?
      ((exec_opcode_typeM == OPC_STOREI)?exec_arg2:
       (exec_arg2 + exec_simmed17)):0; // both LOAD and STORE
   
   assign exec_ram_we_out_next = exec_typem&(exec_isstore);
   assign exec_ram_data_out_b_next = exec_arg1;

   reg [31:0]  mem_out_alu_r;
   reg [31:0]  mem_out_s1_r;
   reg [31:0]  mem_immed_signext_r;

   reg [31:0]  mem_Instr;
   reg [31:0]  mem_PC;

   wire [31:0] exec_simmed24;
   assign exec_simmed24 = {{8{exec_Instr[31]}},exec_Instr[31:8]};
   assign exec_branch_override2 = exec_typeb2;
   assign exec_PC_next = (exec_Instr[2:1] == 2'b01 )? 
                         (exec_arg1[0]?(exec_PC + exec_simmed24):(exec_PC + 1)):
                         (exec_arg1[0]?(exec_arg2):(exec_PC + 1));

   reg [4:0]   mem_sd_class;
   wire [4:0]  mem_sd_class_next;

   assign mem_sd_class_next[0] = exec_typei;
   assign mem_sd_class_next[1] = exec_ext_hasout;
   assign mem_sd_class_next[2] = (exec_typem&(exec_opcode_typeM==3));
   assign mem_sd_class_next[3] = exec_typea & (exec_opcode_typeA == OPC_ADD);
   assign mem_sd_class_next[4] = exec_typem && (exec_opcode_typeM == 0); // LOAD

   
`ifdef ENABLE_EXT
   `IPATH(c2_custom_hoist.v)
`endif

   reg [3:0]   sfsm_state;
   localparam S_IDLE = 0;
   localparam S_WAIT = 1;

   localparam DONE = 1;
   
   reg         ext_done;
   
   reg         stall_exec_r;
   
   assign stall_exec = (exec_typee && exec_immed10[0] && ~ext_done) || (sfsm_state == S_WAIT);

   reg [31:0]  mem_out_ext_r;
   
   always @(posedge clk)
     if (~rst) begin
        mem_out_alu_r <= 0;
        mem_out_s1_r <= 0;
        mem_Instr <= 0;
        mem_PC <= 0;
        
        mem_typee <= 0; mem_typei <= 0; mem_typem <= 0; mem_typea <= 0;
        mem_sd_class <= 0;
        
        exec_ram_addr_b <= 0;
        exec_ram_data_out_b <= 0;
        exec_ram_we_out <= 0;

        ext_done <= 0;
        sfsm_state <= S_IDLE;
        stall_exec_r <= 0;

        mem_out_ext_r <= 0;

        mem_immeds <= 0;
        mem_thrid <= 0;
        mem_r0wb <= 0;
        
              
`ifdef ENABLE_EXT
        `IPATH(c2_custom_reset.v)
`endif
        
     end else begin
        mem_out_alu_r <= stall?mem_out_alu_r:((exec_typei)?exec_immed25_signext:exec_out_next_alu);
        mem_out_s1_r  <= stall?mem_out_s1_r:(exec_arg2+exec_simmed17);
        mem_immed_signext_r <= stall?mem_immed_signext_r:exec_immed_signext;
        
        mem_Instr <= stall?mem_Instr:exec_Instr;
        mem_PC <= stall?mem_PC:exec_PC;

        mem_typee <= stall?mem_typee:exec_typee;
        mem_typei <= stall?mem_typei:exec_typei;
        mem_typem <= stall?mem_typem:exec_typem;
        mem_typea <= stall?mem_typea:exec_typea;
        mem_sd_class <= stall?mem_sd_class:mem_sd_class_next;

        mem_immeds <= stall?mem_immeds:exec_immeds;
        mem_thrid <= stall?mem_thrid:exec:thrid;
        mem_r0wb <= stall?mem_r0wb:exec_r0wb;

        // 
        exec_ram_addr_b <= exec_ram_addr_b_next;
        exec_ram_data_out_b <= exec_ram_data_out_b_next;
        exec_ram_we_out <= exec_ram_we_out_next;

`ifdef ENABLE_EXT
        `IPATH(c2_custom_pipeline.v)
`endif

        // Ext. FSM for the multi-cycle instructions (i.e., those with a wait stage)
`ifdef ENABLE_LONG_EXT
        
        stall_exec_r <= stall_exec;
        case (sfsm_state)
          S_IDLE:
            begin
               ext_done <= 0;
               if (exec_typee && exec_immed10[0] && ~stall_but_ext && ~ext_done) begin
                  sfsm_state <= S_WAIT;
               end
            end
          S_WAIT:
            begin
               `IPATH(c2_custom_wait.v)
            end
        endcase
`endif
     end
   

   //------------------------------------------------
   //--6. MEM logic----------------------------------
   //------------------------------------------------
   wire [31:0] mem_out_next;

   
   wire        mem_ext_hasout;
   assign mem_ext_hasout = mem_typee;
   
   wire [1:0]  mem_opcode_typeM;
   assign mem_opcode_typeM = mem_Instr[4:3];
   wire [3:0]  mem_opcode_typeA;
   
   assign mem_opcode_typeA = mem_Instr[6:3];
   
   wire [31:0] mem_ram_input;
   assign mem_ram_input = ram_data_in_b;

   // Selecting the right EXEC / RAM output
   assign mem_out_next = 
                         mem_sd_class==1?mem_out_alu_r:
                         mem_sd_class==2?mem_out_ext_r:
                         mem_sd_class==4?mem_out_s1_r:
                         mem_sd_class==8?(mem_out_alu_r + mem_immed_signext_r):
                         mem_out_alu_r;

   wire       mem_out_we_next;

   assign mem_out_we_next = mem_typei |
                            (mem_typea && (mem_opcode_typeA!=0)) |
                            (mem_typem && (mem_opcode_typeM == 3));

   wire       mem_out_we_delayed_next;
   
   assign mem_out_we_delayed_next = mem_out_we_next | (mem_typem && (mem_opcode_typeM != 1));
   

   wire [4:0] mem_out_reg_next;
   
   assign mem_out_reg_next =
                      mem_typea?mem_Instr[11:7]:
                      (mem_typei?mem_Instr[6:2]:
                       ((mem_typem&(mem_Instr[3]==0))?
                        mem_Instr[9:5]:
                        (mem_typem&(mem_opcode_typeM==3))?mem_Instr[14:10]:
                        mem_Instr[19:15]));

   reg [31:0] wb_Instr;
   reg [31:0] wb_PC;
   reg [31:0] mem_out;
   reg        mem_out_we;
   reg        mem_out_we_delayed;
   reg [4:0]  mem_out_reg;
   reg        wb_readmem;
   


   assign fwd_mem = mem_out_we;
   assign fwd_mem_reg = mem_out_reg;
   assign fwd_mem_data = mem_out;
   
   always @(posedge clk)
     if (~rst) begin
        wb_Instr <= 0;
        wb_PC <= 0;
        mem_out <= 0;
        mem_out_we <= 0;
        mem_out_we_delayed <= 0;
        mem_out_reg <= 0;
        wb_readmem <= 0;

        wb_immeds <= 0;
        wb_thrid <= 0;
        wb_r0wb <= 0;
        
        
     end else begin
        wb_Instr <= stall?wb_Instr:mem_Instr;
        wb_PC <= stall?wb_PC:mem_PC;
        mem_out <= stall?mem_out:mem_out_next;
        mem_out_we <= stall?mem_out_we:mem_out_we_next;
        mem_out_we_delayed <= stall?mem_out_we_delayed:mem_out_we_delayed_next;
        mem_out_reg <= stall?mem_out_reg:mem_out_reg_next;
        wb_readmem <= stall?wb_readmem:(mem_sd_class==16);

        wb_immeds <= stall?wb_immeds:mem_immeds;
        wb_thrid <= stall?wb_thrid:mem_thrid;
        wb_r0wb <= stall?wb_r0wb:mem_r0wb;

     end // else: !if(~rst)

   //------------------------------------------------
   //--7. WB logic-----------------------------------
   //------------------------------------------------

   reg [31:0] wb_out;
   reg        wb_out_we;
   reg [4:0]  wb_out_reg;

   wire [31:0] wb_ram_input;
   assign wb_ram_input = ram_data_in_b;
   wire [31:0] wb_out_next;
   wire        wb_out_we_next;
   
   
   assign wb_out_next = wb_readmem?wb_ram_input:mem_out;
   assign wb_out_we_next = mem_out_we_delayed;

   assign fwd_wb = wb_out_we;
   assign fwd_wb_reg = wb_out_reg;
   assign fwd_wb_data = wb_out;
   
   always @(posedge clk)
     if (~rst) begin
        wb_out <= 0;
        wb_out_we <= 0;
        wb_out_reg <= 0;
     end else begin
        wb_out <= stall?wb_out:wb_out_next;
        wb_out_we <= stall?wb_out_we:wb_out_we_next;
        wb_out_reg <= stall?wb_out_reg:mem_out_reg;
     end
   
   //------------------------------------------------
   //--8. Reg file instance--------------------------
   //------------------------------------------------

   // Address values for the reg file are formed in the DECODE0 stage (or after DECODE0 stage if
   //   REGFILE_REGISTERED_OUT is not set).
   // The output is ready in the DECODE stage (and quite late in it).

   // Input port address, data and WE are formed in the end of WB stage

   wire [4:0] dbgreg;
   wire       dbgreg_en;
   assign dbgreg_en = 0;
   
   
   regfile_wide #(
             .MICROOPS_ENABLED(0)
             ) regfile1
     (.clk(clk),
      .rst(rst),
      
      .PC(fetch_PC),  // PC value to be fed as a virtual register R31

      
`ifdef REGFILE_REGISTERED_OUT
      .thrid(decode0_thrid),
      .addr1(decode0_reg1addr_next1),
      .addr2(decode0_reg2addr_next1),
`else
      .thrid(decode_thrid),
      .addr1(decode_reg1addr),
      .addr2(decode_reg2addr),
`endif
      
      
      .out1(decode_arg1_out),
      .out2(decode_arg2_out),
      
      .dbgreg(dbgreg),
      .dbgreg_en(dbgreg_en),
      
      .wdata(wb_out),
      .addrw(wb_out_reg),
      .we(wb_out_we),
      .clkcounter(clkcounter) // for debugging only
      );


endmodule
