#include "../runtime.c"

int32 tmp[128];

typedef ::fun void(int32, int32, int32 *) myfunptr;


int32 exec(myfunptr *f, int32 a, int32 b)
{
  int32 ret;
  (*f)(a,b,&ret);
  return ret;
}

void _printnum(int32 *str, int32 v)
{
  itoa(v,tmp);
  _print(str);
  _print(tmp);
  _print("\n");
}

void add(int32 a, int32 b, int32 *ret) {*ret = a + b;}
void mul(int32 a, int32 b, int32 *ret) {*ret = a * b;}

void bootentry()
{
  int32 v = exec(&add, 10, 20);
  _printnum("add: ", v);
  v = exec(&mul, 10, 20);
  _printnum("mul: ", v);
  _testhalt();
}
