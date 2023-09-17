incsrc "../CustomLayer3Menu_Defines/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This is the same as ReadPasscodeQuantity but handles up to 9 digits using a 32-bit number.
;9 instead of 10 because 32-bit unsigned integer max is 4,294,967,295 and the user can enter
;9,999,999,999 which is greater than the max number. This is the inverse of my
;"Convert32bitIntegerToDecDigits" found in my status bar tutorial.
;
;This one actually uses multiplication routine due to its large size.
;Good for "compressed passcode" if you plan on having multiple randomized correct passcodes in
;your game and you do not want the correct passcodes to take up an exorbitant amount of space.
;
;Note: a 32-bit range RNG subroutine is required. At the time of writing this, nobody has made
;that. However, you can just simply generate the BCD format, then use this subroutine to compress
;the two words, then store it in SRAM.
;
;Input:
;-!Freeram_CustomL3Menu_NumberOfCursorPositions (1 byte): Needed to find the last digit
; and all the digits before it to correctly calculate.
;-!Freeram_CustomL3Menu_DigitPasscodeUserInput (up to 4 bytes): The sequence
; of digits to process to convert.
;
;Output:
;-!Scratchram_32bitDecToHexOutput (4 bytes): A 32-bit number that was converted from a
; sequence of digits.
;
;Destroyed:
;-$00-$0F (16 bytes, entire scratch RAM data): Used during the math routine to multiply.
;-$8A (1 byte): Used for indexing what powers of 10 to use.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PHB							;>Preserve bank
	PHK							;\Make bank current so that $xxxx,y uses the correct address
	PLB							;/
	LDA $0F							;\$0F Is reserved for sprite interaction with blocks
	PHA							;/
	PHX							;\Restore potential sprite index and block high byte behavior
	PHY							;/
	LDA !Freeram_CustomL3Menu_NumberOfCursorPositions	;\Rightmost digit
	TAX							;/
	LDA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;>X is on the 1s place.
	STA !Scratchram_32bitDecToHexOutput			;\!Scratchram_32bitDecToHexOutput starts off containing a value of 0-9 in the 1s place
	LDA #$00						;|
	STA !Scratchram_32bitDecToHexOutput+1			;|
	STA !Scratchram_32bitDecToHexOutput+2			;|
	STA !Scratchram_32bitDecToHexOutput+3			;/
	DEX							;>X is on the tens place.
	STZ $01							;\Digit * (10^n), since Digit cannot be greater than 9, bytes 1-3 (byte 0 is the lowest byte and 3 being highest)
	STZ $02							;|will always be zeroes.
	STZ $03							;/
	STZ $8A							;>initialize the powers of 10 index at 0.
	?Loop
		LDA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;\$00-$03: Multiplicand = the 0-9 digit
		STA $00							;/
		LDY $8A
		REP #$20						;\$04-$07: Multiplier = the powers of 10
		LDA ?PowersOfTenScalingLowWord,y			;|
		STA $04							;|
		LDA ?PowersOfTenScalingHighWord,y			;|
		STA $06							;/
		SEP #$20
		JSR ?MathMul32_32					;>$08-$0F (8 bytes, 64 bits): product
		REP #$20
		LDA $08							;\Add by previously calculated value.
		CLC							;|The unsigned overflow carry also works in 16-bit mode,
		ADC !Scratchram_32bitDecToHexOutput			;|therefore on the low word, if $FFFF is exceeded, the carry is set
		STA !Scratchram_32bitDecToHexOutput			;|so the high word will do A+1+B.
		LDA $0A							;|
		ADC !Scratchram_32bitDecToHexOutput+2			;|
		STA !Scratchram_32bitDecToHexOutput+2			;/
		SEP #$20
		?.Next
			INC $8A
			INC $8A
			DEX
			BPL ?Loop
	PLY							;\Restore potential sprite index and block high byte behavior
	PLX							;/
	PLA							;\Restore sprite interaction value.
	STA $0F							;/
	PLB							;>Restore bank
	RTL
	?PowersOfTenScalingLowWord
	dw $000A		;>10^1 (000000010 = $0000000A) $8A = $00
	dw $0064		;>10^2 (000000100 = $00000064) $8A = $02
	dw $03E8		;>10^3 (000001000 = $000003E8) $8A = $04
	dw $2710		;>10^4 (000010000 = $00002710) $8A = $06
	dw $86A0		;>10^5 (000100000 = $000186A0) $8A = $08
	dw $4240		;>10^6 (001000000 = $000F4240) $8A = $0A
	dw $9680		;>10^7 (010000000 = $00989680) $8A = $0C
	dw $E100		;>10^8 (100000000 = $05F5E100) $8A = $0E
	?PowersOfTenScalingHighWord
	dw $0000		;>10^1 (000000010 = $0000000A) $8A = $00
	dw $0000		;>10^2 (000000100 = $00000064) $8A = $02
	dw $0000		;>10^3 (000001000 = $000003E8) $8A = $04
	dw $0000		;>10^4 (000010000 = $00002710) $8A = $06
	dw $0001		;>10^5 (000100000 = $000186A0) $8A = $08
	dw $000F		;>10^6 (001000000 = $000F4240) $8A = $0A
	dw $0098		;>10^7 (010000000 = $00989680) $8A = $0C
	dw $05F5		;>10^8 (100000000 = $05F5E100) $8A = $0E
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Unsigned 32bit * 32bit Multiplication
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Argument
	; $00-$03 : Multiplicand
	; $04-$07 : Multiplier
	; Return values
	; $08-$0F : Product
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;GHB's note to self:
	;$4202 = 1st Multiplicand
	;$4203 = 2nd Multiplicand
	;$4216 = Product
	;During SA-1:
	;$2251 = 1st Multiplicand
	;$2253 = 2nd Multiplicand
	;$2306 = Product

	if !sa1 != 0
		!Reg4202 = $2251
		!Reg4203 = $2253
		!Reg4216 = $2306
	else
		!Reg4202 = $4202
		!Reg4203 = $4203
		!Reg4216 = $4216
	endif

	?MathMul32_32
			if !sa1 != 0
				STZ $2250
				STZ $2252
			endif
			REP #$21
			LDY $00
			BNE ?+
			STZ $08
			STZ $0A
			STY $0C
			BRA ?++
	?+		STY !Reg4202
			LDY $04
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			STZ $0A
			STZ $0C
			LDY $05
			LDA !Reg4216		;>This is always spitting out as 0.
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $08
			LDA $09
			ADC !Reg4216
			LDY $06
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $09
			LDA $0A
			ADC !Reg4216
			LDY $07
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0A
			LDA $0B
			ADC !Reg4216
			STA $0B
			
	?++		LDY $01
			BNE ?+
			STY $0D
			BRA ?++
	?+		STY !Reg4202
			LDY $04
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			LDY #$00
			STY $0D
			LDA $09
			ADC !Reg4216
			LDY $05
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $09
			LDA $0A
			ADC !Reg4216
			LDY $06
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0A
			LDA $0B
			ADC !Reg4216
			LDY $07
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0B
			LDA $0C
			ADC !Reg4216
			STA $0C
			
	?++		LDY $02
			BNE ?+
			STY $0E
			BRA ?++
	?+		STY !Reg4202
			LDY $04
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			LDY #$00
			STY $0E
			LDA $0A
			ADC !Reg4216
			LDY $05
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0A
			LDA $0B
			ADC !Reg4216
			LDY $06
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0B
			LDA $0C
			ADC !Reg4216
			LDY $07
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0C
			LDA $0D
			ADC !Reg4216
			STA $0D
			
	?++		LDY $03
			BNE ?+
			STY $0F
			BRA ?++
	?+		STY !Reg4202
			LDY $04
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			LDY #$00
			STY $0F
			LDA $0B
			ADC !Reg4216
			LDY $05
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0B
			LDA $0C
			ADC !Reg4216
			LDY $06
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0C
			LDA $0D
			ADC !Reg4216
			LDY $07
			STY !Reg4203
			if !sa1 != 0
				STZ $2254	;>Multiplication actually happens when $2254 is written.
				NOP		;\Wait till multiplication is done
				BRA $00		;/
			endif
			
			STA $0D
			LDA $0E
			ADC !Reg4216
			STA $0E
	?++		SEP #$20
			RTS