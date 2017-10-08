
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

void _print(int32 *str)
{
        for (int i = 0; str[i]; i++) _printchr(str[i]);
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


void putc(int32 c)
{
        uint32 *uart_ready = (uint32*)(65538);
        uint32 *uart_out = (uint32*)(65539);
        while(! *uart_ready) ;
        *uart_out = c;
}
      

void print(int32 *str)
{
        for (int i = 0; str[i]; i++) putc(str[i]);
}

void printnum(int32 n)
{
        int32 buf[16];
        itoa(n, buf);
        print(buf);
}

void newline()
{
        putc(10); putc(13);
}
