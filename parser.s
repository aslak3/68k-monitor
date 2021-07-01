
		.include "include/ascii.i"

		.section .text
		.align 2

		.global parser
		.global checktypes

| parse the command string in a0, filling out a1 with the command name and
| chain of types will be in a2, with chains of values in a3.
|
| a4 will contain a chain of null terminated strings.
|
| current types are 1=byte, 2=word, 3=long, 0x80=string
|
| types are always words, values are always longs-guaranteed to be
| zero-paddeed. the end type will be 0.
|
| on exit, a1, a2 and a3 will point back at the start of the output buffers and a0
| will point at the end of the input string.
|
| on exit, d0 holds the count of found elements: 0 (error), 1 (command only)
| or >1 (command and params).

parser:		movem.l %d1-%d2/%a1-%a4,-(%sp)
		moveq.l #1,%d2			| assume at least command
1:		move.b (%a0)+,%d0		| get the current char
		beq noparams			| done?
		cmpi.b #ASC_SP,%d0		| space?
		beq 2f				| hop over copy
		move.b %d0,(%a1)+		| copy this char
		bra 1b				| back copying the cmd
noparams:	move.b #0,(%a1)+		| add a null for cmd 
		move.w #0,(%a2)+		| empty arg list
		bra parserout			| cleanup
2:		move.b #0,(%a1)+		| add a null to end of cmd
3:		cmp.b #'",(%a0)			| look for a double quote
		beq 5f				| handle the string
7:		bsr asciitoint			| d0 int, d1 size
		beq valueerror			| problem with this value?
		move.w %d1,(%a2)+		| add the type
		move.l %d0,(%a3)+		| add the value
		addq.b #1,%d2			| data counter		
		move.b (%a0)+,%d0		| hop over the space
		bne 3b				| back for more if not null
parserout:	move.w #0,(%a2)+		| mark end of the params
		move.w %d2,%d0			| set the found data count
4:		movem.l (%sp)+,%d1-%d2/%a1-%a4
		rts
5:		move.w #0x80,(%a2)+		| save the string type
		move.l %a4,(%a3)+		| save the start addr
		adda.l #1,%a0			| move past quote
8:		move.b (%a0)+,%d0		| copy a string byte
		cmp.b #'",%d0			| end of string?
		beq 6f				| no?
		tst.b %d0			| null?
		beq valueerror			| bad exit
		move.b %d0,(%a4)+		| save it
		bra 8b				| look for more
6:		clr.b (%a4)+			| add a null
		move.b (%a0)+,%d0		| advance and look for null
		beq parserout			| after quote was null		
		bra 3b				| back to slurping ints
valueerror:	move.w #0,%d0			| mark errored
		bra 4b

| check a parameter type list against a commands requirements.
|
| a0 should have the types that should be checked (the command inputs), and
| a1 should have the commands maximum data size list.
|
| the top bit in the command maximum is special: if it is set then this is
| the last type is a varag: the rest of the types must all match this one
|
| if a checked type is of greater size then the command's maximum, the
| valdation will fail and d0 will be 1 on exit, otherwise it will be 0.
| on exit a0 will be restored, allowing the caller to access the arg list.

checktypes:	movem.l %a0/%d1,-(%sp)
1:		move.w (%a0)+,%d0		| get the inputed type
		beq 3f				| check other end is null
		move.w (%a1),%d1		| read in the req
		bclr #15,%d1			| test and clear top bit
		bne 6f				| skip incremenet of a1
		adda.l #2,%a1			| move to next test type
		btst #7,%d1			| see if integer type
		bne 7f				| no, check for exact match 
6:		cmp.w %d1,%d0			| compare with requirement
		bgt 2f				| see if a1>a0
		bra 1b				| back for more
7:		cmp.w %d1,%d0			| compare with requirement
		beq 1b				| yes, same so back for more
2:		moveq.l #1,%d0			| bad
		bra 5f				| and out
3:		move.w (%a1),%d1		| read in requirement
		btst #15,%d1			| test high bit
		bne 4f				| vararg, so good
		tst.w (%a1)			| at the com max list end?
		bne 2b				| no, this is bad
4:		clr.l %d0			| good
5:		movem.l (%sp)+,%a0/%d1
		rts
