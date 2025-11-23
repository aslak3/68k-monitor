TOOLCHAIN = m68k-linux-gnu

AS = $(TOOLCHAIN)-as
LD = $(TOOLCHAIN)-ld
GCC = $(TOOLCHAIN)-gcc
LIBS = -L/usr/lib/gcc-cross/m68k-linux-gnu/12/ -lgcc
OBJCOPY = $(TOOLCHAIN)-objcopy
FLASHER = ./tools/flasher

BIN = monitor.bin
OBJS = main.o exceptions.o constants.o commands.o serial.o strings.o parser.o debug.o \
	misc.o ticks.o memtest.o disassembler.o \
	eth.o string.o ne2k.o asm-wrapper.o mini-printf.o

all: $(BIN)

%.o: %.s
	$(AS) -mcpu=68030 -m68881 --fatal-warnings $< -o $@

%.o: %.c
	$(GCC) -std=c99 -O2 -mstrict-align -fomit-frame-pointer -ffreestanding  -Iinclude -Wall -mcpu=68030 -m68881 -c $< -o $@
monitor.elf: $(OBJS)
	$(LD) -T linker.scr $^ $(LIBS) -o $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@.t
	dd if=$@.t of=$@ ibs=8192 obs=8192 conv=sync
	rm -f $@.t

flash:
	$(FLASHER) -s /dev/ttyS2 -f $(BIN)
	
clean:
	rm -f *.o *.elf *.bin
