		.include "include/macros.i"

| memory structure - public for debugging reasons

structstart     0
member		MEM_NEXT,4			| the next memory block pointer
member		MEM_LENGTH,4			| the length of this block
member		MEM_FREE,2			| 1=free, 0=not free
structend	MEM_SIZE

| flags for memoryavail

		.equ AVAIL_TOTAL, 0
		.equ AVAIL_FREE, 1
		.equ AVAIL_LARGEST, 2

| list struct offsets

structstart	0
member		LIST_HEAD,4
member		LIST_TAIL,4
member		LIST_TAILPREV,4
structend	LIST_SIZE

| node struct offsets

structstart	0
member		NODE_NEXT,4
member		NODE_PREV,4
structend	NODE_SIZE

| system vars

		.equ HEAP_START, 0x00010000	| 64KB in
		.equ HEAP_LENGTH, 0x00080000	| 512KB

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
