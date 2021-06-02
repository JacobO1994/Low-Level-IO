TITLE Designing low-level I/O procedures      (Proj6_934329706.asm)

; Author: Jacob Ogle
; Last Modified: May 24th, 2021
; OSU email address: ogleja@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: June 6th 2021
; Description: A low level I/O program that takes reads a string from a user and displays various numerical data elements of that string
;

INCLUDE Irvine32.inc
; Macros

; ---------------------------------------------------------------------------------
; Name: 
;
;
; Preconditions: 
;
; Receives:
;
; Returns:
; ---------------------------------------------------------------------------------
mGetString MACRO
	; Save used registers
	push	edx
	push	ecx
	push	eax
	push	edi
	; Display Prompt
	mov		edx, [ebp+16]
	call	WriteString
	; Read user input string to inputBuffer
	mov		edx, [ebp + 20]
	mov		ecx, SIZEOF	inputBuffer
	call	ReadString
	; Store number of input bytes to the numbOfBytes mem location
	mov		edi, [ebp + 24]
	mov		[edi], eax
	; Restore registers
	pop		edi
	pop		eax
	pop		ecx
	pop		edx
ENDM

; ---------------------------------------------------------------------------------
; Name: 
;
;
; Preconditions: 
;
; Receives:
;
; Returns:
; ---------------------------------------------------------------------------------
mDisplayString MACRO
_nextInString:
	mov		edx, [ebp + 12]
	call	WriteString
ENDM

; Constants
MAX_SIZE_REG = 2147483647

.data
; Prompts
programInfo		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",
						"Written by: Jacob Ogle",13,10,0	
programRules	BYTE	"Please provide 10 signed decimal integers. Each number needs",
						"to be small enough to fit inside a 32 bit register. After you",
						"have finished inputting the raw numbers I will display a list",
						"of the integers, their sum, and their average value.",13,10,0
enterInteger	BYTE	"Please enter an signed number: ",0
errorMsg		BYTE	"ERROR: You did not enter a signed number or your number was too big. - try again",13,10,0
tryAgain		BYTE	"Please try again: ",0
enteredFollo	BYTE	"You entered the following numbers: ",13,10,0
theSumOfNums	BYTE	"The sum of these numbers is: ",0
theRoundAvg		BYTE	"The rounded average is: ",0
thanks			BYTE	"Thanks for playing!",0

; Arrays
validInputs		SDWORD	10 DUP(?)
inputBuffer		BYTE	12 DUP(0)
numbOfBytes		BYTE	?
asciiOutBuffer	BYTE	12 DUP(?)

; Values
validatedInput	SDWORD	?				; Stores the validated input from ReadVal

; Boolean Flags
signBool		BYTE	0
invalidBool		BYTE	0

.code
main PROC
	mov		edx, offset programInfo
	call	WriteString
	call	Crlf

	mov		edx, offset programRules
	call	WriteString
	call	Crlf

	; Test Program - Getting User Data
	pushad
	mov		ebx, 0
	mov		edi, offset validInputs
_programLoop:
	cmp		ebx, 10
	je		_end
	push	offset validatedInput		; Building stack frame to get 10 user inputs
	push	offset invalidBool
	push	offset signBool
	push	offset numbOfBytes
	push	offset inputBuffer
	push	offset enterInteger
	push	offset errorMsg
	push	offset tryAgain
	call	ReadVal
	cmp		invalidBool, 1
	je		_notValid
	jmp		_resume
_notValid:
	mov		edx, offset errorMsg
	call	WriteString
	jmp		_programLoop
_resume:
	mov		SDWORD ptr esi, offset validatedInput
	mov		edx, [esi]
	mov		[edi], edx
	add		edi, 4						; Register intirect updating the next pointer to the next array element
	inc		ebx
	jmp		_programLoop
_end:
	; End of getting user data - Next is to Display these values using WriteVal
	push	offset signBool
	push	offset asciiOutBuffer
	push	offset validInputs
	call	WriteVal

	push	offset theSumOfNums
	push	offset validInputs
	call	calcSum

	Invoke ExitProcess,0				; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: 
