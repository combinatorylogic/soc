#include "runtime.c"
#include "malloc.c"

int32 num_A = 5766228;
int32 num_B = 13;

// "OS" entry point
void bootentry()
{
  uint32 tmp;
  uint32 cntflag;
  uint32 idx = 0;
  uint32 oidx = 0;
  int32 *tmpbuf;
  // buffer managed by an OS
  int32 *osbuffer;
  int32 osbufferptr = 0;


  // Do some setup
  // ...
  _enter_critical();
  bufferptr = 0;
  _exit_critical();

  osbufferptr = 0;
  _mem_init();
  tmpbuf = malloc(128);
  osbuffer = malloc(512);

  _print("Small1 OS REPL\n");

  // Event loop
 eventloop:
  cntflag = 0;
  _enter_critical();
  tmp = bufferptr;
  if (tmp!=0) { // Have to empty the buffer
    cntflag = 1;
    oidx = osbufferptr;
    for (idx = 0; idx < tmp; idx++) {
      if(osbufferptr<510)
        osbuffer[osbufferptr++] = buffer[idx];
      else
        osbuffer[osbufferptr-1] = buffer[idx];
    }
    bufferptr = 0;
  }
  _exit_critical();

    
  if (!cntflag) goto eventloop; // keep polling, think of a way to suspend CPU
  // If we're here, we've got something to process in our buffer.
  for(idx = oidx; idx < osbufferptr; idx++) {
    _printchr(osbuffer[idx]);
    if (osbuffer[idx] == 10) {
      // TODO: parse user commands here and do something reasonable.
      // incoming command is complete
      _print((int32*)"\nOut:\n");
      int32 c0 = _perfcounter();
      int32 i0 = _perfcounter1();
      itoah(num_A/num_B,tmpbuf);
      int32 c1 = _perfcounter();
      int32 i1 = _perfcounter1();
      _print(tmpbuf);
      _print("\n");
      itoa(c1 - c0, tmpbuf);
      _print("IDIV+ITOAH clock cycles: ");
      _print(tmpbuf);
      _print("\n");
      itoa(i1 - i0, tmpbuf);
      _print("                  insns: ");
      _print(tmpbuf);
      _print("\n");
      osbufferptr = 0;
      oidx = 0;
    }
  }
  goto eventloop; // wait for more input
}
