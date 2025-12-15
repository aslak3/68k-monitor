		.equ VARARG, 0x8000		| vararg argument

| add a command with the given name and maxtypes

.macro checkcommand name,maxtypes:vararg
		.section .rodata.com.name
		.align 2
name_\name:	.asciz "\name"
		.section .rodata.com.maxtypes
		.align 2
maxtypes_\name:	.word \maxtypes
		.word 0
		.section .rodata.com
		.align 2
com_\name:	.long \name			| handler pointer
		.long maxtypes_\name		| list of maxtypes pointer
		.section .rodata
		.align 4
		.long name_\name		| name pointer
		.long com_\name			| command descriptor
.endm

.macro nocheckcommand name
		.section .rodata.com.name
		.align 2
name_\name:	.asciz "\name"
		.section .rodata.com
		.align 2
com_\name:	.long \name			| handler pointer
		.long 0				| list of maxtypes pointer
		.section .rodata
		.align 4
		.long name_\name		| name pointer
		.long com_\name			| command descriptor
.endm

.macro endcommand nextblock
		.long 0x0
		.long \nextblock		| vital! probably 0
.endm

.macro setzero
		ori #0x04,%ccr			| set the z bit
.endm

.macro clearzero
		andi #0xfb,%ccr			| clear the z bit
.endm

.macro enableints
		andi #0xf8ff,%sr
.endm

.macro disableints
		ori #0x0700,%sr
.endm

.macro enablesuper
		ori #0x2000,%sr          	| set supervisor bit
.endm

.macro disablesuper
		andi #0xDFFF,%sr		| clear supervisor bit
.endm

.macro debugreg label, reg
		movem.l %d0/%a0,-(%sp)
		move.l \reg,-(%sp)
		lea (\label,%pc),%a0
		bsr serputstr
		move.l (%sp)+,%d0
		bsr serputlong
		movem.l (%sp)+,%d0/%a0
.endm

.macro debugstr label, reg
		movem.l %d0/%a0,-(%sp)
		move.l \reg,-(%sp)
		lea (\label,%pc),%a0
		bsr serputstr
		move.b #'[',%d0
		bsr serputchar
		move.l (%sp)+,%a0
		bsr serputstr
		move.b #']',%d0
		bsr serputchar
		movem.l (%sp)+,%d0/%a0
.endm

.macro debugprint message, section, flags
.if		\section & DEBUG_SECTIONS
		.section .rodata
_\@:		.asciz "\message"

		.section .text
		.align 2

		movem.l %a5,-(%sp)
		movem.l %a0-%a1,-(%sp)
		movea.l #portadevice,%a5

.if		\section == SECTION_MONITOR
		lea (monitormsg,%pc),%a0
.endif
.if		\section == SECTION_DISASSEMBLER
		lea (dissasmsg,%pc),%a0
.endif

.if		\section == SECTION_MEMORY
		lea (memorymsg,%pc),%a0
.endif
.if		\section == SECTION_LISTS
		lea (listsmsg,%pc),%a0
.endif
.if		\section == SECTION_TASKS
		lea (tasksmsg,%pc),%a0
.endif
.if		\section == SECTION_DEBUGGER
		lea (debuggermsg,%pc),%a0
.endif

		bsr serputstr
		lea (_\@,%pc),%a0
		bsr serputstr
		movem.l (%sp)+,%a0-%a1

.if		\flags & REG_D0
		debugreg d0msg, %d0
.endif
.if		\flags & REG_D1
		debugreg d1msg, %d1
.endif
.if		\flags & REG_D2
		debugreg d2msg, %d2
.endif
.if		\flags & REG_D3
		debugreg d3msg, %d3
.endif
.if		\flags & REG_D4
		debugreg d4msg, %d4
.endif
.if		\flags & REG_D5
		debugreg d5msg, %d5
.endif
.if		\flags & REG_D6
		debugreg d6msg, %d6
.endif
.if		\flags & REG_D7
		debugreg d7msg, %d7
.endif

.if		\flags & REG_A0
		debugreg a0msg, %a0
.endif
.if		\flags & REG_A1
		debugreg a1msg, %a1
.endif
.if		\flags & REG_A2
		debugreg a2msg, %a2
.endif
.if		\flags & REG_A3
		debugreg a3msg, %a3
.endif
.if		\flags & REG_A4
		debugreg a4msg, %a4
.endif
.if		\flags & REG_A5
		debugreg a5msg, %a5
.endif
.if		\flags & REG_A6
		debugreg a6msg, %a6
.endif
.if		\flags & REG_A7
		debugreg a7msg, %a7
.endif

.if		\flags & STR_A0
		debugstr a0msg, %a0
.endif
.if		\flags & STR_A1
		debugstr a1msg, %a1
.endif
.if		\flags & STR_A2
		debugstr a2msg, %a2
.endif
.if		\flags & STR_A3
		debugstr a3msg, %a3
.endif
.if		\flags & STR_A4
		debugstr a4msg, %a4
.endif
.if		\flags & STR_A5
		debugstr a5msg, %a5
.endif
.if		\flags & STR_A6
		debugstr a6msg, %a6
.endif
.if		\flags & STR_A7
		debugstr a7msg, %a7
.endif

		movem.l %a0,-(%sp)
		lea (newlinemsg,%pc),%a0
		bsr serputstr
		movem.l (%sp)+,%a0
		movem.l (%sp)+,%a5
.endif
.endm

.macro instruction label, name, pattern, mask, condfunc, widthfunc, srcfunc, dstfunc
		.section .rodata.instructions.names
		.align 2
name_\label:	.asciz "\name"
		.section .rodata
		.align 2
		.long name_\label		| name pointer
		.word \pattern			| bit pattern
		.word \mask			| mask
		.long \condfunc			| ending (before width) of name like eq
		.long \widthfunc		| width extraction routine
		.long \srcfunc			| source extraction routine
		.long \dstfunc			| destination extraction routine
.endm
