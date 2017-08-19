

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

inline uint32 _SHR(uint32 a, uint32 b) {
  uint32 i = b;
  uint32 r = a;
  do {
    r = r>>1; i--;
  } while(i>0);
  return r;
}

 int32 _ASHR(int32 a, int32 b) {
  int32 i = b;
  int32 r = a;
  do {
          r = r>>1; i--;
  } while(i>0);
  return r;
}

inline int32 _SHL(int32 a, int32 b) {
  int32 i = b;
  int32 r = a;
  do {
    r = r << 1; i--;
  } while(i>0);
  return r;
}
// Russian peasant multiplication
int32 _IMUL(int32 a0, int32 b0)
{
  int32 a = a0;
  int32 b = b0;
  int32 c = 0;
  do {
    if (a & 1)
      c += b;
    a >>= 1;
    b <<= 1;
  } while (a > 0);
  return c;
}

// Integer division
int32 _IDIVMOD(int32 nDividend, int32 nDivisor, int32 *Mod)
{
  int32 nQuotient = 0;
  int32 nPos = -1;
  int32 ullDivisor = nDivisor;
  int32 ullDividend = nDividend;
  int32 nbit = 1;

  while (ullDivisor <  ullDividend) {
    ullDivisor <<= 1;
    nPos ++;
    nbit <<= 1;
  }
  
  nbit >>= 1;
  ullDivisor >>= 1;
  while (nPos >= 0) {
    if (ullDividend >= ullDivisor) {
      nQuotient += nbit;
      ullDividend -= ullDivisor;
    }
      
    ullDivisor >>= 1;
    nPos -= 1;
    nbit >>= 1;
  }
  if (ullDividend == nDivisor) {
    ullDividend = 0; nQuotient++;
  }
  *Mod = ullDividend;
  return nQuotient;
}

inline int32 _IUDIV(int32 a, int32 b)
{
  uint32 rem;
  return _IDIVMOD(a, b, &rem);
}

 int32 _ISDIV(int32 a, int32 b)
{
  uint32 rem;
  return _IDIVMOD(a, b, &rem);
}

inline int32 _IUREM(int32 a, int32 b)
{
  int32 rem;
  _IDIVMOD(a, b, &rem);
  return rem;
}

inline int32 _ISREM(int32 a, int32 b)
{
  int32 rem;
  _IDIVMOD(a, b, &rem);
  return rem;
}


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

void itoah(int32 n0, int32 s[]) {
  int32 i, sign;
  int32 n = n0;
  int32 nmod;
     
  if ((sign = n) < 0)  /* record sign */
    n = -n;          /* make n positive */
  i = 0;
  do {       /* generate digits in reverse order */
    n = _IDIVMOD(n, 16, &nmod);
    int32 chr;
    if (nmod < 10) chr = nmod + '0';
    else chr = nmod-10+'A';
    s[i++] = chr;   /* get next digit */
  } while (n > 0);     /* delete it */
  if (sign < 0)
    s[i++] = '-';
  s[i] = 0;
  reverse(s);
}

inline void _printchr(int32 c)
{
        *((int32*)65536) = c;
}


inline void _testhalt()
{
        int32 *channel = (int32*)(65541);
        *channel = 1;
}
