#include "./runtime_ice_small.c"
#include "./runtime_extra.c"
//#include "./uartsim.c"
#include "./uart.c"

##define fixed_point_width = 19

#include "./arith.c"

  
typedef void *voidptr;

int32 strlen(int32 s[])
{
  int32 l;
  for (l = 0; s[l]!=0; l++);
  return l;
}

void reverse(int32 s[])
{
  int32 i, j;
  int32 c, l;
  l = strlen(s) - 1;
  for (i = 0, j = l; i<j; i++, j--) {
    c = s[i];
    s[i] = s[j];
    s[j] = c;
  }
}

void itoa(int32 n0, int32 s[]) {
  int32 i, sign;
  int32 n = n0;
  int32 nmod;

  if ((sign = n) < 0)  /* record sign */
    n = -n;          /* make n positive */
  i = 0;
  do {       /* generate digits in reverse order */
    n = _IDIVMOD(n, 10, &nmod);
    s[i++] = nmod + '0';   /* get next digit */
  } while (n > 0);     /* delete it */
  if (sign < 0)
    s[i++] = '-';
  s[i] = 0;
  //s[i] = 0;
  //_dbg(3, i);
  reverse(s);
}


        
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

  
int CR[3]={10, 13, 0};

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
        for (y = 0; y < 480; y++, ry+=dy) {
                int32 rx= .f -2.0;
                inline verilog exec(ry) { m0_cy <= ry;} noreturn;
                for (x = 0; x < 640; x+=7, rx+=dx7) {
                        inline verilog 
                                 exec (rx,dx) { m0_cx0 <= rx; m0_cxstep <= dx; m0_rq <= 1; }
                                 wait (m0_ack) { m0_counters_copy <= m0_counters; m0_rq <= 0; }
                                 else { m0_rq <= 0; };
                        int ccx = 0;
                        ccx = (int)(inline verilog exec {} return ( m0_counters_copy ));
                        //                        uart_sendc(' ');
                        uart_sendc('.'+ccx);
                }
                uart_send(CR);
        }
}

void bootentry()
{
  uint32 buffer[64];
  int32 dy = (.f 4.0) / 480;
  int32 dx = (.f 4.0) / 640;
  uart_send("Hello, wodrl.");
  uart_send(CR);
  int32 cn;
  cn = 0;
 begin:
  _leds(cn);
  uart_send("Frame:");
  uart_send(CR);
  innerloop(dx, dy);
  cn++;
  goto begin;
}
