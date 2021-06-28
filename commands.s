
		.include "include/macros.i"
		.include "include/ascii.i"
		.include "include/hardware.i"

		.global commandarray
		.global printbuffer
		.global clear
		.global testtextmode
		.global piano
		.global pianoend

		.section .rodata
		.align 2

| command array consists of a command string link and some userdata for
| each named command. this userdata points to another record which consists
| of a subroutine reference (the handler) and a reference to a
| zero-terminated list of maximum data types.

commandarray:	checkcommand "readbyte", 3
		checkcommand "readword", 3
		checkcommand "readlong", 3
		checkcommand "dump", 3, 3
		checkcommand "writebytes", 3, 1 + VARARG
		checkcommand "writewords", 3, 2 + VARARG
		checkcommand "writelongs", 3, 3 + VARARG
		nocheckcommand "parsertest"
		nocheckcommand "help"
		checkcommand "diskidentify", 3
		checkcommand "diskread", 3, 2, 1
		checkcommand "diskwrite", 3, 2, 1
|		checkcommand "playvgm", 3
|		nocheckcommand "stopvgm"
		nocheckcommand "showticks"
		checkcommand "clear", 3
		checkcommand "testvread", 3, 3, 3
		checkcommand "testvwrite", 3, 3, 3
		checkcommand "checksum", 3, 2
		checkcommand "memcopy", 3, 2, 3
		checkcommand "patternfillw" 3, 2
		checkcommand "patternfillb" 3, 2
		checkcommand "memfill", 3, 2, 2
|		checkcommand "showbmp", 3
		nocheckcommand "testtextmode"
|		nocheckcommand "testattribs"
|		checkcommand "setattrib", 1
		checkcommand "spitxrx", 1, 3, 2, 3, 2
|		checkcommand "sendkeyboard", 1
|		nocheckcommand "showkeyboard"
|		nocheckcommand "sawtest"
		checkcommand "download", 0x80, 3
		checkcommand "playpcm", 1, 3, 3, 1
		nocheckcommand "showscancodes"
		checkcommand "keyleds", 1
		nocheckcommand "ledon"
		nocheckcommand "ledoff"
		nocheckcommand "reset"
|		nocheckcommand "mousetest"
		checkcommand "dma", 3, 2
		nocheckcommand "memtest"
		nocheckcommand "vidmemtest"
		nocheckcommand "anajoytest"
		checkcommand "i2ctx", 1, 3, 2
		checkcommand "i2crx", 1, 3, 2
		checkcommand "eepromread", 1, 3, 2, 2
		checkcommand "eepromwrite", 1, 3, 2, 2
|		checkcommand "spimplay", 3, 3, 2, 2
		checkcommand "dmaplay", 3, 3, 2
		checkcommand "playpiano", 2, 2
		checkcommand "playscale", 3
		checkcommand "spimdata", 2
		checkcommand "spimvol", 2
		endcommand		

		.section .text
		.align 2

| all commands: on entry a0 will be the type (word) array, and a1 will be the
| value (long) array.

| read the byte, word or long at the first argument and display it.


readbyte:	movea.l (0,%a1),%a0		| get the first argument
		move.b (%a0),%d0		| get the byte at that addr
		movea.l #printbuffer,%a0	| set the output buffer
		bsr bytetoascii			| convert into a0
		bra readcommon			| add newline and print

readword:	movea.l (0,%a1),%a0		| get the first argument
		move.w (%a0),%d0		| get the word at that addr
		movea.l #printbuffer,%a0	| set the output buffer
		bsr wordtoascii			| convert into a0
		bra readcommon			| add newline and print

readlong:	movea.l (0,%a1),%a0		| get the first argument
		move.l (%a0),%d0		| get the long at that addr
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		bra readcommon			| add newline and print

readcommon:	lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it
		rts

| dump out (in words) from the first argument the length, the second
| argument (a byte count). the output includes the location, the hex,
| and the ascii, with unprintable chars showing as a dot. through this code:
|
| a0=the lilne buffer, a1=a string to concatenate, d0=coverted digits,
| d1=bytes left in total, d2=words or bytes left in this line,
| d3=up count of d2.

		.section .text
		.align 2

