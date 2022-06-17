		.include "include/hardware.i"
		.include "include/vectors.i"

		.section .text
		.align 2

		.global timerinit
		.global timeruninit
		.global timerticks

timerinit:	move.l #timerisr,VL1AUTOVECTOR
		clr.l timerticks
		move.b #0x10,TIMERCOUNTU
		move.b #1,TIMERCONTROL
		rts

timeruninit:	rts

timerisr:	move.m %d0,-(%sp)
		addq.l #1,timerticks
		move.b #1,TIMERCONTROL		| clear interrupt
		move.m (%sp)+,%d0

		rte				| rte!

		.section .bss
		.align 2

timerticks:	.space 4

