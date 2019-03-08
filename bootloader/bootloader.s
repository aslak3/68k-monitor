		.align 2

		.equ LED, 0x100001
		.equ BUZZER, 0x100003
		.equ SYSCONF, 0x100005

		.equ BASE2681, 0x200001
		.equ MR1A2681, BASE2681+0
		.equ MR2A2681, BASE2681+0
		.equ SRA2681, BASE2681+2
		.equ CSRA2681, BASE2681+2
		.equ BRGEXT2681, BASE2681+4
		.equ CRA2681, BASE2681+4
		.equ RHRA2681, BASE2681+6
		.equ THRA2681, BASE2681+6
		.equ IPCR2681, BASE2681+8
		.equ ACR2681, BASE2681+8
		.equ ISR2681, BASE2681+10
		.equ IMR2681, BASE2681+10
		.equ CTU2681, BASE2681+12
		.equ CRUR2681, BASE2681+12
		.equ CTL2681, BASE2681+14
		.equ CTLR2681, BASE2681+14
		.equ MR1B2681, BASE2681+16
		.equ MR2B2681, BASE2681+16
		.equ SRB2681, BASE2681+18
		.equ CSRB2681, BASE2681+18
		.equ TEST2681, BASE2681+20
		.equ CRB2681, BASE2681+20
		.equ RHRB2681, BASE2681+22
		.equ THRB2681, BASE2681+22
		.equ SCRATCH2681, BASE2681+24
		.equ IP2681, BASE2681+26
		.equ OPCR2681, BASE2681+26
		.equ STARTCOM2681, BASE2681+28
		.equ SETOPCOM2681, BASE2681+28
		.equ STOPCOM2681, BASE2681+30
		.equ RESETOPCOM2681, BASE2681+30

		.section .vectors, #alloc

resetsp:	.long 0x008000			| the initial sp
resetpc:	.long _start			| the initial pc

		.section .text

_start:		move.b #0x00,SYSCONF		| write protect eeprom

		move.b #0b00010011,MR1A2681	| 8n
		move.b #0b00000111,MR2A2681	| one full stop bit
		move.b #0b10111011,CSRA2681	| 9600
		move.b #0b00000101,CRA2681	| enable rx and tx

		move.b #0x00,LED
		move.b #0x00,BUZZER

		movea.l #_rom_start,%a0		| get the start of rom
		movea.l #ramcopy,%a1		| get where to copy it to
		move.w #2048/4-1,%d0		| copy 512 times
1:		move.l (%a0)+,(%a1)+		| copy longs
		dbra %d0,1b			| back for more

		move.b #0x01,LED
		move.b #0x40,BUZZER

		move.l #begin,%d0
		sub.l #_rom_start,%d0
		add.l #ramcopy,%d0
		move.l %d0,%a0

		jmp (%a0)

begin:		|lea resetmsg(%pc),%a0		| grab the greeting in a0
		movea.l #resetmsg,%a0
		bsr putstring			| send it

		bsr getcharwithto		| get a char with timeout
		bne normalstart			| timeout so normal start
		cmp.b #'f',%d0			| is it an f?
		beq flasher			| yes, so do the flashing

normalstart:	move.b #0x00,LED
		move.b #0x00,BUZZER
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

		movea.l #realrom,%a1		| copying into 2KB in

		move.b #0x01,SYSCONF		| write enable eeprom

pagestart:	movea.l #sixtyfourbytes,%a0	| ram copy of page
		move.w #64-1,%d1		| 64bytes for a page
1:		bsr getchar			| get a byte
		move.b %d0,(%a0)+		| save it in ram
		dbra %d1,1b			| back for more

		movea.l #sixtyfourbytes,%a0	| ram copy of page
		move.w #64/4-1,%d1		| 64bytes for a page
1:		move.l (%a0)+,(%a1)+		| save it to realrom
		dbra %d1,1b			| back for more

		move.w #0xff00,%d0		| delay, maybe 10ms?
1:		dbra %d0,1b

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

putchar:	btst.b #2,SRA2681		| busy sending last char?
		beq putchar			| yes, look again
		move.b %d0,THRA2681		| put that byte
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

getchar:	btst.b #0,SRA2681		| chars?
		beq getchar			| no chars yet
		move.b RHRA2681,%d0		| get it in d0
		rts

| get a char with a two second (ish) timeout, exit zero for got a char
| or non zero for timeout.

getcharwithto:	move.w #0xffff,%d0		| get timer
1:		sub.w #1,%d0			| dec timer
		beq 2f				| timeout reached
		btst.b #0,SRA2681		| chars?
		beq 1b				| no chars yet
		move.b RHRA2681,%d0		| get it in d0
		ori #0x04,%ccr			| set zero
		rts
2:		ori #0xfb,%ccr			| clear zero
		rts

		.section .rodata

resetmsg:	.asciz "\r\n***flash with f\r\n"
flashreadymsg:	.asciz "+++"
norealrommsg:	.asciz "No real ROM loaded, STOP\r\n"

| the "real" ROM image goes 2KB into the address space, for now just print
| a message.

		.section .realrom, #alloc

realrom:	movea.l #norealrommsg,%a0
		bsr putstring
1:		bra 1b

		.section .bss

ramcopy:	.space 2048			| copy of bootloader
sixtyfourbytes:	.space 64			| one eeprom page
