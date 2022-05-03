;a simple 4-digit passcode
incsrc "../CustomLayer3Menu_Defines/Defines.asm"


init:
	.PasscodeSetup
	;Setup number input
	LDA #$03							;\Mode: Number input
	STA !Freeram_CustomL3Menu_UIState				;/
	LDA #$00							;>zero out...
	STA !Freeram_CustomL3Menu_CursorPos				;>Cursor position (cursor is at position 0)
	STA !Freeram_CustomL3Menu_WritePhase				;>Start at the write phase to avoid potential NMI overflows (will start out writing each line top to bottom)
	LDA.b #(..PasscodeCorrect_End-..PasscodeCorrect)-1			;\Number of digits or cursor positions
	STA !Freeram_CustomL3Menu_NumberOfCursorPositions		;/
	
	;Default the original passcode to all zeroes and setup the correct passcode
		LDX.b #(..PasscodeCorrect_End-..PasscodeCorrect)-1
		..Loop
			LDA #$00
			STA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x
			LDA ..PasscodeCorrect,x
			STA !Freeram_CustomL3Menu_DigitCorrectPasscode,x
			...Next
				DEX
				BPL ..Loop

		REP #$20
		LDA.w #..SuppliedCode					;\[aa bb] -> $xxbbaa (remember, little endian)
		STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1	;/
		SEP #$20
		LDA.b #..SuppliedCode>>16					;\[cc] -> $ccbbaa
		STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3	;/
		RTL
		..SuppliedCode:
			LDA $00
			BNE ...Done
			...PasscodeCheck
				;Check if passcode entered by player is correct
				LDX.b #(..PasscodeCorrect_End-..PasscodeCorrect)-1
				....PasscodeCheckLoop
					LDA !Freeram_CustomL3Menu_DigitCorrectPasscode,x
					CMP !Freeram_CustomL3Menu_DigitPasscodeUserInput,x
					BNE ....Incorrect
					.....Next
						DEX
						BPL ....PasscodeCheckLoop
				....Correct
					LDA #!CustomL3Menu_SoundEffectNumber_Correct
					STA !CustomL3Menu_SoundEffectPort_Correct
					BRA ...Done
				....Incorrect
					LDA #!CustomL3Menu_SoundEffectNumber_Rejected
					STA !CustomL3Menu_SoundEffectPort_Rejected
			...Done
			RTL	;>This MUST end with an RTL because of the aforementioned "JSL !Freeram_CustomL3Menu_PasscodeCallBackSubroutine"

	RTL
	
	..PasscodeCorrect
		db $00,$01,$02,$03 ;>Must be in between "..PasscodeCorrect" and "...End" to correctly count how many bytes here.
		...End