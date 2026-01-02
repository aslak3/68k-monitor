
		.include "include/macros.i"
		.include "include/system.i"
		.include "include/ascii.i"
		.include "include/hardware.i"

		.section .rodata
		.align 2

		.global commandarray

| command array consists of a command string link and some userdata for
| each named command. this userdata points to another record which consists
| of a subroutine reference (the handler) and a reference to a
| zero-terminated list of maximum data types.

commandarray:	checkcommand "readbyte", 3
		checkcommand "readword", 3
		checkcommand "readlong", 3
		checkcommand "dump", 3, 3
		checkcommand "writebytes", 3, 1 + VARARG
		checkcommand "writewords", 3, 2 + VARARG
		checkcommand "writelongs", 3, 3 + VARARG
		nocheckcommand "parsertest"
		nocheckcommand "help"
		nocheckcommand "showticks"
		checkcommand "checksum", 3, 2
		checkcommand "memclear", 3, 2
		checkcommand "memcopy", 3, 2, 3
		checkcommand "patternfillw" 3, 2
		checkcommand "patternfillb" 3, 2
		checkcommand "memfill", 3, 2, 2
		nocheckcommand "memtest"
		checkcommand "ethdl", 0x80, 3
		checkcommand "hextobytes" 0x800, 3
		nocheckcommand "resume"
		checkcommand "runat", 3
		nocheckcommand "printregs"
		checkcommand "setdreg", 1, 3
		checkcommand "setareg", 1, 3
		checkcommand "disass", 3, 2
		checkcommand "listbps", 0
		checkcommand "addbp", 3, 2
		checkcommand "delbp", 2

		endcommand 0x400		| table in ram?

		.section .text
		.align 2

| all commands: on entry a0 will be the type (word) array, and a1 will be the
| value (long) array.

| read the byte, word or long at the first argument and display it.

readbyte:	movea.l (0,%a1),%a0		| get the first argument
		move.b (%a0),%d0		| get the byte at that addr
		bsr serputbyte			| convert to byte and print
		bra readcommon			| add newline

readword:  	movea.l (0,%a1),%a0      	| get the first argument
		move.w (%a0),%d0         	| get the word at that addr
		bsr serputword           	| convert to word and print
		bra readcommon           	| add newline

readlong:	movea.l (0,%a1),%a0		| get the first argument
		move.l (%a0),%d0		| get the long at that addr
		bsr serputlong			| convert to long and print
		bra readcommon			| add newline and print

readcommon:	lea (newlinemsg,%pc),%a0	| need a newline
		bsr serputstr			| output it
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

		.global printregs

dump:		movea.l (0*4,%a1),%a2		| get the start addr (a2)
		move.l (1*4,%a1),%d1		| get the length (d1)
		and.l #0xfffffff0,%d1		| round length, whole lines

| print the address first.

1:		move.l %a2,%d0			| we need to convert the ...
		bsr serputlong			| ... current address

		move.b #ASC_SP,%d0		| we need to add some spaces
		bsr serputchar			| add one
		bsr serputchar			| and another

| now the 16 bytes, in groups of words

		move.w #8-1,%d2			| 8 words across
		clr.w %d3			| up counter of words
2:		move.w (%d3.w,%a2),%d0		| read the word
		bsr serputword			| add it to the output
		move.b #ASC_SP,%d0		| add a space
		bsr serputchar			| and print it
		cmp.w #4,%d2			| look for middle word
		bne 3f				| no extra space
		move.b #ASC_SP,%d0		| add a space
		bsr serputchar			| and print it
3:		addq.w #2,%d3			| inc, in words, up counter
		dbra %d2,2b			| more words?

		move.b #ASC_SP,%d0		| add a space
		bsr serputchar			| and print it

| ascii display

		move.b #'[',%d0			| add a bracket
		bsr serputchar			| print
		move.w #16-1,%d2		| 16 bytes (chars) to print
		clr.w %d3			| up counter of words
