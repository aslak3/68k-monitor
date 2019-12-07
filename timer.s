		.include "include/hardware.i"
		.include "include/vectors.i"

		.section .text
		.align 2

		.global timerinit
		.global timerticks

timerinit:	move.b #0b01100000,XR88C681ACR	| tick on 3.684Mhz crystal/16
		move.b #0b00001000,XR88C681IMR	| mask in the timer overflow
		move.b #0,XR88C681CTU		| ..
		move.b #42,XR88C681CTL		| 44.1Khz approx
		clr timerticks			| 0 the global ticker countr
		move.l #timerisr,VL7AUTOVECTOR	| setup the isr vector
		move.b XR88C681STARTCOM,%d0	| update the timer overflow
		rts

timerisr:	addq.l #1,timerticks		| inc counter
		bsr opl2noteplay		| do the vgm handler
		tst.b XR88C681STOPCOM		| clear interrupt
		rte				| rte!

		.section .bss
		.align 2

timerticks:	.space 4
