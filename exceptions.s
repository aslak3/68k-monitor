		.include "include/hardware.i"
		.include "include/vectors.i"

		.global exceptionsinit
		.global exceptdetails

		.section .vectors
		.align 2

vectortable:	.space 256*4

		.section .text
		.align 2

| setup all the exception vectors; they al use the generic handler except for the
| ordinary entry on trap #0, the trace exception and the breakpoint trap #15
exceptionsinit:	movea.l #VBUSERROR,%a0		| setup the vector table
1:		cmpa.l #VMMUACCESSERROR,%a0	| look for the last vector
		beq.s 2f			| done all vectors?
		move.l #generichandler,(%a0)	| set generic handler
		adda.l #4,%a0			| next vector
		bra.s 1b			| loop back for next one

2:		move.l #entry,VTRAP0		| setup the vector for enterring monitor
		move.l #entry,VTRACE		| setup the vector for trace exceptions
		move.l #entry,VTRAP15		| setup the vector for breakpoints

		rts

| print the details of the exception from the stack frame pointed to by a6
exceptdetails:	move.w (6,%a6),%d0		| get format/vector
		and.w #0x0fff,%d0		| get vector number
		bsr getvectormsg		| get the message string for the vector
		bsr serputstr			| print it (eg "Bus error")
		lea (srmsg,%pc),%a0		| print SR label
		bsr serputstr
		move.w (0,%a6),%d0
		bsr serputword
		lea (pcmsg,%pc),%a0
		bsr serputstr
		move.l (2,%a6),%d0
		bsr serputlong
		lea (formvectormsg,%pc),%a0
		bsr serputstr
		move.w (6,%a6),%d0
		bsr serputword

		lea (newlinemsg,%pc),%a0
		bsr serputstr
		lea (newlinemsg,%pc),%a0
		bsr serputstr

		bsr printregs

		lea (newlinemsg,%pc),%a0
		bsr serputstr

		rts

| get the message for the given vector address in d0.w putting the result in a0
getvectormsg:	subq.w #8,%d0			| adjust to remove reset vectors
		move.l #vectmsgs,%a0		| base of vector messages
		add.l %d0,%a0			| point to resolved message
		move.l (%a0),%a0		| get the message address
		rts

generichandler:	move.b #0xff,LED		| turn on LED to show exception
		movea.l #portadevice,%a5	| point a5 to port a device
		movea.l #errormsg,%a0		| print error message opener
		bsr serputstr			| output it

		move.l %sp,%a6			| get stack pointer to access exception frame
		bsr exceptdetails		| print exception details

		lea (haltmsg,%pc),%a0
		bsr serputstr

9:		move.w #0xffff,%d0
		move.b #0,LED
10:		dbra %d0,10b
		move.w #0xffff,%d0
		move.b #0xff,LED
11:		dbra %d0,11b
		bra 9b

		.section .rodata
		.align 2

errormsg:	.asciz "\r\n*** "

haltmsg:	.asciz "*** System Halted ***\r\n"

srmsg:		.asciz " SR: "
pcmsg:		.asciz " PC: "
formvectormsg: 	.asciz " Format/Vector: "

vect2msg:	.asciz "Bus error"
vect3msg:	.asciz "Address error"
vect4msg:	.asciz "Illegal instruction"
vect5msg:	.asciz "Divide by zero"
vect6msg:	.asciz "CHK instruction"
vect7msg:	.asciz "TRAPV instruction"
vect8msg:	.asciz "Privilege violation"
vect9msg:	.asciz "Trace"
vect10msg:	.asciz "A-Line emulation"
vect11msg:	.asciz "F-Line emulation"
vect12msg:	.asciz "Reserved 0"
vect13msg:	.asciz "Coprocessor protocol violation"
vect14msg:	.asciz "Format error"
vect15msg:	.asciz "Uninitialized interrupt vector"
vect16msg:	.asciz "Reserved 1"
vect17msg:	.asciz "Reserved 2"
vect18msg:	.asciz "Reserved 3"
vect19msg:	.asciz "Reserved 4"
vect20msg:	.asciz "Reserved 5"
vect21msg:	.asciz "Reserved 6"
vect22msg:	.asciz "Reserved 7"
vect23msg:	.asciz "Reserved 8"
vect24msg:	.asciz "Spurious interrupt"
vect25msg:	.asciz "Level 1 autovector"
vect26msg:	.asciz "Level 2 autovector"
vect27msg:	.asciz "Level 3 autovector"
vect28msg:	.asciz "Level 4 autovector"
vect29msg:	.asciz "Level 5 autovector"
vect30msg:	.asciz "Level 6 autovector"
vect31msg:	.asciz "Level 7 autovector"
vect32msg:	.asciz "Trap #0"
vect33msg:	.asciz "Trap #1"
vect34msg:	.asciz "Trap #2"
vect35msg:	.asciz "Trap #3"
vect36msg:	.asciz "Trap #4"
vect37msg:	.asciz "Trap #5"
vect38msg:	.asciz "Trap #6"
vect39msg:	.asciz "Trap #7"
vect40msg:	.asciz "Trap #8"
vect41msg:	.asciz "Trap #9"
vect42msg:	.asciz "Trap #10"
vect43msg:	.asciz "Trap #11"
vect44msg:	.asciz "Trap #12"
vect45msg:	.asciz "Trap #13"
vect46msg:	.asciz "Trap #14"
vect47msg:	.asciz "Trap #15"
vect48msg:	.asciz "FPU Branch"
vect49msg:	.asciz "FPU Inexact Result"
vect50msg:	.asciz "FPU Divide by Zero"
vect51msg:	.asciz "FPU Underflow"
vect52msg:	.asciz "FPU Overflow"
vect53msg:	.asciz "FPU Operand Error"
vect54msg:	.asciz "FPU Singaling NaN"
vect55msg:	.asciz "FPU Unimplemented Data Type"
vect56msg:	.asciz "MMU Configuration Error"
vect57msg:	.asciz "MMU Illegal Operation Error"
vect58msg:	.asciz "MMU Access Error"

vectmsgs:	.long vect2msg
		.long vect3msg
		.long vect4msg
		.long vect5msg
		.long vect6msg
		.long vect7msg
		.long vect8msg
		.long vect9msg
		.long vect10msg
		.long vect11msg
		.long vect12msg
		.long vect13msg
		.long vect14msg
		.long vect15msg
		.long vect16msg
		.long vect17msg
		.long vect18msg
		.long vect19msg
		.long vect20msg
		.long vect21msg
		.long vect22msg
		.long vect23msg
		.long vect24msg
		.long vect25msg
		.long vect26msg
		.long vect27msg
		.long vect28msg
		.long vect29msg
		.long vect30msg
		.long vect31msg
		.long vect32msg
		.long vect33msg
		.long vect34msg
		.long vect35msg
		.long vect36msg
		.long vect37msg
		.long vect38msg
		.long vect39msg
		.long vect40msg
		.long vect41msg
		.long vect42msg
		.long vect43msg
		.long vect44msg
		.long vect45msg
		.long vect46msg
		.long vect47msg
		.long vect48msg
		.long vect49msg
		.long vect50msg
		.long vect51msg
		.long vect52msg
		.long vect53msg
		.long vect54msg
		.long vect55msg
		.long vect56msg
		.long vect57msg
		.long vect58msg



