/*  Microcode entries. See encode.hl for the microassembler syntax.
 */  
        
        
@PUSH:  // or pushrel
        B = #0x400
        A = ISRC&B
        A = A jnz PUSHREL

        B = 0xf
        C = ISRC&B
        A = {C}

   PUSH_common:

        C = 14    // SP
        C = {C}
        [C] = A  // [SP] = A
        
        B = 2
        A = C+B
        C = 14
        {C} = A   // SP+=2
        B = 2
        PC = PC+B
        ;STOP

  PUSHTMP: A= A jump PUSH_common

  PUSHREL:
        B = #0x3ff // mask 10 bits
        A = ISRC&B // load immediate
        B = #0x200
        A = A&B jz PUSHREL_NoSignExt
        B = #0xfc00
        A = A+B
     PUSHREL_NoSignExt:
        B = A<<1 // 2-byte align
        A = PC+B // add PC
        A = A jump PUSHTMP
        

@POP:  
        C = 14
        C = {C}
        B = #-2
        C = C+B
        A = [C]  // read stack top
        B = 0xf
        C = ISRC&B
        {C} = A  // save it to a register
        C = 14
        A = {C}
        B = #-2
        A = A+B
        {C} = A  // decrement SP

        B = 2
        PC = PC+B
        ;STOP

// Some instructions are occupying two opcodes (due to an overlapping
//    destination register number)
@ADD:
@ADDx:
                      B = 0xf  // decode vreg1
                      C = ISRC&B
                      A = {C}  // read vreg1

                      C = ISRC>>4 // decode vreg2
                      C = C&B
                      B = A
                      A = {C}+B // read vreg2, add to vreg1

                      C = ISRC>>4 // decode vreg3
                      C = C>>4
                      B = 0xf
                      C = C&B

                      {C} = A   // save result to vreg3
                      B = 2
                      PC = PC+B;

                      STOP 

@SUB:
@SUBx:
                      B = 0xf  // decode vreg1
                      C = ISRC&B
                      A = {C}  // read vreg1

                      C = ISRC>>4 // decode vreg2
                      C = C&B
                      B = A
                      A = ~{C}     // read vreg2
                      A = A+B      // add vreg1 to vreg2
                      B = 1
                      A = A+B      // add 1

                      C = ISRC>>4 // decode vreg3
                      C = C>>4
                      B = 0xf
                      C = C&B

                      {C} = A   // save result to vreg3
                      B = 2
                      PC = PC+B;

                      STOP 

@AND:
@ANDx:
                      B = 0xf  // decode vreg1
                      C = ISRC&B
                      A = {C}  // read vreg1

                      C = ISRC>>4 // decode vreg2
                      C = C&B
                      B = A
                      A = {C}&B // read vreg2, bitand with vreg1

                      C = ISRC>>4 // decode vreg3
                      C = C>>4
                      B = 0xf
                      C = C&B

                      {C} = A   // save result to vreg3
                      B = 2
                      PC = PC+B;

                      STOP 

/* a | b = ~(~a & ~b) */
@OR:
@ORx:
                      B = 0xf  // decode vreg1
                      C = ISRC&B
                      A = ~{C}  // read vreg1, negate

                      C = ISRC>>4 // decode vreg2
                      C = C&B
                      B = A
                      A = ~{C} // read vreg2, negate

                      A = A&B  // ~vreg1 AND ~vreg2

                      C = ISRC>>4 // decode vreg3
                      C = C>>4
                      B = 0xf
                      C = C&B

                      {C} = ~A   // save the negated result to vreg3
                      B = 2
                      PC = PC+B;

                      STOP 

@NAND:
@NANDx:
                      B = 0xf  // decode vreg1
                      C = ISRC&B
                      A = {C}  // read vreg1

                      C = ISRC>>4 // decode vreg2
                      C = C&B
                      B = A
                      A = {C} // read vreg2

                      A = A&B  // vreg1 AND vreg2

                      C = ISRC>>4 // decode vreg3
                      C = C>>4
                      B = 0xf
                      C = C&B

                      {C} = ~A   // save the negated result to vreg3
                      B = 2
                      PC = PC+B;

                      STOP

@MOV:
                      B = 0xf  // decode vsrc
                      C = ISRC&B
                      A = {C}  // read vsrc

                      C = ISRC>>4 // decode vdst
                      C = C&B
                      {C} = A  // write vsrc to vdst

                      B = 2
                      PC = PC+B

                      ;STOP

