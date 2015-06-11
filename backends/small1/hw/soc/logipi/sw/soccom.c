#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <linux/types.h>

#include <ncurses.h>  // for non-blocking reads

typedef unsigned int uint32;

extern void error(char *str);
extern int spi_transfer_w32(unsigned int *send_buffer, unsigned int *receive_buffer);
extern void init_comm();

unsigned int ctr;

unsigned int small1_poll()
{
  unsigned int CMD = 1; // POLL CMD
  unsigned int rbuf = 31;
  int ret = spi_transfer_w32(&CMD, &rbuf); // send command
  CMD = 0xffffffff;
  ret = spi_transfer_w32(&CMD, &rbuf); // send command
  if(ret) error("Cannot write");
  return rbuf;
}

unsigned int small1_ping(unsigned int v)
{
  unsigned int CMD = v; // NO CMD
  unsigned int rbuf = 31;
  int ret = spi_transfer_w32(&CMD, &rbuf); // send command
  if(ret) error("Cannot write");
  return rbuf;
}

#define POLL_PC 0
#define POLL_SP 1
#define POLL_LASTBR 2
#define POLL_INSTR 6
#define POLL_POP1 4
#define POLL_POP2 5
#define POLL_PUSH 3

unsigned int small1_pollreg(unsigned int id)
{
  unsigned int CMD = ((id&0xffff)<<16) | 0x4; // POLL REGISTER
  unsigned int rbuf = 31;
  int ret = spi_transfer_w32(&CMD, &rbuf); // send command
  if(ret) error("Cannot write");
  ret = spi_transfer_w32(&CMD, &rbuf); // send dummy
  if(ret) error("Cannot write");
  return rbuf;
}

void small1_send(unsigned int chr)
{
  unsigned int CMD = 2; // SEND CMD
  unsigned int rbuf = 31;
  int ret = spi_transfer_w32(&CMD, &rbuf); // send command
  if(ret) error("Cannot write");
  ret = spi_transfer_w32(&chr, &rbuf); // send command
  if(ret) error("Cannot write");
}

unsigned int small1_prog(unsigned int *buffer,
                         unsigned int length, int debugp)
{
  small1_ping(0xefab);
  small1_ping(0xefab);
  unsigned int CMD = 99|((debugp&1)<<16); // bootload cmd
  unsigned int rbuf = 31;
  int ret = spi_transfer_w32(&CMD, &rbuf); // send command
  if(ret) error("Cannot write");
  ret = spi_transfer_w32(&length, &rbuf); // send length
  if (ret) error("Cannot write");
  int i;
  for (i = 0; i < length; i++) {
    ret = spi_transfer_w32(&buffer[i], &rbuf);
    if (i>0 && rbuf!=buffer[i-1]) printf("Poo poo shit %x vs %x at %x\n", rbuf, buffer[i-1], i);
    if (ret) error("Cannot write");
  }
}

unsigned int *readhexfile(char *fn, unsigned int *blen)
{
  FILE *f;
  unsigned int *buf;
  unsigned int len = 0, size = 65536; unsigned int X;
  f = fopen(fn,"r");
  if (!f) error("Cannot open hex file");
  buf = (unsigned int *)malloc(size*4);
  while (fscanf(f, "%x\n", &X)!=EOF) {
    buf[len++] = X;
    if (len > size - 10) {
      size *= 2;
      buf = (unsigned int *)realloc(buf, size*4);
    }
  }
  fclose(f);
  *blen = len;
  return buf;
}

void printregs()
{
  uint32 PC = 
    small1_pollreg(POLL_PC);
  uint32 SP = 
    small1_pollreg(POLL_SP);

  uint32 LASTBR = 
    small1_pollreg(POLL_LASTBR);
    
  uint32 POP1 = 
    small1_pollreg(POLL_POP1);
    
  uint32 POP2 = 
    small1_pollreg(POLL_POP2);
    
  uint32 INSTR = 
    small1_pollreg(POLL_INSTR);

  uint32 LPUSH = 
    small1_pollreg(POLL_PUSH);
    
  printw("PC=%x, SP=%x, LASTBR=%x\n", PC, SP, LASTBR);
  printw("POP1=%x, POP2=%x, PUSH=%x, INSTR=%x\n", POP1, POP2, LPUSH, INSTR);
}

void printregsf()
{
  uint32 PC = 
    small1_pollreg(POLL_PC);
  uint32 SP = 
    small1_pollreg(POLL_SP);
    
  uint32 LASTBR = 
    small1_pollreg(POLL_LASTBR);
    
  uint32 POP1 = 
    small1_pollreg(POLL_POP1);
    
  uint32 POP2 = 
    small1_pollreg(POLL_POP2);
    
  uint32 INSTR = 
    small1_pollreg(POLL_INSTR);

  uint32 LPUSH = 
    small1_pollreg(POLL_PUSH);
    
  printf("PC=%x, SP=%x, LASTBR=%x\n", PC, SP, LASTBR);
  printf("POP1=%x, POP2=%x, PUSH=%x, INSTR=%x\n", POP1, POP2, LPUSH, INSTR);
}

int main(int argc, char **argv)
{
  ctr = 0;
  if (argc < 2) error("Usage: small1prog <filename.hex> [--debug]");
  unsigned int len;
  unsigned int *buf;
  int debugp = 0;
  if (argc > 2 && !strcmp("--debug", argv[2])) debugp = 1;

  init_comm();

  
  buf = readhexfile(argv[1], &len);
  small1_prog(buf, len, debugp);
  if(debugp) {
    uint32 i;
    for(i = 0;; i++) {
      printregsf();
      small1_ping(0x0005); // debug step CMD
      if(!(i%1000)) {small1_send('\n');printf("COMMSEND\n");}
      unsigned int recv = small1_poll();
      if (recv != 0xffffffff) {printf("COMMRECV=[%x]\n",recv);}
      fflush(stdout);
    }
    exit(0);
  }

  if (getenv("SOCCOM_BATCH")) {
    while(1) {
      unsigned int recv = small1_poll();
      if (recv != 0xffffffff) { putchar(recv); fflush(stdout); }
      if (recv == 0xff) {
        exit(0);
      }
    }
  } else {

    // Enter ncurses
    WINDOW *w = initscr();
    cbreak();noecho();
    nodelay(w, TRUE);scrollok(w, TRUE);
    printw("Polling SMALL1SOC via SPI\n");
    
    
    while(1) {
      unsigned int recv = small1_poll();
      if (recv != 0xffffffff) printw("%c",recv);
      int chr = getch();
      if (chr == '.') {
        if (!debugp) {
          debugp = 1;
          small1_ping(6); // start debug
        }
        small1_ping(5); // debug step
        printregs();
      } else if (chr != ERR) {
        small1_send(chr);
      }
    }
  }
}

