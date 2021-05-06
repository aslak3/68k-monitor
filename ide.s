		.include "include/hardware.i"

		.section .text
		.align 2

		.global ideread
		.global idewrite
		.global ideidentify

| ideread - read to memory a0 from sectors in d1, count in d0 sectors

ideread:	move.b %d0,%d2		| save sector count
		bsr seeknewpos		| seek to the current position
		move.b #IDECOMREADSEC,%d0
					| this is read sector
		bsr simpleidecomm	| send the command
		move.b %d2,%d0		| restore sector count
		bsr idellread		| read into a0
		rts

| idewrite - write from memory a0 to sectors in d1, count in d0 sectors

idewrite:	move.b %d0,%d2		| save sector count
		bsr seeknewpos		| seek to the current position
		move.b #IDECOMWRITESEC,%d0
					| this is write sector
		bsr simpleidecomm	| send the command
		move.b %d2,%d0		| restore sector count
		bsr idellwrite		| write into a0
		rts

| ideidentify - get info about the device into a0

ideidentify:	move.b #IDECOMIDENTIFY,%d0
					| the identify command
		bsr simpleidecomm	| send it
		move.b #1,%d0		| only one sector for identify
		bsr idellread		| 512 reads into a0
		bsr swapsector		| byte swap
		rts

||| IDE LOW LEVEL

| seeknewpos - sets the lba registers up for the disk block at the sector d1
| and also sets the sector count from d0

seeknewpos:	move.b %d0,IDECOUNT	| how many sectors?
		move.b %d1,IDELBA0	| this is the lowest byte in lba
		lsr.w #8,%d1		| move the high byte down
		move.b %d1,IDELBA1	| this is the 2nd lowest byte in lba
		clr.b IDELBA2		| other two lba are zero
		clr.b IDELBA3
		rts

| run the command in d2, setting lba mode, and loop until the disk reports
| the disk is no longer busy running the command

simpleidecomm:	move.b #0xe0,IDEHEADS	| lba mode
		move.b %d0,IDECOMMAND	| set the command in command reg
1:		btst.b #IDESTATUSBSY,IDESTATUS
					| get the status, loop until ...
		bne 1b			| ... not busy
		rts

| loop until status says there is data

idewaitfordata: btst.b #IDESTATUSDRQ,IDESTATUS
					| is there data?
		beq idewaitfordata	| if not, go back and read status
		rts

| read count d0 sectors into a0, saving a0

idellread:	movem.l %a0-%a1/%d1,-(%sp)	| save the start of memory
		bsr idewaitfordata	| need to wait for data, as reading
		movea.l #IDEDATA,%a1
1:		move.w #128-1,%d1	| setup the number words per sector
2:		move.l (%a1),(%a0)+	| read the word from the ide port
		dbra %d1,2b		| go back for more
		sub.w #1,%d0		| decrement sectors remaining
		bne 1b 			| more? go and get it
		movem.l (%sp)+,%a0-%a1/%d1	| restore the start of memory
		rts

| write count d0 sectors from a0, saving a0

idellwrite:	movem.l %a0-%a1/%d1,-(%sp)	| save the start of memory
		bsr idewaitfordata	| need to wait for data, as reading
		movea.l #IDEDATA,%a1
1:		move.w #128-1,%d1	| setup the number words per sector
2:		move.l (%a0)+,(%a1)	| write the word to the ide data port
		dbra %d1,2b		| go back for more
		sub.w #1,%d0		| decrement sectors remaining
		bne 1b 			| more? go and get it
		movem.l (%sp)+,%a0-%a1/%d1	| restore the start of memory
		rts


swapsector:	movem.l %a0/%d0-%d1,-(%sp)
					| save the start of memory
		move.w #256-1,%d1	| setup the number words per sector
1:		move.w (%a0),%d0	| get it
		ror.w #8,%d0		| rotate
		move.w %d0,(%a0)+	| save it out again
		dbra %d1,1b		| more?
		movem.l (%sp)+,%a0/%d0-%d1
					| restore
		rts