4:		move.b (%d3.w,%a2),%d0		| read the byte
		bsr makecharprint		| convert it to dot?
		bsr serputchar			| print it out
		addq.w #1,%d3			| inc up counter
		dbra %d2,4b			| more ascii?
		move.b #']',%d0			| close the brackets
		bsr serputchar			| and print it

| finish up and print the line

		lea.l (newlinemsg,%pc),%a0	| finish with ...
		bsr serputstr			| ... a new line

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
		lea (typemsg,%pc),%a0		| add the type label
		bsr serputstr			| ...
		bsr serputword			| convert d0 and append
		move.b #ASC_SP,%d0		| add a space
		bsr serputchar			| and print it
		lea (valuemsg,%pc),%a0		| value label
		bsr strconcat			| add it
		move.l (%a3)+,%d0		| get the value
		bsr serputlong			| add the value to a0

		lea (newlinemsg,%pc),%a0	| end with a newline
		bsr serputstr			| append it

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
		bsr serputstr			| print it
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
		.ascii "    memcopy fromaddr.l length.w toaddr.l : copy memory\r\n"
		.ascii "    memclear addr.l length.w : clear memory\r\n"
		.ascii "    memfill addr.l length.w val.w : fill with val fixed word\r\n"
		.ascii "    memtest : test memory\r\n"
		.ascii "    patternfillw addr.l length.w : fill with length words\r\n"
		.ascii "    patternfillb addr.l length.w : fill with length bytes\r\n"
		.ascii "    checksum addr.l count.w : checksum memory, count in longs\r\n"
		.ascii "Registess and execution:\r\n"
		.ascii "    printregs : display all registers\r\n"
		.ascii "    setdreg regnum.b val.l : set data register\r\n"
		.ascii "    setareg regnum.b val.l : set address register\r\n"
		.ascii "    runat addr.l : resume execution at addr until trap #0\r\n"
		.ascii "    disass addr.l count.w : disassemble count instructions from addr\r\n"
		.ascii "Breakpoints:\r\n"
		.ascii "    listbps : list all breakpoints\r\n"
		.ascii "    addbp addr.l index.w : add breakpoint at addr at index (0-7)\r\n"
		.ascii "    delbp index.w : delete breakpoint at index (0-7)\r\n"
		.ascii "    resume : resume execution at breakpointed instruction\r\n"
		.ascii "Other:\r\n"
		.ascii "    parsertest [foo.l] [bar.w] [baz.b] ... : test the parser\r\n"
		.ascii "    testtransmit : test the ethernet by sending a packet\r\n"
		.ascii "    ethdl filename.s addr.l : download the file over ethernet\r\n"
		.ascii "    hextobytes addr.l : convert hex string to bytes\r\n"
		.ascii "    showticks : show the tick count in 1/44100 seconds\r\n"
		.ascii "    help : this help.\r\n"
		.asciz ""

		.section .text
		.align 2

ethdl:		move.l (1*4,%a1),-(%sp)
		move.l (0*4,%a1),-(%sp)
		bsr eth_download
		lea 8(%sp),%sp
		rts

hextobytes:	move.l (0*4,%a1),%a0
		move.l (1*4,%a1),%a1
		bsr bytesfromascii
		beq generror			| will rts
		rts

testtransmit:	bsr ne2k_setup
		bsr test_transmit
		rts

showticks:	move.l timerticks,%d0
		bsr serputlong			| convert into a0
		lea (newlinemsg,%pc),%a0	| need a newline
		bsr serputstr			| and print it
		rts


memcopy:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
		movea.l (2*4,%a1),%a1		| get the detstination
1:		move.l (%a0)+,(%a1)+		| copy the long
		dbra %d1,1b			| more?
		rts

patternfillw:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
1:		move.w %d1,(%a0)+		| write the counter
		dbra %d1,1b
		rts

patternfillb:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
1:		move.b %d1,(%a0)+		| write the counter
		dbra %d1,1b
		rts

memfill:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		move.w (2*4+2,%a1),%d0		| get the word to fill with
		subq.w #1,%d1			| used in dbra
1:		move.w %d0,(%a0)+		| write the counter
		dbra %d1,1b
		rts

