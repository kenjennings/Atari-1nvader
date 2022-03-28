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



; ==========================================================================
; TIMING PER VIDEO STANDARD . . .
; Motion/positioning controls:
; At startup, the program determines the video standard and then sets 
; zNTSCorPAL and the zMaxNTSCorPALFrames limit accordingly.
; The VBI increments the Frame Counter (zTHIS_FRAME) up to the limits of
; zMaxNTSCorPALFrames and resets to 0 as needed.
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
; INDEX == ( THIS_FRAME * 2 ) + zNTSCorPALflag
; INC_PLAYER = TABLE_PLAYER_X[ INDEX ]
; INC_LASER = TABLE_LASER_Y[ INDEX ]
;
; Extended lookup for Mothership:
; INDEX == ( MOTHERSHIP_MOVE_SPEED * 12) + ( THIS_FRAME * 2 ) + zNTSCorPALflag
; MOTHERSHIP_MOVEMENT = TABLE_SPEED_CONTROL[ INDEX ]

PAL_FRAMES=$5
NTSC_FRAMES=$6

zNTSCorPAL                  .byte $01         ; Clear (0) = PAL/SECAM, Set (1) = NTSC
zMaxNTSCorPALFrames         .byte NTSC_FRAMES ; Max number of frames per video standard (see tables)

zTHIS_FRAME                 .byte $00         ; Frame counter 0 to 4 (PAL) or 0 to 5 (NTSC) 
zINC_PLAYER_X               .byte $00         ; X Value to add this frame
zINC_LASER_Y                .byte $00         ; Y value to add this frame
zINC_MOTHERSHIP_X           .byte $00         ; X Value to add this frame (Speed control)
zMOTHERSHIP_MOVEMENT        .byte $00 ; Value to add/subtract from Mothership X

zMOTHERSHIP_MOVE_SPEED      .byte $00 ; Game mothership speed index into speed table 0, 2, 4, ..., 14 
zMOTHERSHIP_SPEEDUP_COUNTER .byte $00 ; Game mothership speed up counter 

; Run-time config for frame limits for PAL or NTSC video modes. Index by zNTSCorPAL.
TABLE_NTSC_OR_PAL_FRAMES     
	.byte PAL_FRAMES,NTSC_FRAMES

; How many pixels to move the Player each frame.  PAL, NTSC per each.
; Technically, we can simply use as flag whether or not to process
; horizontal movement for the player.   If this is 1, then movement
; can occur.
; Lookup X == ( THIS_FRAME * 2 ) + zNTSCorPALflag
TABLE_PLAYER_CONTROL 
	.byte 0,0 ; Frame 1, PAL, NTSC
	.byte 1,1 ; Frame 2, PAL, NTSC
	.byte 0,0 ; Frame 3, PAL, NTSC
	.byte 1,1 ; Frame 4, PAL, NTSC
	.byte 1,0 ; Frame 5, PAL, NTSC
	.byte 0,1 ; Frame 6, (-), NTSC

; How many pixels to move the Laser each frame.  PAL, NTSC per each.
; Lookup X == ( THIS_FRAME * 2 ) + zNTSCorPALflag
TABLE_LASER_CONTROL
	.byte 5,4 ; Frame 1, PAL, NTSC
	.byte 5,4 ; Frame 2, PAL, NTSC
	.byte 4,4 ; Frame 3, PAL, NTSC
	.byte 5,4 ; Frame 4, PAL, NTSC
	.byte 4,4 ; Frame 5, PAL, NTSC
	.byte 0,4 ; Frame 6, (-), NTSC

; How many pixels to horizontally move the mothership.  Pal, NTSC per each.
; Since there are multiple speed values for the mothership, there 
; is a control table for each of the speed values.
; Since there are 12 entries (6 PAL, 6 NTSC) per each mothership speed 
; setting the starting point of each is 12 times the mothership speed.
; To make the times 12 easier, provide a direct lookup.
; Lookup X == ( MOTHERSHIP_MOVE_SPEED * 12) + ( THIS_FRAME * 2 ) + zNTSCorPALflag

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

MOTHERHIP_START_ANIM=3
zMOTHERSHIP_ANIM            .byte $00 ; Animation frame for windows on small mothership
zMOTHERSHIP_BIG_ANIM        .byte $00 ; Animation Frame for windows on big mothership. 0 to 13
zMOTHERSHIP_ANIM_CLOCK      .byte MOTHERHIP_START_ANIM   ; delay for animation 

MOTHERSHIP_START_CLOCK1=60            ; The light on top of the ship
zMOTHERSHIP_LIGHT_CLOCK1    .byte MOTHERSHIP_START_CLOCK1
zMOTHERSHIP_LIGHT1          .byte $1  ; toggle $0, $1 for off and on

MOTHERSHIP_START_CLOCK2=61            ; The light on the left leg 
zMOTHERSHIP_LIGHT_CLOCK2    .byte MOTHERSHIP_START_CLOCK2
zMOTHERSHIP_LIGHT2          .byte $1  ; toggle $0, $1 for off and on

