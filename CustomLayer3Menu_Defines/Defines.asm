;NOTE: By using default RAMs here, you are required to use patches that frees up RAM
;as some of the freeram are table-based and could potentially take up a ton of bytes.
;-Free up RAM $7F:8000: https://www.smwcentral.net/?p=section&a=details&id=24054
;-Free $7F0000 (OW Event Restore): https://www.smwcentral.net/?p=section&a=details&id=19580
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA1 detector:
;Do not change anything here unless you know what are you doing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if defined("sa1") == 0
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
endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Checks the current LM version, if it is bigger or equal to <version> it will set <define> to 1, other 0
; Also sets !lm_version to the last used version number. e.g. 1.52 would return 152 (dec)
;
;Don't touch unless you know what you're doing. This is needed for the specific-screen teleport menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if defined("EXLEVEL") == 0
	macro assert_lm_version(version, define)
		!lm_version #= ((read1($0FF0B4)-'0')*100)+((read1($0FF0B6)-'0')*10)+(read1($0FF0B7)-'0')
		if !lm_version >= <version>
			!<define> = 1
		else
			!<define> = 0
		endif
	endmacro
	
	%assert_lm_version(257, "EXLEVEL") ; Ex level support
endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Freeram
;
;NOTE: Some of SMW's RAM are not cleared and may be arbitrary values when specifying what RAM to use, which may cause glitches.
;To avoid potential problems, I suggest using this code for uberasm tool code:
;	
;	incsrc "../CustomLayer3Menu_Defines/Defines.asm"
;	init: ;>Level init
;		LDA #$00
;		STA !Freeram_CustomL3Menu_UIState
;		STA !Freeram_CustomL3Menu_WritePhase
;		STA !Freeram_CustomL3Menu_CursorPos
;		LDX.b #(!LongestPasswordLengthInEntireGame)-1	;>!LongestPasswordLengthInEntireGame is the highest number of characters of your entire game
;		STA !Freeram_CustomL3Menu_DigitPasscodeUserInput
;		BPL -
;		STA !Freeram_CustomL3Menu_ConfirmState
;		RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 !Freeram_CustomL3Menu_UIState = $58
  ;^[1 byte], menu state, used to display what menu/passcode mode. If value stored here is 0, then do nothing, if any nonzero value
  ; then it enters menu mode.

 !Freeram_CustomL3Menu_WritePhase = $5C
  ;^[1 byte], menu phase, use for:
  ; -To avoid necessarily writing tiles every frame, which can cause flickering black bars due to NMI overflows.
  ; -When writing large number of lines, this is used to write each line per frame, also lowering the risk of NMI overflows.
  ; -Determine should the tiles be written when the menu appears and when the tiles be cleared (set to tile $FC) when the menu
  ;  should disappear.
  ; When opening or switching to different menus, this value should be set to #$00 on the frame the menu appears/changes.

 !Freeram_CustomL3Menu_CursorPos = $60
  ;^[1 byte] Contains the position of the cursor.
  ; Notes:
  ;
  ; -This is "zero-based". Meaning the first option is position $00 and the last position is a value stored in
  ;  !Freeram_CustomL3Menu_NumberOfCursorPositions.
  ;
  ; -For 1D movement (a "normal" menu), left and up decrements this value while right/down increments this value.
  ;
  ; -for 2D movement, left and right adjusts this value -1/+1 while vertical movement will -NumbOfCols/+NumbOfCols where NumbOfCols
  ;  is the number of columns, or how many selections per row.
 !Freeram_CustomL3Menu_StringInput_CaretPos = $61
  ;^[1 byte] The position where to place the string when in StringInput mode (0-based).
  
 !Freeram_CustomL3Menu_NumberOfCursorPositions = $62
  ;^[1 byte] The number of valid cursor positions (or number of options) or digits in the passcode, -1 (a menu with 3 options means
  ; This data have a value of #$02).
  ; Used for:
  ;
  ; -To prevent the cursor from going past the last item.
  ;
  ; -To make the cursor jump to the last item when the user moves the cursor past the first item.
  ;
  ; -For passcode digit mode, this is the number of digits to use (a 4-digit passcode means this have the value of #$03).
  ;
  ; For string input, this is the maximum number of characters the user can enter, -1.

 !Freeram_CustomL3Menu_DigitPasscodeUserInput = $06F9|!addr
  ;^[!CustomL3Menu_MaxNumberOfDigitsInEntireGame] bytes. Contains the string of characters entered by the user.
  ; This is used by the number passcode UI. Make sure this is all initialized to 0.
  ;
  ; This is also the character table for !StringInput

 !Freeram_CustomL3Menu_DigitCorrectPasscode = $0F5E|!addr
  ;^[!CustomL3Menu_MaxNumberOfDigitsInEntireGame] bytes. Contains the string of characters that is the correct passcode
  ; that a code compares it to determine if correct or not.
  ;
  ; This is also the character table for !StringInput for the correct passcode.

 !Freeram_CustomL3Menu_PasscodeCallBackSubroutine = $0DC3|!addr
  ;^[4 bytes], this 4-byte of contiguous data:
  ;
  ;-During a passcode UI, it contains a JML instruction (4 bytes) to execute when the user confirms or cancel) a code supplied
  ; from elsewhere, such as a a custom block door. The bytes in this RAM
  ; should be:
  ;  !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+0: 5C ;>This is automatically set to $5C, which is the JML instruction byte.
  ;  !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1: aa ;\These are made-up example of a 24-bit address. If this is not
  ;  !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+2: bb ;|set up correctly, your game will crash or glitch out. Remember
  ;  !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3: cc ;/little endian!
  ;
  ;  This is called from "Uberasm_tool_files/library/CustomLayer3Menu.asm" ("JSL !Freeram_CustomL3Menu_PasscodeCallBackSubroutine")
  ;  The input data given is RAM $00 (1 byte) which determines:
  ;   #$00 = Confirmed
  ;   #$01 = Cancel
  ;  where the $ccbbaa is an address (in little endian) to jump to the supplied code. For example, in a custom block code you
  ;  would do this to setup an address that executes during process of the UI system:
  ;   REP #$20
  ;   LDA.w #SuppliedCode					;\[aa bb] -> $xxbbaa (remember, little endian)
  ;   STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1	;/
  ;   SEP #$20
  ;   LDA.b #SuppliedCode>>16					;\[cc] -> $ccbbaa
  ;   STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3	;/
  ;   RTL
  ;   SuppliedCode:
  ;   ;This code here will not be executed from the custom block, rather from CustomLayer3Menu.asm.
  ;   ;RTL	;>This MUST end with an RTL because of the aforementioned "JSL !Freeram_CustomL3Menu_PasscodeCallBackSubroutine"
  ;-During menu selection, it is 24-bit address (3 bytes, again little endian) representing the location of the table tiles, row-major.
  ; Each option have a fixed number of characters to write based on what you set on !CustomL3Menu_MenuDisplay_OptionCharLength.

 !Freeram_ControlBackup = $0F3A|!addr
  ;^[4 bytes] a copy of $15-$18 (in the same order). This is so that when in UI mode,
  ; the player character (Mario/Luigi) cannot move and inputs can only affect what is
  ; on the UI.
  ; !Freeram_ControlBackup+0: $15 (%byetUDLR held down)
  ; !Freeram_ControlBackup+1: $16 (%byetUDLR first frame only)
  ; !Freeram_ControlBackup+2: $17 (%axlr---- held down)
  ; !Freeram_ControlBackup+3: $18 (%axlr---- first frame only)

 !Freeram_CustomL3Menu_DpadHoldTimer = $63
  ;^[1 byte] A counter that counts how many "quad-frames" (every 4th frame of $13) a specified direction on the D pad is being held down
  ; without changing direction. Used for making the cursor act as if the player is repeatedly pressing a direction when holding down a
  ; direction long enough (in this case a second, enters "turbo mode"). Formula:
  ;
  ; !Freeram_CustomL3Menu_DpadHoldTimer = seconds * 15
  ;
  ; Note that this isn't exact because $13 always increments. So it depends on the amount of time between the start of holding down the
  ; D-pad and the upcoming 4th frame.

 !Freeram_CustomL3Menu_DpadPulser  = $9C
  ;^[1 byte] a backup of the UDLR bits from !Freeram_ControlBackup. This is to detect if the player remains holding in a specific direction
  ; without changing. Format:
  ;
  ; udlrUDLR
  ;
  ; U/u = up
  ; D/d = down
  ; L/l = left
  ; R/r = right
  ;
  ; Low nybble UDLR contains the previous frame of the UDLR bits in !Freeram_ControlBackup. This is to check if the player changes D-pad
  ; directions (or just let go in neutral direction) to reset the "turbo mode"
  ;
  ; High nybble udlr is the "D-pad oscillator" that alternates between 0 and 1, therefore repeatedly firing a direction. Note that this
  ; also stores the UDLR bits from !Freeram_ControlBackup+1 so that the cursor moves one time on the first frame the player presses the
  ; D-pad initially. The codes that check for D-pad movement checks this nybble to enable repeated movements when held down.

 !Freeram_CustomL3Menu_MenuScrollPos = $79
  ;^[1 byte] This represents the scroll position should there be more options than displayed. This is mapped to the first option at the top.

 !Freeram_CustomL3Menu_NumberOfDisplayedOptions = $7C
  ;^[1 byte] This is the number of displayed options, minus 1. Used for scrolling menu displays if there are more options than displayed.
  
 !Freeram_CustomL3Menu_MenuUptionBehavior = $7F0000
  ;^[Number_of_bytes = Highest_number_of_options_in_game] Menu option ID, This contains what text, status and behaviors of each option
  ; to use. Each byte here for each option in the menu in the same order (first byte corresponds to the first option, 2nd on 2nd and so
  ; on). The number of bytes taken here is the menu having the highest number of options in your entire game of all menus.
  ;
  ; Do note that the behaviors that each option perform when selected and the text itself are separate from Uberasm_tool_files/library/CustomLayer3Menu.asm
  ; Meaning the code that perform certain actions (must run every frame when the menu is opened) when selecting an option and supplying
  ; the text must be done on its own ASM file. See example in Uberasm_tool_files/level/LevelWarpMenu.asm. The reason for this is to
  ; allow any type of menus.
 !Freeram_CustomL3Menu_UnlockWarpMenuFlags = $87
  ;^[1 byte] This is the unlock flags when using "CustomLayer3Menu/Uberasm_tool_files\level/LevelWarpMenu.asm". Format:
  ;  76543210
  ;   bits 0-7 corresponds to which screen exit to be enabled: 0 = locked, 1 = enabled.
 
 !Freeram_CustomL3Menu_CursorBlinkTimer = $1B91|!addr
  ;^[1 byte] frame counter for blinking cursor. By default, this is the same as SMW's $7E1B91, not used at all outside of vanilla SMW menus.
  ; Both SMW and this ASM resource need this rather than to use RAM $13 (global frame counter) so that the cursor blink state will always show
  ; when the cursor moves (each time the cursor moves, reset this timer).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Scratch RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 if !sa1 == 0
  !Scratchram_32bitDecToHexOutput = $7F844A
 else
  !Scratchram_32bitDecToHexOutput = $400198
 endif
  ;[4 bytes] Only used when "ReadPasscodeQuantity32Bit" is being used. This is the output of a 32-bit unsigned integer (little
  ;endian) when converting numbers from !Freeram_CustomL3Menu_DigitPasscodeUserInput to a raw binary number.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;Controls. See this info:
 ;https://smwc.me/m/smw/ram/7E0016/
 ;https://smwc.me/m/smw/ram/7E0018/
 ;Each bit in the binary number is any button that would trigger a "confirm" or "cancel"
  !CustomL3Menu_WhichControllerDataToConfirm = 2 ;>0 = Use $15-$16's byetUDLR input, 2 = Use $17-$18's axlr---- input, don't use other values.
  !CustomL3Menu_ButtonConfirm = %10000000 ;>Which bit to check that would "confirm" based on what input type above.
  
  !CustomL3Menu_WhichControllerDataToConfirm2 = 0 ;>0 = Use $15-$16's byetUDLR input, 2 = Use $17-$18's axlr---- input, don't use other values.
  !CustomL3Menu_ButtonConfirm2 = %10000000 ;>Which bit to check that would "confirm" based on what input type above.
   ;^Vanilla SMW have A and B 1-frame buttons acting as "confirm" on the title screen and X and Y being the "Cancel". Problem is is while X and Y are
   ; on the same bit for $16/$18, this is not true for the B button.
  
  !CustomL3Menu_WhichControllerDataToCancel = 0 ;>0 = Use $15-$16's byetUDLR input, 2 = Use $17-$18's axlr---- input, don't use other values.
  !CustomL3Menu_ButtonCancel = %01000000 ;>Which bit to check that would "cancel" based on what input type above.

 ;Sound effects. $00 for the sound effect = nothing
  ;Sound effect of moving cursor
   !CustomL3Menu_SoundEffectPort_CursorMove = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_CursorMove = $06

  ;Sound effect for confirming
   !CustomL3Menu_SoundEffectPort_Confirm = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_Confirm = $01
   
  ;Sound effect for canceling
   !CustomL3Menu_SoundEffectPort_Cancel = $1DF9|!addr
   !CustomL3Menu_SoundEffectNumber_Cancel = $01

  ;Sound effect when the user selects a menu option that is locked or enters the incorrect passcode or confirms on a disabled options
   !CustomL3Menu_SoundEffectPort_Rejected = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_Rejected = $2A

  ;Sound effect when the user selects a menu option that gets accepted or enters the correct passcode
   !CustomL3Menu_SoundEffectPort_Correct = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_Correct = $29

 ;Stripe image displaying layer 3 UI.
 ;Make sure the layer 3 settings in LM are:
 ;-Blank layer 3
 ;-[check] Force Layer 3 tiles with priority above other layers and sprites
 ;-[check] Enable advanced bypass settings for Layer 3
 ;
 ;-[uncheck] CGADSUB for Layer 3
 ;-[uncheck] Move layer 3 to subscreen
 ;
 ;-Vertical scroll: None
 ;-Vertical scroll: None
 ;-Inintal Y position/offset: 0
 ;-Inintal X position/offset: 0
 ;
 ;If multiple tiles, this position represent the top-leftmost tile,
 ;and extends downwards and rightwards.
  ;Right arrow cursor
   !CustomL3Menu_CursorRightArrow_TileNumb = $2E
   !CustomL3Menu_CursorRightArrow_TileProp = %00101001
  ;Number input
   !CustomL3Menu_NumberInput_XPos = 3 ;>31 ($1F) = right edge of screen
   !CustomL3Menu_NumberInput_YPos = 25 ;>27 ($1B) = bottom of screen

   ;Sound effect when increment/decrementing a digit value
    !CustomL3Menu_SoundEffectPort_NumberAdjust = $1DFC|!addr
    !CustomL3Menu_SoundEffectNumber_NumberAdjust = $23

   !CustomL3Menu_MaxNumberOfDigitsInEntireGame = 8
    ;^The most number of digits passcode and the longest string in your entire game.
  ;Menu
   ;These represents the top-rightmost minimum bounding box of the entire graphic of the menu.
   ;-The up arrow indicating the menu could scroll up would be at (!CustomL3Menu_MenuDisplay_XPos, CustomL3Menu_MenuDisplay_YPos)
   ;-Cursor would be at X = !CustomL3Menu_MenuDisplay_XPos and the Y position would be at
   ; Y = !CustomL3Menu_MenuDisplay_YPos+1+(Index*2) where "Index" is 0, 1, 2... up to (including) a value stored in !Freeram_CustomL3Menu_NumberOfCursorPositions.
   ;-Menu option's position (origin at the first character, including space) would be at X = !CustomL3Menu_MenuDisplay_XPos+2 and the Y position
   ; of each option is the same as the cursor positions.
   ;-The down arrow indicating the menu could scroll down would be at X = !CustomL3Menu_MenuDisplay_XPos and
   ; Y = !CustomL3Menu_MenuDisplay_YPos+((!Freeram_CustomL3Menu_NumberOfCursorPositions+1)*2), where !Freeram_CustomL3Menu_NumberOfCursorPositions
   ; in this formula refers to the value stored, not the RAM address number.
    !CustomL3Menu_MenuDisplay_XPos = 3
    !CustomL3Menu_MenuDisplay_YPos = 6
   
   !CustomL3Menu_MenuDisplay_OptionCharLength = 13
    ;^The maximum number of characters, including spaces for each option, in your entire game. NOTE: All strings must be this length
    ; so that when the menu scrolls, leftover tiles won't appear when a string gets replaced with a shorter
    ; string. This can be accomplished by adding spaces at the end if your strings are shorter.
    
   !CustomL3Menu_MenuDisplay_Properties = %00111000
    ;^The YXPCCCTT properties of each options in the menu
    
   !CustomL3Menu_MenuDisplay_ScrollArrowNumber = $80
    ;^Tile number of the up/down scroll arrows to indicate if the menu can scroll up or down.
    ; Note that this must be an upwards arrow, as the code automatically Y-flips it.
    ; This is also used for number adjuster when you change the digits.
    
   !CustomL3Menu_MenuDisplay_ScrollArrowProperties = %00101101
    ;^The YXPCCCTT properties of the scroll arrow. Y bit (bit 7) is automatically set for
    ; downwards arrow.
  ;String input
   ;Position of the string input, being the top-leftmost bounding box (X+0 is where the cursor will be at)
    !CustomL3Menu_StringInput_XPos = 5
    !CustomL3Menu_StringInput_YPos = 7
   ;Tile and properties for the empty space for the string the user enters.
    !CustomL3Menu_StringInput_DisplayString_CaretNotThere = $27
    !CustomL3Menu_StringInput_DisplayString_CaretNotThereProp = %00111000
   ;Sound effects
    !CustomL3Menu_StringInput_SFX_CharWritePort = $1DFC|!addr
    !CustomL3Menu_StringInput_SFX_CharWriteNumber = $23
 ;Other
  ;Debugging
  ;On the status bar:
  ; 1st number: shows the cursor's position, !Freeram_CustomL3Menu_CursorPos (only shows the first time you move cursor)
  ; 2nd number: shows the "maximum" cursor position index, !Freeram_CustomL3Menu_NumberOfCursorPositions
   !Debug_Display = 1
    ;^0 = off, 1 = on.
    ; Use this if you are customizing the menu and ran into issues
   ;Status bar starting address to write:
    !Debug_Display_StatusBarBasePos_Tile = $7FA000
    !Debug_Display_StatusBarBasePos_Props = $7FA001
   !Debug_Display_StatusBarFormat = $02
    ;^$01 = SMW/Ladida's Tile number and properties be in separate tables
    ;       (one table being TTTTTTTT, TTTTTTTT... and another being YXPCCCTT, YXPCCCTT...)
    ; $02 = Super status bar/Overworld border plus format, both tile number and properties
    ;       are on the same table alternating (goes like this: TTTTTTTT, YXPCCCTT,
    ;       TTTTTTTT, YXPCCCTT...)