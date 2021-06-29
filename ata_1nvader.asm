;*******************************************************************************
;*
;* C64 1NVADER - 2019 Darren Foulds
;*
;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings                        
;*                                                                             
;*******************************************************************************

; ==========================================================================
; Atari System Includes (MADS assembler)
	icl "ANTIC.asm" ; Display List registers
	icl "GTIA.asm"  ; Color Registers.
	icl "POKEY.asm" ;
	icl "PIA.asm"   ; Controllers
	icl "OS.asm"    ;
	icl "DOS.asm"   ; LOMEM, load file start, and run addresses.
; --------------------------------------------------------------------------

; ==========================================================================
; Macros (No code/data declared)
	icl "macros.asm"

; --------------------------------------------------------------------------

; ==========================================================================
; Declare some Page Zero variables.
; The Atari OS owns the first half of Page Zero.

; The Atari load file format allows loading from disk to anywhere in
; memory, therefore indulging in this evilness to define Page Zero
; variables and load directly into them at the same time...
; --------------------------------------------------------------------------

	ORG $80


; Game State Control Values ==================================================

zCurrentEvent      .byte $00 ; Global Current Game Behavior.
zEventStage        .byte $00 ; Substage 


; Timer Values ===============================================================

zAnimateFrames     .byte $00 
zInputScanFrames   .byte $00


; Countdown Color =========================================================

zCountdownTimer       .byte $01
zCountdownColor       .byte $04


; Title Logo Values =========================================================

TITLE_SPEED_GFX        = 6                        ; jiffies to count for title color animations
zAnimateTitleGfx       .byte TITLE_SPEED_GFX      ; countdown jiffies. At 0 the animation changes.

TITLE_LOGO_FRAME_MAX   = 3                        ; Four frames, Count 3, 2, 1, 0
zTITLE_LOGO_FRAME      .byte 0                    ; current frame for big graphic logo gfx

TITLE_SPEED_PM         = 3                       ; jiffies to count for title Missile animations
zAnimateTitlePM        .byte TITLE_SPEED_PM       ; countdown jiffies. At 0 the animation changes.

TITLE_LOGO_PMIMAGE_MAX = 44                       ; 43 frames of images.  back to 0 when this is max.
zTitleLogoPMFrame      .byte $00

TITLE_LOGO_X_START     = 78
zTitleHPos             .byte TITLE_LOGO_X_START   ; Missile position.

TITLE_LOGO_Y_POS       = 71                       ; Just a constant.  No need for variable.

ZTitleLogoBaseColor   .byte COLOR_ORANGE1         ; Starting value for first DLI. 
ZTitleLogoColor       .byte COLOR_ORANGE1         ; Value for DLI. Loop from $10 to $E0 by 16


; Scrolling Credits Values ==================================================

; GFX_SCROLL_CREDIT1  ;   +0, HSCROL 12   ; +30, HSCROL 12
; GFX_SCROLL_CREDIT2  ;  +30, HSCROL 12   ;   +0, HSCROL 12

; DL_LMS_SCROLL_CREDIT1  +0 to +30   - inc LMS, dec HS ("Move" data left)
; DL_LMS_SCROLL_CREDIT2  +30 to +0     dec LMS, inc HS ("move" data right)

CREDITS_MAX_PAUSE   = $FF
zCreditsTimer       .byte CREDITS_MAX_PAUSE  ; Number of jiffies to Pause.  When 0, run scroll.

CREDITS_STEP_TIMER   = 1
zCreditsScrollTimer .byte CREDITS_STEP_TIMER ; How many frames to wait for each fine scroll.

zCreditsPhase       .byte $00  ; 0 == waiting  1 == scrolling.
zCreditsMotion      .byte $00  ; 0 == left/right !0 == right/left

zCredit1HS          .byte 12   ; fine horizontal scroll value start.
zCredit2HS          .byte 12   ; fine horizontal scroll value start.


; Big Mothership Values =====================================================

BIG_MOTHERSHIP_START = 127 
zBIG_MOTHERSHIP_Y   .byte BIG_MOTHERSHIP_START ; Starting position of the big mothership

