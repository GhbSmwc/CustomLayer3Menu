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
  ;^[1 byte] Contains the position of the cursor. Note, for 2D movement, left and right adjusts this value -1/+1
  ; while vertical movement will -NumbOfCols/+NumbOfCols where NumbOfCols is the number of columns, or how many
  ; selections per row.

 !Freeram_CustomL3Menu_PasswordStringTable = $0F5E|!addr
  ;^[Max_Number_of_char_in_game] bytes. Contains the string of characters entered by the user.
  ; This is used by the number password UI. Make sure this is all initialized to 0.

 !Freeram_ControlBackup = $0DC3|!addr
  ;^[4 bytes] a copy of $15-$18 (in the same order). This is so that when in UI mode,
  ; the player character (Mario/Luigi) cannot move and inputs can only affect what is
  ; on the UI.
  ; !Freeram_ControlBackup+0: $15 (%byetUDLR held down)
  ; !Freeram_ControlBackup+1: $16 (%byetUDLR first frame only)
  ; !Freeram_ControlBackup+2: $17 (%axlr---- held down)
  ; !Freeram_ControlBackup+3: $18 (%axlr---- first frame only)

 !Freeram_BlockedStatBkp = $79
  ;^[1 byte] A backup of $77 to determine if Mario is on
  ; the ground.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;Controls. See this info:
 ;https://smwc.me/m/smw/ram/7E0016/
 ;https://smwc.me/m/smw/ram/7E0018/
 ;Each bit in the binary number is any button that would trigger a "confirm" or "cancel"
  !CustomL3Menu_WhichControllerDataToConfirm = 1 ;>0 = Use $15-$16's byetUDLR input, 1 = Use $17-$18's axlr---- input
  !CustomL3Menu_ButtonConfirm = %10000000 ;>Which bit to check that would "confirm" based on what input type above.
  !CustomL3Menu_WhichControllerDataToCancel = 0 ;>0 = Use $15-$16's byetUDLR input, 1 = Use $17-$18's axlr---- input
  !CustomL3Menu_ButtonCancel = %10000000 ;>Which bit to check that would "cancel" based on what input type above.

 ;Sound effects. $00 for the sound effect = nothing
  ;Sound effect of moving cursor
   !CustomL3Menu_SoundEffectPort_CursorMove = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_CursorMove = $06

  ;Sound effect for confirming
   !CustomL3Menu_SoundEffectPort_Confirm = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_Confirm = $01

  ;Sound effect when the user selects a menu option that is locked or enters the incorrect passcode
   !CustomL3Menu_SoundEffectPort_Rejected = $1DFC|!addr
   !CustomL3Menu_SoundEffectNumber_Rejected = $2A

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