MOTHERSHIP_START_CLOCK3=62            ; The light on the right leg 
zMOTHERSHIP_LIGHT_CLOCK3    .byte MOTHERSHIP_START_CLOCK3
zMOTHERSHIP_LIGHT3          .byte $1  ; toggle $0, $1 for off and on

zMOTHERSHIP_ROW             .byte $00 ; Game mothership text line row number
zMOTHERSHIP_HITS            .byte $00 ; Number of times the mothership is hit.

;zMOTHERSHIP_SHOT_BY_ONE     .byte $0  ; Collision between PM0 (shot) and PM2
;zMOTHERSHIP_SHOT_BY_TWO     .byte $0  ; Collision between PM1 (shot) and PM2

zEXPLOSION_ON               .byte $00 ; Explosion is present.   
zEXPLOSION_COUNT            .byte $00 ; Timer/index for Explosion. 
zEXPLOSION_X                .byte $00 
zEXPLOSION_Y                .byte $00
zEXPLOSION_NEW_Y            .byte $00


; ==========================================================================
; COUNTDOWN 3, 2, 2, GO! COLOR . . .

zCountdownTimer       .byte $01

zCountdownColor       .byte $04



; ==========================================================================
; SCORING . . .

;zSHOW_SCORE_FLAG             .byte $00 ; Flag to update score on screen.

zMOTHERSHIP_POINTS_AS_DIGITS .byte $00,$00,$00,$00,$00,$00 ; Points for current row.

zPLAYERPOINTS_TO_ADD         .byte $00,$00,$00,$00,$00,$00 ; Mothership points to add to player

zPLAYER_SCORE      
zPLAYER_ONE_SCORE            .byte $00,$00,$00,$00,$00,$00 ; Player 1 score, 6 digit BCD 
zPLAYER_TWO_SCORE            .byte $00,$00,$00,$00,$00,$00 ; Player 2 score, 6 digits 

zHIGH_SCORE                  .byte $00,$00,$00,$00,$00,$00 ; 6 digits

gSCORES_ON                   .byte $01 ; Flag that scores are visible.

; ==========================================================================
; STATISTICS . . .

zSHIP_HITS_AS_DIGITS        .byte $00,$00,$00,$00 ; Remaining hits on mothership as digits.
zMOTHERSHIP_ROW_AS_DIGITS   .byte $00,$00 ; Mothership text line row number as 2 digits for display


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
; TITLE SCREEN OPTIONS MANAGEMENT . . .

gOSS_ScrollState  .byte 0 ; Status of scrolling: 1=scrolling. 0=not scrolling. -1=scroll just stopped. 

gOSS_Mode         .byte 0 ; 0=Off  -1=option menu  +1=is select menu.

gOSS_Timer        .byte 0 ; Counts to wait for text.  When this reaches 0 without input, then erase menu.

gCurrentOption    .byte 0 ; Remember the last OPTION visited.

gCurrentSelect    .byte 0 ; Remember the last SELECT visited.

gCurrentMenuEntry .byte 0 ; Menu entry number for Option and Select.

gCurrentMenuText  .word 0 ; pointer to text for the menu 


; ==========================================================================
; MENUS, SELECTIONS, OPTIONS
; ==========================================================================
; Press OPTION key to cycle through top level menu. 
; Press SELECT key to cycle through SELECT menu lists.
; Press START key to engage the choice on the SELECT Menu.
;
; OPTION entries point to first entry on SELECT menu.
; SELECT entries point to *function() to set/unset item.
;
; --------------------------------------------------------------------------

; Where to go from OPTION when SELECT is pressed...

TABLE_OPTIONS_SELECTMENUS
	.byte 8  ; 8  SELECT Laser Restart Menu
	.byte 15 ; 15 SELECT Laser Speed Menu
	.byte 19 ; 19 SELECT 1NVADER Startup Menu
	.byte 25 ; 25 SELECT 1NVADER Speedup Menu
	.byte 32 ; 32 SELECT 1NVADER Max Speed Menu
	.byte 37 ; 37 SELECT Two Player Modes Menu
	.byte 42 ; 42 SELECT Other things Menu
	.byte 0  ; Go back to first menu.


; Table of pointers to strings for the Mode 6 text.
; This table implements special behavior:  If the HIGH byte
; of a pointer is 0, then the low byte is the new index
; value to use.   This allows a forward iteration through 
; the list to be reset to the previous entry for that 
; group of Select menu entries.

