#include <stdint.h>

#define WRITE_BYTE(address, value) (*(uint8_t volatile *) (address)) = ((uint8_t volatile) value)
#define WRITE_WORD(address, value) (*(uint16_t volatile *) (address)) = ((uint16_t volatile) value)
#define WRITE_LONG(address, value) (*(uint32_t volatile *) (address)) = ((uint32_t volatile) value)

#define READ_BYTE(address) (*(uint8_t volatile *) (address))
#define READ_WORD(address) (*(uint16_t volatile *) (address))
#define READ_LONG(address) (*(uint32_t volatile *) (address))

/* Core */

#define COREBASE 0x84000000
#define LED COREBASE+0x0
#define BUZZER COREBASE+0x1
#define SYSCONF COREBASE+0x2
#define PS2ASTATUS COREBASE+0x3
#define PS2ASCANCODE COREBASE+0x4
#define PS2BSTATUS COREBASE+0x5
#define PS2BSCANCODE COREBASE+0x6
#define I2CADDRESS COREBASE+0x7
#define I2CWRITE COREBASE+0x8
#define I2CREAD COREBASE+0x9
#define I2CCONTROL COREBASE+0xa
#define I2CSTATUS I2CCONTROL
#define RTCINTCONTROL COREBASE+0xb

/* regsiters within one UART port */

#define RHR16C654 0
#define THR16C654 0
#define IER16C654 1
#define ISR16C654 2
#define FCR16C654 2
#define LCR16C654 3
#define MCR16C654 4
#define LSR16C654 5
#define MSR16C654 6
#define SPR16C654 7
#define DLL16C654 0
#define DLM16C654 1
#define EFR16C654 2
#define XON116C654 4
#define XON216C654 5
#define XOFF116C654 6
#define XOFF216C654 7

/* the base address of each port */

#define BASEPA16C654 BASE16C654+0
#define BASEPA BASEPA16C654
#define BASEPB16C654 BASE16C654+8
#define BASEPB BASEPB16C654
#define BASEPC16C654 BASE16C654+16
#define BASEPC BASEPC16C654
#define BASEPD16C654 BASE16C654+24
#define BASEPD BASEPD16C654

/* ide registers */

#define IDEBASE 0x84020000
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

/* 68230 stuff */

#define PITBASE 0x80010000

#define PITPGCR PITBASE+0x00		/* Port General Control Register */
#define PITPSRR PITBASE+0x01		/* Port Service Request Register */
#define PITPADDR PITBASE+0x02		/* Port A Data Direction Register */
#define PITPBDDR PITBASE+0x03		/* Port B Data Direction Register */

#define PITPACR PITBASE+0x06		/* Port A Control Register */
#define PITPBCR PITBASE+0x07		/* Port B Control Register */

#define PITPADR PITBASE+0x08		/* Port A Data Register */
#define PITPBDR PITBASE+0x09		/* Port B Data Register */

#define PITPAAR PITBASE+0x0a		/* Port A Data Register */
#define PITPBAR PITBASE+0x0b		/* Port B Data Register */

#define PITPSR PITBASE+0x0d			/* Port Status Regsiter */

#define PRTSTATUSERROR 0
#define PRTSTATUSNOTSELECT 1
#define PRTSTATUSNOTBUSY 2
#define PRTSTATUSPAPEROUT 3
#define PRTSTATUSNOTSELECTPRINTER 4
#define PRTSTATUSNOTLINEFEED 5
#define PRTSTATUSNOTPRTRESET 6

/* video */

#define VIDBASE 0x80200000
#define VIDX0 VIDBASE+0x0
#define VIDY0 VIDBASE+0x2
#define VIDX1 VIDBASE+0x4
#define VIDY1 VIDBASE+0x6
#define VIDPENCOLOUR VIDBASE+0x8
#define VIDLED VIDBASE+0xfc
#define VIDCOMMAND VIDBASE+0xfe
#define VIDSTATUS VIDCOMMAND

#define VIDCOMMCLEAR 0x0
#define VIDCOMMHOLLOWBOX 0x1
#define VIDCOMMFILLEDBOX 0x2
#define VIDCOMMDOT 0x3
