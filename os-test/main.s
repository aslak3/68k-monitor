		.include "../include/hardware.i"
		.include "../include/macros.i"
		.include "include/system.i"

		.section .rodata
		.align 4

		.global readytasks
		.global currenttask

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
		nocheckcommand "_taskrun"
		checkcommand "_taskdump", 3

		endcommand 0x0

		.section .text
		.align 2

_memoryinit:	bsr memoryinit
		rts

_memoryalloc:	move.l (0,%a1),%d0		| get the size
		bsr memoryalloc			| allocate
		move.l %a0,%d0			| move result to d0 for printing
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it
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
		lea.l (printbuffer,%pc),%a0
		bsr longtoascii
		move.b #0x20,(%a0)+

		move.l %a2,%a1
		lea (TEST_TEXT,%a1),%a1
		bsr strconcat
		lea (newlinemsg,%pc),%a1
		bsr strconcat
		lea.l (printbuffer,%pc),%a0
		bsr conputstr

		move.l (NODE_NEXT,%a2),%a2

		bra _listdumploop
_listdumpo:	rts

_tasktest:	movea.l #readytasks,%a0
		bsr listinit

		movea.l #testtaskcode,%a0
		bsr newtask

		move.l %a0,currenttask
		rts

_taskdump:	move.l (0*4,%a1),%a0
		bsr taskdump
		rts

_taskrun:	jmp _starttask

testtaskcode:	lea (testmessage,%pc),%a0
		bsr conputstr
		bra testtaskcode

testmessage:	.asciz "Hello from test task!!\r\n"

		.section .bss
		.align 4

testlist:	.space LIST_SIZE

readytasks:	.space LIST_SIZE
currenttask:	.long 0

