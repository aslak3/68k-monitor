TOOLCHAIN = m68k-linux-gnu

AS = $(TOOLCHAIN)-as
LD = $(TOOLCHAIN)-ld
OBJCOPY = $(TOOLCHAIN)-objcopy
LIBS = -L/usr/lib/gcc-cross/m68k-linux-gnu/12/ -lgcc ../serial.o ../constants.o ../strings.o
ETH_SENDER = ../eth-sender/eth-sender

BIN = os-test.bin
OBJS = main.o memory.o lists.o debug.o tasks.o

all: $(BIN)

%.o: %.s
	$(AS) -mcpu=68030 -m68881 --fatal-warnings $< -o $@

os-test.elf: $(OBJS)
	$(LD) -T linker.scr $^ $(LIBS) -o $@

%.bin: %.elf
	$(OBJCOPY) --set-start 0x400 -O binary $< $@.t
	dd if=$@.t of=$@ ibs=8192 obs=8192 conv=sync
	rm -f $@.t

eth-sender:
	sudo $(ETH_SENDER)

clean:
	rm -f *.o *.elf *.bin
