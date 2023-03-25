;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2023 Ken Jennings
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
; SET NTSC OR PAL
; ==========================================================================
; Determine video standard.   
; Set some flags used later in the game.
; 
; Return A  (or CPU Z) == PAL or NTSC flag. 
; Clear (xxxx000x) = 0 = PAL/SECAM, Set (xxxx111x) = 1 = NTSC
; --------------------------------------------------------------------------

Gfx_SetNTSCorPAL

	lda PAL
	and #MASK_NTSCPAL_BITS ; Clear (xxxx000x) = PAL/SECAM, Set (xxxx111x) = NTSC
	beq b_gsnop_UpdateFlag ; Value %0.  Write as-is.
	lda #1                 ; I want NTSC to be be only %1, not %00001110
b_gsnop_UpdateFlag
	sta gNTSCorPAL

	tax

	lda TABLE_NTSC_OR_PAL_FRAMES,x
	sta gMaxNTSCorPALFrames

	lda gNTSCorPAL
	rts


; ==========================================================================
; ANIMATE TITLE LOGO
; ==========================================================================
; Change the Title screen's LMS pointer to the graphics for the big logo
; on the screen.  Basically, this is page flipping.
; This is called when the VBI timer runs out controlling the graphics 
; animation speed.
; The VBI decremented the countdown clock for animation, so remember to 
; reset it here.
;
; Originally, when using the ANTIC vscroll bug to create 3 scanline 
; mode in GTIA there was only one LMS address to update.  
; HOWEVER, a tester noticed that MistPGA has a glitchy title display 
; which looks like the device has a failure to understand operation of 
; the ANTIC vscroll bug.  
; There is no need for cleverness here to save DMA time. The VSCROLL 
; version still needed a DLI to run continuously for 18 scan lines to
; manage the VSCROLL hack timing and set the COLPF3 colors. Thus no real 
; time was saved by using the hack to remove excess LMS instructions.
;
; For maximum compatibility the code is reverted to a conventional DLI 
; with LMS instruction to repeat lines of screen data.
; Doing so eliminates the VSCROLL code in the DLI leaving a small DLI 
; activity to set once every 3 scan lines to set  the fifth player 
; (COLPF3) color. 
;
; Animation of the graphics now means that the LMS addresses for 
; 18 scan lines of display needs to be updated. HOWEVER, this does not 
; mean 18 updates.  Since the data is sequential then at the end of the 
; third repeated line ANTIC will continue reading the next line 
; automatically, so, every third line does not need LMS.  This 
; works out to only 13 LMS addresses that need to be updated. 
;
; Also, since each frame of graphics is aligned to a page, the 
; addresses for all the data on a given screen have the same high 
; byte value.   AND, since each frame is aligned to a page the low 
; bytes are the same for each line of graphics data from frame to frame.  
; Therefore, only the high bytes need to be updated for the LMS 
; instructions and they will all be updated to the same high 
; byte value for the page. 
;
; In conclusion, there is only one load, and 13 stores to update the 
; logo animation where the worst case could have been 36 loads and stores.
; --------------------------------------------------------------------------

TABLE_GFX_TITLE_LOGO        ; Stored in reverse order for less iteration code.
	.byte >GFX_TITLE_FRAME4
	.byte >GFX_TITLE_FRAME3
	.byte >GFX_TITLE_FRAME2
	.byte >GFX_TITLE_FRAME1

Gfx_Animate_Title_Logo

	lda #TITLE_SPEED_GFX         ; Reset the countdown clock.  (VBI decremented it)
	sta zAnimateTitleGfx

	dec zTITLE_LOGO_FRAME        ; Subtract frame counter.
	lda zTITLE_LOGO_FRAME
	bpl b_gatl_SkipReset         ; If it did not go negative, then it is good.

	lda #TITLE_LOGO_FRAME_MAX    ; Reset frame counter 

b_gatl_SkipReset
	sta zTITLE_LOGO_FRAME        ; save updated value.
	tax                          ; Now use the  value as index.
	lda TABLE_GFX_TITLE_LOGO,X   ; Get the new graphics address high byte
	sta DL_LMS_TITLE1            ; and update the display list LMS.
	sta DL_LMS_TITLE2            ; and update the display list LMS.
	sta DL_LMS_TITLE3            ; and again
	sta DL_LMS_TITLE4            ; and again
	sta DL_LMS_TITLE5            ; ...
	sta DL_LMS_TITLE6            ; ...
	sta DL_LMS_TITLE7            ; ...
	sta DL_LMS_TITLE8            ; ...
	sta DL_LMS_TITLE9            ; yawn
	sta DL_LMS_TITLE10           ; ...
	sta DL_LMS_TITLE11           ; ...
	sta DL_LMS_TITLE12           ; ...
	sta DL_LMS_TITLE13           ; last LMS high byte to update.

	rts




; ==========================================================================
; CLEAR STATS
; ==========================================================================
; Fill the stats line values with 0 byte/empty space.
;
; Needed for the Title Screen.  Making the stats black is not good
; enough, because the characters are Mode 2 text and will show 
; through the Players used as the idle guns.
; --------------------------------------------------------------------------

Gfx_Clear_Stats

	lda #0
	ldy #25

b_gcs_LoopClearLine

	sta GFX_STATSLINE+8,y
	dey
	bpl b_gcs_LoopClearLine

	rts



; ==========================================================================
; CLEAR SCORES
; ==========================================================================
; Fill the score values on screen with blank spaces/0 bytes.
;
; DOES NOT zero the scores.  This only erases them from display.
; Needed for the countdown animation.  Playtesters commented that the 
; giant mothership flies behind the text.  This is inevitable where 
; Player/Missiles overlap ANTIC Mode 2 COLPF1 text pixels. No changes 
; to priority (PRIOR) can fix this). 
; --------------------------------------------------------------------------

Gfx_Clear_Scores

;	rts

	lda #0
	sta gSCORES_ON

	ldy #$05
b_gcsc_LoopClearSores

	sta GFX_SCORE_P1,y
	sta GFX_SCORE_P2,y
	sta GFX_SCORE_HI,y

	dey
	bpl b_gcsc_LoopClearSores
  
;  	lda #$FC
;b_gss_WriteP1Img
	sta PLAYERADR2+29
	sta PLAYERADR2+30
	sta PLAYERADR2+31
	sta PLAYERADR2+32
	sta PLAYERADR2+33
	sta PLAYERADR2+34

;	lda zPLAYER_TWO_ON
;	beq b_gss_WriteP2Img
;	lda #$FC
;b_gss_WriteP2Img
	sta PLAYERADR3+29
	sta PLAYERADR3+30
	sta PLAYERADR3+31
	sta PLAYERADR3+32
	sta PLAYERADR3+33
	sta PLAYERADR3+34

	rts



; ==========================================================================
; SHOW SCREEN
; ==========================================================================
; Update the Scores and Statistics to the screen.  
;
; I discarded the original game's code that used BCD packed bytes for 
; all the numeric values on screen. 
; Here all the digits are individual bytes with natural values 
; zero through 9. 
; To display these using the proper screen code only requires setting 
; bit $40.
;
; Also, incorporated some additional hackisms:
; * if the stats color is 0, then write blanks instead.
; * If the player is off then write blanks instead for the player's score.
; --------------------------------------------------------------------------

