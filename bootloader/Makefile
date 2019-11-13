AS = m68k-linux-gnu-as
LD = m68k-linux-gnu-ld
OBJCOPY = m68k-linux-gnu-objcopy
UPLOAD = minipro

SINGLEBINS = bootloader
UPPERBINS = $(addsuffix -upper.bin, $(basename $(SINGLEBINS)))
LOWERBINS = $(addsuffix -lower.bin, $(basename $(SINGLEBINS)))

BINS = $(UPPERBINS) $(LOWERBINS)

all: $(BINS)

%.o: %.s
	$(AS) $< -o $@

%.elf: %.o
	$(LD) -T linker.scr -nostdlib $< -o $@

%.bin: %.elf
	$(OBJCOPY) --pad-to 0xf10000 -O binary $< $@

%-upper.bin: %.bin
	$(OBJCOPY) --interleave=2 --byte=0 -I binary -O binary $< $@
%-lower.bin: %.bin
	$(OBJCOPY) --interleave=2 --byte=1 -I binary -O binary $< $@

upload:
	$(UPLOAD) -p AT28C256 -w $(BIN) -P
	
clean:
	rm -f *.o *.elf *.bin
