| ascii constants

| standard 0 to 32 control codes (including space)

		.equ ASC_NUL, 0x00
		.equ ASC_SOH, 0x01
		.equ ASC_STX, 0x02
		.equ ASC_ETX, 0x03
		.equ ASC_EOT, 0x04
		.equ ASC_ENQ, 0x05
		.equ ASC_ACK, 0x06
		.equ ASC_BEL, 0x07
		.equ ASC_BS, 0x08
		.equ ASC_HT, 0x09
		.equ ASC_LF, 0x0a
		.equ ASC_VT, 0x0b
		.equ ASC_FF, 0x0c
		.equ ASC_CR, 0x0d
		.equ ASC_SO, 0x0e
		.equ ASC_SI, 0x0f
		.equ ASC_DLE, 0x10
		.equ ASC_DC1, 0x11
		.equ ASC_DC2, 0x12
		.equ ASC_DC3, 0x13
		.equ ASC_DC4, 0x14
		.equ ASC_NAK, 0x15
		.equ ASC_SYN, 0x16
		.equ ASC_ETB, 0x17
		.equ ASC_CAN, 0x18
		.equ ASC_EM, 0x19
		.equ ASC_SUB, 0x1a
		.equ ASC_ESC, 0x1b
		.equ ASC_FS, 0x1c
		.equ ASC_GS, 0x1d
		.equ ASC_RS, 0x1e
		.equ ASC_US, 0x1f
		.equ ASC_SP, 0x20

| amiga 600 special chars for function and cursor keys

		.equ ASC_F1, 0x80
		.equ ASC_F2, 0x81
		.equ ASC_F3, 0x82
		.equ ASC_F4, 0x83
		.equ ASC_F5, 0x84
		.equ ASC_F6, 0x85
		.equ ASC_F7, 0x86
		.equ ASC_F8, 0x87
		.equ ASC_F9, 0x88
		.equ ASC_F10, 0x89
		.equ ASC_HELP, 0x8a
		.equ ASC_UP, 0x8b
		.equ ASC_DOWN, 0x8c
		.equ ASC_LEFT, 0x8d
		.equ ASC_RIGHT, 0x8e
		.equ ASC_DEL, 0x8f

| special uart break emulation sequence

		.equ ASC_BREAK, 0xff
