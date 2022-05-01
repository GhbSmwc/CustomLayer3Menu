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

	org $00C5CE			;\fix hdma issues (like message box) when setting
	autoclean JSL FixHDMA		;/$7E0071 to #$0B ($00cde8 constantly sets $9D to $00 when $71 is $00.).
	NOP #4
	
	org $00EAA9			;\This is why blocks always assume $77, $13E1 and $13EE
	autoclean JSL BlockedFix	;/are stored as zero (this runs every frame).
	nop #1
	
	freecode
	
	MoveControllerToUI:
		.Restore
			LDA $0DA8|!addr,x		;\Restore controls.
			STA $18				;/
		.Main
			LDA !Freeram_CustomL3Menu_UIState	;\If UI mode, move controls to UI.
			BEQ .Done				;/
	
			..TransferControlsAndClear
				PHX
				LDX #$03			;>Handle 4 bytes of controller bytes.
	
				...Loop
					LDA $15,x				;\Transfer controls
					STA !Freeram_ControlBackup,x		;/
					STZ $15,x				;>And make everything ignore the "normal" controls
		
					....Next
						DEX				;\Next controller byte.
						BPL ...Loop			;/
		PLX
		RTL
		.Done
			RTL
	
	FixHDMA:
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
	
	BlockedFix:
	;	LDA $13E1+!addr		;\In case you also wanted blocks to detect slope, remove
	;	STA $xxxxxx		;/the semicolons (";") before it and add a freeram in place of xxxxxx
		STZ $13E1+!addr		;>Restore code (clears slope type)
	
		LDA $77				;\backup/save block status for use for blocks...
		STA !Freeram_BlockedStatBkp	;/
		STZ $77				;>...before its cleared.
	
		;^This (or both) freeram will get cleared when $77 and/or $13E1
		; gets cleared on the next frame due to a whole big loop SMW runs.
		; when mario isn't touching a solid object.
	
		;So after executing $00EAA9, you should use the freeram that has
		;the blocked and/or slope status saved in them. If before $00EAA9,
		;then use the original ($77 and/or $13E1). Do not write a value on
		;this freeram, it will do nothing, write on those default ram address.
		RTL