.macro insertcommand command
		.section .rodata.commands
cmd\command:	.asciz "\command"
		.section .rodata
		.long cmd\command
		.long \command
.endm

.macro endcommand
		.long 0x0
		.long 0x0			| vital!
.endm
