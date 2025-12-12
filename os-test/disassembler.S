		.include "../include/macros.i"
		.include "../include/system.i"

		.section .text
		.align 2

		.global disassemble

		.equ WIDTH_BYTE, 0
		.equ WIDTH_WORD, 1
		.equ WIDTH_LONG, 2

		.equ INST_NAME, 0
		.equ INST_PATTERN, 4
		.equ INST_MASK, 6
		.equ INST_WIDTHSUB, 8
		.equ INST_SRCSUB, 12
		.equ INST_DSTSUB, 16
		.equ INST_LENGTH, 20


| disassemble the code from the given address at a0 for the given length in words at d0

disassemble:	move.l %a0,%a4			| copy address to a4 for processing
		move.w %d0,%d3			| copy instruction count to d3
		sub.w #1,%d3			| adjust length for loop

| in the loop:
|     a4 = current address

.toploop:	move.l %a4,%d0			| point to instruction for address printing
		bsr serputlong			| output the address
		move.b #':',%d0			| add colon after address
		bsr serputchar			| output colon
		move.b #'\t',%d0		| add tab after colon
		bsr serputchar			| output space

		move.w (%a4)+,%d2		| fetch the instruction word and keep in d2
		movea.l #instructions,%a1	| point to start of instruction table
.testloop:	debugprint "Testing for instruction", SECTION_DISASSEMBLER, REG_A1
		tst.l (INST_NAME,%a1)		| end of table?
		beq .badinst			| unknown instruction
		move.w %d2,%d1			| restore original instruction word
		and.w (INST_MASK,%a1),%d1	| mask off bits not in pattern
		cmp.w (INST_PATTERN,%a1),%d1	| compare to pattern
		beq .foundit			| found it!
		adda.l #INST_LENGTH,%a1		| point to next instruction
		bra .testloop			| keep looking

.continue:	dbra %d3,.toploop		| loop for all instructions
		rts

.badinst:	movea.l #badinstmsg,%a0		| outputting bad instruction message
		bsr serputstr			| output bad instruction message
		bra .endinst			| add a newline and continue

.foundit:	debugprint "Found instruction", SECTION_DISASSEMBLER, REG_D2

		movea.l (INST_NAME,%a1),%a0	| get instruction name
		debugprint "Instruction name", SECTION_DISASSEMBLER, REG_A0
		bsr serputstr			| output instruction name

		moveq #0,%d6			| clear d6 means word width by default

		movea.l (INST_WIDTHSUB,%a1),%a0	| get width extraction routine
		tst.l %a0			| no width?
		beq 1f				| skip it
		jsr (%a0)			| call width extraction routine

1:		move.b #' ',%d0			| add space after width, if present
		bsr serputchar			| output space

		movea.l (INST_SRCSUB,%a1),%a0	| get source extraction routine
		tst.l %a0			| no source?
		beq 1f				| skip it
		jsr (%a0)			| call source extraction routine
		move.b #',',%d0			| add comma after source
		bsr serputchar			| output comma

1:		movea.l (INST_DSTSUB,%a1),%a0	| get dest extraction routine
		tst.l %a0			| no dest?
		beq .endinst			| skip it
		jsr (%a0)			| call dest extraction routine

.endinst:	movea.l #newlinemsg,%a0		| outputting newline after instruction
		bsr serputstr			| output newline

		bra .continue			| continue with next instruction

| extraction routines

widthbytesub:	movem.l %a0,-(%sp)
		movea.l #bytewidth,%a0
		bsr serputstr
		movem.l (%sp)+,%a0
		rts

widthwordsub:	movem.l %a0,-(%sp)
		movea.l #wordwidth,%a0
		bsr serputstr
		movem.l (%sp)+,%a0
		rts

widthlongsub:	movem.l %a0,-(%sp)
		movea.l #longwidth,%a0
		bsr serputstr
		moveq #1,%d6			| set d6 means word width by default
		movem.l (%sp)+,%a0
		rts

