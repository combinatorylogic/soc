      nop
start:
      r9 = #data
      r8 = #20
      M[R9] = r8
      r2 = #1
      r3 = #65540
      r4 = #127
      M[r3] = r4
loop:
      r5 = M[r9]
      M[r3] = r2
      r2 = r2 + r1
      r4 = r2 == r5
      jmpc (r4) @start
      nop
      nop
      jmpr @loop
      nop
      nop



data: 
      .data 10 ;