BIG_MOTHERSHIP_SPEED = 1 ; Number of frames to count per move.
zBigMothershipSpeed .byte BIG_MOTHERSHIP_SPEED ; How many frames to wait per mothership move.

zBigMothershipPhase .byte 0 ;  0 = steady  !0 = Moving up.


; Scrolling Documentation Values ==================================================

DOCS_STEP_TIMER  = 2
zDocsScrollTimer .byte DOCS_STEP_TIMER ; How many frames to wait for each fine scroll.

zDocsHS          .byte 15   ; fine horizontal scroll value start.


; Scrolling Terrain Values ==================================================
; The mountains are a constant component on the Title and Game screens.
; The motion is continuous.  There is never a time where this is considered 
; idle, or must be reset to start at the beginning.
; Display List LMS initialization for the mountains happens in the Display 
; List declaration. 

; Gfx Rows and LMS are 1, 2, 3, 4...  
; GFX_MOUNTAINS1  ;   +0, HSCROL 8   ; +20, HSCROL 0

; DL_LMS_SCROLL_LAND1 ;  +0 to +20   - inc LMS, dec HS ("Move" data left)
;                     ;  +20 to +0     dec LMS, inc HS ("move" data right)

LAND_MAX_PAUSE   = $FF
zLandTimer       .byte LAND_MAX_PAUSE  ; Number of jiffies to Pause.  When 0, run scroll.

LAND_STEP_TIMER   = 6
zLandScrollTimer .byte LAND_STEP_TIMER ; How many frames to wait for each fine scroll.

zLandPhase       .byte $00  ; 0 == waiting  1 == scrolling.
zLandMotion      .byte $00  ; 0 == left/right !0 == right/left

zLandHS          .byte 0   ; fine horizontal scroll value start.
zLandColor       .byte 0   ; index for repeat DLIs on the scrolling land 


; Flickering Stars values ==================================================

zDLIStarLinecounter .byte 0 


; Generic Player/Missile Data Copying =======================================

zPMG_IMAGE    .word 0 ; points to image data

zPMG_HARDWARE .word 0 ; points to the Player/Missile memory map.

SHPOSP0 .byte 0 ; Fake Shadow register for HPOSP0
SHPOSP1 .byte 0 ; Fake Shadow register for HPOSP1
SHPOSP2 .byte 0 ; Fake Shadow register for HPOSP2
SHPOSP3 .byte 0 ; Fake Shadow register for HPOSP3
SHPOSM0 .byte 0 ; Fake Shadow register for HPOSM0
SHPOSM1 .byte 0 ; Fake Shadow register for HPOSM1
SHPOSM2 .byte 0 ; Fake Shadow register for HPOSM2
SHPOSM3 .byte 0 ; Fake Shadow register for HPOSM3


; Game Screen Stars Control values ==========================================

zDL_LMS_STARS_ADDR .word 0 ; points to the LMS to change

zTEMP_NEW_STAR_ID  .byte 0 ; gives the star 3, 2, 1, 0

zTEMP_NEW_STAR_ROW .byte 0 ; Row number for star 0 to 17.

zTEMP_ADD_STAR     .byte 0 ; Flag, 0 = no star to add.  !0 = Try adding a new star.

zTEMP_BASE_COLOR   .byte 0 ; temporary color for star
zTEMP_BASE_COLOR2  .byte 0 ; temporary color for star

zSTAR_COUNT        .byte 0 ; starcnt original code.


; Game Over Text Values =====================================================

zGAME_OVER_TEXT .word 0


; Misc Control Values  =====================================================

zThisDLI .byte 0




; Game Control Values =======================================================

zSHOW_SCORE_FLAG   .byte $00 ; Flag to update score on screen.

zSHIP_HITS           .byte $00  ; integer
zSHIP_HITS_AS_DIGITS .byte $0,$0 ; 

zCOUNTDOWN_FLAG    .byte $00 ; Counts phase, 4, 3, 2, 1, 0.  When it returns to 0, then trigger next phase (game)
zCOUNTDOWN_SECS    .byte $00 ; Countdown jiffies per tick tock event. (the 3, 2, 1, GO)

