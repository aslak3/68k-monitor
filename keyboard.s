		.include "include/ascii.i"
		.include "include/hardware.i"
		.include "include/scancodes.i"

		.section .text
		.align 2

		.global keyboardinit
		.global conputmcuchar
		.global congetstr
		.global congetchar


keyboardinit:	move.b #0b10000011,LCR16C654+BASEPD
		move.b #0x30, DLL16C654+BASEPD  | 9600
		move.b #0, DLM16C654+BASEPD
		move.b #0b00000011, LCR16C654+BASEPD
		move.b #6,%d0
		bsr conputmcuchar
		clr.w leftshifton
		clr.w rightshifton
		clr.w capslockon
		clr.w controlon
		rts

| put the char in d0

conputmcuchar:	btst.b #5,LSR16C654+BASEPD	| busy sending last char?
		beq conputmcuchar		| yes, look again
		move.b %d0,THR16C654+BASEPD	| put that byte
		rts

| get a str in a0

congetstr:	movem.l %d0-%d1/%a0,-(%sp)	
		clr.w %d1			| set the length to 0
getstrloop:	bsr congetchar			| get a char in a
		cmp.b #ASC_CR,%d0		| cr?
		beq getstrout			| if it is, then out
		cmp.b #ASC_LF,%d0		| lf?
		beq getstrout			| if it is, then out
		cmp.b #ASC_BS,%d0		| backspace pressed?
		beq getstrbs			| handle backspace
		cmp.b #ASC_SP,%d0		| less then space ...
		blo getstrloop			| ... ignore, and get another
		btst.b #7,%d0			| top bit set?
		bne getstrloop			| .... ignore (cursor etc)
		move.b %d0,(%a0)+		| add it to string
		addq.w #1,%d1			| increment the number of chars
getstrecho:	bsr conputchar			| echo it
		bra getstrloop			| get more
getstrout:	move.b #0,(%a0)+		| add a null
		movea.l #newlinemsg,%a0		| tidy up ...
		bsr conputstr			| ... with a newline
		movem.l (%sp)+,%d0-%d1/%a0
		rts
getstrbs:	tst.w %d1			| see if the char count is 0
		beq getstrloop			| do nothing if already zero
		subq.w #1,%d1			| reduce count by 1
		move.b #0,(%a0)			| null the current char
		suba.l #1,%a0			| move the pointer back 1
		move.b #ASC_BS,%d0		|  move cursor back one
		bsr conputchar
		move.b #ASC_SP,%d0		| then erase and move forward
		bsr conputchar
		move.b #ASC_BS,%d0		| then back one again
		bsr conputchar
		bra getstrloop			| echo the bs and charry on

| get a char in d0 - guaranteed to have high byte 0

congetchar:	btst.b #0,LSR16C654+BASEPD	| chars?
		beq congetchar			| no chars yet
		clr.w %d0			| clear the top byte as well
		move.b RHR16C654+BASEPD,%d0	| get it in d0
		move.b %d0,SPIDATA
		bsr mapscancode			| translate to ascii
		tst.b %d0			| printable?
		beq congetchar			| back for more
		rts

| translate scancode in a register, returning the ascii a - if no char is
| needed then a is zero

mapscancode:	movem.l %d1/%a0,-(%sp)
		move.w #1,%d1			| default to key up
		btst.b #7,%d0			| key going up or down?
		beq keydown			| down
		clr.w %d1			| 0 for up
keydown:	andi.b #0x7f,%d0		| mask out the up/down
		cmp.b #KEY_L_SHIFT,%d0		| left shift?
		beq asciilshift
		cmp.b #KEY_R_SHIFT,%d0		| right shift?
		beq asciirshift
		cmp.b #KEY_CAPS_LOCK,%d0	| caps lock?
		beq asciicapslock
		cmp.b #KEY_CTRL,%d0		| control?
		beq asciicontrol
		tst.w %d1			| key direction?
		bne printablekey		| down, so convert it
nonprintable:	clr.b %d0			| non printable char, 0, set zero
mapscancodeo:	movem.l (%sp)+,%d1/%a0
		rts				| otherwise we are done

asciilshift:	move.w %d1,leftshifton		| set left shift pressed flag
		bra nonprintable		| done
asciirshift:	move.w %d1,rightshifton		| set right shift pressed flag
		bra nonprintable		| done
asciicapslock:	move.w %d1,capslockon		| set caps lock pressed flag
		bra nonprintable		| done
asciicontrol:	move.w %d1,controlon		| set control prssed flag
		bra nonprintable		| done

printablekey:	movea.l #unshiftmap,%a0		| assume we are not shifting
		tst.w controlon			| check control first
		bne 3f
		tst.w leftshifton		| check for left shift down
		bne 4f				| is it?
		tst.w rightshifton		| check for right shift down
		bne 4f				| is it?
