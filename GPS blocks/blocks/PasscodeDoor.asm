;Act as $025
;This is a door that when UP is pressed will bring up the passcode UI. If the player cancels, the menu just closes with "cancel" sound effect.
;If the player enters the correct passcode, it plays the "correct" sound effect, closes the menu, and teleports the player to whatever screen exit set by LM.
;If the player enters the incorrect passcode, it plays the "incorrect" sound effect and closes the menu.

;If you have !BCD_or_Binary set to 0, The correct passcode is under the label "PasscodeCorrect". Each number should be a value 0-9 and it corresponds to what
;digit shown to the player in the same order (leftmost digit is the first number, second is second, and so on. Be careful not to have too many values more
;than !CustomL3Menu_MaxNumberOfDigitsInEntireGame as it could end up overwriting/overreading bytes beyond
;!Freeram_CustomL3Menu_DigitPasscodeUserInput+<Expected_max_number_of_bytes>-1 and
;!Freeram_CustomL3Menu_DigitCorrectPasscode+<Expected_max_number_of_bytes>-1 (so if you for example expect no more than 8 digits, and you have more than 8,
;data will be written and read past the last bytes of !Freeram_CustomL3Menu_DigitPasscodeUserInput and Freeram_CustomL3Menu_DigitCorrectPasscode and can
;cause issues).


!BCD_or_Binary = 1
 ;^0 = BCD: binary coded decimal (unpacked). The correct passcode is in each decimal digit form.
 ;     This has virtually no limits (well up to 32 digits because that's the width of the screen).
 ;^1 = binary: Stores the entire value as raw digits and also taking up less space (example:
 ; a passcode of "1234" would store $04D2 (2 bytes) instead of [01 02 03 04] (4 bytes)). However
 ; up to 9 digits are allowed.
 
 ;These apply if you have !BCD_or_Binary set to 1:
  !CorrectPasscodeBinary = 1234
  !NumberOfDigits = 4
  
  
;Don't touch
 !CorrectPasscodeSize = 0
 if !CorrectPasscodeBinary > 65535
  !CorrectPasscodeSize = 1
 endif
incsrc "../CustomLayer3Menu_Defines/Defines.asm"

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37


BodyInside:
	LDA !Freeram_CustomL3Menu_UIState			;\If menu already opened, do nothing
	BNE Return						;/
	LDA $16							;\Press up to enter
	AND #$08						;|
	BEQ Return						;/
	LDA $8F							;\Backup of $72. If Mario is not on ground, return
	BNE Return						;/
	%DoorCenterPlayer()
	LDA #$03						;\Activate the menu
	STA !Freeram_CustomL3Menu_UIState			;|
	LDA #$00						;|
	STA !Freeram_CustomL3Menu_WritePhase			;/
	STA !Freeram_CustomL3Menu_CursorPos			;>Default the cursor position
	
	if !BCD_or_Binary == 0
		LDA.b #(PasscodeCorrectEnd-PasscodeCorrect)-1		;\Number of digits or cursor positions
	else
		LDA.b #!NumberOfDigits-1
	endif
	STA !Freeram_CustomL3Menu_NumberOfCursorPositions	;/
	REP #$20						;\Setup code to use when the user enters or exit the passcode.
	LDA.w #SuppliedCode					;|
	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1	;|
	SEP #$20						;|
	LDA.b #SuppliedCode>>16					;|
	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3	;/
	
	if !BCD_or_Binary == 0
		LDX.b #(PasscodeCorrectEnd-PasscodeCorrect)-1		;\Default the original passcode to all zeroes and setup the correct passcode
	else
		LDX.b #!NumberOfDigits-1
	endif
	-							;|
	LDA #$00						;|
	STA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;|
	if !BCD_or_Binary == 0
		LDA PasscodeCorrect,x					;|
		STA !Freeram_CustomL3Menu_DigitCorrectPasscode,x	;|
	endif
	DEX							;|
	BPL -							;/
	RTL

MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
HeadInside:
;WallFeet:	; when using db $37
;WallBody:
SpriteV:
SpriteH:
MarioCape:
MarioFireball:
Return:
	RTL
SuppliedCode:
	LDA $00
	BNE .Done
	.PasscodeCheck
		;Check if passcode entered by player is correct
		if !BCD_or_Binary == 0
			LDX.b #(PasscodeCorrectEnd-PasscodeCorrect)-1
			..PasscodeCheckLoop
				LDA !Freeram_CustomL3Menu_DigitCorrectPasscode,x
				CMP !Freeram_CustomL3Menu_DigitPasscodeUserInput,x
				BNE ..Incorrect
				...Next
					DEX
					BPL ..PasscodeCheckLoop
			..Correct
				LDA #!CustomL3Menu_SoundEffectNumber_Correct
				STA !CustomL3Menu_SoundEffectPort_Correct
				LDA #$06				;\Teleport player.
				STA $71					;|
				STZ $89					;|
				STZ $88					;/
				BRA .Done
			..Incorrect
				LDA #!CustomL3Menu_SoundEffectNumber_Rejected
				STA !CustomL3Menu_SoundEffectPort_Rejected
		else
			if !CorrectPasscodeSize == 0
				LDA.b #!NumberOfDigits-1
				STA !Freeram_CustomL3Menu_NumberOfCursorPositions
				%ReadPasscodeQuantity()
				REP #$20
				LDA $00
				CMP.w #!CorrectPasscodeBinary
				SEP #$20
				BNE ..Incorrect
				
				..Correct
					LDA #!CustomL3Menu_SoundEffectNumber_Correct
					STA !CustomL3Menu_SoundEffectPort_Correct
					LDA #$06				;\Teleport player.
					STA $71					;|
					STZ $89					;|
					STZ $88					;/
					BRA .Done
				..Incorrect
					LDA #!CustomL3Menu_SoundEffectNumber_Rejected
					STA !CustomL3Menu_SoundEffectPort_Rejected
			else
				LDA.b #!NumberOfDigits-1
				STA !Freeram_CustomL3Menu_NumberOfCursorPositions
				%ReadPasscodeQuantity32Bit()
				REP #$20
				LDA !Scratchram_32bitDecToHexOutput
				CMP.w #!CorrectPasscodeBinary
				BNE ..Incorrect
				LDA !Scratchram_32bitDecToHexOutput+2
				CMP.w #!CorrectPasscodeBinary>>16
				BNE ..Incorrect
				..Correct
					SEP #$20
					LDA #!CustomL3Menu_SoundEffectNumber_Correct
					STA !CustomL3Menu_SoundEffectPort_Correct
					LDA #$06				;\Teleport player.
					STA $71					;|
					STZ $89					;|
					STZ $88					;/
					BRA .Done
				..Incorrect
					SEP #$20
					LDA #!CustomL3Menu_SoundEffectNumber_Rejected
					STA !CustomL3Menu_SoundEffectPort_Rejected
			endif
		endif
	.Done
		LDA #$03				;\Initiate closing the passcode mode and clear the stripe image tiles.
		STA !Freeram_CustomL3Menu_WritePhase	;/
		RTL

	if !BCD_or_Binary == 0
		PasscodeCorrect:
			db 1,2,3,4 ;>Must be in between the two labels to get the number of digits correct.
		PasscodeCorrectEnd:
	endif
print "Passcode door"
