  .arg1(arg1reg),            // Pass some 32-bit arguments to the payload program, may signal a state change
  .arg2(arg2reg),
  .arg3(arg3reg),
  
  .enable(c2soc_en),         // Stall the C2 subsystem - mut be deasserted to access imem and smem
  
  .imem_we(imem_we),         // Rewrite instruction memory - may be followed by reset to put PC back to 0
  .imem_addr(imem_addr),
  .imem_data(imem_data),
  
  .smem_re(smem_re),         // Read data back from scratchpad memory, slowly and painfully, one word at a time
  .smem_addr(smem_addr),
  .smem_data(smem_data),  
  .c2soc_status(c2soc_status),  
