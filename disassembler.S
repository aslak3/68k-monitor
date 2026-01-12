		.include "include/macros.i"
		.include "include/system.i"

		.section .text
		.align 2

		.global disassemble		| the only exported subroutine

		.equ INST_NAME, 0		| printable name, like "move"
		.equ INST_PATTERN, 4		| word wide bit pattern that matches or not
		.equ INST_MASK, 6		| input is masked with this before testing
		.equ INST_CONDSUB, 8		| actually the name suffix sub but normally cond
		.equ INST_WIDTHSUB, 12		| width subroutine
		.equ INST_SRCSUB, 16		| source subroutine
		.equ INST_DSTSUB, 20		| destination subroutine
		.equ INST_LENGTH, 24		| the length of the record

		.equ DEVICE_GETCHAR, 0		| device get char offset
		.equ DEVICE_PUTCHAR, 4		| device put char offset
		.equ DEVICE_CURPOS, 8		| device current position offset
		.equ DEVICE_BUFFER, 10		| device buffer

| output routine for the disassembler

| putchar routine for printing instuctions; char in d0, buffer is held in "device" pointer at
| a5. the buffer structure also holds a current position counter at offset 8
instrputchar:	move.w %d1,-(%sp)		| save d1
		move.w (DEVICE_CURPOS,%a5),%d1	| get counter to current byte in d1
		move.b %d0,(DEVICE_BUFFER,%d1.w,%a5)
						| put char in d0 into buffer
		move.b #0,(DEVICE_BUFFER+1,%d1.w,%a5)
						| null terminate
		add.w #1,(DEVICE_CURPOS,%a5)	| advance current position
		move.w (%sp)+,%d1		| restore d1
		rts

| disassemble the code from the given address at a0 for the given number of instructions
| in d0.w. saves all used registers, but a0 and d0 will be modified on exit
disassemble:	movem.l %d1-%d6/%a1-%a4,-(%sp)	| save all used registers
		move.l %a5,iodevice		| save current io device
		movea.l #instrdevice,%a5	| instruction output device needs its putchar
		move.l #instrputchar,(DEVICE_PUTCHAR,%a5)
						| set the putchar routine

		move.l %a0,%a4			| copy address to a4 for processing
		move.w %d0,%d3			| copy instruction count to d3
		sub.w #1,%d3			| adjust length for loop

| in the loop:
|     a4 = current address

.toploop:	movea.l iodevice,%a5		| get the port for printing everything
		move.l %a4,%d0			| point to instruction for address printing
		bsr serputlong			| output the address
		move.b #':',%d0			| add colon after address
		bsr serputchar			| output colon
		move.b #'\t',%d0		| add tab after colon
		bsr serputchar			| output tab

		movea.l #instrdevice,%a5	| point to instruction device for instruction words
		move.w #0,(DEVICE_CURPOS,%a5)	| reset current position in buffer
		move.w #0,wordcharcount		| reset word char count

		bsr nextword			| get the instruction word into d0
		move.w %d0,%d2			| fetch the instruction word and keep in d2
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
		movem.l (%sp)+,%d1-%d6/%a1-%a4	| restore all used registers
		rts

.badinst:	movea.l #badinstmsg,%a0		| outputting bad instruction message
		bsr serputstr			| output bad instruction message
		bra .endinst			| add a newline and continue

.foundit:	debugprint "Found instruction", SECTION_DISASSEMBLER, REG_D2

		movea.l (INST_NAME,%a1),%a0	| get instruction name
		debugprint "Instruction name", SECTION_DISASSEMBLER, REG_A0
		bsr serputstr			| output instruction name

		movea.l (INST_CONDSUB,%a1),%a0	| get condition extraction routine
		tst.l %a0			| no condition?
		beq 1f				| skip it
		jsr (%a0)			| call condition extraction routine

1:		moveq #0,%d6			| clear d6 means word width by default

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

.endinst:	movea.l iodevice,%a5		| get the port for printing everything

		move.b #' ',%d0			| we now are adding spaces before words output
		move.w wordcharcount,%d1	| check how many chars output so far
1:		bsr serputchar			| output space
		add.w #1,%d1			| increment count
		cmp.w #24,%d1			| done all spaces to line up instruction?
		blt 1b				| more spaces to go

		movea.l #instbuffer,%a0		| get instruction buffer
		bsr serputstr			| output the instruction buffer
		movea.l #newlinemsg,%a0		| outputting newline after instruction
		bsr serputstr			| output newline

		bra .continue			| continue with next instruction

| advanaces, by one word, a4 which points to the current instruction in the stream, returning
| the word in d0 which is guaranteed to have the top word clear
nextword:	move.l %a5,-(%sp)		| save a5 the device pointer
		movea.l iodevice,%a5		| get the port for printing everything
		cmp.w #18,wordcharcount		| 20 chars output?
		blt 1f				| skip newline if not yet
		movea.l #newlinemsg,%a0		| output newline after 4 words
		bsr serputstr			| output newline
		move.b #'\t',%d0		| add tab after newline
		bsr serputchar			| output tab
		bsr serputchar			| output another tab
		move.w #0,wordcharcount		| reset word char count
