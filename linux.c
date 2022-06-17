#include <mini-printf.h>
#include <string.h>
#include <linux/bootinfo.h>

#include <linux-sender-protocol.h>

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

#define CL_SIZE 256

void linux_bootinfo(const char *command_line)
{
	char cl[CL_SIZE];

	memset(cl, 0, CL_SIZE);
	strcpy(cl, command_line);
	
	printf("Commandline passed: %s\r\n", command_line);
	printf("BootInfo at %08x\r\n", bootinfo_ptr);

	bootinfo_ptr = add_tag_ul(bootinfo_ptr, BI_MACHTYPE, MACH_MAXI030);
	bootinfo_ptr = add_tag_ul(bootinfo_ptr, BI_CPUTYPE, CPU_68030);
	bootinfo_ptr = add_tag_ul(bootinfo_ptr, BI_FPUTYPE, FPU_68882);
	bootinfo_ptr = add_tag_ul(bootinfo_ptr, BI_MMUTYPE, MMU_68030);
	
	struct mem_info m;
	m.addr = 0;
	m.size = 32 * 1024 * 1024;
	bootinfo_ptr = add_tag(bootinfo_ptr, BI_MEMCHUNK, sizeof(struct mem_info), &m);

//	bootinfo_ptr = add_tag(bootinfo_ptr, BI_COMMAND_LINE, 36, "console=ttySC0,38400 root=/dev/sda2");
//	bootinfo_ptr = add_tag(bootinfo_ptr, BI_COMMAND_LINE, 49, "console=ttySC0,38400 root=/dev/sda2 init=/bin/sh");
	bootinfo_ptr = add_tag(bootinfo_ptr, BI_COMMAND_LINE, CL_SIZE, cl);
	
	bootinfo_ptr = add_tag(bootinfo_ptr, BI_LAST, 0, NULL);
}

void *add_tag(void *start, unsigned short id, unsigned short size, void *data)
{
	struct bi_record *bi;

	bi = (struct bi_record *) start;
	bi->tag = id;
	bi->size = size + sizeof(struct bi_record);

	if (size)
		memcpy(&bi->data[0], data, size);

	return (void *)((char *)start + bi->size);
}

void *add_tag_ul(void *start, unsigned short id, unsigned long data)
{
	return add_tag(start, id, sizeof(unsigned long), &data);
}

