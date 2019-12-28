#include "./runtime_hls.c"

##define fixed_point_width = 19

#include "./arith.c"

#include "runtime_ram.c"

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
        /*
void readram()
{
                for (int32 dst = 0; dst < 115200; dst++) {
                int32 d = inline verilog exec(dst ) {
                         ram1_address_r  <= {6'b10, vga_bufid, dst[19:0]};
                         ram1_byteenable_r <= 8'b11111111;
                         ram1_read_r <= 1;
                } wait (ram1_readdatavalid) {
                } else {
                       if (~ram1_waitrequest) ram1_read_r <= 0;
                } return (ram1_readdata);
		if (d != 0) _leds(0);
                }
                
}
        */

inline void writerm(int32 dst, int32 data)
{
	 inline verilog exec(dst, data)
	 {
	  ram1_address_r  <= {6'b10, vga_bufid, dst[19:0]};
	  ram1_byteenable_r <= 8'b11111111;
	  ram1_writedata_r <= {dst, data[31:0]};
	 };

        
	 inline verilog exec(data) {
	   ram1_write_r <= 1;
	 } wait (~ram1_waitrequest) {
	   ram1_write_r <= 0;
	 };
}


inline void fillram(int32 data)
{
        for (int32 dst = 0; dst < 777600; dst++)
	{
   	     writerm(dst, data);
        }
}


void bootentry()
{

  _leds(128);
  fillram(0x02);
  _leds(127);

  int32 ii = 1;
  int32 pos = 0;
  int32 counter = 1;

  int32 N = 50;
  int32 dstX = .f -0.88078125;
  int32 dstY = .f 0.2206640625;
  int32 dstW = .f 0.03287109374999997;
  int32 dstH = .f 0.032851562500000014;
  int32 zoom = 10;
  int32 dz = 1;
  
 again:

  int32 X0 = .f -2.0;
  int32 Y0 = .f -2.0;
  int32 W0 = .f 4.0;
  int32 H0 = .f 4.0;

  int32 dxzoom = (dstX - X0) / N;
  int32 dyzoom = (dstY - Y0) / N;
  int32 dxzoom1 = (((X0 + W0) - (dstX + dstW))) / N;
  int32 dyzoom1 = (((Y0 + H0) - (dstY + dstH))) / N;

  int32 xstart = X0 + dxzoom * zoom;
  int32 ystart = Y0 + dyzoom * zoom;
  int32 W = X0 + W0 - dxzoom1 * zoom - xstart;
  int32 H = Y0 + H0 - dyzoom1 * zoom - ystart;

  int32 dy = H / 1080;
  int32 dx = W / 1920;

  int32 ry = Y0;
  int32 rowpos = 0;
  for (int32 y = 0; y < 1080; y++, ry+=dy) {
    int32 rx = X0;
    for (int32 x = 0; x < 1920; x++, rx+=dx) {
      int32 c0 = counter;
      counter += 17;
      //mand(rx,ry,&c0);
      int32 c = c0 + 100;
      int32 colour = c0==0?0:(
			      c0==100?0xffffff:
			      (inline verilog exec(c) {} return ({(c[0]?8'd0:c[7:0]),8'd0,
				    (c[0]?{c[7:1],1'b0}:8'd0)})));
      _vga_putpixel1(rowpos, x, colour);
      pos = pos + 1;
    }
    counter += (N+y)&0xff;
    rowpos += 5760;
  }
  _ram1_cls();
  
  zoom+=dz;
  if (zoom >= (N-5)) dz = -1;
  else if (zoom < 1) dz = 1;
  
  _leds(ii<<3);
  ii++;
  goto again;
}
