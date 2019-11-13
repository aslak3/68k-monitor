		.global wordswap
		.global longswap

		.section .text
		.align 2

| wordswap - swap the word in d0

wordswap:	ror.w #8,%d0
		rts


| longswap - endian swap the long in %d0

longswap:	ror.w #8,%d0		| swap the rightmost word
		swap %d0		| swap the long
		ror.w #8,%d0		| swap the rightmost word again
		rts