width76sub:	movem.l %d2/%a0,-(%sp)
		lsr.w #6,%d2			| get bits 7-6
		and.w #0x3,%d2			| mask to 2 bits
		move.l (%d2.w*4,twobwidthtable),%a0
						| get width string
		bsr serputstr
		movem.l (%sp)+,%d2/%a0
		rts

width6sub:	movem.l %d2/%a0,-(%sp)
		lsr.w #6,%d2			| get bit 6
		and.w #0x1,%d2			| mask to 1 bit
		move.l (%d2.w*4,onebwidthtable),%a0
						| get width string
		bsr serputstr
		movem.l (%sp)+,%d2/%a0
		rts

immbytesub:	movem.l %d0/%a0,-(%sp)
		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		move.w (%a4)+,%d0		| get the byte but in a word
		bsr hexbyte			| output the byte
		movem.l (%sp)+,%d0/%a0
		rts

immwordsub:	movem.l %d0/%a0,-(%sp)
		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		move.w (%a4)+,%d0		| get the word
		bsr hexword			| output the word
		movem.l (%sp)+,%d0/%a0
		rts

immlongsub:	movem.l %d0/%a0,-(%sp)
		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		move.l (%a4)+,%d0		| get the long
		bsr hexlong			| output the long
		movem.l (%sp)+,%d0/%a0
		rts

dreg119sub:	movem.l %d2/%a0,-(%sp)
		lsr.w #8,%d2			| get bits 11-9
		lsr.w #1,%d2			| needs one more shift
		and.w #0x7,%d2			| mask to 3 bits
		move.b %d2,%d0			| move to d0 for output
		bsr serputdatareg		| output '%d'
		movem.l (%sp)+,%d2/%a0
		rts

areg119sub:	movem.l %d2/%a0,-(%sp)
		lsr.w #8,%d2			| get bits 11-9
		lsr.w #1,%d2			| needs one more shift
		and.w #0x7,%d2			| mask to 3 bits
		move.b %d2,%d0			| move to d0 for output
		bsr serputaddrreg		| output '%a'
		movem.l (%sp)+,%d2/%a0
		rts

immbwlsub:	movem.l %d2/%a0,-(%sp)
		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		lsr.w #6,%d2			| get bits 7-6
		and.w #0x3,%d2			| mask to 2 bits

		cmp.w #WIDTH_BYTE,%d2		| byte?
		beq 1f				| yes, byte
		cmp.w #WIDTH_WORD,%d2		| word?
		beq 2f				| yes, word
		cmp.w #WIDTH_LONG,%d2		| long?
		beq 3f				| yes, long

		movea.l #badinstmsg,%a0		| bad width
		bsr serputstr			| output bad instruction message
		bra 100f

1:		move.w (%a4)+,%d0		| get the byte in low half
		bsr hexbyte			| output it
		bra 100f

2:		move.w (%a4)+,%d0		| get the word
		bsr hexword			| output it
		bra 100f

3:		move.l (%a4)+,%d0		| get the long
		bsr hexlong			| output it

100:		movem.l (%sp)+,%d2/%a0
		rts

moderightsub:	movem.l %d2-%d3/%a0,-(%sp)
		move.l %d2,%d3			| copy original instruction word
		and.w #0x7,%d2			| d2 holds register only
		lsr.w #3,%d3			| d3 holds mode only, get bits 5-3
		and.w #0x7,%d3			| mask to 3 bits
		bra 1f

modeleftsub:	movem.l %d2-%d3/%a0,-(%sp)
		move.l %d2,%d3			| copy original instruction word
		lsr.w #8,%d2			| d2 holds register only
		lsr.w #1,%d2			| needs one more shift
		and.w #0x7,%d2			| d2 holds register only
		lsr.w #6,%d3			| d3 holds mode only, get bits 8-6
		and.w #0x7,%d3			| mask to 3 bits

