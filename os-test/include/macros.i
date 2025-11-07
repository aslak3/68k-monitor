| structure macros

.macro structstart offset
		structrunning=\offset
.endm

.macro member lab,offset
		.equ \lab, structrunning
		structrunning=structrunning+\offset
.endm

.macro structend lab
		.equ \lab, structrunning
.endm

.macro enableints
		andi #0xf8ff,%sr
.endm

.macro disableints
		ori #0x0700,%sr
.endm

.macro debugreg label, reg
		movem.l %d0/%a0,-(%sp)
		move.l \reg,-(%sp)
		lea (\label,%pc),%a0
		bsr conputstr
		move.l (%sp)+,%d0
		lea (printbuffer,%pc),%a0
		bsr longtoascii
		lea (printbuffer,%pc),%a0
		bsr conputstr
		movem.l (%sp)+,%d0/%a0
.endm

.macro debugprint message, section, flags
.if		\section & DEBUG_SECTIONS
		.section .rodata
_\@:		.asciz "\message"

		.section .text
		.align 2

		movem.l %a0-%a1,-(%sp)
		lea (printbuffer,%pc),%a0
.if		\section == SECTION_MEMORY
		lea (memorymsg,%pc),%a1
.endif
.if		\section == SECTION_LISTS
		lea (listsmsg,%pc),%a1
.endif
.if		\section == SECTION_TASKS
		lea (tasksmsg,%pc),%a1
.endif
		bsr strconcat
		lea (_\@,%pc),%a1
		bsr strconcat
		lea (printbuffer,%pc),%a0
		bsr conputstr
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

		movem.l %a0,-(%sp)
		lea (newlinemsg,%pc),%a0
		bsr conputstr
		movem.l (%sp)+,%a0
.endif
.endm