1:		clr.l %d0			| clear d0 to clear the top word
		move.w (%a4)+,%d0		| advance to next word
		bsr serputword			| output the word from the stream
		swap %d0			| swap to get high word
		move.b #' ',%d0			| output space after word
		bsr serputchar			| output space
		add.w #5,wordcharcount		| increment word char count
		swap %d0			| restore original word
		move.l (%sp)+,%a5		| restore a5 the device pointer
		rts

| uses the above sub to read a long from the instruction stream; two words will be read and
| printed and the long returned in d0
nextlong:	move.l %d1,-(%sp)		| save d1
		bsr nextword			| get high word
		move.w %d0,-(%sp)		| save high word
		bsr nextword			| get low word
		move.w %d0,-(%sp)		| restore high word
		move.l (%sp)+,%d0		| get combined long into d0
		swap %d0			| swap to get word round the right way
		move.l (%sp)+,%d1		| restore d1
		rts

| extraction routines

| prints the postfix for byte (1) wide (.b)
widthbytesub:	movea.l #bytewidthstr,%a0	| get the width
		bsr serputstr			| print the width (.b)
		rts

| prints the postfix for word (2) wide (.w)
widthwordsub:	movea.l #wordwidthstr,%a0	| get the width
		bsr serputstr			| print the width (.w)
		rts

| prints the postfix for long (4) wide (.l)
widthlongsub:	movea.l #longwidthstr,%a0	| get the width
		bsr serputstr			| print the width (.l)
		moveq #1,%d6			| set d6 means long width
		rts

| haandles the case when the two bit width is 11
widthbadsub:	movea.l #badinstmsg, %a0	| get the bad width
		bsr serputstr			| print the width <bad...>)
		rts

| prints a width (.b, .w or .l) from bits 7-6 in the instruction word
width76sub:	move.l %d2,-(%sp)
		lsr.w #4,%d2			| get bits 7-6
		and.w #0xc,%d2			| mask to 2 bits, shifted up 2
		movea.l #bytesubptr,%a0		| set the base of the small table
		movea.l (%d2.w,%a0),%a0		| call width printer (might have side effects)
		jsr (%a0)
		move.l (%sp)+,%d2
		rts

| prints a width (.w or .l) from bit 6 in the instruction word
width6sub:	move.l %d2,-(%sp)
		lsr.w #4,%d2			| get bit 6
		and.w #0x4,%d2			| mask to 1 bit, shifted up 2
		movea.l #wordsubptr,%a0		| set the base of the very small table
		movea.l (%d2.w,%a0),%a0		| call width printer (might have side effects)
		jsr (%a0)
		move.l (%sp)+,%d2
		rts

| prints a width (.w or .l) from bit 8 in the instruction word
width8sub:	move.l %d2,-(%sp)
		lsr.w #6,%d2			| get bit 6
		and.w #0x4,%d2			| mask to 1 bit
		movea.l #wordsubptr,%a0		| set the base of the very small table
		movea.l (%d2.w,%a0),%a0		| call width printer (might have side effects)
		jsr (%a0)
		move.l (%sp)+,%d2
		rts

| prints a shifting direction, either l or r from bit 6; this is used by the various
| rotation/shifting instructions like lsl/r, rorxl/r etc
shiftdirsub:	move.l %d2,-(%sp)
		lsr.w #7,%d2			| get bit 6 shifted up 1
		and.w #0x2,%d2			| mask to 1 bit
		lea (%d2.w,allshiftdirstr),%a0	| get shift dir string
		bsr serputstr			| print the shift dir (l or r)
		move.l (%sp)+,%d2
		rts

| prints the displacement width suffix by checking the 8 bit displacement for 9, either
| .b or .w, used by branch instructions
widthdispsub:	tst.b %d2			| look at displacement
		beq 1f				| 0 means word
		movea.l #bytewidthstr,%a0	| so its a byte dispplacement
		bra 2f				| skip ahead
1:		movea.l #wordwidthstr,%a0	| so it's a word dispplacement
2:		bsr serputstr			| print the width suffix
		rts

| prints the actual displacement for a branch instruction. if its a word-wide displacement
| the word comes in a trailing word from the instruction stream
dispsub:	movem.l %d1/%a1,-(%sp)
		movea.l %a4,%a1			| save current pc, as we need bra addr
		move.b %d2,%d0			| get the displacement
		tst.b %d2			| look at displacement
		beq 1f				| 0 means word
		bsr hexbyte			| print the displacement
		ext.w %d0			| extend (signed) the byte to a word
		bra 2f				| hop the word disp grab as done already
1:		bsr nextword			| get the word from the stream
		bsr hexword			| print the displacement as a word
