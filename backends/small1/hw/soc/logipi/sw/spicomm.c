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
#include <linux/spi/spidev.h>

#include <ncurses.h>  // for non-blocking reads

typedef unsigned int uint32;

int fd ;
static const char * device = "/dev/spidev0.0";
static unsigned int mode = 0/*SPI_MODE_0 | SPI_LSB_FIRST*/;
static unsigned int bits = 8 ;
static unsigned long speed =   1000000UL ;
//static unsigned long speed = 4000000UL ;
static unsigned int delay = 50;

void spi_close(void) ;
int spi_init(void) ;
int spi_transfer(unsigned char * send_buffer, unsigned char * receive_buffer, unsigned int size);

int spi_init(void){
	int ret ;
	fd = open(device, O_RDWR);
	if (fd < 0){
		printf("can't open device\n");
		return -1 ;
	}

	ret = ioctl(fd, SPI_IOC_WR_MODE, &mode);
	if (ret == -1){
		printf("can't set spi mode \n");
		return -1 ;
	}

	ret = ioctl(fd, SPI_IOC_RD_MODE, &mode);
	if (ret == -1){
		printf("can't get spi mode \n ");
		return -1 ;
	}

	/*
	 * bits per word
	 */
	ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
	if (ret == -1){
		printf("can't set bits per word \n");
		return -1 ;
	}

	ret = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &bits);
	if (ret == -1){
		printf("can't get bits per word \n");
		return -1 ;
	}

	/*
	 * max speed hz
	 */
	ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
	if (ret == -1){
		printf("can't set max speed hz \n");
		return -1 ;
	}

	ret = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed);
	if (ret == -1){
		printf("can't get max speed hz \n");
		return -1 ;
	}
	printf("spi mode: %d\n", mode);
	printf("bits per word: %d\n", bits);
        printf("max speed: %d Hz (%d KHz)\n", speed, speed/1000);
	return 1;
}


int spi_transfer(unsigned char * send_buffer, unsigned char * receive_buffer, unsigned int size)
{
	int ret ;
	struct spi_ioc_transfer tr = {
		.tx_buf = (unsigned long)send_buffer,
		.rx_buf = (unsigned long)receive_buffer,
		.len = size,
		.delay_usecs = delay,
		.speed_hz = speed,
		.bits_per_word = bits,
	};
	ret = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
	if (ret < 1){
		printf("can't send spi message %d \n",ret);
		return -1 ;	
	}
	return 0;
}

unsigned int to_little(unsigned int a)
{
  unsigned char *buf = (unsigned char *)(&a);
  unsigned int w = buf[3];
  w += buf[2]<<8;
  w += buf[1]<<16;
  w += buf[0]<<24;
  return w;// return a;
}

int spi_transfer_w32(unsigned int *send_buffer, unsigned int *receive_buffer)
{
  unsigned int snd = *send_buffer;
  unsigned int dst;
  snd = to_little(snd);
  if(fd == 0) spi_init();
  int ret = spi_transfer((unsigned char *)&snd,(unsigned char *)&dst,4);
  *receive_buffer = to_little(dst);
  // printf("SENT:[%x] GOT:[%x]\n", *send_buffer, *receive_buffer);
  return ret;
}

void spi_close(void){
	close(fd);
}


void error(char *str)
{
  printf("%s\n", str);
  exit(-1);
}


void init_comm() {
}
