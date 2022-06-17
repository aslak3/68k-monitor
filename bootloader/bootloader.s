		.align 2

		.include "../include/hardware.i"

		.equ ROMB, _rom_start

		.section .vectors, #alloc

resetsp:	.long 0x00008000		| the initial sp
resetpc:	.long _start			| the initial pc

		.section .text

_start:		|move.b #0x00,SYSCONF		| write protect eeprom

|		move.w #0xffff,LED
|		move.l #0,%d0
|		bsr setmemtolong
|		move.w #0,LED
|		bsr cmpmemtolong

		move.b #0x05, CR26C94+BASEPB	| enable tx and rx
		move.b #0b00010011, MRX26C94+BASEPB | 8 bit, no parity
		move.b #0x07, MRX26C94+BASEPB	|  1 stop bit
		move.b #0xcc, CSR26C94+BASEPB	| 38.4kbaud

		move.b #1,SPIDATA

|		movea.l #hellomsg,%a0
|		bsr putstring

		move.b #2,SPIDATA

		move.b #0x00,LED
		move.b #0x00,BUZZER

		movea.l #_rom_start,%a0		| get the start of rom
		movea.l #ramcopy,%a1		| get where to copy it to
		move.w #8192/4-1,%d0		| copy 2048 times
1:		move.l (%a0)+,(%a1)+		| copy longs
		dbra %d0,1b			| back for more

		move.b #3,SPIDATA

		move.b #0x01,LED
		move.b #0x40,BUZZER

		move.l #begin,%d0
		sub.l #_rom_start,%d0
		add.l #ramcopy,%d0
		move.l %d0,%a0

		move.b #4,SPIDATA

		jmp (%a0)

begin:		move.b #5,SPIDATA

		move.b #0x00,BUZZER

		move.b #6,SPIDATA

		|lea resetmsg(%pc),%a0		| grab the greeting in a0
		movea.l #resetmsg,%a0
		bsr putstring			| send it

		move.b #7,SPIDATA

		bsr getcharwithto		| get a char with timeout
		bne normalstart			| timeout so normal start
		cmp.b #'f',%d0			| is it an f?
		beq flasher			| yes, so do the flashing

normalstart:	move.b #0x00,LED
		jmp realrom			| jump after bootloader code

flasher:	bsr getchar			| highbyte of page count
		move.b %d0,%d2			| move into d2
		asl.w #8,%d2			| shift into high byte
		bsr getchar			| lowbyte of pagecount
		move.b %d0,%d2			| move into lowbyte of d2
		sub.w #1,%d2			| we are using dbra so -1

		move.b #0x00,BUZZER		| turn of buzzer now
		|lea flashreadymsg(%pc),%a0	| tell other end that ...
		movea.l #flashreadymsg,%a0
		bsr putstring			| ... we are ready

		movea.l #realrom,%a1		| copying into 8KB in

		move.b #0x01,SYSCONF		| write enable eeprom

pagestart:	movea.l #eightkbytes,%a0	| ram copy of page
		move.w #8192-1,%d1		| 8kbytes for a page
1:		bsr getchar			| get a byte
		move.b %d0,(%a0)+		| save it in ram
		dbra %d1,1b			| back for more

		move.w #0xaaaa,ROMB+(0x5555*2)	| sector erase 1st cycle
		move.w #0x5555,ROMB+(0x2aaa*2)	| sector erase 2nd cycle
		move.w #0x8080,ROMB+(0x5555*2)	| sector erase 3rd cycle
		move.w #0xaaaa,ROMB+(0x5555*2)	| sector erase 4th cycle
		move.w #0x5555,ROMB+(0x2aaa*2)	| sector erase 5th cycle
		move.w #0x3030,(%a1)		| finally set the sector

		move.b #1,LED
		move.w #0xff00,%d0		| delay, maybe 20mS?
1:		dbra %d0,1b
		move.w #0xff00,%d0		| delay, maybe 20mS?
1:		dbra %d0,1b
		move.b #0,LED
		move.b #1,LED
		move.w #0xff00,%d0		| delay, maybe 20mS?
1:		dbra %d0,1b
		move.w #0xff00,%d0		| delay, maybe 20mS?
1:		dbra %d0,1b
		move.b #0,LED
		move.b #1,LED
		move.w #0xff00,%d0		| delay, maybe 20mS?
1:		dbra %d0,1b
		move.w #0xff00,%d0		| delay, maybe 20mS?
1:		dbra %d0,1b
		move.b #0,LED
		move.b #1,LED
		move.w #0xff00,%d0		| delay, maybe 20mS?
1:		dbra %d0,1b
		move.w #0xff00,%d0		| delay, maybe 20mS?
1:		dbra %d0,1b
		move.b #0,LED

|		bsr togglepoll

		movea.l #eightkbytes,%a0	| ram copy of page
		move.w #8192/2-1,%d1		| 8kbytes for a page

