TITLE Designing low-level I/O procedures      (Proj6_934329706.asm)

; Author: Jacob Ogle
; Last Modified: June 3rd, 2021
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
	mov		ecx, 13							; Size of the input buffer
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
	pop		edx
	call	WriteString
	mov		al, ' '
	call	WriteChar
ENDM

; Constants
MAX_SIZE_REG = 2147483647
MAX_NEG_SIZE_REG = 2147483648

.data
; Prompts
programInfo		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures ",
						"Written by: Jacob Ogle",13,10,0	
programRules	BYTE	"Please provide 10 signed decimal integers. Each number needs ",
						"to be small enough to fit inside a 32 bit register. After you ",
						"have finished inputting the raw numbers I will display a list ",
						"of the integers, their sum, and their average value.",13,10,0
enterInteger	BYTE	"Please enter an signed number: ",0
errorMsg		BYTE	"ERROR: You did not enter a signed number or your number was too big. - try again",13,10,0
tryAgain		BYTE	"Please try again: ",0
enteredFollo	BYTE	"You entered the following numbers: ",13,10,0
theSumOfNums	BYTE	"The sum of these numbers is: ",0
theRoundAvg		BYTE	"The rounded average is: ",0
thanks			BYTE	"Thanks for reading and grading this nauseating 'program'. I suck at assembly, but loved the course. ",0

; Arrays
validInputs		SDWORD	10 DUP(?)
inputBuffer		BYTE	13 DUP(0)
numbOfBytes		BYTE	?
asciiOutBuffer	BYTE	12 DUP(?)

; Values
validatedInput	SDWORD	?				; Stores the validated input from ReadVal
arraySize		BYTE	?				; Stores the number of elements a user inputs
sumResult		SDWORD	?
avgResult		SDWORD	0

; Boolean Flags
signBool		BYTE	0
invalidBool		BYTE	0

.code
main PROC
	push	offset programInfo
	mDisplayString
	call	Crlf
	push	offset programRules
	mDisplayString
	CALL	Crlf
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
	push	offset errorMsg
	mDisplayString
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
	mov		ecx, 10
	mov		ebx, 0
_loop:
	push	offset arraySize
	push	offset signBool
	push	offset asciiOutBuffer
	push	offset validInputs
	call	WriteVal
	inc		ebx
	loop	_loop

	call	Crlf
	push	offset arraySize
	push	offset signBool
	push	offset asciiOutBuffer
	push	offset sumResult
	push	offset theSumOfNums
	push	offset validInputs
	call	calcSum

	call	Crlf
	push	offset arraySize
	push	offset signBool
	push	offset asciiOutBuffer
	push	offset avgResult
	push	offset sumResult
	push	offset theRoundAvg
	call	calcAvg

	call	Crlf
	push	offset thanks
	mDisplayString
	call	Crlf
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
	jo		_overflow
	mov		ecx, eax
	pop		eax
	add		eax, ecx
	mov		edx, eax
	pop		ecx
	pop		eax
	jmp		_normal
_overflow:
	pop		eax
	pop		ecx
	pop		eax
	jmp		_invalid
_normal:
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
	push	esi
	push	eax
	push	ebx
	mov		esi, [ebp + 28]					; Check if the signBool is 1, if so negate the value
	mov		eax, [esi]
	mov		ebx, 1
	cmp		ebx, eax
	pop		ebx
	pop		eax
	pop		esi
	je		_negativeSize
	mov		eax, MAX_SIZE_REG
	cmp		edx, eax
	ja		_invalid
	jmp		_contEndConv
_negativeSize:
	mov		eax, MAX_NEG_SIZE_REG
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
	push	[ebp + 12]
	mDisplayString
	pushad
	mov		edi, [ebp + 8]
	mov		ecx, 0
	mov		edx, 0
_sum:
	mov		eax, [edi]
	mov		ebx, [edi + 4]
	add		eax, ebx
	add		edx, eax
	add		ecx, 2
	cmp		ecx, 10
	je		_endOfSum
	add		edi, 2*4
	jmp		_sum
_endOfSum:
	mov		edi, [ebp + 16]
	mov		[edi], edx
	mov		edx, [ebp + 16]
	mov		eax, [edx]
	push	eax
	push	edx
	mov		ebx, 0						; Sorry I really suck at assembly - setting up the stack for WriteVal since it isn't very portable
	push	[ebp + 28]
	push	[ebp + 24]
	push	[ebp + 20]	
	push	[ebp + 16]
	call	WriteVal
	pop		edx
	pop		eax
	mov		[edx], eax
	; Setup the WriteVal function
	popad
	pop		ebp
	ret		24
calcSum	ENDP	

