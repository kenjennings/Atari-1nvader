;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; ATARI CUSTOM CHARACTER SET
; ==========================================================================

	.align $0400
	; Although most characters are used for Mode 6 or 7 text which has 
	; 64 characters and needs only 512 byte alignment, additional 
	; features use Mode 2 text which allows 128 characters and 
	; requires a 1K boundary.   

CHARACTER_SET

; Page 0xE0.  Chars 0 to 31 -- Symbols, numbers
; Char $00: SPACE  
	.byte $00,$00,$00,$00,$00,$00,$00,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

; Char $01:   !    ;    Atari uses as exclamation point. 
	.byte $00,$10,$10,$10,$10,$00,$10,$00
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 

; Char $02:   "    ;     LEFT Bouncer the second time.
	.byte $E0,$F0,$F0,$F0,$F0,$F0,$E0,$00
; $E0: # # # . . . . . 
; $F0: # # # # . . . . 
; $F0: # # # # . . . . 
; $F0: # # # # . . . . 
; $F0: # # # # . . . . 
; $F0: # # # # . . . . 
; $E0: # # # . . . . . 
; $00: . . . . . . . . 

; Char $03:   #    ;     RIGHT bouncer.   Left/Right line end.
	.byte $07,$0F,$0F,$0F,$0F,$0F,$07,$00
; $07: . . . . . # # # 
; $0F: . . . . # # # # 
; $0F: . . . . # # # # 
; $0F: . . . . # # # # 
; $0F: . . . . # # # # 
; $0F: . . . . # # # # 
; $07: . . . . . # # # 
; $00: . . . . . . . . 

; Char $04:   $    ; Atari - a piece of ground level background pointy mountains.
	.byte $00,$01,$02,$04,$08,$10,$20,$00
; $00: . . . . . . . . 
; $01: . . . . . . . # 
; $02: . . . . . . # . 
; $04: . . . . . # . . 
; $08: . . . . # . . . 
; $10: . . . # . . . . 
; $20: . . # . . . . . 
; $00: . . . . . . . . 

; Char $05:   %    ; Atari - a piece of ground level background pointy mountains.
	.byte $80,$40,$20,$10,$08,$04,$02,$00
; $80: # . . . . . . . 
; $40: . # . . . . . . 
; $20: . . # . . . . . 
; $10: . . . # . . . . 
; $08: . . . . # . . . 
; $04: . . . . . # . . 
; $02: . . . . . . # . 
; $00: . . . . . . . . 

; Char $06:   &    ; Atari - a piece of ground level background pointy mountains.
	.byte $00,$00,$00,$10,$28,$44,$82,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $28: . . # . # . . . 
; $44: . # . . . # . . 
; $82: # . . . . . # . 
; $00: . . . . . . . . 

; Char $07:   '    ; - This was the C64 at sign.  
	; On the Atari this is the single tick/apostrophe for Mode 6
	.byte $00,$08,$08,$10,$00,$00,$00,$00
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $08: . . . . # . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

; Char $08:   (    ; Atari - a piece of ground level background pointy mountains.
	.byte $00,$00,$08,$15,$22,$44,$88,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $15: . . . # . # . # 
; $22: . . # . . . # . 
; $44: . # . . . # . . 
; $88: # . . . # . . . 
; $00: . . . . . . . . 

; Char $09:   )    ; Atari - a piece of ground level background pointy mountains.
	.byte $00,$40,$A0,$10,$08,$04,$02,$00
; $00: . . . . . . . . 
; $40: . # . . . . . . 
; $A0: # . # . . . . . 
; $10: . . . # . . . . 
; $08: . . . . # . . . 
; $04: . . . . . # . . 
; $02: . . . . . . # . 
; $00: . . . . . . . . 

GAME_STAR_CHAR  ; label is for animating cheat mode.
; Char $0A:   *    ; Revise Star again for Atari for Mode 6 color
	.byte $08,$00,$08,$2A,$08,$00,$08,$00
