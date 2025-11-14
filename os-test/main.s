		.include "../include/hardware.i"
		.include "../include/macros.i"
		.include "include/system.i"

		.section .rodata
		.align 4

		.global readytasks
		.global currenttask
		.global superstack

structstart	NODE_SIZE
member		TEST_TEXT,32
structend	TEST_SIZE

commandarray:   nocheckcommand "_memoryinit"
		checkcommand "_memoryalloc" 3
		checkcommand "_memoryfree" 3
		nocheckcommand "_memorydump"

		nocheckcommand "_listinit"
		checkcommand "_addhead" 0x80
		checkcommand "_addtail" 0x80
		nocheckcommand "_remhead"
		nocheckcommand "_remtail"
		checkcommand "_remove" 3
		nocheckcommand "_listdump"

		nocheckcommand "_tasktest"
		nocheckcommand "_testtask2"
		checkcommand "_taskdump", 3

		nocheckcommand "_tickerinit"

		nocheckcommand "_debugger"

		endcommand 0x0

		.section .text
		.align 2

_memoryinit:	bsr memoryinit
		rts

_memoryalloc:	move.l (0,%a1),%d0		| get the size
		bsr memoryalloc			| allocate
		move.l %a0,%d0			| move result to d0 for printing
		bsr serputlong			| convert into a0
		lea (newlinemsg,%pc),%a0	| need a newline
		movea.l #printbuffer,%a0	| wind buffer back
		rts

_memoryfree:	move.l (0,%a1),%a0		| get the block addr
		bsr memoryfree			| free it
		rts

_memorydump:	bsr memorydump
		rts

_listinit:	movea.l #testlist,%a1
		bsr listinit
		rts

_addhead:	move.l (0*4,%a1),%a1
		moveq.l #TEST_SIZE,%d0
		bsr memoryalloc
		move.l %a0,%a2
		lea.l (TEST_TEXT,%a0),%a0
		bsr strconcat
		movea.l #testlist,%a1
		move.l %a2,%a0
		bsr addhead
		rts

_addtail:	move.l (0*4,%a1),%a1
		moveq.l #TEST_SIZE,%d0
		bsr memoryalloc
		move.l %a0,%a2
		lea.l (TEST_TEXT,%a0),%a0
		bsr strconcat
		movea.l #testlist,%a1
		move.l %a2,%a0
		bsr addtail
		rts

_remhead:	movea.l #testlist,%a1
		bsr remhead
		bsr memoryfree
		rts

_remtail:	movea.l #testlist,%a1
		bsr remtail
		bsr memoryfree
		rts

_remove:	move.l (0*4,%a1),%a0
		movea.l #testlist,%a1
		bsr remove
		bsr memoryfree
		rts

_listdump:	movea.l #testlist,%a1
		movea.l (LIST_HEAD,%a1),%a2

_listdumploop:	tst (NODE_NEXT,%a2)
		beq _listdumpo

		move.l %a2,%d0
		bsr serputlong
		move.b #0x20,(%a0)+

		move.l %a2,%a1
		lea (TEST_TEXT,%a1),%a1
		bsr strconcat
		lea (newlinemsg,%pc),%a1
		bsr serputstr

		move.l (NODE_NEXT,%a2),%a2

		bra _listdumploop
_listdumpo:	rts

_tasktest:	move.l #superstack+SSTACK_SIZE,%sp

		movea.l #readytasks,%a1
		bsr listinit

		movea.l #testtaskcode1,%a0
		bsr createtask

		movea.l #testtaskcode2,%a0
		bsr createtask

		jmp _starttask

_testtask2:	move.l #superstack+SSTACK_SIZE,%sp

		movea.l #readytasks,%a1
		bsr listinit

		movea.l #testtaskcode1,%a0
		bsr createtask

		movea.l #testtaskcode2,%a0
		bsr createtask

1:		move.b #1,SPIDATA
		bsr remtail			| take the current task off the head
		move.b #2,SPIDATA
		bsr addhead			| and add it to the tail, rotating the queue
		bra 1b

_taskdump:	move.l (0*4,%a1),%a0
		bsr taskdump
		rts

_tickerinit:	bsr tickerinit
		rts

testtaskcode1:	lea (testmessage1,%pc),%a0
		| forbid
		bsr serputstr
		| permit
		move.w #0x000f,%d1
2:		move.w #0xfff0,%d0
1:		dbra %d0,1b
		dbra %d1,2b
		bra testtaskcode1

testtaskcode2:	lea (testmessage2,%pc),%a0
		| forbid
		bsr serputstr
		| permit
		move.w #0x000f,%d1
2:		move.w #0xfff0,%d0
1:		dbra %d0,1b
		dbra %d1,2b
		bra testtaskcode2

		.section .rodata
		.align 4

testmessage1:	.asciz "ONE!!"
testmessage2:	.asciz "TWO!!"

		.section .bss
		.align 4

testlist:	.space LIST_SIZE

readytasks:	.space LIST_SIZE
currenttask:	.long 0

superstack:	.space SSTACK_SIZE