Gfx_ShowScreen

	ldy #$01                        ; Number of digits (+0 and +1)
	sty gSCORES_ON
	
b_gss_CopyStatsLoop
	lda zSTATS_TEXT_COLOR           ; Is stats color off?  (i.e. 0?)
	beq b_gss_WriteStatRow          ; Yes, copy 0 to screen (conveniently, blank space)
	lda gMOTHERSHIP_ROW_AS_DIGITS,y ; No.  Get the actual digit from the score.
	ora #$40                        ; Turn on bit to put it in the write char code.
b_gss_WriteStatRow                   
	sta GFX_STAT_ROW,y              ; Write to statistics.

	lda zSTATS_TEXT_COLOR
	beq b_gss_WriteStatHits
	lda gSHIP_HITS_AS_DIGITS,y
	ora #$40
b_gss_WriteStatHits
	sta GFX_STAT_HITS,y

	dey
	bpl b_gss_CopyStatsLoop


	ldy #$03
b_gss_CopyPointsLoop
	lda zSTATS_TEXT_COLOR
	beq b_gss_WritePoints
	lda gMOTHERSHIP_POINTS_AS_DIGITS+2,y
	ora #$40
b_gss_WritePoints
	sta GFX_STAT_POINTS,y

	dey
	bpl b_gss_CopyPointsLoop


	ldy #$05
b_gss_LoopCopyScores
	lda zPLAYER_ONE_ON      ; If player 1 is on?
	beq b_gss_WriteP1Score  ; No, write the zero byte (blank space) instead.
	lda gPLAYER_ONE_SCORE,y ; Player on, get a digit from the score.
	ora #$40                ; Turn $0 to $9 into $40 to $49
b_gss_WriteP1Score
	sta GFX_SCORE_P1,y

	lda zPLAYER_TWO_ON      ; If player 2 is on?
	beq b_gss_WriteP2Score  ; No, write the zero byte (blank space) instead.
	lda gPLAYER_TWO_SCORE,y ; Player on, get a digit from the score.
	ora #$40                ; Turn $0 to $9 into $40 to $49
b_gss_WriteP2Score
	sta GFX_SCORE_P2,y

	lda gConfigCheatMode    ; Are we in cheat mode?
	bne b_gss_SkipHiScore   ; Yes.  Do not display high score.

	lda gHIGH_SCORE,y       ; Show high score.
	ora #$40                ; Turn $0 to $9 into $40 to $49
	sta GFX_SCORE_HI,y

b_gss_SkipHiScore
	dey
	bpl b_gss_LoopCopyScores
   
; The P/M Graphics overlay for text colors.
	lda zCurrentEvent
	cmp #EVENT_SETUP_GAME
	bcc b_gss_P1on  ; less then setup Game then draw color block regardless.
	
	lda zPLAYER_ONE_ON ; Game mode, then zero  if player off.
	beq b_gss_WriteP1Img
	
b_gss_P1on
	lda #$FC
	
b_gss_WriteP1Img
	sta PLAYERADR2+29
	sta PLAYERADR2+30
	sta PLAYERADR2+31
	sta PLAYERADR2+32
	sta PLAYERADR2+33
	sta PLAYERADR2+34

	lda zCurrentEvent
	cmp #EVENT_SETUP_GAME
	bcc b_gss_P2on  ; less then setup Game then draw color block regardless.
	
	lda zPLAYER_TWO_ON ; Game mode, then zero if player off.
	beq b_gss_WriteP2Img

b_gss_P2on
	lda #$FC
	
b_gss_WriteP2Img
	sta PLAYERADR3+29
	sta PLAYERADR3+30
	sta PLAYERADR3+31
	sta PLAYERADR3+32
	sta PLAYERADR3+33
	sta PLAYERADR3+34

	rts



; ==========================================================================
; SCROLL CREDITS
; ==========================================================================
; Do the credits lines scrolling.
;
; Two lines of author credits.   
; When the first line scrolls left the second line scrolls right.   
; Pause for a few seconds for reading comprehension.
; Then reverse directions.
; Rinse.  Repeat.
; 
; The timer is maintained by the VBI, then it calls this routine.
;
; 1) (VBI) If waiting, continue to wait.
; 2) (VBI) if not waiting, then do motion.  
; 3) (VBI) Wait for motion timer.
; 4) Execute motion. Either
; 4)a) top row to the left, bottom row to the right, OR
; 4)b) top row to the right, bottom row to the left
; 5) At end, then reset
; 5)a) toggle motion direction.
; 5)b) restart the waiting phase.
; --------------------------------------------------------------------------

Gfx_CreditsScrolling

	lda zCreditsMotion            ; What direction are we moving in?
	beq b_gcs_CreditLeftRight     ; 0 is moving Left/Right

	; Otherwise, we're going in the opposite direction here.  (Right/Left)

	inc zCredit1HS                ; Credit 1 Right
	lda zCredit1HS
	cmp #16                       ; Reach the end of fine scrolling 16 color clocks?
	bne b_gcs_Credit2_Left        ; No, go do the Credit2 line.
	lda #0                        ; Yes. 
	sta zCredit1HS                ; Reset the fine scroll, and...
	dec DL_LMS_SCROLL_CREDIT1     ; Coarse scroll the text... 8 color clocks.
	dec DL_LMS_SCROLL_CREDIT1     ; and another 8 color clocks.

b_gcs_Credit2_Left                ; Credit 2 Left
	dec zCredit2HS                ; Reach the end of fine scrolling 16 color clocks (wrap from 0 to -1)?              
	bpl b_gcs_TestEndRightLeft    ; Nope.  End of scrolling, check end position
	lda #15                       ; Yes. 
	sta zCredit2HS                ; Reset the fine scroll, and...
	inc DL_LMS_SCROLL_CREDIT2     ; Coarse scroll the text... 8 color clocks.
	inc DL_LMS_SCROLL_CREDIT2     ; and another 8 color clocks.

b_gcs_TestEndRightLeft            ; They both scroll the same distance.  Check Line2's end position.
	lda zCredit2HS                ; Get fine scroll position
	cmp #12                       ; At the stopping point?
	bne b_gcs_Exit  ; nope.  We're done with checking.
	lda DL_LMS_SCROLL_CREDIT2     ; Get the coarse scroll position
	cmp #<[GFX_SCROLL_CREDIT2+30] ; at the ending coarse scroll position?
	bne b_gcs_Exit  ; nope.  We're done with checking.

	; reset to do left/right, then re-enable the reading comprehension timer.
	dec zCreditsMotion            ; It was 1 to do right/left scrolling. swap.
	dec zCreditsPhase             ; It was 1 to do scrolling.  switch to waiting.
	bne b_gcs_Exit  ; Finally done with this scroll direction. 

;  we're going in the Left/Right direction. 

b_gcs_CreditLeftRight
	dec zCredit1HS                ; Credit 1 Left
