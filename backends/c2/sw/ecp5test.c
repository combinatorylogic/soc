#include "./runtime_ice.c"
#include "./uart.c"
#include "./runtime_str.c"


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

int CR[2]={13, 0};


void bootentry()
{
  int counter = 0;
  _leds(0x07);
  uart_send("Hello, wodrl.");
  uart_send(CR);
  _leds(0x02);
  while(1) {
    // Read commands from serial, interpret and execute
    uart_send("Hello, poo poo");
    uart_send(CR);
  }
}
