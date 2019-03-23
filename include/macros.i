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
		.align 2
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
		.align 2
		.long name_\name		| name pointer
		.long com_\name			| command descriptor
.endm

.macro endcommand
		.long 0x0
		.long 0x0			| vital!
.endm