;	lda zCredit1HS                ; Reach the end of fine scrolling 16 color clocks (wrap from 0 to -1)?
	bpl b_gcs_Credit2_Right       ; No, go do the Credit2 line. 
	lda #15                       ; Yes. 
	sta zCredit1HS                ; Reset the fine scroll, and...
	inc DL_LMS_SCROLL_CREDIT1     ; Coarse scroll the text... 8 color clocks.
	inc DL_LMS_SCROLL_CREDIT1     ; and another 8 color clocks.

b_gcs_Credit2_Right
	inc zCredit2HS                ; Credit 1 Right
	lda zCredit2HS
	cmp #16                       ; Reach the end of fine scrolling 16 color clocks?
	bne b_gcs_TestEndLeftRight    ; Nope.  End of scrolling, check end position
	lda #0                        ; Yes. 
	sta zCredit2HS                ; Reset the fine scroll, and...
	dec DL_LMS_SCROLL_CREDIT2     ; Coarse scroll the text... 8 color clocks.
	dec DL_LMS_SCROLL_CREDIT2     ; and another 8 color clocks.


b_gcs_TestEndLeftRight            ; They both scroll the same distance.  Check Line2's end position.
	lda zCredit2HS                ; Get fine scroll position
	cmp #12                       ; At the stopping point?
	bne b_gcs_Exit  ; nope.  We're done with checking.
	lda DL_LMS_SCROLL_CREDIT2     ; Get the coarse scroll position
	cmp #<GFX_SCROLL_CREDIT2      ; at the ending coarse scroll position?
	bne b_gcs_Exit  ; nope.  We're done with checking.

	; reset to do left/right, then re-enable the reading comprehension timer.
	inc zCreditsMotion            ; It was 0 to do left/right scrolling. swap.
	dec zCreditsPhase             ; It was 1 to do scrolling.  switch to waiting.
;	bne b_mdv_EndCreditScrolling  ; Finally done with this scroll direction. 

b_gcs_Exit
	rts



; ==========================================================================
; SCROLL DOCS
; ==========================================================================
; Do the documentation line scrolling.
;
; The timer is maintained by the VBI, then it calls this routine.
;
; 1) (VBI) Wait for motion timer.
; 2) Execute motion.
; 3)a) dec fine scroll to move left 
; 3)b) if at end of fine scroll then increment LMS pointer.
; 4) if at end of scrolling region, reset to start
; --------------------------------------------------------------------------

Gfx_DocsScrolling

	dec zDocsHS                ; Docs 1 pixel Left.  Did it wrap from 0 to -1?
	bpl b_gds_Exit             ; No.  We're done doing fine scrolling for this frame. 
	lda #15                    ; Yes...
	sta zDocsHS                ; Reset the fine scroll, and...
	
	lda DL_LMS_SCROLL_DOCS     
	cmp #<GFX_END_DOCS         ; Test if low byte is the ending position.
	bne b_gds_AddDocsLMS       ; No.  Ok to increment LMS
	
	lda DL_LMS_SCROLL_DOCS+1     
	cmp #>GFX_END_DOCS         ; Test if high byte is the ending position.
	bne b_gds_AddDocsLMS       ; No.  Ok to increment LMS

	lda #<GFX_SCROLL_DOCS      ; Load low bytes of starting position.
	sta DL_LMS_SCROLL_DOCS
	lda #>GFX_SCROLL_DOCS      ; Load high bytes of starting position.
	sta DL_LMS_SCROLL_DOCS+1

	jmp b_gds_Exit

b_gds_AddDocsLMS ; Coarse scroll the text... 8 color clocks.

	clc
	lda #2                     ; 16 color clocks is 2 characters.
	adc DL_LMS_SCROLL_DOCS     ; add to low byte of LMS
	sta DL_LMS_SCROLL_DOCS
	bcc b_gds_Exit ; If there is carry
	inc DL_LMS_SCROLL_DOCS+1   ; incrememnt high byte of LMS

b_gds_Exit
	rts



; ==========================================================================
; GAME SCREEN FLICKERING STARS
; ==========================================================================
; At any time there are 4 stars on screen.
; Each star lasts 8 frames until it is replaced.
; When the star fades out a new star is added.
; On the Atari this fade out will be a little more animated.
; The star has a little gradient applied where the top and bottom
; sparkly pixels fade out faster than the center line pixels.
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
; to the value divided by 3.  The zero equivalents (0, 1, 2) will map
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
TABLE_GFX_STAR_COLOR_AND_OUT
	.byte $00,$00,$F0,$F0,$F0,$F0,$F0,$F0,$00

TABLE_GFX_STAR_LUMA_OR_OUT
	.byte $00,$02,$02,$04,$06,$08,$0A,$0C,$0E

TABLE_GFX_STAR_COLOR_AND_IN
	.byte $00,$F0,$F0,$F0,$F0,$F0,$00,$00,$00
	
TABLE_GFX_STAR_LUMA_OR_IN
	.byte $00,$06,$08,$0a,$0C,$0e,$0e,$0e,$0e


;TABLE_GFX_STAR_COLOR_MASK1 ; outer colors.
	.byte $00,$02,$F2,$F4,$F6,$F8,$FA,$FC,$0E

;TABLE_GFX_STAR_COLOR_MASK2 ; inner, brighter colors.
	.byte $00,$F4,$F6,$F8,$FA,$FC,$0E,$0E,$0E


; Flag if the star is in use.  
; $FF is no star in use. 
; Otherwise contains Index to the 18 line tables.  (0 to 15)
TABLE_GFX_ACTIVE_STARS .byte $00,$FF,$FF,$FF

; Base color for the star.
TABLE_GFX_STAR_BASE .byte 0,0,0,0

; Clock counter for each star. 8, 7, 6, 5, 4, 3, 2, 1, 0.  At 0, star goes off.
TABLE_GFX_STARS_COUNT .byte 8,0,0,0


; DLI Usage . . . .

; Is this start running on this row?   If not, then a lot of DLI can be shortcut.
TABLE_GFX_STAR_WORKING
	.byte 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; A list of the outer color value for each star line (only matters on the lines with stars)
TABLE_GFX_STAR_OUT_COLOR
	.byte $0e,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0

; A list of the inner color value for each star line (only matters on the lines with stars)
TABLE_GFX_STAR_IN_COLOR
	.byte $0e,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0

; A list of the fine scroll values for each start line used for pixel positioning.
TABLE_GFX_STAR_HSCROL
		.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

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
	.by <[GFX_STARS_LINE+0],<[GFX_STARS_LINE+0],<[GFX_STARS_LINE+0]   ; (20) (60 61 62)
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
; Due to DLI timing one row of stars has to be removed.   So, if the 
; row picked is 15, then try again.
;
; On exit, A is the new row.
; --------------------------------------------------------------------------

Gfx_Choose_Star_Row

b_gcsr_ButNotRow15
	lda RANDOM
	and #$0f                     ; Reduce to 0 to 15 (um, really 14).
	cmp #$0f
	beq b_gcsr_ButNotRow15

b_gcsr_StartCheckLoop
	ldy #3                       ; Index 3, 2, 1, 0 for star list

