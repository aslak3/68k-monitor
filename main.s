		.align 2

		.include "include/hardware.i"

		.section .text

start:		bsr serialinit

loop:		lea (newlinemsg,%pc),%a0
		bsr putstring

		lea (entercmdmsg,%pc),%a0	| grab the greeting in a0
		bsr putstring			| send it
		movea.l #inputbuffer,%a0
		bsr getstring
		lea (newlinemsg,%pc),%a0
		bsr putstring
		movea.l #inputbuffer,%a0
		movea.l #cmdbuffer,%a1
		movea.l #argbuffer,%a2
		bsr parser
		beq error
		lea (cmdmsg,%pc),%a0
		bsr putstring
		movea.l #cmdbuffer,%a0
		bsr putstring
		lea (newlinemsg,%pc),%a0
		bsr putstring

argloop:	move.w (%a2)+,%d0
		beq loop
		lea (typemsg,%pc),%a0
		bsr putstring
		movea.l #printbuffer,%a0
		bsr wordtoascii
		movea.l #printbuffer,%a0
		bsr putstring
		lea (spacesmsg,%pc),%a0
		bsr putstring

		lea (valuemsg,%pc),%a0
		bsr putstring
		move.l (%a2)+,%d0
		movea.l #printbuffer,%a0
		bsr longtoascii
		movea.l #printbuffer,%a0
		bsr putstring

		lea (newlinemsg,%pc),%a0
		bsr putstring
		bra argloop

error:		lea (errormsg,%pc),%a0
		bsr putstring
		bra loop

		.section .rodata

entercmdmsg:	.asciz "Enter a comamnd string: "
cmdmsg:		.asciz "Command: "
typemsg:	.asciz "Type: "
valuemsg:	.asciz "Value: "
errormsg:	.asciz "Error!\r\n"
newlinemsg:	.asciz "\r\n"
spacesmsg:	.asciz "  "

		.section .bss

inputbuffer:	.space 256
cmdbuffer:	.space 256
argbuffer:	.space 256
printbuffer:	.space 256
