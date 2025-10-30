		.include "../include/hardware.i"
		.include "../include/macros.i"
		.include "include/system.i"

		.section .rodata
		.align 4

commandarray:   nocheckcommand "meminit"
		checkcommand "memalloc" 3
		checkcommand "memfree" 3
		nocheckcommand "memdump"
		endcommand 0x0

		.section .text
		.align 2

meminit:	bsr memoryinit
		rts

memalloc:	move.l (0,%a1),%d0		| get the size
		bsr memoryalloc			| allocate
		move.l %a0,%d0			| move result to d0 for printing
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it
		rts

memfree:	move.l (0,%a1),%a0		| get the block addr
		bsr memoryfree			| free it
		rts

memdump:	bsr memorydump
		rts
