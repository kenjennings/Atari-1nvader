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
; Change the Title screen's LMS pointer to the graphics for the big logo
; on the screen.  Basically, page flipping.   Change one pointer to 
; change what the screen displays rather than copy hundreds of bytes.
; The VBI decremented the countdown clock for animation, so remember to 
; reset it here.
; --------------------------------------------------------------------------

TABLE_GFX_TITLE_LOGO        ; Stored in reverse order for less iteration code.
	.word GFX_TITLE_FRAME4
	.word GFX_TITLE_FRAME3
	.word GFX_TITLE_FRAME2
	.word GFX_TITLE_FRAME1

Gfx_Animate_Title_Logo

	lda #TITLE_SPEED_GFX         ; Reset the countdown clock.  (VBI decremented it)
	sta zAnimateTitleGfx

	dec zTITLE_LOGO_FRAME        ; Subtract frame counter.
	lda zTITLE_LOGO_FRAME
	bpl b_gatl_SkipReset         ; If it did not go negative, then it is good.

	lda #TITLE_LOGO_FRAME_MAX    ; Reset frame counter 

b_gatl_SkipReset
	sta zTITLE_LOGO_FRAME        ; to max value.
	asl                          ; *2 for word size
	tax                          ; Now use the  value *2 as index.
	lda TABLE_GFX_TITLE_LOGO,X   ; Get the new graphics address low byte
	sta DL_LMS_TITLE             ; and update the display list LMS.
	lda TABLE_GFX_TITLE_LOGO+1,X ; Get the new graphics address high byte
	sta DL_LMS_TITLE+1           ; and update the display list LMS.

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
	.sb "  G A M E  O V E R  "   ; Do this about 96% of the time.
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


; ==========================================================================
; GAME SCREEN FLICKERING STARS
; ==========================================================================
; At any time there are 4 stars on screen.
; Each star lasts 8 frames until it is replaced.
; When the star fades out a new star is added.
; On the Atari this fade out will be a little more animated.
; The star has a little gradient applied where the top and bottom
; sparkle pixels fade out faster than the center line pixels.
; 
; Frame:  Top/Bot:   Middle:  (colors for fading)
;    8      $0E        $0E     1
;    7      $*C        $0E     1
;    6      $*A        $0E     1  2 
;    5      $*8        $*C     1  2  
;    4      $*6        $*A     1  2  3  
;    3      $*4        $*8     1  2  3
;    2      $*2        $*6     1  2  3  4
;    1      $02        $*4     1  2  3  4
;    0 reset to 8.
;   ...     ...        ...
;
; Positioning the stars is different.   Every mode 6 line on the screen for
; the stars refers to (LMS) the same line of screen data.  LMS and horizontal
; fine scrolling will be used to position the stars on the row where they 
; appear.
;
; The first 21 bytes of data are blank which is used to show no star. 
; That is, LMS=Line+0, and HSCROLL=15.  
; The star character is at position 22 on the line.
; The star will be displayed by varying the horizontal scroll offset 
; and fine-scroll (HSCROL) value.  This allows per pixel positioning,
; but uses the memory for only the one line of text characters. 
; Where a star appears the starting position for the LMS will be 
; random from 2 to 22 (Or LMS+1 to LMS+21).   Do this by choosing a
; random number, then mask it (bitwise AND) with %3F.  The resulting 
; value, 0 to 63, is used as the index to a lookup table to convert it 
; to the value divided by 3.  The zero equivalants (0, 1, 2) will map
; to 4, 11, 1.
; Horizontal fine scrolling will be a random number from 0 to 15. 
;
; The custom VBI will keep track of the four lines showing the stars.
; It will transition the color for each star fading per each frame. 
; When the  transition reaches frame 11, the star is removed from 
; the screen (fade color table lookups = 0, LMS offset = +0 and HSCROL=15).
;
; A new random line is chosen for the star.  
; Pick a random number from 0 to 15.
; If this row is in use then use the next row and continue incrementing
; until an unused row is found.
; --------------------------------------------------------------------------


