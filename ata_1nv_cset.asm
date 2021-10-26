;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; ATARI CUSTOM CHARACTER SET
; 
; Custom characters.
;
; Revised version includes A-Z 0-9 that are displayable 
; using ANTIC mode 2 or ANTIC mode 6/7 text.  
; Updates created in the GRIDED.BXL program. 
; The new conversion to assembly source created by atf2code utility. 
; --------------------------------------------------------------------------


	.align $0400
	; Although most characters are used for Mode 6 or 7 text which has 
	; 64 characters and needs only 512 byte alignment, additional 
	; features use Mode 2 text which allows 128 characters and 
	; requires a 1K boundary.   

; ==========================================================================
; This character set defines many values in the same order as the
; Atari.  The C64 program offsets this data at +$20.  For Atari purposes
; this can stay at the $00 offset position.   In the C64 code the 
; references to character values need to be offset by -$20 to show 
; correctly on the Atari. 
;
; This defines a stylized space font -- characters A-Z with a few other 
; other symbol characters for text.  There are some special characters 
; for the ground, the bumpers, the mountains, and the stars.
;
; However, the original font has problems.  The minimum horizontal 
; pixel size on a NTSC composite display that can accurately render 
; color is a "color clock".  The font uses single-pixel width lines.  
; In the usual ANTIC text mode 2 (40 colums) each pixel is only one-
; half color clock wide.  Real Atari hardware using a composite or TV 
; display will render text in this font with artifact colors scattered 
; throughout.  
;
; On the C64 this is even worse as its single-pixel width lines are not 
; even a correct fraction of a color clock.  Artifact colors vary by 
; character position.  So far, all the videos I've seen of the game 
; were shot on emulators that don't accurately simulate the C64's 
; pixels' low correlation to the NTSC color clock.  
;
; But, back to the immediate problems on the Atari.....
;
; The correct solution for the characters that will be displayed in ANTIC
; mode 2 is to use two, adjacent horizontal pixels to cover an entire 
; color clock.  During initial development I decided I was far toooo 
; lazy to redefine the entire character set for the limited text in 
; the game.
;
; The next choice is to use a different text mode that displays color
; clock-sized pixels.   ANTIC Mode 6 and 7 use 8-bit wide glyph images
; like ANTIC mode 2, but each pixel is a color clock wide.  Excluding
; the score and line status information ANTIC mode 6 will be used where 
; text is displayed.  
;
; ANTIC Mode 6 characters are twice the width of Mode 2 characters. 
; However, Mode 6  provides other benefits that can be applied to 
; additional bells and whistles.  Unline Mode 2 text, Mode 6 provides
; full color indirection and use of five color registers (backgound 
; plus four foreground colors.)  This mode requires much less DMA 
; than Mode 2 and so provides more CPU time for Display List 
; Interrupts.
;
; The mountains and ground can be displayed using the Mode 6 characters 
; with some modifications to use different color registers which will 
; allow mixing white snow with other colors for the mountains on the same 
; line.  (In fact, Display List Interrupts will be used to apply several
; shades of color to the mountains.)
;
; The score line at the top and the current alien line value information 
; at the bottom of the screen will still use the Mode 2 character text mode.
; These lines use the numbers and not text, so in the original port/release 
; of the game for the Atari only the number glyphs are edited to double the 
; pixel width for consistent rendering.
;
; Converting integer values (the scores) into readable text on screen 
; could involve a lot of extra coding work.  Rather than handling the 
; score as an integer, the scores will be handled as individual bytes
; for each digit.  This will take a little extra coding to manage the 
; score as base 10 values per each byte, but the conversion to display 
; these bytes on screen is quick and easy.   Basically, just add the 
; appropriate offset value to the decimal digits 0 through 9 and this 
; directly provides the internal character value to write to the screen.
; There is no need to break up values into nybbles for display.  
;
; Since Mode 2 text is used for the scores and statistics the full 128 
; characters are available.   So, ten characters in the second set of 64
; which are available to Mode 2 are used for the numbers, so the base 
; characters used for Mode 6 text do not need to be adjusted. 
;
; The September updates included reworking the font.   Most of the first
; 64 characters in the character set remain for the Mode 6 text lines.
; The mostly unused second half of 64 characters now has the A-Z upper
; case defined for use with Mode 2 text lines. The scores, statistics,
; and a new line that describes option features use Mode 2 text.
; --------------------------------------------------------------------------

; ==========================================================================
; For reference, some changes....
; Character codes 0 to 63 are assumed to be primarily for Mode 6 text.
; Character codes 64+ are for Mode 2 text.
;
; C64       ==   Atari
; $07  @    ==   '  ; The natural position for apostrophe on Atari.
; $20       ==   @  ; This is the natural position for "at" on Atari
; The bumper at $20 on the C64 will be done with P5 missiles.
; $01  "1"  ==   !  ; Restore exclamation to its correct position on Atari.
; 
; $01 - $06 ==  
; These are for the animated 3, 2, 1 game start counter.  On the C64 this 
; was two characters put together to make a wide character.  The Atari 
; Mode 6 characters are already "double width", so the game could use
; just 3 characters to immitate the C64 start.  The Atari version now
; displays the countdown using Mode 7 text which is twice as tall as 
; Mode 6 text, so now the characters are 16 scan lines tall, allowing 
; for more screen area for visual color effects on the countdown display. 
;
; The new font was edited in my GRIDED program for font editing, and 
; the assembly output was created by my atf2code program.  Comments
; that existed in the original character set assembly code have been 
; transferred here.
; --------------------------------------------------------------------------

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


GAME_HYPHEN_CHAR=$1D
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

; Char $7C:   |    
	.byte $00,$00,$00,$00,$00,$00,$00,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

; Char $7D: CLEAR  
	.byte $00,$00,$00,$00,$00,$00,$00,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 

; Char $7E: DELETE 
	.byte $00,$00,$00,$00,$00,$00,$00,$00
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
; $00: . . . . . . . . 
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