; $08: . . . . # . . . 
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $2A: . . # . # . # . 
; $08: . . . . # . . . 
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $00: . . . . . . . . 

; Char $0B:   +    ; Atari - a piece of ground level background pointy mountains.
	.byte $80,$44,$2A,$11,$08,$04,$02,$00
; $80: # . . . . . . . 
; $44: . # . . . # . . 
; $2A: . . # . # . # . 
; $11: . . . # . . . # 
; $08: . . . . # . . . 
; $04: . . . . . # . . 
; $02: . . . . . . # . 
; $00: . . . . . . . . 

; Char $0C:   ,    ;     comma
	.byte $00,$00,$00,$00,$00,$00,$10,$20
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $20: . . # . . . . . 

; Char $0D:   -    ;     minus
	.byte $00,$00,$00,$7C,$00,$00,$00,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

; Char $0E:   .    ;     period.
	.byte $00,$00,$00,$00,$00,$00,$10,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 

; Char $0F:   /    ; On the Atari we still need this for a URL in the credits.
	.byte $00,$02,$04,$08,$00,$10,$20,$40
; $00: . . . . . . . . 
; $02: . . . . . . # . 
; $04: . . . . . # . . 
; $08: . . . . # . . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $20: . . # . . . . . 
; $40: . # . . . . . . 

; These are the 0 to 9 digits displayed in the Mode 6 text.
; See the $40 characters for the Mode 2 versions.

; Char $10:   0    
	.byte $00,$38,$44,$54,$54,$44,$38,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $44: . # . . . # . . 
; $54: . # . # . # . . 
; $54: . # . # . # . . 
; $44: . # . . . # . . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $11:   1    
	.byte $00,$10,$20,$10,$10,$10,$10,$00
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $20: . . # . . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 

; Char $12:   2    
	.byte $00,$78,$04,$38,$40,$40,$7C,$00
; $00: . . . . . . . . 
; $78: . # # # # . . . 
; $04: . . . . . # . . 
; $38: . . # # # . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $13:   3    
	.byte $00,$78,$04,$18,$04,$04,$78,$00
; $00: . . . . . . . . 
; $78: . # # # # . . . 
; $04: . . . . . # . . 
; $18: . . . # # . . . 
; $04: . . . . . # . . 
; $04: . . . . . # . . 
; $78: . # # # # . . . 
; $00: . . . . . . . . 

; Char $14:   4    
	.byte $00,$44,$44,$44,$74,$04,$04,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $74: . # # # . # . . 
; $04: . . . . . # . . 
; $04: . . . . . # . . 
; $00: . . . . . . . . 

; Char $15:   5    
	.byte $00,$7C,$40,$78,$04,$04,$78,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $40: . # . . . . . . 
; $78: . # # # # . . . 
; $04: . . . . . # . . 
; $04: . . . . . # . . 
; $78: . # # # # . . . 
; $00: . . . . . . . . 

; Char $16:   6    
	.byte $00,$30,$40,$78,$44,$44,$38,$00
; $00: . . . . . . . . 
; $30: . . # # . . . . 
; $40: . # . . . . . . 
; $78: . # # # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $17:   7    
	.byte $00,$7C,$00,$08,$10,$10,$10,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 

; Char $18:   8    
	.byte $00,$38,$44,$38,$44,$44,$38,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $44: . # . . . # . . 
; $38: . . # # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $19:   9    
	.byte $00,$38,$44,$44,$34,$04,$04,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $34: . . # # . # . . 
; $04: . . . . . # . . 
; $04: . . . . . # . . 
; $00: . . . . . . . . 

; Char $1A:   :     ; :  (yes, colon)
	.byte $00,$10,$10,$00,$00,$10,$10,$00
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 

; Char $1B:   ;    ; Atari - a piece of ground level background pointy mountains. 
	.byte $00,$00,$00,$10,$A8,$44,$82,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $A8: # . # . # . . . 
