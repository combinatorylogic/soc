#include "./runtime_hls.c"

##define fixed_point_width = 19

#include "./arith.c"

int32 mand(int32 cx, int32 cy)
{
  int32 i;
  int32 vx = 0;
  int32 vy = 0;
  int32 dvx = 0; int32 dvy = 0;
  for (i = 0; i < 100; i++) {
    int32 vx1 = dvx - dvy + cx;
    int32 vy1 = ((vx * vy)>>(.wf - 1)) + cy;
    vx = vx1; vy = vy1;
    dvx = (vx * vx)>> .wf;
    dvy = (vy * vy)>> .wf;
    int32 r = dvx+dvy;
    if ( r > .f 4.0 )
      return i;
  }
  return 100;
}

              
void _printnum(int32 n)
{
        int32 buf[16];
        itoa(n, buf);
        int32 *channel = (int32*)(65536);
        for(int32 i = 0; buf[i]!=0; i++) {
                *channel = buf[i];
        }
}

void bootentry()
{
  int32 y;
  int32 x;
  int32 dy = (.f 4.0) / 100;
  int32 dx = dy;
  for (y = 1; y < 100; y++) {
    int32 ry = (dy * y - .f 2.0);
    _printnum( y); _printchr(32);
    _printnum(ry); _printchr(32);
    _printnum(dy); _printchr(32);
    _printnum(dy * y); _printchr(32);
    _printchr(9);
    for (x = 1; x < 100; x++) {
      int32 rx = (dx * x - .f 2.0);
      int32 c =  mand(rx, ry);
      if (c < 100) _printchr('0'+c); else _printchr('+');
    }
    _printchr(10);_printchr(13);
  }
  _testhalt();
}
