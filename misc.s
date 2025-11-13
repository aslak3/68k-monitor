		.global wordswap
		.global longswap
		.global labelprintlong
		.global delay

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

| print the label in a0 with the long in d0 to the device in a5

labelprintlong:	movem.l %a0,-(%sp)
		bsr serputstr
		bsr serputlong
		lea (newlinemsg,%pc),%a0	| need a newline
		bsr serputstr
		movem.l (%sp)+,%a0
		rts

| loop round a dbra %d0.w times

delay:		move.w #0xffff,%d1
1:		dbra %d1,1b
		dbra %d0,delay
		rts
