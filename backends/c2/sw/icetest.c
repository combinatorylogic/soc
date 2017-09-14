#include "runtime_ice.c"

int32 A = 888;
int32 B = 5;
int32 C = 4;

void bootentry()
{
        int32 x = B * C;
        int32 y = A;
        int32 z = B;
        _leds(A);
        _leds(B);
        _leds(x);
        _leds(0xff);
        _leds(x);
        _leds(0xff);
        _leds(z * 4);
        _leds(0xff);
        for (int i = 2; i < x; i++) {
                int32 t = y / i;
                _leds(t);
                _leds(0xff);
        }
 end:
        _leds(0);
        goto end;
}
