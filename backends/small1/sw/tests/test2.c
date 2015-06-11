

#include "../runtime.c"

int32 fib(int32 n)
{
  if (n > 1) return n + fib(n-1); else return 1;
}

int32 fac(int32 n)
{
  if (n > 1) return n * fac(n-1); else return 1;
}


int32 buf[128];
void _printtst(int32 *str, int32 num)
{
  _print(str);
  itoa(num, buf);
  _print(buf);
  _print("\n");
}

void bootentry()
{
  _printtst("5!=", fac(5));
  _printtst("7!=", fac(7));
  _printtst("fib(8)=", fib(8));
  _printtst("fib(10)=", fib(10));
  _printtst("1<<2=", 1<<2);
  _printtst("1<<10=", 1<<10);
  _printtst("8>>2=", 8>>2);
  int32 tmp = 16384;
  tmp = 0 - tmp;
  _printtst("44%10=", 44%10);
  _printtst("55>100=", 55>100);
  _testhalt();
}
