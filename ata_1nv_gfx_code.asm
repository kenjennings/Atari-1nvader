;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; SCREEN GRAPHICS 
;
; Here is all the code that maniupulates screen memory, and any data that 
; is not directly read by ANTIC as screen RAM.
; Any data declared here is reference for the CPU, or source data to 
; be copied to screen memeory.
; --------------------------------------------------------------------------

; ==========================================================================
; ANIMATE TITLE LOGO
; ==========================================================================
; Change the Ttitle screen's LMS pointer to the graphics for the big logo
; on the screen.  Basically, page flipping.   Change one pointer to 
; change what the screen displays rather than copy hundreds of bytes.
; --------------------------------------------------------------------------

TABLE_GFX_TITLE_LOGO        ; Stored in reverse order for less iteration code.
	.byte <GFX_TITLE_FRAME5
	.byte <GFX_TITLE_FRAME4
	.byte <GFX_TITLE_FRAME3	
	.byte <GFX_TITLE_FRAME2
	.byte <GFX_TITLE_FRAME1

Gfx_Animate_Title_Logo

	dec zTITLE_LOGO_FRAME         ; Subtract frame counter.
	bpl b_gatl_SkipReset         ; If it did not go negative, then it is good.
	
	ldx #TITLE_LOGO_FRAME_MAX    ; Reset frame counter 
	stx zTITLE_LOGO_FRAME         ; to max value.
	
b_gatl_SkipReset
	ldx zTITLE_LOGO_FRAME         ; Actually read the value to use as index.
	lda TABLE_GFX_TITLE_LOGO,X   ; Get the new graphics address low byte
	sta DL_LMS_TITLE             ; and update the display list LMS.
	
	rts
	
	
; ==========================================================================
; CHOOSE GAME OVER TEXT
; ==========================================================================
; Choose the Game Over message and set zGAME_OVER_TEXT 
;
; I want Game Over to be the "normal" end game response.  
; A fraction of the time a different value should appear.
; Easter-eggly-like.  
;
; How to do the text randomization:
;
; Get a random number.
;
; Values 0 to 7 count for the easter egg treatment.
;
; All others ( >= 8) will be reduced to 0 for the default text.
;
; For the Easter Egg Game End, use the random number
; chosen then add 2.
;
; If the result is 2, and the game is for 1 player, then 
; decrement.  This will result in choosing the 
; grammatically correct insult for the number of players.
;
; This works out to a 8 in 256 chance to trigger the 
; alternate end game text.  Or 1 in 32 chance.  
; Rare enough to be surprising when it occurs.
; --------------------------------------------------------------------------

GFX_GAME_OVER_TEXT0
	.sb "     GAME  OVER     "   ; Do this about 96% of the time.
GFX_GAME_OVER_TEXT1
	.sb "     LOOOOOSER!     "
GFX_GAME_OVER_TEXT2
	.sb "    LOOOOOOSERS!    "
GFX_GAME_OVER_TEXT3
	.sb "KLAATU BARADA NIKTO "
GFX_GAME_OVER_TEXT4
	.sb "  IT'S A COOKBOOK!  "
GFX_GAME_OVER_TEXT5
	.sb "RESISTANCE IS FUTILE"	
GFX_GAME_OVER_TEXT6
	.sb "U BASE R BELONG 2 US"	
GFX_GAME_OVER_TEXT7
	.sb "  PWNED EARTHLING!  "
GFX_GAME_OVER_TEXT8
	.sb " GRANDMA DID BETTER!"
GFX_GAME_OVER_TEXT9
	.sb " ARE YOU GONNA CRY? "

TABLE_HI_GFX_GAMEOVER
		.by >GFX_GAME_OVER_TEXT0,>GFX_GAME_OVER_TEXT1
		.by >GFX_GAME_OVER_TEXT2,>GFX_GAME_OVER_TEXT3
		.by >GFX_GAME_OVER_TEXT4,>GFX_GAME_OVER_TEXT5
		.by >GFX_GAME_OVER_TEXT6,>GFX_GAME_OVER_TEXT7
		.by >GFX_GAME_OVER_TEXT8,>GFX_GAME_OVER_TEXT9
		
TABLE_LO_GFX_GAMEOVER
		.by <GFX_GAME_OVER_TEXT0,<GFX_GAME_OVER_TEXT1
		.by <GFX_GAME_OVER_TEXT2,<GFX_GAME_OVER_TEXT3
		.by <GFX_GAME_OVER_TEXT4,<GFX_GAME_OVER_TEXT5
		.by <GFX_GAME_OVER_TEXT6,<GFX_GAME_OVER_TEXT7
		.by <GFX_GAME_OVER_TEXT8,<GFX_GAME_OVER_TEXT9


Gfx_Choose_Game_Over_Text
	lda RANDOM                   ; Get a random value
	cmp #8                       ; Is it 0 to 7?
	bcs b_gcgot_UseDefault       ; Nope.  Then use default.
	
	clc
	adc #2                       ; Turn 0 to 7 into 2 to 9.

	ldx zNUMBER_OF_PLAYERS       ; Is this 1 (0) or 2 (1)  players 
	bne b_gcgot_Continue         ; Not 1 player.  We're done with index.
	
	sbc #1                       ; Remove 1 from index to use single loser message.
	bne b_gcgot_Continue         ; Skip over forced default.

b_gcgot_UseDefault
	lda #0                       ; Force default message
	
b_gcgot_Continue
	tax 
	
	lda TABLE_LO_GFX_GAMEOVER,X  ; Save address of the chosen text.
	sta zGAME_OVER_TEXT
	lda TABLE_HI_GFX_GAMEOVER,X
	sta zGAME_OVER_TEXT+1
	
	rts	
