		.include "../include/macros.i"
		.include "../include/system.i"
		.include "include/system.i"

		.global listbps
		.global addbp
		.global delbp

		.section .text
		.align 2

		.equ BP_ADDRESS, 0
		.equ BP_WORD, 4
		.equ BP_PADDING , 6
		.equ BP_SIZE, 8

		.equ BP_COUNT, 8

| lists all currently set breakpoints
listbps:	movea.l #bplist,%a1		| get start of breakpoint list
		move.w #0,%d1			| 8 breakpoints to check
1:		movea.l (BP_ADDRESS,%a1),%a2	| get the breakpoint address
		tst.l %a2			| bp not in use?
		beq 2f				| skip it
		movea.l #bpindexmsg,%a0		| print "Index: "
		bsr serputstr			| output it
		move.w %d1,%d0			| index in d0
		bsr serputword			| output it
		movea.l #newlinemsg,%a0		| newline after each
		bsr serputstr			| output it
		move.l %a2,%a0			| address to disassemble
		move.w #4,%d0			| print four instructions after bp
		bsr disassemble			| disassemble the instruction at the breakpoint
		movea.l #newlinemsg,%a0		| newline after each
		bsr serputstr			| output it
2:		add.l #BP_SIZE,%a1		| next bp entry
		addq.l #1,%d1			| inc bp counter
		cmp.w #BP_COUNT,%d1		| done them all?
		blt 1b				| loop for next
		rts

| adds a breakpoint at the given address in a0, at the position in d0.w (0-7)
addbp:		movea.l #bplist,%a1		| get start of breakpoint list
		lsl.w #3,%d0			| multiply index by BP_SIZE (8)
		move.l %a0,(BP_ADDRESS,%d0.w,%a1)
						| store the address
		rts

delbp:		movea.l #bplist,%a1		| get start of breakpoint list
		lsl.w #3,%d0			| multiply index by BP_SIZE (8)
		clr.l (BP_ADDRESS,%d0.w,%a1)	| clear the address to remove bp
		rts

		.section .rodata
		.align 2

bpindexmsg:	.asciz "Index: "

		.section .bss
		.align 2

bplist:		.space BP_SIZE*BP_COUNT		| space for 8 breakpoints
