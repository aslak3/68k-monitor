		.include "include/hardware.i"
		.include "include/vectors.i"

		.section .text
		.align 2

		.global timerinit

timerinit:	move.b #0b01110000,XR88C681ACR	| tick on 3.684Mhz crystal/ 16
		move.b #0b00001000,XR88C681IMR	| mask in the timer overflow
		move.b #0x11,XR88C681CTU	| ..
		move.b #0xfd,XR88C681CTL	| 4605 decimal - 25/sec
		move.b XR88C681STARTCOM,%d0	| update the timer overflow

		move.l #timerisr,VL7AUTOVECTOR

		rts

timerisr:	movem.l %d0,-(%sp)
		move.b XR88C681STOPCOM,%d0	| clear interrupt
		addq.l #1,timerticks		| inc counter
		movem.l (%sp)+,%d0
		rtr

		.section bss
		.align 2

timerticks:	.space 4