TABLE_OPTIONS_LO
	.byte <GFX_OPTION_1 ; 0
	.byte <GFX_OPTION_2 ; 1 
	.byte <GFX_OPTION_3 ; 2
	.byte <GFX_OPTION_4 ; 3 
	.byte <GFX_OPTION_5 ; 4
	.byte <GFX_OPTION_6 ; 5
	.byte <GFX_OPTION_7 ; 6 
	.byte 0            ; 7   Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte <GFX_MENU_1_1 ; 8   Regular Laser Auto Restart (Default)
	.byte <GFX_MENU_1_2 ; 9   Short Laser Auto Restart
	.byte <GFX_MENU_1_3 ; 10  Long Laser Auto Restart
	.byte <GFX_MENU_1_4 ; 11  Regular Laser Manual Restart
	.byte <GFX_MENU_1_5 ; 12  Regular Laser Manual Restart
	.byte <GFX_MENU_1_6 ; 13  Regular Laser Manual Restart
	.byte 8            ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte <GFX_MENU_2_1 ; 15  Regular laser speed  (Default)
	.byte <GFX_MENU_2_2 ; 16  Fast laser speed (+2)
	.byte <GFX_MENU_2_3 ; 17  Slow laser speed (-2)
	.byte 15           ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte <GFX_MENU_3_1 ; 19 1nvader Start Speed 1 (Default)
	.byte <GFX_MENU_3_2 ; 20 1nvader Start Speed 3
	.byte <GFX_MENU_3_3 ; 21 1nvader Start Speed 5
	.byte <GFX_MENU_3_4 ; 22 1nvader Start Speed 7
	.byte <GFX_MENU_3_5 ; 23 1nvader Start Speed MAX
	.byte 19           ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte <GFX_MENU_4_1 ; 25 1nvader speed up every 10 hits (Default)
	.byte <GFX_MENU_4_2 ; 26 1nvader speed up every 7 hits
	.byte <GFX_MENU_4_3 ; 27 1nvader speed up every 5 hits
	.byte <GFX_MENU_4_4 ; 28 1nvader speed up every 3 hits 
	.byte <GFX_MENU_4_5 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte <GFX_MENU_4_6 ; 30 1nvader speed up no speedup
	.byte 25           ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte <GFX_MENU_5_1 ; 32 Max speed 1
	.byte <GFX_MENU_5_2 ; 33 Max speed 3
	.byte <GFX_MENU_5_3 ; 34 Max speed 5
	.byte <GFX_MENU_5_4 ; 35 Max speed MAX (Default)
	.byte 32           ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte <GFX_MENU_6_1 ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte <GFX_MENU_6_2 ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte <GFX_MENU_6_3 ; 39 FRENEM1ES - Guns attached to each other.           
	.byte <GFX_MENU_6_4 ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 37           ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte <GFX_MENU_7_1 ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte <GFX_MENU_7_2 ; 43 Reset all values to defaults
	.byte <GFX_MENU_7_3 ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 42           ; 45 Return to Select entry 42

TABLE_OPTIONS_HI
	.byte >GFX_OPTION_1 ; 0
	.byte >GFX_OPTION_2 ; 1 
	.byte >GFX_OPTION_3 ; 2
	.byte >GFX_OPTION_4 ; 3 
	.byte >GFX_OPTION_5 ; 4
	.byte >GFX_OPTION_6 ; 5
	.byte >GFX_OPTION_7 ; 6 
	.byte 0            ; 7   Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte >GFX_MENU_1_1 ; 8   Regular Laser Auto Restart (Default)
	.byte >GFX_MENU_1_2 ; 9   Short Laser Auto Restart
	.byte >GFX_MENU_1_3 ; 10  Long Laser Auto Restart
	.byte >GFX_MENU_1_4 ; 11  Regular Laser Manual Restart
	.byte >GFX_MENU_1_5 ; 12  Regular Laser Manual Restart
	.byte >GFX_MENU_1_6 ; 13  Regular Laser Manual Restart
	.byte 0            ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte >GFX_MENU_2_1 ; 15  Regular laser speed  (Default)
	.byte >GFX_MENU_2_2 ; 16  Fast laser speed (+2)
	.byte >GFX_MENU_2_3 ; 17  Slow laser speed (-2)
	.byte 0            ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte >GFX_MENU_3_1 ; 19 1nvader Start Speed 1 (Default)
	.byte >GFX_MENU_3_2 ; 20 1nvader Start Speed 3
	.byte >GFX_MENU_3_3 ; 21 1nvader Start Speed 5
	.byte >GFX_MENU_3_4 ; 22 1nvader Start Speed 7
	.byte >GFX_MENU_3_5 ; 23 1nvader Start Speed MAX
	.byte 0            ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte >GFX_MENU_4_1 ; 25 1nvader speed up every 10 hits (Default)
	.byte >GFX_MENU_4_2 ; 26 1nvader speed up every 7 hits
	.byte >GFX_MENU_4_3 ; 27 1nvader speed up every 5 hits
	.byte >GFX_MENU_4_4 ; 28 1nvader speed up every 3 hits 
	.byte >GFX_MENU_4_5 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte >GFX_MENU_4_6 ; 30 1nvader speed up no speedup
	.byte 0            ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte >GFX_MENU_5_1 ; 32 Max speed 1
	.byte >GFX_MENU_5_2 ; 33 Max speed 3
	.byte >GFX_MENU_5_3 ; 34 Max speed 5
	.byte >GFX_MENU_5_4 ; 35 Max speed MAX (Default)
	.byte 0           ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte >GFX_MENU_6_1 ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte >GFX_MENU_6_2 ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte >GFX_MENU_6_3 ; 39 FRENEM1ES - Guns attached to each other.           
	.byte >GFX_MENU_6_4 ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0           ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte >GFX_MENU_7_1 ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte >GFX_MENU_7_2 ; 43 Reset all values to defaults
	.byte >GFX_MENU_7_3 ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0           ; 45 Return to Select entry 42