dump:		movea.l (0*4,%a1),%a2		| get the start addr (a2)
		move.l (1*4,%a1),%d1		| get the length (d1)
		and.l #0xfffffff0,%d1		| round length, whole lines

| print the address first.

1:		movea.l #printbuffer,%a0	| setup the print buffer

		move.l %a2,%d0			| we need to convert the ...
		bsr longtoascii			| ... current address

		move.b #ASC_SP,(%a0)+		| add a space
		move.b #ASC_SP,(%a0)+		| add another space

| now the 16 bytes, in groups of words

		move.w #8-1,%d2			| 8 words across
		clr.w %d3			| up counter of words
2:		move.w (%d3.w,%a2),%d0		| read the word
		bsr wordtoascii			| add it to the output
		move.b #ASC_SP,(%a0)+		| add a space
		cmp.w #4,%d2			| look for middle word
		bne 3f				| no extra space
		move.b #ASC_SP,(%a0)+		| add a extra space
3:		addq.w #2,%d3			| inc, in words, up counter
		dbra %d2,2b			| more words?

		move.b #ASC_SP,(%a0)+		| only need one space

| ascii display

		move.b #'[',(%a0)+		| add a bracket
		move.w #16-1,%d2		| 16 bytes (chars) to print
		clr.w %d3			| up counter of words
4:		move.b (%d3.w,%a2),%d0		| read the byte
		bsr makecharprint		| convert it to dot?
		move.b %d0,(%a0)+		| add it to the stream
		addq.w #1,%d3			| inc up counter
		dbra %d2,4b			| more ascii?
		move.b #']',(%a0)+		| close the brackets

| finish up and print the line

		lea.l (newlinemsg,%pc),%a1	| finish with ...
		bsr strconcat			| ... a new line

		movea.l #printbuffer,%a0	| now we can ...
		bsr conputstr			| ... print this line!

		adda.l #0x10,%a2		| move to next chunk
		sub.l #0x10,%d1			| adjust the byte count
		bne 1b				| back for more lines

		rts

| writebytes, writewords and writelongs: write a list of values to memory

writeprelim:	movea.l %a1,%a2			| where to find what writing
		adda.l #4,%a2			| onto second arg
		movea.l (0,%a1),%a1		| where we are writing to
		adda.l #2,%a0			| move to second type
		rts

writebytes:	bsr writeprelim			| setup
1:		tst.w (%a0)+			| see if we are at end
		beq 2f				| yes? out
		move.b (3,%a2),(%a1)+		| write the byte
		adda.l #4,%a2			| move to next value
		bra 1b
2:		rts

writewords:	bsr writeprelim			| setup
1:		tst.w (%a0)+			| see if we are at end
		beq 2f				| yes? out
		move.w (2,%a2),(%a1)+		| write the byte
		adda.l #4,%a2			| move to next value
		bra 1b
2:		rts

writelongs:	bsr writeprelim			| setup
1:		tst.w (%a0)+			| see if we are at end
		beq 2f				| yes? out
		move.l (0,%a2),(%a1)+		| write the byte
		adda.l #4,%a2			| move to next value
		bra 1b
2:		rts

| test the parser: output the bytes, words and longs.

		.section .text
		.align 2

parsertest:	movea.l %a0,%a2			| arg type table into a2
1:		move.w (%a2)+,%d0		| get the current type
		beq 2f				| end of list?
		movea.l #printbuffer,%a0	| start of print buffer
		lea (typemsg,%pc),%a1		| add the type label
		bsr strconcat			| ...
		bsr wordtoascii			| convert d0 and append
		lea (spacesmsg,%pc),%a1		| add a space
		bsr strconcat			| ...

		lea (valuemsg,%pc),%a1		| value label
		bsr strconcat			| add it
		move.l (%a3)+,%d0		| get the value
		bsr longtoascii			| add the value to a0

		lea (newlinemsg,%pc),%a1	| end with a newline
		bsr strconcat			| append it

		movea.l #printbuffer,%a0	| wind a0 back to start
		bsr conputstr			| and print it

		bra 1b