b_gcsr_CompareEntry
	cmp TABLE_GFX_ACTIVE_STARS,y ; Compare to each current star, 
	bne b_gcsr_TryNextEntry      ; Does not match, so test next entry.
	
	clc                          ; Oops.  Found a matching value. 
	adc #1                       ; Increment the value and then redo the checking.
	
	cmp #15                      ; Did we reach row 16? umm, 15.
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

	stx gTEMP_NEW_STAR_ID            ; Save Star number

	lda TABLE_GFX_ACTIVE_STARS,X     ; A == the star's row
	sta gTEMP_NEW_STAR_ROW           ; Save for later.
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

	lda #$FF
	sta zTEMP_ADD_STAR               ; If this is on frame 6, then it is time for a new star.

; The idea here is that inner color and outer color are managed differently.
; The Base color is not always the color displayed.   At the start of the 
; flash the color is white and max brightness. It tranistions to the 
; base color and the brighness fades.   When it gets to the lowest luminance
; it becomes white again (actually grey.) 
; This transition happens at different rates for the inner color and the 
; outer color.  So, the sequence for color modification is simply played 
; by the frame counter. Given the base color, AND with the color mask, then 
; OR with the luma mask, and that's the current color to display.

b_gss_ProcessColor
	ldy TABLE_GFX_STARS_COUNT,X        ; Y = Frame counter == Index to color masks.
	lda TABLE_GFX_STAR_BASE,X          ; Base color for star.

	and TABLE_GFX_STAR_COLOR_AND_OUT,y ; Mask to hold or drop the base color
	ora TABLE_GFX_STAR_LUMA_OR_OUT,y   ; Mask to merge the luminance
	ldy gTEMP_NEW_STAR_ROW             ; Get the row.
	sta TABLE_GFX_STAR_OUT_COLOR,Y     ; Save the new outer color.

	ldy TABLE_GFX_STARS_COUNT,X        ; Y = Frame counter == Index to color masks.
	lda TABLE_GFX_STAR_BASE,X          ; Base color for star.

	and TABLE_GFX_STAR_COLOR_AND_IN,y ; Mask to hold or drop the base color
	ora TABLE_GFX_STAR_LUMA_OR_IN,y   ; Mask to merge the luminance
	ldy gTEMP_NEW_STAR_ROW            ; Get the row.
	sta TABLE_GFX_STAR_IN_COLOR,Y     ; Save the new inner color.

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
	
	stx gTEMP_NEW_STAR_ID              ; Save Star number
	
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

	lda #$0E                           ; Still Starting out with white.
	sta TABLE_GFX_STAR_OUT_COLOR,Y     ; Set top/bottom sparkle color
	sta TABLE_GFX_STAR_IN_COLOR,Y      ; Set center star color

	lda #$FF
	sta TABLE_GFX_STAR_WORKING,Y       ; Turn ON this star (DLI observes this.)

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
	
	lda #$FF                           ; Set the negative flag telling the caller a star was added.
	
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
	sta TABLE_GFX_STAR_WORKING,Y   ; Turn off this star (DLI observes this.)

	lda #15
	sta TABLE_GFX_STAR_HSCROL,Y    ; Output all color clocks in the buffer

	lda TABLE_LO_GFX_LMS_STARS,Y   ; Address of this row's LMS 
	sta zDL_LMS_STARS_ADDR         ; Save to page 0 for pointer
	lda TABLE_HI_GFX_LMS_STARS,Y   
	sta zDL_LMS_STARS_ADDR+1

	lda #<GFX_STARS_LINE           ; Low byte to the start of the stars line
	ldy #0
	sta (zDL_LMS_STARS_ADDR),Y     ; Change the LMS to the start of line

	lda #$FF
	sta zTEMP_ADD_STAR             ; Flag that this star is gone.  Add new star at next opportunity.

	rts


; ==========================================================================
; RUN GAME SCREEN STARS
; ==========================================================================
; Cycle through stars 0 to 3.
; Run the service routine.
; If the routines flagged to start a new star, then look for 
; an unused star and restart it.
; --------------------------------------------------------------------------

Gfx_RunGameStars

	ldx #0                   ; Start at star 0

b_grgs_LoopEachStar
	jsr Gfx_Service_Star     ; Service the start timer and color flash

	inx                      ; next Star.
	cpx #4                   ; Loop 0 to 3, then 4 is the end.
	bne b_grgs_LoopEachStar  ; Looping for next star.

	lda zTEMP_ADD_STAR       ; At the end was a star removed (or timer signaled new star?)
	beq b_grgs_Exit          ; No.   Done here.

	ldx #0                   ; Clear the add New Star Flag.
	stx zTEMP_ADD_STAR

b_grgs_LookForUnusedStar
	jsr Gfx_Setup_New_Star   ; Try to setup a new star.
	bmi b_grgs_Exit          ; if it exited <0 then a new star was added.

	inx                      ; next Star.
	cpx #4                   ; Loop 0 to 3, then 4 is the end.
	bne b_grgs_LookForUnusedStar

b_grgs_Exit
	rts



; If not in Cheat mode this returns star to original image

Gfx_SetStarImage

	lda gConfigCheatMode
	beq b_gssi_Exit

	lda #0
	sta GAME_STAR_CHAR+1
	sta GAME_STAR_CHAR+5
	sta GAME_STAR_CHAR+7
	
	lda #$08
	sta GAME_STAR_CHAR
	sta GAME_STAR_CHAR+2
	sta GAME_STAR_CHAR+4
	sta GAME_STAR_CHAR+6

	lda #$2a
	sta GAME_STAR_CHAR+3

b_gssi_Exit
	rts



 ; if in cheat mode, change the star image.
 
Gfx_CheatModeStars        

	lda gConfigCheatMode ; are we in cheat mode ?
	beq b_gcms_Exit      ; Nope.  exit.

	lda gSTARS_CHEAT_CLOCK ; Is this zero?
	beq g_gcms_NextCheatChar ; Yes.  Time to do next char.

	dec gSTARS_CHEAT_CLOCK ; Decrement clock.
	bpl b_gcms_Exit        ; when it reaches 0, it will be identified on next frame.

g_gcms_NextCheatChar
	lda #CHEAT_CLOCK       ; Reset the character image clock
	sta gSTARS_CHEAT_CLOCK

	ldx gCHEAT_IMAGE_INDEX     ; Get image number
	inx                     ; increment image number
	cpx #5                  ; Is is greater than number of characters?
	bne b_gcms_UpdateStarImage ; Nope.  Use the new value.
	ldx #0                  ; Yes.  Reset to first character.

b_gcms_UpdateStarImage
	stx gCHEAT_IMAGE_INDEX    ; Save updated index.
	txa                    ; A = X
	asl                    ; A * 2
	asl                    ; A * 4
	asl                    ; A * 8
	tax                    ; X = A ; New index into table.

	ldy #0
b_gcms_Loopchar
	lda gCHEAT_IMAGE_TABLE,x ; Get image data from table 
	sta GAME_STAR_CHAR,y  ; Write into character set
	inx
	iny
	cpy #8
	bne b_gcms_Loopchar