zSTATS_TEXT_COLOR  .byte $08 ; color/luminance of text on stats line.



PLAYER_PLAY_Y=212   ; Y position for gun in play
PLAYER_IDLE_Y=220   ; Y position for gun idle on stats line
PLAYER_SQUASH_Y=228 ; Y Position when player not playing.

PLAYER_MIN_X =52  ; Farthest left next to bumper  ( Min screeen X + bumper width)
PLAYER_MAX_X =197 ; Farthest right next to bumper ( Max screen X - bumper width - gun width)

PLAYER_X_SIZE=7   ; Width of guns in color clocks.  Needed for collision evaluation.

LASER_START=208   ; Player gun Y  (PLAYER_PLAY_Y) - 4.
LASER_END_Y=36    ; also MOTHERSHIP_MIN_Y

; Player 1 and player 2 values are interleaved.
; I have a stupid idea of using an index for 
; the players, and where applicable calling the 
; same function for both players using only a 
; different index for the players, and so only
; one version of code.... in theory.

zAnimatePlayers    .byte 2   ; animation counter.   Players can move every other frame.

zPLAYER_ON
zPLAYER_ONE_ON     .byte $FF ; (0) not playing. (FF)=Title/Idle  (1) playing.
zPLAYER_TWO_ON     .byte $ff ; (0) not playing. (FF)=Title/Idle  (1) playing.

zPLAYER_PMG
zPLAYER_ONE_PMG    .byte >PLAYERADR0 ; Player 1 Cannon and Laser (high byte)
zPLAYER_TWO_PMG    .byte >PLAYERADR1 ; Player 2 Cannon and Laser (high byte)

zPLAYER_X
zPLAYER_ONE_X      .byte [PLAYER_MIN_X+40] ; Player 1 gun X coord
zPLAYER_TWO_X      .byte [PLAYER_MAX_X-40] ; Player 2 gun X coord 

zPLAYER_NEW_X
zPLAYER_ONE_NEW_X  .byte [PLAYER_MIN_X+40] ; Player 1 gun X coord
zPLAYER_TWO_NEW_X  .byte [PLAYER_MAX_X-40] ; Player 2 gun X coord 

zPLAYER_Y
zPLAYER_ONE_Y      .byte 0 
zPLAYER_TWO_Y      .byte 0 

zPLAYER_NEW_Y
zPLAYER_ONE_NEW_Y  .byte PLAYER_IDLE_Y ; Player 1 Y position (slight animation, but usually fixed position.) 212=game.  220=idle.
zPLAYER_TWO_NEW_Y  .byte PLAYER_IDLE_Y ; Player 2 Y position (slight animation, but usually fixed.)

zPLAYER_DIR
zPLAYER_ONE_DIR    .byte $00 ; Player 1 direction ; 0 == left to right. 1 == right to left.
zPLAYER_TWO_DIR    .byte $00 ; Player 2 direction ; 0 == left to right. 1 == right to left.

zPLAYER_FIRE
zPLAYER_ONE_FIRE   .byte $00 ; Player 1 fire flag (laser 1 color)
zPLAYER_TWO_FIRE   .byte $00 ; Player 2 fire flag (laser 2 color)

zPLAYER_DEBOUNCE      
zPLAYER_ONE_DEBOUNCE .byte $00 ; Set when laser is shot.   cleared when button released.  Cannot shoot again unless button released.
zPLAYER_TWO_DEBOUNCE .byte $00 ; Set when laser is shot.   cleared when button released.  Cannot shoot again unless button released.

zPLAYER_COLOR
zPLAYER_ONE_COLOR  .byte $00 ; Player 1 current color 
zPLAYER_TWO_COLOR  .byte $00 ; Player 2 current color 

zPLAYER_BUMP
zPLAYER_ONE_BUMP   .byte $00 ; Player 1 direction change is flagged
zPLAYER_TWO_BUMP   .byte $00 ; Player 2 direction change is flagged

