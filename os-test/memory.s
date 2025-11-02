		.include "include/system.i"

		.global memoryinit
		.global memoryalloc
		.global memoryfree

		.section .text
		.align 2

| init the heap with a single free block

memoryinit:	debugprint "memoryinit called", SECTION_MEMORY, 0
		movem.l %d0/%a0,-(%sp)
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

memoryalloc:	debugprint "memoryalloc called with", SECTION_MEMORY, REG_D0
		movem.l %d1/%a1,-(%sp)
		add.l #MEM_SIZE,%d0		| add the overheard to the request
		movea.l #HEAP_START,%a0		| start at the start of the heap
_allocloop:	tst.w MEM_FREE(%a0)		| get the free flag
		bne _checkfree			| it's free, now check size
_checknext:	movea.l MEM_NEXT(%a0),%a0	| get the next pointer
		tst.l %a0			| see if this is zero
		bne _allocloop			| not zero, back for more
		suba.l %a0,%a0			| ... if there's no more
_allocout:	tst.l %a0			| set zero flag
		movem.l (%sp)+,%d1/%a1
		debugprint "memoryalloc returning", REG_A0
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

| frees the block - passed a block pointer in a0 as obtained from memoryalloc

memoryfree:	debugprint "memoryfree called with", SECTION_MEMORY, REG_A0
		movem.l %d0/%a1,-(%sp)
		suba.l #MEM_SIZE,%a0		| go back the size of the struct
		move.w #1,MEM_FREE(%a0)		| mark it as free

| now we are going to try to squash free blocks together, starting at the top and
| looking for  two free blocks next to each other

		movea.l #HEAP_START,%a1		| start at the start of the heap
_squashloop:	movea.l %a1,%a0			| start with current=next
		movea.l MEM_NEXT(%a0),%a1	| get the next pointer in a1
		tst.l %a1			| check this isn't null
		beq _memoryfreeout		| end of list
		tst.w MEM_FREE(%a0)		| checking the free flag
		bne _squashnext			| it's free, now check next one
		tst.l %a1			| see if next is zero
		bne _squashloop			| not zero, back for more
_memoryfreeout:	movem.l (%sp)+,%d0/%a1
		rts

_squashnext:	tst.w MEM_FREE(%a1)		| see if next is free
		beq _squashloop			| not free, can't squash it
		move.l MEM_LENGTH(%a0),%d0	| get length of current
		add.l MEM_LENGTH(%a1),%d0	| add on length of next
		move.l %d0,MEM_LENGTH(%a0)	| set new length in current
		movea.l MEM_NEXT(%a1),%a1	| get next's next pointer
		move.l %a1,MEM_NEXT(%a0)	| set it to hop over next
		debugprint "memoryfree squashed a block", SECTION_MEMORY, (REG_D0+REG_A0)
		bra _memoryfreeout		| finished, next is bypassed
