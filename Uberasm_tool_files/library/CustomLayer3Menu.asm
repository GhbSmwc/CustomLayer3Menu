;This main code should be run using "JSL CustomLayer3Menu_ProcessLayer3Menu" from gamemode 14.

;NOTE: To prevent potential NMI overflows (flickering black bars at the top of the
;screen), Tiles are written only when an "update" occurs, not every frame (such as
;moving the cursor, changing the settings in a options menu).

	incsrc "../CustomLayer3Menu_Defines/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Process layer 3 menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ProcessLayer3Menu:
	LDA !Freeram_CustomL3Menu_UIState
	BNE +
	RTL
	+
	;CMP #$XX		;\If you want some menus to not freeze time,
	;BEQ .SkipFreeze	;/uncomment the code here.
	LDX #$0B
	STX $71
	STX $9D
	
	.SkipFreeze
	
	.MenuTypeHandler
		TAX
		LDA Layer3MenuBehavior,x
		STA $00			;>$00 = Index of what menu type of the current menu being on.
		ASL
		TAX
		BCS +
		JMP.w (MenuStates-2,x)
		+
		JMP.w (MenuStates-2+128,x)
	
	MenuStates:
		dw MenuSelection
		dw NumberInput
		dw ValueAdjustMenu
	;--------------------------------------------------------------------------------
	;These are codes that handle the behavior of each menu types
	;$00 contains the index of what menu type of the current menu.
	;--------------------------------------------------------------------------------
	;--------------------------------------------------------------------------------
	;This one is a standard menu
	;--------------------------------------------------------------------------------
		MenuSelection:
			LDX #$00
			JSL DPadMoveCursorOnMenu
			RTL
	;--------------------------------------------------------------------------------
	;Number input
	;--------------------------------------------------------------------------------
		NumberInput:
			PHB					;>Preserve bank
			PHK					;\Change bank so that $xxxx,y works correctly
			PLB					;/
			
			LDA !Freeram_CustomL3Menu_WritePhase	;\NMI overflow prevention. Works like this:
			BNE +					;|There are 3 phases of how this stripe writer writes
			JSR WriteDigits				;|Phase 1 (!Freeram_CustomL3Menu_WritePhase = #$00): Only write the digits, set the phase to #$01 and terminate the code.
			LDA #$01				;|Phase 2 (phase = #$01): Only write the cursor, set the phase to #$02, and terminate the code.
			STA !Freeram_CustomL3Menu_WritePhase	;|Phase 3 (phase = #$02): Allow the player to make inputs to the cursor and adjust the number, and also update the tiles when they're changed.
			BRA .Done				;|
			+					;|Phase 1 & 2 also ignores player input since when the player input data, it updates the tiles, but we already did it here.
			CMP #$02				;|
			BCS .WritePhaseDone			;|
			JSR WriteCursor				;|
			LDA #$02				;|
			STA !Freeram_CustomL3Menu_WritePhase	;|
			BRA .Done				;/
			
			.WritePhaseDone
			LDX #$01				;\Moving cursor left and right switches which digit the player wants to adjust
			JSL DPadMoveCursorOnMenu		;/
			BCC .AdjustNumber
			JSR WriteCursor
			.AdjustNumber
				LDA !Freeram_CustomL3Menu_CursorPos	;\Depending on your cursor positiuon adjust what number to increase/decrease
				TAX					;/
				LDA !Freeram_ControlBackup+1				;\Controller: byetUDLR -> 00byetUD -> 000000UD into the Y index
				LSR #2							;|to determine to increment or decrement it
				AND.b #%00000011					;|
				TAY							;/
				LDA !Freeram_CustomL3Menu_PasswordStringTable,x		;\Take current digit and increment and decrement
				CLC							;|
				ADC IncrementDecrementNumberUI,y			;/
				CMP #$FF						;\If digit increment/decrement outside the 0-9 range, wrap it.
				BEQ .WrapTo9						;|
				CMP #$0A						;|
				BCS .WrapTo0						;|
				BRA .In0To9Range					;/
				.WrapTo9
					LDA #$09
					BRA .In0To9Range
				.WrapTo0
					LDA #$00
				.In0To9Range
				STA !Freeram_CustomL3Menu_PasswordStringTable,x		;>Adjust digit.
			
			LDA IncrementDecrementNumberUI,y			;\No increment, no sound (if both up and down are set or clear)
			BEQ .NoChange						;/
			
			.Change
				LDA #!CustomL3Menu_SoundEffectNumber_NumberAdjust
				STA !CustomL3Menu_SoundEffectPort_NumberAdjust
				JSR WriteDigits
			.NoChange
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
				LDA !Freeram_CustomL3Menu_UIState	;\Number of cursor positions = number of digits the user can adjust
				TAX					;|
				LDA Layer3MenuNumberOfCursorPos-1,x	;|
				INC					;|
				STA $04					;|
				STZ $05					;/
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
							CPX #$0004		;|
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
				LDA !Freeram_CustomL3Menu_UIState	;\Number of cursor positions = number of digits the user can adjust
				TAX					;|$04-$05 and $06-$07: number of tiles/cursor positions/number of digits
				LDA Layer3MenuNumberOfCursorPos-1,x	;|
				INC					;|
				STA $04					;|
				STA $06					;|
				STZ $05					;|
				STZ $07					;/
				JSL SetupStripeHeaderAndIndex		;>X (16-bit): Stripe length
				
				LDA #$7F				;\$00-$02 Tile numbers (assuming this increments by 2)
				STA $02					;|$03-$05 Tile properties (assuming this increments by 2)
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
				PHX					;>Preserve number of tiles
				LDX #$0000
				..Loop
					...Write
						LDA !Freeram_CustomL3Menu_PasswordStringTable,x	;>Tile number (digits)
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
						BCC ..Loop	;/
				PLX				;>Restore number of tiles
				STZ $03				;>RLE
				REP #$20
				LDA $06				;\Number of tiles
				STA $04				;/
				SEP #$20
				JSL FinishStripe
				SEP #$30
				RTS
	;--------------------------------------------------------------------------------
	;Value adjust menu
	;--------------------------------------------------------------------------------
		ValueAdjustMenu:
			RTL
	;--------------------------------------------------------------------------------
	;Each value here is each type from !Freeram_CustomL3Menu_UIState,
	;excluding state $00 (so the first item is index 1). This defines the behavior
	;of each value of !Freeram_CustomL3Menu_UIState.
	; $00 = Menu selection mode (move cursor up and down, and press "confirm"
	;       to select)
	; $01 = number input
	; $02 = Value adjust menu. Up/Down moves the cursor, Left/Right adjust the
	;       value associated with it like a settings menu.
	;--------------------------------------------------------------------------------
		Layer3MenuBehavior:
			db $00		;>Index 0
			db $01		;>Index 1
			db $02		;>Index 2
	;--------------------------------------------------------------------------------
	;Number of positions a cursor can be at, -1.
	;Each number here is each value for !Freeram_CustomL3Menu_UIState excluding state $00.
	;
	;This is needed to prevent the cursor from going beyond the last
	;option and makes it wrap to the first or last item should the cursor
	;position be at -1 or NumberOfOOptions (the cursor is allowed to be at positions
	;0 to NumberOfOOptions-1).
	;--------------------------------------------------------------------------------
		Layer3MenuNumberOfCursorPos:
			db 4-1		;>State 1
			db 4-1		;>State 2
			db 10-1		;>State 3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Cursor move handler
;Handles D-pad to move the cursor. Not suitable for 2D-like menu.
;
;Input:
; X:
;  -$00 = vertical (up and down moves the cursor vertically)
;  -$01 = horizontal (left and right moves the cursor horizontally)
;Output:
; Carry: 0 = No change, 1 = change. Needed so we can only update what's change
;  on the stripe image.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DPadMoveCursorOnMenu:
	LDA !Freeram_ControlBackup+1
	AND DPadMoveCursorOnMenuWhichOrientation,x	;>Mask all bits except the 2 directions
	CMP DPadMoveCursorOnMenuUpOrLeft,x
	BEQ .Decrease
	CMP DPadMoveCursorOnMenuDownOrRight,x
	BEQ .Increase
	BRA .NoChange		;>If both opposite directions pressed in 1 frame, or none pressed at all, no moving cursor
	
	.Decrease
		LDA !Freeram_CustomL3Menu_CursorPos
		DEC
		CMP #$FF
		BNE .NoWrapToBottom
		.WrapToBottom
			LDA !Freeram_CustomL3Menu_UIState
			TAX
			LDA Layer3MenuNumberOfCursorPos-1,x
		.NoWrapToBottom
		STA !Freeram_CustomL3Menu_CursorPos
		BRA .SFX
	.Increase
		LDA !Freeram_CustomL3Menu_UIState	;\Get final position of cursor to compare with so that if beyond the last
		TAX					;|item, loop back to item 0.
		LDA Layer3MenuNumberOfCursorPos-1,x	;|
		STA $01					;/
		
		LDA !Freeram_CustomL3Menu_CursorPos
		INC
		CMP $01
		BEQ .NotExceed
		BCC .NotExceed
		
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