;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------

            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
;First Debug program. Checks add, sub, clr, and end. Result: 0x36, 0x3E, 0x00, 0x0C
;prgm:	.byte	0x14, 0x11, 0x32, 0x22, 0x08, 0x44, 0x04, 0x11, 0x08, 0x55

;Clr Test Case. Result 0x00, R7 = 0x12
prgm:	.byte 	0x13, 0x44, 0x12

;Add Test Case. Result 0x1A, 0x42
;prgm:	.byte	0x16, 0x11, 0x04, 0x11, 0x28

;Add Carry Test Case. Should produce error light
;prgm	.byte	0xFF, 0x11, 0x02

ramOut	.equ	R5							; Define system variables
OpAdr	.equ	R6
result	.equ	R7
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------
Start:
			bic.w	#0x01, &P1OUT			; Turn off red LED
			mov.w	#prgm, OpAdr			; Move program address into the register
			mov.w 	#0x0200, ramOut			; Set output memory address ot 0x0200
			mov.b 	@OpAdr, result			; Sets result register to first value (helps with looping)
			inc.w	OpAdr					; Set address to first operation
ChkOpAdr:
			cmp.b	#0x11, 0(OpAdr)			; Add Operation
			jz		Add
			cmp.b	#0x22, 0(OpAdr)			; Subtract Operation
			jz		Sub
			cmp.b	#0x33, 0(OpAdr)			; Multiply Operation
			jz		Mult
			cmp.b	#0x44, 0(OpAdr)			; Multiply Operation
			jz		Clr
			cmp.b	#0x55, 0(OpAdr)			; End Operation
			jz		End

Error:
			bis.w	#0x01, &P1OUT			; If error turn on Red LED

End:
			jmp 	End						; Processor Trap

Add:
			add.b	1(OpAdr), result
			jc		Error					; Set Error if carry
			jmp		Store
;--------------------------------------------
Sub:
			sub.b	1(OpAdr), result
			jl		Error					; Set Error if overflow (JL checks N xor V == 1)
			jmp		Store
;--------------------------------------------
Mult:
			mov.b	1(OpAdr), R8			; R8 is the rotating factor
			mov.b 	result, R9				; R9 is the doubling factor
			and.w	#0x0000, result			; Clear the result register
MultChk:
			cmp.b	#0x00, R8				; If first factor is zero, opeartion is complete
			jz		Store
			rrc.w	R8						; LSB rotated into carry bit, (previously cleared by cmp.b)
			jnc		SkpAdd					; Place is 0*2^n do not add
			add.b	R9, result				; Add the doubling factor into the result
			jc		Error					; Set error if carry from addition
SkpAdd:
			rlc		R9						; Double the doubling factor
			jc		Error					; If doubling the factor overflows, set error
			jmp		MultChk
;--------------------------------------------
Clr:
			mov.w	#0x0000, 0(ramOut)
			mov.w	1(OpAdr), result
			jmp 	SkpStore
;--------------------------------------------
Store:
			mov.b	result, 0(ramOut)
SkpStore:
			inc.w	ramOut
			incd.w	OpAdr					; Double increment to skip to next operator
			jmp 	ChkOpAdr

			jmp		Error

;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
