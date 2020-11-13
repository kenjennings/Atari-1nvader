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
	.byte <GFX_TITLE_FRAME4
	.byte <GFX_TITLE_FRAME3	
	.byte <GFX_TITLE_FRAME2
	.byte <GFX_TITLE_FRAME1

Gfx_Animate_Title_Logo

	lda #TITLE_SPEED_GFX         ; Reset the countdown clock.  (VBI decremented it)
	sta zAnimateTitleGfx

	dec zTITLE_LOGO_FRAME        ; Subtract frame counter.
	bpl b_gatl_SkipReset         ; If it did not go negative, then it is good.
	
	ldx #TITLE_LOGO_FRAME_MAX    ; Reset frame counter 
	stx zTITLE_LOGO_FRAME        ; to max value.
	
b_gatl_SkipReset
	ldx zTITLE_LOGO_FRAME        ; Actually read the value to use as index.
	lda TABLE_GFX_TITLE_LOGO,X   ; Get the new graphics address low byte
	sta DL_LMS_TITLE             ; and update the display list LMS.

b_gatl_SkipTitleGfx
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
; A new random line is chosen for the star.  Pick a random number from 
; 0 to 31 (mask random value with binary AND $1F).  
; If greater than 17, then subtract 16. (31 - 16 == 15.   18 - 16 = 2).
; If this row is in use then use the next row and continue incrementing
; until an unused row is found.
; --------------------------------------------------------------------------

; 
TABLE_GFX_STAR_COLOR_MASK1 
	.byte $00,$02,$F2,$F4,$F6,$F8,$FA,$FC,$0E

TABLE_GFX_STAR_COLOR_MASK2
	.byte $00,$F4,$F6,$F8,$FA,$FC,$0E,$0E,$0E
	

; Flag if the star is in use.  
; $FF is no star in use. 
; Otherwise contains Index to the 18 line tables.  (0 to 17)
TABLE_GFX_ACTIVE_STARS .byte $FF,$FF,$FF,$FF

; Base color for the star.
TABLE_GFX_STAR_BASE .byte 0,0,0,0

; Clock counter for each star. 8, 7, 6, 5, 4, 3, 2, 1, 0.  At 0, star goes off.
TABLE_GFX_STARS_COUNT .byte 0,0,0,0

; A list of the outer color value for each star line (only matters on the lines with stars)
TABLE_GFX_STAR_OUT_COLOR
	.rept 18 
		.byte 0
	.endr

; A list of the inner color value for each star line (only matters on the lines with stars)
TABLE_GFX_STAR_IN_COLOR
	.rept 18 
		.byte 0
	.endr

; A list of the fine scroll values for each start line used for pixel positioning.
TABLE_GFX_STAR_HSCROL
	.rept 18 
		.byte 0
	.endr	

TABLE_LO_GFX_LMS_STARS
?TEMP_DL_ADDRESS=DL_LMS_FIRST_STAR
	.rept 18
		.byte <[?TEMP_DL_ADDRESS]
?TEMP_DL_ADDRESS += 3
	.endr

TABLE_HI_GFX_LMS_STARS
?TEMP_DL_ADDRESS=DL_LMS_FIRST_STAR+1
	.rept 18
		.byte >[?TEMP_DL_ADDRESS]
?TEMP_DL_ADDRESS += 3
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
; 0 to 31 (mask random value with binary AND $1F).  
; If greater than 17, then subtract 16. (31 - 16 == 15.   18 - 16 = 2).
; If this row is in use then use the next row and continue incrementing
; until an unused row is found.
;
; On exit, A is the new row.
; --------------------------------------------------------------------------

Gfx_Choose_Star_Row

	lda RANDOM
	and #$1F                     ; Reduce to 0 to 31

	cmp #18                      ; Is it greater then 17?
	bcc b_gcsr_StartCheckLoop    ; No. Skip the subtract.  
	clc
	sbc #16                      ; Minus 16

b_gcsr_StartCheckLoop
	ldy #3                       ; Index 3, 2, 1, 0 for star list

b_gcsr_CompareEntry
	cmp TABLE_GFX_ACTIVE_STARS,y ; Compare to each current star, 
	bne b_gcsr_TryNextEntry      ; Does not match, so test next entry.
	
	clc                          ; Oops.  Found a matching value. 
	adc #1                       ; Increment the value and then redo the checking.
	
	cmp #18                      ; Did we reach row 18? 
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
	
