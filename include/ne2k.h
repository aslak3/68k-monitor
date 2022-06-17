#pragma once

#include <stdint.h>
#include "ne2k_const.h"

struct ne2k_struct {
    uint8_t mac[6];                 // MAC address
    uint32_t addrbase;                // Configured I/O base
    uint8_t rx_page_start;          // Start of receive ring
    uint8_t rx_page_stop;           // End of receive ring
    uint8_t next_pkt;               // Next unread received packet
    uint16_t rx_ring_start;         // Start address of receive ring
    uint16_t rx_ring_end;           // End address of receive ring
};

struct recv_ring_desc {
    unsigned char rsr;              // Receiver status
    unsigned char next_pkt;         // Pointer to next packet
    unsigned short count;           // Bytes in packet (length + 4)
};

void ne2k_setup(void);
void ne2k_transmit(uint8_t *payload, uint16_t payload_size);
uint16_t ne2k_receive(uint8_t *payload, uint16_t payload_size);
