		.include "include/hardware.i"

		.align 2
		.section .text

		.global setmemtolong
		.global cmpmemtolong

||| memory tests

setmemtolong:	move.l %d0,%d7
		movea.l #0x10000,%a0		| start at 64KB
		move.w #(((1024*1024)/4)/1024)-64,%d2
						| number of 64K long blocks
1:		move.w #1024-1,%d1		| 64K of long words
2:		move.l %d0,(%a0)+		| set to d1 value
		addq.l #1,%d0
                dbra %d1,2b			| back for more
                dbra %d2,1b			| next 64KB block
		move.l %d7,%d0
		move.w #1,LED
		rts

cmpmemtolong:	move.l %d0,%d7
		movea.l #0x10000,%a0		| start at 0
		move.w #(((1024*1024)/4)/1024)-64,%d2
						| number of 1K long blocks
1:		move.w #1024-1,%d1		| 64K of long words
2:		move.l (%a0)+,%d3		| see if match
		cmp.l %d0,%d3
		bne error
		addq.l #1,%d0
                dbra %d1,2b			| back for more
                dbra %d2,1b			| next 64KB block
		move.l %d7,%d0
		move.w #0,LED
		rts

error:		move.w #0xffff,LED
		move.w #0xff0,%d0
1:		dbra %d0,1b
		move.w #0,LED
		move.w #0xfff0,%d0
2:		dbra %d0,2b
		bra error