; VBI USAGE . . . .

TABLE_GFX_STAR_COLOR_MASK1 
	.byte $00,$02,$F2,$F4,$F6,$F8,$FA,$FC,$0E

TABLE_GFX_STAR_COLOR_MASK2
	.byte $00,$F4,$F6,$F8,$FA,$FC,$0E,$0E,$0E


; Flag if the star is in use.  
; $FF is no star in use. 
; Otherwise contains Index to the 18 line tables.  (0 to 15)
TABLE_GFX_ACTIVE_STARS .byte $FF,$FF,$FF,$FF

; Base color for the star.
TABLE_GFX_STAR_BASE .byte 0,0,0,0

; Clock counter for each star. 8, 7, 6, 5, 4, 3, 2, 1, 0.  At 0, star goes off.
TABLE_GFX_STARS_COUNT .byte 0,0,0,0


; DLI Usage . . . .

; Is this start running on this row?   If not, then a lot of DLI can be shortcut.
TABLE_GFX_STAR_WORKING
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
; For testing purposes, they're all on now.
	.byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; A list of the outer color value for each star line (only matters on the lines with stars)
TABLE_GFX_STAR_OUT_COLOR
	.byte $14,$24,$34,$44,$54,$64,$74,$84,$94,$a4,$b4,$c4,$d4,$e4,$f4,$04

; A list of the inner color value for each star line (only matters on the lines with stars)
TABLE_GFX_STAR_IN_COLOR
	.byte $1e,$2e,$3e,$4e,$5e,$6e,$7e,$8e,$9e,$ae,$be,$ce,$de,$ee,$fe,$0e

; A list of the fine scroll values for each start line used for pixel positioning.
TABLE_GFX_STAR_HSCROL
		.byte 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

TABLE_LO_GFX_LMS_STARS
?TEMP_DL_ADDRESS=DL_LMS_FIRST_STAR
	.rept 16
		.byte <[?TEMP_DL_ADDRESS]
?TEMP_DL_ADDRESS += 4
	.endr

TABLE_HI_GFX_LMS_STARS
?TEMP_DL_ADDRESS=DL_LMS_FIRST_STAR+1
	.rept 16
		.byte >[?TEMP_DL_ADDRESS]
?TEMP_DL_ADDRESS += 4
	.endr

