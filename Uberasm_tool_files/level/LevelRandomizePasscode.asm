;Randomizes an N-digit passcode
incsrc "../CustomLayer3Menu_Defines/Defines.asm"

!NumberOfDigits = 4

!Manuel_Exanimation_Slots_to_Use = $00
 ;^Only use values from 0 to ($0F-NumberOfDigits+1, so that it does not write beyond RAM $7FC07F)
 ; What manuel slots to use. Note: Each digit being used at the moment will be !NumberOfDigits of
 ; Manuel slots starting from this value. Meaning if there are 4 maximum digits, and using manuel 0, this will occupy manuel
 ; numbers 0-3. (manuel numbers ranges from !Manuel_Exanimation_Slots_to_Use to !Manuel_Exanimation_Slots_to_Use+(!NumberOfDigits-1)).

init:
	;This randomizes the correct passcode
		LDA.b #!CustomL3Menu_MaxNumberOfDigitsInEntireGame-1
		STA !Freeram_CustomL3Menu_NumberOfCursorPositions
		JSL RandomizePasscode_RandomizePasscodeString
	;This will write the passcode to examination frames to display to the player.
		LDX.b #!NumberOfDigits-1
		-
		LDA !Freeram_CustomL3Menu_DigitCorrectPasscode,x
		STA $7FC070+!Manuel_Exanimation_Slots_to_Use
		DEX
		BPL -
	RTL