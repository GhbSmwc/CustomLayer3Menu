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
 !Freeram_CustomL3Menu_UIState = $60
  ;^1 byte, menu state, used to display what menu/passcode mode. If value stored here is 0, then do nothing, if any nonzero value
  ; then it enters menu mode.

 !Freeram_CustomL3Menu_LineWriteCount = $61
  ;^1 byte, menu phase, used to load not the entire menu at once (results in vblank overflow -- black bars),
  ; but lines at a time from top to bottom.

 !Freeram_CustomL3Menu_CursorPos = $62
  ;^1 byte. Contains the position of the cursor. Note, for 2D movement, left and right adjusts this value -1/+1
  ; while vertical movement will -NumbOfCols/+NumbOfCols where NumbOfCols is the number of columns, or how many
  ; selections per row.

 !Freeram_CustomL3Menu_PasswordStringTable = $7E0F5E
  ;^[Max_Number_of_char_in_game] bytes. Contains the string of characters entered by the user.