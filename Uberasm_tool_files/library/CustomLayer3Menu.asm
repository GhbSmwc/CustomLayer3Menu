;This main code should be run using "JSL CustomLayer3Menu_ProcessLayer3Menu" from gamemode 14.

;NOTE: To prevent potential NMI overflows (flickering black bars at the top of the
;screen), Tiles are written only when an "update" occurs, not every frame (such as
;moving the cursor, changing the settings in a options menu).

;Subroutines included here that can be used by any menu/UI types:
;-DPadMoveCursorOnMenu
;-SetupStripeHeaderAndIndex
;-FinishStripe

	incsrc "../CustomLayer3Menu_Defines/Defines.asm"
	table "../CustomLayer3Menu_Defines/ascii.txt"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Process layer 3 menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TurboPulseRates:
	;These are the increment rates when holding on the D-pad.
	;This is the amount of delay, (2^n)-1, where n is a non-negative integer is every 2, 4, 8, 16... frames of $13 in between
	;each direction firing. I don't recommend having a rate of firing every frame as that could cause audio problems (every
	;time a sound is played starts silent first).
	db %00000111	;>Slow (!Freeram_CustomL3Menu_DpadPulser is within values 8-29 quad-frames (every 4th frame from $13))
	db %00000011	;>Medium (30-59)
	db %00000001	;>Fast (60+)