2:		ext.l %d0			| extend the displacement word to a long
		move.l %d0,%d1			| save displacement as long in d1
		move.b #' ',%d0			| print a space between the displacement
		bsr serputchar			| ... and the target pc
		move.b #'<',%d0			| print chrevrons around target pc
		bsr serputchar			| and print
		add.l %a1,%d1			| add on the current address
		move.l %d1,%d0			| need to print the address in d0
		bsr hexlong			| print the full address
		move.b #'>',%d0			| print chrevrons around target pc
		bsr serputchar			| print the closing chevron around addr
		movem.l (%sp)+,%d1/%a1
		rts

| prints the word wide displacement for db(bra)
dbdispsub:	clr.b %d2			| force a 0 byte to simulate a bra.s
		bra dispsub			| finish

| prints a condition as obtained from bit 11-8, such as gt, eq, ne etc
condsub:	move.w %d2,%d0			| copy original instruction word
		lsr.w #6,%d0			| shift most of the way
		and.w #0x003c,%d0		| mask to 4 bits, but up 2
		lea (allcondstr,%d0.w),%a0	| get the condition string
		bsr serputstr			| output it
		rts

| prints any embedded data (a nybble) at 3-0, with a leading hash. this is used by trap
| at least
data30sub:	move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		move.w %d2,%d0			| copy original instruction word
		and.w #0xf,%d0			| mask to 4 bits
		bsr hexbyte			| output the nybble sorta
		rts

| prints 3 bits of embedded data at 11-9, with a leading hash. this is used by addq, subq and
| the immediate rotations
data119sub:	move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		move.w %d2,%d0			| copy original instruction word
		lsr.w #8,%d0			| shift most of the way
		lsr.w #1,%d0			| get the data at 11-9
		and.w #0x7,%d0			| mask to 3 bits
		bsr hexbyte			| output the nybble sorta
		rts

| prints the embedded byte at 7-0. this is used by moveq. note that branching does its own
| thing, since the branch might be escaped into a following word
data70sub:	move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		move.b %d2,%d0			| copy original instruction word
		bsr hexbyte			| output the byte
		rts

| prints the trailing byte in the instruction stream, used by things like ori
immbytesub:	move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		bsr nextword			| get the byte but in a word
		bsr hexbyte			| output the byte
		rts

| prints the trailing word in the instruction stream, used by things like ori but also
| stop, and some others
immwordsub:	move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		bsr nextword			| get the word
		bsr hexword			| output the word
		rts

| prints the trailing long in the instruction stream, currently unused
immlongsub:	move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		bsr nextlong			| get the long
		bsr hexlong			| output the long
		rts

| decodes a movem register list. this is fairly involved, as it has to factor in the
| direction of the list, which differs as predecriment (push) maps the registers
| backwards. TODO currently does not print with nice ranges like %a0-%a3, instead it just
| uses a slash between registers, which should satisfy gas but it is not great.
movemsub:	movem.l %d1-%d5,-(%sp)
		lsr.w #3,%d2			| d3 holds mode only, get bits 5-3
		and.w #0x7,%d2			| mask to 3 bits
		cmp.w #0b100,%d2		| address register indirect with predecrement
		beq 0f				| yes, address register indirect with predecrement

		move.w #1,%d4			| scan direction (up)
		move.w #0,%d5			| initial bit test pos
		bra 1f

0:		move.w #-1,%d4			| scan direction (down)
		move.w #15,%d5			| initial bit test pos

1:		bsr nextword			| get the register list word
		move.w %d0,%d1			| get the register where we want it
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
		movem.l (%sp)+,%d1-%d5
		rts

| prints a data register index (3 bits) at 11-9
datareg119sub:	move.l %d2,-(%sp)
		lsr.w #8,%d2			| get bits 11-9
		lsr.w #1,%d2			| needs one more shift
		move.b %d2,%d0			| move to d0 for output
		bsr serputdatareg		| output '%d'
		move.l (%sp)+,%d2
		rts

| prints an address register index (3 bits) at 11-9
addrreg119sub:	move.l %d2,-(%sp)
		lsr.w #8,%d2			| get bits 11-9
		lsr.w #1,%d2			| needs one more shift
		move.b %d2,%d0			| move to d0 for output
		bsr serputaddrreg		| output '%a'
		move.l (%sp)+,%d2
		rts

| prints a byte, word or long immediate which is read from the stream, sized according to
| bits 7-6 in the instruction word
immbwlsub:	move.l %d2,-(%sp)
		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		lsr.w #6,%d2			| get bits 7-6
		and.w #0x3,%d2			| mask to 2 bits

		cmp.w #0b00,%d2		| byte?
		beq 1f				| yes, byte
		cmp.w #0b01,%d2		| word?
		beq 2f				| yes, word
		cmp.w #0b10,%d2		| long?
		beq 3f				| yes, long

		movea.l #badinstmsg,%a0		| bad width
		bsr serputstr			| output bad instruction message
		bra 100f

1:		bsr nextword			| get the byte in low half
		bsr hexbyte			| output it
		bra 100f

2:		bsr nextword			| get the word
		bsr hexword			| output it
		bra 100f

3:		bsr nextlong			| get the long
		bsr hexlong			| output it

100:		move.l (%sp)+,%d2
		rts

