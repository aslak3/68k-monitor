#include <ne2k.h>
#include <asm-wrapper.h>
#include <hardware.h>
#include <mini-printf.h>
#include <string.h>

//#include <linux-sender-protocol.h>

struct ne2k_struct ne2k;

static void ne2k_transmit_ll(uint8_t *packet, uint16_t length);
static void ne2k_readmem(uint16_t src, uint8_t *dst, uint16_t len);
#if 0
static int ne2k_writemem(uint16_t dst, uint8_t *src, uint16_t length);
#endif
static void ne2k_get_packet(uint16_t src, uint8_t *dst, uint16_t len);

void ne2k_setup(void)
{
	uint8_t i = 0; 

 	ne2k.addrbase = 0x44040000UL;
	ne2k.mac[0] = 0x11;
	ne2k.mac[1] = 0x22;
	ne2k.mac[2] = 0x33;
	ne2k.mac[3] = 0x44;
	ne2k.mac[4] = 0x55;
	ne2k.mac[5] = 0x66;

	ne2k.rx_page_start = 0x40; // first page at 16k

	// 12 pages (2x 1536 bytes) at the end of the SRAM as a transmit buffer
	ne2k.rx_page_stop = 0x60 - (NE_TXBUF_SIZE * NE_TX_BUFERS); // last page at 0x60 (not 0x80 (!), because we're in 8bit mode, see RTL8019AS datasheet, p.15)
	ne2k.next_pkt = ne2k.rx_page_start + 1;

	ne2k.rx_ring_start = ne2k.rx_page_start * NE_PAGE_SIZE;
	ne2k.rx_ring_end = ne2k.rx_page_stop * NE_PAGE_SIZE;

	printf("[NE2k] Resetting card...\r\n");

	WRITE_BYTE(ne2k.addrbase + (0x1F<<1), READ_BYTE(ne2k.addrbase + (0x1F<<1)));  // write the value of RESET into the RESET register
	while ((READ_BYTE(ne2k.addrbase + (0x07<<1)) & 0x80) == 0);	  // wait for the RESET to complete
	WRITE_BYTE(ne2k.addrbase + NE_P0_ISR, 0xFF);					 // mask interrupts

	printf("[NE2k] Card reset successfully.\r\n");

	// Set page 0 registers, abort remote DMA, stop NIC
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD2 | NE_CR_STP);	

	// Set FIFO threshold to 8, no auto-init remote DMA, byte order=80x86, byte-wide DMA transfers
	WRITE_BYTE(ne2k.addrbase + NE_P0_DCR, NE_DCR_FT1 | NE_DCR_LS);

	// Set page 3 registers (RTL8019 specific)
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_PAGE_3 | NE_CR_RD2 | NE_CR_STP);
	WRITE_BYTE(ne2k.addrbase + NE_P3_9346CR, (uint8_t) (NE_EEM0 | NE_EEM1));
	WRITE_BYTE(ne2k.addrbase + NE_P3_CONFIG1, 0x00);  // io=0x300
	WRITE_BYTE(ne2k.addrbase + NE_P3_CONFIG2, 0x00);  // io=0x300
	WRITE_BYTE(ne2k.addrbase + NE_P3_CONFIG3, 0x50); // fdx, leds on

	// Set page 0 registers, abort remote DMA, stop NIC
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD2 | NE_CR_STP);

	// Clear remote byte count registers
	WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR0, 0);
	WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR1, 0);

	// Initialize receiver (ring-buffer) page stop and boundry
	WRITE_BYTE(ne2k.addrbase + NE_P0_PSTART, ne2k.rx_page_start);
	WRITE_BYTE(ne2k.addrbase + NE_P0_PSTOP, ne2k.rx_page_stop);
	WRITE_BYTE(ne2k.addrbase + NE_P0_BNRY, ne2k.rx_page_start);

	// Enable the following interrupts: receive/transmit complete, receive/transmit error, 
	// receiver overwrite and remote dma complete.
	WRITE_BYTE(ne2k.addrbase + NE_P0_IMR, NE_IMR_PRXE | NE_IMR_PTXE | NE_IMR_RXEE | NE_IMR_TXEE | NE_IMR_OVWE | NE_IMR_RDCE);

	// Set page 1 registers
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_PAGE_1 | NE_CR_RD2 | NE_CR_STP);

	// Copy out our station address
	for (i = 0; i < ETHER_ADDR_LEN; i++)
	{
#if 0
		printf("MAC %d %x\r\n", i, ne2k.mac[i]);
#endif
		WRITE_BYTE(ne2k.addrbase + NE_P1_PAR0 + (i * 2), ne2k.mac[i]);
	}

	// Set current page pointer 
	WRITE_BYTE(ne2k.addrbase + NE_P1_CURR, ne2k.next_pkt);

	// Initialize multicast address hashing registers to not accept multicasts
	for (i = 0; i < 8; i++)
		WRITE_BYTE(ne2k.addrbase + NE_P1_MAR0 + (i * 2), 0);

	// Set page 0 registers
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD2 | NE_CR_STP);

	// Accept broadcast packets
	WRITE_BYTE(ne2k.addrbase + NE_P0_RCR, 0);