TABLE_GFX_STARS_DIVIDE_THREE
	.by <[GFX_STARS_LINE+1],[<GFX_STARS_LINE+1],<[GFX_STARS_LINE+1]    ; (00) (0   1  2)
	.by <[GFX_STARS_LINE+2],<[GFX_STARS_LINE+2],<[GFX_STARS_LINE+2]    ; (01) (3   4  5)
	.by <[GFX_STARS_LINE+3],<[GFX_STARS_LINE+3],<[GFX_STARS_LINE+3]    ; (02) (6   7  8)
	.by <[GFX_STARS_LINE+4],<[GFX_STARS_LINE+4],<[GFX_STARS_LINE+4]    ; (03) (9  10 11)
	.by <[GFX_STARS_LINE+5],<[GFX_STARS_LINE+5],<[GFX_STARS_LINE+5]    ; (04) (12 13 14)
	.by <[GFX_STARS_LINE+6],<[GFX_STARS_LINE+6],<[GFX_STARS_LINE+6]    ; (05) (15 16 17)
	.by <[GFX_STARS_LINE+7],<[GFX_STARS_LINE+7],<[GFX_STARS_LINE+7]    ; (06) (18 19 20)
	.by <[GFX_STARS_LINE+8],<[GFX_STARS_LINE+8],<[GFX_STARS_LINE+8]    ; (07) (21 22 23)
	.by <[GFX_STARS_LINE+9],<[GFX_STARS_LINE+9],<[GFX_STARS_LINE+9]    ; (08) (24 25 26)
	.by <[GFX_STARS_LINE+10],<[GFX_STARS_LINE+10],<[GFX_STARS_LINE+10] ; (09) (27 28 29)
	.by <[GFX_STARS_LINE+11],<[GFX_STARS_LINE+11],<[GFX_STARS_LINE+11] ; (10) (30 31 32)
	.by <[GFX_STARS_LINE+12],<[GFX_STARS_LINE+12],<[GFX_STARS_LINE+12] ; (11) (33 34 35)
	.by <[GFX_STARS_LINE+13],<[GFX_STARS_LINE+13],<[GFX_STARS_LINE+13] ; (12) (36 37 38)
	.by <[GFX_STARS_LINE+14],<[GFX_STARS_LINE+14],<[GFX_STARS_LINE+14] ; (13) (39 40 41)
	.by <[GFX_STARS_LINE+15],<[GFX_STARS_LINE+15],<[GFX_STARS_LINE+15] ; (14) (42 43 44)
	.by <[GFX_STARS_LINE+16],<[GFX_STARS_LINE+16],<[GFX_STARS_LINE+16] ; (15) (45 46 47)
	.by <[GFX_STARS_LINE+17],<[GFX_STARS_LINE+17],<[GFX_STARS_LINE+17] ; (16) (48 49 50)
	.by <[GFX_STARS_LINE+18],<[GFX_STARS_LINE+18],<[GFX_STARS_LINE+18] ; (17) (51 52 53)
	.by <[GFX_STARS_LINE+19],<[GFX_STARS_LINE+19],<[GFX_STARS_LINE+19] ; (18) (54 55 56)
	.by <[GFX_STARS_LINE+20],<[GFX_STARS_LINE+20],<[GFX_STARS_LINE+20] ; (19) (57 58 59)
	.by <[GFX_STARS_LINE+21],<[GFX_STARS_LINE+21],<[GFX_STARS_LINE+21] ; (20) (60 61 62)
	.by <[GFX_STARS_LINE+11]                                           ; (21) (63)





; ==========================================================================
; CHOOSE STAR ROW
; ==========================================================================
; Choose a row for stars.
;  
; A new random line is chosen for the star.  Pick a random number from 
; 0 to 15 (mask random value with binary AND $0F).  
; If this row is in use then use the next row and continue incrementing
; until an unused row is found.
;
; On exit, A is the new row.
; --------------------------------------------------------------------------

Gfx_Choose_Star_Row

	lda RANDOM
	and #$0f                     ; Reduce to 0 to 15

b_gcsr_StartCheckLoop
	ldy #3                       ; Index 3, 2, 1, 0 for star list

b_gcsr_CompareEntry
	cmp TABLE_GFX_ACTIVE_STARS,y ; Compare to each current star, 
	bne b_gcsr_TryNextEntry      ; Does not match, so test next entry.
	
	clc                          ; Oops.  Found a matching value. 
	adc #1                       ; Increment the value and then redo the checking.
	
	cmp #16                      ; Did we reach row 16? 
	bne b_gcsr_StartCheckLoop    ; No.  So, restart the loop to check values.
	
	lda #0                       ; Yes.  Reset to 0.  
	beq b_gcsr_StartCheckLoop    ; restart the loop to check values.

b_gcsr_TryNextEntry
	dey
	bpl b_gcsr_CompareEntry

	rts
	


