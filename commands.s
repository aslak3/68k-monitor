		.include "include/macros.i"
		.include "include/ascii.i"
		.include "include/hardware.i"

		.global commandarray
		.global printbuffer

		.section .rodata
		.align 2

| command array consists of a command string link and some userdata for
| each named command. this userdata points to another record which consists
| of a subroutine reference (the handler) and a reference to a
| zero-terminated list of maximum data types.

commandarray:	nocheckcommand "reset"
		checkcommand "readbyte", 3
		checkcommand "readword", 3
		checkcommand "readlong", 3
		checkcommand "dump", 3, 3
		checkcommand "writebytes", 3, 1 + VARARG
		checkcommand "writewords", 3, 2 + VARARG
		checkcommand "writelongs", 3, 3 + VARARG
		nocheckcommand "parsertest"
		nocheckcommand "help"
		nocheckcommand "message"
		nocheckcommand "clear"
		nocheckcommand "demo"
		checkcommand "diskidentify", 3
		checkcommand "diskread", 3, 2, 1
		checkcommand "diskwrite", 3, 2, 1
		checkcommand "opl2regwrite", 1, 1
		checkcommand "opl2note", 1
		checkcommand "playvgm", 3
		nocheckcommand "showticks"
		endcommand		

		.section .text
		.align 2

| all commands: on entry a0 will be the type (word) array, and a1 will be the
| value (long) array.

reset:		reset
		rts

| read the byte, word or long at the first argument and display it.


readbyte:	movea.l (0,%a1),%a0		| get the first argument
		move.b (%a0),%d0		| get the byte at that addr
		movea.l #printbuffer,%a0	| set the output buffer
		bsr bytetoascii			| convert into a0
		bra readcommon			| add newline and print

readword:	movea.l (0,%a1),%a0		| get the first argument
		move.w (%a0),%d0		| get the word at that addr
		movea.l #printbuffer,%a0	| set the output buffer
		bsr wordtoascii			| convert into a0
		bra readcommon			| add newline and print

readlong:	movea.l (0,%a1),%a0		| get the first argument
		move.l (%a0),%d0		| get the long at that addr
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		bra readcommon			| add newline and print

readcommon:	lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr putstr			| and print it
		rts

| dump out (in words) from the first argument the length, the second
| argument (a byte count). the output includes the location, the hex,
| and the ascii, with unprintable chars showing as a dot. through this code:
|
| a0=the lilne buffer, a1=a string to concatenate, d0=coverted digits,
| d1=bytes left in total, d2=words or bytes left in this line,
| d3=up count of d2.

		.section .text
		.align 2

dump:		movea.l (0*4,%a1),%a2		| get the start addr (a2)
		move.l (1*4,%a1),%d1		| get the length (d1)
		and.l #0xfffffff0,%d1		| round length, whole lines

| print the address first.

1:		movea.l #printbuffer,%a0	| setup the print buffer

		move.l %a2,%d0			| we need to convert the ...
		bsr longtoascii			| ... current address

		move.b #ASC_SP,(%a0)+		| add a space
		move.b #ASC_SP,(%a0)+		| add another space

| now the 16 bytes, in groups of words

		move.w #8-1,%d2			| 8 words across
		clr.w %d3			| up counter of words
2:		move.w (%d3.w,%a2),%d0		| read the word
		bsr wordtoascii			| add it to the output
		move.b #ASC_SP,(%a0)+		| add a space
		cmp.w #4,%d2			| look for middle word
		bne 3f				| no extra space
		move.b #ASC_SP,(%a0)+		| add a extra space
3:		addq.w #2,%d3			| inc, in words, up counter
		dbra %d2,2b			| more words?

		move.b #ASC_SP,(%a0)+		| only need one space

| ascii display

		move.b #'[',(%a0)+		| add a bracket
		move.w #16-1,%d2		| 16 bytes (chars) to print
		clr.w %d3			| up counter of words
4:		move.b (%d3.w,%a2),%d0		| read the byte
		bsr makecharprint		| convert it to dot?
		move.b %d0,(%a0)+		| add it to the stream
		addq.w #1,%d3			| inc up counter
		dbra %d2,4b			| more ascii?
		move.b #']',(%a0)+		| close the brackets

