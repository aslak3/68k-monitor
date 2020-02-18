		.include "include/ascii.i"
		.include "include/hardware.i"

		.section .text
		.align 2

		.global serialinit
		.global putstr
		.global getstr
		.global putchar
		.global getchar

serialinit:	move.b #0b00010011,XR88C681MR1B	| 8n
		move.b #0b00000111,XR88C681MR2B	| one full stop bit
		move.b #0b10111011,XR88C681CSRB	| 9600
		move.b #0b00000101,XR88C681CRB	| enable rx and tx
		rts

putstr:		move.w %d0,-(%sp)
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

getstr:		movem.l %d0-%d1/%a0,-(%sp)	
		clr.w %d1			| set the length to 0
getstrloop:	bsr getchar			| get a char in a
		cmp.b #ASC_CR,%d0		| cr?
		beq getstrout			| if it is, then out
		cmp.b #ASC_LF,%d0		| lf?
		beq getstrout			| if it is, then out
		cmp.b #ASC_BS,%d0		| backspace pressed?
		beq getstrbs			| handle backspace
		cmp.b #ASC_SP,%d0		| less then space ...
		blo getstrloop			| ... ignore, and get another
		btst.b #7,%d0			| top bit set?
		bne getstrloop			| .... ignore (cursor etc)
		move.b %d0,(%a0)+		| add it to string
		addq.w #1,%d1			| increment the number of chars
getstrecho:	bsr vgaputchar			| echo it
		bra getstrloop			| get more
getstrout:	move.b #0,(%a0)+		| add a null
		movea.l #newlinemsg,%a0		| tidy up ...
		bsr vgaputstr			| ... with a newline
		movem.l (%sp)+,%d0-%d1/%a0
		rts
getstrbs:	tst.w %d1			| see if the char count is 0
		beq getstrloop			| do nothing if already zero
		subq.w #1,%d1			| reduce count by 1
		move.b #0,(%a0)			| null the current char
		suba.l #1,%a0			| move the pointer back 1
		move.b #ASC_BS,%d0		|  move cursor back one
		bsr vgaputchar
		move.b #ASC_SP,%d0		| then erase and move forward
		bsr vgaputchar
		move.b #ASC_BS,%d0		| then back one again
		bsr vgaputchar
		bra getstrloop			| echo the bs and charry on

| get a char in d0

getchar:	btst.b #0,XR88C681SRB		| chars?
		beq getchar			| no chars yet
		move.b XR88C681RHRB,%d0		| get it in d0
getcharo:	rts


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
