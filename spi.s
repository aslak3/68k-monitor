
		.include "include/hardware.i"

		.section .text
		.align 2

		.global sendspibyte

| send the word in d0.w with the slave selected

| enable, clock, data

sendspibyte:	move.b %d0,SPIDATA		| output
		nop
		nop
		move.b SPIDATA,%d0

		rts
