;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2023 Ken Jennings
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
	.by "** Ken Jennings  2023 **"



; ==========================================================================
; TIMING PER VIDEO STANDARD . . .
; Motion/positioning controls:
; At startup, the program determines the video standard and then sets 
; gNTSCorPAL and the gMaxNTSCorPALFrames limit accordingly.
; The VBI increments the Frame Counter (THIS_FRAME) up to the limits of
; gMaxNTSCorPALFrames and resets to 0 as needed.
;
; The original game on the C64 uses speed/pixel counts based on 
; higher resolution which required the Atari version already scale 
; the movements across multiple frames.   In order to accommodate PAL
; this scaling has to be scaled further to make 5 PAL frames
; the equivalent of 6 NTSC frames.
;
; And so, in order to scale PAL to meet NTSC speed specifications there 
; is an array of multiple entries providing the speed/increment values 
; with the PAL sequence of five frames adjusted to match the same 
; distance over six NTSC frames.
;
; The VBI uses the Frame counter plus the video standard flag (0/1) to 
; acquire values from tables used to populate the current INC value and 
; speed control.
;
; Other common cycles (animation loops, etc.) just iterate per each
; VBI.  I judged speed scaling for these not so important.
;
; Basic lookup for Player and Laser control:
; INDEX == ( THIS_FRAME * 2 ) + gNTSCorPALflag
; INC_PLAYER = TABLE_PLAYER_X[ INDEX ]
; INC_LASER = TABLE_LASER_Y[ INDEX ]
;
; Extended lookup for Mothership:
; INDEX == ( MOTHERSHIP_MOVE_SPEED * 12) + ( THIS_FRAME * 2 ) + gNTSCorPALflag
; MOTHERSHIP_MOVEMENT = TABLE_SPEED_CONTROL[ INDEX ]

PAL_FRAMES=$5
NTSC_FRAMES=$6

gNTSCorPAL                  .byte $01         ; Clear (0) = PAL/SECAM, Set (1) = NTSC
gMaxNTSCorPALFrames         .byte NTSC_FRAMES ; Max number of frames per video standard (see tables)

gTHIS_FRAME                 .byte $00         ; Frame counter 0 to 4 (PAL) or 0 to 5 (NTSC) 
gINC_PLAYER_X               .byte $00         ; X Value to add this frame
gINC_LASER_Y                .byte $00         ; Y value to add this frame
;gINC_MOTHERSHIP_X           .byte $00         ; X Value to add this frame (Speed control)
gMOTHERSHIP_MOVEMENT        .byte $00 ; Value to add/subtract from Mothership X

gMOTHERSHIP_MOVE_SPEED      .byte $00 ; Game mothership speed index into speed table 0, 2, 4, ..., 14 
gMOTHERSHIP_SPEEDUP_COUNTER .byte $00 ; Game mothership speed up counter 
gMOTHERSHIP_PROGRESSIVE     .byte $00 ; Counts 10, 9, 8, 7, 6...

; Run-time config for frame limits for PAL or NTSC video modes. Index by gNTSCorPAL.
TABLE_NTSC_OR_PAL_FRAMES     
	.byte PAL_FRAMES,NTSC_FRAMES

; How many pixels to move the Player each frame.  PAL, NTSC per each.
; Technically, we can simply use as flag whether or not to process
; horizontal movement for the player.   If this is 1, then movement
; can occur.
; Lookup X == ( THIS_FRAME * 2 ) + gNTSCorPALflag
TABLE_PLAYER_CONTROL 
	.byte 0,0 ; Frame 1, PAL, NTSC
	.byte 1,1 ; Frame 2, PAL, NTSC
	.byte 0,0 ; Frame 3, PAL, NTSC
	.byte 1,1 ; Frame 4, PAL, NTSC
	.byte 1,0 ; Frame 5, PAL, NTSC
	.byte 0,1 ; Frame 6, (-), NTSC

