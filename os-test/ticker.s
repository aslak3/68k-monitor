		.include "../include/hardware.i"
		.include "../include/vectors.i"

		.section .text
		.align 2

		.global tickerinit

tickerinit:	move.l #tickerhandler,VL1AUTOVECTOR
		move.b #0x10,TIMERCOUNTU
		move.b #0x01,TIMERCONTROL
		move.b #0x01,INTROUTES
		rts
