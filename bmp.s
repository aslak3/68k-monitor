		.include "include/hardware.i"

| these are the header structure offsets

		.equ MAGIC_O,		0
		.equ DATA_OFFSET_O,	0xa

		.global bmpshow

		.section .text
		.align 2

bmpshow:	move.l DATA_OFFSET_O(%a0),%d0	| get offset of pixel data
		bsr longswap			| big endian swap
		movea.l #bmpoffsetmsg,%a1	| for the message
		bsr labelprintlong		| print the offset
		adda.l %d0,%a0			| get start of data
		movea.l #VGADATA,%a1		| setup write ptr reg
		move.w #0,VGAOFFSETADDR
		move.w #0,VGARWADDRLO
		move.w #480-1,%d1		| this number of lines
1:		move.w #(640/8/2)-1,%d0		| this length line
2:		move.w (%a0)+,%d2
		move.w %d2,(%a1)		| push a word
		move.w #0,(%a1)
		dbra %d0,2b			| back for more
		dbra %d1,1b			| and jump, if more to do
		bsr congetchar			| wait for a key
		bsr conclear
		rts

		.section .ronly
		.align 2

bmpoffsetmsg:	.asciz "BMP data begins: "
