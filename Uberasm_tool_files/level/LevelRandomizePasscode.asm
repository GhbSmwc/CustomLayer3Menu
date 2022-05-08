;Randomizes an N-digit passcode
incsrc "../CustomLayer3Menu_Defines/Defines.asm"


init:
	LDA.b #!CustomL3Menu_MaxNumberOfDigitsInEntireGame-1
	STA !Freeram_CustomL3Menu_NumberOfCursorPositions
	JSL RandomizePasscode_RandomizePasscodeString
	RTL