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

| table of number of digits to type, used by the below sub

datatypetable:	.byte 0				| 0

		.byte 1				| 1
		.byte 1				| 2

two:		.byte 2				| 3
		.byte 2				| 4

		.byte 3				| 5
		.byte 3				| 6
		.byte 3				| 7
		.byte 3				| 8

		.byte 0				| padding

| convert the string at a0 to a integer. d0 will hold the value, d1 will
| hold the type (1=byte, 2=word, 3=long). on error, d1 will be 0.
| a0 will be moved to the first non printable char. sets zero on error.

asciitoint:	movem.l %a1/%d2,-(%sp)
		move.l #0,%d0			| set result to zero
		move.w #0,%d1			| clear digit counter
		bra 3f				| branch into loop
1:		sub.b #'0,%d2			| subtract '0'
		blt 4f				| <0? bad
		cmp.b #0x09,%d2			| less then or equal to 9?
		bls 2f				| yes? we are done with this
		sub.b #'A'-':,%d2		| subtract diff 'A'-':'
		blt 4f				| <0? bad
		cmp.b #0x10,%d2			| see if it is uppercase
		blt 2f				| was uppercase
		sub.b #'a-'A,%d2		| was lowercase
		cmp.b #0x10,%d2			| compare with upper range
		bge 4f				| >15? bad
2:		asl.l #4,%d0			| shift val to next nybble
		add.b %d2,%d0			| accumulate number
		add.b #1,%d1			| inc digit counter
		cmp.b #8,%d1			| too many digits?
		bgt 4f				| yes? bad
3:		move.b (%a0)+,%d2		| get the next character
		cmp.b #'!,%d2			| see if it is a nonwsp char
		bls 5f				| yes? then we are done
		bra 1b				| back for more digits
4:		move.b #0,%d1			| mark 0 digits
5:		movea.l #datatypetable,%a1	| get start of table
		move.b (%d1.w,%a1),%d1		| translate to type
		suba.l #1,%a0			| wind back to space char
		movem.l (%sp)+,%d2/%a1
		rts