| finish up and print the line

		lea.l (newlinemsg,%pc),%a1	| finish with ...
		bsr strconcat			| ... a new line

		movea.l #printbuffer,%a0	| now we can ...
		bsr putstr			| ... print this line!

		adda.l #0x10,%a2		| move to next chunk
		sub.l #0x10,%d1			| adjust the byte count
		bne 1b				| back for more lines

		rts

| writebytes, writewords and writelongs: write a list of values to memory

writeprelim:	movea.l %a1,%a2			| where to find what writing
		adda.l #4,%a2			| onto second arg
		movea.l (0,%a1),%a1		| where we are writing to
		adda.l #2,%a0			| move to second type
		rts

writebytes:	bsr writeprelim			| setup
1:		tst.w (%a0)+			| see if we are at end
		beq 2f				| yes? out
		move.b (3,%a2),(%a1)+		| write the byte
		adda.l #4,%a2			| move to next value
		bra 1b
2:		rts

writewords:	bsr writeprelim			| setup
1:		tst.w (%a0)+			| see if we are at end
		beq 2f				| yes? out
		move.w (2,%a2),(%a1)+		| write the byte
		adda.l #4,%a2			| move to next value
		bra 1b
2:		rts

writelongs:	bsr writeprelim			| setup
1:		tst.w (%a0)+			| see if we are at end
		beq 2f				| yes? out
		move.l (0,%a2),(%a1)+		| write the byte
		adda.l #4,%a2			| move to next value
		bra 1b
2:		rts

| test the parser: output the bytes, words and longs.

		.section .text
		.align 2

parsertest:	movea.l %a0,%a2			| arg type table into a2
1:		move.w (%a2)+,%d0		| get the current type
		beq 2f				| end of list?
		movea.l #printbuffer,%a0	| start of print buffer
		lea (typemsg,%pc),%a1		| add the type label
		bsr strconcat			| ...
		bsr wordtoascii			| convert d0 and append
		lea (spacesmsg,%pc),%a1		| add a space
		bsr strconcat			| ...

		lea (valuemsg,%pc),%a1		| value label
		bsr strconcat			| add it
		move.l (%a3)+,%d0		| get the value
		bsr longtoascii			| add the value to a0

		lea (newlinemsg,%pc),%a1	| end with a newline
		bsr strconcat			| append it

		movea.l #printbuffer,%a0	| wind a0 back to start
		bsr putstr			| and print it

		bra 1b

2:		rts

		.section .rodata
		.align 2

typemsg:        .asciz "Type: "
valuemsg:       .asciz "Value: "

| display help message.

		.section .text
		.align 2

help:		lea (helpmsg,%pc),%a0		| get the help message
		bsr putstr			| print it
		rts

		.section .rodata
		.align 2

helpmsg:	.ascii "Memory/IO:\r\n"
		.ascii "    readbyte addr.l : read byte at addr\r\n"
		.ascii "    readword addr.l : read word at addr\r\n"
		.ascii "    readlong addr.l : read long at addr\r\n"
		.ascii "    dump addr.l length.l : dump from addr, length bytes in ascii and hex\r\n"
		.ascii "    writebytes addr.l [value.b ...] : write bytes at addr\r\n"
		.ascii "    writewords addr.l [value.w ...] : write words at addr\r\n"
		.ascii "    writelongs addr.l [value.l ...] : write longs at addr\r\n"
		.ascii "Other:\r\n"
		.ascii "    parsertest [foo.l] [bar.w] [baz.b] ... : test the parser.\r\n"
		.ascii "    help : this help.\r\n"
		.asciz ""

		.section .text
		.align 2

message:	move.w #0,%d0
1:		movea.l #greets,%a0
2:		move.b (%a0)+,%d1
		beq 3f
		move.b %d1,0x300001
		bra 2b
3:		dbra %d0,1b
		rts

demo:		move.w #0,%d0
0:		move.w #0x0040,%d2
5:		move.w #0x0fff,%d1
4:		dbra %d1,4b
		dbra %d2,5b
		bsr movecursor
		move.b #ASC_SP,0x300001
