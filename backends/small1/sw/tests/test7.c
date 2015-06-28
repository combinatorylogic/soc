#include "../runtime.c"

int32 tmp[128];
void _printnum(int32 *str, int32 v)
{
  itoa(v,tmp);
  _print(str);
  _print(tmp);
  _print("\n");
}

int32 tst[3];

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
  tst[0] = 1;
  tst[1] = 3;
  tst[2] = 4;
  for(i=0;i<3;i++) {
    _printnum("N=", tstswitch(tst[i]));
  }
  _testhalt();
}