; $44: . # . . . # . . 
; $82: # . . . . . # . 
; $00: . . . . . . . . 

;GAME_OVER_LEFT_CHAR=$1C
;GAME_OVER_LEFT_ADDR
; Char $1C:   <        ;  STAND-IN for Game Over Text during transition (LEFT)
; Char $1C:   <    ;     Left Side of CENTER BOUNCER
CHAR_CENTER_BOUNCER=$1C ; and $1D
	.byte $07,$0F,$0F,$0F,$0F,$0F,$07,$00
; $01: . . . . . . . # 
; $03: . . . . . . # # 
; $03: . . . . . . # # 
; $03: . . . . . . # # 
; $03: . . . . . . # # 
; $03: . . . . . . # # 
; $01: . . . . . . . # 
; $00: . . . . . . . . 

;GAME_OVER_RIGHT_CHAR=$1D
;GAME_OVER_RIGHT_ADDR
; Char $1D:   =    ;  STAND-IN for Game Over Text during transition (RIGHT)
; Char $1D:   =    ; Right side of CENTER BOUNCER
	.byte $E0,$F0,$F0,$F0,$F0,$F0,$E0,$00
; $80: # . . . . . . .
; $c0: # # . . . . . .
; $c0: # # . . . . . .
; $c0: # # . . . . . .
; $c0: # # . . . . . .
; $c0: # # . . . . . .
; $80: # . . . . . . .
; $00: . . . . . . . . 

; Char $1E:   >    ; UNUSED
	.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; $FF: # # # # # # # # 
; $FF: # # # # # # # # 
; $FF: # # # # # # # # 
; $FF: # # # # # # # # 
; $FF: # # # # # # # # 
; $FF: # # # # # # # # 
; $FF: # # # # # # # # 
; $FF: # # # # # # # # 

; Char $1F:   ?    
	.byte $00,$38,$44,$08,$10,$00,$10,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $44: . # . . . # . . 
; $08: . . . . # . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 


