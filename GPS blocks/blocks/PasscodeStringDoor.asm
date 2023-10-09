;Act as $025
;Same as PasscodeDoor.asm but lets users enter a string with any character besides numbers.
;The correct passcode is conveniently under the label "CorrectPasscode"


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
	%DoorCenterPlayer()
	
	LDA #$04						;\Passcode string mode
	STA !Freeram_CustomL3Menu_UIState			;/
	LDA #$00						;\Initialize write phase
	STA !Freeram_CustomL3Menu_WritePhase			;/
	LDA.b #(CorrectPasscode_end-CorrectPasscode)-1		;\maximum number of characters.
	STA !Freeram_CustomL3Menu_NumberOfCursorPositions	;/
	
	REP #$20						;\Setup code to use when the user enters or exit the passcode.
	LDA.w #SuppliedCode					;|
	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1	;|
	SEP #$20						;|
	LDA.b #SuppliedCode>>16					;|
	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3	;/
	
	LDX.b #(CorrectPasscode_end-CorrectPasscode)-1		;\Setup correct passcode
	-							;|
	LDA CorrectPasscode,x					;|
	STA !Freeram_CustomL3Menu_DigitCorrectPasscode,x	;|
	DEX							;|
	BPL -							;/
	
	RTL

;WallFeet:	; when using db $37
;WallBody:

SpriteV:
SpriteH:
MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
HeadInside:
MarioCape:
MarioFireball:
Return:
	RTL
SuppliedCode:
	LDA $00
	BEQ .Confirm
	
	.Exit
		LDA #$08
		STA !Freeram_CustomL3Menu_WritePhase
		RTL
	.Confirm
		LDX.b #(CorrectPasscode_end-CorrectPasscode)-1
		..Loop
			LDA !Freeram_CustomL3Menu_DigitCorrectPasscode,x
			CMP !Freeram_CustomL3Menu_DigitPasscodeUserInput,x
			BNE ..IncorrectPasscode
			...Next
				DEX
				BPL ..Loop
		..EnteredCorrect
			if !CustomL3Menu_SoundEffectNumber_Correct != $00
				LDA #!CustomL3Menu_SoundEffectNumber_Correct
				STA !CustomL3Menu_SoundEffectPort_Correct
			endif
			LDA #$06				;\Teleport player.
			STA $71					;|
			STZ $89					;|
			STZ $88					;/
			BRA .Exit				;>UI mode must be exited in order for the teleport to work.
		..IncorrectPasscode
			if !CustomL3Menu_SoundEffectNumber_Rejected != $00
				LDA #!CustomL3Menu_SoundEffectNumber_Rejected
				STA !CustomL3Menu_SoundEffectPort_Rejected
			endif
			RTL
CorrectPasscode:
	;The correct passcode. If you want to have a higher maximum number of characters
	;than the number of characters the correct passcode has, pad it with spaces at
	;the end.
	;
	;Make sure they are all in caps for letters since the first page only contains
	;capitol letters.
	db "QWERTY  " ;>Must be in between the two labels to get the number of characters correct.
	.end

print "A passcode door that lets the player enters beyond numbers."
