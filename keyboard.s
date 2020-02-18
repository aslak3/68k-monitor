		.include "include/ascii.i"
		.include "include/hardware.i"

		.section .text
		.align 2

		.global keyboardinit
		.global putkeychar
		.global getkeychar

keyboardinit:	move.b #0b00010011,SCC68681MR1A	| 8n
		move.b #0b00000111,SCC68681MR2A	| one full stop bit
		move.b #0b10111011,SCC68681CSRA	| 9600
		move.b #0b00000101,SCC68681CRA	| enable rx and tx
		move.b #6,%d0
		bsr putkeychar
		rts

| put the char in d0

putkeychar:	btst.b #2,SCC68681SRA		| busy sending last char?
		beq putkeychar			| yes, look again
		move.b %d0,SCC68681THRA		| put that byte
		rts

| get a char in d0

getkeychar:	btst.b #0,SCC68681SRA		| chars?
		beq getkeychar			| no chars yet
		move.b SCC68681RHRA,%d0		| get it in d0
		rts
