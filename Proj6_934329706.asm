TITLE Designing low-level I/O procedures      (Proj6_934329706.asm)

; Author: Jacob Ogle
; Last Modified: June 5th, 2021
; OSU email address: ogleja@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: June 6th 2021
; Description: A low level I/O program that reads a numerical string from a user, and processes the string from it's string form to an actual numerical represnetation. 
;	The program will then compute the sum and average of 10 of these values and then output the numbers the user entered, the sum, and the average (floor) as thier
;	string form representation. Reading strings and writing strings are handled by user-created (myself) macros and procedures. 
;	

INCLUDE Irvine32.inc
; Macros

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Reads a user input (string) to a buffer - for this program the assumed maximum size
;	is a string of length 13
;
; Preconditions: 
;	This macro assumes it is being called within a procedure hence the larger values 
;		for base-offset references.
;	Needs the input buffer pushed, followed by the the prompt, followed by the
;		number of bytes such that they align with the values of base + offset in the
;		recieves section of this header.
;
; Receives:
;	[ebp+16] = prompt to be displayed to user
;	[ebp+ 20] = address of the buffer (memory location the string will be written to)
;	[ebp + 24] = offset of sizeOfBuffer
;
; Returns:
;	Updates the sizeOfBuffer variable, the inputBuffer, and also displays the prompt
;		to the user as the output. No other data changes intended.
; ---------------------------------------------------------------------------------
mGetString MACRO

	; Save used registers
	push	edx
	push	ecx
	push	eax
	push	edi

	; Display Prompt for string entry
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
; Name: mDisplayString
;
;	Displays a string with a space separator followed by the string after it has been 
;	 written to the console.
;
; Preconditions: 
;	The offset of the string to be written needs to be pushed to the stack immediately 
;	before calling the macro.
;
; Receives:
;	Pops the value from the top of the stack into edx: This value should be the offset
;		of the string to be written (see Preconditions).
;
; Returns:
;	No data is intended to be altered. The stack will have popped off the topmost value
;		however, this should not alter the stack alignment.
; ---------------------------------------------------------------------------------
mDisplayString MACRO

	; Pops offset of string to be written and calls WriteString
	pop		edx
	call	WriteString

	; Writes a following space character
	mov		al, ' '
	call	WriteChar

ENDM

; Constants
MAX_SIZE_REG = 2147483647				; A constant representing the upper positivle limit that can fit in a 32 bit register
MAX_NEG_SIZE_REG = 2147483648			; A constant representing the lower negative limit that can fit in a 32 bit register

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
validInputs		SDWORD	10 DUP(?)		; Stores the valid inputs from the user in their numerical form
inputBuffer		BYTE	13 DUP(0)		; String input bugger
numbOfBytes		BYTE	?				; Stores the number of Bytes read in mReadString
asciiOutBuffer	BYTE	12 DUP(?)		; Output buffer of string values in their ASCII representation

; Values
validatedInput	SDWORD	?				; Stores the validated input from ReadVal
arraySize		BYTE	?				; Stores the number of elements a user inputs
sumResult		SDWORD	?
avgResult		SDWORD	0

; Boolean Flags
signBool		BYTE	0				; Flag demarking the sign of the value 0 = positive & 1 = negative
invalidBool		BYTE	0				; Flag demarking if a value is valid or not

.code
main PROC
; --------------------------
;	Main test program. This program will prompt user to enter 10 signed values.
;		These values will be processed by macros (above) and procedures (below)
;		to match the functionality of the program description in the header.
; --------------------------

	; Program Prompts
	push	offset programInfo
	mDisplayString
	call	Crlf
	push	offset programRules
	mDisplayString
	CALL	Crlf

	; Getting User Data
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
	cmp		invalidBool, 1				; ReadVal will validate a user input - this checks if the invalidBool flag has been set indicating an invalid input
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
	add		edi, 4						; Register intirect updating the next pointer to the next array element so that we get 10 values
	inc		ebx
	jmp		_programLoop