b_gcms_Exit
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
	.byte 99,70,70,70,1
;	.byte 90,90,90,90,1


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
	tay                      ; Y = index * 4 for copying.
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

	dec zLandScrollTimer       ; Delay to not scroll to quickly.
	bne b_grsl_EndLandScrolling

	lda #LAND_STEP_TIMER       ; Reset the scroll timer
	sta zLandScrollTimer

	lda zLandMotion            ; What direction are we moving in?
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
; Zero Game Over Text
; ==========================================================================
; Erase the memory used to display the Game Over Text.
; --------------------------------------------------------------------------

Gfx_Zero_Game_Over_Text

	lda #$20   ; Corresponds to blank space character (i.e. the '@')
;	lda RANDOM
	ldy #19  ; Text line is 20 characters.

b_gzgot_ZeroLoop
;	lda RANDOM
	sta GFX_GAME_OVER_LINE,y
	dey
	bpl b_gzgot_ZeroLoop

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

; Note, this is 240 bytes of text below.   However, the game over animation 
; will result in COPYING bytes from these sources to the GAME_OVER_LINE.
; These values/declarations do not need to be aligned or fall within any 
; managed, aligned graphics memory

GFX_GAME_OVER_TEXT0
;	.sb      "  G A M E  O V E R  "   ; Do this about 96% of the time.
	.sb +$40,"@@G@A@M@E@@O@V@E@R@@"   ; Do this about 96% of the time.
GFX_GAME_OVER_TEXT1
	.sb +$40,"@@@@@LOOOOOSER"
	.by CHAR_ALT_BANG
	.sb +$40,"@@@@@"
GFX_GAME_OVER_TEXT2
	.sb +$40,"@@@@LOOOOOOSERS"
	.by CHAR_ALT_BANG
	.sb +$40,"@@@@"
GFX_GAME_OVER_TEXT3
	.sb +$40,"KLAATU@BARADA@NIKTO@"
GFX_GAME_OVER_TEXT4
	.sb +$40,"@@IT"
	.by CHAR_ALT_APOS
	.sb +$40,"S@A@COOKBOOK"
	.by CHAR_ALT_BANG
	.sb +$40,"@@"
GFX_GAME_OVER_TEXT5
	.sb +$40,"RESISTANCE@IS@FUTILE"
GFX_GAME_OVER_TEXT6
	.sb +$40,"U@BASE@R@BELONG@2@US"
GFX_GAME_OVER_TEXT7
	.sb +$40,"@@PWNED@EARTHLING"
	.by CHAR_ALT_BANG
	.sb +$40,"@@"
GFX_GAME_OVER_TEXT8
	.sb +$40,"@GRANDMA@DID@BETTER"
	.by CHAR_ALT_BANG
GFX_GAME_OVER_TEXT9
	.sb +$40,"@ARE@YOU@GONNA@CRY"
	.by CHAR_ALT_QUES
	.sb +$40,"@"
GFX_GAME_OVER_TEXT10
	.sb +$40,"@DO@YOU@NEED@MOMMY"
	.by CHAR_ALT_QUES
	.sb +$40,"@"
GFX_GAME_OVER_TEXT11
	.sb +$40,"@@@@TASTY@HUMANS"
	.by CHAR_ALT_BANG
	.sb +$40,"@@@"


TABLE_HI_GFX_GAMEOVER
	.by >GFX_GAME_OVER_TEXT0,>GFX_GAME_OVER_TEXT1
	.by >GFX_GAME_OVER_TEXT2,>GFX_GAME_OVER_TEXT3
	.by >GFX_GAME_OVER_TEXT4,>GFX_GAME_OVER_TEXT5
	.by >GFX_GAME_OVER_TEXT6,>GFX_GAME_OVER_TEXT7
	.by >GFX_GAME_OVER_TEXT8,>GFX_GAME_OVER_TEXT9
	.by >GFX_GAME_OVER_TEXT10,>GFX_GAME_OVER_TEXT11

TABLE_LO_GFX_GAMEOVER
	.by <GFX_GAME_OVER_TEXT0,<GFX_GAME_OVER_TEXT1
	.by <GFX_GAME_OVER_TEXT2,<GFX_GAME_OVER_TEXT3
	.by <GFX_GAME_OVER_TEXT4,<GFX_GAME_OVER_TEXT5
	.by <GFX_GAME_OVER_TEXT6,<GFX_GAME_OVER_TEXT7
	.by <GFX_GAME_OVER_TEXT8,<GFX_GAME_OVER_TEXT9
	.by <GFX_GAME_OVER_TEXT10,<GFX_GAME_OVER_TEXT11

; HACKERY
;TEMP_CHOOSER .byte $FF

Gfx_Choose_Game_Over_Text
; HACKERY
;	inc TEMP_CHOOSER
;	ldx TEMP_CHOOSER
	ldx RANDOM                   ; Get a random value (0 to 255) 


	cpx #1                       ; "Loser!" singular
	bne b_cgot_Test2
	lda zPLAYER_ONE_ON
	and zPLAYER_TWO_ON
	beq b_gcgot_Continue         ; One Player. Go with it.
	inx                          ; Two Players, so choose Plural. 
	bne b_gcgot_Continue

b_cgot_Test2
	cpx #2                       ; "Losers!" plural
	bne b_cgot_TestOthers
	lda zPLAYER_ONE_ON
	and zPLAYER_TWO_ON
	bne b_gcgot_Continue         ; Two Players.  Go with it.
	dex                          ; One Players, so choose Singular. 
	bne b_gcgot_Continue

b_cgot_TestOthers
	cpx #12                      ; Is it 0 to 11?
	bcc b_gcgot_Continue         ; Yes.  Use what we have now.

	ldx #0                       ; No.  Force default message

b_gcgot_Continue
	lda TABLE_LO_GFX_GAMEOVER,X  ; Save address of the chosen text.
	sta zGAME_OVER_TEXT
	lda TABLE_HI_GFX_GAMEOVER,X
	sta zGAME_OVER_TEXT+1

	rts


; ==========================================================================
; UPDATE GAME OVER CHARS
; ==========================================================================
; Given the current character index, get the character from the string
; write it to the screen display memory.
; 
; (Up to) four adjacent characters are being manipulated at a time. 
; The first character at +/-0 is animated by masking an animation 
; of the character into a second placeholder character image.
; The next two character positions provide other animation phases with 
; color transistions or DLI color movement.
; The last character is the final character state.
;
; (+/-) 0 = COLPF0 (Placeholder char) ( X | %00 000000 )
;
; (+/-) 1 = character in COLPF1 ( X | %01 000000 )
;
; (+/-) 2 =  character in COLPF2 ( X | %10 000000 )
;
; (+/-) 3 =  character in COLPF3 ( X | %11 000000 )
;
; Updates of characters only occurs when the index is within 0 to 9 on
; the left side of the screen, and 10 to 19 on the right side.
; --------------------------------------------------------------------------

