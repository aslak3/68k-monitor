		.align 2

		.include "include/hardware.i"

		.section .text

start:		bsr serialinit

		movea.l #buffer,%a1

		move.l #0x12345678,%d0
		movea.l %a1,%a0
		bsr longtoascii
		movea.l %a1,%a0
		bsr putstring
		lea (newlinemsg,%pc),%a0
		bsr putstring
		
		movea.l #number,%a0
		bsr asciitoint
		movea.l %a1,%a0
		bsr longtoascii
		movea.l %a1,%a0
		bsr putstring
		lea (newlinemsg,%pc),%a0
		bsr putstring
		movea.l %a1,%a0
		move.b %d1,%d0
		bsr bytetoascii
		movea.l %a1,%a0
		bsr putstring
		lea (newlinemsg,%pc),%a0
		bsr putstring


		


loop:		lea (whatsnamemsg,%pc),%a0	| grab the greeting in a0
		bsr putstring			| send it
		movea.l %a1,%a0
		bsr getstring
		lea (hellomsg,%pc),%a0
		bsr putstring
		movea.l %a1,%a0
		bsr putstring
		lea (exclmsg,%pc),%a0
		bsr putstring

		bra loop

		.section .rodata

whatsnamemsg:	.asciz "\r\nHello, what is your name? "
hellomsg:	.asciz "\r\nGreetings, "
exclmsg:	.asciz "!!!"
newlinemsg:	.asciz "\r\n"
number:		.asciz "CaBba6E5"

		.section .bss

buffer:		.space 256
