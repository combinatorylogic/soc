// A quad-core HLS version
#include "./runtime_hls.c"
#include "./vgagfx.c"

##define fixed_point_width = 19
        
#include "./arith.c"

              
void _printnum(int32 n)
{
        int32 buf[16];
        itoa(n, buf);
        int32 *channel = (int32*)(65536);
        for(int32 i = 0; buf[i]!=0; i++) {
                *channel = buf[i];
        }
}

__hls
__nowrap
void mand_core(int32 cx, int32 cxstep, int32 cy, int.1 *counters)
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


  int32 i;
  int32 vx = 0;
  int32 vy = 0;
  int32 dvx = 0; int32 dvy = 0;
  int32 cnd = 1;
  for (i = -1; (i < 99) & cnd; i++) {
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
  *counters = (i+cnd)&1;
  return;
}

inline void _vmemsetrowpos(uint32 pos)
{
  inline verilog define { reg  splitreg; };
  inline verilog define { reg [31:0] vmemrowpos; };
  inline verilog exec (pos) {
     vmemrowpos <= pos;
     splitreg <= 0;
  } noreturn;
}

inline void _vmemdirect(uint32 pos)
{
        inline verilog define { reg [((8*6) - 1):0] bytes6; };
        inline verilog define { reg [4:0] vmembcount; };
        inline verilog
               exec (pos) {
                vmem_select <= 1;
                vmem_we <= 1;
                vmem_in_addr <= vmemrowpos;
                vmem_in_data <= bytes6[8*6-1:8*5];
                bytes6 <= {bytes6[(5*8-1):0],8'b0};
                vmembcount <= splitreg?5:4;
               } wait(vmembcount == 0) {
                        vmem_select <= 0;
                        vmem_we <= 0;
                        vmemrowpos <= vmemrowpos + 1;
                        splitreg <= ~splitreg;
               } else {
                        vmem_in_addr <= vmem_in_addr + 1;
                        vmemrowpos <= vmemrowpos + 1;
                        vmem_in_data <= bytes6[8*6-1:8*5];
                        bytes6 <= {bytes6[(5*8-1):0],8'b0};
                        vmembcount <= vmembcount - 1;
               };
}

inline
void mand44(int32 zoom, int32 dstX, int32 dstY, int32 dstW, int32 dstH, int32 N)
{
  int32 X0 = .f -2.0;
  int32 Y0 = .f -2.0;
  int32 W0 = .f 4.0;
  int32 H0 = .f 4.0;

  int32 dxzoom = (dstX - X0) / N;
  int32 dyzoom = (dstY - Y0) / N;
  int32 dxzoom1 = 0-(((X0 + W0) - (dstX + dstW)) / N);
  int32 dyzoom1 = 0-(((Y0 + H0) - (dstY + dstH)) / N);

  int32 xstart = X0 + dxzoom * zoom;
  int32 ystart = Y0 + dyzoom * zoom;
  int32 W = X0 + W0 + dxzoom1 * zoom - xstart;
  int32 H = Y0 + H0 + dyzoom1 * zoom - ystart;

  int32 i;
  int32 y;
  int32 x;
  int32 dx = W / 640;
  int32 dy = H / 480;
  int32 dx11 = dx * 11;
  int32 dx44 = dx11 * 4;

  // Core1:
  inline verilog instance mand_core(cx = reg m0_cx0,
                                    cxstep = reg m0_cxstep,
                                    cy = reg m0_cy,
                                    ACK = m0_ack,
                                    REQ = reg m0_rq,
                                    counters = m0_counters);
  // Core2:
  inline verilog instance mand_core(cx = reg m1_cx0,
                                    cxstep = reg m1_cxstep,
                                    cy = reg m1_cy,
                                    ACK = m1_ack,
                                    REQ = reg m1_rq,
                                    counters = m1_counters);

   // Core3:
  inline verilog instance mand_core(cx = reg m2_cx0,
                                    cxstep = reg m2_cxstep,
                                    cy = reg m2_cy,
                                    ACK = m2_ack,
                                    REQ = reg m2_rq,
                                    counters = m2_counters);

  // Core4:
  inline verilog instance mand_core(cx = reg m3_cx0,
                                    cxstep = reg m3_cxstep,
                                    cy = reg m3_cy,
                                    ACK = m3_ack,
                                    REQ = reg m3_rq,
                                    counters = m3_counters);

  
  // hoisted definition goes into the CPU core module, as well as the
  // instance above.
  inline verilog define { reg [31:0] m_dx; };
  inline verilog define { reg [31:0] m_dx11; };
  inline verilog define { reg [3:0] m01_ack; };
  inline verilog define { reg [3:0] leftover; };

  inline verilog reset { m_dx <= 0; m_dx11 <= 0; m01_ack <= 0; leftover <= 0;
          splitreg <= 0;
          vmemrowpos <= 0;
          bytes6 <= 0;
          vmembcount <= 0;
          
  };

  inline verilog exec (dx, dx11) { m_dx <= dx; m_dx11 <= dx11;
    m0_cxstep <= dx; 
    m1_cxstep <= dx; 
    m2_cxstep <= dx; 
    m3_cxstep <= dx; 
  } noreturn;
  int32 ry = ystart;
  int32 vdy = 80;
  int32 ypos, pos, pix, xctr, splitw, split, rx;
  ypos = 0; xctr = 0; pix = 0;

  for (y = 0; y < 480; y++,ry+=dy) {
    // A custom single argument instruction with no return is generated here,
    // with statemens added to the exec stage.

   inline verilog exec(ry) { m0_cy <= ry; m1_cy <= ry;
                              m2_cy <= ry; m3_cy <= ry;
      } noreturn;
    rx = xstart;
    pos = ypos; xctr = 0;

    _vmemsetrowpos(pos);
    for (x = 0; x < 640; x+=44,rx+=dx44) {
      // A custom two-argument instruction with a wait stage is generated,
      //   statements are added to exec and wait stages.
      // Wait for both cores to terminate.
      inline verilog 
             exec (rx) {
              m0_cx0 <= rx; m0_rq <= 1;
              m1_cx0 <= rx + m_dx11; m1_rq <= 1;
              m2_cx0 <= rx + (m_dx11<<1); m2_rq <= 1;
              m3_cx0 <= rx + (m_dx11<<1) + m_dx11; m3_rq <= 1;
              m01_ack <= 0;
             }
             wait ((m01_ack + (m0_ack + m1_ack + m2_ack + m3_ack)) == 4) {
                               m0_rq <= 0; m1_rq <= 0;
                               m2_rq <= 0; m3_rq <= 0;
                               m01_ack <= 0;
              } else {
                      m0_rq <= 0; m1_rq <= 0;
                      m2_rq <= 0; m3_rq <= 0;
                      m01_ack <= m01_ack + (m0_ack + m1_ack + m2_ack + m3_ack);
              };
      // There are two possible splits: 5 bytes + 4 extra bits,
      // or 4 previous bits + 44 new bits = 6 bytes
      inline verilog exec (x) {
              if (splitreg==0) begin
                  bytes6 <= {m0_counters, m1_counters, m2_counters, m3_counters[10:4], 8'b0};
                  leftover <= m3_counters[3:0];
              end else begin
                  bytes6 <= {leftover, m0_counters, m1_counters, m2_counters, m3_counters};
              end
              } noreturn;
        _vmemdirect(pos);
    }
    ypos += vdy;
  }
}

void bootentry()
{
        int32 N = 70;
        int32 dstX = .f -0.88078125;
        int32 dstY = .f 0.2206640625;
        int32 dstW = .f 0.03287109374999997;
        int32 dstH = .f 0.032851562500000014;
	int32 x;
        int32 zoom = 10;
        int32 dz = 1;
        int32 cntr = 0;
        _vmemcls();
 loopZ:
	mand44(zoom, dstX, dstY, dstW, dstH, N);
        _leds(cntr++);
        zoom+=dz;
        if (zoom >= (N-5)) dz = -1;
        else if (zoom < 1) dz = 1;
        // Ignored on an FPGA, terminates in Verilator
        _vmemdump();
        _testhalt();
        // Avoid a VGA flicker and tearing
        _vmemwaitscan();
        _vmemswap();
 	goto loopZ;
}

