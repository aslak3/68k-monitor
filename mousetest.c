#include <stdint.h>

#include "hardware.h"

#define STATE_IDLE 0
#define STATE_ENABLE_ACK 1
#define STATE_STREAMING 2

#define CMD_ENABLE 0xf4

#define LINE_LEN_WORDS (640 / 16 * 2)
#define SCALING 32

struct mouse_packet
{
	uint8_t mouse_state;
	uint8_t x_delta;
	uint8_t y_delta;
};

void clear_screen(void);
void update_mouse_state(struct mouse_packet *mp);
void draw_dot_at_pos(void);

volatile uint8_t new_data;
volatile uint8_t data;

int16_t x_pos, y_pos;

void mousetest(void)
{
	struct mouse_packet mp;
	uint16_t state = STATE_IDLE;
	uint8_t mp_counter = 0;

	clear_screen();
	
	x_pos = 640 / 2;
	y_pos = 480 / 2;

	draw_dot_at_pos();

	new_data = 0;

	WRITE_BYTE(PS2ASCANCODE, CMD_ENABLE);
	
	while (1)
	{
		while (!new_data);
		new_data = 0;
		WRITE_BYTE(SPIDATA, data);
		
		switch (state)
		{
			case STATE_IDLE:
				state = STATE_ENABLE_ACK;
				break;

			case STATE_ENABLE_ACK:
				state = STATE_STREAMING;
				mp_counter = 0;
				break;
			
			case STATE_STREAMING:
				if (mp_counter == 0)
					mp.mouse_state = data;
				else if (mp_counter == 1)
					mp.x_delta = data;
				else if (mp_counter == 2)
					mp.y_delta = data;
				mp_counter++;
				if (mp_counter >= 3)
				{
					mp_counter = 0;
					update_mouse_state(&mp);
				}
				break;
			
			default:
				break;
		}
	}
}

void update_mouse_state(struct mouse_packet *mp)
{
	WRITE_WORD(LED, mp->mouse_state & 0x01);

	draw_dot_at_pos();

	x_pos += mp->x_delta - ((mp->mouse_state) << 4 & 0x100);
	y_pos -= mp->y_delta - ((mp->mouse_state) << 3 & 0x100);

	if (x_pos < 0) x_pos = 0;
	if (x_pos > 639) x_pos = 639;
	if (y_pos < 0) y_pos = 0;
	if (y_pos > 479) y_pos = 479;

	if (!(mp->mouse_state & 0x01))
		draw_dot_at_pos();
}					

void clear_screen(void)
{
	WRITE_LONG(VGARWADDRHI, 0L);
	for (uint16_t c = 0; c < 640 / 16 * 480 * 2U; c++)
		WRITE_WORD(VGADATA, 0xffffU);
}

void draw_dot_at_pos(void)
{
	uint32_t address = (y_pos * LINE_LEN_WORDS) + (x_pos / 16 * 2);
	uint16_t odd = (x_pos / 8) % 2;

	WRITE_LONG(VGARWADDRHI, address);
	READ_WORD(VGADATA);
	uint8_t plane1 = READ_BYTE(VGADATA + odd);
	uint8_t plane2 = READ_BYTE(VGADATA + odd); 

	plane1 ^= 1 << (7 - (x_pos % 8));
	plane2 ^= 1 << (7 - (x_pos % 8));
	
	WRITE_LONG(VGARWADDRHI, address);
	WRITE_BYTE(VGADATA + odd, plane1);
	WRITE_BYTE(VGADATA + odd, plane2); 
}

void  __attribute__ ((interrupt)) mouseisr(void)
{
	data = READ_BYTE(PS2ASCANCODE);
	new_data = 1;
}
