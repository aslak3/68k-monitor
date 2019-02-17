		.align	2

		.equ LED, 0x100001
		.equ BUZZER, 0x100003

		.section .text

_start:		move.b #0xff,%d0
		move.b #1,delaycount		| setup delay loop count

next:		move.b %d0,LED			| switch the LED on or off

		bsr delay			| do the delay sub

		add.b #1,delaycount		| inc the delaycount
		and.b #0x3f,delaycount		| truncate it to 0-63

		not.b %d0			| flip

		bra next			| to the top!

delay:		move.w #0,%d2			| clear top byte
		move.b delaycount,%d2		| get loop counter

outterdelay:	move.w #0x8000,%d1		| setup delay
innerdelay:	dbra %d1,innerdelay		| loop on the spot
		dbra %d2,outterdelay

		rts

		.section .bss

delaycount:	.space 1			| delay variable