_end:
	; End of getting user data

	; Display the User Data		- This will display the 10 validated values that the user has input
	call	Crlf
	push	offset enteredFollo
	mDisplayString
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

	; Display the Sum of the 10 vlaidated inputs
	call	Crlf
	push	offset arraySize
	push	offset signBool
	push	offset asciiOutBuffer
	push	offset sumResult
	push	offset theSumOfNums
	push	offset validInputs
	call	calcSum

	; Display the Avg of the 10 validated inputs (floor-average)
	call	Crlf
	push	offset arraySize
	push	offset signBool
	push	offset asciiOutBuffer
	push	offset avgResult
	push	offset sumResult
	push	offset theRoundAvg
	call	calcAvg

	; Thanking the user for using the program (& grader for dealing with this mess)
	call	Crlf
	call	Crlf
	push	offset thanks
	mDisplayString
	call	Crlf


	Invoke ExitProcess,0				; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;	
;	Reads a value from the user using the mGetString macro. Once the string has been
;		retrieved the procedure will validate the value and if valid, store it to a
;		memory location.
;
; Preconditions:
;	The stack needs to be built in a manner that aligns with the requirements
;		of mGetString (see macro header). 
;
; Postconditions:
;	No regisger alterations (all restored). Stack is cleaned at end of procedure. SignBool,
;	invalidBool will be alterd.
;
; Receives:
;	[ebp + 36] = validatedInput buffer - overwritten each call
;	[ebp + 32] = invalidBool offset
;	[ebp + 28] = signBool offset
;	[ebp + 24] = numberOfBytes offset
;	[ebp + 20] = inputBuffer offset
;		all other stack elements below these do not get called by ReadVal, but the stack
;			needs to align with this for base+offset addressing
;
; Returns:
;	The procedure will return updated values in validatedInput, invalidBool, signBool,
;		and numberOfBytes. No other data intended to be changed. Registers all restored.
; ---------------------------------------------------------------------------------
ReadVal PROC
	push	ebp
	mov		ebp, esp

	; Call the mGetString MACRO which will get the user input
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
	; Begin the validation step for each character in the string from user input
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
	je		_setSignNeg
	cmp		al, 43
	jmp		_noSignAfterFirst
	jne		_invalid
	loop	_beginConversion
_setSignNeg:							; Sets the negative signBool if the value is negatice
	push	eax
	mov		eax, [edi]
	cmp		eax, ecx
	pop		eax
	jne		_invalid
	push	edi
	push	eax
	mov		edi, [ebp+28]
	mov		eax, 1
	mov		[edi], eax
	pop		eax
	pop		edi
	loop	_beginConversion
_noSignAfterFirst:						; Checks if a sign (+ or - is enterd after the first value of the string)
	push	eax
	mov		eax, [edi]
	cmp		eax, ecx
	pop		eax
	jne		_invalid
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
	; Restore registers and clean stack
	popad
	pop		ebp
	ret		36
ReadVal	ENDP

; ---------------------------------------------------------------------------------
; Name: calcSum
;
;	The calcSum procedure iterates the validated user inputs in their SDWORD form
;		and calculates the sum of these values to be stored in a variable
;
; Preconditions: The array of valid inputs has been gathered from the user and has 
;		been stored in their SDWORD form
;
; Postconditions: None  - registers and stack cleaned/restored at end of procedure
;
; Receives:
;	[ebp + 28] = arraySize
;	[ebp + 24] = signBool
;	[ebp + 20] = asciiOutBuffer
;	[ebp + 16] = sumResult
;	[ebp + 12] = theSumOfNums
;	[ebp + 8] = validInputs
;
; Returns: 
;	Updates the sumResult & also inirectly alters arraySize, signBool and asciiOutBuffer
;		by calling WriteVal
; ---------------------------------------------------------------------------------
calcSum PROC
	push	ebp
	mov		ebp, esp
	call	Crlf

	; Displays the sum value prompt
	push	[ebp + 12]
	mDisplayString
	
	; Save redgisters
	pushad
	
	; Begin sum calculation
	mov		esi, [ebp + 8]				; loads the offset of the validInputs
	mov		ecx, 0
	mov		edx, 0