1:		cmp.w #0b000,%d3		| data register
		beq 1f				| yes, data register
		cmp.w #0b001,%d3		| address register
		beq 2f				| yes, address register
		cmp.w #0b010,%d3		| address register indirect
		beq 3f				| yes, address register indirect
		cmp.w #0b011,%d3		| address register indirect with postincrement
		beq 4f				| yes, address register indirect with postincrement
		cmp.w #0b100,%d3		| address register indirect with predecrement
		beq 5f				| yes, address register indirect with predecrement
		cmp.w #0b101,%d3		| address with displacement
		beq 6f				| yes, address with displacement
		cmp.w #0b110,%d3		| address register with index and displacement
		beq 7f				| yes, address with index and displacement
		cmp.w #0b111,%d3		| other modes
		beq 10f				| yes, modes switched on register field

bad:		movea.l #badinstmsg,%a0		| bad width
		bsr serputstr			| output bad instruction message
		bra 100f

dregsub:	movem.l %d2-%d3/%a0,-(%sp)
1:		move.b %d2,%d0			| get original instruction word
		bsr serputdatareg		| output '%d'
		bra 100f

aregsub:	movem.l %d2-%d3/%a0,-(%sp)
2:		move.b %d2,%d0			| get original instruction word
		bsr serputaddrreg		| output '%a'
		bra 100f

aregisub:	movem.l %d2-%d3/%a0,-(%sp)
3:		move.b %d2,%d0			| get original instruction word
		bsr serputaddrregi		| output '(%a)'
		bra 100f

aregiincsub:	movem.l %d2-%d3/%a0,-(%sp)
4:		move.b %d2,%d0			| get original instruction word
		bsr serputaddrregi		| output '(%a)'
		move.b #'+',%d0			| add '+' after ea
		bsr serputchar			| output '+'
		bra 100f

aregidecsub:	movem.l %d2-%d3/%a0,-(%sp)
5:		move.b #'-',%d0			| add '-' before ea
		bsr serputchar			| output '-'
		move.b %d2,%d0			| get original instruction word
		bsr serputaddrregi		| output '(%a)'
		bra 100f

aregidispsub:	movem.l %d2-%d3/%a0,-(%sp)
6:		move.b #'(',%d0			| add '(' before ea
		bsr serputchar			| output '('
		move.w (%a4)+,%d0		| get the displacement
		bsr hexword			| output the displacement
		move.b #',',%d0			| add ',' after displacement
		bsr serputchar			| output ','
		move.b %d2,%d0			| get original instruction word
		bsr serputaddrreg		| output '%a'
		move.b #')',%d0			| add ')' after ea
		bsr serputchar			| output ')'
		bra 100f

aregiindexsub:	movem.l %d2-%d3/%a0,-(%sp)
7:		move.b #'(',%d0			| add '(' before extension word
		bsr serputchar			| output '(')'
		move.w (%a4)+,%d4		| get the extension word
		move.w %d4,%d0			| copy for processing offfset
		and.w #0x00ff,%d0		| mask to low byte
		bsr hexbyte			| output low byte offset (signed!)
		move.b #',',%d0			| add ',' between bytes
		bsr serputchar			| output ','
		move.w %d2,%d0			| restore original instruction word
		bsr serputaddrreg		| output register number
		move.b #',',%d0			| add ',' between bytes
		bsr serputchar			| output ','
		move.w %d4,%d0			| copy for processing register
		lsr.w #8,%d0			| shift 8 to get register
		lsr.w #4,%d0			| and another 4
		btst #3,%d0			| looking for register type
		beq 1f				| data register in use?
		bsr serputaddrreg		| output the address register
		bra 2f				| hop over
1:		bsr serputdatareg		| output the data register
2:		move.b #'.',%d0			| width of displacement reg
		bsr serputchar			| print it
		btst #11,%d4			| look for word (0) or long (1)?
		beq 1f				| word width
		move.b #'l',%d0			| so its a long wide displacement
		bsr serputchar			| print it
		bra 2f				| hop over
1:		move.b #'w',%d0			| so its a word wide displacement
		bsr serputchar			| print it
2:		move.b #')',%d0			| add ',' between bytes
		bsr serputchar			| output ','
		bra 100f

