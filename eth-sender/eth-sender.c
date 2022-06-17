#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdint.h>
#include <string.h>

#include <sys/stat.h>

#include <arpa/inet.h>

#include "linux-sender-protocol.h"

int init_raw_socket(char *interface_name);
int packet_tx(int sockfd, uint8_t *buffer, int buffer_size);
int packet_rx(int sockfd, uint8_t *buffer, int buffer_size);

int linux_server(int sockfd);
void usage(char *argv0);

int main(int argc, char *argv[])
{
	char *interface_name = "enp4s0";
	int c;
	
	while ((c = getopt(argc, argv, "hi:r:o:")) != -1)
	{
		switch(c)
		{
			case 'h':
				usage(argv[0]);
				break;
			case 'i':
				interface_name = optarg;
				break;
			default:
				abort();
		}
	}

	int sockfd = init_raw_socket(interface_name);
	if (!sockfd)
	{
		perror("Unable to open raw socket");
		exit(1);
	}

	while (1)
		linux_server(sockfd);
	
	close(sockfd);
	
	return (0);
}

#define BUFFER_SIZE 1024

int linux_server(int sockfd)
{
	struct request_block request_block;
	
	if (packet_rx(sockfd, (uint8_t *) &request_block, sizeof(struct request_block)) <= 0)
	{
		fprintf(stderr, "Receive of request_block failed\n");
		return 0;
	}
	
	printf("Filename requested: %s\n", request_block.filename);

	int filefd = open(request_block.filename, O_RDONLY);
	if (filefd < 0)
	{
		perror("Unable to open input file");
	}

	struct stat statbuf;
	off_t file_size = 0;
	if (filefd >= 0)
	{
		fstat(filefd, &statbuf);
		file_size = statbuf.st_size;
	}
	
	printf("File is %ld bytes\n", file_size);
	
	struct reply_block reply_block;
	reply_block.file_size = htonl((uint32_t) (file_size));

	packet_tx(sockfd, (uint8_t *) &reply_block, sizeof(struct reply_block));

	struct ack_block ack_block;

	packet_rx(sockfd, (uint8_t *) &ack_block, sizeof(struct ack_block));

	printf("Writing...\n");

	off_t bytessent = 0;
	unsigned char transmissionbuffer[BUFFER_SIZE];
	uint8_t checkbuffer[BUFFER_SIZE];
	int failed_frames = 0;
	
	while (bytessent < file_size)
	{
		int bytesread;

		memset(transmissionbuffer, 0, BUFFER_SIZE);
		if ((bytesread = read(filefd, transmissionbuffer, BUFFER_SIZE)) < 1)
		{
			fprintf(stderr, "Unable to read from input file (%d)", bytesread);
			return 1;
		}

failed_try_again:
		packet_tx(sockfd, transmissionbuffer, sizeof(transmissionbuffer));
		packet_rx(sockfd, checkbuffer, sizeof(checkbuffer));

		int failed = memcmp(transmissionbuffer, checkbuffer, sizeof(checkbuffer));
		
		ack_block.failed = htons(failed ? 1 : 0);
		packet_tx(sockfd, (uint8_t *) &ack_block, sizeof(struct ack_block));
		packet_rx(sockfd, (uint8_t *) &ack_block, sizeof(struct ack_block));

		if (failed)
		{
			failed_frames++;
			printf("!");
			fflush(stdout);
			
			int wrong_bytes;
			for (int c = 0; c < BUFFER_SIZE; c++) {
				if (transmissionbuffer[c] != checkbuffer[c]) {
					wrong_bytes++;
				}
			}
			printf(" [ %d wrong bytes ] ", wrong_bytes);
			
			goto failed_try_again;
		}

		bytessent += 1024;
		printf("#");
		fflush(stdout);
	}
	
	printf("\n=== Sent %ld bytes [ with %d retries ] ===\n", bytessent, failed_frames);
	
	if (filefd > -1)
		close(filefd);

	return 0;
}

void usage(char *argv0)
{
	fprintf(stderr, "Usage: %s [-i interface]\n" \
		"\tinterface defaults to enp4s0\n", argv0);
	exit(1);
}
