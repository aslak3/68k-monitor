		.include "../include/macros.i"
		.include "../include/system.i"
		.include "../include/vectors.i"

		.global _trapinit
		.global _debugger

		.section .text
		.align 2

		.equ REG_COUNT, 8*2

_trapinit:	debugprint "setting up trap #0 vector", SECTION_DEBUGGER, 0
		move.l #debugger,TRAP0VECTOR	| setup the vector

		rts

_debugger:	debugprint "entering debugger", SECTION_DEBUGGER, 0
		trap #0				| enter debugger
		debugprint "debugger has returned to us", SECTION_DEBUGGER, 0
		rts

debugger:	rte
		debugprint "entered debugger", SECTION_DEBUGGER,0
		move.l %sp,originalsp		| save stackpointer on entry
		movem %d0-%d7/%a0-%a7,registers	| save all registers

		movea.l #portadevice,%a5	| comms is via port b to gdb host

.loop:		debugprint "top of loop", SECTION_DEBUGGER, 0
		bsr sergetchar			| get the latest byte, waiting as needed
		cmp.b #'\$',%d0			| looking for a start of packet marker
		bne .loop			| no? just keep reading until we found one
		movea.l #getpacketbody,%a0	| we are copying packet content into a0
.packetloop:	bsr sergetchar			| get the next byte in the packet body
		cmp.b #'\#',%d0			| hash marks the end of packet body
		beq .endpacket			| if it is a hash then process complete packet
		move.b %d0,(%a0)+		| otherwise save the byte
		bra .packetloop			| back to top getting packet bytes
.endpacket:	move.b #0,(%a0)+		| add a null on end of packet buffer
|		movea.l #newlinemsg,%a0		| and a newline
|		bsr serputstr			| put it

		movea.l #portadevice,%a5	| back on port b
		bsr sergetchar			| get the checksum bytes
		bsr sergetchar			| and the second one

| TODO: check checksum

		movea.l #getpacketbody,%a0	| now we are comparing the packet
		debugprint "got this packet", SECTION_DEBUGGER, STR_A0
		move.b (%a0)+,%d0		| load d0 with first char of packet
		cmp.b #'d',%d0			| looking for debug flag
		beq .debugtoggle		| found it
		cmp.b #'g',%d0			| looking for register dump
		beq .registerread		| found it
		cmp.b #'G',%d0			| looking register write
		beq .registerwrite		| found it
		cmp.b #'m',%d0			| looking for memory read
		beq .memoryread			| found it
		cmp.b #'c',%d0			| looking for continue
		beq .continue			| found it

.loopbottom:	bsr putpacket

		bra .loop

.exit:		debugprint "leaving debugger", SECTION_DEBUGGER, 0
		movem registers,%d0-%d7/%a0-%a7	| restore all registers
		rte

.debugtoggle:	debugprint "inverting debug flag", SECTION_DEBUGGER, 0
		not.w remotedebug		| invert the remote debug flag
		bra .loop
.registerread:	debugprint "dumping registers", SECTION_DEBUGGER, 0
		movea.l #putpacketbody,%a0	| where to put the packet body we send
		movea.l #registers,%a1		| get start of register table
		move.w #REG_COUNT-1,%d1		| count of registers
		move.l #strdevice,%a5		| "putting" into a0 instead
1:		move.l (%a1)+,%d0		| get a register
		bsr serputlong			| output it into a0
		dbra %d1,1b			| loop outputting all of them
		movea.l #putpacketbody,%a0	| wind a0 back
		movea.l #portadevice,%a5
		debugprint "dumping registers complete", SECTION_DEBUGGER, 0
		bra .loopbottom
.registerwrite:	debugprint "setting registers", SECTION_DEBUGGER, 0
		movea.l #registers,%a1		| get start of register table
		bsr bytesfromascii		| update the registers with new content
		movea.l #okreply,%a0		| send OK
		bra .loopbottom
.memoryread:	debugprint "memory read", SECTION_DEBUGGER, 0
		bra .loopbottom
.continue:	debugprint "continuing", SECTION_DEBUGGER, 0
		bra .exit

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
okreply:	.asciz "OK"

		.section .bss
		.align 2

getpacketbody:	.space 1024
putpacketbody:	.space 1024
remotedebug:	.word 0
originalsp:	.long 0
registers:	.space (8*2*4)
