#include "../runtime.c"

__hls void ctz(int32 n, int32 *ret) {
    int32 msk = 1;
    for (int32 i = 0; i < 32; i++,
                              msk <<= 1)
        if ((n & msk)!=0) {
            *ret = i;
            return;
        }
    *ret = 32;
    return;
}

void _printtst(int32 *str, int32 num)
{
  int32 buf[32];
  _print(str);
  itoa(num, buf);
  _print(buf);
  _print("\n");
}

void bootentry()
{
        int32 ret;
        ctz(16, &ret);
        _printtst("16: ", ret);
        ctz(32, &ret);
        _printtst("32: ", ret);
        ctz(28, &ret);
        _printtst("28: ", ret);
        _testhalt();
}