; Text for the mode 2 line to explain the option/entry.

TABLE_OPTIONS_TEXT_LO
	.byte <GFX_OPTION_1_TEXT ; 0
	.byte <GFX_OPTION_2_TEXT ; 1 
	.byte <GFX_OPTION_3_TEXT ; 2
	.byte <GFX_OPTION_4_TEXT ; 3 
	.byte <GFX_OPTION_5_TEXT ; 4
	.byte <GFX_OPTION_6_TEXT ; 5
	.byte <GFX_OPTION_7_TEXT ; 6 
	.byte 0                 ; 7   Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte <GFX_MENU_1_1_TEXT ; 8   Regular Laser Auto Restart (Default)
	.byte <GFX_MENU_1_2_TEXT ; 9   Short Laser Auto Restart
	.byte <GFX_MENU_1_3_TEXT ; 10  Long Laser Auto Restart
	.byte <GFX_MENU_1_4_TEXT ; 11  Regular Laser Manual Restart
	.byte <GFX_MENU_1_5_TEXT ; 12  Short Laser Manual Restart
	.byte <GFX_MENU_1_6_TEXT ; 13  Long Laser Manual Restart
	.byte 0                 ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte <GFX_MENU_2_1_TEXT ; 15  Regular laser speed   (Default)
	.byte <GFX_MENU_2_2_TEXT ; 16  Fast laser speed (+2)
	.byte <GFX_MENU_2_3_TEXT ; 17  Slow laser speed (-2)
	.byte 0                ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte <GFX_MENU_3_1_TEXT ; 19 1nvader Start Speed 1  (Default)
	.byte <GFX_MENU_3_2_TEXT ; 20 1nvader Start Speed 3
	.byte <GFX_MENU_3_3_TEXT ; 21 1nvader Start Speed 5
	.byte <GFX_MENU_3_4_TEXT ; 22 1nvader Start Speed 7
	.byte <GFX_MENU_3_5_TEXT ; 23 1nvader Start Speed MAX
	.byte 0                ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte <GFX_MENU_4_1_TEXT ; 25 1nvader speed up every 10 hits (Default)
	.byte <GFX_MENU_4_2_TEXT ; 26 1nvader speed up every 7 hits
	.byte <GFX_MENU_4_3_TEXT ; 27 1nvader speed up every 5 hits
	.byte <GFX_MENU_4_4_TEXT ; 28 1nvader speed up every 3 hits 
	.byte <GFX_MENU_4_5_TEXT ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte <GFX_MENU_4_6_TEXT ; 30 1nvader speed up no speedup
	.byte 0                ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte <GFX_MENU_5_1_TEXT ; 32 Max speed 1
	.byte <GFX_MENU_5_2_TEXT ; 33 Max speed 3
	.byte <GFX_MENU_5_3_TEXT ; 34 Max speed 5
	.byte <GFX_MENU_5_4_TEXT ; 35 Max speed MAX (Default)
	.byte 0                ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte <GFX_MENU_6_1_TEXT ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte <GFX_MENU_6_2_TEXT ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte <GFX_MENU_6_3_TEXT ; 39 FRENEM1ES - Guns attached to each other.           
	.byte <GFX_MENU_6_4_TEXT ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte <GFX_MENU_7_1_TEXT ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte <GFX_MENU_7_2_TEXT ; 43 Reset all values to defaults
	.byte <GFX_MENU_7_3_TEXT ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                ; 45 Return to Select entry 42