10:		move.w %d2,%d0			| get original instruction word
		and.w #0x7,%d0			| mask to 3 bits
		cmp.w #0b000,%d0		| absolute word
		beq 1f				| yes, absolute word
		cmp.w #0b001,%d0		| absolute long
		beq 2f				| yes, absolute long
		cmp.w #0b010,%d0		| pc with displacement
		beq 3f				| yes, pc with displacement
		cmp.w #0b011,%d0		| pc with index and displacement
		beq 4f				| yes, pc with index and displacement
		cmp.w #0b100,%d0		| imm
		beq 5f				| yes, imm
		bra bad				| bad mode

1:		move.b #'(',%d0			| add '(' before absolute word
		bsr serputchar			| output '('
		move.w (%a4)+,%d0		| get the absolute word
		bsr hexword			| output it
		move.b #')',%d0			| add ')' after ea
		bsr serputchar			| output ')'
		bra 100f

2:		move.b #'(',%d0			| add '(' before absolute long
		bsr serputchar			| output '('
		move.l (%a4)+,%d0		| get the absolute long
		bsr hexlong			| output it
		move.b #')',%d0			| add ')' after ea
		bsr serputchar			| output ')'
		bra 100f

3:		bra bad				| bad mode (pc with displacement)

4:		bra bad				| bad mode (pc with index and displacement)

5:		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		tst.w %d6			| check width in d6
		bne 1f				| long width?
		move.w (%a4)+,%d0		| get the imm word
		bsr hexword			| output it
		bra 100f
1:		move.l (%a4)+,%d0		| get the imm long
		bsr hexlong			| output it
		bra 100f

100:		movem.l (%sp)+,%d2-%d3/%a0
		rts

| printing routines

| prints the reg name for data register in d3
serputdatareg:	movea.l #dataregstr,%a0		| output '%a'
		bra 1f

| prints the reg name for address register in d3
serputaddrreg:	movea.l #addrregstr,%a0		| output '%a'
		bra 1f

1:		bsr serputstr			| output '%d' or '%a'
		and.b #0x7,%d0			| mask to 3 bits
		add.b #'0',%d0			| convert to ascii
		bsr serputchar
		rts

| same as above but with parentheses around it (indirect mode)
serputaddrregi:	move.w %d0,%d3			| save d0 in d3
		move.b #'(',%d0			| add '(' before ea
		bsr serputchar			| output '('
		move.w %d3,%d0			| restore original instruction word
		bsr serputaddrreg		| output register number
		move.b #')',%d0			| add ')' after ea
		bsr serputchar			| output ')'
		rts

| hexbyte: print a byte with 0x in front
hexbyte:	movea.l #hex,%a0
		bsr serputstr
		bsr serputbyte
		rts

| hexword: print a byte with 0x in front
hexword:	movea.l #hex,%a0
		bsr serputstr
		bsr serputword
		rts

| hexlong: print a byte with 0x in front
hexlong:	movea.l #hex,%a0
		bsr serputstr
		bsr serputlong
		rts

ccrsub:		movem.l %a0,-(%sp)
		movea.l #ccrstr,%a0
		bsr serputstr
		movem.l (%sp)+,%a0
		rts

srsub:		movem.l %a0,-(%sp)
		movea.l #srstr,%a0
		bsr serputstr
		movem.l (%sp)+,%a0
		rts

		.section .rodata
		.align 2