2:		rts

		.section .rodata
		.align 2

typemsg:        .asciz "Type: "
valuemsg:       .asciz "Value: "

| display help message.

		.section .text
		.align 2

help:		lea (helpmsg,%pc),%a0		| get the help message
		bsr conputstr			| print it
		rts

		.section .rodata
		.align 2

helpmsg:	.ascii "Memory/IO:\r\n"
		.ascii "    readbyte addr.l : read byte at addr\r\n"
		.ascii "    readword addr.l : read word at addr\r\n"
		.ascii "    readlong addr.l : read long at addr\r\n"
		.ascii "    dump addr.l length.l : dump from addr, length bytes in ascii and hex\r\n"
		.ascii "    writebytes addr.l [value.b ...] : write bytes at addr\r\n"
		.ascii "    writewords addr.l [value.w ...] : write words at addr\r\n"
		.ascii "    writelongs addr.l [value.l ...] : write longs at addr\r\n"
		.ascii "Disk:\r\n"
		.ascii "    diskidentify addr.l : write disk identify data at addr\r\n"
		.ascii "    diskread addr.l sector.w count.b : read  sector, count 512B sectors\r\n"
		.ascii "    diskwrite addr.l sector.w count.b : write sector, count 512B sectors\r\n"
|		.ascii "Video Game Music:\r\n"
|		.ascii "    playvgm addr.l : play VGM file from memory at addr\r\n"
|		.ascii "    stopvgm : stop VGM playback\r\n"
		.ascii "Other:\r\n"
|		.ascii "    showticks : show the tick count in 1/44100 seconds\r\n"
		.ascii "    parsertest [foo.l] [bar.w] [baz.b] ... : test the parser\r\n"
		.ascii "    testvread addr.l start.w count.w : test video read into addr\r\n"
		.ascii "    testvwrite addr.l start.w count.w : test video write from addr\r\n"
		.ascii "    checksum addr.l count.w : checksum memory, connt in longs\r\n"
		.ascii "    clear data.l : clear the screen with data\r\n"
		.ascii "    help : this help.\r\n"
		.asciz ""

		.section .text
		.align 2

diskidentify:	movea.l (0*4,%a1),%a0		| get address to write in
		bsr ideidentify			| do the identify command
		rts

diskread:	movea.l (0*4,%a1),%a0		| get address to write in
		move.l (1*4,%a1),%d1		| get the start sector
		move.l (2*4,%a1),%d0		| and the count
		bsr ideread			| do the read command
		rts

diskwrite:	movea.l (0*4,%a1),%a0		| get address to write in
		move.l (1*4,%a1),%d1		| get the start sector
		move.l (2*4,%a1),%d0		| and the count
		bsr idewrite			| do the write command
		rts

|playvgm:	movea.l (0*4,%a1),%a6		| get the start addr into a6
|		bsr vgmplayer			| start the playback
|		rts

|stopvgm:	bsr vgmstop			| simple wrapper
|		rts

showticks:	move.l timerticks,%d0
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it
		move.l vblticks,%d0
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it
		rts

clear:		move.l (0*4,%a1),%d2
		bsr conclear
		rts

testvread:	movea.l (0*4,%a1),%a0		| get address to write in
		move.l (1*4,%a1),%d1		| get the start
		move.l (2*4,%a1),%d0		| and the count in words
		move.l %d1,VGARWADDRHI		| one hit
		movea.l #VGADATA,%a1
		move.w (%a1),%d1		| dumamy read
1:		move.w (%a1),(%a0)+
		subq.l #1,%d0
		bne 1b
		rts

testvwrite:	movea.l (0*4,%a1),%a0		| get address to read from
		move.l (1*4,%a1),%d1		| get the start
		move.l (2*4,%a1),%d0		| and the count in words
		move.w #0,VGARWADDRHI
		move.w %d1,VGARWADDRLO		| one hit
		movea.l #VGADATA,%a1