ProcessLayer3Menu:
	LDA !Freeram_CustomL3Menu_UIState
	BNE +
	.Done
	LDA #$00					;\Prevent opening the menu and if the player holds down the D-pad
	STA !Freeram_CustomL3Menu_DpadHoldTimer		;/the timer will pick up right where it left off and starts out with full speed.
	RTL
	+
	
	.HandleFrozen
		;CMP #$XX		;\If you want some UI states to not freeze time,
		;BEQ .SkipFreeze	;/uncomment the code here.
		LDA $71			;\Don't cancel Mario's teleportation or other animation
		CMP #$0B
		BEQ ..Freeze
		CMP #$06
		BEQ ..Teleporting
		CMP #$00
		BNE .Done	;/
	
		..Freeze
			LDA #$0B		;\Allow $9D not to be cleared.
			STA $71			;/
	
		..Teleporting
			LDA #$01
			STA $9D
			STA $13FB|!addr		;>Also make player ignore gravity.
			;NOTE: $13FB also freezes teleportation, preventing a warp until this value is $00.
		..SkipFreeze
	.DpadTurbo
		;This handles when the user holds down the D-pad long enough, will trigger a "repeat key press".
		;Good for accessibility especially for huge menus.
		LDA !Freeram_CustomL3Menu_DpadPulser		;\Clear out the pulse D-pad bits.
		AND.b #%00001111				;|
		STA !Freeram_CustomL3Menu_DpadPulser		;/
		LDA !Freeram_ControlBackup+1			;\And write the 1-frame D-pad inputs (so if the user shortly presses a direction, the first frame guaranteed a cursor move)
		ASL #4						;|
		ORA !Freeram_CustomL3Menu_DpadPulser		;|
		STA !Freeram_CustomL3Menu_DpadPulser		;/
		..CheckHoldingDownDpadWithoutChanging
			LDA !Freeram_CustomL3Menu_DpadPulser
			AND.b #%00001111
			STA $00					;>$00 = previous D-pad input
			LDA !Freeram_ControlBackup+0		;\If not pressing in any direction, no turbo
			AND.b #%00001111			;|
			BEQ ..ResetTurbo			;/
			CMP $00					;\If changed D-pad direction, no turbo
			BNE ..ResetTurbo			;/
		..IncrementTurboTimerAndFireTurbo
			LDA !Freeram_CustomL3Menu_DpadHoldTimer
			CMP #$FF				;>Overflow protection
			BEQ ...NoIncrementTimer
			LDA $13					;\Every 4th frame...
			AND.b #%00000011			;|
			BNE ...NoIncrementTimer			;/
			LDA !Freeram_CustomL3Menu_DpadHoldTimer	;\...Increase timer. Therefore each unit of !Freeram_CustomL3Menu_DpadHoldTimer = Frames*4
			INC					;|
			STA !Freeram_CustomL3Menu_DpadHoldTimer	;/
			...NoIncrementTimer
			LDA !Freeram_CustomL3Menu_DpadHoldTimer
		..ThreasholdSpeeds
			;Remember, Ticks = Seconds*15
			CMP.b #8				;\Prevent the multi-tap when the player taps just once (no accidental additional move cursor).
			BCC ..UpdatePreviousInput		;/
			LDX #$00				;\Slow rate (X = $00)
			CMP.b #(2*15)				;|
			BCC ...Pulse				;/
			INX					;\Medium rate (X = $01)
			CMP.b #(4*15)				;|
			BCC ...Pulse				;/
			INX					;>Fast rate (X = $02)
			
			...Pulse
				LDA $13						;\Only every 2^n frames allows turbo pulsing
				AND TurboPulseRates,x				;|
				BNE ..UpdatePreviousInput			;/
				LDA !Freeram_CustomL3Menu_DpadPulser		;\Clear high nybble of pulser...
				AND.b #%00001111				;|
				STA !Freeram_CustomL3Menu_DpadPulser		;/
				LDA !Freeram_ControlBackup			;\...then set only that high nybble of pulser.
				ASL #4						;|
				ORA !Freeram_CustomL3Menu_DpadPulser		;|
				STA !Freeram_CustomL3Menu_DpadPulser		;/
				BRA ..UpdatePreviousInput
		..ResetTurbo
			LDA #$00
		..WriteTurboTimer
			STA !Freeram_CustomL3Menu_DpadHoldTimer
		..UpdatePreviousInput
			LDA !Freeram_CustomL3Menu_DpadPulser		;\Clear low nybble of pulser...
			AND.b #%11110000				;|
			STA !Freeram_CustomL3Menu_DpadPulser		;/
			LDA !Freeram_ControlBackup			;\...then set only that low nybble of pulser.
			AND.b #%00001111				;|
			ORA !Freeram_CustomL3Menu_DpadPulser		;|
			STA !Freeram_CustomL3Menu_DpadPulser		;/
	
	.MenuTypeHandler
		LDA !Freeram_CustomL3Menu_UIState
		ASL			;\Values >= 128 would have bit 7 being set, which
		TAX			;|"overflows" when a left-shift is performed. When this happens
		BCS +			;/the carry flag is set, so we can make it use a separate table.
		JMP.w (MenuStates-2,x)
		+
		JMP.w (MenuStates-2+128,x)
	
	MenuStates:
		dw ExitMenuEnablePlayerMovement		;>!Freeram_CustomL3Menu_UIState = $01 (X = $02)
		dw MenuSelection			;>!Freeram_CustomL3Menu_UIState = $02 (X = $04)
		dw NumberInput				;>!Freeram_CustomL3Menu_UIState = $03 (X = $06)
		dw ValueAdjustMenu			;>!Freeram_CustomL3Menu_UIState = $04 (X = $08)
	;--------------------------------------------------------------------------------
	;These are codes that handle the behavior of each menu types
	;$00 contains the index of what menu type of the current menu.
	;--------------------------------------------------------------------------------
	;--------------------------------------------------------------------------------
	;Close menu and enable player movement (shouldn't execute every frame)
	;--------------------------------------------------------------------------------
	ExitMenuEnablePlayerMovement:
		LDA #$00				;\Close menu so that the following code does not execute every frame
		STA !Freeram_CustomL3Menu_UIState	;/
		LDA $71					;\Allow the player to teleport when frozen. Also don't interfere with other animations.
		CMP #$0B
		BEQ .Clear
		CMP #$00
		BNE .Skip				;|
		
		.Clear
		STZ $71					;/
		
		.Skip
		LDA #$00
		STA $13FB|!addr				;\Enable player movement and also teleport since $13FB != 0 would freeze teleport.
		STA $9D					;|
		STA !Freeram_CustomL3Menu_WritePhase	;/
		RTL
	;--------------------------------------------------------------------------------
	;This one is a standard menu.
	;--------------------------------------------------------------------------------
		MenuSelectionBitwiseMenuScroll:
			db %00000000
			db %00000010
		ShouldArrowAppear:
			dw $38FC		;>Blank tile and properties when the menu position is at the top or when the menu is at the bottom
			dw (!CustomL3Menu_MenuDisplay_ScrollArrowProperties<<8)|!CustomL3Menu_MenuDisplay_ScrollArrowNumber	;>Tile number and properties for when the menu can scroll up or down.
		MenuSelection:
			PHB					;>Preserve bank
			PHK					;\Change bank so that $xxxx,y works correctly
			PLB					;/

			LDA !Freeram_CustomL3Menu_WritePhase
			ASL
			TAX
			JMP.w (.MenuSelectionStates,x)
			
			.MenuSelectionStates
				dw ..RespondToUserInput			;>!Freeram_CustomL3Menu_WritePhase == $00
				dw ..RespondToUserInput			;>!Freeram_CustomL3Menu_WritePhase == $01
				dw ..CloseMenuDeleteCursor		;>!Freeram_CustomL3Menu_WritePhase == $02
				dw ..CloseMenuDeleteOptions		;>!Freeram_CustomL3Menu_WritePhase == $03
				dw ..CloseMenuDeleteScrollArrows	;>!Freeram_CustomL3Menu_WritePhase == $04
			
				..RespondToUserInput
					LDA !Freeram_CustomL3Menu_CursorPos				;\Cursor position, relative to scroll position
					SEC								;|
					SBC !Freeram_CustomL3Menu_MenuScrollPos				;/
					STA $06								;>$06 = Cursor position relative to scroll (used as to check if it move in "relation to the screen" to know if a VRAM update is needed)
					LDA !Freeram_CustomL3Menu_MenuScrollPos
					STA $01								;>$01 = Scroll position (before the change, again, used to check should the options need an update)
					LDX #$00							;>Vertical menu
					JSL DPadMoveCursorOnMenu
					...IfPlayerCancels
						LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToCancel	;\Check if player cancels
						AND.b #!CustomL3Menu_ButtonCancel					;/
						BEQ +
						LDA #$02								;\Begin closing the menu
						STA !Freeram_CustomL3Menu_WritePhase					;/
						JMP .Done
						+
					...ClampTheScrollPosToBeWhereTheCursorIsAt
						;We have to treat the positions here as if they're 16-bit so that we can have more than 127 possible options without
						;potential glitches as well as when the cursor wraps the menu.
						;
						;This calculates the scroll position
						LDA !Freeram_CustomL3Menu_CursorPos			;\Carry here clears if CursorPos < ScrollPos
						SEC							;|
						SBC !Freeram_CustomL3Menu_MenuScrollPos			;|
						LDA #$00						;|
						SBC #$00						;/
						BMI ....ScrollUp					;>Which can be used to check if the cursor is above the scrolled area.
						
						....HandleScrollDown
						LDA !Freeram_CustomL3Menu_MenuScrollPos			;\$02-$03: Last option displayed position
						CLC							;|
						ADC !Freeram_CustomL3Menu_NumberOfDisplayedOptions	;|
						STA $02							;|
						LDA #$00						;|
						ADC #$00						;|
						STA $03							;/
						LDA !Freeram_CustomL3Menu_CursorPos			;\$02-$03: Cursor position, relative to scroll position.
						SEC							;|
						SBC $02							;|
						STA $02							;|
						LDA #$00						;|
						SBC $03							;|
						STA $03							;/
						REP #$20
						LDA $02
						SEP #$20
						BEQ ....ScrollDone					;\If cursor relative to scroll pos is past the last displayed option, scroll down.
						BPL ....ScrollDown					;/
						BRA ....ScrollDone					;>Situation where the cursor moves but not scroll.
						....ScrollUp
							LDA !Freeram_CustomL3Menu_CursorPos
							BRA ....WriteScrollPos
						....ScrollDown
							LDA !Freeram_CustomL3Menu_CursorPos
							SEC
							SBC !Freeram_CustomL3Menu_NumberOfDisplayedOptions
						....WriteScrollPos
							STA !Freeram_CustomL3Menu_MenuScrollPos
						....ScrollDone
					...ChangeDetection
						;These figures out wheter or not if the cursor graphic needs to change or not, as well as the text.
						....Cursor
							LDX #$00
							LDA !Freeram_CustomL3Menu_CursorPos
							SEC
							SBC !Freeram_CustomL3Menu_MenuScrollPos
							CMP $06
							BEQ .....NoCursorChange
							.....CursorChange
								INX
							.....NoCursorChange
							STX $07			;>$07: %0000000C, C bit:Cursor needs to update: 0 = no, 1 = yes.
						....Scroll
							LDX #$00
							LDA !Freeram_CustomL3Menu_MenuScrollPos
							CMP $01
							BEQ .....NoScroll
							.....DidScroll
								INX
							.....NoScroll
							LDA $07
							ORA MenuSelectionBitwiseMenuScroll,x
							STA $07			;>$07: %000000SC, S bit: scroll needs to update: 0 = no, 1 = yes.
					...DrawMenu
						;We now have the info stored:
						;-RAM $00-$05 will be used for handling stripe
						;-Taking the value stored in !Freeram_CustomL3Menu_CursorPos and subtracting whats stored in
						; !Freeram_CustomL3Menu_MenuScrollPos right here will give you the current cursor position relative to the scroll position.
						;-RAM $06: Previous cursor position relative to the scroll (effectively this is the position "relative to the screen"), before it was moved.
						; This is needed so that when the cursor move without scrolling, or have wrapped to and from the first and last item in a menu when
						; the number of options is longer than how many options shown, to erase the previous cursor with the new cursor drawn on the current option.
						;
						;-RAM $07: What menu elements need to update, format:
						;
						; %000000SC
						; 
						; C = Cursor position change in relation to the scroll position. When just the cursor moves and no scrolling occurred,
						;     this bit is set.
						; S = Scrolled flag. When menu scrolling occurred (move cursor upwards when it is at the top or downwards at the bottom),
						;     this bit is set.
						; 
						; Both C and S bits are set when a wraparound occurred and the displayed options are less than the number of existing options.
						; 
						;Reason to have such an info is we need to only update the tiles if necessary. This is to prevent potential VRAM overflow:
						;black bars flickering at the top of the screen.
						....Cursor
							;DrawCursorPos = (CursorPosRelativeToScroll*2) + (#!CustomL3Menu_MenuDisplay_YPos + 1)
							;
							;(CursorPos*2) makes it so the cursor jumps up/down by 2 lines since the menu are "double-spaced" line breaks.
							LDA !Freeram_CustomL3Menu_WritePhase			;\Draw cursor (so when the menu appears, and before the player moves the cusor, the cursor shows up and not only show the options)
							BEQ .....WriteCurrentCursorPos				;/
							LDA $07
							AND.b #%00000001
							BEQ .....CursorWriteDone
							.....ErasePreviousCursor
								LDA $06						;\Y position
								ASL						;|
								CLC						;|
								ADC #!CustomL3Menu_MenuDisplay_YPos+1		;|
								STA $01						;/
								JSR .SetupStripeInputs
								JSL SetupStripeHeaderAndIndex
								LDA #$FC					;\Tile number
								STA.l $7F837D+4,x				;/
								LDA.b #%00000000				;\Tile properties (YXPCCCTT)
								STA.l $7F837D+4+1,x				;/
								JSL FinishStripe
							.....WriteCurrentCursorPos
								LDA !Freeram_CustomL3Menu_CursorPos		;\Y position
								SEC						;|
								SBC !Freeram_CustomL3Menu_MenuScrollPos		;|>A = cursor position relative to scroll, currently
								ASL						;|
								CLC						;|
								ADC #!CustomL3Menu_MenuDisplay_YPos+1		;|
								STA $01						;/
								JSR .SetupStripeInputs
								JSL SetupStripeHeaderAndIndex
								LDA #$2E					;\Tile number
								STA.l $7F837D+4,x				;/
								LDA.b #%00101001				;\Tile properties (YXPCCCTT)
								STA.l $7F837D+4+1,x				;/
								JSL FinishStripe
							.....CursorWriteDone
						....Options
							LDA !Freeram_CustomL3Menu_WritePhase			;\Draw options (so when the menu appears, and before the player moves the cursor, the options shows up)
							BEQ .....WriteOptions					;/
							LDA $07							;\If there is no need to update the options due to a no-scroll
							AND.b #%00000010					;|don't update.
							BNE +							;|
							JMP .Done						;/
							+
							
							.....WriteOptions
								;To know what to write in the displayed options, we calculate:
								;
								; AddressOfString = (!Freeram_CustomL3Menu_MenuUptionBehavior,index * #!CustomL3Menu_MenuDisplay_OptionCharLength) + #!Freeram_CustomL3Menu_PasscodeCallBackSubroutine
								;
								LDY #$00						;>Loop counter (counts from 0 to !Freeram_CustomL3Menu_NumberOfDisplayedOptions), this is the position relative to scroll position
								LDA.b #!CustomL3Menu_MenuDisplay_YPos+1			;\$0B: Current Y position
								STA $0B							;/
								......Loop
									TYA
									CMP !Freeram_CustomL3Menu_NumberOfDisplayedOptions	;\Loop until all displays are done.
									BEQ +							;|
									BCC +
									JMP ......Done						;/
									+
									.......CheckIfBeyondLastOption ;When the menu's display is bigger than the menu, we quit drawing options beyond the last
										STY $00
										LDA !Freeram_CustomL3Menu_MenuScrollPos			;\$00-$01: Currently processed menu item in relation of the whole menu
										CLC							;|
										ADC $00							;|
										STA $00							;|
										LDA #$00						;|
										ADC #$00						;|
										STA $01							;/
										REP #$20
										LDA !Freeram_CustomL3Menu_NumberOfCursorPositions
										AND #$00FF
										CMP $00
										SEP #$20
										BCC ......Done						;>If last index < last displayed (or last displayed > last index), don't write.
									TYA
									CLC
									ADC !Freeram_CustomL3Menu_MenuScrollPos
									TAX							;>X = what option in menu currently processed
									if !sa1 == 0
										LDA !Freeram_CustomL3Menu_MenuUptionBehavior,x
										STA $4202
										LDA #!CustomL3Menu_MenuDisplay_OptionCharLength
										STA $4203
										NOP #4						;>Wait 8 cycles
										REP #$21
										LDA $4216
									else
										STZ $2250				;>Multiply mode
										LDA !Freeram_CustomL3Menu_MenuUptionBehavior,x
										STA $2251
										STZ $2252
										LDA #!CustomL3Menu_MenuDisplay_OptionCharLength
										STA $2253
										STZ $2254
										NOP					;\Wait 5 cycles
										BRA $00					;/
										REP #$21
										LDA $2306
									endif
									ADC !Freeram_CustomL3Menu_PasscodeCallBackSubroutine
									STA $08								;\$08-$0A: Address of the string data.
									SEP #$20							;|
									LDA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+2		;|
									STA $0A								;/
									.......WriteOptionString
										LDA $0B							;\Y position
										STA $01							;/
										LDA.b #!CustomL3Menu_MenuDisplay_XPos+2			;\X pos
										STA $00							;/
										LDA #$05						;\Layer
										STA $02							;/
										STZ $03							;>D and RLE
										LDA.b #!CustomL3Menu_MenuDisplay_OptionCharLength	;\Number of tiles
										STA $04							;|
										STZ $05							;/
										PHY
										JSL SetupStripeHeaderAndIndex
										LDY #$0000							;>Y had to be 16-bit since the striper had to be 16-bit X
										PHX
										........Loop
											CPY.w #!CustomL3Menu_MenuDisplay_OptionCharLength
											BCS ........CharDone
											LDA [$08],y
											STA $7F837D+4,x
											LDA.b #!CustomL3Menu_MenuDisplay_Properties
											STA $7F837D+5,x
											
											.........Next
												INX #2
												INY
												BRA ........Loop
											
										........CharDone
										PLX
										JSL FinishStripe
										PLY
									.......Next
										INC $0B				;\Each option goes 2 lines down
										INC $0B				;/
										INY
										JMP ......Loop
								......Done
						....DisplayScrollArrows
							;When the menu can be scrolled up or down, display so that the user is informed there is more options.
							LDA !Freeram_CustomL3Menu_WritePhase			;\Draw options (so when the menu appears, and before the player moves the cursor, the options shows up)
							BEQ .....CheckScrollUp					;/
							LDA $07							;\If there is no need to update the options due to a no-scroll
							AND.b #%00000010					;|don't update.
							BNE +							;|
							JMP .Done						;/
							+
							.....CheckScrollUp
								JSR .SetupStripeInputs			;>X, layer, D/RLE, and 1 tile
								LDA.b #!CustomL3Menu_MenuDisplay_YPos	;\Y position
								STA $01					;/
								JSL SetupStripeHeaderAndIndex
								LDY #$0000
								LDA !Freeram_CustomL3Menu_MenuScrollPos
								BEQ ......NoUpArrow
								......UpArrow
									INY #2
								......NoUpArrow
								REP #$20
								LDA ShouldArrowAppear,y
								STA $7F837D+4,x
								SEP #$20
								JSL FinishStripe
							.....CheckScrollDown
								JSR .SetupStripeInputs			;>X, layer, D/RLE, and 1 tile
								;Down_arrow_position = ((!Freeram_CustomL3Menu_NumberOfDisplayedOptions+1) * 2) + !CustomL3Menu_MenuDisplay_YPos
								LDA !Freeram_CustomL3Menu_NumberOfDisplayedOptions	;\Y position
								INC							;|
								ASL							;|
								CLC							;|
								ADC.b #!CustomL3Menu_MenuDisplay_YPos			;|
								STA $01							;/
								JSL SetupStripeHeaderAndIndex
								LDY #$0000
								LDA !Freeram_CustomL3Menu_MenuScrollPos			;\Last displayed option
								CLC							;|
								ADC !Freeram_CustomL3Menu_NumberOfDisplayedOptions	;/
								CMP !Freeram_CustomL3Menu_NumberOfCursorPositions	;>Last option
								BCS ......NoDownArrow					;>If last displayed is at or beyond (in case if there are fewer options than the maximum number of options shown) last option, no arrows
								......DownArrow
									INY #2
								......NoDownArrow
								REP #$20
								LDA ShouldArrowAppear,y
								ORA.w #%1000000000000000
								STA $7F837D+4,x
								SEP #$20
								JSL FinishStripe
							.....WriteOptionsDone
								LDA #$01
								STA !Freeram_CustomL3Menu_WritePhase
								JMP .Done
				..CloseMenuDeleteCursor	;>!Freeram_CustomL3Menu_WritePhase == $02
					LDA.b #!CustomL3Menu_MenuDisplay_XPos
					STA $00
					;CursorYpos = ((!Freeram_CustomL3Menu_CursorPos-!Freeram_CustomL3Menu_MenuScrollPos)*2) + !CustomL3Menu_MenuDisplay_YPos + 1
					LDA !Freeram_CustomL3Menu_CursorPos
					SEC
					SBC !Freeram_CustomL3Menu_MenuScrollPos
					ASL A
					CLC
					ADC.b #!CustomL3Menu_MenuDisplay_YPos+1
					STA $01
					JSR .SetupStripeInputs		;>X position, layer 3, horizontal without RLE, and 1 tile.
					JSL SetupStripeHeaderAndIndex
					REP #$20
					LDA #$38FC			;>Tile $FC, YXPCCCTT = $38 (%00111000), the blank tile
					STA $7F837D+4,x
					SEP #$20
					JSL FinishStripe
					LDA #$03
					STA !Freeram_CustomL3Menu_WritePhase
					JMP .Done
				..CloseMenuDeleteOptions	;>!Freeram_CustomL3Menu_WritePhase == $03
					LDA.b #!CustomL3Menu_MenuDisplay_YPos+1
					STA $06
					LDY #$00
					...Loop
						TYA
						CMP !Freeram_CustomL3Menu_NumberOfCursorPositions
						BEQ +
						BCS ...Done
						+
						PHY
						LDA.b #!CustomL3Menu_MenuDisplay_XPos+2			;\X pos
						STA $00							;/
						LDA $06							;\Y pos
						STA $01							;/
						LDA #$05						;\Layer
						STA $02							;/
						LDA.b #%01000000					;\Direction and RLE (RLE will be used)
						STA $03							;/
						LDA.b #!CustomL3Menu_MenuDisplay_OptionCharLength	;\Number of tiles
						STA $04							;|
						STZ $05							;/
						JSL SetupStripeHeaderAndIndex
						REP #$20
						LDA #$38FC			;>Tile $FC, YXPCCCTT = $38 (%00111000), the blank tile
						STA $7F837D+4,x
						SEP #$20
						JSL FinishStripe
						PLY
						....Next
							INC $06
							INC $06
							INY
							BRA ...Loop
						
					...Done
						LDA #$04
						STA !Freeram_CustomL3Menu_WritePhase
						JMP .Done
				..CloseMenuDeleteScrollArrows		;>!Freeram_CustomL3Menu_WritePhase == $04
					...UpArrow
						LDA.b #!CustomL3Menu_MenuDisplay_XPos	;\XY position
						STA $00					;|
						LDA.b #!CustomL3Menu_MenuDisplay_YPos	;|
						STA $01					;/
						LDA #$05				;\Layer 3
						STA $02					;/
						STZ $03					;>Horizontal, no RLE
						LDA #$01				;\1 tile
						STA $04					;|
						STZ $05					;/
						JSL SetupStripeHeaderAndIndex
						REP #$20
						LDA #$38FC			;>Tile $FC, YXPCCCTT = $38 (%00111000), the blank tile
						STA $7F837D+4,x
						SEP #$20
						JSL FinishStripe
					...DownArrow
						LDA.b #!CustomL3Menu_MenuDisplay_XPos			;\XY position
						STA $00							;|
						LDA !Freeram_CustomL3Menu_NumberOfDisplayedOptions	;|
						INC							;|
						ASL							;|
						CLC							;|
						ADC.b #!CustomL3Menu_MenuDisplay_YPos			;|
						STA $01							;/
						LDA #$05						;\Layer 3
						STA $02							;/
						STZ $03							;>Horizontal, no RLE
						LDA #$01						;\1 tile
						STA $04							;|
						STZ $05							;/
						JSL SetupStripeHeaderAndIndex
						REP #$20
						LDA #$38FC			;>Tile $FC, YXPCCCTT = $38 (%00111000), the blank tile
						STA $7F837D+4,x
						SEP #$20
						JSL FinishStripe
					..ExitMenuMode
						LDA #$01				;\Go back to normal
						STA !Freeram_CustomL3Menu_UIState	;/
						JMP .Done
			.Done
			PLB					;>Restore bank
			RTL
			.SetupStripeInputs
				LDA.b #!CustomL3Menu_MenuDisplay_XPos		;\X position
				STA $00						;/
				LDA #$05					;\Layer 3
				STA $02						;/
				STZ $03						;>Direction and RLE
				LDA #$01					;\Number of tiles
				STA $04						;|
				STZ $05						;/
				RTS
	;--------------------------------------------------------------------------------
	;Number input (passcode)
	;--------------------------------------------------------------------------------
		NumberInput:
			PHB					;>Preserve bank
			PHK					;\Change bank so that $xxxx,y works correctly
			PLB					;/
			;NMI overflow prevention. Works like this:
			;There are 3 phases of how this stripe writer writes
			;Phase 1 (!Freeram_CustomL3Menu_WritePhase = #$00): Only write the digits, set the phase to #$01 and terminate the code.
			;Phase 2 (phase = #$01): Only write the cursor, set the phase to #$02, and terminate the code.
			;Phase 3 (phase = #$02): Allow the player to make inputs to the cursor and adjust the number, and also update the tiles when they're changed.
			;Phase 4 (phase = #$03): Clears out the tiles when the player exits out of the passcode UI.
			;
			;Phase 1 & 2 also ignores player input since when the player input data, it updates the tiles, but we already did it here.
			LDA !Freeram_CustomL3Menu_WritePhase
			ASL
			TAX
			JMP.w (.NumberInputPhases,x)
			
			.NumberInputPhases
				dw ..WriteDigits			;>!Freeram_CustomL3Menu_WritePhase = $00 (X = $00)
				dw ..WriteCursor			;>!Freeram_CustomL3Menu_WritePhase = $01 (X = $02)
				dw ..RespondToUserInput			;>!Freeram_CustomL3Menu_WritePhase = $02 (X = $04)
				dw ..ExitingNumberUIPhase		;>!Freeram_CustomL3Menu_WritePhase = $03 (X = $06)
				dw ..ExitingNumberUIPhase		;>!Freeram_CustomL3Menu_WritePhase = $04 (X = $08)
				dw .Done				;>!Freeram_CustomL3Menu_WritePhase = $05 (X = $0A)
				
				..WriteDigits
					JSR WriteDigits
					LDA #$01
					STA !Freeram_CustomL3Menu_WritePhase
					JMP .Done
				..WriteCursor
					JSR WriteCursor
					LDA #$02
					STA !Freeram_CustomL3Menu_WritePhase
					JMP .Done
				..ExitingNumberUIPhase
					LDA.b #!CustomL3Menu_NumberInput_XPos		;\X pos
					STA $00						;/
					TXA						;\Y pos
					LSR						;|If phase index 3-4, they become 0-1 for table indexing.
					SEC						;|for the Y position
					SBC #$03					;|
					TAX						;|
					LDA ...YPositionToClearDigitsThenCursor,x	;|
					STA $01						;/
					LDA #$05					;\Layer
					STA $02						;/
					LDA.b #%01000000				;\Direction and RLE
					STA $03						;/
					LDA !Freeram_CustomL3Menu_NumberOfCursorPositions	;\Number of cursor positions = number of digits the user can adjust
					INC							;|
					STA $04							;|
					STZ $05							;/
					JSL SetupStripeHeaderAndIndex			;>X (16-bit) = Length of stripe data
					REP #$30
					LDA #$38FC				;\Blank tile
					STA.l $7F837D+4,x			;/
					SEP #$30
					JSL FinishStripe
					LDA !Freeram_CustomL3Menu_WritePhase	;\Next phase
					INC					;|
					STA !Freeram_CustomL3Menu_WritePhase	;/
					CMP #$05				;\If cleared both the digits and cursor,
					BCC +					;/then reset the entire menu
					LDA #$01				;\Reset entire menu (except the passcode string)
					STA !Freeram_CustomL3Menu_UIState	;/
					+
					JMP .Done
					...YPositionToClearDigitsThenCursor
						db !CustomL3Menu_NumberInput_YPos
						db !CustomL3Menu_NumberInput_YPos+1

				..RespondToUserInput
					LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToConfirm
					AND.b #!CustomL3Menu_ButtonConfirm
					BNE ..ConfirmOrCancel
					LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToConfirm2
					AND.b #!CustomL3Menu_ButtonConfirm2
					BNE ..ConfirmOrCancel
					LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToCancel
					AND.b #!CustomL3Menu_ButtonCancel
					BNE ..ConfirmOrCancel
					LDX #$01				;\Moving cursor left and right switches which digit the player wants to adjust
					JSL DPadMoveCursorOnMenu		;/
					BCC ...AdjustNumber			;>Don't display cursor during mid-moving (during default placement of the cursor graphic)
					JSR WriteCursor
					...AdjustNumber
					LDA !Freeram_CustomL3Menu_CursorPos	;\Depending on your cursor positiuon adjust what number to increase/decrease
					TAX					;/
					;LDA !Freeram_ControlBackup+1				;\Controller: byetUDLR -> 00byetUD -> 000000UD into the Y index
					;LSR #2							;|to determine to increment or decrement it
					;AND.b #%00000011					;|
					LDA !Freeram_CustomL3Menu_DpadPulser			;|>udlrUDLR -> 000000ud
					LSR #6
					TAY							;/
					LDA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;\Take current digit and increment and decrement
					CLC							;|
					ADC IncrementDecrementNumberUI,y			;/
					CMP #$FF						;\If digit increment/decrement outside the 0-9 range, wrap it.
					BEQ ...WrapTo9						;|
					CMP #$0A						;|
					BCS ...WrapTo0						;|
					BRA ...In0To9Range					;/
					...WrapTo9
						LDA #$09
						BRA ...In0To9Range
					...WrapTo0
						LDA #$00
					...In0To9Range
					STA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;>Adjust digit.
					LDA IncrementDecrementNumberUI,y			;\No increment, no sound (if both up and down are set or clear)
					BEQ ...NoChange						;/
					...Change
						LDA #!CustomL3Menu_SoundEffectNumber_NumberAdjust
						STA !CustomL3Menu_SoundEffectPort_NumberAdjust
						JSR WriteDigits
					...NoChange
						BRA .Done
				..ConfirmOrCancel
					LDA #$03								;\Clear menu on next frame.
					STA !Freeram_CustomL3Menu_WritePhase					;/
					LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToConfirm
					AND.b #!CustomL3Menu_ButtonConfirm
					BNE ...Confirm
					LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToConfirm2
					AND.b #!CustomL3Menu_ButtonConfirm2
					BNE ...Confirm
					LDA !Freeram_ControlBackup+1+!CustomL3Menu_WhichControllerDataToCancel
					AND.b #!CustomL3Menu_ButtonCancel
					BNE ...Cancel
					
					...Confirm
						;LDA #!CustomL3Menu_SoundEffectNumber_Confirm
						;STA !CustomL3Menu_SoundEffectPort_Confirm
						;JSR CheckPasscodeCorrect
						STZ $00
						BRA ...SetConfirmFlag
					...Cancel
						LDA #!CustomL3Menu_SoundEffectNumber_Cancel
						STA !CustomL3Menu_SoundEffectPort_Cancel
						LDA #$01
						STA $00
					...SetConfirmFlag
						LDA #$5C						;\Setup a JML to a subroutine supplied from elsewhere such as a block door.
						STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine	;/
						JSL !Freeram_CustomL3Menu_PasscodeCallBackSubroutine	;>And now JSL to there, which as expected, JMLs to a supplied code. Once RTL, should go to the instruction below here.
						BRA .Done
			.Done
				PLB			;>Restore bank
				RTL
			
		IncrementDecrementNumberUI:
			db $00		;>%00000000 (none pressed)
			db $FF		;>%00000100 (down pressed)
			db $01		;>%00001000 (up pressed)
			db $00		;>%00001100 (both pressed)
			
		WriteCursor:
			.DisplayCursor
				LDA.b #!CustomL3Menu_NumberInput_XPos	;\XY pos
				STA $00					;|
				LDA.b #!CustomL3Menu_NumberInput_YPos+1	;|
				STA $01					;/
				LDA #$05				;\Layer
				STA $02					;/
				STZ $03					;>Direction and RLE
				LDA !Freeram_CustomL3Menu_NumberOfCursorPositions	;\Number of cursor positions or digits
				INC							;|
				STA $04							;|
				STZ $05							;/
				JSL SetupStripeHeaderAndIndex		;>X (16-bit) = Length of stripe data
				LDA #$7F				;\$00-$02: A RAM address to safely write stripe image
				STA $02					;|
				REP #$21				;|
				TXA					;|
				ADC.w #$7F837D+4			;|
				STA $00					;/
				..ClearOutCursorSpaces
					PHX				;>Preserve stripe length
					LDX #$0000
					..Loop
						...WriteTile
							STX $06					;>$06-$07: Current position processed
							LDA !Freeram_CustomL3Menu_CursorPos	;\If looping index and cursor position match, display a cursor tile.
							AND #$00FF				;|
							CMP $06					;|
							BNE ....Blank				;/
							....Cursor ;The tile written when the cursor is on that spot
								LDA #$B827
								BRA ....Write
							....Blank ;The tile written when the cursor isn't present on this spot
								LDA #$38FC			;>[TileNumber], [Properties] -> $[Properties][TileNumber]
							....Write
								STA [$00]
						...Next
							LDA $00			;\Next tile in stripe
							CLC			;|
							ADC #$0002		;|
							STA $00			;/
							INX			;\Loop until all tiles written
							CPX $04			;|
							BCC ..Loop		;/
					PLX			;>Restore stripe length
					SEP #$20		;\Finish stripe
					JSL FinishStripe	;/
				RTS
		WriteDigits:
			.DisplayDigits
				LDA.b #!CustomL3Menu_NumberInput_XPos	;\XY pos
				STA $00					;|
				LDA.b #!CustomL3Menu_NumberInput_YPos	;|
				STA $01					;/
				LDA #$05				;\Layer
				STA $02					;/
				STZ $03					;>Direction and RLE
				LDA !Freeram_CustomL3Menu_NumberOfCursorPositions	;\Number of cursor positions = number of digits the user can adjust
				INC							;|
				STA $04							;|
				STA $06							;|
				STZ $05							;|
				STZ $07							;/
				JSL SetupStripeHeaderAndIndex		;>X (16-bit): Stripe length
				
				LDA #$7F				;\$00-$02 Tile numbers address (assuming this increments by 2)
				STA $02					;|$03-$05 Tile properties address (assuming this increments by 2)
				STA $05					;|
				REP #$21				;|
				TXA					;|
				ADC.w #$7F837D+4			;|
				STA $00					;|
				TXA					;|
				CLC					;|
				ADC.w #$7F837D+4+1			;|
				STA $03					;|
				SEP #$20				;/
				PHX					;>Preserve number of bytes (stripe length)
				LDX #$0000
				..Loop
					...Write
						LDA !Freeram_CustomL3Menu_DigitPasscodeUserInput,x	;>Tile number (digits)
						STA [$00]					
						LDA.b #%00111000				;>Properties (for all 0-9 digits)
						STA [$03]					
					...Next
						REP #$21	;\Next tile
						LDA $00		;|
						ADC #$0002	;|
						STA $00		;|
						LDA $03		;|
						CLC		;|
						ADC #$0002	;|
						STA $03		;|
						SEP #$20	;/
						INX		;\Loop until all tiles written
						CPX $06		;|
						BEQ ..Loop	;|
						BCC ..Loop	;/
				PLX				;>Restore number of bytes (stripe length)
				STZ $03				;>RLE
				REP #$20
				LDA !Freeram_CustomL3Menu_NumberOfCursorPositions	;\Number of tiles
				AND #$00FF						;|
				INC							;|
				STA $04							;/
				SEP #$20
				JSL FinishStripe
				SEP #$30
				RTS
	;--------------------------------------------------------------------------------
	;Value adjust menu
	;--------------------------------------------------------------------------------
		ValueAdjustMenu:
			RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Cursor move handler
;Handles D-pad to move the cursor. Designed only for "linear" menus that
;moves in 2 directions that moves the cursor (not suitable for 2D-like menu.)
;
;Input:
; X:
;  -$00 = vertical (up and down moves the cursor vertically). "Down"
;   increases, "up" decreases.
;  -$01 = horizontal (left and right moves the cursor horizontally). "Right"
;   increases, "Left" decreases.
;Output:
; Carry: 0 = No change, 1 = change. Needed so we can only update what's change
;  on the stripe image.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DPadMoveCursorOnMenu:
	LDA !Freeram_CustomL3Menu_DpadPulser
	LSR #4						;>Use only pulsing D-pad bits
	AND DPadMoveCursorOnMenuWhichOrientation,x	;>Mask all bits except the 2 directions
	CMP DPadMoveCursorOnMenuUpOrLeft,x
	BEQ .Decrease
	CMP DPadMoveCursorOnMenuDownOrRight,x
	BEQ .Increase
	BRA .NoChange		;>If both opposite directions pressed in 1 frame, or none pressed at all, no moving cursor
	
	.Decrease
		LDA !Freeram_CustomL3Menu_CursorPos	;\If cursor goes beyond the first item (0 - 1 = -1 but we take the before-moved position to free up $FF as a menu choice should in a rare chance you need this)
		BEQ ..WrapToBottom			;/jump to the last item.
		..NoWrapToBottom
			DEC
			BRA ..SetPos
		..WrapToBottom
			LDA !Freeram_CustomL3Menu_NumberOfCursorPositions
		..SetPos
			STA !Freeram_CustomL3Menu_CursorPos
		BRA .SFX
	.Increase
		LDA !Freeram_CustomL3Menu_CursorPos
		INC
		CMP !Freeram_CustomL3Menu_NumberOfCursorPositions	;\If cursor goes beyond the last item, position the cursor to the first item.
		BEQ .NotExceed						;|
		BCC .NotExceed						;/
		
		.Exceed
			LDA #$00
		.NotExceed
		STA !Freeram_CustomL3Menu_CursorPos
	.SFX
		LDA #!CustomL3Menu_SoundEffectNumber_CursorMove
		STA !CustomL3Menu_SoundEffectPort_CursorMove
	.SetCarry
		SEC
		RTL
	.NoChange
		CLC
	.Done
		RTL
DPadMoveCursorOnMenuWhichOrientation:
	db %00001100			;>Vertical
	db %00000011			;>Horizontal
DPadMoveCursorOnMenuUpOrLeft:
	db %00001000			;>Vertical
	db %00000010			;>Horizontal
DPadMoveCursorOnMenuDownOrRight:
	db %00000100			;>Vertical
	db %00000001			;>Horizontal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Cursor move handler, 2D movement
;Handles D-pad to move the cursor in 2D movement. Like text, the caret
;also wraps to the next line when the end of the line has been exceeded.
;
;Input:
; $00 (1 byte): How many columns the menu spans.
; !Freeram_CustomL3Menu_NumberOfCursorPositions (1 byte): Used so that
;  the cursor can only be at valid positions. As this value increases
;  positions will be added to the "right" and if a row is finished,
;  will "line wrap".
;Output:
; Carry: 0 = No change, 1 = change. Needed so we can only update what's change
;  on the stripe image.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DPadMoveCursorOnMenu2D:
	LDA !Freeram_CustomL3Menu_DpadPulser
	AND.b #%11110000
	BEQ .NoMovement
	.Horizontal
		AND.b #%00110000		;\Used CMP just in case user presses opposite directions at the same time.
		CMP.b #%00100000		;|
		BEQ ..Decrement1		;|
		CMP.b #%00010000		;|
		BEQ ..Increment1		;/
		BRA .Vertical
		
		..Decrement1
			LDA !Freeram_CustomL3Menu_CursorPos
			BEQ ...Wrap
			DEC A
			BRA ...Write
			
			...Wrap
				LDA !Freeram_CustomL3Menu_NumberOfCursorPositions
			...Write
				STA !Freeram_CustomL3Menu_CursorPos
		BRA .Vertical
		..Increment1
			LDA !Freeram_CustomL3Menu_CursorPos
			INC
			CMP !Freeram_CustomL3Menu_NumberOfCursorPositions
			BEQ ...Write
			BCC ...Write
			
			...Exceed
				LDA #$00
			...Write
				STA !Freeram_CustomL3Menu_CursorPos
	.Vertical
		LDA !Freeram_CustomL3Menu_DpadPulser
		AND.b #%11000000			;\Again, using CMP and "somewhat unoptimized" code because
		CMP.b #%10000000			;|the user could enter a D-pad pressing opposite directions.
		BEQ ..DecrementByRAM			;|
		CMP.b #%01000000			;|
		BEQ ..IncrementByRAM			;/
		BRA .Done
		
		..DecrementByRAM
			LDA !Freeram_CustomL3Menu_CursorPos
			SEC
			SBC $00
			BCS ...Write
			...Wrap
				LDA !Freeram_CustomL3Menu_NumberOfCursorPositions
			...Write
				STA !Freeram_CustomL3Menu_CursorPos
		..IncrementByRAM
			LDA !Freeram_CustomL3Menu_CursorPos
			CLC
			ADC $00
			CMP !Freeram_CustomL3Menu_NumberOfCursorPositions
			BEQ ...Write
			BCC ...Write
			...Wrap
				LDA #$00
			...Write
				STA !Freeram_CustomL3Menu_CursorPos
	.Done
		SEC
		RTL
	.NoMovement
		CLC
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Easy stripe setup-er. Gets index of stripe table and sets up the header.
;Input:
;-$00: X position (%00XXXXXX, only bits 0-5 used, ranges from 0-63 ($00-$3F))
;-$01: Y position (%00YYYYYY, only bits 0-5 used, ranges from 0-63 ($00-$3F))
;-$02: What layer:
;       $02 = Layer 1
;       $03 = Layer 2
;       $05 = Layer 3
;-$03: Direction and RLE: %DR00000000
;       D = Direction: 0 = horizontal (rightwards), 1 = vertical (downwards)
;       R = RLE: 0 = no repeat, 1 = repeat
;-$04 to $05 (16-bit): Number of tiles.
;Output:
;-X register (16-bit, XY registers are 16-bit): The index position to write stripe data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;note to self
; $7F837D+0,x = EHHHYXyy
; $7F837D+1,x = yyyxxxxx
; $7F837D+2,x = DRllllll
; $7F837D+3,x = LLLLLLLL
SetupStripeHeaderAndIndex:
	.GetWhereToSafelyWriteStripe
		REP #$30		;>16-bit AXY
		LDA $7F837B		;\LDX $XXXXXX does not exist so we need LDA $XXXXXX : TAX to
		TAX			;/get RAM values stored in bank $7F into X register.
	.StartWithBlankHeaderInitally
		LDA #$0000		;\Clear everything out first
		STA $7F837D+0,x		;|
		STA $7F837D+2,x		;/
		SEP #$20
	.Xposition
		LDA $00			;\X bit 0-4
		AND.b #%00011111	;|
		ORA $7F837D+1,x		;|
		STA $7F837D+1,x		;/
		LDA $00			;\X bit 5
		AND.b #%00100000	;|
		LSR #3			;|
		ORA $7F837D+0,x		;|
		STA $7F837D+0,x		;/
	.Yposition
		LDA $01			;\Y bit 0-2
		AND.b #%00000111	;|
		ASL #5			;|
		ORA $7F837D+1,x		;|
		STA $7F837D+1,x		;/
		LDA $01			;\Y bit 3-4
		AND.b #%00011000	;|
		LSR #3			;|
		ORA $7F837D+0,x		;|
		STA $7F837D+0,x		;/
		LDA $01			;\Y bit 5
		AND.b #%00100000	;|
		LSR #2			;|
		ORA $7F837D+0,x		;|
		STA $7F837D+0,x		;/
	.WhatLayer
		LDA $02
		AND.b #%00000111
		ASL #4
		ORA $7F837D+0,x
		STA $7F837D+0,x
	.Direction
		LDA $03
		AND.b #%11000000	;>Failsafe
		ORA $7F837D+2,x
		STA $7F837D+2,x
	.Length
		AND.b #%01000000
		BEQ ..NoRLE
		
		..RLE
			REP #$20
			LDA $04			;\NumberOfBytes = (NumberOfTiles-1)*2
			DEC A			;|
			ASL			;|
			SEP #$20		;/
			BRA ..Write
		..NoRLE
			REP #$20
			LDA $04			;\NumberOfBytes = (NumberOfTiles*2)-1
			ASL			;|
			DEC			;|
			SEP #$20		;/
		..Write
			STA $7F837D+3,x		;\Write
			XBA			;|
			AND.b #%00111111	;|
			ORA $7F837D+2,x		;|
			STA $7F837D+2,x		;/
	.Done
		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Finish stripe write
;
;This writes the terminating byte $FF and updates the length of stripe.
;
;Input:
;-$03: Direction and RLE: %DR00000000. This routine only checks the RLE
;      due to the length formula varies depending if using RLE or not.
;-$04 to $05: Number of tiles
;-X register (16-bit): Index length of stripe table
;Output:
;-$7F837B to $7F837C: New length of stripe
;Destroyed:
;-$00 to $02: Address of where to write the terminating byte based
;             on the indexing and number of tiles.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FinishStripe:
	.UpdateLength
		LDA $03
		AND.b #%01000000
		BEQ ..NoRLE
		
		..RLE
			REP #$21			;REP #$21 is 8-bit A with carry cleared
			TXA				;\Update length of stripe. 6 because 2 bytes of 1 tile plus 4 bytes of header)
			ADC #$0006			;|
			STA $7F837B			;/
			SEP #$30			;>8-bit AXY
			...WhereToWriteTerminateByte
				LDA #$FF
				STA $7F837D+6,x
			RTL
		..NoRLE
			REP #$21			;REP #$21 is 8-bit A with carry cleared
			LDA $04				;\4+(NumberOfTiles*2)...
			ASL				;|
			CLC				;|
			ADC #$0004			;/
			CLC				;\plus the current length
			ADC $7F837B			;/
			STA $7F837B			;>And that is our new length
			SEP #$30			;>8-bit AXY
			...WhereToWriteTerminateByte
				LDA #$7F		;\Bank byte
				STA $02			;/
				REP #$20		;\4+(NumberOfTiles*2)...
				LDA $04			;|
				ASL			;|
				CLC			;|>Just in case
				ADC.w #$837D+4		;|
				STA $00			;/
				TXA			;\Plus index ($7F837D+(NumberOfBytesSinceHeader),x is equivilant to $7F837D + NumberOfBytesSinceHeader + X_index)
				CLC			;|
				ADC $00			;|
				STA $00			;/
				SEP #$20
				LDA #$FF		;\Write terminate byte here.
				STA [$00]		;/
			RTL