| a memory (cmpm) mode special case. outputs as (%aN)+.
memrightsub:	movem.l %d2-%d3,-(%sp)
		move.w %d2,%d3			| copy original instruction word
		and.w #0x7,%d2			| d2 holds register only
		bra 4f				| treat as postincrement address mode

| ditto but for the high bits
memleftsub:	movem.l %d2-%d3,-(%sp)
		move.w %d2,%d3			| copy original instruction word
		lsr.w #8,%d2			| d2 holds register only
		lsr.w #1,%d2			| needs one more shift
		and.w #0x7,%d2			| d2 holds register only
		bra 4f				| treat as postincrement address mode

| another special case used by bcd and addx/subx instructions. outputs the registers either
| as a data register or as -(%aN) depending on bit 3
extrightsub:	movem.l %d2-%d3,-(%sp)
		move.w %d2,%d3			| copy original instruction word
		and.w #0x7,%d2			| d2 holds register only
		btst #3,%d3			| see if data or -address
		beq 1f				| treat as data mode
		bra 5f				| treat as predecrement adddress mode

| ditto but for the high bits
extleftsub:	movem.l %d2-%d3,-(%sp)
		move.w %d2,%d3			| copy original instruction word
		lsr.w #8,%d2			| d2 holds register only
		lsr.w #1,%d2			| needs one more shift
		and.w #0x7,%d2			| d2 holds register only
		btst #3,%d3			| see if data or -address
		beq 1f				| treat as data mode
		bra 5f				| treat as predecrement adddress mode

| this is the common mode selector that handles all the usual modes: data reg, addr reg,
| address from address reg, address with post and pre inc and dec, address with 16 bit
| displacement, and address with 8 bit displacement with a 2nd register. ontop of those
| it decodes the two pc modes, the two absolute modes and the immediate modes (phew)
| this is just the front end decoder point. note that of course not all instructions
| support all modes, but the disassembler does not care about this. this is why ordering
| on the instruction defintions is critical, as some unused modes are used by specific
| instructions. eg bset and movep overlap, but since bset doesn't use address regiser
| mode, that space can be used by movep
moderightsub:	movem.l %d2-%d3,-(%sp)
		move.w %d2,%d3			| copy original instruction word
		and.w #0x7,%d2			| d2 holds register only
		lsr.w #3,%d3			| d3 holds mode only, get bits 5-3
		and.w #0x7,%d3			| mask to 3 bits
		bra 0f

| same for the left hand (high order) bits
modeleftsub:	movem.l %d2-%d3,-(%sp)
		move.w %d2,%d3			| copy original instruction word
		lsr.w #8,%d2			| d2 holds register only
		lsr.w #1,%d2			| needs one more shift
		and.w #0x7,%d2			| d2 holds register only
		lsr.w #6,%d3			| d3 holds mode only, get bits 8-6
		and.w #0x7,%d3			| mask to 3 bits

0:		cmp.w #0b000,%d3		| data register
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

todo:		movea.l #todoinstmsg,%a0	| outputting instr or mode not yet done
		bsr serputstr			| output todo instruction message
		bra .endinst			| add a newline and continue

| we can also call directly into these, since it only relies on d2 being set. note that
| d2 and d3 are both stacked as it would be if one of the entry points above was used.
| also note that this is for decoding the (more common) right hand, low order, bits.
| for where a data register is used in the upper position datareg119sub is used
dataregsub:	movem.l %d2-%d3,-(%sp)
1:		move.b %d2,%d0			| get original instruction word
		bsr serputdatareg		| output '%d'
		bra 100f

| similar to the above but for address registers
addrregsub:	movem.l %d2-%d3,-(%sp)
2:		move.b %d2,%d0			| get original instruction word
		bsr serputaddrreg		| output '%a'
		bra 100f

3:		move.b %d2,%d0			| get original instruction word
		bsr serputaddrregi		| output '(%a)'
		bra 100f

4:		move.b %d2,%d0			| get original instruction word
		bsr serputaddrregi		| output '(%a)'
		move.b #'+',%d0			| add '+' after ea
		bsr serputchar			| output '+'
		bra 100f

5:		move.b #'-',%d0			| add '-' before ea
		bsr serputchar			| output '-'
		move.b %d2,%d0			| get original instruction word
		bsr serputaddrregi		| output '(%aN)'
		bra 100f

| also used by movep, address register with word displacement
addrregidispsub:movem.l %d2-%d3,-(%sp)
6:		move.b #'(',%d0			| add '(' before ea
		bsr serputchar			| output '('
		bsr nextword			| get the displacement
		bsr hexword			| output the displacement
		move.b #',',%d0			| add ',' after displacement
		bsr serputchar			| output ','
		move.b %d2,%d0			| get original instruction word
		bsr serputaorpcreg		| output '%aN' or '%pc'
		move.b #')',%d0			| add ')' after ea
		bsr serputchar			| output ')'
		bra 100f