; ==========================================================================
; SERVICE STAR
; ==========================================================================
; Run the Star color fade Animation.
;
; Given the new star number (0 to 3)
;  - Decrement counter.
;  - Fade the star.
;  - if the current frame is 0, then call Remove_Star for this star.
;  - If the current frame is 6, set flag to restart a star.
;
; ==========================================================================
;
; At any time there are 4 stars on screen.
; Each star lasts 8 frames until it is replaced.
; When the star fades out a new star is added.
; On the Atari this fade out will be a little more animated.
; The star has a little gradient applied where the top and bottom
; sparkle pixels fade out faster than the center line pixels.
; 
; Frame:  Top/Bot:   Middle:  (colors for fading)
;    8      $0E        $0E     1
;    7      $*C        $0E     1
;    6      $*A        $0E     1  2 
;    5      $*8        $*C     1  2  
;    4      $*6        $*A     1  2  3  
;    3      $*4        $*8     1  2  3
;    2      $*2        $*6     1  2  3  4
;    1      $02        $*4     1  2  3  4
;    0 reset to 8.
;   ...     ...        ...
;
; X is the star number 0, 1, 2, 3 for the short lookup.
; --------------------------------------------------------------------------

Gfx_Service_Star

	stx zTEMP_NEW_STAR_ID            ; Save Star number

	lda TABLE_GFX_ACTIVE_STARS,X     ; A == the star's row
	sta zTEMP_NEW_STAR_ROW           ; Save for later.
	bmi b_gss_Exit                   ; This entry is not a real row, so there's nothing to do.

	dec TABLE_GFX_STARS_COUNT,X      ; Decrement the frame counter.
	bne b_gss_CheckClock6            ; (or bpl?) Clock not zero, so ok to continue.

	jmp Gfx_Remove_Star              ; Remove the current star in X.  and that will RTS.

	; Due to the staggered flashing the new star stars when the previous 
	; star reaches frame 6  (another star will reach 0  in this cycle).
	; Yes, this is kind of redundant, but whatever.

b_gss_CheckClock6               
	ldy TABLE_GFX_STARS_COUNT,X      ; Get the clock for this star
	cpy #6                           ; is it 6?
	bne b_gss_ProcessColor           ; No.  So, continue with color processing.
	
	inc zTEMP_ADD_STAR               ; If this is on frame 6, then it is time for a new star.
	
b_gss_ProcessColor
	ldy TABLE_GFX_STARS_COUNT,X      ; Index to color masks.
	lda TABLE_GFX_STAR_BASE,X        ; Base color for star.
	sta zTEMP_BASE_COLOR             ; Save it for re-use for outer color.
	sta zTEMP_BASE_COLOR2            ; Save it for re-use for inner color.
	
	lda TABLE_GFX_STAR_COLOR_MASK1,Y ; Mask to hold or drop the base color
	and #$F0                         ; Either keeps the color or removes it
	and zTEMP_BASE_COLOR             ; Combine with saved color.
	sta zTEMP_BASE_COLOR             ; Save updated color.
	lda TABLE_GFX_STAR_COLOR_MASK1,Y ; Mask to hold or drop the base color
	and #$0F                         ; Keep the luminance
	ora zTEMP_BASE_COLOR             ; Merge with base color.
	ldy TABLE_GFX_STARS_COUNT,X      ; Get the row.
	sta TABLE_GFX_STAR_OUT_COLOR,Y   ; Save the new outer color.
	
	lda zTEMP_BASE_COLOR2            ; Save it for re-use.
	lda TABLE_GFX_STAR_COLOR_MASK2,Y ; Mask to hold or drop the base color
	and #$F0                         ; Either keeps the color or removes it
	and zTEMP_BASE_COLOR2            ; Combine with saved color.
	sta zTEMP_BASE_COLOR2            ; Save updated color.
	lda TABLE_GFX_STAR_COLOR_MASK2,Y ; Mask to hold or drop the base color
	and #$0F                         ; Keep the luminance
	ora zTEMP_BASE_COLOR2            ; Merge with base color.
	ldy TABLE_GFX_STARS_COUNT,X      ; Get the row.
	sta TABLE_GFX_STAR_IN_COLOR,Y    ; Save the new inner color.
		
b_gss_Exit
	rts
	

