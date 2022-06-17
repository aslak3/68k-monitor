#include <stdint.h>
#include <stddef.h>

char *strcpy(char *dst, const char *src)
{
	char *d;
	const char *s;

	for (s = src, d = dst; *s;)
		*d++ = *s++;
	*d++ = '\0';
	return dst;
}

void *memcpy(void *dest, const void *src, size_t n)
{
	size_t m = n;
	const uint8_t *s;
	uint8_t *d;

	for (s = src, d = dest; m > 0; s++, d++)
	{
		m--;
		*d = *s;
	}
	return dest;
}

size_t strlen(const char *str)
{
	size_t n = 0;
	char *s = (char *) str;
	while (*s++) n++;
	
	return n;
}

void *memset(void *s, int c, size_t n)
{
	uint8_t *t;
	size_t m = n;
	
	for (t = s; m > 0; t++)
	{
		m--;
		*t = (uint8_t) c;
	}
	return s;
}
