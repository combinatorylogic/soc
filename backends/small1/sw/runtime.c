typedef int32 int;
typedef uint32 uint;

/* 1. Intrinsic declarations */
void _nop();

void _irqack();  // exit from an IRQ handler



void _enter_critical(); // disable interrupts
void _exit_critical();  // enable interrupts

int32* _intptr(uint32 ptr); // the language does not allow casting,
                            //   so we need an explicit intrinsic to
                            //   circumvent it.

int32 _ptrint(int32 *ptr);

// Performance counters:
int32 _perfcounter();   // Clock cycles
int32 _perfcounter1();  // Instructions
int32 _perfcounter2();  // Custom

int32 _not(int32 x);      // Hardware NOT instruction
int32 _shlone(int32 x);   // <<1
int32 _ashrone(int32 x);  // arithmetic >>1
uint32 _shrone(uint32 x); // >>1

// Custom instructions
void _custom2_0(int32 cmd, int32 x, int32 y);
void _custom1_0(int32 cmd, int32 x);
void _custom0_0(int32 cmd);
int32 _custom0_1(int32 cmd);
int32 _custom1_1(int32 cmd, int32 x);
int32 _custom2_1(int32 cmd, int32 x, int32 y);

// Library functions
inline int32 _LOGNOT(int32 x) {
  return _not(x)&0x1;
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

inline uint32 _SHR(uint32 a, uint32 b) {
  uint32 i = b;
  uint32 r = a;
  do {
    r = _shrone(r); i--;
  } while(i>0);
  return r;
}

inline int32 _ASHR(int32 a, int32 b) {
  int32 i = b;
  int32 r = a;
  do {
    r = _ashrone(r); i--;
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
inline int32 _IMUL(int32 a0, int32 b0)
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
inline int32 _IDIVMOD(int32 nDividend, int32 nDivisor, int32 *Mod)
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

inline int32 _ISDIV(int32 a, int32 b)
{
  uint32 rem;
  return _IDIVMOD(a, b, &rem);
}

inline int32 _IUREM(int32 a, int32 b)
{
  uint32 rem;
  _IDIVMOD(a, b, &rem);
  return rem;
}

inline int32 _ISREM(int32 a, int32 b)
{
  uint32 rem;
  _IDIVMOD(a, b, &rem);
  return rem;
}

// Send a character via an SPI link
inline void _printchr(uint32 chr)
{
  uint32 *channel = _intptr(0x10004);
  uint32 *notfull = _intptr(0x10005);
  while(!(*notfull)) ; // poll until FIFO is not full
  *channel = chr; // send a word  
}


// buffer managed by an interrupt controller
int32 buffer[32];
int32 bufferptr;

// IRQ0 - UART FIFO not empty
void irq0()
{
  int32 *channel = _intptr(0x10001); // Input fifo register address
  int32 *notempty = _intptr(0x10002); // Input fifo register address
  int32 data;
  while (notempty[0]) {
    data = channel[0];     // read word from channel
    if (bufferptr < 31) buffer[bufferptr++] = data;
    else buffer[bufferptr-1] = data;
  }
  _irqack();                   // Quit the irq handler  
}

// IRQ1 - programmable timer 1
void irq1()
{
  _irqack();  // no do no nothing
}

// IRQ2 - programmable timer 2
void irq2()
{
  _irqack(); // no do no nothing
}

// IRQ3 - something?
void irq3()
{
  _irqack(); // no do no nothing
}

void irq6() // Memory access violation, useful for debugging
{
 endless:
  goto endless;
  _irqack();
}

// Memory-mapped HALT, works in simulation only
void _HALT() 
{
  uint32 *channel = _intptr(0x10111);
  *channel = 0xaaaa; // force $stop
}

typedef void *voidptr;

// An interrupt handlers table, implicitly mapped to 0x20000
voidptr irqtable[16] = {irq0, irq1, irq2, irq3, irq3, irq3,
                        irq6, irq3, irq3, irq3, irq3, irq3,
                        irq3, irq3, irq3, irq3};


// Higher level functionality:
void _print(uint32 *strdata)
{
  uint32 idx;
  uint32 chr;
  idx = 0;
  while(1) {
    chr = strdata[idx++];
    if (!chr) return;
    _printchr(chr);
  }
}

int32 strlen(int32 s[])
{
  int32 l;
  for (l = 0; s[l]; l++);
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

// Halting sequence for simulated tests, meaningless on FPGA
void _testhalt()
{
  _printchr(0xff); // signal verilator harness to quit
  _print("--\n");
  while(!bufferptr) ; // wait for any input
  _HALT();
}
