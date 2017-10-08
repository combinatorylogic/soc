#include "./runtime_common.c"

inline uint32 _SHR(uint32 a, uint32 b) {
  uint32 i = b;
  uint32 r = a;
  do {
          r = r >> (uint32)1; i--;
  } while(i>0);
  return r;
}

inline int32 _ASHR(int32 a, int32 b) {
  int32 i = b;
  int32 r = a;
  do {
    r = r >> 1; i--;
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



inline int32 _SLT(int32 l, int32 r) {
  return (l-r)&0x80000000; // is l-r negative?
}

inline int32 _ULT(int32 l, int32 r) {
  return (l-r)&0x80000000; // is l-r negative?
}

inline int32 _SLE(int32 l, int32 r) {
  return (l-r)&0x80000000; // is l-r negative?
}

inline int32 _ULE(int32 l, int32 r) {
  return (l-r)&0x80000000; // is l-r negative?
}

inline int32 _SGT(int32 l, int32 r) {
  return (r-l)&0x80000000; // is l-r negative?
}

inline int32 _SGE(int32 l, int32 r) {
  return l==r || (r-l)&0x80000000; // is l-r negative?
}
