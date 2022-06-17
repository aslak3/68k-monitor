This is my hack-about machine-code monitor for my 68k-based projects.
Currently this is running on my MAXI030 board, but it should be adaptable to
other 68k hardware.

Most of this is written in assembly, but a few parts are written in C:

* The ethernet "driver", which is mostly just there to fascilitate
  transfering a linux kernel.
* Drawing routines to exercise the Cyclone-2 video card
* A routine for sending data to a parallel printer

The GNU compiler is currently used. At some point I'll look at moving to
LLVM, now that it suports the 68K.

The meat of the momnitor is in the commands.s file. A macro system is used
to add commands to a datablock (checkcommand etc).

Unlike most decent monitors, it is not possible to run external code (unless
you count Linux!)

The data parser is quite clever (IMO) and supports byte, word and long
values. The command array describes the maximum length of input. Short
inputs will be zero-extened. eg:

```
checkcommand "writewords", 3, 2 + VARARG
```

So writewords takes two arguments, a long (3) and a word (2), which can
repeat. Thus, these is a valid input to the monitor:

```
writewords 12345678 1234 5678
writewords 1 2
```

Beside the basic data manipulation commands (dump, writelongs, readbyte etc)
the following is a selection of the commands that have been implemented:

* help - output a probably not current list of commands
* parsertest - output the input parameters along with their types
* diskidentify LONG1 - identify the IDE device attached and write the 512byte
  block to LONG1.
* diskread LONG1 WORD1 BYTE1 - read the LBA sector at WORD1, count BYTE1, into
  MPU memory starting at LONG1
* diskwrite LONG1 WORD1 BYTE 1 - you can guess what this does
* ledon/ledoff - control the attached LED
* showticks - show the uptime, assuming the timer input has been routed
* memcopy LONG1 WORD1 LONG2 - copy longs from LONG1 to LONG2, count WORD1.
this is quirky: dbra is used for the loop. this is a dumb copy.
showscancodes - enter a loop reading from the PS2 port, printing scancode
bytes.
* keyleds BYTE1 - send BYTE1 to the PS2 keyboard LEDs
* i2ctx BYTE1 LONG1 WORD1 - send the I2C byte stream at MPU memory LONG1 to
* I2C slave BYTE1, count WORD1
* i2crx BYTE1 LONG1 WORD1 - note that the address should not have the highbit
  set, as this is taken care of for you
* floattest LONG1 - does a very basic FPU calculation (square root of 2.0 as a
  double) and writes it into LONG1
* linuxdl - downloads the linux kernel over ethernet
* linuxrun "kernel command line" - boots linux with the given command line,
  after it has been downlaoded

See the main MAXI030 repo for information on running Linux.

This repo also contains a number of tools, and the bootloader.

The bootloader is trivial.  It occupies the first 8KB of the flash, waits a
couple of seconds for a command from the host machine via UART port B at
(currently) 38400 baud, and then starts the "real" ROM (which is usually
this monitor) if it obtains no command.

The protocol used is trivial enough that it can be descbired here:

- Host reads two lines (this is the bootloader sending the flash prompt on a
  clear line)
- Host sends f to start the flashing process, the 68k board will wait about
  two seconds for this
- Host sends the page (8KB) count for the image in a big-endian word
- For each page:
 - Host sends the page bytes back to back, which are written into temporary RAM
 - Target writes those to flash, including the needed delays (toggle-based
   chchecking been tried, but without success so far)
 - After each page has been commited, the target sends a hash char, which
   the host is waiting on
- At the end, the target sends the whole image back to the host so it can
  check it, though nothing is done about bad transfers
- At the end of the process, the new image is jumped too, just as if the
  board was restarted

In the tools directory is the host (Linux) end of the flashing process, and
a (unused) program for transfering blocks of data via Port B on the
UART inside the monitor.

The host (Linux) part of the Ethernet-based Linux kernel transfer process is
in the eth-sender directory.

Please see my blog for more information: https://www.aslak.net/
