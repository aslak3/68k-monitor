		.include "include/hardware.i"
		.include "include/macros.i"

		.global commandarray

		.section .rodata
		.align 2

| command array consists of a command string link and some userdata for
| each named command. this userdata is a subroutine reference (the
| handler) and a reference to a zero-terminated list of maximum data types.

commandarray:	checkcommand "readbyte", 3, 0
		checkcommand "readword", 3, 0
		checkcommand "readlong", 3, 0
		nocheckcommand "parsertest"
		nocheckcommand "help"
		endcommand		

| all commands: on entry a0 will be the type (word) array, and a1 will be the
| value (long) array.

| read the byte, word or long  at the first argument and display it.

		.section .text
		.align 2

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
		move.l (%a0),%d0		| get the byte at that addr
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		bra readcommon			| add newline and print

readcommon:	lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr putstr			| and print it
		rts


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
		.ascii "    readbyte LLLLLLLL : read byte at LLLLLL\r\n"
		.ascii "    readword LLLLLLLL : read word at LLLLLL\r\n"
		.ascii "    readlong LLLLLLLL : read long at LLLLLL\r\n"
		.ascii "\r\n"
		.ascii "Other:\r\n"
		.ascii "    parsertest [BB] [WWWW] [LLLLLLLL] ... : test the parser.\r\n"
		.ascii "    help : this help.\r\n"
		.asciz ""


		.section .bss
		.align 2

| shared buffer used for printing.

printbuffer:	.space 256
