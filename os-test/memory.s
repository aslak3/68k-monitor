		.include "include/system.i"

		.global memoryinit
		.global memoryalloc
		.global memoryfree

		.section .text
		.align 2

| init the heap with a single free block

memoryinit:	movem.l %d0/%a0,-(%sp)
		movea.l #HEAP_START,%a0		| get the start of the heap
		clr.l MEM_NEXT(%a0)		| no next block
		move.l #HEAP_LENGTH,MEM_LENGTH(%a0)
						| save the size of this block
		moveq.l #1,%d0			| 1 for free, 0 for used
		move.w %d0,MEM_FREE(%a0)	| save that this a free block
		movem.l (%sp)+,%d0/%a0
		rts

| allocate a block of size d0 returning it in a0. if no room then zero is returned
| and zero set in cc

memoryalloc:	add.l #MEM_SIZE,%d0		| add the overheard to the request
		movea.l #HEAP_START,%a0		| start at the start of the heap
_allocloop:	tst.w MEM_FREE(%a0)		| get the free flag
		bne _checkfree			| it's free, now check size
_checknext:	movea.l MEM_NEXT(%a0),%a0	| get the next pointer
		tst.l %a0			| see if this is zero
		bne _allocloop			| not zero, back for more
		suba.l %a0,%a0			| ... if there's no more
|		clr.l %a0
_allocout:	tst.l %a0			| set zero flag
		rts

_checkfree:	cmp.l MEM_LENGTH(%a0),%d0	| compare with size requested
		ble _blockfits			| it fits!
		bra _checknext			| back to check the next one

_blockfits:	move.w #0,MEM_FREE(%a0)		| this block isn't free
		move.l MEM_LENGTH(%a0),%d1	| get the size of this block in d1
		move.l %d0,MEM_LENGTH(%a0)	| and set the now nonfree block size
		movea.l %a0,%a1			| non free block in a0, new in a1
		adda.l %d0,%a1			| work out the start of the new free block
		sub.l %d0,%d1			| calculate the size of the new free block
		cmp.l #MEM_SIZE,%d1		| enough to make a free block?
		ble _blockfitso			| no room for a free following block
		movea.l MEM_NEXT(%a0),%a2	| get the original next block
		move.l %a1,MEM_NEXT(%a0)	| link the now non free block to new freee
		move.l %d1,MEM_LENGTH(%a1)	| save the new free size
		move.w #1,MEM_FREE(%a1)		| set the new free block as free
		move.l %a2,MEM_NEXT(%a1)	| link the new free block to the one after
_blockfitso:	adda.l #MEM_SIZE,%a0		| and header offset, caller..
		bra _allocout			| gets only the useable space

memoryfree:	suba.l #MEM_SIZE,%a0		| go back the size of the struct
		move.w #1,MEM_FREE(%a0)		| mark it as free
		rts
	