		.include "include/macros.i"
		.include "include/system.i"

		.global serputbyte
		.global serputword
		.global serputlong
		.global asciitoint
		.global asciitonybble
		.global bytesfromascii
		.global strcmp
		.global strmatcharray
		.global strconcat
		.global makecharprint
		.global toupper

		.section .text
		.align 2

| convert the byte in d0 to hex, printing on the function in a5. d0.w is retained

serputbyte:	move.w %d0,-(%sp)		| save d0
		lsr.b #4,%d0			| get the left most nybble
		cmp.b #10,%d0			| less then 10?
		blt 1f				| yes, only add to 0
		add.b #'a-'0-10,%d0		| add past 'a', but less '0'
1:		add.b #'0,%d0			| add '0' too
		bsr serputchar			| output that char
		move.w (%sp),%d0		| get the byte back
		and.b #0x0f,%d0			| mask off the left nybble
		cmp.b #10,%d0			| less then 10?
		blt 2f				| yes, only add to 0
		add.b #'a-'0-10,%d0		| add past 'a', but less '0'
2:		add.b #'0,%d0			| add '0' too
		bsr serputchar			| output that char
		move.w (%sp)+,%d0		| get the byte back
		rts

| convert the word in d0 to hex, outputting it with the sub at a5. d0.w is retained

serputword:	move.w %d0,-(%sp)
		lsr.w #8,%d0			| high byte at low byte pos
		bsr serputbyte			| convert that byte
		move.w (%sp),%d0		| get byte back
		bsr serputbyte			| convert the low byte
		move.w (%sp)+,%d0
		rts

| convert the long in d0 to hex, outputting it with the sub at a5. d0.l is retained

serputlong:	move.l %d0,-(%sp)
		swap %d0			| exchange halves
		bsr serputword			| convert the high word
		move.l (%sp),%d0		| get the low half
		bsr serputword			| convert the low word
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

asciitoint:	debugprint "asciitoint", SECTION_MONITOR, 0
		movem.l %d2/%a1,-(%sp)
		clr.l %d2			| set result to zero
		clr.w %d1			| clear digit counter
0:		bsr asciitonybble		| convert the nybble into d0
		beq 2f				| if error, then done
1:		asl.l #4,%d2			| shift val to next nybble
		add.b %d0,%d2			| accumulate number
		debugprint "asciitoinit value now", SECTION_MONITOR, REG_D2
		addq.b #1,%d1			| inc digit counter
		move.b (%a0),%d0		| peek at the next byte
		cmp.b #'!',%d0			| see if its a nowsp char
		bls 3f				| yes? then done (good)
		cmp.b #8,%d1			| too many digits?
		blt 0b				| no? back for more
2:		debugprint "asciitoint error", SECTION_MONITOR, 0
		move.b #0,%d1			| mark 0 digits
		bra 4f				| bad, clean up
3:		movea.l #datatypetable,%a1	| get start of table
		move.b (%d1.w,%a1),%d1		| translate to type
		move.l %d2,%d0			| copy it into the output reg
		debugprint "asciitoint no error value and digit count", SECTION_MONITOR, (REG_D0+REG_D1)
		clearzero			| in case value is 0
4:		movem.l (%sp)+,%d2/%a1
		rts

| convert the nybble wide string at a0 into an integer, storing the result in d0. on error
| zero will be set.

asciitonybble:	debugprint "asciitonybble", SECTION_MONITOR, 0
		move.b (%a0)+,%d0		| get the character
		debugprint "asciitonybble got character", SECTION_MONITOR, REG_D0
		sub.b #'0',%d0			| subtract '0'
		blt 2f				| <0? bad
		cmp.b #9,%d0			| less then or equal to 9?
		bls 1f				| yes? we are done with this
		sub.b #'A'-':',%d0		| subtract diff 'A'-':'
		blt 2f				| <0? bad
		cmp.b #0x10,%d0			| see if it is uppercase
		blt 1f				| was uppercase
		sub.b #'a'-'A',%d0		| was lowercase
		cmp.b #0x10,%d0			| compare with upper range
		bge 2f				| <=15? good
1:		debugprint "asciitobybble no error got digit", SECTION_MONITOR, REG_D0
		clearzero			| clear zero, incase result was zero
		rts
2:		debugprint "asciitobybble error", SECTION_MONITOR, 0
		move.b #0,%d0			| set zero (and return zero)
		rts

| convert the ascii hex string at a0 into bytes at the memory a1, keep going until there is
| a null or an error. on error zero is set.

bytesfromascii:	movem.l %d0-%d1,-(%sp)
1:		bsr asciitonybble		| get the nybble in d0
		beq 2f				| on error, exit
		move.b %d0,%d1			| save result in d1
		bsr asciitonybble		| get the nybble in d0
		beq 2f				| on error, exit
		asl.l #4,%d1			| shift val to next nybble
		add.b %d0,%d1			| save result in d1
		move.b %d1,(%a1)+		| save the converted byte
		tst.b (%a0)			| peek at the next byte
		bne 1b				| if it's a null we are done, good exit
		setzero				| good exit
		bra 3f
2:		clearzero			| bad exit
3:		movem.l (%sp)+,%d0-%d1
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