@MOVI:
                      B = #0x7f
                      A = ISRC&B  // extract immediate
                      
                      C = ISRC>>4
                      C = C>>1
                      C = C>>1
                      C = C>>1
                      B = 0xf
                      C = C&B   // decode vdst
                      {C} = A   // write immediate to vdst

                      B = 2
                      PC = PC+B

                      ;STOP

// Load instruction should handle unaligned single byte loads,
//  because of strings. Store does not do it, because lazy.
@LOAD:
@LOADx:
                      B = 0xf  // decode vaddr
                      C = ISRC&B
                      A = {C}  // read vreg1

                      C = ISRC>>4 // decode voffset
                      C = C&B
                      B = A
                      C = {C}+B // read voffset, add to vaddr

                      // Check if unaligned
                      B = 1
                      A = C&B
                      A = A jnz LOAD_unaligned

                      A = [C]   // load from the address
                      
                      C = ISRC>>4 // decode vdst
                      C = C>>4
                      B = 0xf
                      C = C&B

                      {C} = A   // save result to vdst

                      B = 2
                      PC = PC+B;

                      STOP
                      
            LOAD_unaligned: // one byte only!
                      B = #-1
                      C = C+B
                      A = [C]
                      A = A>>4
                      A = A>>4

                      C = ISRC>>4 // decode vdst
                      C = C>>4
                      B = 0xf
                      C = C&B

                      {C} = A   // save result to vdst

                      B = 2
                      PC = PC+B;

                      STOP

@STORE:
@STOREx:
                      B = 0xf  // decode vaddr
                      C = ISRC&B
                      A = {C}  // read vreg1

                      C = ISRC>>4 // decode voffset
                      C = C&B
                      B = A
                      A = {C}+B // read voffset, add to vaddr

                      C = ISRC>>4 // decode vsrc
                      C = C>>4
                      B = 0xf
                      C = C&B

                      B = A     // save voffset + vaddr in B
                      A = {C}   // read VSRC
                      C = 0+B   // restore dst addr in C
                      [C] = A   // write vsrc to dst

                      B = 2
                      PC = PC+B;

                      STOP

@JUMP:
                      B = #0x7ff // mask 11 bits
                      A = ISRC&B // load immediate
                      
                      B = #0x400
                      C = A&B jnz JUMP_signext
                      A=A jump JUMP_cont
    JUMP_signext:     B = #0xf800
                      A = A+B     // sign-extend
    JUMP_cont:        B = A<<1 // 2-byte align
                      PC = PC + B

                      ;STOP

@JZ:
                      C = ISRC>>4 // decode vsrc
                      C = C>>1
                      C = C>>1
                      C = C>>1
                      B = 0xf
                      C = C&B
                      A = {C}     // read vsrc
                      A = A   jz JZ_proceed
                      B = 2
                      PC = PC + B
                      ; STOP
                      
     JZ_proceed:      B = #0x7f // mask 7 bits
                      A = ISRC&B // load immediate
                      
                      B = #0x40
                      C = A&B jnz JZ_signext
                      A=A jump JZ_cont
      JZ_signext:     B = #0xff80
                      A = A+B     // sign-extend
      JZ_cont:        B = A<<1 // 2-byte align
                      PC = PC + B

                      ;STOP

@JNZ:
                      C = ISRC>>4 // decode vsrc
                      C = C>>1
                      C = C>>1
                      C = C>>1
                      B = 0xf
                      C = C&B
                      A = {C}     // read vsrc
                      A = A   jnz JNZ_proceed
                      B = 2
                      PC = PC + B
                      ; STOP
                      
    JNZ_proceed:      B = #0x7f // mask 7 bits
                      A = ISRC&B // load immediate
                      
                      B = #0x40
                      C = A&B jnz JNZ_signext
                      A=A jump JNZ_cont
     JNZ_signext:     B = #0xff80
                      A = A+B     // sign-extend
     JNZ_cont:        B = A<<1 // 2-byte align
                      PC = PC + B

                      ;STOP

// Push FP and PC, set FP to new SP

@CALL:                C = 15
                      A = {C} // read FP
                      C = 14
                      C = {C} // read SP
                     [C] = A  // store FP

                      A = PC
                      C = 14
                      B = 2
                      C = {C}+B
                      [C] = A // store PC

                      C = 14
                      B = 4
                      A = {C}+B
                      {C} = A  // SP+=4

                      C = 15
                      {C} = A  // FP = SP

                      B = #0x7ff // mask 11 bits
                      A = ISRC&B // load immediate
                      
                      B = #0x400
                      C = A&B jnz CALL_signext
                      A=A jump CALL_cont
    CALL_signext:     B = #0xf800
                      A = A+B                                       // sign-extend
    CALL_cont:        A = A<<1  A = A<<1  C = A<<1     // 8-byte align offset
                      B = #0xfff8
                      A = PC&B                                      // 8-byte align PC
                      B = C
                      PC = A + B;
                      STOP

