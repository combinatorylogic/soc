#include "./runtime_hls.c2"
#include "./vgafifo.c"

/*
 The idea for this demo is following:

   - A pipelined HLS core is producing one new output per clock cycle (after some initial delay),
   - This output is fed into a FIFO, which is consumed by the VGA driver on the other side
   - If FIFO is full, core is stalled
   - New x, y values are pumped in sequentially, output is coming out in the same sequence (would be
     more interesting once we have a loop here, with output coming out of order).
   - On frame flip, metaball positions are recalculated (on a CPU, expecting it to finish and start filling the FIFO
      before the next frame is started)

   - Obviously, we're using an alternative VGA core here - no VRAM, and FIFO is exposed to the CPU instead (btw.,
      can be a colour VGA this way, maybe even with a higher pixel clock - e.g. 1280x720 60hz, 74.25MHz.
   - Which raises a good question - should we expose the hardware configuration controls to the C side somehow?
     We're already doing it for extensions, so why not allow the same for the standard IP cores too? Like, pass a
     set of defines to a hardware assembly backend.

   - Just two metaballs now (for one pixel per clock cycle we'd have to instantiate as many divisions as there are
     metaballs)

 */


__hls
__nowrap
void metaball_vga(int.16 x, int.16 y, int.16 x1, int.16 x2, int.16 y1, int.16 y2, int32 mass, int *out)
{
        ::pragma hls_pipeline_external(out); // notify that parameters change externally
        ::pragma hls_external_stall();           // Respect the external stall signal

        int32 dx1 = x - x1;
        int32 dx2 = x - x2;
        int32 dy1 = y - y1;
        int32 dy2 = y - y2;
        int32 d1sq = dx1 * dx1 + dy1 * dy1;
        int32 d2sq = dx2 * dx2 + dy2 * dy2;
        int32 g1 = mass / d1sq; // see? this is going to be a very long pipeline, with these two parallel divisions here
        int32 g2 = mass / d2sq; 
        *out = g1 + g2;
}


void setup_frame()
{
        inline verilog exec() {
                
        }
}


void bootentry()
{
        // 1. Set up x and y registers and update metaball positions
        
}
