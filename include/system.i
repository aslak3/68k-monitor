		.equ REG_COUNT, (2*8)

| debug

		.equ REG_D0, (1 << 0)
		.equ REG_D1, (1 << 1)
		.equ REG_D2, (1 << 2)
		.equ REG_D3, (1 << 3)
		.equ REG_D4, (1 << 4)
		.equ REG_D5, (1 << 5)
		.equ REG_D6, (1 << 6)
		.equ REG_D7, (1 << 7)

		.equ REG_A0, (1 << 8)
		.equ REG_A1, (1 << 9)
		.equ REG_A2, (1 << 10)
		.equ REG_A3, (1 << 11)
		.equ REG_A4, (1 << 12)
		.equ REG_A5, (1 << 13)
		.equ REG_A6, (1 << 14)
		.equ REG_A7, (1 << 15)

		.equ STR_A0, (1 << 16)
		.equ STR_A1, (1 << 17)
		.equ STR_A2, (1 << 18)
		.equ STR_A3, (1 << 19)
		.equ STR_A4, (1 << 20)
		.equ STR_A5, (1 << 21)
		.equ STR_A6, (1 << 22)
		.equ STR_A7, (1 << 23)

		.equ SECTION_MONITOR, (1 << 0)

		.equ SECTION_MEMORY, (1 << 16)
		.equ SECTION_LISTS, (1 << 17)
		.equ SECTION_TASKS, (1 << 18)
		.equ SECTION_DEBUGGER, (1 << 19)

		| .equ DEBUG_SECTIONS, (SECTION_MONITOR+SECTION_MEMORY+SECTION_LISTS+SECTION_TASKS+SECTION_DEBUGGER)
		.equ DEBUG_SECTIONS, 0

