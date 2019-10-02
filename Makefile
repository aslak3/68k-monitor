AS = m68k-linux-gnu-as
LD = m68k-linux-gnu-ld
OBJCOPY = m68k-linux-gnu-objcopy
FLASHER = ./tools/flasher

BIN = monitor.bin
OBJS = main.o exceptions.o constants.o commands.o serial.o timer.o strings.o parser.o

all: $(BIN)

%.o: %.s include/hardware.i
	$(AS) -mcpu=68000 --fatal-warnings $< -o $@

monitor.elf: $(OBJS)
	$(LD) -T linker.scr -nostdlib $^ -o $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@.t
	dd if=$@.t of=$@ ibs=64 obs=64 conv=sync
	rm -f $@.t
	
flash:
	$(FLASHER) -s /dev/ttyS1 -f $(BIN)
	
clean:
	rm -f *.o *.elf *.bin