; How many pixels to move the Laser each frame.  PAL, NTSC per each.
; Lookup X == ( THIS_FRAME * 2 ) + gNTSCorPALflag
TABLE_LASER_CONTROL
	.byte 2,2 ; Frame 1, PAL, NTSC
	.byte 3,2 ; Frame 2, PAL, NTSC
	.byte 2,2 ; Frame 3, PAL, NTSC
	.byte 3,2 ; Frame 4, PAL, NTSC
	.byte 2,2 ; Frame 5, PAL, NTSC
	.byte 0,2 ; Frame 6, (-), NTSC
	
	.byte 5,4 ; Frame 1, PAL, NTSC
	.byte 5,4 ; Frame 2, PAL, NTSC
	.byte 4,4 ; Frame 3, PAL, NTSC
	.byte 5,4 ; Frame 4, PAL, NTSC
	.byte 5,4 ; Frame 5, PAL, NTSC
	.byte 0,4 ; Frame 6, (-), NTSC

	.byte 7,6 ; Frame 1, PAL, NTSC
	.byte 7,6 ; Frame 2, PAL, NTSC
	.byte 8,6 ; Frame 3, PAL, NTSC
	.byte 7,6 ; Frame 4, PAL, NTSC
	.byte 7,6 ; Frame 5, PAL, NTSC
	.byte 0,6 ; Frame 6, (-), NTSC
	
; How many pixels to horizontally move the mothership.  Pal, NTSC per each.
; Since there are multiple speed values for the mothership, there 
; is a control table for each of the speed values.
; Since there are 12 entries (6 PAL, 6 NTSC) per each mothership speed 
; setting the starting point of each is 12 times the mothership speed.
; To make the times 12 easier, provide a direct lookup.
; Lookup X == ( MOTHERSHIP_MOVE_SPEED * 12) + ( THIS_FRAME * 2 ) + gNTSCorPALflag

TABLE_TIMES_TWELVE
	.byte 0,12,24,36,38,60,72,84

;	.byte 1,1,1,2,2,2,2,3 ; speed option 1, 2, 3, 4, two values each.
;	.byte 3,3,3,4,4,4,4,5 
; How many pixels to move the mothership each frame.   PAL, NTSC per each.
TABLE_SPEED_CONTROL
; Mothership speed 1
	.byte 1,1 ; Frame 1, PAL, NTSC
	.byte 1,1 ; Frame 2, PAL, NTSC
	.byte 2,1 ; Frame 3, PAL, NTSC
	.byte 1,1 ; Frame 4, PAL, NTSC
	.byte 1,1 ; Frame 5, PAL, NTSC
	.byte 0,1 ; Frame 6, (-), NTSC
; Mothership speed 2
	.byte 2,1 ; Frame 1, PAL, NTSC
	.byte 2,2 ; Frame 2, PAL, NTSC
	.byte 1,1 ; Frame 3, PAL, NTSC
	.byte 2,2 ; Frame 4, PAL, NTSC
	.byte 2,1 ; Frame 5, PAL, NTSC
	.byte 0,2 ; Frame 6, (-), NTSC
; Mothership speed 3
	.byte 2,2 ; Frame 1, PAL, NTSC
	.byte 2,2 ; Frame 2, PAL, NTSC
	.byte 3,2 ; Frame 3, PAL, NTSC
	.byte 2,2 ; Frame 4, PAL, NTSC
	.byte 3,2 ; Frame 5, PAL, NTSC
	.byte 0,2 ; Frame 6, (-), NTSC
; Mothership speed 4
	.byte 3,2 ; Frame 1, PAL, NTSC
	.byte 3,3 ; Frame 2, PAL, NTSC
	.byte 3,2 ; Frame 3, PAL, NTSC
	.byte 3,3 ; Frame 4, PAL, NTSC
	.byte 3,2 ; Frame 5, PAL, NTSC
	.byte 0,3 ; Frame 6, (-), NTSC
; Mothership speed 5
	.byte 3,3 ; Frame 1, PAL, NTSC
	.byte 4,3 ; Frame 2, PAL, NTSC
	.byte 3,3 ; Frame 3, PAL, NTSC
	.byte 4,3 ; Frame 4, PAL, NTSC
	.byte 4,3 ; Frame 5, PAL, NTSC
	.byte 0,3 ; Frame 6, (-), NTSC
