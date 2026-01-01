		.include "include/macros.i"
		.include "include/system.i"

		.global listbreakpoints
		.global addbreakpoint
		.global delbreakpoint
		.global settraps
		.global cleartraps

		.section .text
		.align 2

		.equ BP_ADDRESS, 0
		.equ BP_WORD, 4
		.equ BP_PADDING , 6
		.equ BP_SIZE, 8

		.equ BP_COUNT, 8

| TODO: change to use trap #15 or similar
		.equ TRAP_INSTR, 0x4E40		| TRAP instruction opcode TRAP #0

| lists all currently set breakpoints
listbreakpoints:movea.l #bplist,%a1		| get start of breakpoint list
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
addbreakpoint:	movea.l #bplist,%a1		| get start of breakpoint list
		lsl.w #3,%d0			| multiply index by BP_SIZE (8)
		move.l %a0,(BP_ADDRESS,%d0.w,%a1)
						| store the address
		rts

| deletes the breakpoint at the position in d0.w (0-7)
delbreakpoint:	movea.l #bplist,%a1		| get start of breakpoint list
		lsl.w #3,%d0			| multiply index by BP_SIZE (8)
		clr.l (BP_ADDRESS,%d0.w,%a1)	| clear the address to remove bp
		rts

| sets all breakpoints by writing TRAP instructions
settraps:	movea.l #bplist,%a1		| get start of breakpoint list
		move.w #BP_COUNT-1,%d1		| 8 breakpoints to check
1:		movea.l (BP_ADDRESS,%a1),%a2	| get the breakpoint address
		tst.l %a2			| bp not in use?
		beq 2f				| skip it
		move.w (%a2),(BP_WORD,%a1)
						| save original word
		move.w #TRAP_INSTR,(%a2)
						| write TRAP instruction
2:		add.l #BP_SIZE,%a1		| next bp entry
		dbra %d1,1b			| done them all?
		rts

| clears all breakpoints by restoring original instructions
cleartraps:	movea.l #bplist,%a1		| get start of breakpoint list
		move.w #BP_COUNT-1,%d1		| 8 breakpoints to check
1:		movea.l (BP_ADDRESS,%a1),%a2	| get the breakpoint address
		tst.l %a2			| bp not in use?
		beq 2f				| skip it
		move.w (BP_WORD,%a1),(%a2)
						| restore original word
2:		add.l #BP_SIZE,%a1		| next bp entry
		dbra %d1,1b			| done them all?
		rts

		.section .rodata
		.align 2

bpindexmsg:	.asciz "Index: "

		.section .bss
		.align 2

bplist:		.space BP_SIZE*BP_COUNT		| space for 8 breakpoints
