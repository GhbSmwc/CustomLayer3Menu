;This is a warp destination menu. Features include:
;-Lock and unlocked states. Useful for warps to be unlocked later in the game when you access other areas.
incsrc "../CustomLayer3Menu_Defines/Defines.asm"
table "../CustomLayer3Menu_Defines/ascii.txt"

init:
	.MenuSetup
		;These sets up the menu and trigger menu mode
		LDA.b #9-1							;\Number of options (9 of them: first 8 are warps, last 1 is exit)
		STA !Freeram_CustomL3Menu_NumberOfCursorPositions		;/
		LDA #$02							;\How many are shown on the screen (-1)
		STA !Freeram_CustomL3Menu_NumberOfDisplayedOptions		;/
		LDA #$00							;\Initiate the write phase (so that it appears properly before user does anything on the menu)
		STA !Freeram_CustomL3Menu_WritePhase				;/
		LDA #$02							;\Set it to "menu mode"
		STA !Freeram_CustomL3Menu_UIState				;/
		
		;This sets up the behavior (lock states) of each option
		..MenuDefaultBehavior
			LDX.b #7							;\A loop that sets the menu option states by default for options 0-7
			...Loop
				LDA ..MenuOptionActBehavior,x
				STA !Freeram_CustomL3Menu_MenuUptionBehavior,x
				LDA !Freeram_CustomL3Menu_UnlockWarpMenuFlags
				AND ..BitCheck,x
				BEQ ....Next
				LDA !Freeram_CustomL3Menu_MenuUptionBehavior,x		;\When 8-bit integers are even, it is %XXXXXXX0. So we can "add by 1" by setting
				ORA.b #%00000001					;|bit 0 (rightmost bit) from 0 to 1. Faster than INC or CLC : ADC #$01.
				STA !Freeram_CustomL3Menu_MenuUptionBehavior,x		;/
				
				....Next
					DEX
					BPL ...Loop					;/
			LDA #$10							;\Last option ("EXIT")
			STA !Freeram_CustomL3Menu_MenuUptionBehavior+$08		;/
		
		;This sets up the text data location so it can load up to display the option texts
		LDA.b #OptionTileTable						;\Setup the area to jump to to write our menu options.
		STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine		;|
		LDA.b #OptionTileTable>>8					;|
		STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1		;|
		LDA.b #OptionTileTable>>16					;|
		STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+2		;/
		RTL
		..MenuOptionActBehavior:
			;These are each option's default behavior (first item in table is for first option, and so on) to write to !Freeram_CustomL3Menu_MenuUptionBehavior.
			;
			;The values in the table except the last one (the "exit" option) should be even numbers (locked by default), which
			;corresponds to the "locked" state. Meaning values are:
			;$00-$01: Use screen 00
			;$02-$03: Use screen 01
			;$04-$05: Use screen 02
			;$06-$07: Use screen 03
			;$08-$09: Use screen 04
			;$0A-$0B: Use screen 05
			;$0C-$0D: Use screen 06
			;$0E-$0F: Use screen 07
			;When a bit in !Freeram_CustomL3Menu_UnlockWarpMenuFlags is SET, would increment one of the values in !Freeram_CustomL3Menu_MenuUptionBehavior,x
			;causing it to be an odd number which is the "unlocked" state the player can select.
			;
			db $00	;>When !Freeram_CustomL3Menu_CursorPos == $00, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (teleport via screen $00)
			db $02	;>When !Freeram_CustomL3Menu_CursorPos == $01, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (teleport via screen $01)
			db $04	;>When !Freeram_CustomL3Menu_CursorPos == $02, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (teleport via screen $02)
			db $06	;>When !Freeram_CustomL3Menu_CursorPos == $03, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (teleport via screen $03)
			db $08	;>When !Freeram_CustomL3Menu_CursorPos == $04, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (teleport via screen $04)
			db $0A	;>When !Freeram_CustomL3Menu_CursorPos == $05, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (teleport via screen $05)
			db $0C	;>When !Freeram_CustomL3Menu_CursorPos == $06, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (teleport via screen $06)
			db $0E	;>When !Freeram_CustomL3Menu_CursorPos == $07, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (teleport via screen $07)
			db $10	;>When !Freeram_CustomL3Menu_CursorPos == $08, use this value for !Freeram_CustomL3Menu_MenuUptionBehavior,x (exit)
		..BitCheck
			db %00000001
			db %00000010
			db %00000100
			db %00001000
			db %00010000
			db %00100000
			db %01000000
			db %10000000
