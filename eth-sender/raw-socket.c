/*
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 */

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <string.h>

#define MAXI030_MAC0	0x11
#define MAXI030_MAC1	0x22
#define MAXI030_MAC2	0x33
#define MAXI030_MAC3	0x44
#define MAXI030_MAC4	0x55
#define MAXI030_MAC5	0x66

#define DEFAULT_IF	"enp4s0"
#define BUF_SIZ		1024

int init_raw_socket(char *interface_name);
int packet_tx(int sockfd, uint8_t *buffer, int buffer_size);
int packet_rx(int sockfd, uint8_t *buffer, int buffer_size);

struct ifreq if_idx;
struct ifreq if_mac;

int init_raw_socket(char *interface_name)
{
	int sockfd;
	struct ifreq ifopts;    /* set promiscuous mode */
	int sockopt;
	
	/* Open RAW socket to send on */
	if ((sockfd = socket(AF_PACKET, SOCK_RAW, htons(0x0888))) == -1)
	{
		perror("socket");
		close(sockfd);
		exit(EXIT_FAILURE);
	}


	/* Get the index of the interface to send on */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, interface_name, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFINDEX, &if_idx) < 0)
	{
		perror("SIOCGIFINDEX");
		close(sockfd);
		exit(EXIT_FAILURE);
	}
	    
	/* Get the MAC address of the interface to send on */
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, interface_name, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFHWADDR, &if_mac) < 0)
	{
		perror("SIOCGIFHWADDR");
		close(sockfd);
		exit(EXIT_FAILURE);
	}

	/* Set interface to promiscuous mode - do we need to do this every time? */
	strncpy(ifopts.ifr_name, interface_name, IFNAMSIZ-1);
	ioctl(sockfd, SIOCGIFFLAGS, &ifopts);
	ifopts.ifr_flags |= IFF_PROMISC;
	ioctl(sockfd, SIOCSIFFLAGS, &ifopts);
	/* Allow the socket to be reused - incase connection is closed prematurely */
	if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &sockopt, sizeof sockopt) == -1)
	{
		perror("setsockopt");
		close(sockfd);
		exit(EXIT_FAILURE);
	}
	/* Bind to device */
	if (setsockopt(sockfd, SOL_SOCKET, SO_BINDTODEVICE, interface_name, IFNAMSIZ-1) == -1)
	{
		perror("SO_BINDTODEVICE");
		close(sockfd);
		exit(EXIT_FAILURE);
	}

	return sockfd;
}

int packet_tx(int sockfd, uint8_t *buffer, int buffer_size)
{
	char sendbuf[6 + 6 + 2 + BUF_SIZ];
	struct ether_header *eh = (struct ether_header *) sendbuf;
	int tx_len = 0;
	struct sockaddr_ll socket_address;

	/* Construct the Ethernet header */
	memset(sendbuf, 0, BUF_SIZ);
	/* Ethernet header */
	eh->ether_shost[0] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[0];
	eh->ether_shost[1] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[1];
	eh->ether_shost[2] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[2];
	eh->ether_shost[3] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[3];
	eh->ether_shost[4] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[4];
	eh->ether_shost[5] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[5];
	eh->ether_dhost[0] = MAXI030_MAC0;
	eh->ether_dhost[1] = MAXI030_MAC1;
	eh->ether_dhost[2] = MAXI030_MAC2;
	eh->ether_dhost[3] = MAXI030_MAC3;
	eh->ether_dhost[4] = MAXI030_MAC4;
	eh->ether_dhost[5] = MAXI030_MAC5;
	/* Ethertype field */
	eh->ether_type = htons(0x888);
	tx_len += sizeof(struct ether_header);

	/* Packet data */
	memset(&sendbuf[tx_len], 0, BUF_SIZ);
 	memcpy(&sendbuf[tx_len], buffer, buffer_size);
	tx_len = 6 + 6 + 2 + buffer_size;

	/* Index of the network device */
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
	/* Address length*/
	socket_address.sll_halen = ETH_ALEN;
	/* Destination MAC */
	socket_address.sll_addr[0] = MAXI030_MAC0;
	socket_address.sll_addr[1] = MAXI030_MAC1;
	socket_address.sll_addr[2] = MAXI030_MAC2;
	socket_address.sll_addr[3] = MAXI030_MAC3;
	socket_address.sll_addr[4] = MAXI030_MAC4;
	socket_address.sll_addr[5] = MAXI030_MAC5;

	if (tx_len < 64) tx_len = 64;

	/* Send packet */
	if (sendto(sockfd, sendbuf, tx_len, 0, (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll)) < 0)
		perror("Send failed\n");

	return 0;
}

int packet_rx(int sockfd, uint8_t *buffer, int buffer_size)
{
	ssize_t numbytes;
	uint8_t buf[6 + 6 + 2 + BUF_SIZ];
	uint8_t *payload;
	
	/* Header structures */
	struct ether_header *eh = (struct ether_header *) buf;
	payload = buf + sizeof(struct ether_header);

repeat:	numbytes = recvfrom(sockfd, buf, 6 + 6 + 2 + BUF_SIZ, 0, NULL, NULL);
#if 0
	printf("listener: got packet %lu bytes\n", numbytes);
#endif

	/* Check the packet is from MAXI030 */
	if (!(eh->ether_shost[0] == MAXI030_MAC0 &&
		eh->ether_shost[1] == MAXI030_MAC1 &&
		eh->ether_shost[2] == MAXI030_MAC2 &&
		eh->ether_shost[3] == MAXI030_MAC3 &&
		eh->ether_shost[4] == MAXI030_MAC4 &&
		eh->ether_shost[5] == MAXI030_MAC5))
	{
		goto repeat;
	}

#if 0
	printf("Source MAC: %x:%x:%x:%x:%x:%x\n",
						eh->ether_shost[0],
						eh->ether_shost[1],
						eh->ether_shost[2],
						eh->ether_shost[3],
						eh->ether_shost[4],
						eh->ether_shost[5]);
	printf("Destination MAC: %x:%x:%x:%x:%x:%x\n",
						eh->ether_dhost[0],
						eh->ether_dhost[1],
						eh->ether_dhost[2],
						eh->ether_dhost[3],
						eh->ether_dhost[4],
						eh->ether_dhost[5]);
#endif

	for (int c = 0; c < numbytes && c < buffer_size; c++) {
		buffer[c] = payload[c];
	}
	return ((int) numbytes);
}
