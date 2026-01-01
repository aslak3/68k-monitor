		.include "../include/macros.i"
		.include "../include/system.i"
		.include "include/system.i"

		.section .text
		.align 2

		.global testbps

testbps:	movea.l #portadevice,%a5	| point a5 to port a device

		move.w #10,%d0		| test address
1:		bsr serputword		| print it
		movea.l #newlinemsg,%a0	| print newline
		bsr serputstr		| output it
		dbra %d0,1b		| loop for more
1:		trap #0			| enter monitor
		bra 1b