1:		move.w (%a0)+,(%a1)
		subq.w #1,%d0			| used in dbra
		bne 1b

		rts

memcopy:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
		movea.l (2*4,%a1),%a1		| get the detstination
1:		move.l (%a0)+,(%a1)+		| copy the long
		dbra %d1,1b			| more?
		rts

patternfillw:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
1:		move.w %d1,(%a0)+		| write the counter
		dbra %d1,1b
		rts

patternfillb:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
1:		move.b %d1,(%a0)+		| write the counter
		dbra %d1,1b
		rts

memfill:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		move.w (2*4+2,%a1),%d0
		subq.w #1,%d1			| used in dbra
1:		move.w %d0,(%a0)+		| write the counter
		dbra %d1,1b
		rts



checksum:	movea.l (0*4,%a1),%a0		| get address to read from
		move.w (1*4+2,%a1),%d1		| get the length
		subq.w #1,%d1			| used in dbra
		clr.l %d0			| clear sum
1:		add.l (%a0)+,%d0		| sum it
		dbra %d1,1b			| back for more
		movea.l #printbuffer,%a0	| set the output buffer
		bsr longtoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it
		rts

|showbmp:	movea.l (0*4,%a1),%a0		| get the address of bmp
|		bsr bmpshow			| display and wait
|		rts		

testtextmode:	move.w #80*60,%d0
		bsr conclear
		clr.w %d1
1:		move.w %d1,VGADATA		| character
		add.w #0x0101,%d1
		dbra %d0,1b
		bsr congetchar
		bsr conclear
		rts

|testattribs:	move.w #4-1,%d2
|		move.w #0,VGARWADDRLO
|		clr.w %d1
|		movea.l #VGADATA,%a0
|2:		move.w #640/16*480,%d0		| count of words
|1:		move.w #0x00ff,(%a0)
|		move.w #0xff00,(%a0)
|		dbra %d0,1b
|		bsr congetchar
|		move.w #0,VGARWADDRLO
|		dbra %d2,2b
|		bsr conclear
|		rts

|setattrib:	move.b (0*4+3,%a1),attributes
|		rts


spitxrx:	movea.l %a1,%a6
		movea.l (1*4,%a6),%a1		| get source
		move.w (2*4+2,%a6),%d1		| get the length to read
		movea.l (3*4,%a6),%a2		| get destination
		move.w (4*4+2,%a6),%d2		| get the length to write
		move.b (0*4+3,%a6),SPISELECTS
		tst.w %d1
		beq spirx

spitx:		subq.w #1,%d1			| dbra
1:		move.b (%a1)+,SPIDATA		| get byte to send
		dbra %d1,1b

spirx:		tst.w %d2
		beq done
		subq.w #1,%d2			| dbra
2:		clr.b %d0
		move.b #0,SPIDATA
		nop
		move.b SPIDATA,(%a2)+
		dbra %d2,2b
done:		move.b #0,SPISELECTS
		rts

anajoytest:	move.b #0x03,SPISELECTS
		move.b #0x68,SPIDATA
		nop
		nop
		move.b SPIDATA,%d0
		lsl.w #8,%d0
		move.b #0,SPIDATA
		nop
		nop
		move.b SPIDATA,%d0

		movea.l #printbuffer,%a0	| set the output buffer
		bsr wordtoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it

		move.b #0,SPISELECTS
		move.w #0xffff,%d0
1:		dbra %d0,1b
		bra anajoytest
		
i2ctx:		move.b (0*4+3,%a1),%d1		| i2c address
	    	movea.l (1*4,%a1),%a0		| start addr
		move.w (2*4+2,%a1),%d0		| length

		bsr i2cwrite
		
		rts
		
i2crx:		move.b (0*4+3,%a1),%d1		| i2c address
	    	movea.l (1*4,%a1),%a0		| start addr
		move.w (2*4+2,%a1),%d0		| length

		bsr i2cread
		
		rts