| this big block deals with addr reg or pc base register with byte wide and register
| displacements
7:		move.b #'(',%d0			| add '(' before extension word
		bsr serputchar			| output '(')'
		bsr nextword			| get the extension word
		move.w %d0,%d4			| get the extension word where we want it
		move.w %d4,%d0			| copy for processing offfset
		and.w #0x00ff,%d0		| mask to low byte
		bsr hexbyte			| output low byte offset (signed!)
		move.b #',',%d0			| add ',' between bytes
		bsr serputchar			| output ','
		move.w %d2,%d0			| restore original instruction word
		bsr serputaorpcreg		| output register number or pc
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

| these are all the 0b111 modes. note that the pc modes with reg set to 0b010 or 0b011,
| use the code above
10:		move.w %d2,%d0			| get original instruction word
		and.w #0x7,%d0			| mask to 3 bits
		cmp.w #0b000,%d0		| absolute word
		beq 1f				| yes, absolute word
		cmp.w #0b001,%d0		| absolute long
		beq 2f				| yes, absolute long
		cmp.w #0b010,%d0		| pc with displacement
		beq 6b				| yes, pc with displacement ^^
		cmp.w #0b011,%d0		| pc with index and displacement
		beq 7b				| yes, pc with index and displacement ^^
		cmp.w #0b100,%d0		| imm
		beq 3f				| yes, imm
		bra bad				| bad mode

1:		move.b #'(',%d0			| add '(' before absolute word
		bsr serputchar			| output '('
		bsr nextword			| get the absolute word
		bsr hexword			| output it
		move.b #')',%d0			| add ')' after ea
		bsr serputchar			| output ')'
		bra 100f

2:		move.b #'(',%d0			| add '(' before absolute long
		bsr serputchar			| output '('
		bsr nextlong			| get the absolute long
		bsr hexlong			| output it
		move.b #')',%d0			| add ')' after ea
		bsr serputchar			| output ')'
		bra 100f

3:		move.b #'#',%d0			| output '#'
		bsr serputchar			| output it
		tst.w %d6			| check width in d6
		bne 1f				| long width?
		bsr nextword			| get the imm word
		bsr hexword			| output it
		bra 100f
1:		bsr nextlong			| get the imm long
		bsr hexlong			| output it
		bra 100f

100:		movem.l (%sp)+,%d2-%d3
		rts

| printing routines

| print either %pc if d3, the mode, is set to 111 or the address register in d0
serputaorpcreg:	cmp.w #0b111,%d3		| looking for pc mode
		bne serputaddrreg		| it's not pc, print the addr reg and return
		movea.l #pcstr,%a0		| get the pc register string
		jmp serputstr			| will return

| prints the reg name for data register in d0, changing d0
serputdatareg:	and.w #0x7,%d0			| mask away unneeded bits
		lsl.w #2,%d0			| each reg is a 4 byte string
		lea (alldataregstr,%d0.w),%a0	| calc address
		bsr serputstr			| print it
		rts

| prints the reg name for address register in d0, changing d0
serputaddrreg:	and.w #0x7,%d0			| mask away unneeded bits
		lsl.w #2,%d0			| each reg is a 4 byte string
		lea (alladdrregstr,%d0.w),%a0	| calc address
		bsr serputstr			| print it
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

| simple printing routines

| hexbyte: print a byte from d0 with 0x in front
hexbyte:	movea.l #hex,%a0
		bsr serputstr
		bsr serputbyte
		rts

| hexword: print a word from d0 with 0x in front
hexword:	movea.l #hex,%a0
		bsr serputstr
		bsr serputword
		rts

| hexlong: print a long from d0 with 0x in front
hexlong:	movea.l #hex,%a0
		bsr serputstr
		bsr serputlong
		rts

ccrsub:		movea.l #ccrstr,%a0
		bsr serputstr
		rts

srsub:		movea.l #srstr,%a0
		bsr serputstr
		rts

uspsub:		movea.l #uspstr,%a0
		bsr serputstr
		rts

		.section .rodata
		.align 2

