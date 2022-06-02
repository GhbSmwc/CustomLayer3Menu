
incsrc "../CustomLayer3Menu_Defines/Defines.asm"
table "../CustomLayer3Menu_Defines/ascii.txt"

init:
	.MenuSetup
		LDA.b #(..MenuOptionActBehavior_End-..MenuOptionActBehavior)-1	;\Number of options (-1)
		STA !Freeram_CustomL3Menu_NumberOfCursorPositions		;/
		LDA #$02							;\How many are shown on the screen (-1)
		STA !Freeram_CustomL3Menu_NumberOfDisplayedOptions		;/
		LDA #$00							;\Initiate the write phase (so that it appears properly before user does anything on the menu)
		STA !Freeram_CustomL3Menu_WritePhase				;/
		LDA #$02							;\Set it to "menu mode"
		STA !Freeram_CustomL3Menu_UIState				;/
		LDX.b #(..MenuOptionActBehavior_End-..MenuOptionActBehavior)-1	;\A loop that sets the menu option states
		-
		LDA ..MenuOptionActBehavior,x
		STA !Freeram_CustomL3Menu_MenuUptionID,x
		DEX
		BPL -								;/
		LDA.b #OptionTileTable						;\Setup the area to jump to to write our menu options.
		STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine		;|
		LDA.b #OptionTileTable>>8					;|
		STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1		;|
		LDA.b #OptionTileTable>>16					;|
		STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+2		;/
		RTL
		..MenuOptionActBehavior:
			;These are each option's behavior to write to !Freeram_CustomL3Menu_MenuUptionID.
			db $00	;>When !Freeram_CustomL3Menu_CursorPos == $00, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $01	;>When !Freeram_CustomL3Menu_CursorPos == $01, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $02	;>When !Freeram_CustomL3Menu_CursorPos == $02, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $03	;>When !Freeram_CustomL3Menu_CursorPos == $03, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $04	;>When !Freeram_CustomL3Menu_CursorPos == $04, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $05	;>When !Freeram_CustomL3Menu_CursorPos == $05, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $06	;>When !Freeram_CustomL3Menu_CursorPos == $06, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $07	;>When !Freeram_CustomL3Menu_CursorPos == $07, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $08	;>When !Freeram_CustomL3Menu_CursorPos == $08, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			db $09	;>When !Freeram_CustomL3Menu_CursorPos == $09, use this value for !Freeram_CustomL3Menu_MenuUptionID,x
			...End
main:
	.MenuBehavior
		LDA !Freeram_CustomL3Menu_UIState	;\Must be in menu mode so that when the menu is closed does not have the possibility
		CMP #$02				;|of triggering the warp (assuming that it's possible to have such controller backup being
		BCS +					;/nonzero outside menus).
		RTL
		+
		LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToConfirm
		AND.b #!CustomL3Menu_ButtonConfirm
		BNE ..Confirm
		LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToConfirm2
		AND.b #!CustomL3Menu_ButtonConfirm2
		BNE ..Confirm
		BRA ..MenuOptionBehavior_Nothing
		..Confirm
		LDA !Freeram_CustomL3Menu_CursorPos		;\X index = What menu option is highlighted
		TAX						;/
		LDA !Freeram_CustomL3Menu_MenuUptionID,x	;>A = the state of the highlighted option.
		ASL
		TAX
		BCS +
		JMP.w (..MenuOptionBehavior,x)
		+
		JMP.w (..MenuOptionBehavior+128,x)
	
		..MenuOptionBehavior:
			;Now here, Each item in this list is each value for !Freeram_CustomL3Menu_MenuUptionID.
			;Therefore causes a jump in the code to run different codes/behaviors based on what's stored
			;in !Freeram_CustomL3Menu_MenuUptionID.
			;
			;Assuming you didn't edit this ASM file, choosing the first item in the menu will pick behavior
			;$01, which when getting to here, will use the second item in this list. This behavior
			;number gets decremented by 1 (another table will be used and because 0-based indexing), use
			;that number as an index (y register) to grab a value from a table "....TeleportScreenToUse"
			;which in turn sets up what screen exit to use during teleporting.
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $00 (X = $00)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $01 (X = $02)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $02 (X = $04)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $03 (X = $06)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $04 (X = $08)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $05 (X = $0A)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $06 (X = $0C)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $07 (X = $0E)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $08 (X = $10)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $09 (X = $12)
			dw ...Teleport			;>!Freeram_CustomL3Menu_MenuUptionID,x = $0A (X = $14)
		
			...Nothing
				RTL
			...Teleport
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
				LDA !Freeram_CustomL3Menu_MenuUptionID,x	;>A = the state of the highlighted option.
				TAY						;>Y = index of what screen to use
				
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
				RTL
				....TeleportScreenToUse
					db $01
					db $02
					db $03
					db $04
					db $05
					db $06
					db $07
					db $08
					db $09
					db $0A
	OptionTileTable:
		;String to display based on what value for !Freeram_CustomL3Menu_MenuUptionID.
		;
		;There MUST be exactly !CustomL3Menu_MenuDisplay_OptionCharLength number of characters
		;in each string here. So if there is a string that's shorter, pad spaces at the end
		;to match it. This is so that when a string is being replaced with a shorter one,
		;will not have leftover tiles from the replaced string.
		;
		;Each string here is each value of !Freeram_CustomL3Menu_MenuUptionID with the
		;first one being $00.
		db "SCREEN 01" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $00
		db "SCREEN 02" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $01
		db "SCREEN 03" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $02
		db "SCREEN 04" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $03
		db "SCREEN 05" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $04
		db "SCREEN 06" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $05
		db "SCREEN 07" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $06
		db "SCREEN 08" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $07
		db "SCREEN 09" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $08
		db "SCREEN 0A" ;>When !Freeram_CustomL3Menu_MenuUptionID,x = $09
	RTL