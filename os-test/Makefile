TOOLCHAIN = m68k-linux-gnu

AS = $(TOOLCHAIN)-as
GCC = $(TOOLCHAIN)-gcc
LD = $(TOOLCHAIN)-ld
OBJCOPY = $(TOOLCHAIN)-objcopy
LIBS = ../serial.o ../constants.o ../strings.o ../debug.o
ETH_SENDER = ../eth-sender/eth-sender

BIN = os-test.bin
OBJS = main.o memory.o lists.o dumper.o tasks.o ticker.o debugger.o disassembler.o \
	disasstest.o

all: $(BIN)

%.o: %.s include/*.i
	$(AS) -mcpu=68030 -m68881 -fatal-warnings -c $< -o $@
%.o: %.S include/*.i
	$(GCC) -mcpu=68030 -m68881 -Xfatal-warnings -c $< -o $@
disasstest.o: disasstest.s
	$(AS) -mcpu=68000 --fatal-warnings $< -o $@

os-test.elf: $(OBJS)
	$(LD) -Map=os-test.map -T linker.scr $^ $(LIBS) -o $@

%.bin: %.elf
	$(OBJCOPY) --set-start 0x400 -O binary $< $@.t
	dd if=$@.t of=$@ ibs=8192 obs=8192 conv=sync
	rm -f $@.t

eth-sender:
	sudo $(ETH_SENDER)

clean:
	rm -f *.o *.elf *.bin
