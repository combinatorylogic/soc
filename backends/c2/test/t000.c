int32* _intptr(uint32 ptr);
#include "../sw/runtime.c"
#include "common.c"


void bootentry()
{
        int32 a = 19491;
        int32 b = 4;
        int32 c = _IUDIV(a, b);
        _printnum(c);
        _printchr(13);
        _halt();
}

