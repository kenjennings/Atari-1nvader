;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; PAGE 0 VARIABLE DECLARATIONS
;
; Declare and define some Page Zero variables.
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

TITLE_LOGO_Y_POS       = 62                       ; Just a constant.  No need for variable.

zTitleLogoBaseColor   .byte COLOR_ORANGE1         ; Starting value for first DLI. 
zTitleLogoColor       .byte COLOR_ORANGE1         ; Value for DLI. Loop from $10 to $E0 by 16
zTitleLogoCount       .byte 0                     ; How many times has the logo dli run?

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

BIG_MOTHERSHIP_START = 120
zBIG_MOTHERSHIP_Y   .byte BIG_MOTHERSHIP_START ; Starting position of the big mothership

BIG_MOTHERSHIP_SPEED = 1 ; Number of frames to count per move.
zBigMothershipSpeed .byte BIG_MOTHERSHIP_SPEED ; How many frames to wait per mothership move.

zBigMothershipPhase .byte 0 ;  0 = steady  !0 = Moving up.


; Scrolling Documentation Values ==================================================

DOCS_STEP_TIMER  = 2
zDocsScrollTimer .byte DOCS_STEP_TIMER ; How many frames to wait for each fine scroll.

zDocsHS          .byte 15   ; fine horizontal scroll value start.


; Scrolling Options text. ======================================================

zOptionHScroll   .byte 15 ; fine scroll for options. (both lines.)


zSTATS_TEXT_COLOR  .byte $08 ; color/luminance of text on stats line.



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

zGAME_OVER_TEXT  .word $0000  ; Pointer to the game over string to print.
;zGO_CSET_C_ADDR  .word $0000  ; Pointer to the source image for the char.
;zGO_MASK_ADDR    .word $0000  ; Pointer to the mask image 
zGO_FRAME        .byte $ff    ; Frame counter, 6 to 0.
zGO_CHAR_INDEX   .byte $00    ; index into game over text, 0 to 9
;zGO_COLPF0       .byte $00    ; Color value for PF0
;zGO_COLPF1       .byte $00    ; Color value for PF1
zGO_COLPF2_INDEX .byte $00    ; Index into Colpf2 values.



; Misc Control Values  =====================================================

zThisDLI .byte 0


; Game Control Values =======================================================

zCOUNTDOWN_FLAG    .byte $00 ; Counts phase, 4, 3, 2, 1, 0.  When it returns to 0, then trigger next phase (game)
zCOUNTDOWN_SECS    .byte $00 ; Countdown jiffies per tick tock event. (the 3, 2, 1, GO)

;zSTATS_TEXT_COLOR  .byte $08 ; color/luminance of text on stats line.



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

;zAnimatePlayers    .byte 2   ; animation counter.   Players can move every other frame.

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
zPLAYER_ONE_COLOR  .byte $00 ; Player 1 current color loaded from table.
zPLAYER_TWO_COLOR  .byte $00 ; Player 2 current color loaded from table.

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