zPLAYER_CRASH
zPLAYER_ONE_CRASH  .byte $00 ; Player 1 being pushed by mothership
zPLAYER_TWO_CRASH  .byte $00 ; Player 2 being pushed by mothership

zPLAYER_REDRAW
zPLAYER_ONE_REDRAW .byte $00 ; 0 = skip image update.  1 = redraw.
zPLAYER_TWO_REDRAW .byte $00 ; 0 = skip image update.  1 = redraw.

zPLAYER_SHOT_THE_SHERIFF
zPLAYER_ONE_SHOT_THE_SHERIFF .byte $00 ; Flag that Player 1 shot the mothership
zPLAYER_TWO_SHOT_THE_SHERIFF .byte $00 ; Flag that Player 2 shot the mothership

zLASER_ON
zLASER_ONE_ON      .byte $01 ; whether or not the laser is shooting
zLASER_TWO_ON      .byte $00 ; whether or not the laser is shooting

zLASER_X
zLASER_ONE_X       .byte $00 ; Laser 1 X coord
zLASER_TWO_X       .byte $00 ; Laser 2 X coord

zLASER_Y
zLASER_ONE_Y       .byte $00 ; Laser 1 Y coord
zLASER_TWO_Y       .byte $00 ; Laser 2 Y coord

zLASER_NEW_Y
zLASER_ONE_NEW_Y   .byte $00 ; Laser 1 Y coord
zLASER_TWO_NEW_Y   .byte $00 ; Laser 2 Y coord

zLASER_BANG
zLASER_ONE_BANG    .byte $00 ; Laser 1 collision with mothership (P0 to P2)
zLASER_TWO_BANG    .byte $00 ; Laser 2 collision with mothership (P1 to P2) 

zLASER_COLOR 
zLASER_ONE_COLOR    .byte $00 ; Laser 1 index into TABLE_COLOR_LASERS
zLASER_TWO_COLOR    .byte $00 ; Laser 2 index into TABLE_COLOR_LASERS 




; ======== V B I ======== The world's most inept sound system.

; Pointer used by the VBI service routine for the current sequence under work:
SOUND_POINTER .word $0000

; Pointer to the sound entry in use for each voice.
SOUND_FX_LO
SOUND_FX_LO0 .byte 0
SOUND_FX_LO1 .byte 0
SOUND_FX_LO2 .byte 0
SOUND_FX_LO3 .byte 0 

SOUND_FX_HI
SOUND_FX_HI0 .byte 0
SOUND_FX_HI1 .byte 0
SOUND_FX_HI2 .byte 0
SOUND_FX_HI3 .byte 0 

; Sound Control value coordinates between the main process and the VBI 
; service routine to turn on/off/play sounds. Control Values:
; 0   = Set by Main to direct VBI to stop managing sound pending an 
;       update from MAIN. This does not stop the POKEY's currently 
;       playing sound.  It is set by the VBI when a sequence is complete 
;       to indicate the channel is idle/unmanaged. 
; 1   = MAIN sets to direct VBI to start playing a new sound FX.
; 2   = VBI sets when it is playing to inform MAIN that it has taken 
;       direction and is now busy.
; 255 = Direct VBI to silence the channel immediately.
;
; So, the procedure for playing sound.
; 1) MAIN sets the channel's SOUND_CONTROL to 0.
; 2) MAIN sets the channel's SOUND_FX_LO/HI pointer to the sound effects 
;    sequence to play.
; 3) MAIN sets the channel's SOUND_CONTROL to 1 to tell VBI to start.
; 4) VBI sets the channel's SOUND_CONTROL value to 2 when playing, then 
;    when the sequence is complete, back to value 0.

SOUND_CONTROL
SOUND_CONTROL0  .byte $00
SOUND_CONTROL1  .byte $00
SOUND_CONTROL2  .byte $00
SOUND_CONTROL3  .byte $00

; When these are non-zero, the current settings continue for the next frame.
SOUND_DURATION
SOUND_DURATION0 .byte $00
SOUND_DURATION1 .byte $00
SOUND_DURATION2 .byte $00
SOUND_DURATION3 .byte $00


