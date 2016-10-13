#include <iostream>
#include <chrono>
#include <mutex>
#include <thread>
#include <verilated.h>
#include "Vtop.h"

#include <ncurses.h>

Vtop *top;

vluint64_t sim_clock = 0;
vluint64_t sys_clock = 0;

typedef unsigned int uint32;

void error(char *str)
{
  printf("%s\n", str);
  exit(-1);
}

unsigned int *readhexfile(char *fn, unsigned int *blen)
{
  FILE *f;
  unsigned int *buf;
  unsigned int len = 2, size = 65536; unsigned int X;
  f = fopen(fn,"r");
  if (!f) error("Cannot open hex file");
  buf = (unsigned int *)malloc(size*4);
  buf[0] = 99; // BOOTLOAD CMD
  while (fscanf(f, "%x\n", &X)!=EOF) {
    buf[len++] = X;
    if (len > size - 10) {
      size *= 2;
      buf = (unsigned int *)realloc(buf, size*4);
    }
  }
  fclose(f);
  *blen = len;
  buf[1] = len-2;
  return buf;
}

unsigned int to_small1;
bool to_small1_ready;
std::mutex to_small1_m;

bool queued_to(unsigned int *out)
{
  bool ret;
  to_small1_m.lock();
  ret = to_small1_ready;
  if (ret) *out = to_small1;
  to_small1_ready = false;
  to_small1_m.unlock();
  return ret;
}

void queue_to(unsigned int msg)
{
 poll:
  to_small1_m.lock();
  if (to_small1_ready) {
    to_small1_m.unlock();
    std::this_thread::sleep_for(std::chrono::microseconds(50));
    goto poll;
  }
  to_small1 = msg;
  to_small1_ready = true;
  to_small1_m.unlock();
}

unsigned int from_small1;
bool from_small1_ready;
std::mutex from_small1_m;

bool queued_from(unsigned int *out)
{
  bool ret;
  from_small1_m.lock();
  ret = from_small1_ready;
  if (ret) *out = from_small1;
  from_small1_ready = false;
  from_small1_m.unlock();
  return ret;
}

unsigned int wait_from()
{
  unsigned int ret;
  while(!queued_from(&ret))
    std::this_thread::sleep_for(std::chrono::microseconds(50));
  return ret;
}

void queue_from(unsigned int msg)
{
 poll:
  from_small1_m.lock();
  if (from_small1_ready) {
    from_small1_m.unlock();
    std::this_thread::sleep_for(std::chrono::microseconds(50));
    goto poll;
  }
  from_small1 = msg;
  from_small1_ready = true;
  from_small1_m.unlock();
}

unsigned int small1_poll()
{
  queue_to(0x01); // POLL CMD
  unsigned int tmp = wait_from(); // just eat it
  queue_to(0xffffffff); // dummy
  return wait_from();
}

void small1_send(unsigned int msg)
{
  queue_to(0x02); // SEND CMD
  unsigned int tmp = wait_from(); // just eat it

  queue_to(msg); // send message
  tmp = wait_from(); // just eat it
}

#define POLL_PC 1
#define POLL_SP 2
#define POLL_MEMSTATE 3
#define POLL_ADDR 4
#define POLL_LASTBR 5
#define POLL_INSTR 6
#define POLL_POP1 7
#define POLL_POP2 8
#define POLL_PUSH 9
#define POLL_OUTEMPTY 10
#define POLL_INEMPTY 11
#define POLL_IN_IRQ 12
#define POLL_MEMDATA 13

int spi_transfer_w32(unsigned int *cmd, unsigned int *rbuf)
{
  queue_to(*cmd);
  *rbuf = wait_from();
  return 0;
}

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

void printregs()
{
  uint32 PC = 
    small1_pollreg(POLL_PC);
  uint32 SP = 
    small1_pollreg(POLL_SP);
  uint32 MS = 
    small1_pollreg(POLL_MEMSTATE);
  uint32 ADDR = 
    small1_pollreg(POLL_ADDR);
    
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
    
  uint32 OUTEMPTY = 
    small1_pollreg(POLL_OUTEMPTY);
    
  uint32 INEMPTY = 
    small1_pollreg(POLL_INEMPTY);
    
  uint32 IN_IRQ = 
    small1_pollreg(POLL_IN_IRQ);
    
  uint32 MEMDATA = 
    small1_pollreg(POLL_MEMDATA);
    
  printw("PC=%x, SP=%x, MS=%x, ADDR=%x (-> %x), LASTBR=%x\n", PC, SP, MS, ADDR, MEMDATA, LASTBR);
  printw("POP1=%x, POP2=%x, PUSH=%x, INSTR=%x\n", POP1, POP2, LPUSH, INSTR);
  printw("OUTEMPTY=%x, INEMPTY=%x, IN_IRQ=%x\n\n", OUTEMPTY, INEMPTY, IN_IRQ);
}

bool interact_p;

void commproc()
{
  if (interact_p) {
    WINDOW *w = initscr();
    cbreak();noecho();
    nodelay(w, TRUE);scrollok(w, TRUE);
    printw("Polling SMALL1SOC via SPI\n");
    
    unsigned int ctr = 0;
    
    while(1) {
      unsigned int recv = small1_poll();
      if (recv != 0xffffffff) printw("%c",recv);
      int chr = getch();
      if (chr != ERR) {
        small1_send(chr);
      }
    }
  } else {
    while(1) {
      unsigned int recv = small1_poll();
      if (recv == 0xff) {
        small1_send('\n'); // promt test to quit
      } else
        if (recv != 0xffffffff) { printf("%c",recv);fflush(stdout); }
    }
  }
}

