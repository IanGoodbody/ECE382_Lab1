;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .data
prgm:		.byte 0x14, 0x11, 0x32, 0x22, 0x08, 0x44, 0x04, 0x11, 0x08, 0x55
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section

ramOut	.equ	R5							; Define system variables
romIn	.equ	R6
result	.equ	R7
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------
Start:
			mov.w	#prgm, romIn
			mov.w 	#0x0200, ramOut
			mov.b 	@romIn, result
			inc.w	romIn

			cmp.b	@romIn, #0x11
			jz		Add
			cmp.b	@romIn, #0x22
			jz		Sub
			cmp.b	@romIn, #0x33
			jz		Mult
			cmp.b	@romIn, #0x44
			jz		Clr
			cmp.b	@romIn, #0x55
			jz		End

Error:
			bis.w	#0x01, &P1OUT

End:
			jmp 	End

Add:
			add.b	1(romIn), result
			jc		Error
			jmp		Store

Sub:
			sub.b	1(romIn), result
			jl		Error
			jmp		Store

Mult:
			mov.b	@romIn, R8
			mov.b 	result, R9
			and.w	#0x0000, result
			cmp.w	R8, #0x0000
MultChk:
			jz		Store
			clrc
			rrc.w	R8
			jnc		SkpAdd
			add.b	R9, result
			jc		Error
SkpAdd:
			rlc		R9
			jc		Error
			jmp		MultChk

Clr:
			mov.w	#0x0000, result
			jmp 	Store

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