TABLE_OPTIONS_TEXT_HI
	.byte >GFX_OPTION_1_TEXT ; 0
	.byte >GFX_OPTION_2_TEXT ; 1 
	.byte >GFX_OPTION_3_TEXT ; 2
	.byte >GFX_OPTION_4_TEXT ; 3 
	.byte >GFX_OPTION_5_TEXT ; 4
	.byte >GFX_OPTION_6_TEXT ; 5
	.byte >GFX_OPTION_7_TEXT ; 6 
	.byte 0                 ; 7   Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte >GFX_MENU_1_1_TEXT ; 8   Regular Laser Auto Restart (Default)
	.byte >GFX_MENU_1_2_TEXT ; 9   Short Laser Auto Restart
	.byte >GFX_MENU_1_3_TEXT ; 10  Long Laser Auto Restart
	.byte >GFX_MENU_1_4_TEXT ; 11  Regular Laser Manual Restart
	.byte >GFX_MENU_1_5_TEXT ; 12  Short Laser Manual Restart
	.byte >GFX_MENU_1_6_TEXT ; 13  Long Laser Manual Restart
	.byte 0                 ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte >GFX_MENU_2_1_TEXT ; 15  Regular laser speed   (Default)
	.byte >GFX_MENU_2_2_TEXT ; 16  Fast laser speed (+2)
	.byte >GFX_MENU_2_3_TEXT ; 17  Slow laser speed (-2)
	.byte 0                ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte >GFX_MENU_3_1_TEXT ; 19 1nvader Start Speed 1  (Default)
	.byte >GFX_MENU_3_2_TEXT ; 20 1nvader Start Speed 3
	.byte >GFX_MENU_3_3_TEXT ; 21 1nvader Start Speed 5
	.byte >GFX_MENU_3_4_TEXT ; 22 1nvader Start Speed 7
	.byte >GFX_MENU_3_5_TEXT ; 23 1nvader Start Speed MAX
	.byte 0                ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte >GFX_MENU_4_1_TEXT ; 25 1nvader speed up every 10 hits (Default)
	.byte >GFX_MENU_4_2_TEXT ; 26 1nvader speed up every 7 hits
	.byte >GFX_MENU_4_3_TEXT ; 27 1nvader speed up every 5 hits
	.byte >GFX_MENU_4_4_TEXT ; 28 1nvader speed up every 3 hits 
	.byte >GFX_MENU_4_5_TEXT ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte >GFX_MENU_4_6_TEXT ; 30 1nvader speed up no speedup
	.byte 0                ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte >GFX_MENU_5_1_TEXT ; 32 Max speed 1
	.byte >GFX_MENU_5_2_TEXT ; 33 Max speed 3
	.byte >GFX_MENU_5_3_TEXT ; 34 Max speed 5
	.byte >GFX_MENU_5_4_TEXT ; 35 Max speed MAX (Default)
	.byte 0                ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte >GFX_MENU_6_1_TEXT ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte >GFX_MENU_6_2_TEXT ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte >GFX_MENU_6_3_TEXT ; 39 FRENEM1ES - Guns attached to each other.           
	.byte >GFX_MENU_6_4_TEXT ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte >GFX_MENU_7_1_TEXT ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte >GFX_MENU_7_2_TEXT ; 43 Reset all values to defaults
	.byte >GFX_MENU_7_3_TEXT ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                ; 45 Return to Select entry 42



; Functions to set game options to update display OPTION large description (ON/OFF).

TABLE_GET_FUNCTIONS_LO
	.byte 0 ; 0
	.byte 0 ; 1 
	.byte 0 ; 2
	.byte 0 ; 3 
	.byte 0 ; 4
	.byte 0 ; 5
	.byte 0 ; 6 
	.byte 0                     ; 7  Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte <[getLaserRestart-1] ; 8   Regular Laser Auto Restart (Default)
	.byte <[getLaserRestart-1] ; 9   Short Laser Auto Restart
	.byte <[getLaserRestart-1] ; 10  Long Laser Auto Restart
	.byte <[getLaserRestart-1] ; 11  Regular Laser Manual Restart
	.byte <[getLaserRestart-1] ; 12  Short Laser Manual Restart
	.byte <[getLaserRestart-1] ; 13  Long Laser Manual Restart
	.byte 0                     ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte 0 ; getLaserSpeed-1   ; 15  Regular laser speed
	.byte 0 ; getLaserSpeed-1   ; 16  Fast laser speed (+2)
	.byte 0 ; getLaserSpeed-1   ; 17  Slow laser speed (-2)
	.byte 0                    ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte 0 ; getMSStartSpeed-1 ; 19 1nvader Start Speed 1 (Default)
	.byte 0 ; getMSStartSpeed-1 ; 20 1nvader Start Speed 3
	.byte 0 ; getMSStartSpeed-1 ; 21 1nvader Start Speed 5
	.byte 0 ; getMSStartSpeed-1 ; 22 1nvader Start Speed 7
	.byte 0 ; getMSStartSpeed-1 ; 23 1nvader Start Speed MAX
	.byte 0                    ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte 0 ; getMSHitCounter-1 ; 25 1nvader speed up every 10 hits (Default)
	.byte 0 ; getMSHitCounter-1 ; 26 1nvader speed up every 7 hits
	.byte 0 ; getMSHitCounter-1 ; 27 1nvader speed up every 5 hits
	.byte 0 ; getMSHitCounter-1 ; 28 1nvader speed up every 3 hits 
	.byte 0 ; getMSHitCounter-1 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte 0 ; getMSHitCounter-1 ; 30 1nvader speed up no speedup
	.byte 0                    ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte 0 ; getMSMaxSpeed-1   ; 32 Max speed 1
	.byte 0 ; getMSMaxSpeed-1   ; 33 Max speed 3
	.byte 0 ; getMSMaxSpeed-1   ; 34 Max speed 5
	.byte 0 ; getMSMaxSpeed-1   ; 35 Max speed MAX (Default)
	.byte 0                    ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte 0 ; get2PMode         ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte 0 ; get2PMode         ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte 0 ; get2PMode         ; 39 FRENEM1ES - Guns attached to each other.           
	.byte 0 ; get2PMode         ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                    ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte 0 ; getOnesieMode     ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte 0 ;                   ; 43 Reset all values to defaults
	.byte 0 ; getCheatMode      ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                    ; 45 Return to Select entry 42

