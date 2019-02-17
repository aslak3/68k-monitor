CC = gcc
CFLAGS = -Wall -O2

BINS = flasher

all: $(BINS)

flasher: flasher.o serialio.o
	$(CC) $(LDFLAGS) -o $@ $^

fileserver: fileserver.o serialio.o
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(BINS) *.o
