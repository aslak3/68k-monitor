		.include "include/hardware.i"

		.align 2
		.section .text

		.global memtester

||| memory tests, jump target

| d1 has the size of the test, which will be from 0, must be /4.

memtester:	move.l #0x0001,%d0
		movec.l %d0,%cacr

		add.l #0xfedcba98,%d0
		move.l %d1,%d6			| save end address

setmemtolong:	move.l %d0,%d7			| save the pattern
		movea.l %d2,%a0			| start at 0

1:		move.l %d0,(%a0)+		| set to d1 value
		addq.l #1,%d0			| inc pattern
		subq.l #4,%d1			| dec x4 addr to go
		bne 1b

		move.l %d7,%d0			| get pattern back
		move.b #1,LED

||||

		move.l %d6,%d1			| get end address back
		movea.l %d2,%a0			| start at 0

1:		move.l (%a0)+,%d3		| see if match
		cmp.l %d0,%d3
		bne error
		addq.l #1,%d0			| next pattern
		subq.l #4,%d1
		bne 1b

		move.b #0,LED

		move.l %d6,%d1			| get end address back


||||| WORD

		add.l #0xfedcba98,%d0
		move.l %d1,%d6			| save end address

		move.l %d0,%d7			| save the pattern
		movea.l %d2,%a0			| start at 0

1:		move.w %d0,(%a0)+		| set to d1 value
		addq.l #1,%d0			| inc pattern
		subq.l #2,%d1			| dec x4 addr to go
		bne 1b

		move.l %d7,%d0			| get pattern back
		move.b #1,LED

||||

		move.l %d6,%d1			| get end address back
		movea.l %d2,%a0			| start at 0

1:		move.w (%a0)+,%d3		| see if match
		cmp.w %d0,%d3
		bne error
		addq.l #1,%d0			| next pattern
		subq.l #2,%d1
		bne 1b

		move.b #0,LED

		move.l %d6,%d1			| get end address back


||||| BYTE

		add.l #0xfedcba98,%d0
		move.l %d1,%d6			| save end address

		move.l %d0,%d7			| save the pattern
		movea.l %d2,%a0			| start at 0

1:		move.b %d0,(%a0)+		| set to d1 value
		addq.l #1,%d0			| inc pattern
		subq.l #1,%d1			| dec x4 addr to go
		bne 1b

		move.l %d7,%d0			| get pattern back
		move.b #1,LED

||||

		move.l %d6,%d1			| get end address back
		movea.l %d2,%a0			| start at 0

1:		move.b (%a0)+,%d3		| see if match
		cmp.b %d0,%d3
		bne error
		addq.l #1,%d0			| next pattern
		subq.l #1,%d1
		bne 1b

		move.b #0,LED

		move.l %d6,%d1			| get end address back

		bra memtester

error:		move.b #0x80,BUZZER
		move.b #0xff,LED
		move.w #0x0ff0,%d0
1:		dbra %d0,1b
		move.b #0,LED
		move.w #0xfff0,%d0
2:		dbra %d0,2b
		bra error
