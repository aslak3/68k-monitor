| core

		.equ COREBASE, 0x84000000
		.equ LED, COREBASE+0x0
		.equ BUZZER, COREBASE+0x1
		.equ SYSCONF, COREBASE+0x2
		.equ PS2ASTATUS, COREBASE+0x3
		.equ PS2ASCANCODE, COREBASE+0x4
		.equ PS2BSTATUS, COREBASE+0x5
		.equ PS2BSCANCODE, COREBASE+0x6
		.equ I2CADDRESS, COREBASE+0x7
		.equ I2CWRITE, COREBASE+0x8
		.equ I2CREAD, COREBASE+0x9
		.equ I2CCONTROL, COREBASE+0xa
		.equ I2CSTATUS, I2CCONTROL
		.equ RTCINTCONTROL, COREBASE+0xb

		.equ ROMB, _rom_start

| regsiters within one port

		.equ RHR16C654, 0
		.equ THR16C654, 0
		.equ IER16C654, 1
		.equ ISR16C654, 2
		.equ FCR16C654, 2
		.equ LCR16C654, 3
		.equ MCR16C654, 4
		.equ LSR16C654, 5
		.equ MSR16C654, 6
		.equ SPR16C654, 7
		.equ DLL16C654, 0
		.equ DLM16C654, 1
		.equ EFR16C654, 2
		.equ XON116C654, 4
		.equ XON216C654, 5
		.equ XOFF116C654, 6
		.equ XOFF216C654, 7

| the base address of each port

		.equ BASE16C654, 0x84010000

		.equ BASEPA16C654, BASE16C654+0
		.equ BASEPA, BASEPA16C654
		.equ BASEPB16C654, BASE16C654+8
		.equ BASEPB, BASEPB16C654
		.equ BASEPC16C654, BASE16C654+16
		.equ BASEPC, BASEPC16C654
		.equ BASEPD16C654, BASE16C654+24
		.equ BASEPD, BASEPD16C654

| ide registers

		.equ IDEBASE, 0x84020000
		.equ IDEDATA, IDEBASE+0
		.equ IDEERR, IDEBASE+4
		.equ IDEFEATURES, IDEBASE+4
		.equ IDECOUNT, IDEBASE+8
		.equ IDELBA0, IDEBASE+12
		.equ IDELBA1, IDEBASE+16
		.equ IDELBA2, IDEBASE+20
		.equ IDELBA3, IDEBASE+24
		.equ IDEHEADS, IDEBASE+24
		.equ IDESTATUS, IDEBASE+28
		.equ IDECOMMAND, IDEBASE+28

| ide commands

		.equ IDECOMREADSEC, 0x20
		.equ IDECOMWRITESEC, 0x30
		.equ IDECOMIDENTIFY, 0xec
		.equ IDECOMFEATURES, 0xef

| ide status reg, bit numbers

		.equ IDESTATUSBSY, 7
		.equ IDESTATUSDRDY, 6
		.equ IDESTATUSDWF,  5
		.equ IDESTATUSDSC, 4
		.equ IDESTATUSDRQ, 3
		.equ IDESTATUSCORR, 2
		.equ IDESTATUSIDX,  1
		.equ IDESTATUSERR,  0

| ide feaures

		.equ IDEFEATURE8BIT, 0x01

| misc ide

		.equ IDESECTORSIZE, 512

| RTL8019

		.equ RTL8019_BASE, 0x80000000

| configuration registers initial values

		.equ RTL8019_RCR_INIT, 0x04		| accept broadcast packets and packets destined to this mac
		.equ RTL8019_IMR_INIT, 0xFF		| enable all interrupts
		.equ RTL8019_RXSTOP_INIT, 0x60		| last page of buffer in rtl8019 device
		.equ RTL8019_TXSTART_INIT, 0x40		| start page for tx buffer
		.equ RTL8019_RXSTART_INIT, 0x46		| end page for tx buffer (total pages = 6, total bytes = 6 * 256)
		.equ RTL8019_DCR_INIT, 0x58		| byte wide dma, normal operation (no loopback), send packet command executed, fifo thresh select bit 1
		.equ RTL8019_TCR_INIT, 0x00		| enable crc on tx and rx, normal operation (no loopback)

| ne2000 file registers
| page 0
		.equ RTL8019_CR    , (0x00<<1)		|  R/W   (on all pages)
		.equ RTL8019_CLDA0 , (0x01<<1)		|  R
		.equ RTL8019_PSTART, (0x01<<1)		|  W
		.equ RTL8019_CLDA1 , (0x02<<1)		|  R
		.equ RTL8019_PSTOP , (0x02<<1)		|  W
		.equ RTL8019_BNRY  , (0x03<<1)		|  R/W
		.equ RTL8019_TSR   , (0x04<<1)		|  R
		.equ RTL8019_TPSR  , (0x04<<1)		|  W
		.equ RTL8019_NCR   , (0x05<<1)		|  R
		.equ RTL8019_TBCR0 , (0x05<<1)		|  W
		.equ RTL8019_FIFO  , (0x06<<1)		|  R
		.equ RTL8019_TBCR1 , (0x06<<1)		|  W
		.equ RTL8019_ISR   , (0x07<<1)		|  R/W
		.equ RTL8019_CRDA0 , (0x08<<1)		|  R
		.equ RTL8019_RSAR0 , (0x08<<1)		|  W
		.equ RTL8019_CRDA1 , (0x09<<1)		|  R
		.equ RTL8019_RSAR1 , (0x09<<1)		|  W
		.equ RTL8019_8019ID0  , (0x0A<<1)		|  R
		.equ RTL8019_RBCR0    , (0x0A<<1)		|  W
		.equ RTL8019_8019ID1  , (0x0B<<1)		|  R
		.equ RTL8019_RBCR1    , (0x0B<<1)		|  W
		.equ RTL8019_RSR   , (0x0C<<1)		|  R
		.equ RTL8019_RCR   , (0x0C<<1)		|  W
		.equ RTL8019_CNTR0 , (0x0D<<1)		|  R
		.equ RTL8019_TCR   , (0x0D<<1)		|  W
		.equ RTL8019_CNTR1 , (0x0E<<1)		|  R
		.equ RTL8019_DCR   , (0x0E<<1)		|  W
		.equ RTL8019_CNTR2 , (0x0F<<1)		|  R
		.equ RTL8019_IMR   , (0x0F<<1)		|  W

| ne2000 file registers
| page 1
		.equ RTL8019_PAR0  , (0x01<<1)		|  R/W
		.equ RTL8019_CURR  , (0x07<<1)		|  R/W
		.equ RTL8019_MAR0  , (0x08<<1)		|  R/W

		.equ RTL8019_RDMAPORT       , (0x10<<1)

		.equ ETH_MIN_PACKET_LEN, 60	| rtl8019 cannot send packets smaller than this