; On the C64 this character is at $02 
; I like to have the  single tick (') and the at (@) in the 
; correct positions in the Atari font.
; Therefore, the Atari the @ sign is moved to its normal position 
; here, so that the single tick (apostrophe) can be used at its normal place
; for text.

; Page 0xE1.  Chars 32 to 63 -- Uppercase
; Char $20:   @      ; Revised @ for Atari Mode 6
	.byte $00,$38,$C6,$D6,$DC,$C0,$3C,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $C6: # # . . . # # . 
; $D6: # # . # . # # . 
; $DC: # # . # # # . . 
; $C0: # # . . . . . . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $21:   A    
	.byte $00,$04,$0C,$14,$24,$5C,$44,$00
; $00: . . . . . . . . 
; $04: . . . . . # . . 
; $0C: . . . . # # . . 
; $14: . . . # . # . . 
; $24: . . # . . # . . 
; $5C: . # . # # # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $22:   B    
	.byte $00,$78,$44,$58,$44,$44,$5C,$00
; $00: . . . . . . . . 
; $78: . # # # # . . . 
; $44: . # . . . # . . 
; $58: . # . # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $5C: . # . # # # . . 
; $00: . . . . . . . . 

; Char $23:   C    
	.byte $00,$3C,$40,$40,$40,$40,$7C,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $24:   D    
	.byte $00,$70,$48,$44,$44,$44,$5C,$00
; $00: . . . . . . . . 
; $70: . # # # . . . . 
; $48: . # . . # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $5C: . # . # # # . . 
; $00: . . . . . . . . 

; Char $25:   E    
	.byte $00,$7C,$40,$58,$40,$40,$7C,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $40: . # . . . . . . 
; $58: . # . # # . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $26:   F    
	.byte $00,$7C,$40,$58,$40,$40,$40,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $40: . # . . . . . . 
; $58: . # . # # . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $00: . . . . . . . . 

; Char $27:   G    
	.byte $00,$3C,$40,$40,$44,$44,$7C,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $28:   H    
	.byte $00,$44,$44,$5C,$44,$44,$44,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $5C: . # . # # # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $29:   I    
	.byte $00,$10,$10,$10,$10,$10,$10,$00
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 

; Char $2A:   J    
	.byte $00,$08,$08,$08,$08,$08,$08,$30
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $08: . . . . # . . . 
; $08: . . . . # . . . 
; $08: . . . . # . . . 
; $08: . . . . # . . . 
; $08: . . . . # . . . 
; $30: . . # # . . . . 

; Char $2B:   K    
	.byte $00,$44,$44,$58,$44,$44,$44,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $58: . # . # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $2C:   L    
	.byte $00,$40,$40,$40,$40,$40,$7C,$00
; $00: . . . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $2D:   M    
	.byte $00,$44,$2C,$54,$44,$44,$44,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $2C: . . # . # # . . 
; $54: . # . # . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $2E:   N    
	.byte $00,$44,$64,$54,$4C,$44,$44,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $64: . # # . . # . . 
; $54: . # . # . # . . 
; $4C: . # . . # # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $2F:   O    
	.byte $00,$38,$44,$44,$44,$44,$38,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $30:   P    
	.byte $00,$78,$44,$44,$58,$40,$40,$00
; $00: . . . . . . . . 
; $78: . # # # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $58: . # . # # . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $00: . . . . . . . . 

; Char $31:   Q    
	.byte $00,$38,$44,$44,$44,$40,$3C,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $40: . # . . . . . . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $32:   R    
	.byte $00,$78,$44,$44,$58,$44,$44,$00
; $00: . . . . . . . . 
; $78: . # # # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $58: . # . # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $33:   S    
	.byte $00,$3C,$40,$38,$04,$04,$78,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $40: . # . . . . . . 
; $38: . . # # # . . . 
; $04: . . . . . # . . 
; $04: . . . . . # . . 
; $78: . # # # # . . . 
; $00: . . . . . . . . 

; Char $34:   T    
	.byte $00,$7C,$00,$10,$10,$10,$10,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $10: . . . # . . . . 
; $00: . . . . . . . . 

; Char $35:   U    
	.byte $00,$44,$44,$44,$44,$44,$38,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $36:   V    
	.byte $00,$44,$44,$48,$50,$60,$40,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $48: . # . . # . . . 
; $50: . # . # . . . . 
; $60: . # # . . . . . 
; $40: . # . . . . . . 
; $00: . . . . . . . . 

; Char $37:   W    
	.byte $00,$44,$44,$44,$54,$2C,$44,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $54: . # . # . # . . 
; $2C: . . # . # # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $38:   X    
	.byte $00,$44,$44,$18,$44,$44,$44,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $18: . . . # # . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $39:   Y    
	.byte $00,$44,$44,$44,$3C,$04,$38,$00
; $00: . . . . . . . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $3C: . . # # # # . . 
; $04: . . . . . # . . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $3A:   Z    
	.byte $00,$7C,$00,$08,$10,$20,$7C,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $10: . . . # . . . . 
; $20: . . # . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $3B:   [    ; mnt l .   Mountain Left
	.byte $01,$02,$06,$0A,$18,$2A,$40,$A0
; $01: . . . . . . . # 
; $02: . . . . . . # . 
; $06: . . . . . # # . 
; $0A: . . . . # . # . 
; $18: . . . # # . . . 
; $2A: . . # . # . # . 
; $40: . # . . . . . . 
; $A0: # . # . . . . . 

; Char $3C:   \    ; mnt r .   Mountain Right
	.byte $80,$40,$A0,$30,$28,$04,$26,$05
; $80: # . . . . . . . 
; $40: . # . . . . . . 
; $A0: # . # . . . . . 
; $30: . . # # . . . . 
; $28: . . # . # . . . 
; $04: . . . . . # . . 
; $26: . . # . . # # . 
; $05: . . . . . # . # 

; Char $3D:   ]    ; mnt top.  Mountain Top
	.byte $00,$00,$00,$00,$18,$3C,$6E,$AB
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $3C: . . # # # # . . 
; $6E: . # # . # # # . 
; $AB: # . # . # . # # 

