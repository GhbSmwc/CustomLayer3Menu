;This subroutine centers the player onto the door upon interacting with it to prevent
;issues placing the door on the right side of the screen boundary (If Mario stands
;anywhere to the left from the center would use the lower screen exit than the one
;the door is on).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA $187A|!addr
	ASL
	TAX
	REP #$20
	LDA $9A					;>What block the cliision point is on
	AND #$FFF0				;>Round down to the nearest 16th pixel (floor(MarioPos/16)*16)
	STA $94					;>And set player position
	LDA $98					;\Same as above but Y position. Mario's height position however is raised up
	AND #$FFF0				;|when on yoshi.
	SEC					;|
	SBC ?YOffset,x				;|
	STA $96					;/
	SEP #$20
	LDA #$0B
	STA $71	
	STA $13FB|!addr
	;^Freeze player. now you may think this is redundant since it is already performed by uberasm tool
	; BUT this is to prevent the player randomly being 1 pixel higher thanks to a code at $00EED4 which
	; executes AFTER processing this centering code here and BEFORE the uberasm code. The patch included
	; in this package will check these RAMs and won't move the player.
	RTL
	?YOffset:
	dw $0010			;>$187A = $00 (not on yoshi)
	dw $0020			;>$187A = $01 (on yoshi)
	dw $0020			;>$187A = $02 (on yoshi and turning around)