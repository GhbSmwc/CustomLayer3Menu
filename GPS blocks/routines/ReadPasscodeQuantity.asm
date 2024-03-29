incsrc "../CustomLayer3Menu_Defines/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine takes the sequence of digits (essentially BCD unpacked format) from
;!Freeram_CustomL3Menu_DigitPasscodeUserInput and converts it into a raw binary number
;(essentially the opposite of hex to dec routines which those converts a binary number into a
;sequence of decimal digits). This only supports up to 4 digits because 16-bit unsigned max
;number is 65,535 and the user can enter a 5-digit number 99,999 which is greater than 65,535.
;
;How it works: It calculates like this (D0, D1, D2, D3 represents a digit where numbers 0-3
;represents ones, tens, hundreds, and then thousands in that order):
; D0 + (D1 * 10) + (D2 * 100) + (D3 * 1000)
;
; Example: 1234 -> "1", "2", "3", "4" -> $04D2
;  4 + (3 * 10) + (2 * 100) + (1 * 1000)
;  = 4 + 30 + 200 + 1000
;  = 1234 = $04D2
;This is positional notation to get a value based on its position.
;
;This is very useful for making it easy to read the number the user has entered rather than
;digit by digit, having the correct passcode take up smaller space (9999 would take up 4 bytes
;[09 09 09 09] vs 2 bytes [0F 27 ($270F)]).
;
;Input:
;-!Freeram_CustomL3Menu_NumberOfCursorPositions (1 byte): Needed to find the last digit
; and all the digits before it to correctly calculate.
;-!Freeram_CustomL3Menu_DigitPasscodeUserInput (up to 4 bytes): The sequence
; of digits to process to convert.
;
;Output:
;-$00 (2 bytes): A 16-bit number that was converted from a sequence of digits.
;
;Destroyed:
;-$03 (1 byte): Used to determine what place value for indexing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PHX								;\Preserve XY just in case if used for sprite and block behaviors
	PHY								;/
	PHB								;>Preserve bank
	PHK								;\Set bank to current one
	PLB								;/
	LDA !Freeram_CustomL3Menu_NumberOfCursorPositions		;\Ones place done ($00 = values 0-9)
	TAX								;|
	LDA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x		;|
	STA $00								;|
	STZ $01								;/
	DEX								;>X now starts at the tens place
	STZ $03
	?Loop
		LDA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;>A = the digit value (only 0-9)
		ASL							;>16-bit is 2 bytes.
		CLC							;\This basically gets a digit to "multiply by 10^n"
		ADC $03							;|
		TAY							;/
		REP #$20
		LDA ?DigitTables,y
		CLC							;\Add (basically 1234 = 1000 + 200 + 30 + 4)
		ADC $00							;|
		STA $00							;/
		SEP #$20
		?.Next
			LDA $03		;\Next place value digit
			CLC		;|
			ADC.b #20	;|
			STA $03		;/
			DEX		;\Next digit of !Freeram_CustomL3Menu_DigitPasscodeUserInput
			BPL ?Loop	;/
	PLB								;>Restore bank
	PLY								;\Restore XY
	PLX								;/
	RTL
	?DigitTables
		;Tens
		dw 00				;>Y = 00 ($00)
		dw 10				;>Y = 02 ($02)
		dw 20				;>Y = 04 ($04)
		dw 30				;>Y = 06 ($06)
		dw 40				;>Y = 08 ($08)
		dw 50				;>Y = 10 ($0A)
		dw 60				;>Y = 12 ($0C)
		dw 70				;>Y = 14 ($0E)
		dw 80				;>Y = 16 ($10)
		dw 90				;>Y = 18 ($12)
		;Hundreds
		dw 000				;>Y = 20 ($14)
		dw 100				;>Y = 22 ($16)
		dw 200				;>Y = 24 ($18)
		dw 300				;>Y = 26 ($1A)
		dw 400				;>Y = 28 ($1C)
		dw 500				;>Y = 30 ($1E)
		dw 600				;>Y = 32 ($20)
		dw 700				;>Y = 34 ($22)
		dw 800				;>Y = 36 ($24)
		dw 900				;>Y = 38 ($26)
		;Thousands
		dw 0000				;>Y = 40 ($28)
		dw 1000				;>Y = 42 ($2A)
		dw 2000				;>Y = 44 ($2C)
		dw 3000				;>Y = 46 ($2E)
		dw 4000				;>Y = 48 ($30)
		dw 5000				;>Y = 50 ($32)
		dw 6000				;>Y = 52 ($34)
		dw 7000				;>Y = 54 ($36)
		dw 8000				;>Y = 56 ($38)
		dw 9000				;>Y = 58 ($3A)