		.include "include/ascii.i"
		.include "include/hardware.i"

		.global vgainit
		.global vgaputchar
		.global vgaputstr
		.global vgaup
		.global vgadown

		.section .text
		.align 2

vgainit:	bsr vgaclear			| just a clear
		rts

vgaclear:	move.w %d0,-(%sp)
		move.w #80*60*6-1,%d0		| clear six screens worth
		move.b #0,VGAWRITEADDRHI	| clr will read. :(
		move.b #0,VGAWRITEADDRLO	| clr will read. :(
1:		move.b #0,VGADATA		| ditto
		dbra %d0,1b			| back for more
		move.b #0,VGAWRITEADDRHI	| clr will read. :(
		move.b #0,VGAWRITEADDRLO	| clr will read. :(
		clr.w row			| top
		clr.w column			| left
		clr.w scrollrow			| no scroll offset
		bsr vgaseekscroll		| move the cursor
		move.w (%sp)+,%d0
		rts

vgaseekscroll:	movem.l %d0/%a0,-(%sp)
		move.w row,%d0			| get the current row
		add.w scrollrow,%d0		| add he scroll offset
		subi.w #59,%d0			| offset into 2nd screen?
		ble 1f				| no, then out
		mulu.w #80,%d0			| 80 cols in a row
2:		movea.l #VGAOFFSETADDRHI,%a0	| load pointer
		movep.w %d0,(0,%a0)		| one hit!
vgaseekscrollo:	movem.l (%sp)+,%d0/%a0
		rts
1:		clr.w %d0
		bra 2b

vgaseek:	movem.l %d1/%a0,-(%sp)
		move.w row,%d1			| get the row
		mulu.w #80,%d1			| 80 columns in a row
		add.w column,%d1		| and add the column
		movea.l #VGAWRITEADDRHI,%a0	| load pointer
		movep.w %d1,(0,%a0)		| one hit!
		movem.l (%sp)+,%d1/%a0
		rts


vgaputstr:	move.w %d0,-(%sp)
1:		move.b (%a0)+,%d0		| get the byte to send
		beq 2f				| null? done 
		bsr vgaputchar			| send that byte
		bra 1b				| back for more
2:		move.w (%sp)+,%d0
		rts

| vgaputstr - write the character in %d0

vgaputchar:	movem.l %d0/%a0,-(%sp)
		cmp.b #ASC_CR,%d0		| look for carriage return
		beq handlecr			| yes? handle it
		cmp.b #ASC_LF,%d0		| look for line feed
		beq handlelf			| yes? handle it
		cmp.b #ASC_BS,%d0		| look for back space
		beq handlebs			| yes? handle it
		cmp.b #ASC_FF,%d0		| look for form feed (clear)
		beq handleff			| yes? handle it
		btst.b #7,%d0			| high bit set
		bne vgaputcharo			| yes? ignor this write
		cmp.b #ASC_SP,%d0		| unknown control code?
		blt vgaputcharo			| ignore it
		move.b %d0,VGADATA		| output the byte (printable)
		addq.w #1,column		| increment the column
		cmp.w #80,column		| check for right margin
		beq newlineneeded		| yes? need a new line
vgaputcharo:	movem.l (%sp)+,%d0/%a0
		rts

updateout:	bsr vgaseek			| move the cursor
		bra vgaputcharo			| done

handlecr:	clr.w column			| reset to left column
		bra updateout			| move the cursor and out

newlineneeded:	clr.w column			| move to left coloumn
handlelf:	addq.w #1,row			| increment row
		bsr vgaseekscroll		| do scroll action
		bra updateout			| move the cursor and out

handlebs:	subq.w #1,column		| left one column
		bpl updateout			| not left most? out
oldlineneeded:	subq.w #1,row			| back one row then
		move.w #79,column		| and move to right most col
		bra updateout			| move the cursor and out

handleff:	bsr vgaclear			| clear the screen and home
		bra vgaputcharo			| no need to move cursor

vgaup:		subq.w #1,scrollrow		| dec scroll counter
		bsr vgaseekscroll		| update
		rts

vgadown:	addq.w #1,scrollrow		| inc scroll counter
		bsr vgaseekscroll		| update
		rts

		.section .bss
		.align 2

row:		.space 2			| 0->available memory
column:		.space 2			| 0->79
scrollrow:	.space 2			| 0->available memory
