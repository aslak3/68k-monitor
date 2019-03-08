		.align 2

		.include "include/hardware.i"

		.section .text

start:		bsr serialinit

		movea.l #buffer,%a1

loop:		lea (enternumbermsg,%pc),%a0	| grab the greeting in a0
		bsr putstring			| send it
		movea.l %a1,%a0
		bsr getstring
		lea (newlinemsg,%pc),%a0
		bsr putstring
		movea.l %a1,%a0
		bsr asciitoint
		lea (hexmsg,%pc),%a0
		bsr putstring
		movea.l %a1,%a0
		bsr longtoascii
		tst.b %d1
		beq error
		movea.l %a1,%a0
		bsr putstring
		lea (newlinemsg,%pc),%a0
		bsr putstring
		lea (typemsg,%pc),%a0
		bsr putstring
		move.b %d1,%d0
		movea.l %a1,%a0
		bsr bytetoascii
		movea.l %a1,%a0
		bsr putstring
		lea (newlinemsg,%pc),%a0
		bsr putstring
		bra loop
error:		lea (errormsg,%pc),%a0
		bsr putstring
		bra loop

		.section .rodata

enternumbermsg:	.asciz "\r\nEnter a number: "
hexmsg:		.asciz "Hex: "
typemsg:	.asciz "Type: "
errormsg:	.asciz "Error!\r\n"
newlinemsg:	.asciz "\r\n"

		.section .bss

buffer:		.space 256