1:		move.b (%d0.w,%a0),%d0		| find ascii value
		tst.w capslockon		| check for caps lock on
		beq 2f				| is it?
		bsr toupper			| otherwise uppercase the letter
2:		bra mapscancodeo		| cleanup
3:		movea.l #controlmap,%a0		| controling, use alternate table
		bra 1b				| get key
4:		movea.l #shiftmap,%a0		| shifting, use alternate table
		bra 1b				| get key

		.section .bss
		.align 2

leftshifton:    .space 2
rightshifton:   .space 2
capslockon:     .space 2
controlon:      .space 2

		.section .rodata
		.align 2

unshiftmap:

| row 0
	
		.byte ASC_ESC			| escape
		.byte ASC_NUL			| unwired
		.byte ASC_F1			| f1
		.byte ASC_F2			| f2
		.byte ASC_F3			| f3
		.byte ASC_F4			| f4
		.byte ASC_F5			| f5
		.byte ASC_NUL			| unwired

		.byte ASC_F6			| f6
		.byte ASC_NUL			| blank
		.byte ASC_F7			| f7
		.byte ASC_F8			| f8
		.byte ASC_F9			| f9
		.byte ASC_F10			| f10
		.byte ASC_HELP			| help
		.byte ASC_NUL			| unused

| row 1

		.ascii "~"
		.ascii "1"
		.ascii "2"
		.ascii "3"
		.ascii "4"
		.ascii "5"
		.ascii "6"
		.ascii "7"

		.ascii "8"
		.ascii "9"
		.ascii "0"
		.ascii "-"
		.ascii "="
		.ascii "\\"
		.byte ASC_UP			| cursor up
		.byte ASC_NUL			| unused

| row 2

		.byte ASC_HT			| tab
		.ascii "q"
		.ascii "w"
		.ascii "e"
		.ascii "r"
		.ascii "t"
		.ascii "y"
		.ascii "u"

		.ascii "i"
		.ascii "o"
		.ascii "p"
		.ascii "["
		.ascii "]"
		.byte ASC_CR			| replaced: return
		.byte ASC_LEFT			| cursor left
		.byte ASC_NUL			| unused

| row 3

		.byte ASC_NUL			| caps lock
		.ascii "a"
		.ascii "s"
		.ascii "d"
		.ascii "f"
		.ascii "g"
		.ascii "h"
		.ascii "j"

		.ascii "k"
		.ascii "l"
		.ascii "|"
		.ascii "\""
		.byte ASC_NUL			| blank
		.byte ASC_DEL			| delete
		.byte ASC_RIGHT			| cursor right
		.byte ASC_NUL			| unused

| row 4

		.byte ASC_NUL			| blank
		.ascii "z"
		.ascii "x"
		.ascii "c"
		.ascii "v"
		.ascii "b"
		.ascii "n"
		.ascii "m"

		.ascii ","
		.ascii "."
		.ascii "/"
		.byte ASC_NUL			| unwired
		.byte ASC_SP
		.byte ASC_BS			| backspace
		.byte ASC_DOWN			| cursor down
		.byte ASC_NUL			| unused

| row 5 (meta)

		.byte ASC_NUL			| right shift
		.byte ASC_NUL			| right alt
		.byte ASC_NUL			| right amiga
		.byte ASC_NUL			| ctrl
		.byte ASC_NUL			| left shift
		.byte ASC_NUL			| left alt
		.byte ASC_NUL			| left amiga

shiftmap:

| row 0

		.byte ASC_ESC			| escape
		.byte ASC_NUL			| unwired
		.byte ASC_F1			| f1
		.byte ASC_F2			| f2
		.byte ASC_F3			| f3
		.byte ASC_F4			| f4
		.byte ASC_F5			| f5
		.byte ASC_NUL			| unwired

		.byte ASC_F6			| f6
		.byte ASC_NUL			| blank
		.byte ASC_F7			| f7
		.byte ASC_F8			| f8
		.byte ASC_F9			| f9
		.byte ASC_F10			| f10
		.byte ASC_BREAK			| help
		.byte ASC_NUL			| unused

| row 1

		.ascii "`"
		.ascii "!"
		.ascii "@"
		.ascii " "
		.ascii "$"
		.ascii "%"
		.ascii "^"
		.ascii "&"

		.ascii "*"
		.ascii "("
		.ascii ")"
		.ascii "_"
		.ascii "+"
		.ascii "|"
		.byte ASC_UP			| cursor up
		.byte ASC_NUL			| unused

