#include "asm-wrapper.h"
#include "hardware.h"
#include "mini-printf.h"

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

unsigned long int next;

static void runcommand(uint16_t command)
{
	WRITE_WORD(VIDCOMMAND, command);
	while (READ_WORD(VIDSTATUS) & 0x0001);
}

static int rand(void)
{
	next = next * 1103515243 + 12345;
	return (unsigned int)(next / 65536) % 32768;
}


void clearscreen(void)
{
	WRITE_WORD(VIDPENCOLOUR, 0);
	runcommand(VIDCOMMCLEAR);
}
	
void drawstuff(void)
{
	next = 1;
	
	clearscreen();
	while (1)
	{
		uint16_t x0 = rand() % 640;
		uint16_t y0 = rand() % 480;
		uint16_t x1 = rand() % 640;
		uint16_t y1 = rand() % 480;
		
		WRITE_WORD(VIDX0, MIN(x0, x1));
		WRITE_WORD(VIDY0, MIN(y0, y1));
		WRITE_WORD(VIDX1, MAX(x0, x1));
		WRITE_WORD(VIDY1, MAX(y0, y1));

		WRITE_WORD(VIDPENCOLOUR, rand() % 65536);
		runcommand(rand () & 1 ? VIDCOMMFILLEDBOX : VIDCOMMHOLLOWBOX);

		int c;
		for (c = 0; c < 1000000; c++);
	
		printf("A box %d %d %d %d\r\n", x0, y0, x1, y1);
	}
}
		
	