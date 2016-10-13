

#include "../runtime.c"

int32 fib(int32 n)
{
  if (n > 1) return n + fib(n-1); else return 1;
}

int32 fac(int32 n)
{
  if (n > 1) return n * fac(n-1); else return 1;
}


void _printtst(int32 *str, int32 num)
{
  int32 buf[32];
  _print(str);
  itoah(num, buf);
  _print(buf);
  _print("\n");
}


void bootentry()
{
  _printtst("5!=", fac(5));
  _printtst("7!=", fac(7));
  _printtst("fib(8)=", fib(8));
  _printtst("fib(A)=", fib(0xA));
  _testhalt();
}
