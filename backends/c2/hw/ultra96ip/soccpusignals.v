
     
      input [31:0]                             arg1reg,
      input [31:0]                             arg2reg,
      input [31:0]                             arg3reg,
      
      input                                    c2soc_en,
      
      input                                    imem_we,
      input [31:0]                             imem_addr,
      input [31:0]                             imem_data,
      
      input                                    smem_re,
      input [31:0]                             smem_addr,
      output [31:0]                            smem_data,
      output [31:0]                             c2soc_status,
