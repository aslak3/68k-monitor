		.include "../include/hardware.i"
		.include "../include/macros.i"
		.include "include/system.i"

		.section .rodata
		.align 4

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
		nocheckcommand "_listdump"

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
		rts

_remtail:	movea.l #testlist,%a1
		bsr remtail
		rts

_listdump:	movea.l #testlist,%a1
		movea.l (LIST_HEAD,%a1),%a1

_listdumploop:	movea.l (NODE_NEXT,%a1),%a2
		tst.l %a2
		beq _listdumpo

		lea (TEST_TEXT,%a1),%a0
		bsr conputstr
		lea (newlinemsg,%pc),%a0
		bsr conputstr

		move.l (NODE_NEXT,%a1),%a1

		bra _listdumploop
_listdumpo:	rts

		.section .bss
		.align 4

testlist:	.space LIST_SIZE