; Mothership speed 6
	.byte 4,3 ; Frame 1, PAL, NTSC
	.byte 4,4 ; Frame 2, PAL, NTSC
	.byte 5,3 ; Frame 3, PAL, NTSC
	.byte 4,4 ; Frame 4, PAL, NTSC
	.byte 4,3 ; Frame 5, PAL, NTSC
	.byte 0,4 ; Frame 6, (-), NTSC
; Mothership speed 7
	.byte 5,4 ; Frame 1, PAL, NTSC
	.byte 5,4 ; Frame 2, PAL, NTSC
	.byte 4,4 ; Frame 3, PAL, NTSC
	.byte 5,4 ; Frame 4, PAL, NTSC
	.byte 5,4 ; Frame 5, PAL, NTSC
	.byte 0,4 ; Frame 6, (-), NTSC
; Mothership speed 8
	.byte 5,4 ; Frame 1, PAL, NTSC
	.byte 5,5 ; Frame 2, PAL, NTSC
	.byte 6,4 ; Frame 3, PAL, NTSC
	.byte 5,5 ; Frame 4, PAL, NTSC
	.byte 6,4 ; Frame 5, PAL, NTSC
	.byte 0,5 ; Frame 6, (-), NTSC


; ==========================================================================
; OTHER MOTHERSHIP VALUES . . .

MOTHERSHIP_MIN_X     = 40  ; Farthest Left off the normal width screen.
MOTHERSHIP_MAX_X     = 208 ; Farthest right off the normal width screen.
MOTHERSHIP_MIN_Y     = 36  ; starting position of mothership, last position for laser.
MOTHERSHIP_MIN_OFF_X = 15  ; Completely off screen, not visible.
MOTHERSHIP_MAX_OFF_X = 232 ; Completely off screen, not visible.

gMOTHERSHIP_MIN_X           .byte MOTHERSHIP_MIN_X
gMOTHERSHIP_MAX_X           .byte MOTHERSHIP_MAX_X

gMOTHERSHIP_X               .byte $00 ; Game mothership X coord 
gMOTHERSHIP_NEW_X           .byte $00 ; Game mothership X coord 
gMOTHERSHIP_Y               .byte $00 ; Game mothership Y coord 
gMOTHERSHIP_NEW_Y           .byte $00 ; Game mothership Y coord 

gMOTHERSHIP_DIR             .byte $00 ; Mothership direction.  0 = left to right.   1 = Right to Left

MOTHERHIP_START_ANIM=3
gMOTHERSHIP_ANIM            .byte $00 ; Animation frame for windows on small mothership
gMOTHERSHIP_BIG_ANIM        .byte $00 ; Animation Frame for windows on big mothership. 0 to 13
gMOTHERSHIP_ANIM_CLOCK      .byte MOTHERHIP_START_ANIM   ; delay for animation 

MOTHERSHIP_START_CLOCK1=60            ; The light on top of the ship
gMOTHERSHIP_LIGHT_CLOCK1    .byte MOTHERSHIP_START_CLOCK1
gMOTHERSHIP_LIGHT1          .byte $1  ; toggle $0, $1 for off and on

MOTHERSHIP_START_CLOCK2=61            ; The light on the left leg 
gMOTHERSHIP_LIGHT_CLOCK2    .byte MOTHERSHIP_START_CLOCK2
gMOTHERSHIP_LIGHT2          .byte $1  ; toggle $0, $1 for off and on

MOTHERSHIP_START_CLOCK3=62            ; The light on the right leg 
gMOTHERSHIP_LIGHT_CLOCK3    .byte MOTHERSHIP_START_CLOCK3
gMOTHERSHIP_LIGHT3          .byte $1  ; toggle $0, $1 for off and on

gMOTHERSHIP_ROW             .byte $00 ; Game mothership text line row number
gMOTHERSHIP_HITS            .byte $00 ; Number of times the mothership is hit.