; ==========================================================================
; SETUP NEW STAR
; ==========================================================================
; Get a new star row.
; Prior to calling this Remove_Star should be called.
;  
; Given the new star number (0 to 3)
;  - Choose a random row, 
;  - Setup the star position
;  - Setup the star color.
;  - Setup the star clock counter.
;
; X is the star number 0, 1, 2, 3 for the short lookup.
;
; --------------------------------------------------------------------------

Gfx_Setup_New_Star
	
	stx zTEMP_NEW_STAR_ID              ; Save Star number
	
	ldy TABLE_GFX_ACTIVE_STARS,X       ; Y == the star's row
	bpl b_gsns_Exit                    ; This entry is not row $FF, so we can't remake it. 
	
	jsr Gfx_Choose_Star_Row            ; A = random row number.
	
	sta TABLE_GFX_ACTIVE_STARS,X       ; Save the new row.
	tay                                ; Y = Row.
	
	lda #8
	sta TABLE_GFX_STARS_COUNT,X        ; Reset the clock for the star
	
	lda RANDOM                         ; Get a random color for the star
	and #$F0                           ; Interested in only the color component.
	sta TABLE_GFX_STAR_BASE,X          ; Save Base color.

	lda #$FF                           ; Still Starting out with white.
	sta TABLE_GFX_STAR_OUT_COLOR,Y     ; Set top/bottom sparkle color
	sta TABLE_GFX_STAR_IN_COLOR,Y      ; Set center star color

	lda RANDOM                         ; Random value for star HSCROL 
	and #$0F                           ; Reduce to 0 to 15
	sta TABLE_GFX_STAR_HSCROL,Y        ; Output all color clocks in the buffer

	lda TABLE_LO_GFX_LMS_STARS,Y       ; Address of this row's LMS 
	sta zDL_LMS_STARS_ADDR             ; Save to page 0 for pointer
	lda TABLE_HI_GFX_LMS_STARS,Y   
	sta zDL_LMS_STARS_ADDR+1

	lda RANDOM                         ; Random value for star positiion.
	and #$3f                           ; Reduce to 0 - 63
	tay                                ; Y = 0 to 63 for conversion lookup.
	lda TABLE_GFX_STARS_DIVIDE_THREE,Y ; Convert to screen LMS low byte value
	ldy #0
	sta (zDL_LMS_STARS_ADDR),Y         ; Change the LMS to point at the line
	
b_gsns_Exit
	rts
	
	
	
; ==========================================================================
; REMOVE STAR
; ==========================================================================
; Remove a star from the management data.
; At the end of this the designated star will be black color and
; moved to a scroll position off the screen.   The configuration 
; data will be left to indicate no star is in use on that row.
;  
; Given the star number (0 to 3)
;  - Zero the color values. 
;  - Zero the LMS.  
;  - Set HSCROL 15.
;  - Set the Star number row to $FF
;
; X is the star number 0, 1, 2, 3 for the short lookup.
; --------------------------------------------------------------------------

Gfx_Remove_Star

	ldy TABLE_GFX_ACTIVE_STARS,X   ; Y == the star's row

	lda #$FF
	sta TABLE_GFX_ACTIVE_STARS,X   ; Turn off this star.

	lda #8
	sta TABLE_GFX_STARS_COUNT,X    ; Reset the clock for the row

	lda #0                         ; Color = Black
	sta TABLE_GFX_STAR_BASE,X      ; Base color for star
	sta TABLE_GFX_STAR_OUT_COLOR,Y ; Star's center color
	sta TABLE_GFX_STAR_IN_COLOR,Y  ; Star's edge pixels color

	lda #15
	sta TABLE_GFX_STAR_HSCROL,Y    ; Output all color clocks in the buffer

	lda TABLE_LO_GFX_LMS_STARS,Y   ; Address of this row's LMS 
	sta zDL_LMS_STARS_ADDR         ; Save to page 0 for pointer
	lda TABLE_HI_GFX_LMS_STARS,Y   
	sta zDL_LMS_STARS_ADDR+1

	lda #<GFX_STARS_LINE           ; Low byte to the start of the stars line
	ldy #0
	sta (zDL_LMS_STARS_ADDR),Y     ; Change the LMS to the start of line

	inc zTEMP_ADD_STAR             ; Flag that this star is gone.  Add new star at next opportunity.

	rts


