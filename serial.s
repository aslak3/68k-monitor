 		.include "include/ascii.i"
		.include "include/hardware.i"

		.section .text
		.align 2

                .global conputchar
                .global conputstr
                .global congetchar
                .global congetstr

		.global serialinit
		.global serputstr
		.global sergetstr
		.global serputchar
		.global sergetchar
		.global dlgetchar
		.global dlputchar
		.global dlputstr

serialinit:	move.b #0b10000011,LCR16C654+BASEPA
		move.b #0x0c,DLL16C654+BASEPA	| 38.4k
		move.b #0,DLM16C654+BASEPA
		move.b #0b00000011,LCR16C654+BASEPA

		move.b #0b10000011,LCR16C654+BASEPB
		move.b #0x0c,DLL16C654+BASEPB	| 38.4k
		move.b #0,DLM16C654+BASEPB
		move.b #0b00000011,LCR16C654+BASEPB
		rts

conputstr:
serputstr:	move.w %d0,-(%sp)
1:		move.b (%a0)+,%d0		| get the byte to put
		beq 2f				| end of message, done
		bsr serputchar			| output the char in d0
		bra 1b				| back for more
2:		move.w (%sp)+,%d0
		rts

| put the char in d0

conputchar:
serputchar:	btst.b #5,LSR16C654+BASEPA	| busy sending last char?
		beq serputchar			| yes, look again
		move.b %d0,THR16C654+BASEPA	| put that byte
		rts

| get a str in a0

congetstr:
sergetstr:	movem.l %d0-%d1/%a0,-(%sp)	
		clr.w %d1			| set the length to 0
getstrloop:	bsr sergetchar			| get a char in a
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
getstrecho:	bsr serputchar			| echo it
		bra getstrloop			| get more
getstrout:	move.b #0,(%a0)+		| add a null
		movea.l #newlinemsg,%a0		| tidy up ...
		bsr serputstr			| ... with a newline
		movem.l (%sp)+,%d0-%d1/%a0
		rts
getstrbs:	tst.w %d1			| see if the char count is 0
		beq getstrloop			| do nothing if already zero
		subq.w #1,%d1			| reduce count by 1
		move.b #0,(%a0)			| null the current char
		suba.l #1,%a0			| move the pointer back 1
		move.b #ASC_BS,%d0		|  move cursor back one
		bsr serputchar
		move.b #ASC_SP,%d0		| then erase and move forward
		bsr serputchar
		move.b #ASC_BS,%d0		| then back one again
		bsr serputchar
		bra getstrloop			| echo the bs and charry on

| get a char in d0

congetchar:
sergetchar:	btst.b #0,LSR16C654+BASEPA	| chars?
		beq sergetchar			| no chars yet
		move.b RHR16C654+BASEPA,%d0	| get it in d0
		rts

|||

dlputchar:	btst.b #5,LSR16C654+BASEPB	| busy sending last char?
		beq dlputchar			| yes, look again
		move.b %d0,THR16C654+BASEPB	| put that byte
		rts

dlgetchar:	btst.b #0,LSR16C654+BASEPB	| chars?
		beq dlgetchar			| no chars yet
		move.b RHR16C654+BASEPB,%d0	| get it in d0
		rts

dlputstr:	move.w %d0,-(%sp)
1:		move.b (%a0)+,%d0		| get the byte to put
		beq 2f				| end of message, done
		bsr dlputchar			| output the char in d0
		bra 1b				| back for more
2:		move.w (%sp)+,%d0
		rts
