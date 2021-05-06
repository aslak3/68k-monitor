		.include "include/hardware.i"

		.align 2
		.section .text

		.global vsetmemtoword
		.global vcmpmemtoword

||| memory tests

vsetmemtoword:	move.l %d0,%d7
		move.l #0,VGARWADDRHI		| start at the start
		move.w #(((1024*1024)/2)/1024)-1,%d2
						| number of 1024 word blocks
1:		move.w #1024-1,%d1		| 1024 words
2:		move.w %d0,VGADATA		| set to d1 value
		addq.w #1,%d0
                dbra %d1,2b			| back for more
                dbra %d2,1b			| next 64KB block
		move.l %d7,%d0
		move.w #1,LED
		rts

vcmpmemtoword:	move.w %d0,%d7
		move.l #0,VGARWADDRHI
		move.w VGADATA,%d6		| dummy
		move.w #(((1024*1024)/2)/1024)-1,%d2
						| number of 1024 word blocks
1:		move.w #1024-1,%d1		| 1024 words		
2:		move.w VGADATA,%d3		| see if match
		cmp.w %d0,%d3
		bne error
		addq.w #1,%d0
                dbra %d1,2b			| back for more
                dbra %d2,1b			| next 64KB block
		move.w %d7,%d0
		move.w #0,LED
		rts

error:		move.w #0xffff,LED
		move.w #0xff0,%d0
1:		dbra %d0,1b
		move.w #0,LED
		move.w #0xfff0,%d0
2:		dbra %d0,2b
		bra error