TABLE_GET_FUNCTIONS_HI
	.byte 0 ; 0
	.byte 0 ; 1 
	.byte 0 ; 2
	.byte 0 ; 3 
	.byte 0 ; 4
	.byte 0 ; 5
	.byte 0 ; 6 
	.byte 0                     ; 7  Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte >[getLaserRestart-1] ; 8   Regular Laser Auto Restart (Default)
	.byte >[getLaserRestart-1] ; 9   Short Laser Auto Restart
	.byte >[getLaserRestart-1] ; 10  Long Laser Auto Restart
	.byte >[getLaserRestart-1] ; 11  Regular Laser Manual Restart
	.byte >[getLaserRestart-1] ; 12  Short Laser Manual Restart
	.byte >[getLaserRestart-1] ; 13  Long Laser Manual Restart
	.byte 0                     ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte 0 ; getLaserSpeed-1   ; 15  Regular laser speed
	.byte 0 ; getLaserSpeed-1   ; 16  Fast laser speed (+2)
	.byte 0 ; getLaserSpeed-1   ; 17  Slow laser speed (-2)
	.byte 0                    ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte 0 ; getMSStartSpeed-1 ; 19 1nvader Start Speed 1 (Default)
	.byte 0 ; getMSStartSpeed-1 ; 20 1nvader Start Speed 3
	.byte 0 ; getMSStartSpeed-1 ; 21 1nvader Start Speed 5
	.byte 0 ; getMSStartSpeed-1 ; 22 1nvader Start Speed 7
	.byte 0 ; getMSStartSpeed-1 ; 23 1nvader Start Speed MAX
	.byte 0                    ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte 0 ; getMSHitCounter-1 ; 25 1nvader speed up every 10 hits (Default)
	.byte 0 ; getMSHitCounter-1 ; 26 1nvader speed up every 7 hits
	.byte 0 ; getMSHitCounter-1 ; 27 1nvader speed up every 5 hits
	.byte 0 ; getMSHitCounter-1 ; 28 1nvader speed up every 3 hits 
	.byte 0 ; getMSHitCounter-1 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte 0 ; getMSHitCounter-1 ; 30 1nvader speed up no speedup
	.byte 0                    ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte 0 ; getMSMaxSpeed-1   ; 32 Max speed 1
	.byte 0 ; getMSMaxSpeed-1   ; 33 Max speed 3
	.byte 0 ; getMSMaxSpeed-1   ; 34 Max speed 5
	.byte 0 ; getMSMaxSpeed-1   ; 35 Max speed MAX (Default)
	.byte 0                    ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte 0 ; get2PMode         ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte 0 ; get2PMode         ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte 0 ; get2PMode         ; 39 FRENEM1ES - Guns attached to each other.           
	.byte 0 ; get2PMode         ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                    ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte 0 ; getOnesieMode     ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte 0 ;                   ; 43 Reset all values to defaults
	.byte 0 ; getCheatMode      ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                    ; 45 Return to Select entry 42


; Functions to set game options.

TABLE_SET_FUNCTIONS_LO
	.byte 0 ; 0
	.byte 0 ; 1 
	.byte 0 ; 2
	.byte 0 ; 3 
	.byte 0 ; 4
	.byte 0 ; 5
	.byte 0 ; 6 
	.byte 0                     ; 7  Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte <[setLaserRestart-1] ; 8   Regular Laser Auto Restart (Default)
	.byte <[setLaserRestart-1] ; 9   Short Laser Auto Restart
	.byte <[setLaserRestart-1] ; 10  Long Laser Auto Restart
	.byte <[setLaserRestart-1] ; 11  Regular Laser Manual Restart
	.byte <[setLaserRestart-1] ; 12  Short Laser Manual Restart
	.byte <[setLaserRestart-1] ; 13  Long Laser Manual Restart
	.byte 0                     ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte 0 ; setLaserSpeed-1   ; 15  Regular laser speed
	.byte 0 ; setLaserSpeed-1   ; 16  Fast laser speed (+2)
	.byte 0 ; setLaserSpeed-1   ; 17  Slow laser speed (-2)
	.byte 0                    ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte 0 ; setMSStartSpeed-1 ; 19 1nvader Start Speed 1 (Default)
	.byte 0 ; setMSStartSpeed-1 ; 20 1nvader Start Speed 3
	.byte 0 ; setMSStartSpeed-1 ; 21 1nvader Start Speed 5
	.byte 0 ; setMSStartSpeed-1 ; 22 1nvader Start Speed 7
	.byte 0 ; setMSStartSpeed-1 ; 23 1nvader Start Speed MAX
	.byte 0                    ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte 0 ; setMSHitCounter-1 ; 25 1nvader speed up every 10 hits (Default)
	.byte 0 ; setMSHitCounter-1 ; 26 1nvader speed up every 7 hits
	.byte 0 ; setMSHitCounter-1 ; 27 1nvader speed up every 5 hits
	.byte 0 ; setMSHitCounter-1 ; 28 1nvader speed up every 3 hits 
	.byte 0 ; setMSHitCounter-1 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte 0 ; setMSHitCounter-1 ; 30 1nvader speed up no speedup
	.byte 0                    ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte 0 ; setMSMaxSpeed-1   ; 32 Max speed 1
	.byte 0 ; setMSMaxSpeed-1   ; 33 Max speed 3
	.byte 0 ; setMSMaxSpeed-1   ; 34 Max speed 5
	.byte 0 ; setMSMaxSpeed-1   ; 35 Max speed MAX (Default)
	.byte 0                    ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte 0 ; set2PMode         ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte 0 ; set2PMode         ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte 0 ; set2PMode         ; 39 FRENEM1ES - Guns attached to each other.           
	.byte 0 ; set2PMode         ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                    ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte 0 ; setOnesieMode     ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte 0 ; setAllDefaults    ; 43 Reset all values to defaults
	.byte 0 ; setCheatMode      ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                    ; 45 Return to Select entry 42

