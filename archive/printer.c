#include "asm-wrapper.h"
#include "hardware.h"
#include "mini-printf.h"

int print_buffer(uint8_t *buffer, uint32_t length)
{
	/* Set port A to be an output */
	WRITE_BYTE(PITPADDR, 0xff);
	/* Set port B to be an input */
	WRITE_BYTE(PITPBDDR, 0x00);
	/* Submode 01, pulsed H2 */
	WRITE_BYTE(PITPACR, 0x78);
	/* Enable port A, mode 0 */
	WRITE_BYTE(PITPGCR, 0x10);
	
	uint32_t i;	
	for (i = 0; i < length; i++)
	{
		if (READ_BYTE(PITPBAR) & (1<<PRTSTATUSPAPEROUT))
		{
			printf("Paper out\r\n");
			break;
		}
		if (!(READ_BYTE(PITPBAR) & (1<<PRTSTATUSNOTSELECT)))
		{
			printf("Printer not selected\r\n");
			break;
		}
		WRITE_BYTE(PITPADR, buffer[i]);
		while (!(READ_BYTE(PITPSR) & 0x01));
	}

	return i;
}

