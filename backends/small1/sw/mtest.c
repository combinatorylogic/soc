#include "runtime.c"
#include "malloc.c"

#include "vga.c"

inline
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

int32 colors[] = {' ','.',',','-',':','=','o','w','*','H','#'};

void bootentry()
{
  int32 y;
  int32 x;
  int32 * ch = colors;
  initvga();
 loop:
  for (x = 1024; x < 5824; x++) _vmemset(x,0);
  for (y = 0; y < 60; y++) {
    int32 ry = (16384 * y / 60 - 8192);
    for (x = 0; x < 80; x++) {
      int32 rx = (16384 * x / 80 - 8192);
      int32 c = mand(rx, ry);
      int32 dstchr;
      if (c < 100) dstchr = ch[c%10]; else dstchr = 128|'+';
      int32 pos = x + y * 80;
      _vmemset(pos + 1024, dstchr);
    }
  }
  goto loop;
}

