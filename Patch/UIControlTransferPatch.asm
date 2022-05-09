;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This patch disable player and sprite reacting to controls when being
;in UI mode.

;This also render blocks to be able to check if the player is on the
;ground.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ROM type detector:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	!dp = $0000
	!addr = $0000
	!sa1 = 0
	!gsu = 0

if read1($00FFD6) == $15
	sfxrom
	!dp = $6000
	!addr = !dp
	!gsu = 1
elseif read1($00FFD5) == $23
	sa1rom
	!dp = $3000
	!addr = $6000
	!sa1 = 1
endif

incsrc "../CustomLayer3Menu_Defines/Defines.asm"

	org $0086C1				;\Control transfer
	autoclean JSL MoveControllerToUI	;|
	nop					;/

	org $00C5CE				;\fix hdma issues (like message box) when setting
	autoclean JSL FixHDMA			;/$7E0071 to #$0B ($00cde8 constantly sets $9D to $00 when $71 is $00.).
	NOP #4
	
	org $00EED4
	autoclean JML DontMoveMario1PixelUp	;This fixes an issue where centering the player vertically within a block can sometimes make mario 1 pixel higher
	
	freecode
	
	MoveControllerToUI:	;>JSL from $0086C1
		.Restore
			LDA $0DA8|!addr,x		;\Restore controls.
			STA $18				;/
		.Main
			LDA !Freeram_CustomL3Menu_UIState	;\If UI mode, move controls to UI.
			BEQ .Done				;/
	
			..TransferControlsAndClear
;				PHX
;				LDX #$03			;>Handle 4 bytes of controller bytes.
;	
;				...Loop
;					LDA $15,x				;\Transfer controls
;					STA !Freeram_ControlBackup,x		;/
;					STZ $15,x				;>And make everything ignore the "normal" controls
;		
;					....Next
;						DEX				;\Next controller byte.
;						BPL ...Loop			;/
;				PLX
				LDA $15				;\Unrolled loop because the controller data processing is during Vblank.
				STA !Freeram_ControlBackup	;|
				LDA $16				;|
				STA !Freeram_ControlBackup+1	;|
				LDA $17				;|
				STA !Freeram_ControlBackup+2	;|
				LDA $18				;|
				STA !Freeram_ControlBackup+3	;/
		RTL
		.Done
			RTL
	
	FixHDMA:	;>JSL from $00C5CE
		LDA $0D9B|!addr
		CMP #$C1
		BNE .NormalLevel

		.BowserFight
			;Restore code
			STZ.W $0D9F|!addr		;>no HDMA!
			LDA.B #$01			;\
			STA.W $1B88|!addr		;/ message box is expanding

		.NormalLevel
			RTL
			
	DontMoveMario1PixelUp:		;>JSL from $00EED4
		LDA $13FB|!addr
		;ORA $xxxx
		BNE .NoMove
		.Restore
			LDA $96
			SEC
			SBC $91
			JML $80EED9
		.NoMove
			JML $80EEE1