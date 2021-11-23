TOOLCHAIN = m68k-linux-gnu

AS = $(TOOLCHAIN)-as
LD = $(TOOLCHAIN)-ld
GCC = $(TOOLCHAIN)-gcc-10
LIBS = -L/usr/lib/gcc-cross/m68k-linux-gnu/10/ -lgcc
OBJCOPY = $(TOOLCHAIN)-objcopy
FLASHER = ./tools/flasher

BIN = monitor.bin
OBJS = main.o exceptions.o constants.o commands.o serial.o strings.o parser.o keyboard.o \
	ide.o misc.o i2c.o keyboard.o ticks.o memtest.o \
	ne2k.o printer.o mandlebrot.o draw.o \
	asm-wrapper.o mini-printf.o
all: $(BIN)

%.o: %.s
	$(AS) -mcpu=68020 -m68882 --fatal-warnings $< -o $@

%.o: %.c
#	$(GCC) -std=c99 -O0 -Iinclude -Wall -mcpu=68000 -c $< -o $@
	$(GCC) -std=c99 -O0 -mstrict-align -fomit-frame-pointer -ffreestanding  -Iinclude -Wall -mcpu=68020 -c $< -o $@

monitor.elf: $(OBJS)
	$(LD) -T linker.scr $^ $(LIBS) -o $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@.t
	dd if=$@.t of=$@ ibs=8192 obs=8192 conv=sync
	rm -f $@.t

flash:
	$(FLASHER) -s /dev/ttyS4 -f $(BIN)
	
clean:
	rm -f *.o *.elf *.bin