; Char $3E:   ^    ; grnd lo .  Ground bottom line.
	.byte $FF,$11,$44,$00,$00,$00,$00,$00
; $FF: # # # # # # # # 
; $11: . . . # . . . # 
; $44: . # . . . # . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

; Char $3F:   _    ; grnd hi .  Ground Top Line
	.byte $99,$42,$99,$40,$AA,$55,$FF,$00
; $99: # . . # # . . # 
; $42: . # . . . . # . 
; $99: # . . # # . . # 
; $40: . # . . . . . . 
; $AA: # . # . # . # . 
; $55: . # . # . # . # 
; $FF: # # # # # # # # 
; $00: . . . . . . . . 

; These are the 10 characters used for ANTIC Mode 2 Score text.
; Scores are calculating using a single base 10 digit per byte.
; To display the right character on the screen simply add (or
; ORA) $40 to the digit.

; Revise digits for Atari display in ANTIC Mode 2 and proper 
; color artifact avoidance.

; Page 0xE2.  Chars 64 to 95 -- graphics control characters
; Char $40: ctrl-,   ; 0
	.byte $00,$3C,$66,$66,$66,$66,$3C,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $41: ctrl-A   ; 1
	.byte $00,$18,$30,$18,$18,$18,$18,$00
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $30: . . # # . . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

; Char $42: ctrl-B   ; 2
	.byte $00,$7C,$06,$3C,$60,$60,$7E,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $06: . . . . . # # . 
; $3C: . . # # # # . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 

; Char $43: ctrl-C   ; 3
	.byte $00,$7C,$06,$1C,$06,$06,$7C,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $06: . . . . . # # . 
; $1C: . . . # # # . . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $44: ctrl-D   ; 4
	.byte $00,$66,$66,$66,$76,$06,$06,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $76: . # # # . # # . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $00: . . . . . . . . 

; Char $45: ctrl-E   ; 5
	.byte $00,$7E,$60,$7C,$06,$06,$7C,$00
; $00: . . . . . . . . 
; $7E: . # # # # # # . 
; $60: . # # . . . . . 
; $7C: . # # # # # . . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $46: ctrl-F   ; 6
	.byte $00,$38,$60,$7C,$66,$66,$3C,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $60: . # # . . . . . 
; $7C: . # # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $47: ctrl-G   ; 7
	.byte $00,$7E,$00,$0C,$18,$18,$18,$00
; $00: . . . . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 
; $0C: . . . . # # . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

; Char $48: ctrl-H   ; 8
	.byte $00,$3C,$66,$3C,$66,$66,$3C,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $49: ctrl-I    9
	.byte $00,$3C,$66,$66,$36,$06,$06,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $36: . . # # . # # . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $00: . . . . . . . . 

; Char $4A: ctrl-J   ; Old version of 0 for mode 2
	.byte $00,$38,$C6,$C6,$C6,$C6,$38,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $C6: # # . . . # # . 
; $C6: # # . . . # # . 
; $C6: # # . . . # # . 
; $C6: # # . . . # # . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $4B: ctrl-K    ; Old version of 1 for mode 2
	.byte $00,$18,$30,$18,$18,$18,$18,$00
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $30: . . # # . . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

; Char $4C: ctrl-L   ; Old version of 2 for mode 2
	.byte $00,$78,$06,$38,$C0,$C0,$7C,$00
; $00: . . . . . . . . 
; $78: . # # # # . . . 
; $06: . . . . . # # . 
; $38: . . # # # . . . 
; $C0: # # . . . . . . 
; $C0: # # . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $4D: ctrl-M   ; Old version of 3 for mode 2
	.byte $00,$78,$06,$18,$06,$06,$78,$00