; ==========================================================================
; RUN GAME SCREEN STARS
; ==========================================================================
; Cycle through stars 0 to 3.
; Run the service routine.
; --------------------------------------------------------------------------

Gfx_RunGameStars

	ldx #0

b_grgs_LoopEachStar
	jsr Gfx_Service_Star
	
	inx
	cpx #4
	
	bne b_grgs_LoopEachStar

	rts


; ==========================================================================
; DRAW COUNTDOWN
; ==========================================================================
; Given the value of the flag, copy the 4 bytes from the 
; array to the screen.
; Update the clock ticks for the text pause.
; Decrement the Flag for the next Big Countdown.
; Engage the clock tick sound IF this did not run out of countdown.
; --------------------------------------------------------------------------

GFX_COUNTDOWN_TEXT  ; 4, 3, 2, 1, 0 (multiply times 4, copy 4.
	.sb +$C0 "!OG!...1...2...3    "

GFX_COUNTDOWN_TICK ; Jiffy ticks to wait for this text
	.byte 90,90,90,90,1


Gfx_DrawCountdown

	ldy zCOUNTDOWN_FLAG      ; Get current index to text for countdown.
	bmi b_gcd_ExitCountdown  ; If negative, do nothing.

;	cpy #4                   ; Also, if it is already 4, I want to make sure clock is right
;	beq b_gcd_DoReset        ; (this is at the blank text, so only 1 tick for the clock.)
;	bpl b_gcd_SkipReset      ; Every other value.

;b_gcd_SkipReset
	lda GFX_COUNTDOWN_TICK,y
	sta zCOUNTDOWN_SECS 

	tya                      ; A = index
	asl                      ; index * 2
	asl                      ; index * 4
	tay	                     ; Y = index * 4 for copying.
	ldx #3                   ; index into Gfx memeory.

b_gcd_CopyText
	lda GFX_COUNTDOWN_TEXT,y ; From text array.
	sta GFX_COUNTDOWN,x      ; To screen memory
	iny                      ; Copying forwards from array.
	dex                      ; Copying backwards to screen memory.
	bpl b_gcd_CopyText       ; 3, 2, 1, 0

;	dec zCOUNTDOWN_FLAG      ; The value to use for display next time.
;	bmi b_gcd_ExitCountdown  ; If we reached the end, do not play sound
	; ldy #COUNTDOWN_TICKTOCK
	; jsr PlaySound 

b_gcd_ExitCountdown
	lda zCOUNTDOWN_FLAG

	rts



; ==========================================================================
; RUN SCROLLING LAND
; ==========================================================================
; Used by VBI on all screens. 
;
; Scroll all four lines of terrain back and forth.
; All four move in the same direction/same speed.
; Pause for a few seconds at the end of a move.
; Then reverse directions.
; Rinse.  Repeat.
;
; 1) If waiting, continue to wait.
; 2) if not waiting, then do motion.  
; 3) Wait for motion timer.
; 4) Execute motion. Either
; 4)a) Move Left, OR
; 4)b) Move Right. 
; 5) At end, then reset
; 5)a) toggle motion direction.
; 5)b) restart the waiting phase.
; --------------------------------------------------------------------------

Gfx_RunScrollingLand

	lda #0
	sta zLandColor

	lda zLandPhase            ; 0 == waiting    1  == scrolling
	bne b_grsl_RunLandScrolling

	; Waiting....
	dec zLandTimer
	bne b_grsl_EndLandScrolling  ; Timer still >0

	; Reset timer.  And start scrolling.
	inc zLandPhase             ; To get here we know this was 0.
	lda #LAND_MAX_PAUSE
	sta zLandTimer
	
	; We are moving the credits...

