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
.testloop:	tst.l (INST_NAME,%a1)		| end of table?
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

condsub:	movem.l %a0,-(%sp)
		move.w %d2,%d0			| copy original instruction word
		lsr.w #6,%d0			| shift most of the way
		and.w #0x003c,%d0		| mask to 4 bits, but up 2
		lea (allcondstr,%d0.w),%a0	| get the condition string
		bsr serputstr			| output it
		movem.l (%sp)+,%a0
		rts

data30sub:	movem.l %d2/%a0,-(%sp)
		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		move.w %d2,%d0			| copy original instruction word
		and.w #0xf,%d0			| mask to 4 bits
		bsr hexbyte			| output the nybble sorta
		movem.l (%sp)+,%d2/%a0
		rts

data119sub:	movem.l %d2/%a0,-(%sp)
		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		move.w %d2,%d0			| copy original instruction word
		lsr.w #8,%d0			| shift most of the way
		lsr.w #1,%d0			| get the data at 11-9
		and.w #0x7,%d0			| mask to 3 bits
		bsr hexbyte			| output the nybble sorta
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

movemsub:	movem.l %d1-%d5/%a0,-(%sp)
		lsr.w #3,%d2			| d3 holds mode only, get bits 5-3
		and.w #0x7,%d2			| mask to 3 bits
		cmp.w #0b100,%d2		| address register indirect with predecrement
		beq 0f				| yes, address register indirect with predecrement

		move.w #1,%d4			| scan direction (up)
		move.w #0,%d5			| initial bit test pos
		bra 1f

0:		move.w #-1,%d4			| scan direction (down)
		move.w #15,%d5			| initial bit test pos

1:		move.w (%a4)+,%d1		| get the register word
		moveq #0,%d2			| flag to avoid printing first slash
		move.w #15,%d3			| bit counter
		movea.l #allregstr,%a0		| count into the list of regs, longs
2:		btst %d5,%d1			| see if reg bit is set
		beq 4f				| not set? skip the printing
		tst.w %d2			| see if this is the first reg
		beq 3f				| skip printing the first slash
		move.b #'/',%d0			| printing a slash separator
		bsr serputchar			| print it
3:		bsr serputstr			| print the register name
		suba.l #4,%a0			| restore a0 by jumping back 4
		moveq #1,%d2			| force printing the slash seps
4:		add.w %d4,%d5			| scanning the next bit, up or down
		adda.l #4,%a0			| next reg string
		dbra %d3,2b			| back for more
		movem.l (%sp)+,%d1-%d5/%a0
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

| prints the reg name for data register in d0, changing d0
serputdatareg:	movea.l #dataregstr,%a0		| output '%a'
		bra 1f

| prints the reg name for address register in d0, changing d0
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

