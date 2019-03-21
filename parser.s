		.align 2

		.include "include/ascii.i"

		.section .text

		.global parser

| parse the command string in a0, filling out a1 with the command name and
| chain of types will be in a2, with chains of values in a3.
|
| current types are 1=byte, 2=word, 3=long
|
| types are always words, values are always longs-guaranteed to be
| zero-paddeed. the end type will be 0.
|
| on exit, a1, a2 and a3 will point back at the start of the output buffers and a0
| will point at the end of the input string.
|
| on exit, d0 holds the count of found elements: 0 (error), 1 (command only)
| or >1 (command and params). zero will be set on error.

parser:		movem.l %d1-%d2/%a1-%a3,-(%sp)
		moveq.l #1,%d2			| assume at least command
1:		move.b (%a0)+,%d0		| get the current char
		beq _noparams			| done?
		cmpi.b #ASC_SP,%d0		| space?
		beq 2f				| hop over copy
		move.b %d0,(%a1)+		| copy this char
		bra 1b				| back copying the cmd
_noparams:	move.b #0,(%a1)+		| add a null for cmd 
		move.w #0,(%a2)+		| empty arg list
		bra _parserout			| cleanup
2:		move.b #0,(%a1)+		| add a null to end of cmd
3:		bsr asciitoint			| d0 int, d1 size
		beq _valueerror			| problem with this value?
		move.w %d1,(%a2)+		| add the type
		move.l %d0,(%a3)+		| add the value
		addq.b #1,%d2			| data counter		
		move.b (%a0)+,%d0		| hop over the space
		bne 3b				| back for more if not null
_parserout:	move.w #0,(%a2)+		| mark end of the params
		move.w %d2,%d0			| set the found data count
4:		movem.l (%sp)+,%d1-%d2/%a1-%a3
		rts
_valueerror:	move.w #0,%d0			| mark errored
		bra 4b