| instruction label, printable name, word match bits, word mask bits,
|   name suffix decoder, width suffix decoder, source decoder, destination decoder
instructions:	instruction ori_ccr,   "ori",	    0b0000000000111100, 0b1111111111111111, \
			null, widthbytesub, immbytesub, ccrsub
		instruction ori_sr,    "ori",	    0b0000000001111100, 0b1111111111111111, \
			null, widthwordsub, immwordsub, srsub
		instruction ori_ea,    "ori",       0b0000000000000000, 0b1111111100000000, \
			null, width76sub, immbwlsub, moderightsub

		instruction andi_ccr,  "andi",      0b0000001000111100, 0b1111111111111111, \
			null, widthbytesub, immbytesub, ccrsub
		instruction andi_sr,   "andi",      0b0000001001111100, 0b1111111111111111, \
			null, widthwordsub, immwordsub, srsub
		instruction andi_ea,   "andi"       0b0000001000000000, 0b1111111100000000, \
			null, width76sub, immbwlsub, moderightsub

		instruction subi_ea,   "subi",      0b0000010000000000, 0b1111111100000000, \
			null, width76sub, immbwlsub, moderightsub
		instruction addi_ea,   "addi",      0b0000011000000000, 0b1111111100000000, \
			null, width76sub, immbwlsub, moderightsub

		instruction eori_ccr,  "eori",      0b0000101000111100, 0b1111111111111111, \
			null, widthbytesub, immbytesub, ccrsub
		instruction eori_sr,   "eori",      0b0000101001111100, 0b1111111111111111, \
			null, widthwordsub, immwordsub, srsub
		instruction eori_ea,   "eori",      0b0000101000000000, 0b1111111100000000, \
			null, width76sub, immbwlsub, moderightsub

		instruction cmpi_ea,   "cmpi",      0b0000110000000000, 0b1111111100000000, \
			null, width76sub, immbwlsub, moderightsub

		instruction movep_wr,  "movep",     0b0000000100001000, 0b1111000110111000, \
			null, width6sub, addrregidispsub, datareg119sub
		instruction movep_wm,  "movep",     0b0000000110001000, 0b1111000110111000, \
			null, width6sub, datareg119sub, addrregidispsub

		instruction movea_wrw, "movea",     0b0011000001000000, 0b1111000111000000, \
			null, widthwordsub, moderightsub, addrreg119sub
		instruction movea_wrl, "movea",     0b0010000001000000, 0b1111000111000000, \
			null, widthlongsub, moderightsub, addrreg119sub

		instruction move_wrb,  "move",      0b0001000000000000, 0b1111000000000000, \
			null, widthbytesub, moderightsub, modeleftsub
		instruction move_wrw,  "move",      0b0011000000000000, 0b1111000000000000, \
			null, widthwordsub, moderightsub, modeleftsub
		instruction move_wrl,  "move",      0b0010000000000000, 0b1111000000000000, \
			null, widthlongsub, moderightsub, modeleftsub

		instruction btst_i,    "btst",      0b0000100000000000, 0b1111111111000000, \
			null, null, immbytesub, moderightsub
		instruction btst_dr,   "btst",      0b0000000100000000, 0b1111000111000000, \
			null, null, datareg119sub, moderightsub
		instruction bchg_i,    "bchg",      0b0000100001000000, 0b1111111111000000, \
			null, null, immbytesub, moderightsub
		instruction bchg_dr,   "bchg",      0b0000000101000000, 0b1111000111000000, \
			null, null, datareg119sub, moderightsub
		instruction bclr_i,    "bclr",      0b0000100010000000, 0b1111111111000000, \
			null, null, immbytesub, moderightsub
		instruction bclr_dr,   "bclr",      0b0000000110000000, 0b1111000111000000, \
			null, null, datareg119sub, moderightsub
		instruction bset_i,    "bset",      0b0000100011000000, 0b1111111111000000, \
			null, null, immbytesub, moderightsub
		instruction bset_dr,   "bset",      0b0000000111000000, 0b1111000111000000, \
			null, null, datareg119sub, moderightsub

		instruction mv_fr_sr,  "move",      0b0100000011000000, 0b1111111111000000, \
			null, widthwordsub, srsub, moderightsub
		instruction mv_to_ccr, "move",      0b0100010011000000, 0b1111111111000000, \
			null, widthwordsub, moderightsub, ccrsub
		instruction mv_to_sr,  "move",      0b0100011011000000, 0b1111111111000000, \
			null, widthwordsub, moderightsub, srsub

		instruction negx_ea,   "negx",      0b0100000000000000, 0b1111111100000000, \
			null, width76sub, null, moderightsub
		instruction clr_ea,    "clr",       0b0100001000000000, 0b1111111100000000, \
			null, width76sub, null, moderightsub
		instruction neg_ea,    "neg",       0b0100010000000000, 0b1111111100000000, \
			null, width76sub, null, moderightsub
		instruction not_ea,    "not",       0b0100011000000000, 0b1111111100000000, \
			null, width76sub, null, moderightsub

		instruction ext_wl,    "ext",       0b0100100010000000, 0b1111111110111000, \
			null, width6sub, null, dataregsub
		instruction nbcd_ea,   "nbcd",      0b0100100000000000, 0b1111111111000000, \
			null, null, null, moderightsub
		instruction swap_d,    "swap",      0b0100100001000000, 0b1111111111111000, \
			null, null, null, dataregsub

		instruction pea_ea,    "pea",       0b0100100001000000, 0b1111111111000000, \
			null, null, null, moderightsub

		instruction illegal,   "illegal",   0b0100101011111100, 0b1111111111111111, \
			null, null, null, null

		instruction tas_ea,    "tas",       0b0100101011000000, 0b1111111111000000, \
			null, null, null, moderightsub
		instruction tst_ea,    "tst",       0b0100101000000000, 0b1111111100000000, \
			null, width76sub, null, moderightsub

		instruction trap,      "trap",      0b0100111001000000, 0b1111111111110000, \
			null, null, null, data30sub

		instruction link,      "link",      0b0100111001010000, 0b1111111111111000, \
			null, widthwordsub, addrregsub, immwordsub
		instruction unlk,      "unlk",      0b0100111001011000, 0b1111111111111000, \
			null, null, null, addrregsub

		instruction mv_to_usp, "move",      0b0100111001100000, 0b1111111111111000, \
			null, widthlongsub, addrregsub, uspsub
		instruction mv_fr_usp, "move",      0b0100111001101000, 0b1111111111111000, \
			null, widthlongsub, uspsub, addrregsub

		instruction reset,     "reset",     0b0100111001110000, 0b1111111111111111, \
			null, null, null, null
		instruction nop,       "nop",       0b0100111001110001, 0b1111111111111111, \
			null, null, null, null
		instruction stop,      "stop",      0b0100111001110010, 0b1111111111111111, \
			null, null, null, immwordsub
		instruction rte,       "rte",       0b0100111001110011, 0b1111111111111111, \
			null, null, null, null
		instruction rts,       "rts",       0b0100111001110101, 0b1111111111111111, \
			null, null, null, null
		instruction trapv,     "trapv",     0b0100111001110110, 0b1111111111111111, \
			null, null, null, null
		instruction rtr,       "rtr",       0b0100111001110111, 0b1111111111111111, \
			null, null, null, null

		instruction jsr,       "jsr",       0b0100111010000000, 0b1111111111000000, \
			null, null, null, moderightsub
		instruction jmp,       "jmp",       0b0100111011000000, 0b1111111111000000, \
			null, null, null, moderightsub

		instruction movem_wr,  "movem",     0b0100100010000000, 0b1111111110000000, \
			null, width6sub, movemsub, moderightsub
		instruction movem_wm,  "movem",     0b0100110010000000, 0b1111111110000000, \
			null, width6sub, moderightsub, movemsub

		instruction lea,       "lea",       0b0100000111000000, 0b1111000111000000, \
			null, null, moderightsub, addrreg119sub
		instruction suba,      "suba",      0b1001000011000000, 0b1111000011000000, \
			null, width8sub, moderightsub, addrreg119sub
		instruction cmpa,      "cmpa",      0b1011000011000000, 0b1111000011000000, \
			null, width8sub, moderightsub, addrreg119sub
		instruction adda,      "adda",      0b1101000011000000, 0b1111000011000000, \
			null, width8sub, moderightsub, addrreg119sub

		instruction chk,       "chk",       0b0100000110000000, 0b1111000111000000, \
			null, widthwordsub, moderightsub, datareg119sub

		instruction dbcc,      "db",        0b0101000011001000, 0b1111000011111000, \
			condsub, null, dataregsub, dbdispsub
		instruction scc,       "s",         0b0101000011000000, 0b1111000011000000, \
			condsub, null, null, moderightsub
		instruction bra,       "bra",       0b0110000000000000, 0b1111111100000000, \
			null, widthdispsub, null, dispsub
		instruction bsr,       "bsr",       0b0110000100000000, 0b1111111100000000, \
			null, widthdispsub, null, dispsub
		instruction bcc,        "b",        0b0110000000000000, 0b1111000000000000, \
			condsub, widthdispsub, null, dispsub

		instruction moveq,     "moveq",     0b0111000000000000, 0b1111000100000000, \
			null, widthlongsub, data70sub, datareg119sub

		instruction divu,      "divu",      0b1000000011000000, 0b1111000111000000, \
			null, widthwordsub, moderightsub, datareg119sub
		instruction divs,      "divs",      0b1000000111000000, 0b1111000111000000, \
			null, widthwordsub, moderightsub, datareg119sub
		instruction mulu,      "mulu",      0b1100000011000000, 0b1111000111000000, \
			null, widthwordsub, moderightsub, datareg119sub
		instruction muls,      "muls",      0b1100000111000000, 0b1111000111000000, \
			null, widthwordsub, moderightsub, datareg119sub

		instruction sbcd,      "sbcd",      0b1000000100000000, 0b1111000111110000, \
			null, null, extrightsub, extleftsub
		instruction abcd,      "abcd",      0b1100000100000000, 0b1111000111110000, \
			null, null, extrightsub, extleftsub

		instruction subx,      "subx",      0b1001000100000000, 0b1111000100110000, \
			null, width76sub, extrightsub, extleftsub
		instruction addx,      "addx",      0b1101000100000000, 0b1111000100110000, \
			null, width76sub, extrightsub, extleftsub

		instruction addq,      "addq",      0b0101000000000000, 0b1111000100000000, \
			null, width76sub, data119sub, moderightsub
		instruction subq,      "subq",      0b0101000100000000, 0b1111000100000000, \
			null, width76sub, data119sub, moderightsub

		instruction exg_dd,    "exg"        0b1100000101000000, 0b1111000111111000, \
			null, null, datareg119sub, dataregsub
		instruction exg_aa,    "exg"        0b1100000101001000, 0b1111000111111000, \
			null, null, addrreg119sub, addrregsub
		instruction exg_da,    "exg"        0b1100000110001000, 0b1111000111111000, \
			null, null, datareg119sub, addrregsub

		instruction or_wr,     "or",        0b1000000000000000, 0b1111000100000000, \
			null, width76sub, moderightsub, datareg119sub
		instruction or_wea,    "or",        0b1000000100000000, 0b1111000100000000, \
			null, width76sub,  datareg119sub, moderightsub
		instruction and_wr,    "and",       0b1100000000000000, 0b1111000100000000, \
			null, width76sub, moderightsub, datareg119sub
		instruction and_wea,   "and",       0b1100000100000000, 0b1111000100000000, \
			null, width76sub,  datareg119sub, moderightsub

		instruction sub_wr,    "sub",       0b1001000000000000, 0b1111000100000000, \
			null, width76sub, moderightsub, datareg119sub
		instruction sub_wea,   "sub",       0b1001000100000000, 0b1111000100000000, \
			null, width76sub,  datareg119sub, moderightsub
		instruction add_wr,    "add",       0b1101000000000000, 0b1111000100000000, \
			null, width76sub, moderightsub, datareg119sub
		instruction add_wea,   "add",       0b1101000100000000, 0b1111000100000000, \
			null, width76sub,  datareg119sub, moderightsub
		instruction cmpm,      "cmpm",      0b1011000100001000, 0b1111000100111000, \
			null, width76sub, memrightsub, memleftsub
		instruction cmp,       "cmp",       0b1011000000000000, 0b1111000100000000, \
			null, width76sub, moderightsub, datareg119sub
		instruction eor,       "eor",       0b1011000100000000, 0b1111000100000000, \
			null, width76sub, datareg119sub, moderightsub

		instruction as_m,      "as",        0b1110000011000000, 0b1111111011000000, \
			shiftdirsub, widthwordsub, null, moderightsub
		instruction ls_m,      "ls",        0b1110001011000000, 0b1111111011000000, \
			shiftdirsub, widthwordsub, null, moderightsub
		instruction rox_m,     "rox",       0b1110010011000000, 0b1111111011000000, \
			shiftdirsub, widthwordsub, null, moderightsub
		instruction ro_m,      "ro",        0b1110011011000000, 0b1111111011000000, \
			shiftdirsub, widthwordsub, null, moderightsub

		instruction as_ir,     "as",        0b1110000000000000, 0b1111000000111000, \
			shiftdirsub, width76sub, data119sub, dataregsub
		instruction ls_ir,     "ls",        0b1110000000001000, 0b1111000000111000, \
			shiftdirsub, width76sub, data119sub, dataregsub
		instruction rox_ir,    "rox",       0b1110000000010000, 0b1111000000111000, \
			shiftdirsub, width76sub, data119sub, dataregsub
		instruction ro_ir,     "ro",        0b1110000000011000, 0b1111000000111000, \
			shiftdirsub, width76sub, data119sub, dataregsub

		instruction as_rr,     "as",        0b1110000000100000, 0b1111000000111000, \
			shiftdirsub, width76sub, datareg119sub, dataregsub
		instruction ls_rr,     "ls",        0b1110000000101000, 0b1111000000111000, \
			shiftdirsub, width76sub, datareg119sub, dataregsub
		instruction rox_rr,    "rox",       0b1110000000110000, 0b1111000000111000, \
			shiftdirsub, width76sub, datareg119sub, dataregsub
		instruction ro_rr,     "ro",        0b1110000000111000, 0b1111000000111000, \
			shiftdirsub, width76sub, datareg119sub, dataregsub

		.long 0				| end of table

