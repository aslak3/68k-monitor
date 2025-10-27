#include <mini-printf.h>
#include <string.h>

#include <sender-protocol.h>

void ne2k_setup(void);
uint16_t ne2k_receive(uint8_t *payload, uint16_t payload_size);
void ne2k_transmit(uint8_t *payload, uint16_t payload_size);

void *add_tag(void *start, unsigned short id, unsigned short size, void *data);
void *add_tag_ul(void *start, unsigned short id, unsigned long data);

uint8_t *bootinfo_ptr = NULL;

void eth_download(char *filename, uint8_t *start)
{
	struct request_block request_block;

	printf("Downloading %s to %x\r\n", filename, start);

	strcpy(request_block.filename, filename);

	ne2k_setup();

	ne2k_transmit((uint8_t *) &request_block, sizeof(request_block));

	struct reply_block reply_block;

	ne2k_receive((uint8_t *) &reply_block, sizeof(struct reply_block));
	
	printf("File size: %d (0x%x)\r\n", reply_block.file_size, reply_block.file_size);
	
	struct ack_block ack_block;
	
	ne2k_transmit((uint8_t *) &ack_block, sizeof(struct ack_block));
	
	uint8_t *target = start;
	int col = 0;
	while (target < (uint8_t *)(start + reply_block.file_size))
	{
		ne2k_receive(target, 1024);

		ne2k_transmit(target, 1024);
		
		ne2k_receive((uint8_t *) &ack_block, sizeof(struct ack_block));
		if (ack_block.failed != 0)
		{
			printf("\r\nFailed\r\n");
			col = 0;
		}
		else
		{
			col++;
			printf("#");
			if (col == 80)
			{
				printf("\r\n");
				col = 0;
			}				
			
			target += 1024;
		}

		ne2k_transmit((uint8_t *) &ack_block, sizeof(struct ack_block));
	}

	bootinfo_ptr = (uint8_t *)(reply_block.file_size + 4096 + 4095);
	bootinfo_ptr = (uint8_t *)((uintptr_t) bootinfo_ptr & (uintptr_t) 0xfffff000);
	
	while (target < bootinfo_ptr + 0x2000)
		*target++ = '\0';
}