;zMOTHERSHIP_SHOT_BY_ONE     .byte $0  ; Collision between PM0 (shot) and PM2
;zMOTHERSHIP_SHOT_BY_TWO     .byte $0  ; Collision between PM1 (shot) and PM2

gEXPLOSION_ON               .byte $00 ; Explosion is present.   
gEXPLOSION_COUNT            .byte $00 ; Timer/index for Explosion. 
gEXPLOSION_X                .byte $00 
gEXPLOSION_Y                .byte $00
gEXPLOSION_NEW_Y            .byte $00


; ==========================================================================
; COUNTDOWN 3, 2, 2, GO! COLOR . . .

gCOUNTDOWN_TIMER       .byte $01
gCOUNTDOWN_COLOR       .byte $04



; ==========================================================================
; SCORING . . .

;zSHOW_SCORE_FLAG             .byte $00 ; Flag to update score on screen.

gMOTHERSHIP_POINTS_AS_DIGITS .byte $00,$00,$00,$00,$00,$00 ; Points for current row.

gPLAYERPOINTS_TO_ADD         .byte $00,$00,$00,$00,$00,$00 ; Mothership points to add to player

gPLAYER_SCORE      
gPLAYER_ONE_SCORE            .byte $00,$00,$00,$00,$00,$00 ; Player 1 score, 6 digit BCD 
gPLAYER_TWO_SCORE            .byte $00,$00,$00,$00,$00,$00 ; Player 2 score, 6 digits 

gHIGH_SCORE                  .byte $00,$00,$00,$00,$00,$00 ; 6 digits

gSCORES_ON                   .byte $01 ; Flag that scores are visible.


; ==========================================================================
; PLAYER STUFF  . . .

gONESIE_PLAYER .byte 0 ; Which player is active now in Onesie mode



; ==========================================================================
; STATISTICS . . .

gSHIP_HITS_AS_DIGITS        .byte $00,$00,$00,$00 ; Remaining hits on mothership as digits.
gMOTHERSHIP_ROW_AS_DIGITS   .byte $00,$00 ; Mothership text line row number as 2 digits for display


; ==========================================================================
; TITLE SCREEN TAG LINE . . .

STE_WAIT=0
STE_FIN0=1
STE_FIN1=2
STE_FINO=3
STE_LMS=$80

; index to state engine array. 
GFX_TAG_INDEX    .byte 0 

; current jiffy counter.  When this is 0, then do the next steps (or loop)
GFX_TAG_COUNTER  .byte 0 

; How many jiffies to wait for each STEP in a state
TABLE_TAG_STEP_JIFFIES  
	.byte 0,60,1,65,1      ; (ONE BUTTON)
	.byte 0,55,1,65,1      ; (ONE ALIEN)
	.byte 0,55,1,65,1      ; (ONE LIFE)
	.byte 0,55,1,45,1,70,1 ; (NO MERCY)

; Countdown the steps (loops) for the current state.  When 0, then do next State.
GFX_TAG_STEPS   .byte 0 

; How many times does this state loop?  (for fade in/out animations.) Index by STATE
TABLE_TAG_STATE_STEPS    
	.byte 0,8,16,0,16      ; (ONE BUTTON)
	.byte 0,0,16,0,16      ; (ONE ALIEN)
	.byte 0,0,16,0,16      ; (ONE LIFE)
	.byte 0,0,16,0,16,1,16 ; (NO MERCY)

; Current state being executed. 
GFX_TAG_STATE   .byte 0 

; State list for engine.
TABLE_TAG_ENGINE_STATES
	.byte STE_LMS|0,STE_WAIT,STE_FIN0,STE_WAIT,STE_FINO                   ; (ONE BUTTON)
	.byte STE_LMS|1,STE_WAIT,STE_FIN0,STE_WAIT,STE_FINO                   ; (ONE ALIEN)
	.byte STE_LMS|2,STE_WAIT,STE_FIN0,STE_WAIT,STE_FINO                   ; (ONE LIFE)
	.byte STE_LMS|3,STE_WAIT,STE_FIN0,STE_WAIT,STE_FIN1,STE_WAIT,STE_FINO ; (NO MERCY)
	.byte $FF

