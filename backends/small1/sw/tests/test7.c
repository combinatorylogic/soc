#include "../runtime.c"

int32 buf[128];
void _printtst(int32 *str, int32 num)
{
  _print(str);
  itoa(num, buf);
  _print(buf);
  _print("\n");
}

int32 mand(int32 cx, int32 cy)
{
  /*
    Using 20.12 fixed point representation here
   */
  int32 i;
  int32 vx = 0;
  int32 vy = 0;
  int32 dvx = 0; int32 dvy = 0;
  for (i = 0; i < 100; i++) {
    int32 vx1 = dvx - dvy + cx;
    int32 vy1 = ((vx * vy)>>11) + cy;
    vx = vx1; vy = vy1;
    dvx = (vx * vx)>>12;
    dvy = (vy * vy)>>12;
    int32 r = dvx+dvy;
    if ( r > 16384)
      return i;
  }
  return 100;
}

int32 colors[] = {' ','.','.','.',',','_','o','i','*','#','#'};

void bootentry()
{
  int32 y;
  int32 x;
  int32 * ch = colors;
  uint32 cyclesmax = 0;
  uint32 insnsmax = 0;
  for (y = 0; y < 100; y++) {
    int32 ry = (16384 * y / 100 - 8192);
    for (x = 0; x < 100; x++) {
      int32 rx = (16384 * x / 100 - 8192);
      uint32 c0 = _perfcounter();
      uint32 i0 = _perfcounter1();
      int32 c = mand(rx, ry);
      uint32 c0x = _perfcounter();
      uint32 i0x = _perfcounter1();
      c0x -= c0; i0x -= i0;
      if (c0x>cyclesmax) cyclesmax = c0x;
      if (i0x>insnsmax) insnsmax = i0x;

      if (c < 100) _printchr(ch[c%10]); else _printchr('+');
    }
    _print("\n");
  }
  _printtst(">> Max. cycles per pixel: ", cyclesmax);
  _printtst(">>  Max. insns per pixel: ", insnsmax);
  _testhalt();
}