eepromread:	move.b (0*4+3,%a1),%d1		| i2c address
		move.l (1*4,%a1),%a0		| local address
		move.w (2*4+2,%a1),%d0		| length
		move.w (3*4+2,%a1),%d2		| remote address

		bsr i2ceewriteread
		
		rts

eepromwrite:	move.b (0*4+3,%a1),%d1		| i2c address
		move.l (1*4,%a1),%a0		| local address
		move.w (2*4+2,%a1),%d3		| length in pages
		move.w (3*4+2,%a1),%d2		| remote address

1:		bsr i2ceepagewrite
		add.w #0x20,%d2
		subq.w #1,%d3
		bne 1b
		
		rts
		
|sendkeyboard:	move.b (0*4+3,%a1),%d0
|		bsr conputmcuchar
|		rts

|showkeyboard:	bsr congetchar
|		move.b %d0,%d1
|		cmp.b #ASC_ESC,%d0
|		beq showkeyboardo
|		bsr serputchar
|		bra showkeyboard
|showkeyboardo:	rts

sawtest:	move.w #0x3000,%d0
		move.w #0xff-1,%d1
|1:		bsr sendspiword
		addi.w #0x10,%d0
		dbra %d1,1b
		move.w #0xff-1,%d1
|2:		bsr sendspiword
		subi.w #0x10,%d0
		dbra %d1,2b
		bra sawtest

download:	movea.l (0*4,%a1),%a0
		movea.l (1*4,%a1),%a2

		move.b #1,%d0
		bsr dlputchar
		bsr dlputstr
		clr.b %d0
		bsr dlputchar

		bsr dlgetchar			| ignore response for now

		move.w #4-1,%d1
		clr.l %d2
1:		lsl.l #8,%d2
		bsr dlgetchar
		move.b %d0,%d2
		dbra %d1,1b			| d2 now has length

		movea.l #printbuffer,%a0	| wind a0 back to start
		lea (filesizemsg,%pc),%a1	| value label
		bsr strconcat			| add it
		move.l %d2,%d0
		bsr longtoascii			| add the value to a0

		lea (newlinemsg,%pc),%a1	| end with a newline
		bsr strconcat			| append it

		movea.l #printbuffer,%a0	| wind a0 back to start
		bsr conputstr			| and print it

		move.b #1,%d0			| load the go signal
		bsr dlputchar			| and send it

2:		tst.l %d2
		beq 4f

		bsr dlgetchar
		move.b %d0,(%a2)+		| save the read byte

		tst.b %d2			| look at lowest byte
		bne 3f				| not zero, don't print
		move.b #'.,%d0			| print . every 256 bytes
		bsr conputchar

3:		subq.l #1,%d2
		bra 2b

4:		lea (newlinemsg,%pc),%a0	| end with a newline
		bsr conputstr			| and print it

		rts

		.section .rodata
		.align 2

filesizemsg:	.asciz "File size: "

|		.section .text
|		.align 2

playpcm:	move.b (0*4+3,%a1),%d2
		movea.l (1*4,%a1),%a0
		move.l (2*4,%a1),%d1
		move.w (3*4+2,%a1),%d0

		lsl.w #4,%d0
		or.w #0xb000,%d0
		ror.w #8,%d0
		move.b %d2,SPISELECTS
		move.b %d0,SPIDATA
		ror.w #8,%d0
		move.b %d0,SPIDATA
		move.b #0,SPISELECTS

1:		clr.w %d0
		move.b (%a0)+,%d0
		lsl.w #4,%d0
		or.w #0x3000,%d0
		ror.w #8,%d0
		move.b %d2,SPISELECTS
		move.b %d0,SPIDATA
		ror.w #8,%d0
		move.b %d0,SPIDATA
		move.b #0,SPISELECTS
		
2:		move.w #0x10,%d0
3:		dbra %d0,3b

		subq.l #1,%d1
		bne 1b

		rts

showscancodes:	btst.b #0,PS2ASTATUS
		beq showscancodes
		move.b PS2ASCANCODE,%d0
		movea.l #printbuffer,%a0	| set the output buffer
		bsr bytetoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it
		bra showscancodes		

