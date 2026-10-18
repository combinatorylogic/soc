
#include "runtime.c"


__hls void divtest(int32 a, int32 b, int32 *ret)
{
        *ret = a/b;
}

void testdiv(int32  a, int32 b)
{
        int32 ret;
        _print("Test: "); _printnum(a); _print(" / "); _printnum(b);
        _print(" = ");
        divtest(a, b, &ret);
        _printnum(ret);  _print(" vs. "); _printnum(a / b);
        _print("\n");
}

void bootentry()
{
        testdiv(812312,234);
        testdiv(666,4);
        testdiv(9999999,4);
        testdiv(9999999,388);
        _testhalt();
}