; Address of text string for LMS.  Index by LINE.
TABLE_GFX_TAG_LMS            
	.byte <GFX_TAG_TEXT      ; (ONE BUTTON)
	.byte <[GFX_TAG_TEXT+16] ; (ONE ALIEN)
	.byte <[GFX_TAG_TEXT+32] ; (ONE LIFE)
	.byte <[GFX_TAG_TEXT+48] ; (NO MERCY)



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

; Table to convert row to Y coordinate for mothership.
; This is also do-able with a LSR to multiply times 8 then add offset.

TABLE_ROW_TO_Y ; r2ytab 
	.byte 36,44,52,60     ; 0  - 3   ; 36 + ( Y * 8 )
	.byte 68,76,84,92     ; 4  - 7
	.byte 100,108,116,124 ; 8  - 11
	.byte 132,140,148,156 ; 12 - 15
	.byte 164,172,180,188 ; 16 - 19
	.byte 196,204,212     ; 20 - 22

TABLE_TO_DIGITS ; 0 to 21.  (22 is last row which should be undisplayed.)
	.byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09
	.byte $10,$11,$12,$13,$14,$15,$16,$17,$18,$19
	.byte $20,$21,$22


; ==========================================================================

; Are there really 8 stars? In the video it appears there are 4
; visible on screen at any time.  It seems like the code wraps  
; around at 6, so ...? 

TABLE_STAR_LOCATION ; star
	.byte 0,32,64,96       ; eight
	.byte 128,160,192,224  ; stars
 

; Game Over Text Values =====================================================

DELAYED .byte 60

gGAME_OVER_FLAG             .byte $00  ; The game is over?

; Automatic return to title screen
gGAME_OVER_FRAME            .byte 0    ; Frame counter 255 to 0
gGAME_OVER_TICKS            .byte 0    ; decrement every GAME_OVER_FRAME=0.  Large countdown.

; Game Screen Stars Control values ==========================================

gTEMP_NEW_STAR_ID  .byte 0 ; gives the star 3, 2, 1, 0

gTEMP_NEW_STAR_ROW .byte 0 ; Row number for star 0 to 17.


; Star and Cheat Mode "Star" ================================================

CHEAT_CLOCK = 60

gSTARS_CHEAT_CLOCK .byte 0           ; countodown to change graphic

gCHEAT_IMAGE_INDEX .byte $ff         ; 0-4 current cheat char.

gCHEAT_IMAGE_TABLE                   ; gCHEAT_IMAGE_INDEX * 8 is index.

; Char $0A:   *                      ; Revise Star again for Atari for Mode 6 color
;	.byte $08,$00,$08,$2A,$08,$00,$08,$00
; $08: . . . . # . . . 
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $2A: . . # . # . # . 
; $08: . . . . # . . . 
; $00: . . . . . . . . 
; $08: . . . . # . . . 
; $00: . . . . . . . . 


; Char $23:   C    
	.byte $3C,$40,$40,$40,$40,$40,$7C,$00
; $3C: . . # # # # . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 

; Char $28:   H    
	.byte $44,$44,$44,$5C,$44,$44,$44,$00
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $5C: . # . # # # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
; $00: . . . . . . . . 

; Char $25:   E    
	.byte $7C,$40,$40,$58,$40,$40,$7C,$00
; $7C: . # # # # # . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $58: . # . # # . . . 
; $40: . # . . . . . . 
; $40: . # . . . . . . 
; $7C: . # # # # # . . 
; $00: . . . . . . . . 


; Char $21:   A    
	.byte $04,$0C,$14,$24,$5C,$44,$44
; $04: . . . . . # . . 
; $0C: . . . . # # . . 
; $14: . . . # . # . . 
; $24: . . # . . # . . 
; $5C: . # . # # # . . 
; $44: . # . . . # . . 
; $44: . # . . . # . . 
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


; ======== E N D   O F   V A R I A B L E S ======== 
