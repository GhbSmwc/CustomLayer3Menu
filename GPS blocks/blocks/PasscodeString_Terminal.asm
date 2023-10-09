;Act as $025
;This is a "terminal" that when UP is pressed will bring up the passcode UI. If the player cancels, the menu just closes with "cancel" sound effect.
;If the player enters the correct passcode, it plays the "correct" sound effect, closes the menu, and sets or clears the animation trigger flag.
;If the player enters the incorrect passcode, it plays the "incorrect" sound effect and closes the menu.
;
;This is the string version of the passcode terminal that the player can enter more than just numbers.
;
;I call this a gate because it is an obstacle that enables the player to access another area in the SAME level without the warp animation when the
;passcode is correct rather than being an object that teleports the player to another level.
;
;The animation trigger flag can be used along with the custom trigger blocks: https://www.smwcentral.net/?p=section&a=details&id=3931 , preferably
;blocks that are solid then become passable when the correct passcode is entered.

;The correct passcode is under the label "PasscodeCorrect". Notes:
; -Be careful not to have the string too long (each character is a byte, including the space character) than
;  !CustomL3Menu_MaxNumberOfDigitsInEntireGame as it could end up overwriting/overreading bytes beyond
;  !Freeram_CustomL3Menu_DigitPasscodeUserInput+<Expected_max_number_of_bytes>-1 and
;  !Freeram_CustomL3Menu_DigitCorrectPasscode+<Expected_max_number_of_bytes>-1 (so if you for example expect no more than 8 characters, and you have
;  more than 8, data will be written and read past the last bytes of !Freeram_CustomL3Menu_DigitPasscodeUserInput and
;  Freeram_CustomL3Menu_DigitCorrectPasscode and can cause issues).
; -It is case sensitive. Meaning by default, the input character set's letters are all capitalized, therefore you should have them in all caps as
;  the correct passcode.


;Custom trigger to use
 !CustomTrigger = $02
  ;^Only enter $00-$0F (0-15). This is what LM's CUSTOM trigger to use.
 !ClearOrSet = 1
  ;^0 = clear (bit will be 0)
  ; 1 = set (bit will be 1)

 ;Don't touch, these calculates should it use $7FC0FC or $7FC0FD,
 ;as well as what bit in the byte to use.
  !CustomTrigger_WhichByte #= !CustomTrigger/8 ;This will be 0 if using triggers $00-$07, otherwise 1 if $08-$0F
  !CustomTrigger_BitToUse #= %00000001<<(!CustomTrigger%8)


incsrc "../CustomLayer3Menu_Defines/Defines.asm"
table "../CustomLayer3Menu_Defines/ascii.txt"

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
	LDA $7FC0FC+!CustomTrigger_WhichByte			;\If player already enters the correct passcode, if he tries to do it again, do nothing.
	AND.b #!CustomTrigger_BitToUse				;|
	if !ClearOrSet == 0					;|
		BEQ Return
	else
		BNE Return
	endif							;/
	LDA #$04						;\Activate the menu
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
	
	LDX.b #(PasscodeCorrectEnd-PasscodeCorrect)-1		;\Set what is the correct passcode into the table
	-							;|
	LDA.w PasscodeCorrect,x					;|
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
			wdm
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
				LDA $7FC0FC+!CustomTrigger_WhichByte		;\Write trigger bit.
				if !ClearOrSet == 0
					AND.b #!CustomTrigger_BitToUse^$FF
				else
					ORA.b #!CustomTrigger_BitToUse
				endif
				STA $7FC0FC+!CustomTrigger_WhichByte		;/
				BRA .Done
			..Incorrect
				if !CustomL3Menu_SoundEffectNumber_Rejected != $00
					LDA #!CustomL3Menu_SoundEffectNumber_Rejected
					STA !CustomL3Menu_SoundEffectPort_Rejected
				endif
				RTL
	.Done
		LDA #$08				;\Initiate closing the passcode mode and clear the stripe image tiles.
		STA !Freeram_CustomL3Menu_WritePhase	;/
		RTL

	PasscodeCorrect:
		db "QWERTY  " ;>Must be in between the two labels to get the number of characters correct.
	PasscodeCorrectEnd:
print "Passcode terminal"
