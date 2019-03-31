		.include "include/hardware.i"

		.global exceptionsinit

		.section .vectors
		.align 2

evinitialsp:	.space 4
evinitialpc:	.space 4
evaccessfault:	.space 4
evaddresserr:	.space 4
evillegalinst:	.space 4

		.section .text
		.align 2

exceptionsinit:	move.l #accessfault,evaccessfault
		move.l #addresserr,evaddresserr
		move.l #illegalinst,evillegalinst
		rts

accessfault:	lea (accessfaultmsg,%pc),%a0
		bra 2f
addresserr:	lea (addresserrmsg,%pc),%a0
		bra 2f
illegalinst:	lea (illegalinstmsg,%pc),%a0
		bra 2f

2:		move.b #0xff,LED
		bsr putstr
9:		bra 9b

		.section .rodata
		.align 2

accessfaultmsg:	.asciz "\r\n*** Access fault exception, halt.\r\n"
addresserrmsg:	.asciz "\r\n*** Address error exception, halt.\r\n"
illegalinstmsg:	.asciz "\r\n*** Illegal instruction, halt.\r\n"
