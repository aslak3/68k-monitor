| structure macros

.macro structstart offset
		structrunning=\offset
.endm

.macro member lab,offset
		.equ \lab, structrunning
		structrunning=structrunning+\offset
.endm

.macro structend lab
		.equ \lab, structrunning
.endm

