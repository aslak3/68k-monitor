		.align 2

		.equ LATCH, 0x100001

		.section .text

_start:		move.w #0xdf00,delay		| start with a long delay
		movea.l #ledstart,%a0		| get start address
		move.w #ledend-ledstart-1,%d0	| set the length
		movea.l #ramstart,%a1

1:		move.b (%a0)+,(%a1)+		| copy a byte from a0 to a1
		dbra %d0,1b			| more, down to -1

mainloop:	movea.l #ramstart,%a0		| get the ram copy
		move.w #ledend-ledstart-1,%d0	| set the length

next:		move.b (%a0),LATCH		| move byte to LATCH
		not.b (%a0)+			| flip it on each run

		bsr dodelay

		dbra %d0,next			| back for more

		sub.w #0x2000,delay		| shorter delay next time
		bra mainloop			| to the top!

dodelay:	move.w delay,%d1		| setup delay
1:		nop
		nop
		nop
		nop
		dbra %d1,1b			| hop on the spot

		rts

		.section .rodata

ledstart:	.byte 0b00000001
		.byte 0b00000010
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00100000
		.byte 0b01000000
		.byte 0b10000000
		.byte 0b01000000
		.byte 0b00100000
		.byte 0b00010000
		.byte 0b00001000
		.byte 0b00000100
		.byte 0b00000010
		.byte 0b00000001
		.byte 0b00000010
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00100000
		.byte 0b01000000
		.byte 0b10000000
		.byte 0b01000000
		.byte 0b00100000
		.byte 0b00010000
		.byte 0b00001000
		.byte 0b00000100
		.byte 0b00000010
		.byte 0b00000001
		.byte 0b00000011
		.byte 0b00000111
		.byte 0b00001111
		.byte 0b00011111
		.byte 0b00111111
		.byte 0b01111111
		.byte 0b11111111
		.byte 0b11111111
		.byte 0b00000000
		.byte 0b11111111
		.byte 0b00000000
		.byte 0b11111111
		.byte 0b00000000
		.byte 0b11111111
		.byte 0b00000000
		.byte 0b11111111
		.byte 0b00000000
		.byte 0b11111111
		.byte 0b00000000
		.byte 0b11111111
		.byte 0b11111110
		.byte 0b11111100
		.byte 0b11111000
		.byte 0b11110000
		.byte 0b11100000
		.byte 0b11000000
		.byte 0b10000000
		.byte 0b00000000
		.byte 0b10000000
		.byte 0b11000000
		.byte 0b11100000
		.byte 0b11110000
		.byte 0b01111000
		.byte 0b00111100
		.byte 0b00011110
		.byte 0b00001111
		.byte 0b10000111
		.byte 0b11000011
		.byte 0b11100001
		.byte 0b11110000
		.byte 0b01111000
		.byte 0b00111100
		.byte 0b00011110
		.byte 0b00001111
		.byte 0b10000111
		.byte 0b11000011
		.byte 0b11100001
		.byte 0b11110000
		.byte 0b01111000
		.byte 0b00111100
		.byte 0b00011110
		.byte 0b00001111
		.byte 0b00000111
		.byte 0b00000011
		.byte 0b00000001
		.byte 0b00000000
ledend:

		.section .bss

ramvectors:	.space 1024			| runtime vectors
delay:		.space 2			| delay variable
ramstart:					| and the pattern copy
