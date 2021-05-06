		.include "include/hardware.i"
		.include "include/vectors.i"

		.section .text
		.align 2

		.global timerinit
		.global timeruninit
		.global timerticks
		.global vblticks

timerinit:	move.l #timerisr,VUSER128
		move.l #vblisr,VUSER130
		move.w #5*8000,TIMERCOUNT
		rts

timeruninit:	rts

timerisr:	move.w #0,TIMERCOUNT		| clear timer, restart
		addq.l #1,timerticks
		rte				| rte!

vblisr:		move.w %d0,-(%sp)
		move.w TIMERCOUNT,%d0		| clear timer, restart
		addq.l #1,vblticks
		move.w (%sp)+,%d0
		rte				| rte!

		.section .bss
		.align 2

timerticks:	.space 4
vblticks:	.space 4