keyleds:	move.b #0xed,PS2ASCANCODE
		move.w #0x2000,%d0
1:		dbra %d0,1b
		move.b (0*4+3,%a1),PS2ASCANCODE
		rts

ledon:		move.w #1,LED
		rts

ledoff:		move.w #0,LED
		rts

reset:		reset
		bra start

dma:		move.l #0,VGARWADDRHI
		move.l (0*4,%a1),DMASRCHI
		move.w (1*4+2,%a1),DMALEN
		move.w #0x0003,DMAFLAGS
		rts

memtest:	move.l #0,VGARWADDRHI
		move.l #0,%d0
1:		bsr setmemtolong
		bsr cmpmemtolong
		swap.w %d0
		move.w %d0,VGADATA
		move.w %d0,VGADATA
		swap.w %d0
		move.w %d0,VGADATA
		move.w %d0,VGADATA
		add.l #0xfedcba98,%d0
		bra 1b		
		rts

vidmemtest:	move.w #0,%d0
1:		bsr vsetmemtoword
		bsr vcmpmemtoword
		add.w #0xaa55,%d0
		movea.l #printbuffer,%a0	| set the output buffer
		bsr wordtoascii			| convert into a0
		lea (newlinemsg,%pc),%a1	| need a newline
		bsr strconcat			| add it
		movea.l #printbuffer,%a0	| wind buffer back
		bsr conputstr			| and print it

		bra 1b		
		rts

|spimplay:	movea.l #SPIMSTATUS+1,%a2
|		movea.l #SPIMDATA,%a3
|
|		movea.l (0*4,%a1),%a0		| address
|		move.l (1*4,%a1),%d1		| length
|		move.w (2*4+2,%a1),SPIMDELAY	| delay
|
|		move.w (3*4+2,%a1),SPIMVOL	| set volume
|
|1:		btst.l #0,(%a2)
|		bne 1b
|
|spimplaystart:	tst.l %d1
|		beq 2f
|
|1:		btst.b #0,(%a2)
|		bne 1b
|
|		move.w (%a0)+,(%a3)
|		
|		subq.l #1,%d1
|		bra spimplaystart
|
|2:		rts

dmaplay:	move.l (0*4,%a1),DMAMADDRHI	| address
 		move.l (1*4,%a1),DMAMLENHI	| length
		move.w (2*4+2,%a1),SPIMDELAY	| delay
		rts

playpiano:	move.l #0x8000,DMAMADDRHI
		move.l #pianoend-piano,DMAMLENHI
		move.w (0*4+2,%a1),DMAMVOL
		move.w (1*4+2,%a1),SPIMDELAY
		rts		

playscale:	movea.l #notetable,%a0
		move.w #0xf0f0,%d1
1:		move.l (0*4,%a1),%d0
		move.l #0x8000,DMAMADDRHI
		move.w %d1,DMAMVOL
		sub.w #0x1010,%d1
		move.l #pianoend-piano,DMAMLENHI
		move.w (%a0)+,SPIMDELAY
2:		subq.l #1,%d0
		bne 2b
		tst.w (%a0)
		bne 1b
		rts

spimdata:	move.w #1,SPIMDELAY
		move.w (0*4+2,%a1),SPIMDATA
		rts
spimvol:	move.w #1,SPIMDELAY
		move.w (0*4+2,%a1),SPIMVOL
		rts



		.section .rodata
		.align 2

notetable:
		.word 1133
		.word 1070
		.word 1010
		.word 953
		.word 899
		.word 849
		.word 801
		.word 756
		.word 714
		.word 674
		.word 636
		.word 600
		.word 566
		.word 535
		.word 505
		.word 476
		.word 449
		.word 424
		.word 400
		.word 378
		.word 357
		.word 337
		.word 318
		.word 300
		.word 283
		.word 0

piano:		.word 0
		.incbin "piano.raw"
pianoend:
		.section .bss
		.align 2

| shared buffer used for printing.

printbuffer:	.space 256