; In the event stupid programming tricks means some things can't be saved on 
; the stack, then protect them here....
SAVEA = $FD
SAVEX = $FE
SAVEY = $FF


; ======== E N D   O F   P A G E   Z E R O ======== 



; Now for the Code...
; Should be the first usable memory after DOS (and DUP?).

	ORG LOMEM_DOS
;	ORG LOMEM_DOS_DUP ; Use this if following DOS won't work.  or just use $5000 or $6000

	; Label And Credit Where Ultimate Credit Is Due
	.by "** Thanks to the Word (John 1:1), Jesus Christ, Creator of heaven, "
	.by "and earth, and semiconductor chemistry and physics making all this "
	.by "fun possible. "
	.by "** ATARI 1NVADER "
	.by "** Atari 8-bit computer systems. "
	.by "** Ken Jennings  2021 **"



; TEMPORARILY RELOACATE TO HIGHER MEMORY AS PAGE ZERO BECAME FILLED WITH CRUFTY TEMPORARY VARIABLES




; Note that the original game dealt with some things in BCD values, 
; such as the Mothership row here making it a little more convenient to 
; convert hex values to printable characters on the screen.  This makes 
; using the value as an index a royal pain.  For sanity's sake this 
; port is going to use it as a plain integer/binary byte value and do 
; the special handling for the screen display part.
; This is why the original code has weird gaps in some lookup tables.

MOTHERSHIP_MIN_X = 40  ; Farthest Left off the normal width screen.
MOTHERSHIP_MAX_X = 208 ; Farthest right off the normal width screen.
MOTHERSHIP_MIN_Y = 36  ; starting position of mothership, last position for laser.

zMOTHERSHIP_X               .byte $00 ; Game mothership X coord 
zMOTHERSHIP_NEW_X           .byte $00 ; Game mothership X coord 
zMOTHERSHIP_Y               .byte $00 ; Game mothership Y coord 
zMOTHERSHIP_NEW_Y           .byte $00 ; Game mothership Y coord 

zMOTHERSHIP_DIR             .byte $00 ; Mothership direction.  0 = left to right.   1 = Right to Left
zMOTHERSHIP_ANIM            .byte $00 ; Animation frame for windows
zMOTHERSHIP_ANIM_FRAME      .byte 3   ; delay for animation 
zMOTHERSHIP_MOVE_SPEED      .byte $00 ; Game mothership speed  
zMOTHERSHIP_MOVE_COUNTER    .byte $00 ; Game mothership speed counter 
zMOTHERSHIP_SPEEDUP_THRESH  .byte $00 ; Game mothership speed up threahold 
zMOTHERSHIP_SPEEDUP_COUNTER .byte $00 ; Game mothership speed up counter 
zMOTHERSHIP_ROW             .byte $00 ; Game mothership text line row number
zMOTHERSHIP_ROW_AS_DIGITS   .byte $0,$0 ; Mothership text line row number as 2 digits for display


zMOTHERSHIP_SHOT_BY_ONE     .byte $0  ; Collision between PM0 (shot) and PM2
zMOTHERSHIP_SHOT_BY_TWO     .byte $0  ; Collision between PM1 (shot) and PM2

zEXPLOSION_COUNT            .byte $00
zEXPLOSION_X                .byte $00 
zEXPLOSION_NEW_X            .byte $00 
zEXPLOSION_Y                .byte $00
zEXPLOSION_NEW_Y            .byte $00

zMOTHERSHIP_COLOR           .byte $00 ; Game mothership color.

zMOTHERSHIP_POINTS          .word $0000 ; Current Points for hitting mothership
zMOTHERSHIP_POINTS_AS_DIGITS .byte $0,$0,$0,$0,$0,$0 ; Points to add to score.

zJOY_ONE_LAST_STATE         .byte $00 ; Joystick Button One last state.
zJOY_TWO_LAST_STATE         .byte $00 ; Joystick Button Two last state

zHIGH_SCORE                 .byte $00,$00,$00,$00,$00,$00 ; 6 digits

