// Fun fact: it actually fits 8k.
// Must assemble with disabled barrel shifter (and no muops, of course)
//
#include "./runtime_ice_small.c"

#include "./ice_vga.c"

##define fixed_point_width = 19

#include "./arith.c"

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
        
void innerloop(int32 dx, int32 dy)
{
        uint32 tmp = 0;
        int32 cnt = 0;
        int32 adr = 0;
        int32 x, y;
        int32 ry= .f -2.0;
        for (y = 0; y < 480; y++, ry+=dy) {
                int32 rx= .f -2.0;
                for (x = 0; x < 640; x++, rx+=dx) {
                        int32 c;
                        mand(rx, ry, &c);
                        tmp = (tmp<<1)+(c&1);cnt++;
                        if(cnt==16) { _vmemset(adr, tmp); tmp = 0; cnt = 0; adr++;}
                }
        }
}

void bootentry()
{
        _vgaenable();
        int32 dy = (.f 4.0) / 480;
        int32 dx = (.f 4.0) / 640;
        int32 cnt0 = 1;
        _leds(1);
 begin:
        _vmemcls();
        innerloop(dx, dy);
        _sleep(5000);
        _leds(cnt0); cnt0++;
        goto begin;
}
