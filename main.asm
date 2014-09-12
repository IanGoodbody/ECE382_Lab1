;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Designer: C2C Ian R. Goodbody
; Organization: USAFA DFECE
;
; Summary: This program is for an eight bit calculator. The program reads data 
; and instructions from ROM and outputs the results to RAM. The calculator
; supports 5 functions: add, subtract, multiply, clear, and end.
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
;First Debug program: Checks add, sub, clr, and end. Result: 0x36, 0x3E, 0x00, 0x0C
;prgm:	.byte	0x14, 0x11, 0x32, 0x22, 0x08, 0x44, 0x04, 0x11, 0x08, 0x55

;Clr Test Case: Result 0x00, R7 = 0x12;			Verified
;prgm:	.byte 	0x13, 0x44, 0x12, 0x55

;Add Test Case: Result 0x1A, 0x42, 0x80;		Verified
;prgm:	.byte	0x16, 0x11, 0x04, 0x11, 0x28, 0x11, 0x3E, 0x55

;Add Carry Test Case: Result 0xFF				Verified
;prgm	.byte	0xFF, 0x11, 0x02, 0x55

;Subtract Test Case: Result 0xE0, 0x63, 0x00	Verified
;prgm	.byte	0xFF, 0x22, 0x1F, 0x22, 0x7D, 0x22, 0x63, 0x55

;Subtract Overflow Test Case: Result 0x00		Verified
;prgm	.byte	0x01, 0x22, 0x02

;Comp Mult Test: Result 0xFE, 0xFF, 0x00, 0x80, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x69
;prgm:	.byte	0x02, 0x33, 0x7F, 0x33, 0x02, 0x44, 0x80, 0x33, 0x01, 0x44, 0x02, 0x33, 0xFF, 0x44, 0x00, 0x33, 0xAA, 0x44, 0x0F, 0x33, 0x07, 0x55

;Inproper operand failure Test
;prgm:	.byte	0xBE, 0xEF, 0xEC, 0x55

;Basic Functionality
;prgm:	.byte	0x11, 0x11, 0x11, 0x11, 0x11, 0x44, 0x22, 0x22, 0x22, 0x11, 0xCC, 0x55

;B Functionality
;prgm:	.byte	0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0xDD, 0x44, 0x08, 0x22, 0x09, 0x44, 0xFF, 0x22, 0xFD, 0x55

;A Funtionality test
prgm:	.byte	0x22, 0x11, 0x22, 0x22, 0x33, 0x33, 0x08, 0x44, 0x08, 0x22, 0x09, 0x44, 0xff, 0x11, 0xff, 0x44, 0xcc, 0x33, 0x02, 0x33, 0x00, 0x44, 0x33, 0x33, 0x08, 0x55

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
			jz		End						; I feel as though this should be more idiot proof and give some sort of external error out. Or reset all the values that would be fun
End:
			jmp 	End						; Processor Trap
;--------------------------------------------
Add:
			add.b	1(OpAdr), result
			jc		MaxError				; Set Error if carry
			jmp		Store
;--------------------------------------------
Sub:
			sub.b	1(OpAdr), result
			jlo		MinError				; Set Error if no carry occures (result < 1(OpAdr))
			jmp		Store
;--------------------------------------------
Mult:
			mov.b	1(OpAdr), R8			; R8 is the rotating factor
			mov.b 	result, R9				; R9 is the doubling factor
			and.w 	#0x0000, result			; Clear the result register
MultChk:
			tst.b	R8						; If first factor is zero, opeartion is complete
			jz		Store
			clrc							; Clear Carry so it does not move in the rotate
			rrc.b	R8						; LSB rotated into carry bit
			jnc		SkpAdd					; Place is 0*2^n do not add
			add.b	R9, result				; Add the doubling factor into the result
			jc		MaxError				; Set error if carry from addition
SkpAdd:
			rlc.b	R9						; Double the doubling factor
			jnc		MultChk					; If doubling the factor does not overflow, end
			tst.b	R8
			jz		Store					;The doubling factor has overflowed but will not be added into the result because the the multiplication process has finished
			jmp		MaxError
;--------------------------------------------
Clr:
			mov.b	#0x00, 0(ramOut)
			mov.b	1(OpAdr), result
			jmp 	SkpStore
;--------------------------------------------
MaxError:
			mov.b	#0xFF, result
			jmp 	Store
MinError:
			mov.b	#0x00, result
Store:
			mov.b	result, 0(ramOut)
SkpStore:
			inc.w	ramOut
			incd.w	OpAdr					; Double increment to skip to next operator
			jmp 	ChkOpAdr

			jmp		MinError

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