; $00: . . . . . . . . 
; $78: . # # # # . . . 
; $06: . . . . . # # . 
; $18: . . . # # . . . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $78: . # # # # . . . 
; $00: . . . . . . . . 

; Char $4E: ctrl-N   ; Old version of 4 for mode 2
	.byte $00,$C6,$C6,$C6,$76,$06,$06,$00
; $00: . . . . . . . . 
; $C6: # # . . . # # . 
; $C6: # # . . . # # . 
; $C6: # # . . . # # . 
; $76: . # # # . # # . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $00: . . . . . . . . 

; Char $4F: ctrl-O   ; Old version of 5 for mode 2
	.byte $00,$F8,$C0,$F8,$06,$06,$78,$00
; $00: . . . . . . . . 
; $F8: # # # # # . . . 
; $C0: # # . . . . . . 
; $F8: # # # # # . . . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $78: . # # # # . . . 
; $00: . . . . . . . . 

; Char $50: ctrl-P 
	.byte $00,$3C,$66,$66,$66,$66,$3C,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $51: ctrl-Q 
	.byte $00,$18,$30,$18,$18,$18,$18,$00
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $30: . . # # . . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

; Char $52: ctrl-R 
	.byte $00,$7C,$06,$3C,$60,$60,$7E,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $06: . . . . . # # . 
; $3C: . . # # # # . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 

; Char $53: ctrl-S 
	.byte $00,$7C,$06,$1C,$06,$06,$7C,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $06: . . . . . # # . 
; $1C: . . . # # # . . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $54: ctrl-T 
	.byte $00,$66,$66,$66,$76,$06,$06,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $76: . # # # . # # . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $00: . . . . . . . . 

; Char $55: ctrl-U 
	.byte $00,$7E,$60,$7C,$06,$06,$7C,$00
; $00: . . . . . . . . 
; $7E: . # # # # # # . 
; $60: . # # . . . . . 
; $7C: . # # # # # . . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $56: ctrl-V 
	.byte $00,$38,$60,$7C,$66,$66,$3C,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $60: . # # . . . . . 
; $7C: . # # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $57: ctrl-W 
	.byte $00,$7E,$00,$0C,$18,$18,$18,$00
; $00: . . . . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 
; $0C: . . . . # # . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

; Char $58: ctrl-X 
	.byte $00,$3C,$66,$3C,$66,$66,$3C,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $59: ctrl-Y 
	.byte $00,$3C,$66,$66,$36,$06,$06,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $36: . . # # . # # . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $00: . . . . . . . . 

; Char $5A: ctrl-Z 
	.byte $00,$18,$18,$00,$00,$18,$18,$00
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

; Char $5B: ESCAPE    ; Old version of 6 for mode 2
	.byte $00,$38,$C0,$F8,$C6,$C6,$38,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $C0: # # . . . . . . 
; $F8: # # # # # . . . 
; $C6: # # . . . # # . 
; $C6: # # . . . # # . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $5C: UP      ; Old version of 7 for mode 2 
	.byte $00,$7C,$00,$0C,$18,$18,$18,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 
; $0C: . . . . # # . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 
 
; Char $5D: DOWN      ; Old version of 8 for mode 2
	.byte $00,$38,$C6,$38,$C6,$C6,$38,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $C6: # # . . . # # . 
; $38: . . # # # . . . 
; $C6: # # . . . # # . 
; $C6: # # . . . # # . 
; $38: . . # # # . . . 
; $00: . . . . . . . . 

; Char $5E: LEFT      ; Old version of 9 for mode 2
	.byte $00,$38,$C6,$C6,$36,$06,$06,$00
; $00: . . . . . . . . 
; $38: . . # # # . . . 
; $C6: # # . . . # # . 
; $C6: # # . . . # # . 
; $36: . . # # . # # . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $00: . . . . . . . . 

