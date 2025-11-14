		.include "../include/hardware.i"
		.include "../include/macros.i"
		.include "include/system.i"

		.global _debugger

		.section .text
		.align 2

_debugger:	movea.l #portbdevice,%a5	| comms is via port b to gdb host

.loop:		debugprint "top of loop", SECTION_DEBUGGER, 0
		bsr sergetchar			| get the latest byte, waiting as needed
		cmp.b #'\$',%d0			| looking for a start of packet marker
		bne .loop			| no? just keep reading until we found one
		movea.l #packetbody,%a0		| we are copying packet content into a0
.packetloop:	bsr sergetchar			| get the next byte in the packet body
		cmp.b #'\#',%d0			| hash marks the end of packet body
		beq .endpacket			| if it is a hash then process complete packet
		move.b %d0,(%a0)+		| otherwise save the byte
		bra .packetloop			| back to top getting packet bytes		
.endpacket:	move.b #0,(%a0)+		| add a null on end of packet buffer
		movea.l #newlinemsg,%a0		| and a newline
		bsr serputstr			| put it

		movea.l #portbdevice,%a5	| back on port b
		bsr sergetchar			| get the checksum bytes
		bsr sergetchar			| and the second one

| TODO: check checksum

		movea.l #packetbody,%a0		| now we are comparing the packet
		debugprint "got this packet", SECTION_DEBUGGER, STR_A0
		movea.l #mustreplyempty,%a1	| to something
		bsr strcmp			| see if we found it
		beq sendempty			| jump there if we found it

		bra .loop			| to the next packet!

sendempty:	debugprint "sending an empty packet", SECTION_DEBUGGER, 0
		movea.l #emptyreply,%a0		| nothing here
		bsr putpacket			| send the markers and 00 checksum
		bra .loop

| sends the packet body in a0, with head and tail markers and checksum

putpacket:	debugprint "putpacket called", SECTION_DEBUGGER, 0
		movem.l %d0-%d1,-(%sp)
		move.b #'+',%d0			| plus means we ack the packet
		bsr serputchar			| send it
		move.b #'$',%d0			| sending begin packet marker
		bsr serputchar			| send it
		clr.b %d1			| d1 holds the checksum
1:		move.b (%a0)+,%d0		| get the char to send
		beq 2f				| if null, we are done
		add.b %d0,%d1			| tot up checksum, truncating to bytes
		bsr serputchar			| send it
		bra 1b				| back for more chars
2:		move.b #'#',%d0			| before the checksum, mark the end of data
		bsr serputchar			| send it
		move.b %d1,%d0			| grab the checksum
		bsr serputbyte			| turn it into ascii
		movem.l (%sp)+,%d0-%d1
		rts

		.section .rodata
		.align 2

mustreplyempty:	.asciz "vMustReplyEmpty"

emptyreply:	.asciz ""

		.section .bss
		.align 2

packetbody:	.space 256
