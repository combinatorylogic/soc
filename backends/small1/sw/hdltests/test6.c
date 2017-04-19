#include "../runtime.c"

__hls void HW_IDIVMOD(int32 nDividend, int32 nDivisor, int32 *Mod, int32 *Ret)
{
  int32 nQuotient = 0;
  int32 nPos = -1;
  int32 ullDivisor = nDivisor;
  int32 ullDividend = nDividend;
  int32 nbit = 1;

  while (ullDivisor <  ullDividend) {
    ullDivisor <<= 1;
    nPos ++;
    nbit <<= 1;
  }
  
  nbit >>= 1;
  ullDivisor >>= 1;
  while (nPos >= 0) {
    if (ullDividend >= ullDivisor) {
      nQuotient += nbit;
      ullDividend -= ullDivisor;
    }
      
    ullDivisor >>= 1;
    nPos -= 1;
    nbit >>= 1;
  }
  if (ullDividend == nDivisor) {
    ullDividend = 0; nQuotient++;
  }
  *Mod = ullDividend;
  *Ret = nQuotient;
}

void _printtsth(int32 *str, int32 num)
{
  int32 buf[32];
  _print(str);
  itoah(num, buf);
  _print(buf);
  _print("\n");
}
void _printtst(int32 *str, int32 num)
{
  int32 buf[32];
  _print(str);
  itoa(num, buf);
  _print(buf);
  _print("\n");
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
  int32 res2;
  HW_IDIVMOD(x, y, &md2, &res2);
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