bytewidthstr:	.asciz ".b"
wordwidthstr:	.asciz ".w"
longwidthstr:	.asciz ".l"

bytesubptr:	.long widthbytesub
wordsubptr:	.long widthwordsub
		.long widthlongsub
		.long widthbadsub

hex:		.asciz "0x"

ccrstr:		.asciz "%ccr"
srstr:		.asciz "%sr"
uspstr:		.asciz "%usp"
pcstr:		.asciz "%pc"

| each must be 4 bytes long
allregstr:
alldataregstr:
d0regstr:	.asciz "%d0"
d1regstr:	.asciz "%d1"
d2regstr:	.asciz "%d2"
d3regstr:	.asciz "%d3"
d4regstr:	.asciz "%d4"
d5regstr:	.asciz "%d5"
d6regstr:	.asciz "%d6"
d7regstr:	.asciz "%d7"
alladdrregstr:
a0regstr:	.asciz "%a0"
a1regstr:	.asciz "%a1"
a2regstr:	.asciz "%a2"
a3regstr:	.asciz "%a3"
a4regstr:	.asciz "%a4"
a5regstr:	.asciz "%a5"
a6regstr:	.asciz "%a6"
a7regstr:	.asciz "%a7"

		.align 4

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

		.align 2

allshiftdirstr:	.asciz "r"
		.asciz "l"

badinstmsg:	.asciz "<bad instruction>"
todoinstmsg:	.asciz "<todo instruction>"

		.section .bss
		.align 2

iodevice:	.long 0				| unset at start

| buffer for outputting disassembled instructions
instrdevice:	.long 0				| read is not used
		.long 0				| write function (set in code)
		.word 0				| pointer to the current byte in the buffer
instbuffer:	.space 256			| space for output buffer

wordcharcount:	.word 0				| count of chars in word output buffer
