#include "./runtime_hls.c"
#include "./runtime_flt.c"
#include "./vgagfx_issue.c"
//#include "./7seg.c"

__hls    // instruct the compiler to generate an HDL module
__nowrap // do not generate wrapper extended instructions
void mand_core(float cx0, float cxstep, int32 ix, float cy, int.4 *counters)
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
  ::pragma hls_pipeline_loop(ix, 1, counters);


        // Z <- Z^2 + C, Z0 = 0
        // Z <- (x+iy)*(x+iy) + Cx + iCy = x*x + i*x*y + i * x * y - y*y + Cx + i*Cy
        // Zx <- x*x - y*y + Cx
        // Zy <- 2*(x*y) + Cy
  int.8 i;
  float vx = (float)0.0;
  float vy = (float)0.0;
  float dvx = (float)0.0; float dvy = (float)0.0;
  int32 cnd = 1;
  for (i = (int.8)(-1); (i < (int.8)99) & cnd; i++) {
    float cx = cx0 + ((float)ix) * cxstep;
    float vx1 = (dvx - dvy) + cx;
    float vy1 = ((float)2.0) * (vx * vy) + cy;
    vx = vx1; vy = vy1;
    dvx = (vx * vx);
    dvy = (vy * vy);
    float r = dvx+dvy;
    if ( r > (float)4.0) {
            cnd = 0;
    }
  }
  *counters = (i+cnd)&0xf;
  return;
}

##nil

inline
void mandfun(float x0, float y0, float w, float h)
{
        float cx = x0;
        float cy = y0;
        float dx = w/(float)640.0;
        float dy = h/(float)480.0;
        int32 width = %kernel_width(mand_core);
        float dx19 = dx * (float)width;
        
        /*        _print("x0="); _printnum(x0);   _printchr(32);
        _print("y0=");_printnum(y0);   _printchr(32);
        _print("w=");_printnum(w);    _printchr(32);
        _print("h=");_printnum(h);    _printchr(32);
        _print("dx=");_printnum(dx);   _printchr(32);
        _print("dy=");_printnum(dy);   _printchr(32);
        _printchr(10);   _printchr(13); 
        _print("dx19=");_printnum(dx19); _printchr(32);
        _printchr(10);   _printchr(13); */

 %issue_threads_sync(mand_core, 8, {cxstep = dx, ix = 0}, vmem_blit)
  {
          int32 rpos, xpos;
          rpos = 0;
          for (int32 y = 0; y < 480; y++) {
                  cx = x0;
                  xpos = 0;
                  for (int32 x = 0; x < 640; x+= width) {
                          xpos = xpos + 9;
                          int32 dst = rpos + xpos;
                          // _printnum(dst); _printchr(10);
                          %emit_task( cx0 = cx, cy = cy,
                                      blit_destination = dst );
                          cx = cx + dx19;
                  }
                  cy = cy + dy;
                  rpos = rpos + 320;
          }
  }
}


void bootentry()
{
        uint32 clk0 = _clockcnt();
        mandfun(-2.0, -2.0, 4.0, 4.0);
        uint32 clk1 = _clockcnt();
        _print("Total cycles: ");
        _printnum(clk1-clk0);
        _printchr(10);
        _vmemdump();
         _testhalt();
}
