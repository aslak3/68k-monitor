		.include "include/hardware.i"

		.section .text
		.align 2

		.global serialinit
		.global putstr
		.global getstr

serialinit:	move.b #0b00010011,XR88C681MR1B	| 8n
		move.b #0b00000111,XR88C681MR2B	| one full stop bit
		move.b #0b10111011,XR88C681CSRB	| 9600
		move.b #0b00000101,XR88C681CRB	| enable rx and tx
		rts

putstr:	move.w %d0,-(%sp)
1:		move.b (%a0)+,%d0		| get the byte to put
		beq 2f				| end of message, done
		bsr putchar			| output the char in d0
		bra 1b				| back for more
2:		move.w (%sp)+,%d0
		rts

| put the char in d0

putchar:	btst.b #2,XR88C681SRB		| busy sending last char?
		beq putchar			| yes, look again
		move.b %d0,XR88C681THRB		| put that byte
		rts

| get a str in a0

getstr:		move.w %d0,-(%sp)
1:		bsr getchar			| get a char
		bsr putchar			| echo it
		cmpi.b #0x0a,%d0		| lf?
		beq 2f				| match, done
		cmpi.b #0x0d,%d0		| cr?
		beq 2f				| match, done
		move.b %d0,(%a0)+		| save it to the str
		bra 1b				| next char
2:		move.b #0,(%a0)			| add a null
		move.w (%sp)+,%d0
		rts

| get a char in d0

getchar:	btst.b #0,XR88C681SRB		| chars?
		beq getchar			| no chars yet
		move.b XR88C681RHRB,%d0		| get it in d0
		rts

| get a char with a two second (ish) timeout, exit zero for got a char
| or non zero for timeout.

getcharwithto:	move.w #0xffff,%d0		| get timer
1:		sub.w #1,%d0			| dec timer
		beq 2f				| timeout reached
		btst.b #0,XR88C681SRB		| chars?
		beq 1b				| no chars yet
		move.b XR88C681RHRB,%d0		| get it in d0
		ori #0x04,%ccr			| set zero
		rts
2:		ori #0xfb,%ccr			| clear zero
		rts
