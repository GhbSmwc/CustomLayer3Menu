;Act as $025
;This is the same as "PasscodeDoor.asm" BUT does not SET the passcode and is intended to work with randomized passcode.
;
;Note: This block itself does not set the passcode randomly. Make sure you set the passcode (via a randomizer) before
;the player is able to use this block. This can be done by randomizing the passcode on level init or when they start
;a new game.

!Number_Of_Digits = 4
 ;^How many digits this passcode block has.

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
	LDA.b #!Number_Of_Digits-1				;\Number of digits or cursor positions
	STA !Freeram_CustomL3Menu_NumberOfCursorPositions	;/
	REP #$20						;\Setup code to use when the user enters or exit the passcode.
	LDA.w #SuppliedCode					;|
	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1	;|
	SEP #$20						;|
	LDA.b #SuppliedCode>>16					;|
	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3	;/
	
	
	LDX.b #!Number_Of_Digits-1		;\Default the original passcode to all zeroes.
	-							;|
	LDA #$00						;|
	STA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;|
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
		LDX.b #!Number_Of_Digits-1
		..PasscodeCheckLoop
			LDA !Freeram_CustomL3Menu_DigitCorrectPasscode,x
			CMP !Freeram_CustomL3Menu_DigitPasscodeUserInput,x
			BNE ..Incorrect
			...Next
				DEX
				BPL ..PasscodeCheckLoop
		..Correct
			if !CustomL3Menu_SoundEffectNumber_Correct != $00
				LDA #!CustomL3Menu_SoundEffectNumber_Correct
				STA !CustomL3Menu_SoundEffectPort_Correct
			endif
			LDA #$06				;\Teleport player.
			STA $71					;|
			STZ $89					;|
			STZ $88					;/
			BRA .Done
		..Incorrect
			if !CustomL3Menu_SoundEffectNumber_Rejected != $00
				LDA #!CustomL3Menu_SoundEffectNumber_Rejected
				STA !CustomL3Menu_SoundEffectPort_Rejected
			endif
	.Done
		LDA #$03				;\Initiate closing the passcode mode and clear the stripe image tiles.
		STA !Freeram_CustomL3Menu_WritePhase	;/
		RTL

print "Randomized Passcode door"