_sum:
	mov		eax, [esi]
	mov		ebx, [esi + 4]
	add		eax, ebx
	add		edx, eax
	add		ecx, 2
	cmp		ecx, 10
	je		_endOfSum
	add		esi, 2*4					; Incrementing ESI to the next array element x 2 since we need to compute the next two sum elements
	jmp		_sum
	
	; End of sum calculation is done - Stroe the result and display the value
_endOfSum:
	mov		edi, [ebp + 16]				; Loads offset of sumResult to EDI to store the result
	mov		[edi], edx
	mov		edx, [ebp + 16]
	mov		eax, [edx]
	
	; Writing the Sum value to the console by calling WriteVal
	push	eax
	push	edx
	mov		ebx, 0						; Sorry I really suck at assembly - setting up the stack for WriteVal since it isn't very portable - zero to ebx allows for the sum to be written to the first array element of the osciiOutArray
	push	[ebp + 28]
	push	[ebp + 24]
	push	[ebp + 20]	
	push	[ebp + 16]
	call	WriteVal
	pop		edx
	pop		eax
	mov		[edx], eax
	popad
	pop		ebp
	ret		28
calcSum	ENDP	

; ---------------------------------------------------------------------------------
; Name: calcAvg
;
;	The calcAvg procedure uses the sum value and divides it by 10 to compute the
;		average of the user input. It then writes this to the console.
;
; Preconditions: The sum must be calculated and stored in the sumResult varible in 
;	SDWORD form.
;	The procedure assumes that the arraysize is 10.
;
; Postconditions: None - all registers preserved & restored and the stack is cleaned
;
; Receives:
;	[ebp + 28] = arraySize
;	[ebp + 24] = signBool
;	[epb + 20] = asciiOutBuffer
;	[ebp + 16] = avgResult
;	[ebp + 12] = sumResult
;	[ebp + 8]  = theRoundAvg
;
; Returns:
;	Updates the avgResult & also inirectly alters arraySize, signBool and asciiOutBuffer
;		by calling WriteVal.
; ---------------------------------------------------------------------------------
calcAvg PROC
	push	ebp
	mov		ebp, esp

	; Preserving Registers
	pushad
	call	Crlf
	
	; Displays the prompt string for the average
	push	[ebp + 8]
	mDisplayString

	mov		edi, [ebp + 16]			; loads the offset of avgResult into the edi
	mov		esi, [ebp + 12]			; loads the offset of sumResult into the esi
	
	; Computation of the average
	mov		eax, [esi]
	cdq
	mov		ebx, 10
	idiv	ebx
	
	; Load final avgerage valie into in eax
	mov		[edi], eax

	; Building the ugly stack frame for WriteVal - Displays the floor-average value to the console
	mov		ebx, 0		
	push	[ebp + 28]
	push	[ebp + 24]
	push	[ebp + 20]	
	push	[ebp + 16]
	call	WriteVal
	
	; Restore registers and clean the stack frame
	popad
	pop		ebp
	ret		24
calcAvg ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
;	WriteVal takes some SDWORD value and converts it to it's string format to be
;		displayed to the console. It does so by a conversion algorith in which
;		the SDWORD is divided by 10 and the remainder is pushed to the stack 
;		and once the division yields a quotient of 0 the conversion is done.
;		The values will be then one-by-one converted to their ASCII to representation
;		by calling sub-procedure convertToASCII. These values will be then stored
;		in an output buffer, asciiOutBuffer.
;
; Preconditions: A sdword must be stored in the memory location in which the procedure
;		will access (see Recieves). The asciiOutBuffer is cleared. ArraySize must be known
;		and the signBool must be set
;
; Postconditions: None - registers preserved and stack cleaned.
;
; Receives:
;	[ebp + 20] = arraySize
;	[ebp + 16] = signBool
;	[ebp + 12] = asciiOutBuffer
;	[ebp + 8]  = validInputs
;
; Returns: 
;	Updates the arraySize
; ---------------------------------------------------------------------------------
WriteVal PROC
	push	ebp
	mov		ebp, esp
	mov		edi, [ebp + 12]					; Offset of asciiOutBuffer
	mov		esi, [ebp + 8]					; Offset of validInputs
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
	; Beginning the division portion of the algorithm to convert the SDWORD to invidual values