1:		movea.l #demomsg,%a0
2:		move.b (%a0)+,%d1
		beq 3f
		move.b %d1,0x300001
		bra 2b
3:		addq.w #1,%d0
		cmp.w #80*60,%d0
		bne 0b
		bra demo
		rts

movecursor:	move.w %d0,-(%sp)
		move.b %d0,0x300007
		lsr.w #8,%d0
		move.b %d0,0x300005
		move.w (%sp)+,%d0
		rts

clear:		move.b #0,0x300003
		move.w #(80*60)-1,%d0
1:		move.b #0x20,0x300001
		dbra %d0,1b
		move.b #0,0x300003
		rts

		.section .rodata
		.align 2

greets:		.asciz "Hello from the 68HC000! Is anyone there?  "
demomsg:	.asciz "The Motorola 68000 ('sixty-eight-thousand'; also called the m68k or Motorola 68k, sixty-eight-kay) is a 16/32-bit CISC microprocessor, introduced in 1979 by Motorola Semiconductor Products Sector. The design implements a 32-bit instruction set, with 32-bit registers and a 32-bit internal data bus. The address bus is 24-bits and does not use memory segmentation, which made it popular with programmers. Internally, it uses a 16-bit data ALU and two additional 16-bit ALUs used mostly for addresses,[2] and has a 16-bit external data bus.[3] For this reason, Motorola referred to it as a 16/32-bit processor. As one of the first widely available processors with a 32-bit instruction set, and running at relatively high speeds for the era, the 68k was a popular design through the 1980s. It was widely used in a new generation of personal computers with graphical user interfaces, including the Apple Macintosh, Commodore Amiga, Atari ST and many others. It competed primarily against the Intel 8088, found in the IBM PC, which it easily outperformed. The 68k and 8088 pushed other designs, like the Zilog Z8000 and National Semiconductor 32016, into niche markets, and made Motorola a major player in the CPU space. The 68k was soon expanded with additional family members, implementing full 32-bit ALUs as part of the growing Motorola 68000 series. The original 68k is generally software forward-compatible with the rest of the line despite being limited to a 16-bit wide external bus.[2] After 40 years in production, the 68000 architecture is still in use."

		.section .text
		.align 2

diskidentify:	movea.l (0*4,%a1),%a0		| get address to write in
		bsr ideidentify			| do the identify command
		rts

diskread:	movea.l (0*4,%a1),%a0		| get address to write in
		move.l (1*4,%a1),%d1		| get the start sector
		move.l (2*4,%a1),%d0		| and the count
		bsr ideread			| do the read command
		rts

diskwrite:	movea.l (0*4,%a1),%a0		| get address to write in
		move.l (1*4,%a1),%d1		| get the start sector
		move.l (2*4,%a1),%d0		| and the count
		bsr idewrite			| do the write command
		rts

opl2regwrite:	move.b ((0*4)+3,%a1),%d1
		move.b ((1*4)+3,%a1),%d0
		bra opl2

.macro opl2macro address value
		move.b \address,%d1
		move.b \value,%d0
		bsr opl2
.endm

opl2note:	opl2macro #0x20,#0x21
		opl2macro #0x40,#0x10
		opl2macro #0x60,#0xf0
		opl2macro #0x80,#0x77
		opl2macro #0xa0,"((0*4)+3,%a1)"
		opl2macro #0x23,#0x01
		opl2macro #0x43,#0x00
		opl2macro #0x63,#0xf0
		opl2macro #0x93,#0x77
		opl2macro #0xb0,#0x31
		rts

opl2:		move.b %d1,OPL2REGADDR
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		move.b %d0,OPL2DATA
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		rts

playvgm:	movea.l (0*4,%a1),%a6
		bsr vgmplayer
		rts

showticks:	move.l timerticks,%d0
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr putstr			| and print it
		rts

		.section .rodata
		.align 2

testmsg:	.asciz "Hello from the 68681\r\n"

		.section .bss
		.align 2

| shared buffer used for printing.

printbuffer:	.space 256

