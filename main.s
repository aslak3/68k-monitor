		.include "include/hardware.i"

		.section .text
		.align 2

		.global start
		.global entry
		.global savedregisters

start:		movea.l #0x01000000,%sp		| 16 MB

| clear the first 32MB

		movea.l #0x00000000,%a0		| start at 0
		move.w #(((4*1024*1024)/4)/65536)-1,%d1
						| number of 64KB long blocks
1:		move.w #65536-1,%d0		| 64KB of long words
2:		clr.l (%a0)+			| clear it
		dbra %d0,2b			| back for more
		dbra %d1,1b			| next 64KB block

		move.b #1,LED

		bsr exceptionsinit		| setup execption handlers
		bsr serialinit			| prepare the console port
|		bsr timerinit			| prepare the timer
|		bsr vgainit
|		bsr keyboardinit
|		bsr mouseinit
		bsr initbreakpoints		| prepare breakpoint system

		move.w #1024-1,%d0
		movea.l #0x00008000,%a0
1:		move.w #0xff00,(%a0)+
		dbra %d0,1b

		move.l #0x0101,%d0
		movec.l %d0,%cacr
		move.w #0x2000,%sr

		move.b #0,LED
1:		trap #0				| enter monitor
		bra 1b				| run loop again

entry:		movem.l %d0-%d7/%a0-%a7,savedregisters
						| save all registers

		movea.l #portadevice,%a5	| point a5 to port a device
		movea.l #trap0msg,%a0		| load address of trap0 message
		bsr serputstr			| print trap0 message
		move.l (2,%sp),%d0		| get pc
		bsr serputlong			| print pc
		subq.l #2,%d0			| adjust pc to point to trap
		move.l %d0,resumepc		| save it for breakpoint handling
		movea.l #srmsg,%a0		| load sr message
		bsr serputstr			| print sr message
		move.w (0,%sp),%d0		| get sr
		bsr serputword			| print sr
		movea.l #formvectormsg,%a0	| load format/vector message
		bsr serputstr			| print it
		move.w (6,%sp),%d0		| get format/vector
		| TODO: resolve vector into human readable form for banner
		bsr serputword			| print it
		lea (newlinemsg,%pc),%a0	| need a newline
		bsr serputstr			| and print it
		lea (newlinemsg,%pc),%a0	| need a newline
		bsr serputstr			| and another newline

		bsr cleartraps			| we want to see the real instructions now

		bsr printregs			| print all registers
		lea (newlinemsg,%pc),%a0	| need a newline
		bsr serputstr			| and print it

		movea.l resumepc,%a0		| get the resume pc
		move.w #4,%d0			| print four instructions after trap
		bsr disassemble			| disassemble the instruction at the trap

mainloop:	lea.l (newlinemsg,%pc),%a0	| blank between commands
		bsr serputstr			| ...

		lea.l (entercmdmsg,%pc),%a0	| grab the greeting in a0
		bsr serputstr			| send it
		movea.l #inputbuffer,%a0	| set the input up
		bsr sergetstr			| read a line

		movea.l #inputbuffer,%a0	| a0=input buffer
		movea.l #cmdbuffer,%a1		| a1=command buffer
		movea.l #typebuffer,%a2		| a2=type buffer
		movea.l #valuebuffer,%a3	| a3=value buffer
		movea.l #stringbuffer,%a4	| a4=string buffer
		bsr parser			| parse out the line
		beq parsererror			| check for error
		movea.l #commandarray,%a0	| setup command array in a0
		bsr strmatcharray		| match against cmd in a1
		beq nocommand			| no command
		move.l %d0,%a4			| move com data ptr to a5
		movea.l #typebuffer,%a0		| retrivie the input types
		move.l 4(%a4),%d0		| get the required types
		beq 1f				| dont check if its null
		move.l %d0,%a1			| move req types into a1
		jsr checktypes			| check the types
		bne badparams			| bad params check failed
1:		movea.l (%a4),%a2		| address is first entry
		movea.l %a3,%a1			| values in a1
		jsr (%a2)			| run the comamnd sub
		bra mainloop

parsererror:	lea (parsererrormsg,%pc),%a0
		bsr serputstr
		bra mainloop

badparams:	lea (badparamsmsg,%pc),%a0
		bsr serputstr
		bra mainloop

nocommand:	lea (nocommandmsg,%pc),%a0
		bsr serputstr
		bra mainloop

		.section .rodata
		.align 2

trap0msg:	.asciz "\r\n*** Entering Monitor via Trap #0 PC: "
srmsg:		.asciz " SR: "
formvectormsg: 	.asciz " Format/Vector: "
entercmdmsg:	.asciz "Monitor: > "

parsererrormsg:	.asciz "Parser rror!\r\n"
nocommandmsg:	.asciz "No such command\r\n"
badparamsmsg:	.asciz "Bad paramters to command\r\n"

		.section .bss
		.align 2			| longs need aligning

savedregisters:	.space (8*2*4)

inputbuffer:	.space 256
cmdbuffer:	.space 256
typebuffer:	.space 256
valuebuffer:	.space 256
stringbuffer:	.space 256