typedef enum {
  SPI_IDLE,
  SPI_DONE,
  SPI_SENDBIT,
  SPI_ENDBIT,
  SPI_ENDMSG
} spistate;

int main(int argc, char **argv, char **env) {
  interact_p = true;
  char *fname = NULL;
  if (argc>1 && !strcmp(argv[1], "--batch")) interact_p = false;
  if (argc>2) fname = argv[2];

  unsigned int buflen = 0;
  unsigned int *buf = readhexfile(fname==NULL?(char *)"small1.hex":fname, &buflen); // TODO: pass hex file name as an argument
  top = new Vtop;		// Create instance of module


  Verilated::commandArgs(argc, argv);
  Verilated::debug(0);

  to_small1_ready = false;
  from_small1_ready = false;
  
  top->clk100mhz = 0;		// Clock
  top->PB = 0;                  // reset button pressed
  top->RP_SPI_CE0N = 1;         // De-select SPI SS
  
  // Warm up in reset
  while(sys_clock < 100) {
    if (sim_clock%4==0) {
      top->clk100mhz = 1; sys_clock++;
    } else if (sim_clock%4==2) top->clk100mhz = 0;
    if(sim_clock == 300) {
      top->PB = 1; // Release reset button
    }
    top->eval();
    sim_clock++;
  }

  if (interact_p) printf("Sending hex [%d words]\n", buflen);
  // Send hex file via SPI
  spistate SPI_state = SPI_IDLE;
  unsigned int currentword;
  unsigned int bufpos = 0;
  unsigned int currentbits;
  unsigned int current_in;

  unsigned long long brk;
  
  while(1) {
    if (sim_clock%2==0) {
      top->clk100mhz = 1; sys_clock++;
    } else if (sim_clock%2==1) top->clk100mhz = 0;

    if ((sim_clock%2 == 1) && (sys_clock%8 == 1)) { // Exec SPI action
      switch(SPI_state) {
      case SPI_IDLE: {  // Initiate next word
        // N.B., this is not very faithful to how a Linux SPI driver is doing things,
        //       despite claiming the opposite, it cannot be configured to send more than 8-bits at once,
        //       so the real driver will lower SS four times per word instead of just one as in here.
        if (bufpos < buflen) {
          currentword = buf[bufpos]; bufpos ++;
          currentbits = 32;
          current_in = 0;
          top->RP_SPI_CE0N = 0; // Activate SS
          top->SYS_SPI_SCK = 0;
          SPI_state = SPI_SENDBIT;
          if (interact_p) {printf("*"); fflush(stdout);}
        } else {
          SPI_state = SPI_DONE;
          brk = sys_clock;
        }
        break;
      }
      case SPI_SENDBIT: {
        top->SYS_SPI_SCK = 1; // raise SPI SCK
        top->SYS_SPI_MOSI = (currentword>>31)&1; // Send upper bit
        currentbits --;
        currentword<<=1;
        SPI_state = SPI_ENDBIT;
        break;
      }
      case SPI_ENDBIT: {
        top->SYS_SPI_SCK = 0; // lower SPI SCK
        current_in = (current_in<<1) | top->SYS_SPI_MISO; // read bit
        if (!currentbits) { // word done
          SPI_state = SPI_ENDMSG;
          if (bufpos>3 && current_in != buf[bufpos-2])
            printf("OOPS %x(%x) at %x\n", current_in,buf[bufpos-2], bufpos-2);
        } else SPI_state = SPI_SENDBIT;
        break;
      }
      case SPI_ENDMSG: {
        top->RP_SPI_CE0N = 1; // Release SS
        SPI_state = SPI_IDLE; // Next word
        break;
      }
      }
    }

    if (SPI_state == SPI_DONE && sys_clock - brk > 500) break;
    
    top->eval();
    sim_clock++;
  }

  SPI_state = SPI_IDLE;

  // Start user interactive process
  std::thread usercomm(commproc);

  // Start SPI communication loop
  while(!top->FINISH) {
    if (sim_clock%2==0) {
      top->clk100mhz = 1; sys_clock++;
    } else if (sim_clock%2==1) top->clk100mhz = 0;

    if ((sim_clock%2 == 1) && (sys_clock%8==1)) { // Exec SPI action
      switch(SPI_state) {
      case SPI_IDLE: {  // Initiate next word
        unsigned int comm = 0;
        if (queued_to(&comm)) {
          currentword = comm;
          currentbits = 32;
          current_in = 0;
          top->RP_SPI_CE0N = 0; // Activate SS
          top->SYS_SPI_SCK = 0;
          SPI_state = SPI_SENDBIT;
        } else {
          SPI_state = SPI_IDLE;
        }
        break;
      }
      case SPI_SENDBIT: {
        top->SYS_SPI_SCK = 1; // raise SPI SCK
        top->SYS_SPI_MOSI = (currentword>>31)&1; // Send upper bit
        currentbits --;
        currentword<<=1;
        SPI_state = SPI_ENDBIT;
        break;
      }
      case SPI_ENDBIT: {
        top->SYS_SPI_SCK = 0; // lower SPI SCK
        current_in = (current_in<<1) | top->SYS_SPI_MISO; // read bit
        if (!currentbits) { // word done
          SPI_state = SPI_ENDMSG;
          queue_from(current_in);
        } else SPI_state = SPI_SENDBIT;
        break;
      }
      case SPI_ENDMSG: {
        top->RP_SPI_CE0N = 1; // Release SS
        SPI_state = SPI_IDLE; // Next word
        break;
      }
      }
    }

    top->eval();
    sim_clock++;
  }
  top->final();
  //usercomm.join();
  exit(0);
}
