		.include "include/system.i"
		.include "../include/hardware.i"

		.section .text
		.align 2

		.global createtask
		.global newtask
		.global tickerhandler
		.global _starttask

		.global permitted

| creates a task with the intital pc in a0 and make it ready to run

createtask:	debugprint "createtask called with initial pc", SECTION_TASKS, REG_A0
		movem.l %a1,-(%sp)
		bsr newtask			| create the task in a0
		move.l #readytasks,%a1		| get the ready queue
		bsr addtail			| add it
		movem.l (%sp)+,%a1
		rts

| the lowest level, used for making a "bare" task, like the idler and init,
| a0 is the initial pc. task handle returned in a0

newtask:	debugprint "newtask called with initial pc", SECTION_TASKS, REG_A0
		movem.l %d0/%a1-%a2,-(%sp)
		move.l %a0,%a1			| copy the pc into a1
		move.l #(USTACK_SIZE+TASK_SIZE),%d0
						| get the task struct size including stack
		bsr memoryalloc			| task block now, with low of stack in a0
		lea USTACK_SIZE-UREGS_SIZE(%a0),%a2
						| a2 now points to initial task state=sp
		debugprint "inital sp", SECTION_TASKS, REG_A2
		
		lea USTACK_SIZE(%a0),%a0	| a0 now points to our task struct
		move.l %a2,TASK_SP(%a0)		| save our starting stack pointer
		move.l %a1,TASK_START_PC(%a0)	| and the intial pc (information only)
		move.w #0x0000,TASK_SR(%a0)	| not supervisor mode
		move.l %a1,TASK_PC(%a0)		| we start from here^
		move.w #0x0064,TASK_FORMAT_VECTOR(%a2)
						| format #0, autovector 1
		movem.l (%sp)+,%d0/%a1-%a2
		debugprint "newtask returning", SECTION_TASKS, REG_A0
		rts	

| make task in currenttask the current task

tickerhandler:	move.b #1,TIMERCONTROL		| clear the interrupt regardless
		tst.w permitted			| are we multitasking?
		bne 1f				| if we are then skip the return
		rte				| otherwise we are finished already

1:		move.l %sp,sspcopy		| save our current ssp
		movec %usp,%sp			| use the user sp temporarily
		movem.l %d0-%d7/%a0-%a6,-(%sp)	| stack the task state into user stack
		move.l sspcopy,%sp		| restore the old ssp

		move.l currenttask,%a0		| get the current task pointer

		move.l %usp,%a1			| get the current usp again ...
		move.l %a1,TASK_SP(%a0)		| ... so we can save it in the task struct
		move.w SREGS_SR(%sp),TASK_SR(%a0)
						| load SR from ssp into the task struct
		move.l SREGS_PC(%sp),TASK_PC(%a0)
						| and the pc
		move.w SREGS_FORMAT_VECTOR(%sp),TASK_FORMAT_VECTOR(%a0)
						| and the format/vector code

||||| schedule the next task to run, which might be the only ready task

		move.l #readytasks,%a1		| get the ready queue of tasks
		bsr remtail			| take the current task off the head
		bsr addhead			| and add it to the tail, rotating the queue

		not.b LED			| flash the LED if scheduling

_starttask:	move.l %a0,currenttask		| save the current task
		move.w #1,permitted		| now the ticker handler can complete
		move.w TASK_SR(%a0),SREGS_SR(%sp)
						| load SR into ssp from the task struct
		move.l TASK_PC(%a0),SREGS_PC(%sp)
						| and the pc
		move.w TASK_FORMAT_VECTOR(%a0),SREGS_FORMAT_VECTOR(%sp)
						| and the format/vector code
		move.l TASK_SP(%a0),%a1		| get the new task's sp
		movec %a1,%usp			| load the user stack pointer
		movem.l (%a1)+,%d0-%d7/%a0-%a6	| unstack all the registers for new task
		rte				| run this task's user code via 4 word stack

		.section .bss
		.align 4

sspcopy:	.long 0
permitted:	.word 0