instructions:	instruction ori_ccr,  "ori",	0b0000000000111100, 0b1111111111111111, \
			widthbytesub, immbytesub, ccrsub
		instruction ori_sr,   "ori",	0b0000000001111100, 0b1111111111111111, \
			widthwordsub, immwordsub, srsub
		instruction ori_ea,   "ori",    0b0000000000000000, 0b1111111100000000, \
			width76sub, immbwlsub, moderightsub

		instruction andi_ccr, "andi",   0b0000001000111100, 0b1111111111111111, \
			widthbytesub, immbytesub, ccrsub
		instruction andi_sr,  "andi",   0b0000001001111100, 0b1111111111111111, \
			widthwordsub, immwordsub, srsub
		instruction andi_ea,  "andi"    0b0000001000000000, 0b1111111100000000, \
			width76sub, immbwlsub, moderightsub

		instruction subi_ea,  "subi",   0b0000010000000000, 0b1111111100000000, \
			width76sub, immbwlsub, moderightsub
		instruction addi_ea,  "addi",   0b0000011000000000, 0b1111111100000000, \
			width76sub, immbwlsub, moderightsub

		instruction eori_ccr, "eori",   0b0000101000111100, 0b1111111111111111, \
			widthbytesub, immbytesub, ccrsub
		instruction eori_sr,  "eori",   0b0000101001111100, 0b1111111111111111, \
			widthwordsub, immwordsub, srsub
		instruction eori_ea,  "eori",   0b0000101000000000, 0b1111111100000000, \
			width76sub, immbwlsub, moderightsub

		instruction cmpi_ea,  "cmpi",   0b0000110000000000, 0b1111111100000000, \
			width76sub, immbwlsub, moderightsub

		| movep instructions must be before memory btst instructions to avoid
		| false matches
		instruction movep_wr,  "movep",  0b0000000100001000, 0b1111000110111000, \
			width6sub, aregidispsub, dreg119sub // write to register
		instruction movep_wm,  "movep",  0b0000000110001000, 0b1111000110111000, \
			width6sub, dreg119sub, aregidispsub // write to memory

		instruction movea_wrw, "movea",   0b0011000001000000, 0b1111000111000000, \
			widthwordsub, moderightsub, areg119sub
		instruction movea_wrl, "movea",   0b0010000001000000, 0b1111000111000000, \
			widthlongsub, moderightsub, areg119sub

		instruction move_wrb, "move",     0b0001000000000000, 0b1111000000000000, \
			widthbytesub, moderightsub, modeleftsub
		instruction move_wrw, "move",     0b0011000000000000, 0b1111000000000000, \
			widthwordsub, moderightsub, modeleftsub
		instruction move_wrl, "move",     0b0010000000000000, 0b1111000000000000, \
			widthlongsub, moderightsub, modeleftsub

		instruction btst_i, "btst",     0b0000100000000000, 0b1111111111000000, \
			null, immbytesub, moderightsub
		instruction btst_dr, "btst",    0b0000000100000000, 0b1111000111000000, \
			null, dreg119sub, moderightsub
		instruction bchg_i, "bchg",     0b0000100001000000, 0b1111111111000000, \
			null, immbytesub, moderightsub
		instruction bchg_dr, "bchg",    0b0000000101000000, 0b1111000111000000, \
			null, dreg119sub, moderightsub
		instruction bclr_i, "bclr",     0b0000100010000000, 0b1111111111000000, \
			null, immbytesub, moderightsub
		instruction bclr_dr, "bclr",    0b0000000110000000, 0b1111000111000000, \
			null, dreg119sub, moderightsub
		instruction bset_i, "bset",     0b0000100011000000, 0b1111111111000000, \
			null, immbytesub, moderightsub
		instruction bset_dr, "bset",    0b0000000111000000, 0b1111000111000000, \
			null, dreg119sub, moderightsub

		instruction move_from_sr, "move", 0b0100000011000000, 0b1111111111000000, \
			widthwordsub, srsub, moderightsub
		instruction move_to_ccr, "move",  0b0100010011000000, 0b1111111111000000, \
			widthwordsub, moderightsub, ccrsub
		instruction move_to_sr, "move",   0b0100011011000000, 0b1111111111000000, \
			widthwordsub, moderightsub, srsub

		| end of table
		.long 0

nullwidth:	.asciz ""
bytewidth:	.asciz ".b"
wordwidth:	.asciz ".w"
longwidth:	.asciz ".l"

twobwidthtable:	.long bytewidth
onebwidthtable:	.long wordwidth
		.long longwidth

hex:		.asciz "0x"

ccrstr:		.asciz "%ccr"
srstr:		.asciz "%sr"
dataregstr:	.asciz "%d"
addrregstr:	.asciz "%a"

badinstmsg:	.asciz "<bad instruction>"
