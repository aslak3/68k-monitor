		.include "include/system.i"

		.global memorydump
		.global printbuffer

		.section .text
		.align 2

memorydump:	movea.l #HEAP_START,%a2		| get the start of the heap

1:		lea (printbuffer,%pc),%a0	| start of print buffer
		lea (thismsg,%pc),%a1		| next label
		move.l %a2,%d0			| get the current block pointer
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

		.section bss
		.align 2

printbuffer:	.space 256
