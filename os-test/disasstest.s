disasstest:	ori.b #0x12,%ccr
		ori.w #0x3456,%sr
		ori.b #0x7f,%d7
		ori.l #0xdeadbeef,(%a2)
		ori.w #0x1234,(%a3)+
		ori.l #0x12345678,-(%a4)
		ori.w #0x5678,(0x1234,%a5)
		ori.l #0x0cabba6e,(0x2a,%a2,%d3.l)
		nop
		rts
