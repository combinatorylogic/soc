#include "./runtime_hls.c"
#include "./runtime_flt.c"
#include "./vgagfx_issue.c"

__hls
__nowrap
void metaball_vgax(int.16 x0, float y, int.4 *out)
{
        ::pragma hls_pipeline_loop(x0, 1, out);

        float xs[32];
        float ys[32];
        float mass[32];
        float g = (float)0.0;
        int.8 gout = 0;

        for (int32 i = 0; i < 32; i++) {
                float x = (float)x0;
                float x1 = xs[i];
                float y1 = ys[i];
                float dx1 = x - x1;
                float dy1 = y - y1;
                float d1sq = dx1 * dx1 + dy1 * dy1;
                float g1 = mass[i] / d1sq;
                g = g + g1;
                gout = (int32)g;
        }
        *out = gout>>2;
}

##nil

int32 xs[32];
int32 ys[32];
int32 mass[32];


void bootentry()
{
        int32 width = %kernel_width(metaball_vgax);
        int32 hwidth = width/2;
        int32 xpos, ypos, rpos;
        int32 t = 50; int32 i;
        for (i = 0; i < 32 ; i++) {
                xs[i]   = (bitcast: int32)((float)(i*9918273 % 640));
                ys[i]   = (bitcast: int32)((float)(i*987918273 % 480));
                mass[i] = (bitcast: int32)((float)((i*1240+250) % 360000 + 2000));
        }
        
        for(;;) {
                %issue_threads_sync(metaball_vgax, 6, {}, vmem_blit)
                {
                        rpos = 0; ypos = 0;
                        for (i = 0; i < 32 ; i++) {
                                %prefill_array(xs, i, xs[i]);
                                %prefill_array(ys, i, ys[i]);
                                %prefill_array(mass, i, mass[i]);
                                if (i % 2) {
                                        xs[i] = (bitcast:int32)(((bitcast: float)xs[i]) + (float)1.0);
                                        ys[i] = (bitcast:int32)(((bitcast: float)ys[i]) - (float)1.5);
                                } else {
                                        xs[i] = (bitcast:int32)(((bitcast: float)xs[i]) - (float)2.0);
                                        ys[i] = (bitcast:int32)(((bitcast: float)ys[i]) + (float)3.5);
                                }

                                if (((bitcast: float)(xs[i])) > ((float)640.0)) xs[i] = ((bitcast: int32)((float)0.0));
                                if (((bitcast: float)(ys[i])) > ((float)480.0)) ys[i] = ((bitcast: int32)((float)0.0));
                                if (((float)0.0) > ((bitcast: float)(xs[i])))   xs[i] = ((bitcast: int32)((float)640.0));
                                if (((float)0.0) > ((bitcast: float)(ys[i])))   ys[i] = ((bitcast: int32)((float)480.0));
                        }
                        for (int32 y = 0; y < 480; y++) {
                                float fy = (float) y;
                                xpos = 0;
                                for(int32 x = 0; x < 640; x+= width) {
                                        int32 dst = rpos + xpos;
                                        %emit_task(x0 = x, y = fy,
                                                   blit_destination = dst);
                                        xpos = xpos + hwidth;
                                }
                                rpos = rpos + 320;
                        }
                }
                t++;
                _vmemwaitscan();
                _vmemdump();
                //_testhalt();
        }
}
