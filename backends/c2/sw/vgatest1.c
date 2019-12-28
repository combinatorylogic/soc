#include "./runtime_hls.c"
#include "./vgagfx.c"
#include "./vgagfx2.c"


void drawline(int32 x0, int32 y0, int32 x1)
{
        int32 y1 = 100;
    int32 dx, dy, p, x, y;
 
    dx=x1-x0;
    dy=y1-y0;
 
    x=x0;
    y=y0;
 
    p=(dy<<1)-dx;
 
    while(x<x1)
    {
        _vmemsetpixel(x,y,7);
        if(p>=0)
        {
            y=y+1;
            p=p+(dy<<1)-(dx<<1);
        }
        else
        {
            p=p+(dy<<1);
        }
        x=x+1;
    }
}
 
void bootentry()
{
        _vmemcls();
        /*
          _vmemsetpixel(2,2,3);  // read 00 -- 00
        _vmemsetpixel(3,2,1);  // read 03 -- 00
        _vmemsetpixel(3,2,9);  // read 13 -- 30
        _vmemsetpixel(7,2,2);  // read  0  -- 01
        _vmemsetpixel(9,1,8);  // read  0 -- 39
        */
         drawline(10,15, 500); 
         drawline(45,70, 500); 
        _vmemdump();
        _testhalt();
}
