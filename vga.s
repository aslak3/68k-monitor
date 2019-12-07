		.include "include/ascii.i"
		.include "include/hardware.i"

		.global vgainit
		.global vgaputchar
		.global vgaputstr

		.section .text
		.align 2

vgainit:	bsr vgaclear			| just a clear
		rts

vgaclear:	movem.w %d0-%d1,-(%sp)
		clr.b %d1			| doing lots of clearing
		move.w #65535-1,%d0		| clear 64KB worth
		move.b %d1,VGAWRITEADDRHI	| clr will read. :(
		move.b %d1,VGAWRITEADDRLO	| clr will read. :(
1:		move.b %d1,VGADATA		| ditto
		dbra %d0,1b			| back for more
		move.b %d1,VGAWRITEADDRHI	| clr will read. :(
		move.b %d1,VGAWRITEADDRLO	| clr will read. :(
		clr.w row			| top
		clr.w column			| left
		move.b %d1,VGAOFFSETADDRHI	| clr will read. :(
		move.b %d1,VGAOFFSETADDRLO	| clr will read. :(
		move.b #0x0f,VGACONFIG		| white on black
		movem.w (%sp)+,%d0-%d1
		rts

| scrolling approach is to hardware scroll one screen worth, then copy.
| 1. row before row 60: do nothing
| 2. row before row 120: move offset to 60-row
| 3. otherwise:
| 3a. read in bottom (newest) scren
| 3b. copy it to the top screen
| 3c. fill the old bottom screen with empty data
| 3d. move the display (offset) to the top
| 3e. with the curor on the bottom row
| 3f. user not aware that aything interesting has happened

vgaseekscroll:	movem.l %d0-%d1/%a0,-(%sp)

		move.w row,%d0			| get the current row
		subi.w #59,%d0			| offset into 2nd screen?
		ble vgaseekscrollo		| no, then out
		mulu.w #80,%d0			| 80 cols in a row
		movea.l #VGAOFFSETADDRHI,%a0	| load pointer for offset
		movep.w %d0,(0,%a0)		| one hit!
		move.w row,%d0			| get offset again		
		subi.w #60+59,%d0		| bottom of 2nd screen?
		ble vgaseekscrollo		| no, then out

		movea.l #VGAREADADDRHI,%a0	| load pointer for reading
		move.w #80*60,%d0		| copying 2nd screen
		movep.w %d0,(0,%a0)		| move there
		move.b VGADATA,%d1		| dummy read!
		movea.l #scrollbuffer,%a0	| copying to the buffer
		move.w #80*60-1,%d1		| need that many bytes, too
1:		move.b VGADATA,(%a0)+		| read one byte
		dbra %d1,1b			| back for more copying

		movea.l #VGAWRITEADDRHI,%a0	| load pointer for writing
		clr.w %d0			| writing to 1st screen
		movep.w %d0,(0,%a0)		| move there
		movea.l #scrollbuffer,%a0	| copying to the buffer
		move.w #80*60-1,%d1		| need that many bytes, too
2:		move.b (%a0)+,VGADATA		| write one byte
		dbra %d1,2b			| back for more copying
		move.w #80*60-1,%d1		| need that many bytes, too
		clr.b %d0			| need to clear next screen
3:		move.b %d0,VGADATA		| read one byte
		dbra %d1,3b			| back for more copying

		movea.l #VGAOFFSETADDRHI,%a0	| load pointer for writing
		move.w #0,%d0			| bottom of 1st screen
		movep.w %d0,(0,%a0)		| move there
		move.w #60,row			| reset scroll offset

vgaseekscrollo:	movem.l (%sp)+,%d0-%d1/%a0
		rts

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
|		bsr putchar			| send to serial too
		cmp.b #ASC_CR,%d0		| look for carriage return
		beq handlecr			| yes? handle it
		cmp.b #ASC_LF,%d0		| look for line feed
		beq handlelf			| yes? handle it
		cmp.b #ASC_BS,%d0		| look for back space
		beq handlebs			| yes? handle it
		cmp.b #ASC_FF,%d0		| look for form feed (clear)
		beq handleff			| yes? handle it
		cmp.b #ASC_BEL,%d0		| look for bell character
		beq handlebell			| yes? handle it
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

handlebell:	move.b #0,VGACONFIG		| red background
		move.w #65535-1,%d1		| delay init
1:		dbra %d1,1b			| wait for a bit
		move.b #0x0f,VGACONFIG		| back to white on black
		bra vgaputcharo

		.section .bss
		.align 2

row:		.space 2			| 0->available memory
column:		.space 2			| 0->79
scrollrow:	.space 2			| 0->available memory
scrollbuffer:	.space 80*60			| one screen worth