calcAvg PROC
	push	ebp
	mov		ebp, esp
	pushad
	call	Crlf
	push	[ebp + 8]
	mDisplayString
	mov		edi, [ebp + 16]
	mov		esi, [ebp + 12]
	mov		eax, [esi]
	cdq
	mov		ebx, 10
	idiv	ebx
	;	put final avg in eax
	mov		[edi], eax
	mov		ebx, 0		
	push	[ebp + 28]
	push	[ebp + 24]
	push	[ebp + 20]	
	push	[ebp + 16]
	call	WriteVal
	popad
	pop		ebp
	ret		24
calcAvg ENDP

convertToASCII PROC
	push	ebp
	mov		ebp, esp
	pushad
	mov		esi, [ebp + 8]
	mov		edi, esi
	mov		eax, [ebp + 12]
	mov		ecx, [eax]
_comparisons:
	cmp		ecx, 0
	je		_endOfComparisons
	mov		al, [esi]
	cmp		al, 45
	je		_negative
	jmp		_numbers
_negative:
	add		edi, 1
	add		esi, 1
	jmp		_comparisons
_numbers:
	cmp		al, 1
	je		_one
	cmp		al, 2
	je		_two
	cmp		al, 3
	je		_three
	cmp		al, 4
	je		_four
	cmp		al, 5
	je		_five
	cmp		al, 6
	je		_six
	cmp		al, 7
	je		_seven
	cmp		al, 8
	je		_eight
	cmp		al, 9
	je		_nine
	cmp		al, 0
	je		_zero
_one:
	mov		bl, 49
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_two:
	mov		bl, 50
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_three:
	mov		bl, 51
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_four:
	mov		bl, 52
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_five:
	mov		bl, 53
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_six:
	mov		bl, 54
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_seven:
	mov		bl, 55
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_eight:
	mov		bl, 56
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_nine:
	mov		bl, 57
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_zero:
	mov		bl, 48
	mov		[edi], bl
	add		edi, 1
	add		esi, 1
	dec		ecx
	jmp		_comparisons
_endOfComparisons:
	popad
	pop		ebp
	ret		8
convertToASCII ENDP

clearBuffer PROC
	push	ebp
	mov		ebp, esp
	pushad
	mov		esi, [ebp + 8]
	mov		ecx, 12
_clearLoop:
	mov		eax, 0
	mov		[esi], eax						; Repeatedly adds zero the the array position pointed to by esi
	inc		esi
	loop	_clearLoop
	mov		edi, [ebp + 12]
	mov		eax, 0
	mov		[edi], eax
	popad
	pop		ebp
	ret		8
clearBuffer ENDP

WriteVal PROC
	push	ebp
	mov		ebp, esp
	mov		edi, [ebp + 12]
	mov		esi, [ebp + 8]
	push	eax
	push	edx
	push	ebx
	mov		eax, 4							; As we iterate in the main procedure, we will track which iteration we are on via ebx and then add 4x[ebx] to the esi pointer so that we are capturing each element of thea array
	mul		ebx
	add		esi, eax
	pop		ebx
	pop		edx
	pop		eax
	pushad
	mov		ebx, 10
	mov		ecx, 0
_divStart:
	mov		eax, [esi]
	cmp		eax, 0
	jl		_invert
_resumeWithDiv:
	cld
_divRemaining:
	inc		ecx
	mov		edx, 0
	div		ebx
	push	edx
	cmp		eax, 0
	je		_doneDiv
	jmp		_divRemaining
_invert:									; If a negative value is added, updates the sign boolean global and then negates the value
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
	cmp		ebx, 1							; Checking for sign boolean flag that, if set, will jump to _addSign and push the negative sign value that will be added to the string
	pop		ebx
	pop		edi
	je		_addSign
_storeSize:									; Stores the size of the user input array which will be used in the conversion of ascii values
	pushad
	mov		edi, [ebp + 20]
	mov		eax, 0
	mov		[edi], eax
	mov		[edi], ecx
	popad
	jmp		_resumeBufferAdding
_addSign:
	mov		eax, 45
	stosb
	jmp		_storeSize
_resumeBufferAdding:
	pop		eax
	stosb
	loop	_resumeBufferAdding
	push	[ebp + 20]
	push	[ebp + 12]
	call	convertToASCII					; Calling a subprocedure to convert the values to their ASCII representation
	push	[ebp + 12]
	mDisplayString
	push	[ebp + 16]						; Clearing the signBool flag also
	push	[ebp + 12]
	call	clearBuffer						; Calling a subprocedure to clear the asciiOutBuffer so that values do not remain for the next iteration
	popad
	pop		ebp
	ret		16
writeVal ENDP

END main
