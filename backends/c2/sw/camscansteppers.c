#include "./runtime_ice_small.c"
//#include "./runtime_extra.c"
#include "./stepper.c"
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

// Control 4x 28byj-48 steppers. Steppers 0 and 1 carry a laser pointer,
//   steppers 2 and 3 carry a RPi camera cradle.
//
// Command format is:
// M <id> <nsteps> - move a stepper <id> to given number of steps (0.01132 degrees each)
// H - halt
//
// Status response format is:
// # <version string> - sent once on bootup
// R - all motors are ready  - sent once as soon as condition arises

int pollready() {
        if (_stepper_ready() == 0xf) return 1;
        return 0;
}

void exec_m_cmd(int id, int steps)
{
        int a = (steps>0)?steps:-steps;
        int dir = (steps>0)?1:0;
        _stepper_nsteps(id, a, dir);
}

int CR[2]={13, 0};

void runcmd()
{
        int c = uart_buffer[0];
        if (c == 'M') { // M-command
                // Parse two numbers
                int id, angle;
                int next = parse_num(uart_buffer + 2, &id);
                next = parse_num(uart_buffer + 2 + next, &angle);
                exec_m_cmd(id, angle);
                uart_send("ACK_M");
                /*
                int buf[20];
                itoa(angle, buf);
                uart_send(" -: ");
                uart_send(buf);
                */
                uart_send(CR);
        } else if (c == 'H') { // H-command
                uart_send("ACK_H"); uart_send(CR);
                // TODO! disable motors, do a hard halt
        }
        uart_pos = 0; // reset UART buffer
        uart_buffer[0] = 0;
}

int ready_sent;
void readcmd()
{
        if(polluart()) {
                ready_sent = 0;
                runcmd();
        }
        if(pollready() && !ready_sent) {
                uart_send("R");
                uart_send(CR);
                ready_sent = 1;
        }
}

void bootentry()
{
  int counter = 0;
        ready_sent = 0;
        uart_pos = 0;
        _leds(0x07);
        uart_send("# 4-STEPPER controller v0.1 [ ICE40 8k breakout ]");
        uart_send(CR);
        _leds(0x02);
        while(1) {
          // Read commands from serial, interpret and execute
          readcmd();
          counter++;
          _leds(counter>>10);
        }
  
}
