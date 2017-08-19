int32* _intptr(uint32 ptr);


inline void _leds(int32 n)
{
        int32 *channel = (int32*)(65540);
        *channel = n;
}


inline
void _putc(int32 n)
{
        int32 *channel = (int32 *)(65536);
        *channel = n;
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
    int32 tmp = nmod + '0';
    s[i++] = tmp;   /* get next digit */
  } while (n > 0);     /* delete it */
  if (sign < 0)
    s[i++] = '-';
  s[i] = 0;
  reverse(s);
}

void _printnum(int32 n)
{
        int32 buf[16];
        itoa(n, buf);
        int32 *channel = (int32*)(65536);
        for(int32 i = 0; buf[i]!=0; i++) {
                *channel = buf[i];
        }
}

int32 fac(int32 n)
{
        if (n > 1) return n * fac(n-1);
        else return 1;
}

void _halt()
{
        int32 *channel = _intptr(65541);
        *channel = 1;
}

void bootentry()
{
        int32 c = fac(5);
        *((int32*)65542) = 1;
        _printnum(c);
        _putc(13);
        _putc(10);
        c = fac(9);
        _printnum(c);
        _putc(13);
        _putc(10);
        *((int32*)65542) = 1;
        _halt();
}

