#include <stdio.h>

void _printchr(char c)
{
        printf("%c", c);
}

int mand_core(float cx0, float cxstep, int ix, float cy)
{
        // Z <- Z^2 + C, Z0 = 0
        // Z <- (x+iy)*(x+iy) + Cx + iCy = x*x + i*x*y + i * x * y - y*y + Cx + i*Cy
        // Zx <- x*x - y*y + Cx
        // Zy <- 2*(x*y) + Cy
  int i;
  float vx = (float)0.0;
  float vy = (float)0.0;
  float dvx = (float)0.0; float dvy = (float)0.0;
  int cnd = 1;
  for (i = (int)(-1); (i < (int)99) & cnd; i++) {
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
  return (i+cnd)&0xf;
}

void mandfun(float x0, float y0, float w, float h)
{
        float cx = x0;
        float cy = y0;
        float dx = w/(float)640.0;
        float dy = h/(float)480.0;
        float dx24 = dx * (float)24.0;

        for (int y = 0; y < 480; y++) {
                
                cx = x0;
                for (int x = 0; x < 640; x+=24) {

                        for(int n = 0; n < 24; n++) {
                                int c = mand_core(cx, dx, n, cy);
                                if (c>14) _printchr('*'); else
                                        if (c>10) _printchr('+'); else
                                                if(c>1) _printchr('@'); else _printchr('?');
                        }
                        cx = cx + dx24;
                }
                cy = cy + dy;
                _printchr(10);_printchr(13);
        }

}


int main()
{
        mandfun(-2.0, -2.0, 4.0, 4.0);
        return 0;
}
