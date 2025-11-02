		.include "include/system.i"

		.global memorydump
		.global printbuffer

		.global d0msg
		.global d1msg
		.global d2msg
		.global d3msg
		.global d4msg
		.global d5msg
		.global d6msg
		.global d7msg

		.global a0msg
		.global a1msg
		.global a2msg
		.global a3msg
		.global a4msg
		.global a5msg
		.global a6msg
		.global a7msg

		.global memorymsg

		.section .text
		.align 2

memorydump:	movea.l #HEAP_START,%a2		| get the start of the heap

1:		lea (printbuffer,%pc),%a0	| start of print buffer
		lea (thismsg,%pc),%a1		| next label
		move.l %a2,%d0			| get the current block pointer
		add #MEM_SIZE,%d0		| turn it into a useful pointer for free
		movea.l #longtoascii,%a6	| printing a long for d0
		bsr labandint			| print them into a0
		lea (printbuffer,%pc),%a0	| wind buffer back
		bsr conputstr			| and print it

		lea (printbuffer,%pc),%a0	| start of print buffer
		lea (nextmsg,%pc),%a1		| next label
		move.l MEM_NEXT(%a2),%d0	| get the next pointer
		movea.l #longtoascii,%a6	| printing a long for d0
		bsr labandint			| print them into a0
		lea (printbuffer,%pc),%a0	| wind buffer back
		bsr conputstr			| and print it

		lea (printbuffer,%pc),%a0	| start of print buffer
		lea (lengthmsg,%pc),%a1		| length label
		move.l MEM_LENGTH(%a2),%d0	| get the length
		movea.l #longtoascii,%a6	| printing a long for d0
		bsr labandint			| print them into a0
		lea (printbuffer,%pc),%a0	| wind buffer back
		bsr conputstr			| and print it

		lea (printbuffer,%pc),%a0	| start of print buffer
		lea (freemsg,%pc),%a1		| free label
		move.w MEM_FREE(%a2),%d0	| get the free flag
		movea.l #bytetoascii,%a6	| printing a byte for d0
		bsr labandint			| print them into a0
		lea (printbuffer,%pc),%a0	| wind buffer back
		bsr conputstr			| and print it

		lea.l (newlinemsg,%pc),%a0	| blank between blocks
        	bsr conputstr			| ...

		movea.l MEM_NEXT(%a2),%a2	| get the next pointer
		tst %a2				| not null?
		bne 1b				| ... back for more
		rts

thismsg:	.asciz "This: "
nextmsg:	.asciz "Next: "
lengthmsg:	.asciz "Length: "
freemsg:	.asciz "Free: "

d0msg:		.asciz " D0="
d1msg:		.asciz " D1="
d2msg:		.asciz " D2="
d3msg:		.asciz " D3="
d4msg:		.asciz " D4="
d5msg:		.asciz " D5="
d6msg:		.asciz " D6="
d7msg:		.asciz " D7="

a0msg:		.asciz " A0="
a1msg:		.asciz " A1="
a2msg:		.asciz " A2="
a3msg:		.asciz " A3="
a4msg:		.asciz " A4="
a5msg:		.asciz " A5="
a6msg:		.asciz " A6="
a7msg:		.asciz " A7="

memorymsg:	.asciz "MEMORY: "

		.section .bss
		.align 2

printbuffer:	.space 256