@JUMPI:               B = 0xf    // decode vaddr
                      C = ISRC&B
                      PC = {C};  // read vaddr, set PC
                      STOP

@CALLI:               C = 15
                      A = {C} // read FP
                      C = 14
                      C = {C} // read SP
                     [C] = A  // store FP

                      A = PC
                      C = 14
                      B = 2
                      C = {C}+B
                      [C] = A // store PC

                      C = 14
                      B = 4
                      A = {C}+B
                      {C} = A  // SP+=4

                      C = 15
                      {C} = A  // FP = SP

                      B = 0xf    // decode vaddr
                      C = ISRC&B
                      PC = {C};  // read vaddr, set PC
                      STOP

@RET:                 B = #-2
                      C = 15 // FP
                      C = {C}+B // old PC pos
                      B = 2
                      PC = [C]+B // old PC value + 2
                      B = #-4
                      C = 15
                      C = {C}+B // old FP pos
                      B = [C] // old FP value

                      A = C
                      C = 14 // SP
                      {C} = A // old SP value

                      C = 15
                      A = 0+B
                      {C} = A // restore FP
                      ; STOP

@INC:
                      B = 0xf    // decode vdst
                      C = ISRC&B
                      B = 1
                      A = {C}+B  // read and inc vdst
                      {C} = A    // save it back

                      B = 2
                      PC = PC + B

                      ;STOP

@DEC:
                      B = 0xf    // decode vdst
                      C = ISRC&B
                      B = #-1
                      A = {C}+B  // read and inc vdst
                      {C} = A    // save it back

                      B = 2
                      PC = PC + B

                      ;STOP

@SHL:                 B = 0xf    // decode L
                      C = ISRC&B
                      A = {C}

                      C = ISRC>>4
                      C = C&B
                      B = {C}   // decode R

                      C = A
                      A = 0+B
                      B = #-1

         SHL_loop:    A=A jz SHL_end
                      C=C<<1
                      A=A+B
                      A=A jump SHL_loop

         SHL_end:     A=C // store the result
                      B=0xf
                      C=ISRC>>4
                     {C} = A

                      B = 2
                      PC = PC+B
                      ;STOP

@SHR:                 B = 0xf    // decode L
                      C = ISRC&B
                      A = {C}

                      C = ISRC>>4
                      C = C&B
                      B = {C}   // decode R

                      C = A
                      A = 0+B
                      B = #-1

         SHR_loop:    A=A jz SHR_end
                      C=C>>1
                      A=A+B
                      A=A jump SHR_loop

         SHR_end:     A=C // store the result
                      B=0xf
                      C=ISRC>>4
                     {C} = A

                      B = 2
                      PC = PC+B
                      ;STOP

@NOT:                 B = 0xf    // decode src
                      C = ISRC&B
                      A = ~{C}

                      C = ISRC>>4
                      C = C&B
                     {C} = A   // store the result

                      B = 2
                      PC = PC+B
                      ;STOP
                  
@EXTENDED:
        B = #0x7f0
        A = ISRC&B
        // extended op 0: long immed
        A=A   jz EXTENDED_OP0_IMMED
        // extended op 1: add with carry
        B = #-16
        A=A+B jz EXTENDED_OP1_ADDC

        // TODO: other insns
        STOP

  EXTENDED_OP0_IMMED: // long immediate into Rx
        B = PC  C = 2 + B  C = [C]
        B = 0xf B = ISRC&B
        A = C   C = 0+B   {C} = A  // store long immediate

        B = 4
        PC = PC+B
        ;STOP

  EXTENDED_OP1_ADDC: // carry bit from an addition
        // read the next instruction word:
        B = PC   C = 2+B   B = [C]
        C = 0xf & B
        A = {C}  // read vreg1

        B = PC   C = 2+B   C = [C]
        C = C>>4  B = 0xf
        C = C & B
        C = {C}  // read vreg2

        B = A
        A = C+B  // add
        A = CR   // save CR immediately, discard the addition result

        B = PC  C = 2+B   C = [C]
        C = C>>4   C = C>>4   B = 0xf    C = C&B
       {C} = A   // save into vreg3

        B = 4
        PC = PC + B

       ; STOP
        

@CUSTOM:              STOP                  
                  
