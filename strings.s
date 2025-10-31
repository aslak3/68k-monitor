		.section .text
		.align 2

		.global bytetoascii
		.global wordtoascii
		.global longtoascii
		.global asciitoint
		.global strcmp
		.global strmatcharray
		.global strconcat
		.global makecharprint
		.global toupper
		.global labandint

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
		clr.l %d0			| set result to zero
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

| compare the string at a0 with the string at a1, setting d0 to 0 if they are
| the same. zero will also be set. otherwise d1 will be 1. a0 and a1 are
| preserved, for repeated calling.

strcmp:		movem.l %a0-%a1,-(%sp)
1:		move.b (%a0)+,%d0		| read in a1 char
		beq 5f				| null, still need check a1
		cmp.b (%a1)+,%d0		| compare
		beq 1b				| match, keep checking
2:		move.w #1,%d0			| not match
		bra 4f				| out we go
3:		clr.w %d0			| match
4:		movem.l (%sp)+,%a0-%a1
		rts
5:		tst.b (%a1)			| check null on right
		bne 2b				| not the same
		bra 3b				| out we go with match

| match the string in a1 to the list of strings at a0.this list is of the
| form str1,user1,str2,usr2,null. usern goes in d0 on exit, or null for
| no matches

strmatcharray:	movem.l %a2,-(%sp)
		movea.l %a0,%a2			| a2 is used for the list
1:		move.l (%a2)+,%d0		| get the test string
		beq 4f				| end of list?
		move.l %d0,%a0			| move to a0 for compare
		bsr strcmp			| check against cmd
		beq 2f				| match!
		move.l (%a2)+,%d0		| hop over the userdata
		bra 1b				| check more
2:		move.l (%a2)+,%d0		| get the user data/null
3:		movem.l (%sp)+,%a2
		rts
4:		move.l (%a2)+,%d0		| get the possible next hop
		bne 5f				| got next table pointer
		bra 3b				| otherwise we are done
5:		move.l %d0,%a2			| reload the loop pointer
		bra 1b		

| concatenat the string in a1 on the end of the string in a0. on exit,
| a0 will be pointing at the closing null.

strconcat:	move.b (%a1)+,(%a0)+		| add one byte to a0
		beq 1f				| null? out
		bra strconcat			| concat some more
1:		suba.l #1,%a0			| back onto the null
		rts

| flattens the byte in d0 to its printable character, ie <20 or >7e becomes
| a dot.

makecharprint:	cmp.b #0x20,%d0			| compare with space
		blo 1f				| lower? must be unprintable
		cmp.b #0x7e,%d0			| compare with the end char
		bhi 1f				| higher? it must be unprintable
		rts				| if not, leave it alone
1:		move.b #'.',%d0			| otherwise flatten it to dot
		rts

| makes the letter in d0 uppercase

toupper:	cmp.b #'a,%d0			| compare with "a"
		blo 1f				| lower? not a letter
		cmp.b #'z,%d0			| compare with "z"
		bhi 1f				| higher? not a letter
		sub.b #'a-'A,%d0		| convert to uppercase
1:		rts

| puts the label in a1 with d0 printed by the routine in a6 into a0

labandint:	bsr strconcat			| add the label to a0
		jsr (%a6)			| use the passed routine to format
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		rts
