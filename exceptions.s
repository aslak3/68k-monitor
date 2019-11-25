		.include "include/hardware.i"
		.include "include/vectors.i"

		.global exceptionsinit

		.section .vectors
		.align 2

vectortable:	.space 256*4

		.section .text
		.align 2

exceptionsinit:	move.l #buserror,VBUSERROR
		move.l #addresserr,VADDRESSERROR
		move.l #illegalinst,VILLEGALINSTRUCTION
		move.l #zerodivide,VZERODIVIDE
		rts

buserror:	lea (buserrormsg,%pc),%a0
		lea (8,%sp),%sp			| advance to sr/pc
		bra 2f
addresserr:	lea (addresserrmsg,%pc),%a0
		lea (8,%sp),%sp			| advance to sr/pc
		bra 2f
illegalinst:	lea (illegalinstmsg,%pc),%a0
		bra 2f
zerodivide:	lea (zerodividemsg,%pc),%a0
		bra 2f

2:		move.b #0xff,LED
		bsr putstr
		movea.l #buffer,%a0
		lea (srmsg,%pc),%a1
		bsr strconcat
		move.w 0(%sp),%d0
		bsr wordtoascii
		lea (spacesmsg,%pc),%a1
		bsr strconcat
		lea (pcmsg,%pc),%a1
		bsr strconcat
		move.l 2(%sp),%d0
		bsr longtoascii
		lea (newlinemsg,%pc),%a1
		bsr strconcat
		movea.l #buffer,%a0
		bsr putstr
9:		move.w #0xffff,%d0
		move.b #0,LED
10:		dbra %d0,10b
		move.w #0xffff,%d0
		move.b #0xff,LED
11:		dbra %d0,11b
		bra 9b

		.section .rodata
		.align 2

buserrormsg:	.asciz "\r\n*** Bus error, halt.\r\n"
addresserrmsg:	.asciz "\r\n*** Address error, halt.\r\n"
illegalinstmsg:	.asciz "\r\n*** Illegal instruction, halt.\r\n"
zerodividemsg:	.asciz "\r\n*** Divide by zero, halt.\r\n"
srmsg:		.asciz "SR: "
pcmsg:		.asciz "PC: "
spmsg:		.asciz "SP: "

		.section .bss
		.align 2

buffer:		.space 256
