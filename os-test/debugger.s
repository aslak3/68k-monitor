		.include "../include/hardware.i"
		.include "../include/macros.i"
		.include "include/system.i"

		.section .text
		.align 2

_echotest:	movea.l #printbuffer,%a0
1:		bsr portbgetchar
		cmp.b #'\$',%d0
		bne 1b
2:		bsr portbgetchar
		cmp.b #'\#',%d0
		beq 3f
		move.b %d0,(%a0)+
		bra 2b
3:		move.b #0,(%a0)+
		movea.l #printbuffer,%a0
		movea.l #portadevice,%a5
		bsr serputstr
		movea.l #newlinemsg,%a0
		bsr serputstr

		bsr portbgetchar
		bsr portbgetchar

		movea.l #printbuffer,%a0
		movea.l #mustreplyempty,%a1
		bsr strcmp
		beq sendempty

		bra _echotest

sendempty:	movea.l #portbdevice,%a5
		movea.l #emptyreply,%a0
		bsr serputstr

		movea.l #portadevice,%a5
		movea.l #emptyreply,%a0
		bsr serputstr

		bra _echotest

| sends the packet body in a0, with head and tail markers and checksum

putpacket:	moveml.l %d0-%d1,-(%sp)
		move.b #'$',%d0			| sending begin packet marker
		bsr portbputchar		| send it
		clr.b %d1			| d1 holds the checksum
1:		move.b (%a0)+,%d0		| get the char to send
		add.b %d0,%d1			| tot up checksum, truncating to bytes
		beq 2f				| if null, we are done
		bsr portbputchar		| send it
		bra 1b				| back for more chars
2:		movea.l #printbuffer,%a0	| we are formatting into the main buffer
		move.b %d1,%d0			| graph the checksum
		bsr bytetoascii			| turn it into ascii
		movea.l 

		.section .rodata
		.align 2

mustreplyempty:	.asciz "vMustReplyEmpty"

emptyreply:	.asciz "+$#00"