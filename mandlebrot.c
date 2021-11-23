/**  mandel.c   by Eric R. Weeks   written 9-28-96
 **  weeks@physics.emory.edu
 **  http://www.physics.emory.edu/~weeks/
 **  
 **  This program is public domain, but this header must be left intact
 **  and unchanged.
 **  
 **  to compile:  cc -o mand mandel.c
 ** 
 **/

#include <math.h>
#include <stdlib.h>
#include <stdint.h>
#include "hardware.h"
#include "mini-printf.h"

static void color();
uint16_t *ptr;

void mandlebrotc(void)
{
	double x,xx,y,cx,cy;
	int iteration,hx,hy;
	int itermax = 100;		/* how many iterations to do	*/
	double magnify=1.0;		/* no magnification		*/
	int hxres = 640;		/* horizonal resolution		*/
	int hyres = 480;		/* vertical resolution		*/
	int c;
	
	for (c = 1; c < 100; c++)
	{
		float f = 1.0/c;
		
		printf("%d\r\n", (int)(f*1000.0));
	}
	WRITE_BYTE(LED, 1);
	WRITE_WORD(0x80200008, 0);
	WRITE_WORD(0x8020000c, 0);
	
	ptr = (uint16_t *)0x80000000;

	for (hy=1;hy<=hyres;hy++)  {
		for (hx=1;hx<=hxres;hx++)  {
			cx = (((float)hx)/((float)hxres)-0.5)/magnify*3.0-0.7;
			cy = (((float)hy)/((float)hyres)-0.5)/magnify*3.0;
			x = 0.0; y = 0.0;
			for (iteration=1;iteration<itermax;iteration++)  {
				xx = x*x-y*y+cx;
				y = 2.0*x*y+cy;
				x = xx;
				if (x*x+y*y>100.0) break;
			}
			if (iteration<99999)  color(iteration % 256,iteration % 64 * 4,iteration % 16 * 16);
			else color(0,0,180);
		}
	}
}

static void color(int red, int green, int blue)
{
	WRITE_WORD(ptr, (uint16_t) ( (red / 8) | ((green / 4) << 5) | ((blue / 8) << 9)) );
	ptr = ptr + 1;
}