//	WRITE_BYTE(ne2k.addrbase + NE_P0_RCR, NE_RCR_AB);

	// Take NIC out of loopback
	WRITE_BYTE(ne2k.addrbase + NE_P0_TCR, 0);

	// Clear any pending interrupts
	WRITE_BYTE(ne2k.addrbase + NE_P0_ISR, 0xFF);

	// Start NIC
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD2 | NE_CR_STA);

	printf("[NE2k] init done!\r\n");
}

// Wait for a frame, copying only the payload out.
uint16_t ne2k_receive(uint8_t *payload, uint16_t payload_size)
{
	struct recv_ring_desc packet_hdr;
	unsigned short packet_ptr;
	unsigned short len;
	unsigned char bndry;
	uint8_t uip_buf[6 + 6 + 2 + 1500];

	// Set page 1 registers
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_PAGE_1 | NE_CR_RD2 | NE_CR_STA);
	
	while (1)
	{
		if (ne2k.next_pkt != READ_BYTE(ne2k.addrbase + NE_P1_CURR))
		{
			// Get pointer to buffer header structure
			packet_ptr = ne2k.next_pkt * NE_PAGE_SIZE;
			
			// Read receive ring descriptor
			ne2k_readmem(packet_ptr, (uint8_t *) &packet_hdr, sizeof(struct recv_ring_desc));

			// This was once caused in 8bit mode with a page stop behind 0x60 (which isn't allowed according to the RTL8019 datasheet.)
			// It shouldn't and probably will not happen in any normal operation. 
			if (!(packet_hdr.rsr & 0x01))
			{
				printf("[NE2k] Packet read with invalid RSR, Page: 0x%02x, RSR: 0x%02x, Next Pkt: 0x%02x, Length: 0x%04x\r\n", ne2k.next_pkt, packet_hdr.rsr, packet_hdr.next_pkt, packet_hdr.count);
				return 0;
			}
		
			packet_hdr.count = ((packet_hdr.count << 8) & 0xff00) | ((packet_hdr.count >> 8) & 0x00ff);

			len = packet_hdr.count - sizeof(struct recv_ring_desc);
#if 0
			printf("[NE2k] received packet, %u bytes\r\n", len);
#endif
			if (len > 6 + 6 + 2 + 1500)
			{
				printf("[NE2k] packet too large.\r\n");
				return 0;
			}
			
			// Fetch packet payload
			packet_ptr += sizeof(struct recv_ring_desc);
			ne2k_get_packet(packet_ptr, uip_buf, len);

			// Copy it to target
			for (int s = 6 + 6 + 2, d = 0; s < len && d < payload_size; s++, d++)
				payload[d] = uip_buf[s];

			// Set the read pointer to the page number give in the received header
			ne2k.next_pkt = packet_hdr.next_pkt;

			// Set page 0 registers
			WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_PAGE_0 | NE_CR_RD2 | NE_CR_STA);

			// Update boundry pointer
			bndry = ne2k.next_pkt - 1;
			if (bndry < ne2k.rx_page_start) bndry = ne2k.rx_page_stop - 1;
			WRITE_BYTE(ne2k.addrbase + NE_P0_BNRY, bndry);

			// Set page 1 registers
			WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_PAGE_1 | NE_CR_RD2 | NE_CR_STA);

			return len;
		}
	}

	return 0;
}

#pragma pack(1)
struct frame
{
	uint8_t dst_mac[6];                 // MAC address
	uint8_t src_mac[6];                 // MAC address
	uint16_t type;
	uint8_t data[1500];
};

void test_transmit(void)
{
	uint8_t buffer[] = "Hello Linux from MAXI030!";

	for (int index = 0; index < sizeof(buffer); index += 16)
	{
		for (int i = 0; i < 16; i++)
		{
			if (index + i < sizeof(buffer))
				printf("%02x ", buffer[index + i]);
			else
				printf("   ");
		}
		for (int i = 0; i < 16; i++)
		{
			if (index + i < sizeof(buffer))
			{
				if (buffer[index + i] >= 0x20 && buffer[index + i] < 0x80)
					printf("%c", buffer[index + i]);
				else
					printf(".");
			}
		}
		printf("\r\n");
	}

	ne2k_transmit(buffer, sizeof(buffer));
}

void ne2k_transmit(uint8_t *payload, uint16_t payload_size)
{
	struct frame my_frame;
	
	my_frame.dst_mac[0] = 0xf0;
	my_frame.dst_mac[1] = 0x2f;
	my_frame.dst_mac[2] = 0x74;
	my_frame.dst_mac[3] = 0x15;
	my_frame.dst_mac[4] = 0xa3;
	my_frame.dst_mac[5] = 0x59;

	my_frame.src_mac[0] = 0x11;
	my_frame.src_mac[1] = 0x22;
	my_frame.src_mac[2] = 0x33;
	my_frame.src_mac[3] = 0x44;
	my_frame.src_mac[4] = 0x55;
	my_frame.src_mac[5] = 0x66;

	my_frame.type = 0x0888;

	for (uint16_t c = 0; c < payload_size; c++)
		my_frame.data[c] = payload[c];

	ne2k_transmit_ll((uint8_t *) &my_frame, 6 + 6 + 2 + payload_size);
}

