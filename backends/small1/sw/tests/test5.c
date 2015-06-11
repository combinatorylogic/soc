#include "../runtime.c"
#include "../malloc.c"

int32 tmp[128];

void _printpos(int32 *str, int32 *ptr)
{
  int32 p = _ptrint(ptr) - _ptrint(_data);
  itoah(p,tmp);
  _print(str);
  _print(tmp);
  _print("\n");
}

void bootentry()
{
  _mem_init();
  int32 *p1 = malloc(4);
  _printpos("p1=", p1);
  int32 *p2 = malloc(4);
  _printpos("p2=", p2);
  free(p1);
  p1 = malloc(8);
  _printpos("p1'=", p1);
  p2 = malloc(4);
  _printpos("p2'=", p2);
  _testhalt();
}
