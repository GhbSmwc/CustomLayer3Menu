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
  
 !Freeram_CustomL3Menu_NumberOfCursorPositions = $61
  ;^[1 byte] The number of valid cursor positions or digits in the passcode, -1.
  ; Used for:
  ;
  ; -To prevent the cursor from going past the last item.
  ;
  ; -To make the cusor jump to the last item when the user moves the cursor past the first item.
  ;
  ; -For passcode digit mode, this is the number of digits to use (a 4-digit passcode means this have the value of #$03).

 !Freeram_CustomL3Menu_DigitPasscodeUserInput = $06F9|!addr
  ;^[!CustomL3Menu_MaxNumberOfDigitsInEntireGame] bytes. Contains the string of characters entered by the user.
  ; This is used by the number passcode UI. Make sure this is all initialized to 0.

 !Freeram_CustomL3Menu_DigitCorrectPasscode = $0F5E|!addr
  ;^[!CustomL3Menu_MaxNumberOfDigitsInEntireGame] bytes. Contains the string of characters that is the correct passcode
  ; that a code compares it to determine if correct or not.

 !Freeram_CustomL3Menu_PasscodeCallBackSubroutine = $0DC3|!addr
  ;^[4 bytes], this 4-byte of contiguous data contains a JML instruction to execute a code supplied from elsewhere, such as a
  ; a custom block door. The bytes in this RAM should be:
  ;  !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+0: 5C ;>This MUST be $5C, which is the JML instruction byte.
  ;  !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1: aa ;\These are made-up example address. If this is not
  ;  !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+2: bb ;|set up correctly, your game will crash or glitch out.
  ;  !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3: cc ;/
  ;
  ; This is being called via a JSL in the UI code in "Uberasm_tool_files/library/CustomLayer3Menu.asm" ("JSL !Freeram_CustomL3Menu_PasscodeCallBackSubroutine")
  ; The input data given is $00 (1 byte) which determines:
  ;  #$00 = Not confirmed (menu waiting for user to confirm) or when the user canceled. Therefore "not entered"
  ;  #$01 = Confirmed
  ; where the $ccbbaa is an address (in little endian) to jump to the supplied code. For example, in a custom block code you
  ; would do this to setup an address that executes during process of the UI system:
  ;	REP #$20
  ;	LDA.w #SuppliedCode					;\[aa bb] -> $xxbbaa (remember, little endian)
  ;	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+1	;/
  ;	SEP #$20
  ;	LDA.b #SuppliedCode>>16					;\[cc] -> $ccbbaa
  ;	STA !Freeram_CustomL3Menu_PasscodeCallBackSubroutine+3	;/
  ;	RTL
  ;	SuppliedCode:
  ;	;This code here will not be executed from the custom block, rather from CustomLayer3Menu.asm.
  ;	;RTL	;>This MUST end with an RTL because of the aforementioned "JSL !Freeram_CustomL3Menu_PasscodeCallBackSubroutine"

 !Freeram_ControlBackup = $0F3A|!addr
  ;^[4 bytes] a copy of $15-$18 (in the same order). This is so that when in UI mode,
  ; the player character (Mario/Luigi) cannot move and inputs can only affect what is
  ; on the UI.
  ; !Freeram_ControlBackup+0: $15 (%byetUDLR held down)
  ; !Freeram_ControlBackup+1: $16 (%byetUDLR first frame only)
  ; !Freeram_ControlBackup+2: $17 (%axlr---- held down)
  ; !Freeram_ControlBackup+3: $18 (%axlr---- first frame only)

 !Scratchram_32bitDecToHexOutput = $0F42|!addr
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

  ;Sound effect when the user selects a menu option that is locked or enters the incorrect passcode
   !CustomL3Menu_SoundEffectPort_Rejected = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_Rejected = $2A

  ;Sound effect when the user selects a menu option that gets accepted or enters the correct passcode
   !CustomL3Menu_SoundEffectPort_Correct = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_Correct = $29

  ;Sound effect when increment/decrementing a digit value
   !CustomL3Menu_SoundEffectPort_NumberAdjust = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_NumberAdjust = $23

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
  ;Number input
   !CustomL3Menu_NumberInput_XPos = 3 ;>31 ($1F) = right edge of screen
   !CustomL3Menu_NumberInput_YPos = 25 ;>27 ($1B) = bottom of screen

 ;Other
  !CustomL3Menu_MaxNumberOfDigitsInEntireGame = 8
   ;^The most number of digits passcode in your entire game.