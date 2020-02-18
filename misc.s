		.global wordswap
		.global longswap
		.global labelprintlong

		.section .text
		.align 2

| wordswap - swap the word in d0

wordswap:	ror.w #8,%d0
		rts


| longswap - endian swap the long in %d0

longswap:	ror.w #8,%d0			| swap the rightmost word
		swap %d0		 	| swap the long
		ror.w #8,%d0			| swap the rightmost word again
		rts

labelprintlong:	movem.l %a0,-(%sp)
		movea.l #printbuffer,%a0
		bsr strconcat
		bsr longtoascii
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat
		movea.l #printbuffer,%a0
		bsr vgaputstr
		movem.l (%sp)+,%a0
		rts
