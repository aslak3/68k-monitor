		.align 2

		.include "include/hardware.i"
		.include "include/macros.i"

		.section .text

start:		bsr serialinit

mainloop:	lea (newlinemsg,%pc),%a0
		bsr putstr

		lea (entercmdmsg,%pc),%a0	| grab the greeting in a0
		bsr putstr			| send it
		movea.l #inputbuffer,%a0
		bsr getstr
		lea (newlinemsg,%pc),%a0
		bsr putstr

		movea.l #inputbuffer,%a0
		movea.l #cmdbuffer,%a1
		movea.l #typebuffer,%a2
		movea.l #valuebuffer,%a3
		bsr parser
		beq error
		movea.l #commandarray,%a0	| setup command array in a0
		bsr strmatcharray		| match against cmd in a1
		beq nocommand			| no command
		move.l %d0,%a0			| jsr needs addr in addrreg
		jsr (%a0)			| run the sub found
		bra mainloop

error:		lea (errormsg,%pc),%a0
		bsr putstr
		bra mainloop

nocommand:	lea (nocommandmsg,%pc),%a0
		bsr putstr
		bra mainloop

parsertest:	move.w (%a2)+,%d0
		beq endargs
		lea (typemsg,%pc),%a0
		bsr putstr
		movea.l #printbuffer,%a0
		bsr wordtoascii
		movea.l #printbuffer,%a0
		bsr putstr
		lea (spacesmsg,%pc),%a0
		bsr putstr

		lea (valuemsg,%pc),%a0
		bsr putstr
		move.l (%a3)+,%d0
		movea.l #printbuffer,%a0
		bsr longtoascii
		movea.l #printbuffer,%a0
		bsr putstr

		lea (newlinemsg,%pc),%a0
		bsr putstr

		bra parsertest

endargs:	rts

help:		lea (helpmsg,%pc),%a0
		bsr putstr
		rts

		.section .rodata

entercmdmsg:	.asciz "> "

typemsg:	.asciz "Type: "
valuemsg:	.asciz "Value: "

errormsg:	.asciz "Error!\r\n"
nocommandmsg:	.asciz "No such command\r\n"

helpmsg:	.ascii "Other:\r\n"
		.ascii "    parsertest [BB] [WWWW] [LLLLLLLL] : test the parser.\r\n"
		.ascii "    help : this help.\r\n"
		.asciz ""


newlinemsg:	.asciz "\r\n"
spacesmsg:	.asciz "  "

		.align 2			| longs need aligning

commandarray:	insertcommand "parsertest"
		insertcommand "help"
		endcommand		

		.section .bss

inputbuffer:	.space 256
cmdbuffer:	.space 256
typebuffer:	.space 256
valuebuffer:	.space 256
printbuffer:	.space 256
