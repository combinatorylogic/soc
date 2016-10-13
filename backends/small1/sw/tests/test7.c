#include "../runtime.c"

void _printnum(int32 *str, int32 v)
{
  int32 tmp[32];
  itoa(v,tmp);
  _print(str);
  _print(tmp);
  _print("\n");
}


inline int tstswitch(int x) {
  switch(x) {
  case 1: return 9;
  case 2: return 3;
  case 3: return 4;
  case 4:
  case 5:
  case 6: return 5;
  default: return 0;
  }
}

void bootentry()
{
  int i;
  int32 tst[3];
  tst[0] = 1;
  tst[1] = 3;
  tst[2] = 4;
  for(i=0;i<3;i++) {
    _printnum("N=", tstswitch(tst[i]));
  }
  _testhalt();
}
