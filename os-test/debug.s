		.include "include/system.i"

		.global memorydump
		.global taskdump
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
		.global listsmsg
		.global tasksmsg
		.global debuggermsg

		.section .text
		.align 2

memorydump:	movea.l #HEAP_START,%a2		| get the start of the heap

1:		lea (thismsg,%pc),%a0		| next label
		bsr serputstr			| print it
		move.l %a2,%d0			| get the current block pointer
		add #MEM_SIZE,%d0		| turn it into a useful pointer for free
		bsr serputlong			| print it
		lea (newlinemsg,%pc),%a0	| adding a newline
		bsr serputstr			| print it
		
		lea (nextmsg,%pc),%a0		| next label
		bsr serputstr			| print it
		move.l MEM_NEXT(%a2),%d0	| get the next pointer
		bsr serputlong			| turn it into a long and print
		lea (newlinemsg,%pc),%a0	| adding a newline
		bsr serputstr			| and print it

		lea (lengthmsg,%pc),%a0		| length label
		bsr serputstr			| print it
		move.l MEM_LENGTH(%a2),%d0	| get the length
		bsr serputlong			| print it
		lea (newlinemsg,%pc),%a0	| adding a newline
		bsr serputstr			| and print it

		lea (freemsg,%pc),%a0		| free label
		bsr serputstr			| print it		
		move.w MEM_FREE(%a2),%d0	| get the free flag
		bsr serputbyte			| print it as byte this time
		lea.l (newlinemsg,%pc),%a0	| blank between blocks
        	bsr serputstr			| ...

		lea.l (newlinemsg,%pc),%a0	| blank between blocks
        	bsr serputstr			| ...

		movea.l MEM_NEXT(%a2),%a2	| get the next pointer
		tst %a2				| not null?
		bne 1b				| ... back for more
		rts

taskdump:	move.l %a0,%a2

		lea (startpcmsg,%pc),%a0	| inital pc label
		bsr serputstr			| print it		
		move.l (TASK_START_PC,%a2),%d0	| get the initial pc
		bsr serputlong			| print it
		lea (newlinemsg,%pc),%a0	| adding a newline
		bsr serputstr			| and print it
		rts

		lea (spmsg,%pc),%a0		| inital sp label
		bsr serputstr			| print it		
		move.l (TASK_SP,%a2),%d0	| get the sp
		bsr serputlong			| print it
		lea (newlinemsg,%pc),%a0	| adding a newline
		bsr serputstr			| and print it
		rts

thismsg:	.asciz "This: "
nextmsg:	.asciz "Next: "
lengthmsg:	.asciz "Length: "
freemsg:	.asciz "Free: "

startpcmsg:	.asciz "Initial PC: "
spmsg:		.asciz "SP: "

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
listsmsg:	.asciz "LISTS: "
tasksmsg:	.asciz "TASKS: "
debuggermsg:	.asciz "DEBUGGER: "

		.section .bss
		.align 2

printbuffer:	.space 256
