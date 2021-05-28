AS = m68k-linux-gnu-as
LD = m68k-linux-gnu-ld
OBJCOPY = m68k-linux-gnu-objcopy
UPLOAD = minipro

SINGLEBINS = bootloader
UPPERBINS = $(addsuffix -upper.bin, $(basename $(SINGLEBINS)))
LOWERBINS = $(addsuffix -lower.bin, $(basename $(SINGLEBINS)))

BINS = bootloader.bin $(UPPERBINS) $(LOWERBINS)

BOARD = MIDI020

ifeq ($(BOARD), MINI000)
TARGET = AT28C256
PAD = 0xf10000
else ifeq ($(BOARD), MAXI000)
TARGET = SST39SF040@PLCC32
PAD = 0x1000000
else ifeq ($(BOARD), MIDI020)
TARGET = SST39SF040@PLCC32
PAD = 0xff100000
endif

all: $(BINS)

%.o: %.s
	$(AS) $< -o $@

%.elf: %.o
	$(LD) -T linker.scr -nostdlib $< -o $@

%.bin: %.elf
	$(OBJCOPY) --pad-to $(PAD) -O binary $< $@

%-upper.bin: %.bin
	$(OBJCOPY) --interleave=2 --byte=0 -I binary -O binary $< $@
%-lower.bin: %.bin
	$(OBJCOPY) --interleave=2 --byte=1 -I binary -O binary $< $@

upload:
	$(UPLOAD) -p $(TARGET) -w $(BIN) -P
download:
	$(UPLOAD) -p $(TARGET) -r $(BIN) -P
	
clean:
	rm -f *.o *.elf *.bin