Gfx_UpdateGameOverChars

	ldy zGO_CHAR_INDEX
	bmi b_gugoc_Exit     ; Negative means not set.

	cpy #13
	bcs b_gugoc_Exit     ; 13 is past the end.

; Stage 1 Left
	cpy  #10
	bcs b_gugoc_DecStage1L
	jsr Gfx_WriteCharX00
;	lda #GAME_OVER_LEFT_CHAR
;	lda #GAME_OVER_RIGHT_CHAR+1
;	sta GFX_GAME_OVER_LINE,Y
b_gugoc_DecStage1L
	dey
	bmi b_gugoc_DoRightSide

; Stage 2 Left
	cpy  #10
	bcs b_gugoc_DecStage2L
	jsr Gfx_WriteCharX01
b_gugoc_DecStage2L
	dey
	bmi b_gugoc_DoRightSide

; Stage 3 Left
	cpy  #10
	bcs b_gugoc_DecStage3L
	jsr Gfx_WriteCharX10
b_gugoc_DecStage3L
	dey
	bmi b_gugoc_DoRightSide

; Stage 4 Left
	cpy  #10               ; Is this even possible?
	bcs b_gugoc_DoRightSide
	jsr Gfx_WriteCharX11

; 	right side

b_gugoc_DoRightSide
	sec
	lda #19
	sbc zGO_CHAR_INDEX
	tay
	
; Stage 1 Right
	cpy #10
	bcc b_gugoc_IncStage1R
	jsr Gfx_WriteCharX00
;	lda #GAME_OVER_RIGHT_CHAR
;	sta GFX_GAME_OVER_LINE,Y
b_gugoc_IncStage1R
	iny
	cpy #20
	bcs b_gugoc_Exit

; Stage 1 Right
	cpy #10
	bcc b_gugoc_IncStage2R
	jsr Gfx_WriteCharX01
b_gugoc_IncStage2R
	iny
	cpy #20
	bcs b_gugoc_Exit
	
; Stage 1 Right
	cpy #10
	bcc b_gugoc_IncStage3R
	jsr Gfx_WriteCharX10
b_gugoc_IncStage3R
	iny
	cpy #20
	bcs b_gugoc_Exit

; Stage 1 Right
	cpy #10
	bcc b_gugoc_Exit
	jsr Gfx_WriteCharX11

b_gugoc_Exit
	rts


Gfx_WriteCharX00
	lda (zGAME_OVER_TEXT),y ; TempCharValue
	and #%00111111          ; clean it. 
	sta GFX_GAME_OVER_LINE,Y
	rts

Gfx_WriteCharX01
	lda (zGAME_OVER_TEXT),y ; TempCharValue
	and #%00111111          ; clean it. 
	ora #%01000000          ; OR %01
	sta GFX_GAME_OVER_LINE,Y
	rts

Gfx_WriteCharX10
	lda (zGAME_OVER_TEXT),y ; TempCharValue
	and #%00111111          ; clean it. 
	ora #%10000000          ; OR %10
	sta GFX_GAME_OVER_LINE,Y
	rts

Gfx_WriteCharX11
	lda (zGAME_OVER_TEXT),y ; TempCharValue
	and #%00111111          ; clean it. 
	ora #%11000000          ; OR %11
	sta GFX_GAME_OVER_LINE,Y
	rts



; ==========================================================================
; SETUP COLPF2 INDEX
; ==========================================================================
; Given the current frame number set the correct index offset for the 
; COLPF2 index used by the DLI on this frame.
; Since the index use counts down 16 times, the starting value for the 
; index is:
;
; (((frame index + 1) * 16) - 1)  OR
;
; frame   index
; 0        15
; 1        31
; 2        47
; 3        63
; 4        79
; 5        95
;
; It is 12 bytes of instructions to do the formula and store the result.
; So, just use a table lookup.  Duh.
; --------------------------------------------------------------------------

TABLE_FRAME_TO_COLPF2INDEX
	.byte 15,31,47,63,79,95


Gfx_SetupCOLPF2Index

	ldx zGO_FRAME                    ; Current frame number
	lda TABLE_FRAME_TO_COLPF2INDEX,x

	sta zGO_COLPF2_INDEX

	rts




