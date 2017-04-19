#include "../runtime.c"

__hls void HWMEMTEST0(int32 x, int32 y, int32 z, int32 *ret)
{
        
        int32 ram[64];
        ram[x] = y+z;
        *ret = ram[x]+1;
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

int test[2] = {0x3, 0x7};

void bootentry()
{
        int32 c0 = _perfcounter();
        int32 i0 = _perfcounter1();
        int32 res1;
        HWMEMTEST0(2, 9, 1, &res1);
        int32 c1 = _perfcounter();
        int32 i1 = _perfcounter1();

        _printtsth("result1=", res1);
        _printtst(">>  Cycles: ", c1-c0);
        _printtst(">>  Insns: ", i1-i0);
        _testhalt();
}