b_grsl_RunLandScrolling

	dec zLandScrollTimer      ; Delay to not scroll to quickly.
	bne b_grsl_EndLandScrolling

	lda #LAND_STEP_TIMER      ; Reset the scroll timer
	sta zLandScrollTimer

	lda zLandMotion           ; What direction are we moving in?
	beq b_grsl_LandLeft        ; 0 is moving Left

	; Otherwise, we're going in the opposite direction here.  (Right)

	inc zLandHS                ; Land Right
	lda zLandHS
	cmp #16                    ; Reach the end of fine scrolling 16 color clocks?
	bne b_grsl_EndLandScrolling ; No, Nothing else to do here.
	lda #0                     ; Yes. 
	sta zLandHS                ; Reset the fine scroll, and...
	dec DL_LMS_SCROLL_LAND1    ; Coarse scroll the text... 8 color clocks.
	dec DL_LMS_SCROLL_LAND1    ; and another 8 color clocks.
	dec DL_LMS_SCROLL_LAND2    ; Coarse scroll the text... 8 color clocks.
	dec DL_LMS_SCROLL_LAND2    ; and another 8 color clocks.
	dec DL_LMS_SCROLL_LAND3    ; Coarse scroll the text... 8 color clocks.
	dec DL_LMS_SCROLL_LAND3    ; and another 8 color clocks.
	dec DL_LMS_SCROLL_LAND4    ; Coarse scroll the text... 8 color clocks.
	dec DL_LMS_SCROLL_LAND4    ; and another 8 color clocks.

b_grsl_TestEndRight              ; Check the Land's end position.
	lda zLandHS                 ; Get fine scroll position.  0 is the end
	bne b_grsl_EndLandScrolling  ; Not 0..  We're done with checking.
	lda DL_LMS_SCROLL_LAND1     ; Get the coarse scroll position
	cmp #<[GFX_MOUNTAINS1]      ; at the ending coarse scroll position?
	bne b_grsl_EndLandScrolling  ; nope.  We're done with checking.

	; reset to do left, then re-enable the pause
	dec zLandMotion           ; It was 1 to do right scrolling. Make it 0 for left.
	dec zLandPhase            ; It was 1 to do scrolling.  switch to waiting.
	bne b_grsl_EndLandScrolling ; Finally done with this scroll direction. 

;  we're going in the Left direction. 

b_grsl_LandLeft
	dec zLandHS                    ; Land 1 Left
	bmi b_grsl_HSReset              ; At -1 means time to reset HSCROLL
	beq b_grsl_TestEndLeft          ; if 0, then possibly at an end boundary.  Go test for end.
	bne b_grsl_EndLandScrolling     ; Not 0, then not at a boundary test, so nothing more to do.

b_grsl_HSReset	                   ; Reached -1 for fines croll.  Coarse Scroll and reset.
	inc DL_LMS_SCROLL_LAND1        ; Coarse scroll the text... 8 color clocks.
	inc DL_LMS_SCROLL_LAND1        ; and another 8 color clocks.
	inc DL_LMS_SCROLL_LAND2        ; Coarse scroll the text... 8 color clocks.
	inc DL_LMS_SCROLL_LAND2        ; and another 8 color clocks.
	inc DL_LMS_SCROLL_LAND3        ; Coarse scroll the text... 8 color clocks.
	inc DL_LMS_SCROLL_LAND3        ; and another 8 color clocks.
	inc DL_LMS_SCROLL_LAND4        ; Coarse scroll the text... 8 color clocks.
	inc DL_LMS_SCROLL_LAND4        ; and another 8 color clocks.
	lda #15                        ; Reset to start HSCROLL
	sta zLandHS                    ; Reset the fine scroll, and...
	bne b_grsl_EndLandScrolling     ; Nothing more to do.

