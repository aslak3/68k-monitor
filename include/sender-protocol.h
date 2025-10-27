#pragma once

#include <stdint.h>

struct request_block
{
	char filename[256];
};

struct reply_block
{
	uint32_t file_size;
};

struct ack_block
{
	uint32_t failed;
};