zPLAYER_SCORE       ; This may not be indexable like the rest of it.
zPLAYER_ONE_SCORE  .byte $00,$00,$00,$00,$00,$00 ; Player 1 score, 6 digit BCD 
zPLAYER_TWO_SCORE  .byte $00,$00,$00,$00,$00,$00 ; Player 2 score, 6 digits 






; Player/Missile object states.  X, Y, counts, etc where needed =============

; Note that each table is in the same order listing each visible 
; screen object for the Game.
; (Note the title screen components as the mother ship and the animated 
; logo are handled by special cases.)
; Lots of Page 0 still available, so let's just be lazy and clog this up.
; Note LDA zp,X  (two bytes) if we were thinking about code size.


PMG_MOTHERSHIP_ID = 0 ; Screen object ID values index each table below.
PMG_EXPLOSION_ID  = 1
PMG_CANNON_1_ID   = 2
PMG_CANNON_2_ID   = 3
PMG_LASER_1_ID    = 4
PMG_LASER_2_ID    = 5

zPMG_SAVE_CURRENT_ID .byte 0 ; Save ID to get around having to txa/pha/pla/tax

zTABLE_PMG_OLD_X
zPMG_OLD_MOTHERSHIP_X .byte 0 
zPMG_OLD_EXPLOSION_X  .byte 0 
zPMG_OLD_CANNON_1_X   .byte 0
zPMG_OLD_CANNON_2_X   .byte 0
zPMG_OLD_LASER_1_X    .byte 0
zPMG_OLD_LASER_2_X    .byte 0

zTABLE_PMG_NEW_X
zPMG_NEW_MOTHERSHIP_X .byte 0 
zPMG_NEW_EXPLOSION_X  .byte 0 
zPMG_NEW_CANNON_1_X   .byte 0
zPMG_NEW_CANNON_2_X   .byte 0
zPMG_NEW_LASER_1_X    .byte 0
zPMG_NEW_LASER_2_X    .byte 0

zTABLE_PMG_OLD_Y
zPMG_OLD_MOTHERSHIP_Y .byte 0 
zPMG_OLD_EXPLOSION_Y  .byte 0 
zPMG_OLD_CANNON_1_Y   .byte 0
zPMG_OLD_CANNON_2_Y   .byte 0
zPMG_OLD_LASER_1_Y    .byte 0
zPMG_OLD_LASER_2_Y    .byte 0

zTABLE_PMG_NEW_Y
zPMG_NEW_MOTHERSHIP_Y .byte 0 
zPMG_NEW_EXPLOSION_Y  .byte 0 
zPMG_NEW_CANNON_1_Y   .byte 0
zPMG_NEW_CANNON_2_Y   .byte 0
zPMG_NEW_LASER_1_Y    .byte 0
zPMG_NEW_LASER_2_Y    .byte 0

zTABLE_PMG_IMG_ID ; this does not change.
	.byte PMG_IMG_MOTHERSHIP_ID
	.byte PMG_IMG_EXPLOSION_ID
	.byte PMG_IMG_CANNON_ID
	.byte PMG_IMG_CANNON_ID
	.byte PMG_IMG_LASER_ID
	.byte PMG_IMG_LASER_ID

zTABLE_PMG_HARDWARE ; Page, high byte, for each displayed item.
	.byte >PLAYERADR2 ; Mothership
	.byte >PLAYERADR3 ; Explosion
	.byte >PLAYERADR0 ; Player 1 Cannon
	.byte >PLAYERADR1 ; Player 2 Cannon
	.byte >PLAYERADR0 ; Player 1 Laser
	.byte >PLAYERADR1 ; Player 2 Laser



; ==========================================================================
; Include all the code parts . . .

	icl "ata_1nv_gfx.asm"       ; Data for Display Lists and Screen Memory (2K)

	icl "ata_1nv_cset.asm"      ; Data for custom character set (1K space)

	icl "ata_1nv_pmg.asm"       ; Data for Player/Missile graphics (and reserve the 2K bitmap).


	icl "ata_1nv_gfx_code.asm"  ; Routines for manipulating screen graphics.

	icl "ata_1nv_pmg_code.asm"  ; Routines for Player/Missile graphics animation.


	icl "ata_1nv_int.asm"       ; Code for I/O, Isplay List Interrupts, and Vertical Blank Interrupt.

	icl "ata_1nv_game.asm"      ; Code for game logic.

	icl "ata_1nv_audio.asm"     ; The world's lamest sound sequencer.

