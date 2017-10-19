# C2 SoC

C2 is a simple 5-stage RISC CPU, optimised for Xilinx 7-series and Lattice iCE40 FPGAs.
Pipeline is exposed directly in the ISA, with explicit delay slots for certain instructions.

C2 does not support interrupts, cannot be configured to use cache (and, therefore, SDRAM), and
is intended to be a *minion* CPU, suitable for synthesising high throughput network-on-chip systems.

HLS and inline Verilog are fully supported on C2, allowing to infer customised CPU nodes for the NoC.

# ISA encoding

```
Type A:   0 [ 0 0 X X X X ] [7:11 - DSTRG] [12:16 - SRCR1] [17:21 - SRCR2] [22:31 - 10xIMMED] - ALU+writeback
Type B:   1 [ 0 0 ] [3:31 - 29xIMMED] - CALL/RET/JUMP (abs)
          1 [ 0 1 ] [3:31 - 29xSIMMED] - JUMP (rel)
          1 [ 1 0 ] [3:7 - SRCR1] [8:31 - 24xSIMMED] - CJUMP - delay slots = 2
          1 [ 1 1 ] [3:7 - SRC$1] [8:12 - SRCR2] [13:31 IMMED] - CIJUMP - delay slots = 2
Type I:   0 [ 1 ] [2:6 - DSTRG] [7:31 - 25xSIMMED] - LDIMMED

Type E:   0 [ 0 0 1 1 1 1 ] [7:11 - DSTRG] [12:16 - SRCR1] [17:21 - SRCR2] [22:31 - 10xEXTCODE] - invoke an
    extended instruction
Type EE:  0 [ 0 0 1 1 1 1 ] [7:11 - DSTRG] [12:16 - SRCR1] [17:21 - SRCR2] [22:31 - 10x 1] - EXTCODE is in the
    next instruction [9:0], and [31:10] can be used for the extended immediate or whatever else

    EXTCODE[0] == 1 - stall the pipeline until the WAIT condition is released
    EXTCODE[0] == 0 - instruction is asyncronous, no need to stall the pipeline automatically (though
                       the custom code can still do it).

Type M:   0 [ 0 1 0 0 ] [5:9 - DSTRG] [10:14 - SRCR2] [15:31 - SIMMED] - LOAD MEM[R2+SIMMED] to DST
          0 [ 0 1 0 1 ] [5:9 - SRCR1] [10:14 - SRCR2] [15:19 - DSTRG] - LOAD MEM[R2+R1] to DST
          0 [ 0 1 1 0 ] [5:9 - SRCR1] [10:14 - SRCR2] [15:31 - SIMMED] - MEM[R2+SIMMED] <- R1
          0 [ 0 1 1 1 ] [5:9 - SRCR1] [10:14 - SRCR2] [15:31 - SIMMED] - MEM[R2] <- R1; R2 += SIMMED
```

## Register mapping

```
   R0 = 0   (hardwired)
   R1 = 1   (hardwired)

   R2 .. R28 - general purpose, with R2 being used as a function return value

   R29 = SP (ABI convention)
   R30 = FP (ABI convention)
   R31 = PC (hardwired, not in the reg file)
```


## ALU (type A) opcodes

```
Type A opcodes:
   0: NOP // disables writeback
   1: AND
   2: ADD (+SIMMED)
   3: SUB
   4: OR
   5: NOT // R2 ignored
   6: SHL // optional barrel shifter, alternatively only supports shift by 1
   7: SHR // optional barrel shifter, alternatively only supports shift by 1
   8: XOR
   9: EQ // if immediate != 0, compare Ra with immediate
  10: NE // if immediate != 0, compare Ra with immediate
  11: CMP // all other comparisons, immediate encodes the comparison type:
      0 - SLT
      1 - SGT
      The rest is optional, core may not implement them:
      2 - SLE
      3 - SGE
      4 - ULT
      5 - UGT
      6 - ULE
      7 - UGE
  12: ASHR
  13: ---
  14: SELECT // if a previous instruction destination is R0, use the writeback in flight as
             // a condition to select Ra or Rb
  15: EXT (Type E)
```

# Available configurations

There are some configuration options available:

    1. Barrel shifter: when disabled, SHL, SHR and ASHR instructions will only shift by 1 (ignoring their second argument)
    2. Comparison instructions: when disabled, everything but EQ and NE must be implemented in software
    3. Microcoded CALL/RET
    4. Extended instructions


# FPGAs

C2 was tested on Xilinx Artix-7 (Nexys4DDR board) and Lattice ICE40.

On Artix-7 a default configuration is ok for up to 100MHz clock. On ICE40, the same configuration can sustain 
about 35MHz. Of course, using extended instructions can affect timing significantly.

The default Nexys4DDR SoC includes an LED output and a 640x480 monochrome VGA. There is also an optional UART 
(up to 115200) and an optional 7-segment display driver.

On the BlackIce board we have to stick to 25MHz, because we cannot use PLLs with 16-bit SRAM.
