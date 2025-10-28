		.include "../include/hardware.i"
		.include "../include/macros.i"

		.section .rodata
		.align 2

commandarray:   nocheckcommand "testing"
		endcommand 0x0

		.section .text
		.align 2

testing:	lea (msg,%pc),%a0
                bsr conputstr
                rts

		.section .rodata
		.align 2

msg:		.asciz "HELLO\r\n"
