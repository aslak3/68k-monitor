		.include "include/hardware.i"

		.section .text
		.align 2

start:

| clear the first 1MB

		movea.l #0,%a0			| start at 0
		move.w #(((1024*1024)/4)/65536)-1,%d1
						| number of 64KB long blocks
1:		move.w #65536-1,%d0		| 64KB of long words
2:		clr.l (%a0)+			| clear it
		dbra %d0,2b			| back for more
		dbra %d1,1b			| next 64KB block
		bsr exceptionsinit		| setup execption handlers
		bsr serialinit			| prepare the console port
		bsr timerinit			| prepare the timer
		bsr vgainit

mainloop:	lea.l (newlinemsg,%pc),%a0	| blank between commands
		bsr vgaputstr			| ...

		lea.l (entercmdmsg,%pc),%a0	| grab the greeting in a0
		bsr vgaputstr			| send it
		movea.l #inputbuffer,%a0	| set the input up
		bsr getstr			| read a line

		movea.l #inputbuffer,%a0	| a0=input buffer
		movea.l #cmdbuffer,%a1		| a1=command buffer
		movea.l #typebuffer,%a2		| a2=type buffer
		movea.l #valuebuffer,%a3	| a3=value buffer
		bsr parser			| parse out the line
		beq parsererror			| check for error
		movea.l #commandarray,%a0	| setup command array in a0
		bsr strmatcharray		| match against cmd in a1
		beq nocommand			| no command
		move.l %d0,%a4			| move com data ptr to a4
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
		bsr vgaputstr
		bra mainloop

badparams:	lea (badparamsmsg,%pc),%a0
		bsr vgaputstr
		bra mainloop

nocommand:	lea (nocommandmsg,%pc),%a0
		bsr vgaputstr
		bra mainloop

		.section .rodata
		.align 2

entercmdmsg:	.asciz "Monitor: > "

parsererrormsg:	.asciz "Parser rror!\r\n"
nocommandmsg:	.asciz "No such command\r\n"
badparamsmsg:	.asciz "Bad paramters to command\r\n"

		.section .bss
		.align 2			| longs need aligning

inputbuffer:	.space 256
cmdbuffer:	.space 256
typebuffer:	.space 256
valuebuffer:	.space 256
