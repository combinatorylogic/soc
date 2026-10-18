#include "./runtime_hls.c"

##define fixed_point_width = 19

#include "./arith.c"

#include "runtime_ram_sim.c"

__hls
void mand(int32 cx, int32 cy, int32 *ret)
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
                if ( r > .f 4.0 ) {
                        *ret = i;
                        return;
                }
        }
        *ret = 100;
        return;
	}

// vram byte addr starts at 0x4000000
// or 0b10 00 00000000000000000000000
// i.e., {6'b10, vga_bufid[1:0], dst[22:0]}
//   VGA 128bit Avalon address is:
//    0b10 00 0000000000000000000 - which makes sense
// Therefore, 64-bit Avalon write address must be:
//    0b10 00 00000000000000000000
// i.e., {6'b10, vga_bufid[1:0], dst[19:0]}


void bootentry()
{
  int32 dy = (.f 4.0) / 1080;
  int32 dx = (.f 4.0) / 1920;

  int32 ii = 1;
  int32 pos = 0;

  
 again:
  int32 ry = .f -2.0;
  for (int32 y = 0; y < 1080; y++, ry+=dy) {
    int32 rx = .f -2.0;
    for (int32 x = 0; x < 1920; x++, rx+=dx) {
      int32 c0;
      mand(rx,ry,&c0);
      int32 c = c0 + 100;
      int32 colour = inline verilog exec(c) {} return ({1'b0,c[7:1], c[7:0], c[7:2],2'b0});
      _vga_putpixel(x, y, colour);
      pos = pos + 1;
    }
  }
  _leds(ii<<3);
  ii++;
  goto again;
}
