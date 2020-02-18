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
		movea.l #VGAWRITEADDRHI,%a1	| setup write ptr reg
		movea.l #VGAOFFSETADDRHI,%a2	| setup offset ptr reg
		move.b #1,VGAMODE1		| set bitmap mode!
		move.w #80*60*2,%d0		| get where data goes
		movep.w %d0,(0,%a1)		| set write pointer
		movep.w %d0,(0,%a2)		| set offset
		adda.l #(640/8)*479,%a0		| move to last line
		move.w #480-1,%d1		| this number of lines
1:		move.w #(640/8)-1,%d0		| this length line
2:		move.b (%a0)+,VGADATA		| push a byte
		dbra %d0,2b			| back for more
		suba.l #(640/8)*2,%a0		| to the next line
		dbra %d1,1b			| and jump, if more to do
		bsr getchar			| wait for a key
		move.w #80*60*2,%d0		| top of the pic
		move.w #480-1,%d1
1:		movep.w %d0,(0,%a2)		| set offset
		addi.w #640/8,%d0		| move it a line
		move.w #0x1000,%d2		| setup delay
2:		dbra %d2,2b			| delay loop
		dbra %d1,1b			| next line
		bsr vgaclear
		rts

		.section .ronly
		.align 2

bmpoffsetmsg:	.asciz "BMP data begins: "
