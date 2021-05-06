#include <stdint.h>

#define WRITE_BYTE(address, value) (*(uint8_t volatile *) (address)) = ((uint8_t volatile) value)
#define WRITE_WORD(address, value) (*(uint16_t volatile *) (address)) = ((uint16_t volatile) value)
#define WRITE_LONG(address, value) (*(uint32_t volatile *) (address)) = ((uint32_t volatile) value)

#define READ_BYTE(address) (*(uint8_t volatile *) (address))
#define READ_WORD(address) (*(uint16_t volatile *) (address))
#define READ_LONG(address) (*(uint32_t volatile *) (address))

/* alpha */

#define ALPHABASE 0x100000
#define SYSCONF ALPHABASE+0
#define LED ALPHABASE+2
#define BUZZER ALPHABASE+4

#define BASE16C654 0x102000
#define ROMB _rom_start

/* beta */

#define BETABASE 0x101000
#define VGARWADDRHI BETABASE+0
#define VGARWADDRLO BETABASE+2
#define VGADATA BETABASE+4
#define VGADATAHI BETABASE+4
#define VGADATALO BETABASE+5
#define VGAMODEDEFATTR BETABASE+6
#define VGAOFFSETADDR BETABASE+8
#define PS2ASTATUS BETABASE+0xa
#define PS2ASCANCODE BETABASE+0xb
#define SPISELECTS BETABASE+0xe
#define SPIDATA BETABASE+0x10
#define TIMERCOUNT BETABASE+0x12

/* regsiters within one port */

#define RHR16C654 0
#define THR16C654 0
#define IER16C654 2
#define ISR16C654 4
#define FCR16C654 4
#define LCR16C654 6
#define MCR16C654 8
#define LSR16C654 10
#define MSR16C654 12
#define SPR16C654 14
#define DLL16C654 0
#define DLM16C654 2
#define EFR16C654 4
#define XON116C654 8
#define XON216C654 10
#define XOFF116C654 12
#define XOFF216C654 14

/* the base address of each port */

#define BASEPA16C654 BASE16C654+0
#define BASEPA BASEPA16C654
#define BASEPB16C654 BASE16C654+16
#define BASEPB BASEPB16C654
#define BASEPC16C654 BASE16C654+32
#define BASEPC BASEPC16C654
#define BASEPD16C654 BASE16C654+48
#define BASEPD BASEPD16C654

/* ide registers */

#define IDEBASE 0x103000
#define IDEDATA IDEBASE+0
#define IDEERR IDEBASE+4
#define IDEFEATURES IDEBASE+4
#define IDECOUNT IDEBASE+8
#define IDELBA0 IDEBASE+12
#define IDELBA1 IDEBASE+16
#define IDELBA2 IDEBASE+20
#define IDELBA3 IDEBASE+24
#define IDEHEADS IDEBASE+24
#define IDESTATUS IDEBASE+28
#define IDECOMMAND IDEBASE+28

/* ide commands */

#define IDECOMREADSEC 0x20
#define IDECOMWRITESEC 0x30
#define IDECOMIDENTIFY 0xec
#define IDECOMFEATURES 0xef

/* ide status reg bit numbers */

#define IDESTATUSBSY 7
#define IDESTATUSDRDY 6
#define IDESTATUSDWF  5
#define IDESTATUSDSC 4
#define IDESTATUSDRQ 3
#define IDESTATUSCORR 2
#define IDESTATUSIDX  1
#define IDESTATUSERR  0

/* ide feaures */

#define IDEFEATURE8BIT 0x01

/* misc ide */

#define IDESECTORSIZE 512