uspsub:		movem.l %a0,-(%sp)
		movea.l #uspstr,%a0
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

		instruction btst_i, "btst",       0b0000100000000000, 0b1111111111000000, \
			null, immbytesub, moderightsub
		instruction btst_dr, "btst",      0b0000000100000000, 0b1111000111000000, \
			null, dreg119sub, moderightsub
		instruction bchg_i, "bchg",       0b0000100001000000, 0b1111111111000000, \
			null, immbytesub, moderightsub
		instruction bchg_dr, "bchg",      0b0000000101000000, 0b1111000111000000, \
			null, dreg119sub, moderightsub
		instruction bclr_i, "bclr",       0b0000100010000000, 0b1111111111000000, \
			null, immbytesub, moderightsub
		instruction bclr_dr, "bclr",      0b0000000110000000, 0b1111000111000000, \
			null, dreg119sub, moderightsub
		instruction bset_i, "bset",       0b0000100011000000, 0b1111111111000000, \
			null, immbytesub, moderightsub
		instruction bset_dr, "bset",      0b0000000111000000, 0b1111000111000000, \
			null, dreg119sub, moderightsub

		instruction move_from_sr, "move", 0b0100000011000000, 0b1111111111000000, \
			widthwordsub, srsub, moderightsub
		instruction move_to_ccr, "move",  0b0100010011000000, 0b1111111111000000, \
			widthwordsub, moderightsub, ccrsub
		instruction move_to_sr, "move",   0b0100011011000000, 0b1111111111000000, \
			widthwordsub, moderightsub, srsub

		instruction negx_ea,   "negx",    0b0100000000000000, 0b1111111100000000, \
			width76sub, null, moderightsub
		instruction clr_ea,   "clr",      0b0100001000000000, 0b1111111100000000, \
			width76sub, null, moderightsub
		instruction neg_ea,   "neg",      0b0100010000000000, 0b1111111100000000, \
			width76sub, null, moderightsub
		instruction not_ea,   "not",      0b0100011000000000, 0b1111111100000000, \
			width76sub, null, moderightsub

		instruction ext_wl,    "ext",     0b0100100010000000, 0b1111111110111000, \
			width6sub, null, dregsub
		instruction nbcd_ea,   "nbcd",    0b0100100000000000, 0b1111111111000000, \
			null, null, moderightsub
		instruction swap_d,    "swap",    0b0100100001000000, 0b1111111111111000, \
			null, null, dregsub

		instruction pea_ea,    "pea",     0b0100100001000000, 0b1111111111000000, \
			null, null, moderightsub

		instruction illegal,   "illegal", 0b0100101011111100, 0b1111111111111111, \
			null, null, null

		instruction tas_ea,    "tas",     0b0100101011000000, 0b1111111111000000, \
			null, null, moderightsub
		instruction tst_ea,    "tst",     0b0100101000000000, 0b1111111100000000, \
			width76sub, null, moderightsub

		instruction trap,     "trap",     0b0100111001000000, 0b1111111111110000, \
			null, null, data30sub

		instruction link,      "link",    0b0100111001010000, 0b1111111111111000, \
			widthwordsub, aregsub, immwordsub
		instruction unlk,      "unlk",    0b0100111001011000, 0b1111111111111000, \
			null, null, aregsub

		instruction move_to_usp   "move", 0b0100111001100000, 0b1111111111111000, \
			widthlongsub, aregsub, uspsub
		instruction move_from_usp "move", 0b0100111001101000, 0b1111111111111000, \
			widthlongsub, uspsub, aregsub

		instruction reset,   "reset",     0b0100111001110000, 0b1111111111111111, \
			null, null, null
		instruction nop,   "nop",         0b0100111001110001, 0b1111111111111111, \
			null, null, null
		instruction stop,   "stop",       0b0100111001110010, 0b1111111111111111, \
			null, null, immwordsub
		instruction rte,   "rte",         0b0100111001110011, 0b1111111111111111, \
			null, null, null
		instruction rts,   "rts",         0b0100111001110101, 0b1111111111111111, \
			null, null, null
		instruction trapv,   "trapv",     0b0100111001110110, 0b1111111111111111, \
			null, null, null
		instruction rtr,   "rtr",         0b0100111001110111, 0b1111111111111111, \
			null, null, null

		instruction movem_wr,   "movem",  0b0100100010000000, 0b1111111110000000, \
			width6sub, movemsub, moderightsub
		instruction movem_wm,   "movem",  0b0100110010000000, 0b1111111110000000, \
			width6sub, moderightsub, movemsub

		instruction lea, "lea",           0b0100000111000000, 0b1111000111000000, \
			widthwordsub, moderightsub, areg119sub

		instruction chk, "chk",           0b0100000110000000, 0b1111000111000000, \
			widthwordsub, moderightsub, dreg119sub

		instruction dbcc "db",            0b0101000011001000, 0b1111000011111000, \
			condsub, dregsub, immwordsub
		instruction scc "s",              0b0101000011000000, 0b1111000011000000, \
			condsub, null, moderightsub

		instruction addq "addq",          0b0101000000000000, 0b1111000100000000, \
			width76sub, data119sub, moderightsub
		instruction subq "subq",          0b0101000100000000, 0b1111000100000000, \
			width76sub, data119sub, moderightsub

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
uspstr:		.asciz "%usp"
dataregstr:	.asciz "%d"
addrregstr:	.asciz "%a"

allregstr:
alldregstr:
d0regstr:	.asciz "%d0"
d1regstr:	.asciz "%d1"
d2regstr:	.asciz "%d2"
d3regstr:	.asciz "%d3"
d4regstr:	.asciz "%d4"
d5regstr:	.asciz "%d5"
d6regstr:	.asciz "%d6"
d7regstr:	.asciz "%d7"
allaregstr:
a0regstr:	.asciz "%a0"
a1regstr:	.asciz "%a1"
a2regstr:	.asciz "%a2"
a3regstr:	.asciz "%a3"
a4regstr:	.asciz "%a4"
a5regstr:	.asciz "%a5"
a6regstr:	.asciz "%a6"
a7regstr:	.asciz "%a7"

allcondstr:	.ascii "t\0\0\0"
		.ascii "f\0\0\0"
		.ascii "hi\0\0"
		.ascii "ls\0\0"
		.ascii "cc\0\0"
		.ascii "cs\0\0"
		.ascii "ne\0\0"
		.ascii "eq\0\0"
		.ascii "vc\0\0"
		.ascii "vs\0\0"
		.ascii "pl\0\0"
		.ascii "mi\0\0"
		.ascii "ge\0\0"
		.ascii "lt\0\0"
		.ascii "gt\0\0"
		.ascii "le\0\0"

badinstmsg:	.asciz "<bad instruction>"
