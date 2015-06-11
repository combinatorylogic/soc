#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>

#include <errno.h>
#include <termios.h>
#include <unistd.h>


void error(char *str)
{
  printf("%s\n", str);
  exit(-1);
}

int
set_interface_attribs (int fd, int speed, int parity)
{
  struct termios tty;
  memset (&tty, 0, sizeof tty);
  if (tcgetattr (fd, &tty) != 0)
    {
      exit(-1);
    }

  cfsetospeed (&tty, speed);
  cfsetispeed (&tty, speed);

  tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
  tty.c_iflag &= ~IGNBRK;
  tty.c_lflag = 0;
  tty.c_oflag = 0;
  tty.c_cc[VMIN]  = 0;
  tty.c_cc[VTIME] = 5;
  
  tty.c_iflag &= ~(IXON | IXOFF | IXANY);
  tty.c_cflag |= (CLOCAL | CREAD);
  tty.c_cflag &= ~(PARENB | PARODD);
  tty.c_cflag |= parity;
  tty.c_cflag &= ~CSTOPB;
  tty.c_cflag &= ~CRTSCTS;
  tty.c_lflag &= ~(ICANON | ECHO | ISIG);

  tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
        | INLCR | IGNCR | ICRNL | IXON);
  tty.c_oflag &= ~OPOST; 
  
  if (tcsetattr (fd, TCSANOW, &tty) != 0)
    {
      exit(-1);
    }
  return 0;
}

void
set_blocking (int fd, int should_block)
{
  struct termios tty;
  memset (&tty, 0, sizeof tty);
  if (tcgetattr (fd, &tty) != 0)
    {
      exit(-1);
    }

  tty.c_cc[VMIN]  = should_block ? 1 : 0;
  tty.c_cc[VTIME] = 5;

  if (tcsetattr (fd, TCSANOW, &tty) != 0)
    exit(-1);
}

int fd;

void init_comm()
{
  char *portname = "/dev/ttyACM0";
  fd = open (portname, O_RDWR | O_NOCTTY | O_SYNC);
  if (fd < 0) {
    exit(-1);
    return;
  }
  
  set_interface_attribs (fd, B115200, 0);
  set_blocking (fd, 0);
}

// Simulate the LogiPi SPI interface over USB
int spi_transfer_w32(unsigned int *send_buffer, unsigned int *receive_buffer)
{
  unsigned int sb0 = *send_buffer;
  write(fd, &sb0, 4);
  usleep (25); // ??? 
  int res = read(fd, receive_buffer, 4); // SOC must always send 4 bytes in
                                         // response
  if (res!=4) return -1;
  return 0;
}


