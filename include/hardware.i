| alpha

		.equ ALPHABASE, 0x100000
		.equ SYSCONF, ALPHABASE+0
		.equ LED, ALPHABASE+2
		.equ BUZZER, ALPHABASE+4
		.equ DMASRCHI, ALPHABASE+0x6
		.equ DMASRCLO, ALPHABASE+0x8
		.equ DMADSTHI, ALPHABASE+0xa
		.equ DMADSTLO, ALPHABASE+0xc
		.equ DMALEN, ALPHABASE+0xe
		.equ DMAFLAGS, ALPHABASE+0x10
		.equ I2CADDRESS, ALPHABASE+0x13
		.equ I2CWRITE, ALPHABASE+0x15
		.equ I2CREAD, ALPHABASE+0x17
		.equ I2CCONTROL, ALPHABASE+0x19
		.equ I2CSTATUS, ALPHABASE+0x19

		.equ ROMB, _rom_start

| beta

		.equ BETABASE, 0x101000
		.equ VGARWADDRHI, BETABASE+0
		.equ VGARWADDRLO, BETABASE+2
		.equ VGAOFFSETADDRHI, BETABASE+4
		.equ VGAOFFSETADDRLO, BETABASE+6
		.equ VGADATA, BETABASE+8
		.equ VGADATAHI, BETABASE+8
		.equ VGADATALO, BETABASE+9
		.equ VGAMODEDEFATTR, BETABASE+0xa
		.equ VGAINCREMENT, BETABASE+0xc
		.equ PS2ASTATUS, BETABASE+0xe
		.equ PS2ASCANCODE, BETABASE+0xf
		.equ PS2BSTATUS, BETABASE+0x10
		.equ PS2BSCANCODE, BETABASE+0x11
		.equ SPISELECTS, BETABASE+0x12
		.equ SPIDATA, BETABASE+0x14
		.equ TIMERCOUNT, BETABASE+0x16
		.equ SPIMDATA, BETABASE+0xe
		.equ SPIMVOL, BETABASE+0x10
|		.equ SPIMDELAY, BETABASE+0x12
|		.equ SPIMSTATUS, BETABASE+0x14
		.equ DMAMADDRHI, BETABASE+0xe
		.equ DMAMADDRLO, BETABASE+0x10
		.equ DMAMLENHI, BETABASE+0x12
		.equ DMAMLENLO, BETABASE+0x14
		.equ DMAMVOL, BETABASE+0x16
		.equ DMAMSTATUS, BETABASE+0x18
		.equ SPIMDELAY, BETABASE+0x1a

| regsiters within one port

		.equ RHR16C654, 0
		.equ THR16C654, 0
		.equ IER16C654, 2
		.equ ISR16C654, 4
		.equ FCR16C654, 4
		.equ LCR16C654, 6
		.equ MCR16C654, 8
		.equ LSR16C654, 10
		.equ MSR16C654, 12
		.equ SPR16C654, 14
		.equ DLL16C654, 0
		.equ DLM16C654, 2
		.equ EFR16C654, 4
		.equ XON116C654, 8
		.equ XON216C654, 10
		.equ XOFF116C654, 12
		.equ XOFF216C654, 14

| the base address of each port
		.equ BASE16C654, 0x102000

		.equ BASEPA16C654, BASE16C654+0
		.equ BASEPA, BASEPA16C654
		.equ BASEPB16C654, BASE16C654+16
		.equ BASEPB, BASEPB16C654
		.equ BASEPC16C654, BASE16C654+32
		.equ BASEPC, BASEPC16C654
		.equ BASEPD16C654, BASE16C654+48
		.equ BASEPD, BASEPD16C654

| ide registers

		.equ IDEBASE, 0x103000
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