TABLE_SET_FUNCTIONS_HI
	.byte 0 ; 0
	.byte 0 ; 1 
	.byte 0 ; 2
	.byte 0 ; 3 
	.byte 0 ; 4
	.byte 0 ; 5
	.byte 0 ; 6 
	.byte 0                     ; 7  Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte 0 >[setLaserRestart-1] ; 8   Regular Laser Auto Restart (Default)
	.byte 0 >[setLaserRestart-1] ; 9   Short Laser Auto Restart
	.byte 0 >[setLaserRestart-1] ; 10  Long Laser Auto Restart
	.byte 0 >[setLaserRestart-1] ; 11  Regular Laser Manual Restart
	.byte 0 >[setLaserRestart-1] ; 12  Short Laser Manual Restart
	.byte 0 >[setLaserRestart-1] ; 13  Long Laser Manual Restart
	.byte 0                     ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte 0 ; setLaserSpeed-1   ; 15  Regular laser speed
	.byte 0 ; setLaserSpeed-1   ; 16  Fast laser speed (+2)
	.byte 0 ; setLaserSpeed-1   ; 17  Slow laser speed (-2)
	.byte 0                    ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte 0 ; setMSStartSpeed-1 ; 19 1nvader Start Speed 1 (Default)
	.byte 0 ; setMSStartSpeed-1 ; 20 1nvader Start Speed 3
	.byte 0 ; setMSStartSpeed-1 ; 21 1nvader Start Speed 5
	.byte 0 ; setMSStartSpeed-1 ; 22 1nvader Start Speed 7
	.byte 0 ; setMSStartSpeed-1 ; 23 1nvader Start Speed MAX
	.byte 0                    ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte 0 ; setMSHitCounter-1 ; 25 1nvader speed up every 10 hits (Default)
	.byte 0 ; setMSHitCounter-1 ; 26 1nvader speed up every 7 hits
	.byte 0 ; setMSHitCounter-1 ; 27 1nvader speed up every 5 hits
	.byte 0 ; setMSHitCounter-1 ; 28 1nvader speed up every 3 hits 
	.byte 0 ; setMSHitCounter-1 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte 0 ; setMSHitCounter-1 ; 30 1nvader speed up no speedup
	.byte 0                    ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte 0 ; setMSMaxSpeed-1   ; 32 Max speed 1
	.byte 0 ; setMSMaxSpeed-1   ; 33 Max speed 3
	.byte 0 ; setMSMaxSpeed-1   ; 34 Max speed 5
	.byte 0 ; setMSMaxSpeed-1   ; 35 Max speed MAX (Default)
	.byte 0                    ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte 0 ; set2PMode         ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte 0 ; set2PMode         ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte 0 ; set2PMode         ; 39 FRENEM1ES - Guns attached to each other.           
	.byte 0 ; set2PMode         ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                    ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte 0 ; setOnesieMode     ; 42 ONES1ES - 2P take turns shooting. (Default - Off)
	.byte 0 ; setAllDefaults    ; 43 Reset all values to defaults
	.byte 0 ; setCheatMode      ; 44 Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                    ; 45 Return to Select entry 42



; Laser Restart: 0= regular height, 1=short height, 2= long height, then $00= manual, $80=Automatic

CONFIG_LASER_RESTART .byte $00


; Data/Flag passed to routine to set the value or match the current value.