; Char $5F: RIGHT     
	.byte $00,$3C,$66,$0C,$18,$00,$18,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $0C: . . . . # # . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

CHAR_ALTERNATE_BLANK=$20  ; ($60 - $40 == $20)
CHAR_MODE2_BLANK=$60
; Page 0xE3.  Chars 96 to 127 -- lowercase
; Char $60: ctrl-. 
	.byte $00,$00,$00,$00,$00,$00,$00,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

; Char $61:   a    
	.byte $00,$06,$0E,$1E,$36,$6E,$66,$00
; $00: . . . . . . . . 
; $06: . . . . . # # . 
; $0E: . . . . # # # . 
; $1E: . . . # # # # . 
; $36: . . # # . # # . 
; $6E: . # # . # # # . 
; $66: . # # . . # # . 
; $00: . . . . . . . . 

; Char $62:   b    
	.byte $00,$7C,$66,$6C,$66,$66,$6E,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $66: . # # . . # # . 
; $6C: . # # . # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $6E: . # # . # # # . 
; $00: . . . . . . . . 

; Char $63:   c    
	.byte $00,$3E,$60,$60,$60,$60,$7E,$00
; $00: . . . . . . . . 
; $3E: . . # # # # # . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 

; Char $64:   d    
	.byte $00,$78,$6C,$66,$66,$66,$6E,$00
; $00: . . . . . . . . 
; $78: . # # # # . . . 
; $6C: . # # . # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $6E: . # # . # # # . 
; $00: . . . . . . . . 

; Char $65:   e    
	.byte $00,$7E,$60,$6C,$60,$60,$7E,$00
; $00: . . . . . . . . 
; $7E: . # # # # # # . 
; $60: . # # . . . . . 
; $6C: . # # . # # . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 

; Char $66:   f    
	.byte $00,$7E,$60,$6C,$60,$60,$60,$00
; $00: . . . . . . . . 
; $7E: . # # # # # # . 
; $60: . # # . . . . . 
; $6C: . # # . # # . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $00: . . . . . . . . 

; Char $67:   g    
	.byte $00,$3E,$60,$60,$66,$66,$7E,$00
; $00: . . . . . . . . 
; $3E: . . # # # # # . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 

; Char $68:   h    
	.byte $00,$66,$66,$6E,$66,$66,$66,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $6E: . # # . # # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $00: . . . . . . . . 

; Char $69:   i    
	.byte $00,$18,$18,$18,$18,$18,$18,$00
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

; Char $6A:   j    
	.byte $00,$0C,$0C,$0C,$0C,$0C,$0C,$38
; $00: . . . . . . . . 
; $0C: . . . . # # . . 
; $0C: . . . . # # . . 
; $0C: . . . . # # . . 
; $0C: . . . . # # . . 
; $0C: . . . . # # . . 
; $0C: . . . . # # . . 
; $38: . . # # # . . . 

; Char $6B:   k    
	.byte $00,$66,$66,$6C,$66,$66,$66,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $6C: . # # . # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $00: . . . . . . . . 

; Char $6C:   l    
	.byte $00,$60,$60,$60,$60,$60,$7E,$00
; $00: . . . . . . . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 

; Char $6D:   m    
	.byte $00,$66,$3E,$76,$66,$66,$66,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $3E: . . # # # # # . 
; $76: . # # # . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $00: . . . . . . . . 

; Char $6E:   n    
	.byte $00,$66,$76,$7E,$6E,$66,$66,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $76: . # # # . # # . 
; $7E: . # # # # # # . 
; $6E: . # # . # # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $00: . . . . . . . . 

; Char $6F:   o    
	.byte $00,$3C,$66,$66,$66,$66,$3C,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $70:   p    
	.byte $00,$7C,$66,$66,$6C,$60,$60,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $6C: . # # . # # . . 