memclear:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
1:		clr.b (%a0)+			| clear the byte
		dbra %d1,1b			| back for more
		rts

checksum:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
		clr.l %d0			| clear sum
1:		add.l (%a0)+,%d0		| sum it
		dbra %d1,1b			| back for more
		bsr serputlong			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr serputstr			| and print it
		rts

printregs:	movea.l #savedregisters,%a1	| get regs
		clr.w %d1			| count of reg from 0
		movea.l #d0msg,%a2		| a0 reg
1:		move.l %a2,%a0			| restore label address
		bsr serputstr			| print the label
		adda.l #5,%a2			| move to next label "A0: \0"
		move.l (%a1)+,%d0		| get a register
		bsr serputlong			| output it into a0
		move.b #ASC_SP,%d0		| add a space
		bsr serputchar			| and print it
		addq.w #1,%d1			| add one to reg
		move %d1,%d0			| copy the reg count
		andi.w #0x3,%d0			| check for gap after /4 reg
		bne 2f				| no gap
		movea.l #newlinemsg,%a0		| need a gap
		bsr serputstr			| print the gap
2:		cmp.w #REG_COUNT,%d1		| looking for the last reg
		bne 1b				| back to the next reg
		rts

setdreg:	movea.l #savedregisters+(0*4),%a0
						| get d registers
		bra setreg

setareg:	movea.l #savedregisters+(8*4),%a0
						| get a registers
		bra setreg


setreg:		move.l (0*4,%a1),%d0		| get the register number
		cmp.b #8,%d0			| compare with 8
		bge generror			| oopsy
		lsl.l #2,%d0			| make it a long offset
		move.l (1*4,%a1),%d1		| get the value
		move.l %d1,(%a0,%d0)		| set the register
		rts

disass:		move.l (0*4,%a1),%a0		| get address to disassemble
		move.w (1*4+2,%a1),%d0		| get the length
		bsr disassemble			| disassemble it
		rts

listbps:	bsr listbreakpoints
		rts

addbp:		move.l (0*4,%a1),%a0		| get address
		move.w (1*4+2,%a1),%d0		| get index
		bsr addbreakpoint
		rts

delbp:		move.w (0*4+2,%a1),%d0		| get index
		bsr delbreakpoint
		rts

| resume execution after a breakpoint trap, by repeating the instruction at the trap that
| took us into the monitor
resume:		lea (exitmsg,%pc),%a0		| exiting monitor message
		bsr serputstr			| output it
		move.l resumepc,%d0		| get the resume pc
		bsr serputlong			| output it
		lea (newlinemsg,%pc),%a0	| newline after each
		bsr serputstr			| output it

		bsr settraps			| set any breakpoints, exept the resume pc
		movem.l savedregisters,%d0-%d7/%a0-%a7
						| restore all registers
		move.l resumepc,(2,%sp)		| resuming at instruction at old trap
		rte

runat:		move.l (0*4,%a1),resumepc	| save address to resume at
		bra resume

| branch target for showing a generic error message

generror:	lea (generrormsg,%pc),%a0
		bsr serputstr
		rts

		.section .rodata
		.align 2

entercmdmsg:	.asciz "Monitor: > "
exitmsg:	.asciz "*** Exiting monitor via RTE new PC: "
filesizemsg:	.asciz "File size: "

generrormsg:	.asciz "Command returned an error\r\n"

d0msg:		.asciz "D0: "
d1msg:		.asciz "D1: "
d2msg:		.asciz "D2: "
d3msg:		.asciz "D3: "
d4msg:		.asciz "D4: "
d5msg:		.asciz "D5: "
d6msg:		.asciz "D6: "
d7msg:		.asciz "D7: "

a0msg:		.asciz "A0: "
a1msg:		.asciz "A1: "
a2msg:		.asciz "A2: "
a3msg:		.asciz "A3: "
a4msg:		.asciz "A4: "
a5msg:		.asciz "A5: "
a6msg:		.asciz "A6: "
a7msg:		.asciz "A7: "
