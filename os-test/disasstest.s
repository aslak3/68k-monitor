disasstest:	ori.b #0x12,%ccr
		ori.w #0x3456,%sr
		ori.b #0x7f,%d7
		andi.l #0xdeadbeef,(%a2)
		andi.w #0x1234,%sr
		ori.l #0x12345678,-(%a4)
		ori.w #0x5678,(0x1234,%a5)
		andi.l #0x0cabba6e,0xdeadbeef
		ori.w #1,0xabcd.w
		subi.w #0x1234,%d1
		subi.l #0xdeadbeef,%d2
		addi.b #0x7f,(0x12345678)
		eori.l #0xfeedface,(0x66666666)
		eori.b #0x2a,%ccr
		btst.b #31,(%a0)
		btst #31,%d1
		btst %d0,%d1
		bchg.b #3,(0x7f,%d2.l,%a1)
		bchg %d2,%d3
		bclr.b #5,(%d2.w,%a2)
		bclr %d4,%d5
		bset.b #7,(0x100,%a3)
		bset %d6,%d7

