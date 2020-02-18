		.align 2

		.include "include/hardware.i"

		.section .text

		.global sendspiword

| send the word in d0.w with the slave selected

| enable, clock, data

sendspiword:	clr.b %d3			| make a zero
		move.b #0b00000100,%d1		| enable high
		move.b %d1,SPI
		eori.b #0b00000100,%d1		| enable low
		move.b %d1,SPI

		move.w #16-1,%d2		| 16 bits to shift
1:		move.b #0b00000000,%d1		| enable low
		lsl.w #1,%d0			| get the bit
		addx.b %d3,%d1 			| add shifted data to mosi
		move.b %d1,SPI			| clock low with data
		eori.b #0b00000010,%d1		| flip the clock
		move.b %d1,SPI			| clock high with data
		dbra %d2,1b			| more bits?

		move.b #0b00000000,%d1		| enable still low
		move.b %d1,SPI
		move.b #0b00000100,%d1		| enable high
		move.b %d1,SPI
		
		rts
		