; ==========================================================================
; TAG LINE
; ==========================================================================
; A series of text messages appear under the logo.
; They fade up from black, remain momentarily, then fade to black.
;
; There are activites common to each -- mostly waiting.  Some activities 
; must loop multiple times (fade in, fade out).  A speed setting per 
; loop or the activity is also needed.
;
; The tagline is just a cosmetic nicety.   There is no reason to scale 
; the timing to make PAL execute in the same speed as NTSC.  
; Additionally, since the color values for the tag line are all grey, 
; palette adjustment for PAL does not occur. 
;
; In Detail:
;
; (ONE BUTTON)
; Long Wait (10 sec), Fade in, Wait (1 sec), Fade out.
; (ONE ALIEN)
;      Wait (1 sec),  Fade in, Wait (1 Sec), Fade out.
; (ONE LIFE)
;      Wait (1 sec),  Fade in, Wait (1 Sec), Fade out.
; (NO) /MERCY/
;      Wait (1 sec)   Fade in,  
; /NO/ (MERCY)
;      Wait (2 sec),  Fade in, Wait (2 sec), Fade out (NO and MERCY).
;
; In order to have two Fade-ins for the same line ("NO", then "MERCY") 
; there needs to be two color registers on the line, and then two 
; different fade in routines, one per color registers.   Fade out is  
; done at the same time, so one fade out routine can be used that 
; decrements both color registers.
;
; The individual activities:
;
; (0) Wait                 X seconds, X jiffies per second
; (1) Fade in COLPF0,      X loops,   X jiffies wait per loop.
; (2) Fade in COLPF1,      X loops,   X jiffies wait per loop.
; (3) Fade out COLPF0/PF1, X loops,   X jiffies wait per loop.
;
; The display LMS List:
;
; (0) ONE BUTTON -- All COLPF0
; (1) ONE ALIEN  -- All COLPF0
; (2) ONE LIFE   -- All COLPF0
; (3) NO MERCY   -- "NO" COLPF0, "MERCY" COLPF1
;
; The LMS value is the same across multiple states in the animation.
; Rather than specifying an LMS value that infrequently changes 
; in a program state array, instead define LMS value changes as 
; a state in the loop.   The high bit of the state identification 
; would indicate the step is an LMS change, and the remainder of 
; the state identification value is the index for the LMS.  The
; step and jiffy counter for the LMS change would be 0.  If it is
; examines by timer code, then this should trigger the state engine 
; to immediately move to the next state in the array.
;
; STATE = LMS =
; $80   = (0) = "ONE BUTTON"
; $81   = (1) = "ONE ALIEN"
; $82   = (2) = "ONE ALIEN"
; $83   = (3) = "ONE ALIEN"
;
; Implementation - The Complete sequence:
; 
; INIT == Set All COLPF0/1 in table == 0, set TAG_INDEX = 0
; 
; CONTINUOUS LOOP
; FUNCTION    = STATE |  STEPS   | JIFFIES 
; LMS         = ($80) |  0 sec   |  0 jiffies (ONE BUTTON)
; Wait        =  (0)  | 10 sec   | 60 jiffies 
; Fade in PF0 =  (1)  | 16 loops |  2 jiffies  
; Wait        =  (0)  |  1  sec  | 60 jiffies 
; Fade out    =  (3)  | 16 loops |  2 jiffies 
; LMS         = ($81) |  0 sec   |  0 jiffies (ONE ALIEN)
; Wait        =  (0)  |  1 sec   | 60 jiffies 
; Fade in PF0 =  (1)  | 16 loops |  2 jiffies  
; Wait        =  (0)  |  1  sec  | 60 jiffies 
; Fade out    =  (3)  | 16 loops |  2 jiffies  
; LMS         = ($82) |  0 sec   |  0 jiffies (ONE LIFE)
; Wait        =  (0)  |  1 sec   | 60 jiffies  
; Fade in PF0 =  (1)  | 16 loops |  2 jiffies  
; Wait        =  (0)  |  1  sec  | 60 jiffies 
; Fade out    =  (3)  | 16 loops |  2 jiffies 
; LMS         = ($83) |  0 sec   |  0 jiffies (NO MERCY)
; Wait        =  (0)  |  1 sec   | 60 jiffies 
; Fade in PF0 =  (1)  | 16 loops |  2 jiffies  
; Wait        =  (0)  |  1 sec   | 60 jiffies  
; Fade in PF1 =  (2)  | 16 loops |  2 jiffies  
; Wait        =  (0)  |  2 sec   | 60 jiffies 
; Fade out    =  (3)  | 16 loops |  2 jiffies 
; END LOOP
;
;
; Pseudo coding this . . . 
; Hint -- LMS states are executed the moment they are encountered.
; Other states must run the jiffy counter to zero and then execute 
; per the number of steps specified.
;
;
; Start of Routine Service Tag Line States and Steps:
; Count the jiffies...
; If TAG_COUNTER >0 Then TAG_COUNTER--: JumpTo End of Routine
; (Jiffy Counter has ended, check state, end state.) 
;
; TAG_COUNTER = TAG_STEP_JIFFIES[ TAG_INDEX ] ; reset jiffy counter in case we loop the step again.
; If TAG_STEPS > 0 Then TAG_STEPS--: JumpTo RunState
;
;
; NextState:
; TAG_INDEX++
; Call SetTagState
; JumpTo End of Routine
;
;
; SetTagState:
; TAG_STATE = TAG_ENGINE_STATES[ TAG_INDEX ]
;
; If TAG_STATE == 255 Then TAG_INDEX = 0 : JumpTo SetTagState
;
; If TAG_STATE & $80 Then Call RunState : TAG_INDEX++ : JumpTo SetTagState
;
; TAG_STEPS   = TAG_STATE_STEPS[ TAG_INDEX ]
; TAG_COUNTER = TAG_STEP_JIFFIES[ TAG_INDEX ]
;
; End of SetTagState
;
;
; RunState:
; If TAG_STATE & $80 Then Call SetTagLMS : End of RunState
;
; TAG_COUNTER = TAG_STEP_JIFFIES[ TAG_INDEX ]
; 
; Switch ( TAG_STATE )
;     0: ( Wait  ) ; Nothing to do.  Main logic maintains jiffy count and step count.
;
;     1: ( Fade In COLPF0 )
;        Loop 0 to 7
;            If COLOR_TAGLINE_PF0[ Loop ] < GREY_MASTER[ Loop ] Then COLOR_TAGLINE_PF0[ Loop ]++
;        Next Loop
;
;     2: ( Fade in COLPF1 )
;        Loop 0 to 7
;            If COLOR_TAGLINE_PF1[ Loop ] < GREY_MASTER[ Loop ] Then COLOR_TAGLINE_PF1[ Loop ]++
;        Next Loop
;
;     3: ( Fade out COLPF0/PF1 )
;        Loop 0 to 7
;            If COLOR_TAGLINE_PF0[ Loop ] != 0 Then COLOR_TAGLINE_PF0[ Loop ]--
;            If COLOR_TAGLINE_PF1[ Loop ] != 0 Then COLOR_TAGLINE_PF1[ Loop ]--
;        Next Loop
;
; End Switch: JumpTo End of Routine
;
; End of RunState.
;
;
; SetTagLMS:
; INDEX = TAG_STATE & $7F ; Remove high bit.
; LMS = GFX_TAG_LMS[ INDEX ]
; DL_LMS_TAG_TEXT = LMS
; End of SetTagLMS
;
;
; End of Routine Service Tag Line States and Steps.
; --------------------------------------------------------------------------

; ==========================================================================
; INIT TAG LINE
; ==========================================================================
; Set Tag Index Out of Range which will trigger going to the first 
; entry immediately which will cause update of the LMS.
; 
; Technically, counters should be 0, too.  Buuut, since the first step 
; in the index is to change the LMS pointer this will happen automatically.
; 
; Also zero the colord for COLPF0 and COLPF1 to make sure whatever is 
; displayed in the tag line is off/not visible.
; --------------------------------------------------------------------------

Gfx_InitTagLine

	lda #$FF
	sta GFX_TAG_INDEX

	lda #0
	ldy #7
b_gitl_LoopZeroColors
	sta TABLE_COLOR_TAGLINE_PF0,y
	sta TABLE_COLOR_TAGLINE_PF1,y
	dey
	bpl b_gitl_LoopZeroColors

	rts


; ==========================================================================
; RUN TAG LINE
; ==========================================================================
; Very simply...
; Check if init, then force setup to first entry in engine table.
;
; If jiffy timer on, then decrement jiffy timer. 
; If jiffy timer found at 0, then check step counter.
; If step counter on then decrement step counter, and  call the state 
; engine for the current state.
; If step counter found at 0, then increment to next entry in state engine.
; end
;
; When going to Next State, copy state, steps, and counter.
; If state $80 bit set, then immediately call.
; End
;
; Running the State:  Based on state number do the appropriate action
; ... Set new LMS
; ... Wait
; ... Increment COLPF0
; ... Increment COLPF1
; ... Decrement COLPF0/COLPF1
; End.
; --------------------------------------------------------------------------

Gfx_RunTagLine

	ldy GFX_TAG_INDEX             ; Is the Index -1?
	bpl b_grtl_RunCounter         ; No.  Continue normally.

	ldy #0                        ; Reset ...  index, 0 timer, and load first state (LMS).
	sty GFX_TAG_INDEX             ; ... index to 0.
	sty GFX_TAG_COUNTER           ; Jiffy delay to 0
	sty GFX_TAG_STEPS             ; State steps to 0
	lda TABLE_TAG_ENGINE_STATES   ; Get first state (which we know is LMS)
	sta GFX_TAG_STATE             ; And Save.
	bmi b_grtl_RunState           ; And run this now.  (Because it is LMS). (Always Branches)

b_grtl_RunCounter
	lda GFX_TAG_COUNTER           ; Is counter 0?
	beq b_grtl_RunStep            ; Yes, counter ran out, do next step 
	dec GFX_TAG_COUNTER           ; No, decrement, and
	rts                           ; Done here until next time.

