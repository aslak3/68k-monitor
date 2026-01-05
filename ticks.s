		.include "include/hardware.i"
		.include "include/vectors.i"

		.section .text
		.align 2

		.global timerinit
		.global timeruninit
		.global timerticks

timerinit:	move.l #timerisr,VL1AUTOVECTOR	| set timer interrupt vector
		clr.l timerticks		| clear tick count
		move.b #0x10,TIMERCOUNTU	| set timer count high byte
		move.b #0x00,TIMERCOUNTL	| set timer count low byte
		move.b #1,TIMERCONTROL		| enable timer but not interrupts yet
		rts

timeruninit:	rts				| does nothing for now

timerisr:	addq.l #1,timerticks
		move.b #1,TIMERCONTROL		| clear interrupt
		rte				| rte!

		.section .bss
		.align 2

timerticks:	.space 4