1: 		move.w #0xaaaa,ROMB+(0x5555*2)	| byte program 1st cycle
		move.w #0x5555,ROMB+(0x2aaa*2)	| byte program 2nd cycle
		move.w #0xa0a0,ROMB+(0x5555*2)	| byte program 3rd cycle
		move.w (%a0)+,(%a1)		| save it to realrom

		move.w #0x100,%d0		| delay, maybe 20uS?
2:		dbra %d0,2b

|		bsr togglepoll
		addq.l #2,%a1

3:		dbra %d1,1b			| back for more

		move.b #0x23,%d0		| "#"
		bsr putchar			| tell the other next block
		dbra %d2,pagestart		| get remaining pages

		move.b #0x00,SYSCONF		| write protect eeprom

| now send it back

		movea.l #realrom,%a0		| back to the start
1:		move.b (%a0)+,%d0		| get the byte we wrote
		bsr putchar			| send it back
		cmp.l %a0,%a1			| past the end?
		bne 1b				| back for the next byte
		bra normalstart			| start in new realrom

| put the string in a0

putstring:	move.b (%a0)+,%d0		| get the byte to put
		beq 1f				| end of message, done
		bsr putchar			| output the char in d0
		bra putstring			| back for more
1:		rts

| put the char in d0

putchar:	btst.b #3,SR26C94+BASEPB	| busy sending last char?
		beq putchar			| yes, look again
		move.b %d0,TXFIFO26C94+BASEPB	| put that byte
		rts

| get a string in a0

getstring:	bsr getchar
		bsr putchar			| echo it
		cmpi.b #0x0a,%d0		| lf?
		beq 1f				| match, done
		cmpi.b #0x0d,%d0		| cr?
		beq 1f				| match, done
		move.b %d0,(%a0)+		| save it to the string
		bra getstring			| next char
1:		move.b #0,(%a0)			| add a null
		rts

| get a char in d0

getchar:	btst.b #0,SR26C94+BASEPB	| chars?
		beq getchar			| no chars yet
		move.b RXFIFO26C94+BASEPB,%d0	| get it in d0
		rts

| get a char with a two second (ish) timeout, exit zero for got a char
| or non zero for timeout.

getcharwithto:	move.w #0xffff,%d0		| get timer
1:		sub.w #1,%d0			| dec timer
		beq 2f				| timeout reached
		btst.b #0,SR26C94+BASEPB	| chars?
		beq 1b				| no chars yet
		move.b RXFIFO26C94+BASEPB,%d0	| get it in d0
		ori #0x04,%ccr			| set zero
		rts
2:		ori #0xfb,%ccr			| clear zero
		rts

||| memory tests

setmemtolong:	move.l %d0,%d7
		movea.l #0,%a0			| start at 0
		move.w #(((1024*1024)/4)/1024)-2,%d2
						| number of 64K long blocks
1:		move.w #1024-1,%d1		| 64K of long words
2:		move.l %d0,(%a0)+		| set to d1 value
		addq.l #1,%d0
                dbra %d1,2b			| back for more
                dbra %d2,1b			| next 64KB block
		move.l %d7,%d0
		rts

cmpmemtolong:	move.l %d0,%d7
		movea.l #0,%a0			| start at 0
		move.w #(((1024*1024)/4)/1024)-2,%d2
						| number of 1K long blocks
1:		move.w #1024-1,%d1		| 64K of long words
2:		move.l (%a0)+,%d3		| see if match
		cmp.l %d0,%d3
		bne error
		addq.l #1,%d0
                dbra %d1,2b			| back for more
                dbra %d2,1b			| next 64KB block
		move.l %d7,%d0
		rts

error:		move.w #0xffff,LED
		move.w #0xff0,%d0
1:		dbra %d0,1b
		move.w #0,LED
		move.w #0xfff0,%d0
2:		dbra %d0,2b
		bra error

togglepoll:	movem.w %d0-%d1,-(%sp)
		move.b #0,LED
		move.w (%a1),%d0		| read base address
		and.w #0x4040,%d0
		move.w %d0,%d1
1:		and.w #0x4040,%d0		| get new state of toggle
		cmp.w %d0,%d1
		bne 2f
		move.w %d0,%d1
		move.w (%a1),%d0
		bra 1b
2:		movem.w (%sp)+,%d0-%d1
		move.b #1,LED
		rts

		.section .rodata

hellomsg:	.asciz "\r\nHello from flash\r\n"
resetmsg:	.asciz "\r\n***flash with f\r\n"
flashreadymsg:	.asciz "+++"
norealrommsg:	.asciz "No real ROM loaded, STOP\r\n"

| the "real" ROM image goes 8KB into the address space, for now just print
| a message.

		.section .realrom, #alloc

realrom:	movea.l #norealrommsg,%a0
		bsr putstring
1:		bra 1b

		.section .bss

ramcopy:	.space 8192			| copy of bootloader
eightkbytes:	.space 8192			| one eeprom page
delay:		.space 2
buffer:		.space 100
