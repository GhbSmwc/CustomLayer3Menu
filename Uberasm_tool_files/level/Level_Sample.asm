;a simple 4-digit passcode
incsrc "../CustomLayer3Menu_Defines/Defines.asm"


init:
	LDA #$01
	STA !Freeram_CustomL3Menu_UIState
	LDA #$00
	STA !Freeram_CustomL3Menu_CursorPos
	STA !Freeram_CustomL3Menu_WritePhase
	RTL