
typedef int32 int;
typedef uint32 uint;

// Custom instructions
void _custom2_0(int32 cmd, int32 x, int32 y);
void _custom1_0(int32 cmd, int32 x);
void _custom0_0(int32 cmd);
void _custom2_0b(int32 cmd, int32 x, int32 y);
void _custom1_0b(int32 cmd, int32 x);
void _custom0_0b(int32 cmd);
int32 _custom0_1(int32 cmd);
int32 _custom1_1(int32 cmd, int32 x);
int32 _custom2_1(int32 cmd, int32 x, int32 y);
void _dbgreg(int32 rnum);
/////////////////////////

uint32 _SHR(uint32 a, uint32 b);
int32 _ASHR(int32 a, int32 b);
int32 _SHL(int32 a, int32 b);
        
int32 _IMUL(int32 a0, int32 b0);
int32 _IDIVMOD(int32 nDividend, int32 nDivisor, int32 *Mod);
int32 _IUDIV(int32 a, int32 b);
int32 _ISDIV(int32 a, int32 b);
int32 _IUREM(int32 a, int32 b);
int32 _ISREM(int32 a, int32 b);

inline void _leds(int32 n)
{
        int32 *channel = (int32*)(65540);
        *channel = n;
}