_divStart:
	mov		eax, [esi]
	cmp		eax, 0							; If the value is negative it will be inverted for easier converstion
	jl		_invert
_resumeWithDiv:
	cld			
_divRemaining:								; _divRemaining handles cases after initial division - does so by making the quotient of the last division to be the new dividend
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
	mov		esi, [ebp + 16]					; Offset of signBool
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
_addSign:									; Adds the sign if one is needed ie. negative
	mov		eax, 45
	stosb
	jmp		_storeSize
_resumeBufferAdding:
	pop		eax
	stosb
	loop	_resumeBufferAdding

	; Now that the division is done - proceed with conversion of values to ascii
	push	[ebp + 20]						; Pushes the arraySize offset
	push	[ebp + 12]						; Pushes the asciiOutBuffer offset
	call	convertToASCII					; Calling a subprocedure to convert the values to their ASCII representation
	
	; Once conversions done to ascii - push the offset of the asciiOutBuffer to mDisplayString so that the string represenation is written
	push	[ebp + 12]
	mDisplayString
	
	; Clearing teh buffers & signBool
	push	[ebp + 16]						; Clearing the signBool flag also
	push	[ebp + 12]						; Offset asciiOutBuffer 
	call	clearBuffer						; Calling a subprocedure to clear the asciiOutBuffer so that values do not remain for the next iteration
	
	; Restore registers & clear the stack frame
	popad
	pop		ebp
	ret		16
writeVal ENDP

; ---------------------------------------------------------------------------------
; Name: convertToASCII
;
;	The convertToASCII procedure does what the name implies. It is an implmenetation
;		of an algorithm to convert a DWORD to individual ASCII characters. This proc
;		is intended to be called within the WriteVal procedure as a part of the
;		the process of writing a SDWORD to an integer.
;		
;
; Preconditions: 
;		All of the numerical elements have been pushed to the stack in the order that
;			they will be displayed to the console or converted to their string form.
;			This is handled by the WriteVal procedure. arraySize must also be known
;			since this procedure loops the number of time that the arraySize is.
;
; Postconditions: None - registers restored and stack cleaned 
;
; Receives:
;	[ebp + 12] = offset arraySize
;	[ebp + 8]  = offset asciiOutBuffer
;
; Returns: 
;	Fills the asciiOutBuffer with the ascii values of the numberical values.
; ---------------------------------------------------------------------------------
convertToASCII PROC
	push	ebp
	mov		ebp, esp
	pushad
	mov		esi, [ebp + 8]				; Loading the esi with the offset of asciiOutBuffer
	mov		edi, esi
	mov		eax, [ebp + 12]				; Loading eax with the offset of arraySize
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

; ---------------------------------------------------------------------------------
; Name: clearBuffer
;
;	ClearBuffer takes a buffer and nullifies it's values and additionally clears the
;		signBool value to zero. This procedure is called as a part of WriteVal
;
; Preconditions: None
;
; Postconditions: None - registers restored and stack cleared
;
; Receives:
;	[ebp + 12] = offset signBool
;	[ebp + 8]  = offset asciiOutBuffer
; Returns: 
; ---------------------------------------------------------------------------------
clearBuffer PROC
	push	ebp
	mov		ebp, esp
	; Preserving Registers
	pushad
	; Setting up clearing loop
	mov		esi, [ebp + 8]					
	mov		ecx, 12							; assumes the buffer size is 12 for this program
_clearLoop:
	mov		eax, 0
	mov		[esi], eax						; Repeatedly adds zero the the array position pointed to by esi
	inc		esi
	loop	_clearLoop
	; Clearing the signBool flag variable
	mov		edi, [ebp + 12]
	mov		eax, 0
	mov		[edi], eax
	; Restore registers & clear stack
	popad
	pop		ebp
	ret		8
clearBuffer ENDP
END main
