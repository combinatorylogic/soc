#include "./runtime_ice_small.c"

#include "./ice_vga.c"

##define fixed_point_width = 19

#include "./arith.c"

        
__hls    // instruct the compiler to generate an HDL module
__nowrap // do not generate wrapper extended instructions
void mand_core_ice(int32 cx, int32 cxstep, int32 cy, int.1 *counters)
{
  /*
   * Instruct the HLS inference engine to generate
   * a pipeline, with cx being a thread parameter, incrementing
   * in cxstep for every consequent thread.
   *
   * v_out is marked as output and is extended into a register of sizeof(*v_out) * N_THREADS
   * bits.
   * 
   */
  ::pragma hls_pipeline_loop(cx, cxstep, counters);

  int.8 i;
  int32 vx = 0;
  int32 vy = 0;
  int32 dvx = 0; int32 dvy = 0;
  int32 cnd = 1;
  for (i = (int.8)-1; (i < (int.8)99) & cnd; i++) {
    int32 vx1 = dvx - dvy + cx;
    int32 vy1 = ((vx * vy)>> (.wf - 1)) + cy;
    vx = vx1; vy = vy1;
    dvx = (vx * vx)>> .wf;
    dvy = (vy * vy)>> .wf;
    int32 r = dvx+dvy;
    if ( r > .f 4.0) {
            cnd = 0;
    }
  }
  *counters = (i+cnd)&0x1;
  return;
}

void innerloop(int32 dx, int32 dy)
{
        // Core1:
        inline verilog instance mand_core_ice(cx = reg m0_cx0,
                                              cxstep = reg m0_cxstep,
                                              cy = reg m0_cy,
                                              ACK = m0_ack,
                                              REQ = reg m0_rq,
                                              counters = m0_counters);

        inline verilog define { reg [6:0] m0_counters_copy; };
        
        
        uint32 tmp = 0;
        int32 cnt = 0;
        int32 adr = 0;
        int32 x, y;
        int32 ry= .f -2.0;
        int32 dx7 = dx * 7;
        int32 xx = 0;
        for (y = 0; y < 480; y++, ry+=dy) {
                int32 rx= .f -2.0;
                inline verilog exec(ry) { m0_cy <= ry;} noreturn;
                for (x = 0,xx = 0; x < 640; x+=7, rx+=dx7) {
                        int32 c;
                        inline verilog 
                                 exec (rx,dx) { m0_cx0 <= rx; m0_cxstep <= dx; m0_rq <= 1; }
                                 wait (m0_ack) { m0_counters_copy <= m0_counters; m0_rq <= 0; }
                                 else { m0_rq <= 0; };
                        for (int32 i = 0; i < 7; i++) {
                                int c = inline verilog exec {m0_counters_copy <= m0_counters_copy << 1;}
                                               return (m0_counters_copy[6]);
                                if (!(xx >= 640)) {
                                        tmp = (tmp<<1)+c;
                                        cnt++;
                                        if(cnt==16) {
                                                _vmemset(adr, tmp);
                                                tmp = 0; cnt = 0;
                                                adr++;
                                        }
                                }
                                xx++;
                        }
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
        // _sleep(5000);
        _leds(cnt0); cnt0++;
        goto begin;
}