TABLE_OPTION_ARGUMENTS
	.byte 0 ; 0
	.byte 0 ; 1 
	.byte 0 ; 2
	.byte 0 ; 3 
	.byte 0 ; 4
	.byte 0 ; 5
	.byte 0 ; 6 
	.byte 0                        ; 7  Return to Option entry 0
	; (SELECT Laser Restart Menu)
	.byte $00   ; setLaserRestart-1  ; 8   Regular Laser Auto Restart (Default)
	.byte $01   ; setLaserRestart-1  ; 9   Short Laser Auto Restart
	.byte $02   ; setLaserRestart-1  ; 10  Long Laser Auto Restart
	.byte $80 ; setLaserRestart-1  ; 11  Regular Laser Manual Restart
	.byte $81 ; setLaserRestart-1  ; 12  Short Laser Manual Restart
	.byte $82 ; setLaserRestart-1  ; 13  Long Laser Manual Restart
	.byte 0                        ; 14  Return to Select entry 8
	; (SELECT Laser Speed Menu)
	.byte $00 ; setLaserSpeed-1   ; 15  Regular laser speed
	.byte $01 ; setLaserSpeed-1   ; 16  Fast laser speed (+2)
	.byte $02 ; setLaserSpeed-1   ; 17  Slow laser speed (-2)
	.byte 0                    ; 18 Return to Select entry 15
	; (SELECT 1NVADER Startup Menu)
	.byte $01 ; setMSStartSpeed-1 ; 19 1nvader Start Speed 1 (Default)
	.byte $03 ; setMSStartSpeed-1 ; 20 1nvader Start Speed 3
	.byte $05 ; setMSStartSpeed-1 ; 21 1nvader Start Speed 5
	.byte $07 ; setMSStartSpeed-1 ; 22 1nvader Start Speed 7
	.byte $09 ; setMSStartSpeed-1 ; 23 1nvader Start Speed MAX
	.byte 0                    ; 24 Return to Select entry 19
	; (SELECT 1NVADER Speedup Menu)
	.byte 10  ; setMSHitCounter-1 ; 25 1nvader speed up every 10 hits (Default)
	.byte 7   ; setMSHitCounter-1 ; 26 1nvader speed up every 7 hits
	.byte 5   ; setMSHitCounter-1 ; 27 1nvader speed up every 5 hits
	.byte 3   ; setMSHitCounter-1 ; 28 1nvader speed up every 3 hits 
	.byte 128 ; setMSHitCounter-1 ; 29 1nvader speed up progressive 10,9,8,7,6...
	.byte 0   ; setMSHitCounter-1 ; 30 1nvader speed up no speedup
	.byte 0                    ; 31 Return to Select entry 25
	; (SELECT 1NVADER Max Speed Menu)
	.byte $01 ; setMSMaxSpeed-1   ; 32 Max speed 1
	.byte $03 ; setMSMaxSpeed-1   ; 33 Max speed 3
	.byte $05 ; setMSMaxSpeed-1   ; 34 Max speed 5
	.byte $09 ; setMSMaxSpeed-1   ; 35 Max speed MAX (Default)
	.byte 0                    ; 36 Return to Select entry 32
	; (SELECT Two Player Modes Menu)
	.byte $00 ; set2PMode         ; 37 FR1GULAR - Guns bounce off each other. (Default)
	.byte $01 ; set2PMode         ; 38 FR1GNORE - Guns do not bounce off each other.
	.byte $02 ; set2PMode         ; 39 FRENEM1ES - Guns attached to each other.           
	.byte $03 ; set2PMode         ; 40 FRE1GHBORS - Center barrier.  Guns have half screen.
	.byte 0                    ; 41 Return to Select entry 37
	; (SELECT Other things Menu)
	.byte 0 ; setOnesieMode     ; 42 TOGGLE - ONES1ES - 2P take turns shooting. (Default - Off)
	.byte 0 ; setAllDefaults    ; 43 Reset all values to defaults
	.byte 0 ; setCheatMode      ; 44 TOGGLE - Cheat Mode - 1nvader never reaches bottom row.
	.byte 0                    ; 45 Return to Select entry 42


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

zGAME_OVER_FLAG             .byte $00  ; The game is over?

; Automatic return to title screen
zGAME_OVER_FRAME            .byte 0    ; Frame counter 255 to 0
zGAME_OVER_TICKS            .byte 0    ; decrement every GAME_OVER_FRAME=0.  Large countdown.

; Game Screen Stars Control values ==========================================

gTEMP_NEW_STAR_ID  .byte 0 ; gives the star 3, 2, 1, 0

gTEMP_NEW_STAR_ROW .byte 0 ; Row number for star 0 to 17.


; Star and Cheat Mode "Star" ================================================

CHEAT_CLOCK = 60

gSTARS_CHEAT_CLOCK .byte CHEAT_CLOCK ; countodown to change graphic

gSTARS_OR_CHEAT    .byte 0           ; 0 = normal.   1-5 current cheat char.

gSTARS_OR_CHEAT_TABLE                ; gSTARS_OR_CHEAT * 8 is index.

; Char $0A:   *                      ; Revise Star again for Atari for Mode 6 color
	.byte $08,$00,$08,$2A,$08,$00,$08,$00
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
