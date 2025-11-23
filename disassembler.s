		.include "include/macros.i"
		.include "include/system.i"

		.section .text
		.align 2

		.global disassemble

| disassemble the code from the given address at a0 for the given length in words at d0

disassemble:	move.l %a0,%a1			| copy address to a1 for processing
		sub.w #1,%d0			| adjust length for loop

| in the loop:
|     a1 = current address, d0 = words left, d1 = instruction word excluding line,
| d2 = instruction line

.toploop:	move.w (%a1)+,%d1		| fetch the instruction word
		move.w %d1,%d2			| copy it to d2 for manipulation
		lsr.w #8,%d2			| isolate the opcode in d2
		lsr.w #4,%d2			| shift right 4 more bits
		and.w #0x0fff,%d1		| mask off everything but the line bits
		cmp.w #0x00,%d2			| check for 0 line instruction
		beq handle0line
		cmp.w #0x01,%d2			| check for 1 line instruction
		beq handle1line
		bra badline			| unknown line
.continue:	dbra %d0,.toploop		| loop for all instructions
		rts

handle0line:	debugprint "0 line instruction", SECTION_DISASSEMBLER, REG_D1
		move.w (%a1)+,%d2		| fetch next word
		debugprint "data word:", SECTION_DISASSEMBLER, REG_D2
		bra .continue

handle1line:	debugprint "1 line instruction", SECTION_DISASSEMBLER, REG_D1
		bra .continue

badline:	debugprint "Bad instruction line", SECTION_DISASSEMBLER, REG_D2
		bra .continue

test:		ori.b #0x12,%ccr
		ori.w #0x3456,%sr

