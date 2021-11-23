		.include "include/hardware.i"
		.include "include/vectors.i"

		.section .text
		.align 2

		.global timerinit
		.global timeruninit
		.global timerticks
		.global vblticks

timerinit:	move.l #timerisr,VUSER128
		rts

timeruninit:	rts

timerisr:	addq.l #1,timerticks
		move.b #0,RTCINTCONTROL
		rte				| rte!

		.section .bss
		.align 2

timerticks:	.space 4

