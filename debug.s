		.global d0msg
		.global d1msg
		.global d2msg
		.global d3msg
		.global d4msg
		.global d5msg
		.global d6msg
		.global d7msg

		.global a0msg
		.global a1msg
		.global a2msg
		.global a3msg
		.global a4msg
		.global a5msg
		.global a6msg
		.global a7msg

		.global monitormsg
		.global dissasmsg
		.global memorymsg
		.global listsmsg
		.global tasksmsg
		.global debuggermsg

		.global debugbuffer

		.section .rodata
		.align 2

d0msg:		.asciz " D0="
d1msg:		.asciz " D1="
d2msg:		.asciz " D2="
d3msg:		.asciz " D3="
d4msg:		.asciz " D4="
d5msg:		.asciz " D5="
d6msg:		.asciz " D6="
d7msg:		.asciz " D7="

a0msg:		.asciz " A0="
a1msg:		.asciz " A1="
a2msg:		.asciz " A2="
a3msg:		.asciz " A3="
a4msg:		.asciz " A4="
a5msg:		.asciz " A5="
a6msg:		.asciz " A6="
a7msg:		.asciz " A7="

monitormsg:	.asciz "MONITOR: "
memorymsg:	.asciz "MEMORY: "
listsmsg:	.asciz "LISTS: "
tasksmsg:	.asciz "TASKS: "
debuggermsg:	.asciz "DEBUGGER: "
dissasmsg:	.asciz "DISASSEMBLER: "

		.section .bss
		.align 2

debugbuffer:	.space 256
