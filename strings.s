		.align 2

		.section .text

		.global bytetoascii
		.global wordtoascii
		.global longtoascii
		.global asciitoint

| convert the byte in d0 to hex, writing it into a0 and advancing it 2
| bytes. d0.w is retained

bytetoascii:	move.w %d0,-(%sp)		| save d0
		lsr.b #4,%d0			| get the left most nybble
		cmp.b #10,%d0			| less then 10?
		blt 1f				| yes, only add to 0
		add.b #'a-'0-10,%d0		| add past 'a', but less '0'
1:		add.b #'0,%d0			| add '0' too
		move.b %d0,(%a0)+		| save the nybble
		move.w (%sp),%d0		| get the byte back
		and.b #0x0f,%d0			| mask off the left nybble
		cmp.b #10,%d0			| less then 10?
		blt 2f				| yes, only add to 0
		add.b #'a-'0-10,%d0		| add past 'a', but less '0'
2:		add.b #'0,%d0			| add '0' too
		move.b %d0,(%a0)+		| save the nybble
		move.b #0,(%a0)			| add null but dont advance
		move.w (%sp)+,%d0		| get the byte back
		rts

| convert the word in d0 to hex, writing it into a0 and advancing it 4
| bytes. d0.w is retained

wordtoascii:	move.w %d0,-(%sp)
		lsr.w #8,%d0			| high byte at low byte pos
		bsr bytetoascii			| convert that byte
		move.w (%sp),%d0		| get byte back
		bsr bytetoascii			| convert the low byte
		move.w (%sp)+,%d0
		rts

| convert the long in d0 to hex, writing it into a0 and advancing it 8
| bytes. d0.l is retained

longtoascii:	move.l %d0,-(%sp)
		swap %d0			| exchange halves
		bsr wordtoascii			| convert the high word
		move.l (%sp),%d0		| get the low half
		bsr wordtoascii			| convert the low word
		move.l (%sp)+,%d0
		rts

| convert the string at a0 to a integer. d0 will hold the value, d1 will
| hold the number of hex digits converted. on error, d1 will be 0

asciitoint:	move.w %d2,-(%sp)
		move.l #0,%d0
		move.b #0,%d1			| clear digit counter
		move.b (%a0)+,%d2		| get the first char
		cmp.b #'!,%d2			| see if it is a nonwsp char
		bls 3f				| out right away
1:		sub.b #'0,%d2			| subtract '0'
		cmp.b #0x09,%d2			| less then or equal to 9?
		bls 2f				| yes? we are done with this
		sub.b #'A'-':,%d2		| subtract diff 'A'-':'
		cmp.b #0x10,%d2
		blt 2f				| was uppercase
		sub.b #'a-'A,%d2		| was lowercase
2:		add.b %d2,%d0
		add.b #1,%d1			| inc digit counter
		move.b (%a0)+,%d2
		cmp.b #'!,%d2			| see if it is a nonwsp char
		bls 3f
		asl.l #4,%d0			| shift to next nyblle
		bra 1b
3:		move.w (%sp)+,%d2
		rts
