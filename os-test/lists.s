		.include "include/system.i"

		.global listinit
		.global addhead
		.global addtail
		.global remhead
		.global remtail
		.global remove

| init the list in a1 (y)

listinit:	debugprint "listinit called", SECTION_LISTS, REG_A1
		movem.l %a0,-(%sp)
		lea.l LIST_TAIL(%a1),%a0	| calc the tail node address
		move.l %a0,LIST_HEAD(%a1)	| set the dummy head
		move.l #0,LIST_TAIL(%a1)	| set the dummy tail
		lea.l LIST_HEAD(%a1),%a0	| calc the head none address
		move.l %a0,LIST_TAILPREV(%a1)	| set the dummy tail prev
		movem.l (%sp)+,%a0
		rts

| adds node at a0 to list in a1 to the head of the list

addhead:	debugprint "addhead called", SECTION_LISTS, (REG_A0+REG_A1)
		movem.l %a2,-(%sp)
		movea.l LIST_HEAD(%a1),%a2	| get the current head node
		move.l %a0,NODE_PREV(%a2)	| set the old head node's prev to the new node
		move.l %a2,NODE_NEXT(%a0)	| set the new next to the current head
		move.l %a1,NODE_PREV(%a0)	| set the new prev to the new node
		move.l %a0,LIST_HEAD(%a1)	| set the new head node to the new node
		movem.l (%sp)+,%a2
		rts

| adds node at a0 to list at a1 to the tail of the list

addtail:	debugprint "addtail called", SECTION_LISTS, (REG_A0+REG_A1)
		movem.l %a2,-(%sp)
		movea.l LIST_TAILPREV(%a1),%a2	| get the current tail node
		move.l %a0,NODE_NEXT(%a2)	| set the old head node's next to the new node
		move.l %a2,NODE_PREV(%a0)	| set the new prev to the current head
		lea.l LIST_TAIL(%a1),%a1	| move list to its tail
		move.l %a1,NODE_NEXT(%a0)	| set the new next to the new node
		move.l %a0,LIST_TAIL(%a1)	| set the new tail node to the new node
		movem.l (%sp)+,%a2
		rts

| remove head from the list in a1 returning the old head in a0

remhead:	debugprint "remhead called", SECTION_LISTS, REG_A1
		movem.l %a2,-(%sp)
		movea.l LIST_HEAD(%a1),%a0	| get the current head node
		movea.l NODE_NEXT(%a0),%a2	| get that node's next (real) node
		tst.l %a2			| need to see if list empty
		beq _remheado			| if already empty, do nothing
		move.l %a2,LIST_HEAD(%a1)	| make this the new head
		move.l %a1,NODE_PREV(%a2)	| and make this nodes prev the head
_remheado:	movem.l (%sp)+,%a2
		debugprint "removed head node" SECTION_LISTS, REG_A0
		rts

| remove tail from the list in a1 returning old tail in a0

remtail:	debugprint "remtail called", SECTION_LISTS, REG_A1
		movem.l %a1-%a2,-(%sp)		| we are modifiying the list pointer
		movea.l LIST_TAILPREV(%a1),%a0	| get the current head node
		movea.l NODE_PREV(%a0),%a2	| get that node's prev
		tst.l %a2			| need to see if list empty
		beq _remtail			| if empty, nothing to do
		move.l %a2,LIST_TAILPREV(%a1)	| make this the new tail
		adda.l #LIST_TAIL,%a1		| move to the tail end of header
		move %a1,NODE_NEXT(%a2)		| and make this nodes next the tail
_remtail:	movem.l (%sp)+,%a1-%a2		| restore u and y
		debugprint "removed tail node" SECTION_LISTS, REG_A0
		rts

| remove node at a0 from whatever list it is in

remove:		debugprint "remove called", SECTION_LISTS, REG_A0
		movem.l %a1-%a2,-(%sp)
		move.l NODE_NEXT(%a0),%a1	| get the dead nodes next
		move.l NODE_PREV(%a0),%a2	| get the dead nodes prev
		move.l %a1,NODE_NEXT(%a2)	| make the prevs next the prev
		move.l %a2,NODE_PREV(%a1)	| make the nexts prev the next
		movem.l (%sp)+,%a1-%a2
		rts