b_grtl_RunStep
	ldy GFX_TAG_INDEX             ; (Got here because jiffy counter 0.  Reset it). Get Current index
	lda TABLE_TAG_STEP_JIFFIES,y  ; Load the current state's jiffy delay
	sta GFX_TAG_COUNTER           ; Reset jiffy counter.

	lda GFX_TAG_STEPS             ; Is Steps 0?
	beq b_grtl_NextState          ; Yes.  Setup next state.
	dec GFX_TAG_STEPS             ; No, decrement, and
	bpl b_grtl_RunState           ; Run this state. (always branch)

b_grtl_NextState
	inc GFX_TAG_INDEX             ; Next state index
	ldy GFX_TAG_INDEX             ; Get index
	lda TABLE_TAG_ENGINE_STATES,y ; Get new state
	cmp #$FF                      ; This is 255?
	bne b_grtl_LoadNextState      ; No.  Continue as normal.
	ldy #0                        ; Yes.  Reset the ...
	sty GFX_TAG_INDEX             ; ... index to start.

b_grtl_LoadNextState
	lda TABLE_TAG_STEP_JIFFIES,y  ; Load the new state's jiffy delay
	sta GFX_TAG_COUNTER
	lda TABLE_TAG_STATE_STEPS,y   ; Load the new state's steps
	sta GFX_TAG_STEPS
	lda TABLE_TAG_ENGINE_STATES,y ; Load the new state.
	sta GFX_TAG_STATE
	bmi b_grtl_RunState           ; Is the State negative (LMS to execute now).
	rts                           ; No.  End of state management.

b_grtl_RunState
	lda GFX_TAG_STATE             ; Get the current state
	bmi b_grtl_ExecLMS            ; Negative means an LMS instruction
	beq b_grtl_ExecWait           ; 0 == wait; already run by jiffy/step counter 
	cmp #1
	beq b_grtl_ExecFadePF0        ; 1 == Fade In COLPF0
	cmp #2
	beq b_grtl_ExecFadePF1        ; 2 == Fade In COLPF1
	cmp #3
	beq b_grtl_Exec_FadeOut       ; 3 == Fade Out COLPF0/COLPF1
b_grtl_ExecWait                   ; Wait is a do-nothing activity.
	rts                           ; And therefore, exit.

b_grtl_ExecLMS                    ; EXECUTE SET LMS 
	and #$7F                      ; Remove high bit
	tay                           ; Use the rest as index
	lda TABLE_GFX_TAG_LMS,y       ; Get LMS low byte from table
	sta DL_LMS_TAG_TEXT           ; Update Display List.
	jmp b_grtl_NextState          ; Go setup the next Step NOW.

b_grtl_ExecFadePF0                ; EXECUTE FADE IN COLPF0
	ldx #7                        ; Loop 8 times
b_grtl_LoopIncCOLPF0
	lda TABLE_COLOR_TAGLINE_PF0,x ; Get the current value
	cmp TABLE_GREY_MASTER,x       ; Is it the same as the master table?
	beq b_grtl_SkipIncPF0         ; Yes.  Nothing to increment.
	inc TABLE_COLOR_TAGLINE_PF0,x ; Add 1 to current entry.
b_grtl_SkipIncPF0
	dex                           ; Subtract from index
	bpl b_grtl_LoopIncCOLPF0      ; Loop 7...0
	rts

b_grtl_ExecFadePF1                ; EXECUTE FADE IN COLPF1
	ldx #7                        ; Loop 8 times
b_grtl_LoopIncCOLPF1
	lda TABLE_COLOR_TAGLINE_PF1,x ; Get the current value
	cmp TABLE_GREY_MASTER,x       ; Is it the same as the master table?
	beq b_grtl_SkipIncPF1         ; Yes.  Nothing to increment.
	inc TABLE_COLOR_TAGLINE_PF1,x ; Add 1 to current entry.
b_grtl_SkipIncPF1
	dex                           ; Subtract from index
	bpl b_grtl_LoopIncCOLPF1      ; Loop 7...0
	rts

b_grtl_Exec_FadeOut               ; EXECUTE FADE OUT COLP0/COLPF1
	ldx #7                        ; Loop 8 times
b_grtl_LoopDecCOLPF
	lda TABLE_COLOR_TAGLINE_PF0,x ; Get the current value
	beq b_grtl_SkipDecPF0         ; Zero.   Nothing to decrement.
	dec TABLE_COLOR_TAGLINE_PF0,x ; Subtract 1 from current entry.
b_grtl_SkipDecPF0
	lda TABLE_COLOR_TAGLINE_PF1,x ; Get the current value
	beq b_grtl_SkipDecPF1         ; Zero.   Nothing to decrement.
	dec TABLE_COLOR_TAGLINE_PF1,x ; And this was the same starting value, so decrement.
b_grtl_SkipDecPF1
	dex                           ; Subtract from index
	bpl b_grtl_LoopDecCOLPF       ; Loop 7...0
	rts


; ==========================================================================
; BUMPER VISUAL TWEAKS
; ==========================================================================
; Make adjustments to the bottom line of the screen based on the 
; type of two-player game that is being played.  (Or not two player game.)
; 
; You know, FR1GNORE could be a workable game mode for single-player.
; --------------------------------------------------------------------------

Gfx_BumperVisualTweaks

	lda #0                      ; Erase all bumpers
	sta GFX_BUMPERLINE          ; Left
	sta GFX_BUMPERLINE+19       ; Right
	sta GFX_MIDBUMPERS          ; Center
	sta GFX_MIDBUMPERS+1        ; and center, too.

	lda zPLAYER_ONE_ON          ; Are both players playing?
	and zPLAYER_TWO_ON
	beq Gfx_ShowBumpers         ; Nope. Default bumpers. (and return from there).
	
	lda gConfigTwoPlayerMode    ; Get two-player mode
	beq Gfx_ShowBumpers         ; 0 FR1GULAR, Show default bumpers (and return from there).

	cmp #1                      ; 1 FR1GNORE mode, no rebounds. No bumpers.
	bne b_tpvt_TestFrenemies    ; Not 1, try next
	lda #$3f|CSET_MODE67_COLPF3 ; TEMPORARY PLACEHOLDER
	sta GFX_BUMPERLINE
	sta GFX_BUMPERLINE+19       ; Placeholders for 
	rts

b_tpvt_TestFrenemies
	cmp #2                      ; 1 FRENEM1ES mode, Normal Bumpers
	beq Gfx_ShowBumpers         ; Default bumpers. (and return from there).

	; And 3 is FRE1GHBORS 
	lda #CHAR_CENTER_BOUNCER    ; Add the center bumper
	sta GFX_MIDBUMPERS
	lda #CHAR_CENTER_BOUNCER+1
	sta GFX_MIDBUMPERS+1        ; Fall through to show the normal bumpers.


Gfx_ShowBumpers

	lda #CHAR_LEFT_BOUNCER
	sta GFX_BUMPERLINE
	lda #CHAR_RIGHT_BOUNCER
	sta GFX_BUMPERLINE+19

	rts

