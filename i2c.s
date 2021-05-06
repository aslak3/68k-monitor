		.include "include/macros.i"
		.include "include/hardware.i"

		.global i2cwrite
		.global i2cread
		.global i2ceewriteread
		.global i2ceepagewrite

		.section .rodata
		.align 2

| write: a0 = address, d0 = byte count, d1 = slave address

i2cwrite:	move.b #0,I2CCONTROL		| writing
		move.b %d1,I2CADDRESS		| i2c address, writing

1:		btst.b #0,I2CSTATUS
		bne 1b				| poll for not busy to send addr

i2cwriteloop:	subq.w #1,%d0			| dec bytes to go counter
		bne 1f				| skip setting last byte?
		move.b #0x01,I2CCONTROL		| last_byte = 1
1:		move.b (%a0)+,I2CWRITE		| trigger read

2:		btst.b #0,I2CSTATUS		| get status
		bne 2b				| loop until not busy

		tst.w %d0			| testing the bytes to go
		bne i2cwriteloop		| more?

		rts

| read: a0 = address, d0 = byte count, d1 = slave address
		
i2cread:	move.b #0,I2CCONTROL		| clear last_byte
		or.b #0x80,%d1			| reading
		move.b %d1,I2CADDRESS		| send it

1:		btst.b #0,I2CSTATUS
		bne 1b

i2creadloop:	subq.w #1,%d0			| dec bytes to go counter
		bne 1f				| skip setting last byte?
		move.b #0x01,I2CCONTROL		| last_byte = 1
1:		move.b #0,I2CREAD		| trigger read

2:		btst.b #0,I2CSTATUS		| get status
		bne 2b				| loop until not busy

		move.b I2CREAD,(%a0)+		| get byte and store it
		
		tst.w %d0			| testing the bytes to go
		bne i2creadloop			| more?
		
		rts
		
| i2ceewriteread: a0 = address, d0 = byte count, d1 = slave address, d2 = remote address

i2ceewriteread:	bsr i2cpreamble			| send i2c addr, remote address

		or.b #0x80,%d1			| address+read
		move.b %d1,I2CADDRESS		| set it, then wait
		
2:		btst.b #0,I2CSTATUS		| get status
		bne 2b				| loop until not busy

i2ceereadloop:	subq.w #1,%d0			| dec bytes to go counter
		bne 1f				| skip setting last byte?
		move.b #0x01,I2CCONTROL		| last_byte = 1
1:		move.b #0,I2CREAD		| trigger read

2:		btst.b #0,I2CSTATUS		| get status
		bne 2b				| loop until not busy

		move.b I2CREAD,(%a0)+		| get byte and store it
		
		tst.w %d0			| testing the bytes to go
		bne i2ceereadloop		| more?
		
		rts
		
| i2ceewritewrite: a0 = address, d0 = byte count, d1 = slave address, d2 = remote address

i2ceepagewrite:	bsr i2cpreamble			| send i2c addr, remote address

		move.b #0x20,%d0		| size of a page

i2ceewriteloop:	subq.w #1,%d0			| dec bytes to go counter
		bne 1f				| skip setting last byte?
		move.b #0x01,I2CCONTROL		| last_byte = 1
1:		move.b (%a0)+,I2CWRITE		| trigger write

2:		btst.b #0,I2CSTATUS		| get status
		bne 2b				| loop until not busy
	
		tst.w %d0			| testing the bytes to go
		bne i2ceewriteloop		| more?
		
		rts
		
| private
		
i2cpreamble:	move.b #0,I2CCONTROL		| writing
i2cpreambler:	move.b %d1,I2CADDRESS		| i2c address, writing

1:		btst.b #0,I2CSTATUS
		bne 1b				| poll for not busy

		btst.b #1,I2CSTATUS		| resend if nak
		bne i2cpreambler
		
		ror.w #8,%d2
1:		move.b %d2,I2CWRITE		| trigger read

2:		btst.b #0,I2CSTATUS		| get status
		bne 2b				| loop until not busy

		ror.w #8,%d2
1:		move.b %d2,I2CWRITE		| trigger read

2:		btst.b #0,I2CSTATUS		| get status
		bne 2b				| loop until not busy
		
		rts
