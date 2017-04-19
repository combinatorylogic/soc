#include "../runtime.c"

__hls void HWTEST(int32 x, int32 y, int32 *ret)
{
        int32 tmp = x;
        for(int32 i = 0; i < y; i++) tmp=tmp<<1;
        *ret = tmp;
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

// Integer division
inline int32 _HWTEST(int32 x, int32 y)
{
        int32 ret;
        HWTEST(x,y,&ret);
        return ret;
}

int test[2] = {0x3, 0x7};

void bootentry()
{
  // Make sure it's not constant folded
  int x = test[0];
  int y = test[1];

  int32 c0 = _perfcounter();
  int32 i0 = _perfcounter1();
  int32 res1 = x<<y;
  int32 c1 = _perfcounter();
  int32 i1 = _perfcounter1();

  int32 c0h = _perfcounter();
  int32 i0h = _perfcounter1();
  int32 res2 = _HWTEST(x, y);
  int32 c1h = _perfcounter();
  int32 i1h = _perfcounter1();

  
  _printtsth("result1=", res1);
  _printtst(">>  Cycles: ", c1-c0);
  _printtst(">>  Insns: ", i1-i0);
  _printtsth("result2=", res2);
  _printtst(">>  Cycles: ", c1h-c0h);
  _printtst(">>  Insns: ", i1h-i0h);
  
  _testhalt();
}
