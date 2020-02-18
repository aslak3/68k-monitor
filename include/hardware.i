		.equ LED, 0x100001
		.equ BUZZER, 0x100003
		.equ SYSCONF, 0x100005
		.equ SPI, 0x100007

		.equ XR88C681BASE, 0x200001
		.equ XR88C681MR1A, XR88C681BASE+0
		.equ XR88C681MR2A, XR88C681BASE+0
		.equ XR88C681SRA, XR88C681BASE+2
		.equ XR88C681CSRA, XR88C681BASE+2
		.equ XR88C681BRGEST, XR88C681BASE+4
		.equ XR88C681CRA, XR88C681BASE+4
		.equ XR88C681RHRA, XR88C681BASE+6
		.equ XR88C681THRA, XR88C681BASE+6
		.equ XR88C681IPCR, XR88C681BASE+8
		.equ XR88C681ACR, XR88C681BASE+8
		.equ XR88C681ISR, XR88C681BASE+10
		.equ XR88C681IMR, XR88C681BASE+10
		.equ XR88C681CTU, XR88C681BASE+12
		.equ XR88C681CRUR, XR88C681BASE+12
		.equ XR88C681CTL, XR88C681BASE+14
		.equ XR88C681CTLR, XR88C681BASE+14
		.equ XR88C681MR1B, XR88C681BASE+16
		.equ XR88C681MR2B, XR88C681BASE+16
		.equ XR88C681SRB, XR88C681BASE+18
		.equ XR88C681CSRB, XR88C681BASE+18
		.equ XR88C681TEST, XR88C681BASE+20
		.equ XR88C681CRB, XR88C681BASE+20
		.equ XR88C681RHRB, XR88C681BASE+22
		.equ XR88C681THRB, XR88C681BASE+22
		.equ XR88C681SCRATCH, XR88C681BASE+24
		.equ XR88C681IP, XR88C681BASE+26
		.equ XR88C681OPCR, XR88C681BASE+26
		.equ XR88C681STARTCOM, XR88C681BASE+28
		.equ XR88C681SETOPCOM, XR88C681BASE+28
		.equ XR88C681STOPCOM, XR88C681BASE+30
		.equ XR88C681RESETOPCOM, XR88C681BASE+30

| vga registers

		.equ VGABASE, 0x300001
		.equ VGADATA, VGABASE+0
		.equ VGACOLOURS, VGABASE+2
		.equ VGAMODE1, VGABASE+4
		.equ VGAMODE2, VGABASE+6
		.equ VGAWRITEADDRHI, VGABASE+8
		.equ VGAWRITEADDRLO, VGABASE+10
		.equ VGAREADADDRHI, VGABASE+8
		.equ VGAREADADDRLO, VGABASE+10
		.equ VGAOFFSETADDRHI, VGABASE+12
		.equ VGAOFFSETADDRLO, VGABASE+14

| scc68681 duart

		.equ SCC68681BASE, 0x400001
		.equ SCC68681MR1A, SCC68681BASE+0
		.equ SCC68681MR2A, SCC68681BASE+0
		.equ SCC68681SRA, SCC68681BASE+2
		.equ SCC68681CSRA, SCC68681BASE+2
		.equ SCC68681BRGEST, SCC68681BASE+4
		.equ SCC68681CRA, SCC68681BASE+4
		.equ SCC68681RHRA, SCC68681BASE+6
		.equ SCC68681THRA, SCC68681BASE+6
		.equ SCC68681IPCR, SCC68681BASE+8
		.equ SCC68681ACR, SCC68681BASE+8
		.equ SCC68681ISR, SCC68681BASE+10
		.equ SCC68681IMR, SCC68681BASE+10
		.equ SCC68681CTU, SCC68681BASE+12
		.equ SCC68681CRUR, SCC68681BASE+12
		.equ SCC68681CTL, SCC68681BASE+14
		.equ SCC68681CTLR, SCC68681BASE+14
		.equ SCC68681MR1B, SCC68681BASE+16
		.equ SCC68681MR2B, SCC68681BASE+16
		.equ SCC68681SRB, SCC68681BASE+18
		.equ SCC68681CSRB, SCC68681BASE+18
		.equ SCC68681TEST, SCC68681BASE+20
		.equ SCC68681CRB, SCC68681BASE+20
		.equ SCC68681RHRB, SCC68681BASE+22
		.equ SCC68681THRB, SCC68681BASE+22
		.equ SCC68681IVR, SCC68681BASE+24
		.equ SCC68681IP, SCC68681BASE+26
		.equ SCC68681OPCR, SCC68681BASE+26
		.equ SCC68681STARTCOM, SCC68681BASE+28
		.equ SCC68681SETOPCOM, SCC68681BASE+28
		.equ SCC68681STOPCOM, SCC68681BASE+30
		.equ SCC68681RESETOPCOM, SCC68681BASE+30

| ide registers

		.equ IDEBASE, 0x500000
		.equ IDEDATA, IDEBASE+0
		.equ IDEERR, IDEBASE+2
		.equ IDEFEATURES, IDEBASE+2
		.equ IDECOUNT, IDEBASE+4
		.equ IDELBA0, IDEBASE+6
		.equ IDELBA1, IDEBASE+8
		.equ IDELBA2, IDEBASE+10
		.equ IDELBA3, IDEBASE+12
		.equ IDEHEADS, IDEBASE+12
		.equ IDESTATUS, IDEBASE+14
		.equ IDECOMMAND, IDEBASE+14

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

| opl2

		.equ OPL2BASE, 0x600001
		.equ OPL2REGADDR, OPL2BASE+0
		.equ OPL2DATA, OPL2BASE+2
