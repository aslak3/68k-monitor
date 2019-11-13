		.include "include/macros.i"
		.include "include/hardware.i"

		.equ MAGIC_O,		0
		.equ EOF_O,		0x04
		.equ VERSION_O,		0x08
		.equ DATA_OFFSET_O,	0x34
		.equ YM3812_CLOCK_O,	0x50

		.global vgmplayer
		.global opl2noteplay

		.section .text
		.align 2

| play the vgm block pointed to by a6

vgmplayer:	move.l MAGIC_O(%a6),%d0
		movea.l #magicmsg,%a1
		bsr labelprintlong

		move.l EOF_O(%a6),%d0
		bsr longswap
		movea.l #eofmsg,%a1
		bsr labelprintlong

		move.l VERSION_O(%a6),%d0
		bsr longswap
		movea.l #versionmsg,%a1
		bsr labelprintlong

		move.l YM3812_CLOCK_O(%a6),%d0
		bsr longswap
		movea.l #ym3812clockmsg,%a1
		bsr labelprintlong

		move.l DATA_OFFSET_O(%a6),%d0
		bsr longswap
		add.l #DATA_OFFSET_O,%d0
		move.l %a6,%d1
		add.l %d1,%d0
		move.l %d0,pointer
		movea.l #vgmdatamsg,%a1
		bsr labelprintlong
		move.w #1,running
		clr.w countdown
		rts

labelprintlong:	movea.l #printbuffer,%a0
		bsr strconcat
		bsr longtoascii
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat
		movea.l #printbuffer,%a0
		bsr putstr
		rts

		.section .rodata
		.align 2

magicmsg:	.asciz "Magic: "
eofmsg:		.asciz "EOF: "
versionmsg:	.asciz "Version: "
ym3812clockmsg:	.asciz "YM3812 Clock Hz: "
vgmdatamsg:	.asciz "VGM data starts at: "

		.section .text
		.align 2

| INTERRUPT

opl2noteplay:	tst.w running
		bne 1f
		rts
1:		movem.l %d0/%a0,-(%sp)
		move.w countdown,%d0
		beq 2f				| not counting down?
		subq.w #1,%d0			| yes, count down
		move.w %d0,countdown		| store for next time
		bra out2			| finished
2:		move.l pointer,%a0
again:		move.b (%a0)+,%d0
		cmpi.b #0x5a,%d0
		beq ym3812
		cmpi.b #0x61,%d0
		beq countn
		cmpi.b #0x62,%d0
		beq count735
		cmpi.b #0x63,%d0
		beq count882
		cmpi.b #0,%d0
		beq done
out1:		move.l %a0,pointer
out2:		movem.l (%sp)+,%d0/%a0
		rts

ym3812:		move.b (%a0)+,OPL2REGADDR
		move.w #0x20,%d0
1:		dbra %d0,1b
		move.b (%a0)+,OPL2DATA
		move.w #0x20,%d0
2:		dbra %d0,2b
		bra again

countn:		move.b (%a0)+,%d0		| bottom half
		lsl.w #8,%d0			| move up
		move.b (%a0)+,%d0		| top half
		ror.w #8,%d0			| byteswap
		move.w %d0,countdown		| save countdown value
		bra out1

count735:	move.w #735,countdown
		bra out1

count882:	move.w #882,countdown
		bra out1

done:		clr.w running			| stop playback
		bra out1

		.section .bss
		.align 2

running:	.space 2
pointer:	.space 4
countdown:	.space 2
