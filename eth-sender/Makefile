CC = gcc
CFLAGS = -Wall -O2 -I../include

BINS = eth-sender

all: $(BINS)

eth-sender: raw-socket.o eth-sender.o
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(BINS) *.o
