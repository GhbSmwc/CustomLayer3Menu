incsrc "../CustomLayer3Menu_Defines/Defines.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This code will randomize the passcode.
;
;Very useful to prevent players who have the knowledge of the passcode from sharing with others by
;requiring them to find the generated passcode. Recommended to have it either reset every time a
;new game is started or when the player enters the level from the map to avoid confusion on why
;the second time they enter no longer works. OR inform the player that the passcode changes.
;
;Note: I HIGHLY recommend using "Better Random Number Generator": https://www.smwcentral.net/?p=section&a=details&id=17534
;because SMW resets the seed every time you exit a level.
;
;Input:
; -!Freeram_CustomL3Menu_NumberOfCursorPositions (1 byte): The number of digits to randomize, -1.
;
;Output:
; -!Freeram_CustomL3Menu_DigitCorrectPasscode (N bytes): The randomized correct passcode. N bytes
;  is the number of bytes equal to !Freeram_CustomL3Menu_NumberOfCursorPositions minus 1.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RandomizePasscodeString:
	LDA !Freeram_CustomL3Menu_NumberOfCursorPositions
	TAX
	.Loop
		LDA #$09					;>Maximum (only numbers 0-9 are valid)
		PHX
		JSR RNG
		PLX
		STA !Freeram_CustomL3Menu_DigitCorrectPasscode,x	;>Write a random digit
		..Next
			DEX
			BPL .Loop
	RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Akaginite's (ID:8691) better ranged RNG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;*Input:
; *A (8-bit) = the maximum number
;*Output
; *A (8-bit) = result (0 to max, inclusive).
;
;Formula:
; int(rand*(max+1)/256)
;
;Do note that if using SA-1, the multiplication registers
;are signed, be careful not to use values more than #$7FFF
;(32767 in decimal).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RNG:	INC A			;>Because the number is truncated, without it, would be 1-less than intended max.
	BEQ .All		;>If decided to use all possible values, simply no calculations for range needed.
	if !sa1 == 0
		STA $4202	;>Max number times RNG(0,255)
	else
		STA $2251
		STZ $2252	;>Remove high byte
	endif
	JSL $01ACF9		;\get random number 0-255
	if !sa1 == 0
		STA $4203	;/
		XBA		;\Wait 8 cycles
		XBA		;|
		NOP		;/
	else
		STA $2253
		STZ $2254		;>This tells SA-1 to perform the calculation here.
		NOP			;\Wait till calculations is done
		BRA $00			;/
		endif
	if !sa1 == 0
		LDA $4217		;>Value 0 to max. (loading high byte as 8-bit = LSR 8 times; divide by 256).
	else
		LDA $2307
	endif
	RTS

.All	JML $01ACF9
	RTS