; $60: . # # . . . . . 
; $60: . # # . . . . . 
; $00: . . . . . . . . 

; Char $71:   q    
	.byte $00,$3C,$66,$66,$66,$60,$3E,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $60: . # # . . . . . 
; $3E: . . # # # # # . 
; $00: . . . . . . . . 

; Char $72:   r    
	.byte $00,$7C,$66,$66,$6C,$66,$66,$00
; $00: . . . . . . . . 
; $7C: . # # # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $6C: . # # . # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $00: . . . . . . . . 

; Char $73:   s    
	.byte $00,$3E,$60,$3C,$06,$06,$7C,$00
; $00: . . . . . . . . 
; $3E: . . # # # # # . 
; $60: . # # . . . . . 
; $3C: . . # # # # . . 
; $06: . . . . . # # . 
; $06: . . . . . # # . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $74:   t    
	.byte $00,$7E,$00,$18,$18,$18,$18,$00
; $00: . . . . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 

; Char $75:   u    
	.byte $00,$66,$66,$66,$66,$66,$3C,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $76:   v    
	.byte $00,$66,$66,$6C,$78,$70,$60,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $6C: . # # . # # . . 
; $78: . # # # # . . . 
; $70: . # # # . . . . 
; $60: . # # . . . . . 
; $00: . . . . . . . . 

; Char $77:   w    
	.byte $00,$66,$66,$66,$76,$3E,$66,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $76: . # # # . # # . 
; $3E: . . # # # # # . 
; $66: . # # . . # # . 
; $00: . . . . . . . . 

; Char $78:   x    
	.byte $00,$66,$66,$1C,$66,$66,$66,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $1C: . . . # # # . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $00: . . . . . . . . 

; Char $79:   y    
	.byte $00,$66,$66,$66,$3E,$06,$3C,$00
; $00: . . . . . . . . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $66: . # # . . # # . 
; $3E: . . # # # # # . 
; $06: . . . . . # # . 
; $3C: . . # # # # . . 
; $00: . . . . . . . . 

; Char $7A:   z    
	.byte $00,$7E,$00,$0C,$18,$30,$7E,$00
; $00: . . . . . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 
; $0C: . . . . # # . . 
; $18: . . . # # . . . 
; $30: . . # # . . . . 
; $7E: . # # # # # # . 
; $00: . . . . . . . . 


;GAME_HYPHEN_CHAR=$1D
;GAME_HYPHEN_CHAR=$3B
GAME_HYPHEN_CHAR=$7B
; Char $7B: ctrl-;    ; A new hyphen
	.byte $00,$00,$00,$3c,$00,$00,$00,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . # # # # . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

;CHAR_ALT_BANG=$3c ; ($7c - $40 == $3c)
CHAR_ALT_BANG=$7c
; Char $7C:   |    
	.byte $00,$18,$18,$18,$18,$00,$18,$00
; $00: . . . . . . . . 
; $10: . . . # # . . . 
; $10: . . . # # . . . 
; $10: . . . # # . . . 
; $10: . . . # # . . . 
; $00: . . . . . . . . 
; $10: . . . # # . . . 
; $00: . . . . . . . .

CHAR_ALT_APOS=$3D ; ($7d - $40 == $3d)
; Char $7D: CLEAR  
	.byte $00,$18,$18,$30,$00,$00,$00,$00
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $18: . . . # # . . . 
; $30: . . # # . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

CHAR_ALT_QUES=$3E ; ($7e - $40 == $3e)
; Char $7E: DELETE 
	.byte $00,$3c,$66,$0c,$18,$00,$18,$00
; $00: . . . . . . . . 
; $3C: . . # # # # . . 
; $66: . # # . . # # . 
; $0C: . . . . # # . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 
; $18: . . . # # . . . 
; $00: . . . . . . . . 


; Char $7F: TAB    
	.byte $00,$00,$00,$00,$00,$00,$00,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

