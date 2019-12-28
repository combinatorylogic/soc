#include "./runtime_hls.c"
#include "./runtime_flt.c"
#include "./vgagfx_issue.c"

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
void mandfun(float zoom, float dstX, float dstY, float dstW, float dstH, float N)
{
        float X0 = (float)-2.0;
        float Y0 = (float)-2.0;
        float W0 = (float)4.0;
        float H0 = (float)4.0;

        float dxzoom = (dstX - X0) / N;
        float dyzoom = (dstY - Y0) / N;

        float dxzoom1 = (((X0 + W0) - (dstX + dstW))) / N;
        float dyzoom1 = (((Y0 + H0) - (dstY + dstH))) / N;
        
        float x0 = X0 + dxzoom * zoom;
        float y0 = Y0 + dyzoom * zoom;
        float w = X0 + W0 - dxzoom1 * zoom - x0;
        float h = Y0 + H0 - dyzoom1 * zoom - y0;

        float cx = x0;
        float cy = y0;
        float dx = w/(float)640.0;
        float dy = h/(float)480.0;
        int32 width = %kernel_width(mand_core);
        float dx19 = dx * (float)width;
        
        // Make a hardware-assisted thread issue device, instantiating
        // 8 compute cores, with cxstep=dx and ix=0 being fixed arguments
        // and vmem_blit core instantiated for the result accumulation.
        %issue_threads_sync(mand_core, 16, {cxstep = dx, ix = 0}, vmem_blit)
        {
          int32 rpos, xpos;
          rpos = 0;
          for (int32 y = 0; y < 480; y++) {
                  cx = x0;
                  xpos = 0;
                  for (int32 x = 0; x < 640; x+= width) {
                          xpos = xpos + 9;
                          int32 dst = rpos + xpos;
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
        int32 N = 150;
        /*
1:
  <xmin>-0.565320000000000003304</xmin>
   <xmax>-0.536160000000000003952</xmax>
   <ymin>0.524050000000000000000</ymin>
   <ymax>0.545920000000000000000</ymax>

2:
   <xmin>-1.759638902562499973399</xmin>
   <xmax>-1.758313640624999973446</xmax>
   <ymin>0.018522870041666666766</ymin>
   <ymax>0.019519166250000000064</ymax>


         */
        float dstX = (float) -0.565320000000000003304;
        float dstY = (float) 0.52405;
        float dstW = ((float) -0.536160000000000003952) - dstX;
        float dstH = ((float) 0.54592) - dstY;
        /*
        float dstX = (float) -1.759638902562499973399;
        float dstY = (float) 0.018522870041666666766;
        float dstW = ((float) -1.758313640624999973446) - dstX;
        float dstH = ((float) 0.01951916625) - dstY;
        */
	int32 x;
        int32 zoom = 149;
        int32 dz = 1;
        int32 cntr = 0;
        _vmemcls();
 loopZ:
        mandfun((float)zoom, dstX, dstY, dstW, dstH, (float)N);
        zoom += dz;
        if (zoom >= (N-1)) dz = -1;
        else if (zoom < 1) dz = 1;
        _vmemwaitscan();
        _vmemdump();
        _testhalt();
        goto loopZ;
}