static void ne2k_transmit_ll(uint8_t *packet, uint16_t length)
{
	unsigned short dst;
	uint16_t i; 

	while (READ_BYTE(ne2k.addrbase + NE_P0_CR) & NE_CR_TXP)
	{
		// packet is still being sent. waiting...
	}

	// Set page 0 registers
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD2 | NE_CR_STA);

	// Reset remote DMA complete flag
	WRITE_BYTE(ne2k.addrbase + NE_P0_ISR, NE_ISR_RDC);

	// Set up DMA byte count
	if (length > 64)
	{
		WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR0, (unsigned char) (length & 0xff));
		WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR1, (unsigned char) (length >> 8));
	}
	else
	{
		WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR0, (unsigned char) 64);
		WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR1, (unsigned char) 0);
	}
	
	// Set up destination address in NIC memory
	dst = ne2k.rx_page_stop; // for now we only use one tx buffer
	WRITE_BYTE(ne2k.addrbase + NE_P0_RSAR0, (unsigned char) ((dst * NE_PAGE_SIZE) & 0xff));
	WRITE_BYTE(ne2k.addrbase + NE_P0_RSAR1, (unsigned char) ((dst * NE_PAGE_SIZE) >> 8));

	// Set remote DMA write
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD1/* | NE_CR_STA*/);

	for (i = 0; i < length; ++i)
	{
		WRITE_BYTE(ne2k.addrbase + NE_NOVELL_DATA, packet[i]);
	}
	while (i++ < 64)
	{
		WRITE_BYTE(ne2k.addrbase + NE_NOVELL_DATA, 0x00);
	}

	// Set TX buffer start page
	WRITE_BYTE(ne2k.addrbase + NE_P0_TPSR, dst);

	// Set TX length (packets smaller than 64 bytes must be padded)
	if (length > 64)
	{
		WRITE_BYTE(ne2k.addrbase + NE_P0_TBCR0, (uint8_t) (length & 0xff));
		WRITE_BYTE(ne2k.addrbase + NE_P0_TBCR1, (uint8_t) (length >> 8));
	}
	else
	{
		WRITE_BYTE(ne2k.addrbase + NE_P0_TBCR0, 64);
		WRITE_BYTE(ne2k.addrbase + NE_P0_TBCR1, 0);
	}

	// Set page 0 registers, transmit packet, and start
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD2 | NE_CR_TXP | NE_CR_STA);

#if 0
	printf("[NE2k] Transmitted packet with length %d\r\n", length);
#endif
}

static void ne2k_readmem(uint16_t src, uint8_t *dst, uint16_t len)
{   
	uint16_t i;

	// Abort any remote DMA already in progress
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD2 | NE_CR_STA);

	// Setup DMA byte count
	WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR0, (uint8_t) (len & 0xff));
	WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR1, (uint8_t) (len >> 8));

	// Setup NIC memory source address
	WRITE_BYTE(ne2k.addrbase + NE_P0_RSAR0, (uint8_t) (src & 0xff));
	WRITE_BYTE(ne2k.addrbase + NE_P0_RSAR1, (uint8_t) (src >> 8));

	// Select remote DMA read
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD0 | NE_CR_STA);

	// Read NIC memory
	for (i = 0; i < len; i++)
	{
		((uint8_t*)dst)[i] = READ_BYTE(ne2k.addrbase + NE_NOVELL_DATA);
	}
}

#if 0
static int ne2k_writemem(uint16_t dst, uint8_t *src, uint16_t length)
{
	uint16_t i;

	// Set page 0 registers
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD2 | NE_CR_STA);

	// Reset remote DMA complete flag
	WRITE_BYTE(ne2k.addrbase + NE_P0_ISR, READ_BYTE(ne2k.addrbase + NE_P0_ISR) & ~NE_ISR_RDC);

	// Set up destination address in NIC memory
	WRITE_BYTE(ne2k.addrbase + NE_P0_RSAR0, (unsigned char) (dst & 0xff));
	WRITE_BYTE(ne2k.addrbase + NE_P0_RSAR1, (unsigned char) (dst >> 8));
	
	WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR0, (unsigned char) (length & 0xff));
	WRITE_BYTE(ne2k.addrbase + NE_P0_RBCR1, (unsigned char) (length >> 8));

	// Set remote DMA write
	WRITE_BYTE(ne2k.addrbase + NE_P0_CR, NE_CR_RD1 | NE_CR_STA);

	for (i = 0; i < length; ++i)
		WRITE_BYTE(ne2k.addrbase + NE_NOVELL_DATA, src[i]);

	return 0;
}
#endif

static void ne2k_get_packet(uint16_t src, uint8_t *dst, uint16_t len)
{
	if (src + len > ne2k.rx_ring_end)
	{
		uint16_t split = ne2k.rx_ring_end - src;

		ne2k_readmem(src, dst, split);
		len -= split;
		src = ne2k.rx_ring_start;
		dst += split;
	}

	ne2k_readmem(src, dst, len);
}
