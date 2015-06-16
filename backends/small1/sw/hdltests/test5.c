#include "../runtime.c"

int32 buf[128];
void _printtsth(int32 *str, int32 num)
{
  _print(str);
  itoah(num, buf);
  _print(buf);
  _print("\n");
}
void _printtst(int32 *str, int32 num)
{
  _print(str);
  itoa(num, buf);
  _print(buf);
  _print("\n");
}

// Integer division
int32 _IDIVMODHW(int32 nDividend, int32 nDivisor, int32 *Mod)
{
  inline verilog usemodule "./divide.v";
  inline verilog instance idivmodhw(dividend = reg div0_dividend,
                                    divisor =  reg div0_divisor,
                                    rq = reg div0_rq,
                                    div_out = div0_out,
                                    div_mod = div0_mod,
                                    ack = div0_ack);
  inline verilog exec(nDividend, nDivisor) {
    div0_dividend <= nDividend;
    div0_divisor <= nDivisor;
    div0_rq <= 1;
  } wait (div0_ack) {
    div0_rq <= 0;
  } else { div0_rq <= 0; };
  *Mod = inline verilog exec {} return (div0_mod);
  return inline verilog exec {} return (div0_out);
}

void bootentry()
{
  int x = 0x76123;
  int y = 0x231;
  int md1;
  int md2;

  int32 c0 = _perfcounter();
  int32 i0 = _perfcounter1();
  int32 res1 = _IDIVMOD(x, y, &md1);
  int32 c1 = _perfcounter();
  int32 i1 = _perfcounter1();

  int32 c0h = _perfcounter();
  int32 i0h = _perfcounter1();
  int32 res2 = _IDIVMODHW(x, y, &md2);
  int32 c1h = _perfcounter();
  int32 i1h = _perfcounter1();

  
  _printtsth("result1=", res1);
  _printtsth("  ...mod=", md1);
  _printtst(">>  Cycles: ", c1-c0);
  _printtst(">>  Insns: ", i1-i0);
  _printtsth("result2=", res2);
  _printtsth("  ...mod=", md2);
  _printtst(">>  Cycles: ", c1h-c0h);
  _printtst(">>  Insns: ", i1h-i0h);
  
  _testhalt();
}
