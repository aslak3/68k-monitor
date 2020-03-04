		.align 2

		.include "include/hardware.i"

		.section .text

		.global sendspiword
		.global sendspibyte

| send the word in d0.w with the slave selected

| enable, clock, data

sendspiword:	move.b #0,SPISELECT		| enable low

		ror.w #8,%d0			| swap to move hi to lo
		move.b %d0,SPIOUT		| output high
		ror.w #8,%d0			| swap
		move.b %d0,SPIOUT		| output low

		move.b #1,SPISELECT		| enable high

		rts

sendspibyte:	move.b #0,SPISELECT		| enable low

		move.b %d0,SPIOUT		| output

		move.b #1,SPISELECT		| enable high

		rts
