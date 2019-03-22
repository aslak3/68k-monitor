.macro checkcommand name,maxtypes:vararg
		.section .rodata.com.name
name_\name:	.asciz "\name"
		.section .rodata.com.maxtypes
maxtypes_\name:	.word \maxtypes	
		.section .rodata.com
com_\name:	.long \name			| handler pointer
		.long maxtypes_\name		| list of maxtypes pointer
		.section .rodata
		.long name_\name		| name pointer
		.long com_\name			| command descriptor
.endm

.macro nocheckcommand name
		.section .rodata.com.name
name_\name:	.asciz "\name"
		.section .rodata.com
com_\name:	.long \name			| handler pointer
		.long 0				| list of maxtypes pointer
		.section .rodata
		.long name_\name		| name pointer
		.long com_\name			| command descriptor
.endm

.macro endcommand
		.long 0x0
		.long 0x0			| vital!
.endm
