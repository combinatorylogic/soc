#include "../runtime.c"

int32 buf[128];
void _printtst(int32 *str, int32 num)
{
  _print(str);
  itoa(num, buf);
  _print(buf);
  _print("\n");
}

int32 colors[] = {' ','.','.','.',',','_','o','i','*','#','#'};

void bootentry()
{
  int32 i;
  int32 y;
  int32 x;
  int32 * ch = colors;
  uint32 cyclesmax = 0;
  uint32 insnsmax = 0;
  int32 dx = 16384 * 1 / 100;
  int32 dx11 = dx * 11;
  // Read modules from file, add this file path to the toplevel
  //   includes section
  inline verilog usemodule "./mand.v";
  // clock and reset signals are assigned automatically,
  // reg and wire definitions are hoisted (with types 
  //   propagated from the module ports)
  inline verilog instance mand_core(cx0 = reg m0_cx0,
                                    cxstep = reg m0_cxstep,
                                    cy = reg m0_cy,
                                    ack = m0_ack,
                                    rq = reg m0_rq,
                                    counters = m0_counters);
  // hoisted definition goes into the CPU core module, as well as the
  // instance above.
  inline verilog define { reg [(7*11)-1:0] m0_counters_copy; };
  int32 ry = -8192;
  for (y = 0; y < 100; y++,ry+=dx) {
    // A custom single argument instruction with no return is generated here,
    // with statemens added to the exec stage.
    inline verilog exec(ry) { m0_cy <= ry;} noreturn;
    int32 rx = -8192;
    for (x = 0; x < 110; x+=11,rx+=dx11) {
      uint32 i0 = _perfcounter1();
      uint32 c0 = _perfcounter();
      // A custom two-argument instruction with a wait stage is generated,
      //   statements are added to exec and wait stages.
      inline verilog 
            exec (rx,dx) { m0_cx0 <= rx; m0_cxstep <= dx; m0_rq <= 1;}
            wait (m0_ack) { m0_counters_copy <= m0_counters; m0_rq <= 0; } 
                 else { m0_rq <= 0; };
      uint32 c0x = _perfcounter();
      uint32 i0x = _perfcounter1();
      c0x -= c0; i0x -= i0;
      if (c0x>cyclesmax) cyclesmax = c0x;
      if (i0x>insnsmax) insnsmax = i0x;
      for (i = 0; i < 11; i++) {
        // A custom no arguments instruction with a return value is generated,
        //  with return value statement added to exec stage
        int c = inline verilog exec {m0_counters_copy <= m0_counters_copy >> 7;}
                               return (m0_counters_copy[6:0]);
        if (c < 100) _printchr(ch[c%10]); else _printchr('+');
      }
    }
    _print("\n");
  }
  _printtst(">> Max. cycles per 11 pixels: ", cyclesmax);
  _printtst(">>  Max. insns per 11 pixels: ", insnsmax);
  _testhalt();
}