| row 2

		.byte ASC_HT			| tab
		.ascii "Q"
		.ascii "W"
		.ascii "E"
		.ascii "R"
		.ascii "T"
		.ascii "Y"
		.ascii "U"

		.ascii "I"
		.ascii "O"
		.ascii "P"
		.ascii "{"
		.ascii "}"
		.byte ASC_CR			| replaced: return
		.byte ASC_LEFT			| cursor up
		.byte ASC_NUL			| unused

| row 3

		.byte ASC_NUL			| caps lock
		.ascii "A"
		.ascii "S"
		.ascii "D"
		.ascii "F"
		.ascii "G"
		.ascii "H"
		.ascii "J"

		.ascii "K"
		.ascii "L"
		.ascii ":"
		.ascii "\""
		.byte ASC_NUL			| blank
		.byte ASC_DEL			| delete
		.byte ASC_RIGHT			| cursor right
		.byte ASC_NUL			| unused

| row 4

		.byte ASC_NUL			| blank
		.ascii "Z"
		.ascii "X"
		.ascii "C"
		.ascii "V"
		.ascii "B"
		.ascii "N"
		.ascii "M"

		.ascii "<"
		.ascii ">"
		.ascii "?"
		.byte ASC_NUL			| unwired
		.byte ASC_SP
		.byte ASC_BS			| backspace
		.byte ASC_DOWN			| cursor down
		.byte ASC_NUL			| unused

| row 5 (meta)

		.byte ASC_NUL			| right shift
		.byte ASC_NUL			| right alt
		.byte ASC_NUL			| right amiga
		.byte ASC_NUL			| ctrl
		.byte ASC_NUL			| left shift
		.byte ASC_NUL			| left alt
		.byte ASC_NUL			| left amiga
controlmap:

| row 0

		.byte ASC_ESC			| escape
		.byte ASC_NUL			| unwired
		.byte ASC_F1			| f1
		.byte ASC_F2			| f2
		.byte ASC_F3			| f3
		.byte ASC_F4			| f4
		.byte ASC_F5			| f5
		.byte ASC_NUL			| unwired

		.byte ASC_F6			| f6
		.byte ASC_NUL			| blank
		.byte ASC_F7			| f7
		.byte ASC_F8			| f8
		.byte ASC_F9			| f9
		.byte ASC_F10			| f10
		.byte ASC_HELP			| help
		.byte ASC_NUL			| unused

| row 1

		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_RS			| '^'
		.byte ASC_NUL			| unused

		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_US			| '_'
		.byte ASC_NUL			| unused
		.byte ASC_FS			| '\'
		.byte ASC_UP			| cursor up
		.byte ASC_NUL			| unused

| row 2

		.byte ASC_HT			| tab
		.byte ASC_DC1			| 'Q'
		.byte ASC_ETB			| 'W'
		.byte ASC_ENQ			| 'E'
		.byte ASC_DC2			| 'R'
		.byte ASC_DC4			| 'T'
		.byte ASC_EM			| 'Y'
		.byte ASC_NAK			| 'U'

		.byte ASC_HT			| 'I'
		.byte ASC_SI			| 'O'
		.byte ASC_DLE			| 'P'
		.byte ASC_ESC			| '['
		.byte ASC_GS			| ']'
		.byte ASC_CR			| return
		.byte ASC_LEFT			| cursor up
		.byte ASC_NUL			| unused

| row 3

		.byte ASC_NUL			| caps lock
		.byte ASC_SOH			| 'A'
		.byte ASC_DC3			| 'S'
		.byte ASC_EOT			| 'D'
		.byte ASC_ACK			| 'F'
		.byte ASC_BEL			| 'G'
		.byte ASC_BS			| 'H'
		.byte ASC_LF			| 'J'

		.byte ASC_VT			| 'K'
		.byte ASC_FF			| 'L'
		.byte ASC_NUL			| unused
		.byte ASC_US			| '''
		.byte ASC_NUL			| blank
		.byte ASC_DEL			| delete
		.byte ASC_RIGHT			| cursor right
		.byte ASC_NUL			| unused

| row 4

		.byte ASC_NUL			| blank
		.byte ASC_SUB			| 'Z'
		.byte ASC_CAN			| 'X'
		.byte ASC_ETX			| 'C'
		.byte ASC_SYN			| 'V'
		.byte ASC_STX			| 'B'
		.byte ASC_SO			| 'N'
		.byte ASC_CR			| 'M'

		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unused
		.byte ASC_NUL			| unwired
		.byte ASC_NUL
		.byte ASC_NUL			| backspace
		.byte ASC_DOWN			| cursor down
		.byte ASC_NUL			| unused

| row 5 (meta)

		.byte ASC_NUL			| right shift
		.byte ASC_NUL			| right alt
		.byte ASC_NUL			| right amiga
		.byte ASC_NUL			| ctrl
		.byte ASC_NUL			| left shift
		.byte ASC_NUL			| left alt
		.byte ASC_NUL			| left amiga