; --------------------------------------------------------------------------



; ==========================================================================

; Points for Mothership by row.

; 00 = 1000 ; 01 = 0500 
; 02 = 0475 ; 03 = 0450 ; 04 = 0425 ; 05 = 0400
; 06 = 0375 ; 07 = 0350 ; 08 = 0325 ; 09 = 0300
; 10 = 0275 ; 11 = 0250 ; 12 = 0225 ; 13 = 0200
; 14 = 0175 ; 15 = 0150 ; 16 = 0125 ; 17 = 0100
; 18 = 0075 ; 19 = 0050 ; 20 = 0025 ; 21 = 0001
	
TABLE_MOTHERSHIP_POINTS_HIGH
	.byte $10,$05,$04,$04,$04,$04,$03,$03,$03,$03,$02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00

TABLE_MOTHERSHIP_POINTS_LOW
	.byte $00,$00,$75,$50,$25,$00,$75,$50,$25,$00,$75,$50,$25,$00,$75,$50,$25,$00,$75,$50,$25,$01



GetMothershipPoints
getpoints
;	; calculate zMOTHERSHIP_POINTS (mspts)
	;
	; NOTE that MOTHERSHIP_ROW is being treated as a regular 
	; integer for indexing purposes.  The original code handled 
	; this as BCD, creating gaps between values $09/9 and
	; $10/16.
	
	lda #0       ; 0000 pts
	sta zMOTHERSHIP_POINTS
	sta zMOTHERSHIP_POINTS+1

	ldx ZMOTHERSHIP_ROW
	lda TABLE_MOTHERSHIP_POINTS_LOW,X
	sta zMOTHERSHIP_POINTS
	lda TABLE_MOTHERSHIP_POINTS_HIGH,X
	sta zMOTHERSHIP_POINTS+1

	rts


; Are there really 8 stars? In the video it appears there are 4
; in screen at any time.  It seems like the code wraps around 
; at 6, so ...? 
TABLE_STAR_LOCATION ; star
	.byte 0,32,64,96       ; eight
	.byte 128,160,192,224  ; stars
		 
; starcnt  .byte 0 ; zSTAR_COUNT

; Table to convert row to Y coordinate for mothership.
; This is also do-able with a LSR to multiply times 8 then add offset.

TABLE_ROW_TO_Y ; r2ytab 
;	.byte 58,66,74,82,90,98,106,114,122,130       ; Rows 0 to 9
;	.byte 0,0,0,0,0,0                             ; Ummm?
;	.byte 138,146,154,162,170,178,186,194,202,210 ; Rows 10 to 19
;	.byte 0,0,0,0,0,0                             ; Again?
;	.byte 218,226,234                             ; Rows 20 to 22

.byte 36,44,52,60     ; 0  - 3
.byte 68,76,84,92     ; 4  - 7
.byte 100,108,116,124 ; 8  - 11
.byte 132,140,148,156 ; 12 - 15
.byte 164,172,180,188 ; 16 - 19
.byte 196,204,212     ; 20 - 22


; ==========================================================================
; The Game Entry Point where AtariDOS calls for startup.
; 
; And the perpetual loop calling the game's event dispatch routine.
; The code needs this routine as a starting place, so that the 
; routines called from the subroutine table have a place to return
; to.  Otherwise the RTS from those routines would be at the 
; top level and exit the game.
; --------------------------------------------------------------------------

GameStart

	jsr GameLoop 

	jmp GameStart ; Do While More Electricity


; ==========================================================================
; Inform DOS of the program's Auto-Run address...
; GameStart is in the "Game.asm' file.
; --------------------------------------------------------------------------

	mDiskDPoke DOS_RUN_ADDR,GameStart
 
	END

