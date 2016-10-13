#include "../runtime.c"

void _printtsth(int32 *str, int32 num)
{
  int32 buf[32];
  _print(str);
  itoah(num, buf);
  _print(buf);
  _print("\n");
}

void bootentry()
{
  int x = 0xff;
  int y = 0xff;
  _printtsth("result=",inline verilog exec(x,y) {} return ({y[7:0],x[7:0]}));
  _testhalt();
}