main:
	.MenuBehavior
		;This sets up the behavior when selecting an option. This must run every frame only when the menu is opened.
		LDA !Freeram_CustomL3Menu_UIState		;\Must be in menu mode so that when the menu is closed does not have the possibility
		CMP #$02					;|of triggering the warp (assuming that it's possible to have such controller backup being
		;BNE ..Confirm_Teleport_Done			;/nonzero outside menus).
		BEQ +
		JMP ..Confirm_Teleport_Done
		+
		LDA !Freeram_CustomL3Menu_WritePhase						;\Don't allow confirmation during menu closing
		CMP #$02									;|
		BCC +
		JMP ..Confirm_Teleport_Done							;/
		+
		LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToConfirm		;\Button to confirm
		AND.b #!CustomL3Menu_ButtonConfirm						;|
		BNE ..Confirm									;|
		LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToConfirm2	;|
		AND.b #!CustomL3Menu_ButtonConfirm2						;|
		BNE ..Confirm									;/
		LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToCancel		;\Check if player cancels
		AND.b #!CustomL3Menu_ButtonCancel						;/
		BNE ..Confirm_Exit								;>Exit
		RTL
		..Confirm
			LDA !Freeram_CustomL3Menu_CursorPos		;\X index = What menu option is highlighted
			TAX						;/
			LDA !Freeram_CustomL3Menu_MenuUptionBehavior,x	;>A = the state of the highlighted option.
			CMP #$10					;\Option state $10+ are not warp options.
			BCC ...Teleport					;/Behavior number $10 is "BACK"
			;BEQ ...Exit
			...Exit
				LDA #!CustomL3Menu_SoundEffectNumber_Cancel		;\Cancel sound effect
				STA !CustomL3Menu_SoundEffectPort_Cancel		;/
				LDA #$02
				STA !Freeram_CustomL3Menu_WritePhase
				RTL
			
			...Teleport
				AND.b #%00000001
				BNE ....Unlocked
				
				....Locked
					LDA #!CustomL3Menu_SoundEffectNumber_Rejected
					STA !CustomL3Menu_SoundEffectPort_Rejected
					RTL
				....Unlocked
					LDA #!CustomL3Menu_SoundEffectNumber_Confirm		;\Confirm sound effect
					STA !CustomL3Menu_SoundEffectPort_Confirm		;/
					if !EXLEVEL
						JSL $03BCDC|!bank	;>LM's subroutine that calculate what screen the player is in since there are multiple boundaries on both X and Y.
					else
						LDA $5B			;\Get level type (horizontal/vertical)
						AND #$01		;|
						ASL 			;/
						TAX 			;>X is either 0 or 2
						LDA $95,x		;\And we load the high byte of the X or Y depending on level type,
						TAX			;/which is the screen's 16-block width/height
					endif
					;X = current screen number player is on.
					;LDA ($19B8+!screen_num)|!addr	;\adjust what screen exit to use for
					;STA $19B8|!addr,x		;|teleporting. Works by setting the current screen the player is in
					;LDA ($19D8+!screen_num)|!addr	;|to use another exit.
					;STA $19D8|!addr,x		;/
					PHB				;>Preserve bank
					PHK				;\Switch to current bank
					PLB				;/
					
					STX $06						;>$06: Current screen
					LDA !Freeram_CustomL3Menu_CursorPos		;\X index = What menu option is highlighted
					TAX						;/
					LDA !Freeram_CustomL3Menu_MenuUptionBehavior,x	;>A = the state of the highlighted option.
					TAY						;>Y = index based on behavior set.
					
					LDA #$7E					;\Bank bytes
					STA $02						;|
					STA $05						;/
					REP #$21					;\$00-$02: Contains an address $19B8
					LDA #$19B8					;|$03-$05: Contains an address $19D8
					STA $00						;|
					LDA #$19D8					;|
					STA $03						;/
					SEP #$20
					
					LDA $00						;\Adjust what byte in $19B8/$19D8 to write.
					ADC ....TeleportScreenToUse,y			;|
					STA $00						;|
					LDA $03						;|
					CLC						;|
					ADC ....TeleportScreenToUse,y			;|
					STA $03						;/
					
					LDX $06						;\Set the screen the player is in to use another screen's exit
					LDA ($00)					;|
					STA $19B8|!addr,x				;|
					LDA ($03)					;|
					STA $19D8|!addr,x				;/
					
					PLB			;>Restore bank
					LDA #$06 		;\Teleport the player.
					STA $71  		;|
					STZ $88			;|
					STZ $89			;/
					LDA #$01
					STA !Freeram_CustomL3Menu_UIState
				....Done
					RTL
				....TeleportScreenToUse
					;These are screen numbers to use, NOT by option's position in the menu, but by
					;the current-option-the-cursor-is-on's !Freeram_CustomL3Menu_MenuUptionBehavior,x value.
					;So if the cursor is on ANY option that has a !Freeram_CustomL3Menu_MenuUptionBehavior,x
					;being a value of 01, it will choose the second item (0-based indexing) on this table.
					db $00		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $00 (screen $00, locked)
					db $00		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $01 (screen $00, unlocked)
					db $01		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $02 (screen $01, locked)
					db $01		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $03 (screen $01, unlocked)
					db $02		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $04 (screen $02, locked)
					db $02		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $05 (screen $02, unlocked)
					db $03		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $06 (screen $03, locked)
					db $03		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $07 (screen $03, unlocked)
					db $04		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $08 (screen $04, locked)
					db $04		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $09 (screen $04, unlocked)
					db $05		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $0A (screen $05, locked)
					db $05		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $0B (screen $05, unlocked)
					db $06		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $0C (screen $06, locked)
					db $06		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $0D (screen $06, unlocked)
					db $07		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $0E (screen $07, locked)
					db $07		;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x == $0F (screen $07, unlocked)
	OptionTileTable:
		;String to display based on what value for !Freeram_CustomL3Menu_MenuUptionBehavior.
		;
		;There MUST be exactly !CustomL3Menu_MenuDisplay_OptionCharLength number of characters
		;in each string here. So if there is a string that's shorter, pad spaces at the end
		;to match it. This is so that when a string is being replaced with a shorter one,
		;will not have leftover tiles from the replaced string.
		;
		;Each string here is each value of !Freeram_CustomL3Menu_MenuUptionBehavior with the
		;first one being $00.
		db "01. LOCKED   " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $00
		db "01. SCREEN 00" ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $01
		db "02. LOCKED   " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $02
		db "02. SCREEN 01" ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $03
		db "03. LOCKED   " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $04
		db "03. SCREEN 02" ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $05
		db "04. LOCKED   " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $06
		db "04. SCREEN 03" ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $07
		db "05. LOCKED   " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $08
		db "05. SCREEN 04" ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $09
		db "06. LOCKED   " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $0A
		db "06. SCREEN 05" ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $0B
		db "07. LOCKED   " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $0C
		db "07. SCREEN 06" ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $0D
		db "08. LOCKED   " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $0E
		db "08. SCREEN 07" ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $0F
		db "BACK         " ;>When !Freeram_CustomL3Menu_MenuUptionBehavior,x = $10