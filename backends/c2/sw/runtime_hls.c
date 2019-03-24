#include "runtime_common.c"
#include "runtime_extra.c"

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

/*
__hls void _HLS_IMUL(int32 a0, int32 b0, int32 *ret) {
        *ret = a0*b0;
}

inline int32 _IMUL(int32 a0, int32 b0)
{
        int32 ret;
        _HLS_IMUL(a0,b0,&ret);
        return ret;
}
*/

inline int32 _IMUL(int32 a0, int32 b0)
{
        inline verilog usemodule "./slowMul.v";
        inline verilog instance slowMul(ack = mul_ack,
                                        p0  = reg mul_p0,
                                        p1  = reg mul_p1,
                                        req = reg mul_req,
                                        out = mul_out);
        inline verilog reset {
                mul_req <= 0;
                mul_p0 <= 0;
                mul_p1 <= 0;
        };
        inline verilog exec(a0, b0) {
                mul_p0 <= a0;
                mul_p1 <= b0;
                mul_req <= 1;
        } wait (mul_ack) {
                mul_req <= 0;
                } else { mul_req <= 0; };
        return inline verilog exec {} return ( mul_out );
}


__hls void HW_IDIVMOD(int32 nDividend, int32 nDivisor, int32 *Mod, int32 *Ret)
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
  *Ret = nQuotient;
}

// Integer division
inline int32 _IDIVMOD(int32 nDividend, int32 nDivisor, int32 *Mod)
{
        int32 ret;
        HW_IDIVMOD(nDividend, nDivisor, Mod, &ret);
        return ret;
}

inline int32 _IUDIV(int32 a, int32 b)
{
  uint32 rem;
  return _IDIVMOD(a, b, &rem);
}

inline  int32 _ISDIV(int32 a, int32 b)
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
