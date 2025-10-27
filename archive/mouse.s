		.include "include/hardware.i"
		.include "include/vectors.i"

		.section .text
		.align 2

		.global mouseinit

mouseinit:	move.l #mouseisr,VUSER129
		rts
