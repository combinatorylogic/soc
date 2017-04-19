#include "../runtime.c"

__hls void HWMEMTEST(int32 precharge, int32 idx, int32 val, int32 *ret)
{
        
        int32 ram[64];
        
        if (precharge) {
                ram[idx] = val;
                return;
        } else {
                int32 sum = 0;
                for (int32 i = 0; i < 64; i++) {
                        sum += ram[i];
                }
                *ret = sum;
                return;
        }
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
  // Make sure it's not constant folded
        for (int32 i = 0; i < 64; i++) {
                int32 tmp;
                HWMEMTEST(1, i, i, &tmp);
        }
        
        int32 c0 = _perfcounter();
        int32 i0 = _perfcounter1();
        int32 res1;
        HWMEMTEST(0, 0, 0, &res1);
        int32 c1 = _perfcounter();
        int32 i1 = _perfcounter1();

        _printtst("result1=", res1);
        _printtst(">>  Cycles: ", c1-c0);
        _printtst(">>  Insns: ", i1-i0);
        _testhalt();
}