;
;
; Preconditions:
;
; Postconditions:
;
; Receives:
;
; Returns:
; ---------------------------------------------------------------------------------
ReadVal PROC
	push	ebp
	mov		ebp, esp
	; Call the mGetString MACRO which will grab the user input
	mGetString
	
	; Restting BoolFlags
	pushad
	mov		edi, [ebp + 32]				; Invalid Bool offset
	mov		edx, 0
	mov		[edi], edx
	mov		edi, [ebp + 28]
	mov		[edi], edx		
	popad

	; Convert the string representation to the numerical representation
	pushad
	cld
	mov		esi, [ebp+20]				; inputBuffer offset
	mov		edi, [ebp+24]	
	mov		ecx, [edi]					; loads the number of bytes into ecx
	mov		eax, ecx
	mov		edx, 0
_beginConversion:
	lodsb
_validate:
	cmp		al, 48
	jl		_checkSigns					; if the value is below 48 there is a chance that it is a sign entered by user (+/-)
	cmp		al, 57		
	jg		_invalid					; if user input is valid, program implements an algorithm similar to that in module 8
	push	eax
	push	ecx
	sub		eax, 48
	push	eax
	mov		eax, 10
	mov		ecx, edx
	mul		ecx
	mov		ecx, eax
	pop		eax
	add		eax, ecx
	mov		edx, eax
	pop		ecx
	pop		eax
	loop	_beginConversion
	jmp		_endConversion
_checkSigns:
	cmp		al, 45
	je		_setSign
	cmp		al, 43
	jne		_invalid
	loop	_beginConversion
_setSign:
	push	edi
	push	eax
	mov		edi, [ebp+28]
	mov		eax, 1
	mov		[edi], eax
	pop		eax
	pop		edi
	loop	_beginConversion
_invalid:
	push	edi
	push	eax
	mov		edi, [ebp + 32]					; Set the invalidBool to 1
	mov		eax, 1
	mov		[edi], eax
	pop		eax
	pop		edi
	jmp		_end
_endConversion:
	jmp		_sizeCheck
_contEndConv:
	push	ebx
	push	eax
	mov		esi, [ebp + 28]					; Check if the signBool is 1, if so negate the value
	mov		eax, [esi]
	mov		ebx, 1
	cmp		ebx, eax
	pop		eax
	pop		ebx
	je		_negate
	jmp		_storeToMem
_negate:
	neg		edx
	jmp		_storeToMem
_sizeCheck:
	mov		eax, MAX_SIZE_REG
	cmp		edx, eax
	ja		_invalid
	jmp		_contEndConv
_storeToMem:
	push	edi
	mov		SDWORD ptr edi, [ebp + 36]		; validatedInput offset - repeatedly overwrites previous value
	mov		[edi], edx
	pop		edi
	jmp		_end
_end:
	popad
	pop		ebp
	ret	32
ReadVal	ENDP

calcSum PROC
	push	ebp
	mov		ebp, esp
	call	Crlf
	mDisplayString
	pushad
	mov		edi, [ebp + 8]
	mov		ecx, 0
	mov		edx, 0
_sum:
	mov		eax, [edi]
	mov		ebx, [edi + TYPE validInputs]
	add		eax, ebx
	add		edx, eax
	add		ecx, 2
	cmp		ecx, 10
	je		_endOfSum
	add		edi, 2*TYPE validInputs
	jmp		_sum
_endOfSum:
	mov		eax, edx
	call	WriteInt

	popad
	pop		ebp
	ret		8
calcSum	ENDP	


WriteVal PROC
	push	ebp
	mov		ebp, esp
	push	edi
	mov		edi, [ebp + 12]
	mov		ebx, 10
	mov		ecx, 0
_divStart:
	mov		esi, [ebp + 8]
	mov		eax, [esi]
	cmp		eax, 0
	jl		_invert
_resumeWithDiv:
	cld
_divRemaining:
	inc		ecx
	mov		edx, 0
	idiv	ebx
	push	edx
	cmp		edx, 1
	je		_doneDiv
	jmp		_divRemaining
_invert:
	push	eax
	push	esi
	mov		esi, [ebp + 16]
	mov		eax, 1
	mov		[esi], eax
	pop		esi
	pop		eax
	neg		eax
	jmp		_resumeWithDiv
_doneDiv:
	push	edi
	push	ebx
	mov		edi, [ebp + 16]
	mov		ebx, [edi]
	cmp		ebx, 1
	pop		ebx
	pop		edi
	je		_addSign
_addSign:
	mov		eax, 45
	stosb
_resumeBufferAdding:
	pop		eax
	stosb
	loop	_resumeBufferAdding

	mDisplayString
	pop		edi
	pop		ebp
	ret		12
writeVal ENDP

END main
