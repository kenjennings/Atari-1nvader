;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; VARIABLES FOR THE GAME
;
; Main file has the ORG specification.
; --------------------------------------------------------------------------

	; Label And Credit Where Ultimate Credit Is Due
	.by "** Thanks to the Word (John 1:1), Jesus Christ, Creator of heaven, "
	.by "and earth, and semiconductor chemistry and physics making all this "
	.by "fun possible. "
	.by "** ATARI 1NVADER "
	.by "** Atari 8-bit computer systems. "
	.by "** Ken Jennings  2021 **"


MOTHERSHIP_MIN_X = 40  ; Farthest Left off the normal width screen.
MOTHERSHIP_MAX_X = 208 ; Farthest right off the normal width screen.
MOTHERSHIP_MIN_Y = 36  ; starting position of mothership, last position for laser.

zMOTHERSHIP_MIN_X           .byte MOTHERSHIP_MIN_X
zMOTHERSHIP_MAX_X           .byte MOTHERSHIP_MAX_X

zMOTHERSHIP_X               .byte $00 ; Game mothership X coord 
zMOTHERSHIP_NEW_X           .byte $00 ; Game mothership X coord 
zMOTHERSHIP_Y               .byte $00 ; Game mothership Y coord 
zMOTHERSHIP_NEW_Y           .byte $00 ; Game mothership Y coord 

zMOTHERSHIP_DIR             .byte $00 ; Mothership direction.  0 = left to right.   1 = Right to Left
zMOTHERSHIP_ANIM            .byte $00 ; Animation frame for windows
zMOTHERSHIP_ANIM_FRAME      .byte 3   ; delay for animation 
zMOTHERSHIP_MOVE_SPEED      .byte $00 ; Game mothership speed index into speed table 0, 2, 4, ..., 14 
zMOTHERSHIP_SPEEDUP_COUNTER .byte $00 ; Game mothership speed up counter 
zMOTHERSHIP_MOVEMENT        .byte $00 ; Value to add/subtract from Mothership X
zMOTHERSHIP_COLOR           .byte $00 ; Game mothership color.

zMOTHERSHIP_ROW             .byte $00 ; Game mothership text line row number
zMOTHERSHIP_HITS            .byte $00 ; Number of times the mothership is hit.

zMOTHERSHIP_SHOT_BY_ONE     .byte $0  ; Collision between PM0 (shot) and PM2
zMOTHERSHIP_SHOT_BY_TWO     .byte $0  ; Collision between PM1 (shot) and PM2

zEXPLOSION_ON               .byte $00 ; Explosion is present.   
zEXPLOSION_COUNT            .byte $00 ; Timer/index for Explosion. 
zEXPLOSION_X                .byte $00 
zEXPLOSION_Y                .byte $00
zEXPLOSION_NEW_Y            .byte $00


; ==========================================================================
; SCORING . . .

zSHOW_SCORE_FLAG             .byte $00 ; Flag to update score on screen.

zMOTHERSHIP_POINTS_AS_DIGITS .byte $00,$00,$00,$00,$00,$00 ; Points for current row.

zPLAYERPOINTS_TO_ADD         .byte $00,$00,$00,$00,$00,$00 ; Mothership points to add to player

zPLAYER_SCORE      
zPLAYER_ONE_SCORE            .byte $00,$00,$00,$00,$00,$00 ; Player 1 score, 6 digit BCD 
zPLAYER_TWO_SCORE            .byte $00,$00,$00,$00,$00,$00 ; Player 2 score, 6 digits 

zHIGH_SCORE                  .byte $00,$00,$00,$00,$00,$00 ; 6 digits


; ==========================================================================
; STATISTICS . . .

zSHIP_HITS_AS_DIGITS        .byte $00,$00,$00,$00 ; Remaining hits on mothership as digits.
zMOTHERSHIP_ROW_AS_DIGITS   .byte $00,$00 ; Mothership text line row number as 2 digits for display


; ==========================================================================

; Points for Mothership by row.

; 00 = 1000 ; 01 = 0500 
; 02 = 0475 ; 03 = 0450 ; 04 = 0425 ; 05 = 0400
; 06 = 0375 ; 07 = 0350 ; 08 = 0325 ; 09 = 0300
; 10 = 0275 ; 11 = 0250 ; 12 = 0225 ; 13 = 0200
; 14 = 0175 ; 15 = 0150 ; 16 = 0125 ; 17 = 0100
; 18 = 0075 ; 19 = 0050 ; 20 = 0025 ; 21 = 0001

TABLE_MOTHERSHIP_POINTS
	.byte $10,$00,$05,$00,$04,$75,$04,$50,$04,$25 ;  0 -  4
	.byte $04,$00,$03,$75,$03,$50,$03,$25,$03,$00 ;  5 -  9
	.byte $02,$75,$02,$50,$02,$25,$02,$00,$01,$75 ; 10 - 14
	.byte $01,$50,$01,$25,$01,$00,$00,$75,$00,$50 ; 15 - 19
	.byte $00,$25,$00,$01                         ; 20 - 21

; Are there really 8 stars? In the video it appears there are 4
; in screen at any time.  It seems like the code wraps around 
; at 6, so ...? 
TABLE_STAR_LOCATION ; star
	.byte 0,32,64,96       ; eight
	.byte 128,160,192,224  ; stars
 

; Table to convert row to Y coordinate for mothership.
; This is also do-able with a LSR to multiply times 8 then add offset.

TABLE_ROW_TO_Y ; r2ytab 
.byte 36,44,52,60     ; 0  - 3 ; 36
.byte 68,76,84,92     ; 4  - 7
.byte 100,108,116,124 ; 8  - 11
.byte 132,140,148,156 ; 12 - 15
.byte 164,172,180,188 ; 16 - 19
.byte 196,204,212     ; 20 - 22

TABLE_TO_DIGITS ; 0 to 21.  (22 is last row which should be undisplayed.)
	.byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09
	.byte $10,$11,$12,$13,$14,$15,$16,$17,$18,$19
	.byte $20,$21,$22

TABLE_SPEED_CONTROL ; How many pixels to move each frame ( two values - frame +0, frame +1, looping.)
	.byte 1,1,1,2,2,2,2,3 ; speed option 1, 2, 3, 4, two values each.
	.byte 3,3,3,4,4,4,4,5 


; ======== E N D   O F   V A R I A B L E S ======== 
