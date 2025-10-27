		.include "include/ascii.i"
		.include "include/hardware.i"

		.global vgainit

		.global conclear
		.global conputchar
		.global conputstr
		.global attributes

		.section .text
		.align 2

vgainit:	clr.l %d2
		bsr conclear			| just a clear
		move.b #0x00,attributes		| use vga impl default
		rts

conclear:	movem.w %d0-%d1,-(%sp)
		clr.l %d1			| used for 0 
		move.w #65536/4-1,%d0		| clear all 64KB
		move.l %d1,VGARWADDRLO		| clr will read. :(
1:		swap.w %d2
		move.w %d2,VGADATA		| character
		swap.w %d2
		move.w %d2,VGADATA		| character
		dbra %d0,1b			| back for more
		move.l %d1,VGARWADDRLO		| clr will read. :(
		clr.w row			| top
		clr.w column			| left
		movem.w (%sp)+,%d0-%d1
		rts

| scrolling approach is to hardware scroll one screen worth, then copy.
| 1. row before row 60: do nothing
| 2. row before row 120: move offset to 60-row
| 3. otherwise:
| 3a. read in bottom (newest) scren
| 3b. copy it to the top screen
| 3c. move the display (offset) to the top
| 3d. fill the old bottom screen with empty data
| 3e. with the curor on the bottom row
| 3f. user not aware that aything interesting has happened

vgascroll:	movem.l %d0-%d2/%a0,-(%sp)
		movea.l #VGADATA,%a1

		move.w row,%d0			| get the current row
		subi.w #59,%d0			| offset into 2nd screen?
		ble vgascrollo			| no, then out
		mulu.w #80*2,%d0		| 80 cols in a row
		move.w %d0,VGAOFFSETADDRLO	| one hit!
		move.w row,%d0			| get offset again
		subi.w #60+59,%d0		| bottom of 2nd screen?
		ble vgascrollo			| no, then out

		move.w #80*2*60,%d0		| copying 2nd screen
		move.w %d0,VGARWADDRLO		| move there
		move.w (%a1),%d1		| dummy read!
		movea.l #scrollbuffer,%a0	| copying to the buffer
		move.w #80*60-1,%d1		| need that many words, too
1:		move.w (%a1),(%a0)+		| read one word
		dbra %d1,1b			| back for more copying

		clr.w %d0			| writing to 1st screen
		move.w %d0,VGARWADDRLO		| move there
		movea.l #scrollbuffer,%a0	| copying to the buffer
		move.w #80*60-1,%d1		| need that many words, too
2:		move.w (%a0)+,(%a1)		| write one word
		dbra %d1,2b			| back for more copying

		move.w #0,%d0			| bottom of 1st screen
		move.w %d0,VGAOFFSETADDRLO	| move there
		move.w #60,row			| reset scroll offset

		move.w #80*60-1,%d2		| need that many chars, too
		clr.b %d0			| need to clear next screen
		move.b attributes,%d0		| get current attribute
		ror.w #8,%d0			| rotate
3:		move.w %d0,(%a1)		| clear one byte (char)
		dbra %d2,3b			| back for more copying

vgascrollo:	movem.l (%sp)+,%d0-%d2/%a0
		rts

vgaseek:	movem.l %d0-%d1/%a0,-(%sp)
		move.w row,%d1			| get the row
		mulu.w #80*2,%d1		| 80 columns in a row
		move.w column,%d0		| get column number
		lsl.w #1,%d0			| attribute byte factoring
		add.w %d0,%d1			| and add the column
		move.w %d1,VGARWADDRLO	| one hit!
		movem.l (%sp)+,%d0-%d1/%a0
		rts

conputstr:	move.w %d0,-(%sp)
1:		move.b (%a0)+,%d0		| get the byte to send
		beq 2f				| null? done 
		bsr conputchar			| send that byte
		bra 1b				| back for more
2:		move.w (%sp)+,%d0
		rts

| vgaputstr - write the character in %d0

conputchar:	movem.l %d0-%d1/%a0,-(%sp)
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
		ror.w #8,%d0
		move.b attributes,%d0
		ror.w #8,%d0
		move.w %d0,VGADATA		| output the byte (printable)
		addq.w #1,column		| increment the column
		cmp.w #80,column		| check for right margin
		beq newlineneeded		| yes? need a new line
vgaputcharo:	movem.l (%sp)+,%d0-%d1/%a0
		rts

updateout:	bsr vgaseek			| move the cursor
		bra vgaputcharo			| done

handlecr:	clr.w column			| reset to left column
		bra updateout			| move the cursor and out

newlineneeded:	clr.w column			| move to left coloumn
handlelf:	addq.w #1,row			| increment row
		bsr vgascroll			| do scroll action
		bra updateout			| move the cursor and out

handlebs:	subq.w #1,column		| left one column
		bpl updateout			| not left most? out
oldlineneeded:	subq.w #1,row			| back one row then
		move.w #79,column		| and move to right most col
		bra updateout			| move the cursor and out

handleff:	bsr conclear			| clear the screen and home
		bra vgaputcharo			| no need to move cursor

handlebell:|	move.b #0,VGACOLOURS		| red background
		move.w #65535-1,%d1		| delay init
1:		dbra %d1,1b			| wait for a bit
|		move.b #0x0f,VGACOLOURS		| back to white on black
		bra vgaputcharo

		.section .bss
		.align 2

row:		.space 2			| 0->available memory
column:		.space 2			| 0->79
scrollrow:	.space 2			| 0->available memory
scrollbuffer:	.space 80*2*60			| one screen worth
attributes:	.space 1			| next attrib