b_grsl_TestEndLeft                  ; At HSCROL 0.  This may be a boundary.
	lda DL_LMS_SCROLL_LAND1        ; Get the coarse scroll position
	cmp #<[GFX_MOUNTAINS1+20]      ; at the ending coarse scroll position?
	bne b_grsl_EndLandScrolling     ; Nothing more to do.

	; reset to do right, then re-enable the pause.
	inc zLandMotion           ; It was 0 to do left.  Make it non-zero for right scrolling.
	dec zLandPhase            ; It was 1 to do scrolling.  switch to waiting.
	bne b_grsl_EndLandScrolling ; Finally done with this scroll direction. 

b_grsl_EndLandScrolling

rts



; ==========================================================================
; SHOW SCREEN
; ==========================================================================
; If the Score Redraw flag is set, update the Players and High scores 
; on screen.  Forgoing the BCD packed bytes in the original.  This 
; simplifies the copy to the screen.  The scores use 6 individual 
; bytes, one for each decimal position, not three bytes of packed BCD.
; --------------------------------------------------------------------------

Gfx_ShowScreen

	lda zSHOW_SCORE_FLAG
	bne b_gss_ShowChars ; shsca

	rts ;     jmp shscz


; shsca    
b_gss_ShowChars 
	lda #0      ; turn flag off
	sta zSHOW_SCORE_FLAG


 ; check p1 score for hi score
 
 	ldy #0

b_gss_LoopCompareP1
	lda zHIGH_SCORE,y
	cmp zPLAYER_ONE_SCORE,y
	beq b_gss_ContinueCheckingP1Score ; They are the same.  Try more.
	bcc b_gss_CopyP1ToHiScore ; HiScore Less Than P1 Score.
	bcs b_gss_CheckP2Score; chkhip2 ; Not greater than

b_gss_ContinueCheckingP1Score
	iny
	cpy #6
	bne b_gss_LoopCompareP1
	beq b_gss_CheckP2Score


b_gss_CopyP1ToHiScore
	ldy #5

b_gss_LoopCopyP1ToHiScore
	lda zPLAYER_ONE_SCORE,y
	sta zHIGH_SCORE,y

	dey
	bpl b_gss_LoopCopyP1ToHiScore


b_gss_CheckP2Score
; chkhip2  ; check p2 score for hiscore

 	ldy #0

b_gss_LoopCompareP2
	lda zHIGH_SCORE,y
	cmp zPLAYER_TWO_SCORE,y
	beq b_gss_ContinueCheckingP2Score ; They are the same.  Try more.
	bcc b_gss_CopyP2ToHiScore ; HiScore Less Than P2 Score.
	bcs b_gss_ShowScoresOnScreen; chkhip2 ; Not greater than

b_gss_ContinueCheckingP2Score
	iny
	cpy #6
	bne b_gss_LoopCompareP2
	beq b_gss_ShowScoresOnScreen


b_gss_CopyP2ToHiScore
	ldy #5

b_gss_LoopCopyP2ToHiScore
	lda zPLAYER_TWO_SCORE,y
	sta zHIGH_SCORE,y

	dey
	bpl b_gss_LoopCopyP2ToHiScore


; chkhiz   ; done hiscore check

; Copy all the scores to the graphics memory.

b_gss_ShowScoresOnScreen
; shscc    ; show high score.

	ldy #5

b_gss_LoopCopyScores
	lda zPLAYER_ONE_SCORE,y
	ora #$40                ; Turn $0 to $9 into $40 to $49
	sta GFX_SCORE_P1,y

	lda zPLAYER_TWO_SCORE,y
	ora #$40                ; Turn $0 to $9 into $40 to $49
	sta GFX_SCORE_P2,y

	lda zHIGH_SCORE,y
	ora #$40                ; Turn $0 to $9 into $40 to $49
	sta GFX_SCORE_HI,y

	dey
	bpl b_gss_LoopCopyScores

; shscz    
	rts

