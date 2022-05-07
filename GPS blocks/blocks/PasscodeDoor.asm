;Act as $025
;This is a door that when UP is pressed will bring up the passcode UI. If the player cancels, the menu just closes with "cancel" sound effect.
;If the player enters the correct passcode, it plays the "correct" sound effect, closes the menu, and teleports the player to whatever screen exit set by LM.
;If the player enters the incorrect passcode, it plays the "incorrect" sound effect and closes the menu.

;The correct passcode is under the label "PasscodeCorrect". Each number should be a value 0-9 and it corresponds to what digit shown to the player
;in the same order (leftmost digit is the first number, second is second, and so on. Be careful not to have too many values more than what you expect
;as it could end up overwriting/overreading bytes beyond !Freeram_CustomL3Menu_DigitPasscodeUserInput+<Expected_max_number_of_bytes>-1 and
;!Freeram_CustomL3Menu_DigitCorrectPasscode+<Expected_max_number_of_bytes>-1 (so if you for example expect no more than 8 digits, and you have more than 8,
;data will be written and read past !Freeram_CustomL3Menu_DigitPasscodeUserInput+7 and Freeram_CustomL3Menu_DigitCorrectPasscode+7 and can cause issues).

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
	LDA #$03						;\Activate the menu
	STA !Freeram_CustomL3Menu_UIState			;|
	LDA #$00						;|
	STA !Freeram_CustomL3Menu_WritePhase			;/
	STA !Freeram_CustomL3Menu_CursorPos			;>Default the cursor position
	LDA.b #(PasscodeCorrectEnd-PasscodeCorrect)-1		;\Number of digits or cursor positions
	STA !Freeram_CustomL3Menu_NumberOfCursorPositions	;/
	REP #$20						;\Setup code to use when the user enters or exit the passcode.
	LDA.w #SuppliedCode					;|
	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1	;|
	SEP #$20						;|
	LDA.b #SuppliedCode>>16					;|
	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3	;/
	
	
	LDX.b #(PasscodeCorrectEnd-PasscodeCorrect)-1		;\Default the original passcode to all zeroes and setup the correct passcode
	-							;|
	LDA #$00						;|
	STA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;|
	LDA PasscodeCorrect,x					;|
	STA !Freeram_CustomL3Menu_DigitCorrectPasscode,x	;|
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
	.Done
		LDA #$03				;\Initiate closing the passcode mode and clear the stripe image tiles.
		STA !Freeram_CustomL3Menu_WritePhase	;/
		RTL

	PasscodeCorrect:
		db $00,$01,$02,$03 ;>Must be in between the two labels to get the number of digits correct.
		PasscodeCorrectEnd:

print "Passcode door"
