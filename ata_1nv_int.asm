;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2023 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; TIMER STUFF AND INPUT
;
; Miscellaneous:
; Timer ranges
; Tick Tock values,
; Count downs,
; DLI and VBI routines.
;
; --------------------------------------------------------------------------


;==============================================================================
;                                                           MyImmediateVBI
;==============================================================================
; Immediate Vertical Blank Interrupt.
;
; Frame-critical tasks:
; Manage switching Display Lists.
; Force steady state of DLI.
;
; Input: zCurrentEvent  
; Current Event specified which Display List and which DLI chain to follow.
;
; EVENT_INIT             = 0  ; One Time initialization.
; EVENT_SETUP_TITLE      = 1  ; Entry Point to setup title screen.
; EVENT_TITLE            = 2  ; Credits and Instructions.
; EVENT_COUNTDOWN        = 3  ; Transition animation from Title to Game.
; EVENT_SETUP_GAME       = 4  ; Entry Point for New Game setup.
; EVENT_GAME             = 5  ; GamePlay
; EVENT_LAST_ROW         = 6  ; Ship/guns animation from Game to GameOver.
; EVENT_SETUP_GAMEOVER   = 7  ; Setup screen for Game over text.
; EVENT_GAMEOVER         = 8  ; Game Over. Animated words, go to title.
;==============================================================================

TABLE_GAME_DISPLAY_LIST
	.word $0000                   ; 0  = EVENT_INIT            one time globals setup
	.word DISPLAY_LIST_DO_NOTHING ; 1  = EVENT_SETUP_TITLE
	.word DISPLAY_LIST_TITLE      ; 2  = EVENT_TITLE           run title and get player start button
	.word DISPLAY_LIST_TITLE      ; 3  = EVENT_COUNTDOWN       then move mothership
	.word DISPLAY_LIST_TITLE      ; 4  = EVENT_SETUP_GAME
	.word DISPLAY_LIST_GAME       ; 5  = EVENT_GAME            regular game play.  boom boom boom
	.word DISPLAY_LIST_GAMEOVER   ; 6  = EVENT_SETUP_GAMEOVER
	.word DISPLAY_LIST_GAMEOVER   ; 7  = EVENT_GAMEOVER        display text, then go to title

TABLE_GAME_DISPLAY_LIST_INTERRUPT
	.word DoNothing_DLI  ; 0  = EVENT_INIT            one time globals setup
	.word DoNothing_DLI  ; 1  = EVENT_SETUP_TITLE
	.word TITLE_DLI      ; 2  = EVENT_TITLE           run title and get player start button
	.word TITLE_DLI      ; 3  = EVENT_COUNTDOWN       then move mothership
	.word TITLE_DLI      ; 4  = EVENT_SETUP_GAME
	.word GAME_DLI       ; 5  = EVENT_GAME            regular game play.  boom boom boom
	.word GAME_OVER_DLI  ; 6  = EVENT_SETUP_GAMEOVER
	.word GAME_OVER_DLI  ; 7  = EVENT_GAMEOVER        display text, then go to title


MyImmediateVBI

; ======== MANAGE CHANGING DISPLAY LIST AND DISPLAY LIST INTERRUPTS ========

	lda zCurrentEvent                       ; Is the game at 0 (INIT)?
	beq ExitMyImmediateVBI                  ; Yes.  Then we should not be here.

	asl                                     ; State value times 2 for size of address
	tax                                     ; Use as index

	lda TABLE_GAME_DISPLAY_LIST,x           ; Copy Display List Pointer for the OS
	sta SDLSTL                              
	lda TABLE_GAME_DISPLAY_LIST_INTERRUPT,x ; Copy Display List Interrupt chain table starting address
	sta VDSLST
	inx                                     ; and the high bytes...
	lda TABLE_GAME_DISPLAY_LIST,x
	sta SDLSTH
	lda TABLE_GAME_DISPLAY_LIST_INTERRUPT,x
	sta VDSLST+1

ExitMyImmediateVBI

	jmp SYSVBV ; Return to OS.  XITVBV for Deferred interrupt.



;==============================================================================
;                                                           MyDeferredVBI
;==============================================================================
; Deferred Vertical Blank Interrupt.
;
; This is the highest level that just examines the current screen 
; and calls the larger function that does the logic.
;
;==============================================================================

MyDeferredVBI

	lda zCurrentEvent           ; Is this still 0 (INIT)? 
	bne b_mdv_DoMyDeferredVBI   ; No.   Continue the Deferred VBI

	jmp XITVBV                  ; Yes.  We should not be here.  End now.  Return to OS.


; ======== Beginning - global for all ========
; Kill Attract mode.  Process PAL v NTSC frame for timing.

b_mdv_DoMyDeferredVBI

	jsr FrameManagement ; Figure out NTSC v PAL timing 


; ======== TITLE SCREEN AND COUNTDOWN ACTIVIES  ========
; ======================================================

	lda zCurrentEvent               ; Get current state
;	cmp #[EVENT_COUNTDOWN+1]        
	cmp #[EVENT_SETUP_GAME+1]       ; Is it TITLE or COUNTDOWN
;	bcc b_mdv_DoTitleAndCountdown   ; Yes. Less Than < SETUP is correct
	bcs b_mdv_DoGameManagement      ; No. Greater Than > COUNTDOWN is GAME or GAMEOVER
;	jmp b_mdv_DoGameManagement      ; No. Greater Than > COUNTDOWN is GAME or GAMEOVER

b_mdv_DoTitleAndCountdown

	jsr vbiDoTitleAndCountdown

	jmp EndOfMyDeferredVBI ; END OF TITLE SCREEN AND COUNTDOWN 


; ====================  GAME SCREEN  ===================
; ======================================================

b_mdv_DoGameManagement

;	lda zCurrentEvent         ; Get current state
	cmp #EVENT_GAME           ; Is it The Game?
;	beq b_mdv_DoTheGame       ; Yes. Do the Game
	bne b_mdv_DoGameOver      ; No. Check if doing  Game Over routine Greater Than > COUNTDOWN is GAME or GAMEOVER

;	jmp b_mdv_DoGameOver      ; No. Check if doing  Game Over routine Greater Than > COUNTDOWN is GAME or GAMEOVER

b_mdv_DoTheGame

	jsr vbiDoTheGame

	jmp EndOfMyDeferredVBI ; END OF GAME SCREEN


; =====================  GAME OVER  ====================
; ======================================================

; Use the index as found in the variables. 
; Increment at the end.  On entry, -1 means increment.

b_mdv_DoGameOver

;	lda zCurrentEvent              ; Get current state
	cmp  #EVENT_GAMEOVER           ; Are we doing Game Over
;	beq b_mdv_DoGameOverTransition ; Yes. Do the Game Over animation
;	jmp EndOfMyDeferredVBI          ; No. Done here.
	bne EndOfMyDeferredVBI          ; No. Done here.

b_mdv_DoGameOverTransition         ; Let's animate text being displayed.

	jsr vbiDoGameOverTransition 

;	jmp EndOfMyDeferredVBI ; END OF GAME OVER SCREEN 


; ====================  END OF VBI  ====================
; ======================================================
; All the following run all the time on all displays.

EndOfMyDeferredVBI

; ======== NEW SHADOW REGISTERS  ========
; The main line code will do the extra work of updating the P/M graphics
; to starting Horizontal position (these fake Shadow regs).
; The game relies on the DLIs to cut up Players/Missiles to their proper 
; horizontal positions.

;b_mdv_ReloadFromShadow

	lda SHPOSP0  ; VBI Copy SHPOSP0 to HPOSP0
	sta HPOSP0   ; VBI Copy SHPOSP0 to HPOSP0
	lda SHPOSP1  ; VBI Copy SHPOSP1 to HPOSP1
	sta HPOSP1   ; VBI Copy SHPOSP1 to HPOSP1
	lda SHPOSP2  ; blah blah
	sta HPOSP2
	lda SHPOSP3
	sta HPOSP3
	lda SHPOSM0  ; etc etc etc
	sta HPOSM0
	lda SHPOSM1
	sta HPOSM1
	lda SHPOSM2
	sta HPOSM2
	lda SHPOSM3
	sta HPOSM3

	jsr Gfx_RunScrollingLand      ; Animated 24/7 on all screens

DoCheesySoundService              ; World's most inept sound sequencer.
	jsr SoundService

	jmp XITVBV                    ; Return to OS.  SYSVBV for Immediate interrupt.



;==============================================================================
;====================  TITLE SCREEN AND COUNTDOWN ACTIVIES ====================
;==============================================================================

; For the Title and Countdown the work that needs to occur:
; 1) Mothership if moving up.
; 2) 3, 2, 1 GO, if in progress.
; 3) Animate Missiles for Title logo
; 4) Author scrolling
; 5) Documentation Scrolling
; 6) Mountain Background Scrolling.

vbiDoTitleAndCountdown


; ======== 1) MANAGE TITLE MOTHERSHIP MOVING UP  ========

b_mdv_DoBigMothership

	lda zBigMothershipPhase     ; What's it doing?  0 = steady.  1 = moving.
	beq b_mdv_EndBigMothership  ; 0, so nothing going on here.

	jsr Pmg_Draw_Big_Mothership ; Redraw.

	lda zBIG_MOTHERSHIP_Y       ; If this is positive, 
	bpl b_mdv_DecBigMothership  ; subtract 1 for the next frame.

	lda #0                      ; Y reached negative on last frame.
	sta zBigMothershipPhase     ; The mothership is now off/erased.
	beq b_mdv_EndBigMothership

b_mdv_DecBigMothership
	dec zBIG_MOTHERSHIP_Y       ; This section will run once with Y==-1, to erase mothership.

b_mdv_EndBigMothership
	; Whether or not the mothership is moving the lights must be maintained.
	jsr Pmg_AnimateMothershipLights
	jsr Pmg_AnimateBigMothershipWindows

	; P0 and P1 are shared between the big mothership and the guns.   
	; The size for the Players needs to be reset to double width for the 
	; top half of the screen.  A DLI after the mothership will set the size 
	; for the guns.
	lda #PM_SIZE_DOUBLE 
	sta SIZEP0
	sta SIZEP1


; ======== 2) MANAGE COUNTDOWN ANIMATION  ========

; Mostly run during the main line code.


; ======== 3) MANAGE TITLE COLOR ANIMATION ========

; Swap the graphics image to make it appear the text is animated.
; Manage the Missile positions and base color used for the color overlay.
; Main code draws Missiles images.

b_mdv_DoTitleAnimation 

	jsr Gfx_RunTagLine           ; Fade in/out tagline message

	; First, Animate the Title graphics (gfx pixels)

	dec zAnimateTitleGfx         ; decrement countown clock
	bne b_mdv_SkipTitleGfx       ; has not reached 0, then no work to do. 

	jsr Gfx_Animate_Title_Logo   ; Updates the display list LMS to point to new pixels.

b_mdv_SkipTitleGfx

	; Second, update the color information

	lda ZTitleLogoBaseColor      ; Always restore this from the base.
	sta ZTitleLogoColor          ; Save it for the DLI use
	lda #0 
	sta zTitleLogoCount          ; Reset count of the color change DLI on the logo.

	dec zAnimateTitlePM
	; Note that the main code is responsible for loading up the Missile image.  
	; THEREFORE, do not reset the zAnimateTitlePM timer for the Missile animation here.  
	; The main code will do it, because it needs to know that the timer reached 0.
	
	bne b_mdv_SkipTitleMissileUpdate ; !0 is not time to animate missiles?

	jsr Pmg_AdjustMissileColorAndHPOS ; Change Missile color and position.

b_mdv_SkipTitleMissileUpdate


; ======== 4) MANAGE CREDITS SCROLLING ========

; Two lines of author credits.   
; When the first line scrolls left the second line scrolls right.   
; Pause for a few seconds for reading comprehension.
; Then reverse directions.
; Rinse.  Repeat.

; 1) (VBI) If waiting, continue to wait.
; 2) (VBI) if not waiting, then do motion.  
; 3) (VBI) Wait for motion timer.
; 4) Execute motion. Either
; 4)a) top row to the left, bottom row to the right, OR
; 4)b) top row to the right, bottom row to the left
; 5) At end, then reset
; 5)a) toggle motion direction.
; 5)b) restart the waiting phase.

b_mdv_DoCreditScrolling

	lda zCreditsPhase             ; 0 == waiting    1  == scrolling
	bne b_mdv_DelayCreditScrollingTimer

	; Waiting....
	dec zCreditsTimer
	bne b_mdv_EndCreditScrolling  ; Timer still >0

	; Reset timer.  And start scrolling.
	inc zCreditsPhase             ; To get here we know this was 0.
	lda #CREDITS_MAX_PAUSE
	sta zCreditsTimer

b_mdv_DelayCreditScrollingTimer
	dec zCreditsScrollTimer       ; Delay to not scroll to quickly.
	bne b_mdv_EndCreditScrolling

	lda #CREDITS_STEP_TIMER       ; Reset the scroll timer
	sta zCreditsScrollTimer

	; We are moving the credits...
	jsr Gfx_CreditsScrolling

b_mdv_EndCreditScrolling


; ======== 5) MANAGE DOCUMENTATION SCROLLING ========

; 1) Wait for motion timer.
; 2) Execute motion.
; 3)a) dec fine scroll to move left 
; 3)b) if at end of fine scroll then increment LMS pointer.
; 4) if at end of scrolling region, reset to start

b_mdv_DocsScrolling

	; Waiting....
	dec zDocsScrollTimer
	bne b_mdv_EndDocsScrolling  ; Timer still >0

	; Reset timer.
	lda #DOCS_STEP_TIMER
	sta zDocsScrollTimer

	; We are scrolling the documentation...
	jsr Gfx_DocsScrolling  

b_mdv_EndDocsScrolling


; ======== 6) MANAGE OPTION, SELECT, START MENUS ========
; MENUTASTIC ============================================================================

; 1) If menu is in motion, continue the motion.  End.
; 2) If menu is not in motion, collect input from Option/Select/Start keys
; 3) If there is input, restart the input timer.
; 4) If there is no input, decrement the input timer.  End.

b_mdv_ManageMenus

	jsr vbi_ManageMenutastic

b_mdv_EndManageMenus

; MENUTASTIC ============================================================================


; ======== 7) MANAGE TERRAIN SCROLLING ========

; This happens later for all screens . . .

; Scroll all four lines of terrain back and forth.
; All four move in the same direction/same speed.
; Pause for a few seconds at the end of a move.
; Then reverse directions.
; Rinse.  Repeat.

; b_mdv_DoLandScrolling

;	jsr Gfx_RunScrollingLand

; b_mdv_EndLandScrolling


; ======== 8) MANAGE PLAYER MOVEMENT  ========

; The main code provided updates to player state for the New Y position.
; If the New Y does not match the old Player Y player then update Y.
; Redraw players only if something changed.
; Also, main code can flip on Redraw to force a redraw.

b_mdv_DoPlayerMovement

	jsr Pmg_ManagePlayersMovement

b_mdv_EndPlayerMovement

; ========  END OF TITLE SCREEN  ========

	rts




;==============================================================================
;================================  GAME SCREEN  ===============================
;==============================================================================

vbiDoTheGame

	lda #0
	sta zDLIStarLinecounter        ; reset DLI counter.

	jsr Pmg_CollectCollisions      ; Collect collision bits, set flags, hit HITCLR

	jsr Gfx_RunGameStars           ; Animate the flashing stars

	jsr GameProcessExplosion       ; Handle collision detection, start explosion

	jsr Pmg_ProcessMothership      ; automatically increments Y until it is NEW_Y

	jsr Pmg_Draw_Lasers            ; draw lasers if present.

	jsr Pmg_ManagePlayersMovement  ; Handles guns for Title and Game displays.

	jsr Gfx_CheatModeStars         ; if in cheat mode, change the star image.

	rts



;==============================================================================
;=============================  GAME OVER SCREEN  =============================
;==============================================================================

vbiDoGameOverTransition

	lda zGO_CHAR_INDEX             ; 0 to 9 [12] (-1 is starting state) 13 is end.
	cmp #13 
	beq b_EndofEndofGameOver       ; Animation is over when char index reaches 13.

	dec zGO_FRAME                  ; 5 to 0. -1 is reset and increment char index.
	bpl b_mdv_DoGameOverAnimation  ; 0 or more.  So, Frame does not need reset.

	lda #5
	sta zGO_FRAME                  ; Restart frame counter
	inc zGO_CHAR_INDEX             ; Go to next character.
	lda zGO_CHAR_INDEX
	cmp #13 
	beq b_EndofEndofGameOver       ; Animation is over when char index reaches 13.

	jsr Gfx_UpdateGameOverChars    ; Update chars on screen with color bits set.

b_mdv_DoGameOverAnimation
	jsr Gfx_SetupCOLPF2Index       ; Setup base index used for DLI for COLPF2

b_EndofEndofGameOver
	rts



;==============================================================================
;=========================== DISPLAY LIST INTERRUPTS ==========================
;==============================================================================

	.align $0100 ; Make the DLIs start in the same page to simplify chaining. I hope.


;==============================================================================
;                                                           MyDLI
;==============================================================================
; Display List Interrupts
;
; Note the DLIs don't care where the ThisDLI index ends as 
; this is managed by the VBI.
;==============================================================================

; shorthand for starting DLI  (that do not JMP immediately to common code)
	 .macro mStart_DLI
		 mRegSaveAY

;		 ldy zThisDLI
	 .endm


;==============================================================================
; TITLE DLIs
;
; The positioning and color for the Mothership, the 3, 2, 1, GO, and 
; all the Missiles acting as P5 to color the title area all managed 
; with the fake Shadow registers loaded to the hardware registers 
; during the Deferred Vertical Blank routine.
;
; So, the first DLI needed on the Title screen sets narrow width 
; DMA and changes the GPRIOR value to show GTI 16-greyscale mode. 
;
;==============================================================================

TITLE_DLI  ; Placeholder for VBI to restore staring address for DLI chain.

;==============================================================================
; TITLE_DLI_0                                             
;==============================================================================
; DLI to set Narrow screen DMA.  Needed to move this to an earlier 
; position on screen to accommodate the Countdown text.
; -----------------------------------------------------------------------------


TITLE_DLI_0

	mStart_DLI

	jsr DLI_ColorFilterScores

	pla
	tay

	mChainDLI TITLE_DLI_0,TITLE_DLI_0_1



TITLE_DLI_0_1

	mStart_DLI

	jsr DLI_ScoreLineGradient

	; Set all the ANTIC screen controls and DMA options.
	lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NARROW]
	sta WSYNC                ; line 8
	sta DMACTL

	jsr DLI_RestorePlayers
	
	pla
	tay

	mChainDLI TITLE_DLI_0_1,TITLE_DLI_1


;==============================================================================
; TITLE_DLI_1                                             
;==============================================================================
; DLI to set Narrow screen DMA, and turn on GTIA mode 16 grey scale mode.
; This is preparing the screen for the big title logo done in GTIA pixels.
; -----------------------------------------------------------------------------

TITLE_DLI_1 

	pha

	; Setup PRIOR for 16 grey-scale graphics, and Missile color overlay.
	; The screen won't show any noticeable change here, because the COLBK 
	; value is black, and this won't change for the 16-shade mode.
	lda #[MULTICOLOR_PM|FIFTH_PLAYER|GTIA_MODE_16_SHADE|$01] 
	sta PRIOR

	mChainDLI TITLE_DLI_1,TITLE_DLI_2


;==============================================================================
; TITLE_DLI_2                                             
;==============================================================================
; DLI to increment and reload the COLPF3 value for the Missiles/5th Player
; color overlay.   Each line is a different base color. 
; In theory that's 4 grey shades + (6 lines * 4 shades) + background
; which is 29 colors possible on the logo.  In reality its probably closer
; to 18 to 20 given the shape of text v the overlay. 
; -----------------------------------------------------------------------------

TITLE_DLI_2

	mStart_DLI ; Saves A and Y

	lda zTitleLogoColor     ; Update color register.
	sta WSYNC               ; (1.1) sync to end of line.
	sta COLPF3

	cmp #COLOR_ORANGE_GREEN ; Is it the ending color?
	bne b_tdli2_AddToColor  ; No. Add to the color component.

	lda #COLOR_ORANGE1      ; Yes.  Reset to first color.
	bne b_tdli2_UpdateColor ; Go do the update.

b_tdli2_AddToColor
	clc
	adc #$10                ; Add 16 to color.

b_tdli2_UpdateColor
	sta zTitleLogoColor     ; Save it for the next DLI use

	inc zTitleLogoCount
	lda zTitleLogoCount
	cmp #6
	beq b_tdli2_ExitChain

	; Normal Exit 
	pla
	tay
	pla

	rti


b_tdli2_ExitChain
	pla
	tay

	mChainDLI TITLE_DLI_2,TITLE_DLI_2_5 ; Done here.  Finally go to next DLI.


;==============================================================================
; TITLE_DLI_2_5                                           
;==============================================================================
; AFTER the multi-color logo fun and games reset the playfield to normal  
; GTIA playfield color interpretation.
; -----------------------------------------------------------------------------

TITLE_DLI_2_5

	pha

;	lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NORMAL]
;	sta WSYNC                      ; Next scan line
;	sta DMACTL                     ; Set all the ANTIC screen controls and DMA options.
	; Return to normal color interpretation, Players on top.
	lda #[MULTICOLOR_PM|FIFTH_PLAYER|GTIA_MODE_DEFAULT|$01]       
	sta WSYNC                      ; Next scan line
	sta PRIOR

	mChainDLI TITLE_DLI_2_5,TITLE_DLI_2_7 ; Done here.  Finally go to next DLI.


;==============================================================================
; TITLE_DLI_2_7                                          
;==============================================================================
; Handle the colors for the One Liner Tag line subtitle.  
; (One Button. One Alien. One Life. No Mercy.)
; At the end, set the playfield DMA back to normal width.
; -----------------------------------------------------------------------------

TITLE_DLI_2_7

	 mStart_DLI ; Saves A and Y

	ldy #7

b_dli27_LoopColors
	lda TABLE_COLOR_TAGLINE_PF0,y
	sta WSYNC    
	sta COLPF0
	lda TABLE_COLOR_TAGLINE_PF1,y   
	sta COLPF1

	dey
	bpl b_dli27_LoopColors

	pla
	tay

	lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NORMAL]
	sta WSYNC                      ; Next scan line
	sta DMACTL                     ; Set all the ANTIC screen controls and DMA options.

	mChainDLI TITLE_DLI_2_7,TITLE_DLI_3 ; Done here.  Finally go to next DLI.



;==============================================================================
; TITLE_DLI_3                                             
;==============================================================================
; DLI to run the horizontally scrolling Author Credits and stuff a gradient 
; color into COLPF0 and COLPF1 for the text.
; -----------------------------------------------------------------------------

TITLE_DLI_3

	 mStart_DLI ; Saves A and Y

	ldy #7

	lda zCredit1HS ;
	sta HSCROL

b_dli3_LoopColors	
	lda TABLE_COLOR_AUTHOR1,y
	sta WSYNC    
	sta COLPF0
	lda TABLE_COLOR_AUTHOR2,y
	sta COLPF1
	
	dey
	bpl b_dli3_LoopColors

	pla
	tay

	mChainDLI TITLE_DLI_3,TITLE_DLI_3_2


;==============================================================================
; TITLE_DLI_3_2                                             
;==============================================================================
; DLI to run the horizontally scrolling Computer Credits and stuff a gradient 
; color into COLPF0 and COLPF1 for the text.
; -----------------------------------------------------------------------------

TITLE_DLI_3_2

	 mStart_DLI ; Saves A and Y

	ldy #7

	lda zCredit2HS ;
	sta HSCROL

b_dli32_LoopColors	
	lda TABLE_COLOR_COMP1,y
	sta WSYNC    
	sta COLPF0
	lda TABLE_COLOR_COMP2,y
	sta COLPF1
	
	dey
	bpl b_dli32_LoopColors

	pla
	tay

	mChainDLI TITLE_DLI_3_2,TITLE_DLI_4


;==============================================================================
; TITLE_DLI_4                                             
;==============================================================================
; DLI to run the horizontally scrolling Documentation  and  stuff  gradient 
; colors into COLPF0 for the text on the line.
; -----------------------------------------------------------------------------

TITLE_DLI_4

	 mStart_DLI ; Saves A and Y

	ldy #7

	lda zDocsHS 
	sta HSCROL

b_dli4_LoopColors	
	lda TABLE_COLOR_DOCS,y
	sta WSYNC    
	sta COLPF0
	lda TABLE_COLOR_DOCS2,y
	sta COLPF1
	
	dey
	bpl b_dli4_LoopColors

	lda #PM_SIZE_NORMAL  ; Guns below mothership need correct size
	sta SIZEP0
	sta SIZEP1

	pla
	tay


	mChainDLI TITLE_DLI_4,TITLE_DLI_4_5 ; Done here.  Finally go to next DLI.


;==============================================================================
; TITLE_DLI_4_5                                             
;==============================================================================
; DLI to stuff  gradient colors into COLPF0/COLPF1/COLPF2 for Mode 6 
; options text line.
; Then make sure COLPF2 is black for the documentation text done in 
; Mode 2, then run the same gradient for COLPF1 that is used for the 
; score line. 
; -----------------------------------------------------------------------------

TITLE_DLI_4_5

	 mStart_DLI ; Saves A and Y

	ldy #7

;	lda zOptionHScroll ; Scroll value for options.  VBI sets this and LMS.
;	sta HSCROL

b_dli4_5_LoopColors
	lda TABLE_COLOR_OPTS0,y
	sta WSYNC    
	sta COLPF0
	lda TABLE_COLOR_OPTS1,y
	sta COLPF1
	lda TABLE_COLOR_OPTS2,y
	sta COLPF2
	
	dey
	bpl b_dli4_5_LoopColors
	
	lda #0
	sta COLPF2 ; Need COLPF2 to be black for options text below.

	jsr DLI_ScoreLineGradient ; shade the documentation line 

	pla
	tay

	mChainDLI TITLE_DLI_4_5,TITLE_DLI_COMMON_MOUNTAINS ; Done here.  Finally go to next DLI.



;==============================================================================
; TITLE_DLI_COMMON_MOUNTAINS                                             
;==============================================================================
; DLI to run the colors for the horizontally scrolling land.
; Fine scroll is already set, so, this just sets COLPF0, 1, 2.
; The color tables refereced are in gfx.asm.
; Note that this indexes TWICE and changes the colors at the 
; top of the line, and in the middle of the line of text.
; -----------------------------------------------------------------------------

TITLE_DLI_COMMON_MOUNTAINS

	mStart_DLI ; Saves A and Y

	lda zLandHS
	sta HSCROL
	
	ldy zLandColor           ; Get color index.
	
	lda TABLE_LAND_COLPF0,y  ; Load the three registers for PF0, PF1, PF2
	sta WSYNC   ; (1.0)
	sta COLPF0
	
	lda TABLE_LAND_COLPF1,y
	sta COLPF1

	lda TABLE_LAND_COLPF2,y
	sta COLPF2

	iny                      ; Next index

	lda TABLE_LAND_COLPF0,y  ; Prep for first update below...

	sta WSYNC   ; (1.1)      ; Skip 3 more scan lines.
	sta WSYNC   ; (1.2)
	sta WSYNC   ; (1.3)
	
	sta WSYNC   ; (1.4)      ; 4th line, start new colors.
	
	sta COLPF0               ; Load the three registers for PF0, PF1, PF2 

	lda TABLE_LAND_COLPF1,y
	sta COLPF1

	lda TABLE_LAND_COLPF2,y
	sta COLPF2

	iny                      ; Next index.

	cpy #8                   ; Have we done this 4 times?   (4 * 2 iny == 8)
	beq b_dli5_FinalExit     ; Yup.   can chain to the next DLI now.

	sty zLandColor           ; FYI: VBI will reset index to 0.

	pla                      ; Clean up. Normal Exit.  Next DLI calls this same routine.
	tay
	pla

	rti


b_dli5_FinalExit            ; Chain to next DLI

	pla
	tay

	mChainDLI TITLE_DLI_COMMON_MOUNTAINS,TITLE_DLI_COMMON_LASTLINES ; Done here.  Finally go to next DLI.


;==============================================================================
; TITLE_DLI_COMMON_LASTLINES                                             
;==============================================================================
; Do the colors for the non-scrolling land under the mountains.
; Start the background from darkest dirt color and increment brighness.
; Start COLPF0 at a lighter tan and increment to lighter color at same speed.
; 
; At the end, reset colors for the bottom status line.
; -----------------------------------------------------------------------------


TITLE_DLI_COMMON_LASTLINES

	mStart_DLI ; Saves A and Y

	
	lda TT_DLI6_Alt_Ground ; ($24) Change COLPF1 to use as alternate ground color.
	sta WSYNC
	sta COLPF1

; In order to work in the update for the guns horizontal position to
; separate them from their lasers, we need to hardcode the first 
; scan line of work.
;b_dli6_NextLoop                    ; Make colors on the Active Guns and Bumper.
	lda TABLE_COLOR_BLINE_BUMPER+6 ; bumper first
	sta COLPF3

	lda zPLAYER_ONE_X ; DLI Gun's HPOSP0 value to separate from laser
	sta HPOSP0        ; DLI Gun's HPOSP0 value to separate from laser
	lda zPLAYER_TWO_X ; DLI Gun's HPOSP1 value to separate from laser
	sta HPOSP1        ; DLI Gun's HPOSP1 value to separate from laser

	ldy #5 ; Yup, 6 counting down to 0 is 7 scan lines, not 8. (Aaaand, counting only 5.  sixth is above.)
	sta WSYNC

b_dli6_NextLoop  
	lda TABLE_COLOR_BLINE_BUMPER,y ; bumper first
	sta COLPF3

	lda TABLE_COLOR_BLINE_PM0,y    ; Player 1 gun
	sta COLPM0

	lda TABLE_COLOR_BLINE_PM1,y   ; Player 2 gun
	sta COLPM1

	dey
	sta WSYNC

	bpl b_dli6_NextLoop          ; Stop looping on the 7th scan line


	lda TABLE_LAND_COLPF0+7      ; make the background match PF0's color from the scrolling mountains 
	sta COLBK                    ; for one scan line

	lda #0
	ldy zPLAYER_ONE_COLOR       ; Set guns to grey on the stats line.

	; NOTE.  This is only halvsies work.  ANTIC Mode 2 Text does not render invisible 
	; UNDER the Players objects.  It always renders on top.   So, where the idle guns 
	; overlap the stats line the text will show on top of the Players.   The Code 
	; MUST ALSO remove the actual statistics text when it is not needed -- when the 
	; guns are in the idle positions.
	
	sta WSYNC      ; Next scan line set the colors for the STATISTICS text. 
	sta COLBK      ; Background/border to black, too.
	sta COLPF2     ; Text background

	sty COLPM0
	ldy zPLAYER_TWO_COLOR
	sty COLPM1

	ldy zSTATS_TEXT_COLOR
	sty COLPF1      ; STATISTICS LINE Text luminance
	beq b_dli6_Exit ; If text is off, then do nothing else.

b_dli6_LoopStatsColor ; Gradient for STATISTICS LINE if it is on.
	sta WSYNC
	sta WSYNC
	dey
	dey
	sty COLPF1      ; Stats Text luminance
	cpy #4
	bne b_dli6_LoopStatsColor 

b_dli6_Exit
	pla
	tay


	mChainDLI TITLE_DLI_COMMON_LASTLINES,DoNothing_DLI ; Done here.  Park it until VBI restarts it.


	.align $0100

;==============================================================================
;                                              GAME_DLI_0
;==============================================================================
; Set HSCROL for stars.  Sync down and deal out the  colors.
;
;  There is an extra blank line now to deal with something weird in 
; the DLI timing.   According to Altirra recursive DLI are happening.
; This is likely due to certain HSCROL positions changing DMA time.
; (Though I'm having problems determing how.)
; This will subtract a couple stars lines from the display to make up 
; for the extra blank lines.
;
; 1 Blank scan line + DLI == set hscrol
; 1 Blankscan line        == and setup colors.
; Mode6, 1                == Star COLPF1 dark
; Mode6, 2                == 
; Mode6, 3                == Star COLPF1 dark
; Mode6, 4                == Star COLPF1 light
; Mode6, 5                == Star COLPF1 dark - Last STA COLPF0.  Setup for next DLI.
; Mode6, 6                == 
; Mode6, 7                == Star COLPF1 dark
; Mode6, 8                == 
;
;  Star for Atari for Mode 6 color
;	.by $08,$00,$08,$2a
;	.by $08,$00,$08,$00
; $08 ....*... 1 dark
; $00 ........ 2
; $08 ....*... 3 dark
; $2A ..*.*.*. 4 light
; $08 ....*... 5 dark
; $00 ........ 6
; $08 ....*... 7 dark
; $00 ........ 8
; -----------------------------------------------------------------------------


GAME_DLI  ; Placeholder for VBI to restore starting address for DLI chain.


GAME_DLI_0

	mStart_DLI

	jsr DLI_ColorFilterScores

	pla
	tay

	mChainDLI GAME_DLI_0,GAME_DLI_0_1



GAME_DLI_0_1

	mStart_DLI

	jsr DLI_ScoreLineGradient

	sta WSYNC

	jsr DLI_RestorePlayers

	pla
	tay

	mChainDLI GAME_DLI_0_1,GAME_DLI_1



GAME_DLI_1

	mStart_DLI ; Saves A and Y

	ldy zDLIStarLinecounter

	lda TABLE_GFX_STAR_HSCROL,y
	sta HSCROL

	inc zDLIStarLinecounter        ; (Note, VBI will zero this). 

;; The things above are time critical, because they may start on 
;; a mode 2 line with high DMA, so the working star rows evaluation 
;; need to be evaluated later.   This shortcut evaluation below 
;; saves a solid four scan lines of waiting per each star row 
;; that is idle.

	lda TABLE_GFX_STAR_WORKING,y
	bne b_GDLI0_ActiveStar
	sta COLPF0                      ; Black out the star if not in use.
	beq b_GDLI0_ShortcutToExit

	; This Star is Active.   Apply a gradient, like, fading behavior.
b_GDLI0_ActiveStar
	lda TABLE_GFX_STAR_OUT_COLOR,y  ; Get the outer color.
	sta COLPF0

	pha
	lda TABLE_GFX_STAR_IN_COLOR,y   ; Get the inner, brighter color.


; FYI, the rest of this is wait wait wait.
	sta WSYNC
	sta WSYNC
	sta WSYNC
	sta WSYNC

	sta COLPF0                     ; Use the inner, brighter color.
	pla                            ; Get the outer color again.
	sta WSYNC 
	sta COLPF0                     ; Use the outer color

b_GDLI0_ShortcutToExit             ; If star was Inactive this is the easy exit to save time.
;	inc zDLIStarLinecounter        ; (Note, VBI will zero this). 

	cpy #14                        ; Has this DLI run 15 times?  (originally 16)

	bne b_GDLI0_NormalExit         ; No.   normal exit to repeat this DLI.

	pla                            ; Done executing this series of DLIs.   
	tay

	mChainDLI GAME_DLI_0,TITLE_DLI_COMMON_MOUNTAINS ; Do the land colors next.


b_GDLI0_NormalExit                ; Exit without changing the DLI vector.

	pla
	tay
	pla

	rti

;==============================================================================


;==============================================================================
;                                              GAME_OVER_DLI_0
;==============================================================================
; Set COLPF0 and COLPF1 per current frame index.
; Chain to next DLI that works COLPF2 and COLPF3.
; -----------------------------------------------------------------------------

GAME_OVER_DLI  ; Placeholder for VBI to restore starting address for DLI chain.


GAME_OVER_DLI_0

	mStart_DLI

	jsr DLI_ColorFilterScores

	pla
	tay

	mChainDLI GAME_OVER_DLI_0,GAME_OVER_DLI_0_1



GAME_OVER_DLI_0_1

	mStart_DLI

	jsr DLI_ScoreLineGradient

	sta WSYNC
	
	jsr DLI_RestorePlayers

	pla
	tay

	mChainDLI GAME_OVER_DLI_0_1,GAME_OVER_DLI_1



GAME_OVER_DLI_1

	mStart_DLI ; Saves A and Y

	ldy zGO_FRAME ; Get current frame

	lda TABLE_GAME_OVER_PF0,Y ; colors for initial blast-in frames in reverse
	sta COLPF0
	lda TABLE_GAME_OVER_PF1,Y ; colors for next phase in reverse
	sta COLPF1

	pla                            ; Done executing this series of DLIs.   
	tay

	lda #>[CHARACTER_SET+$0200]
	sta CHBASE
	
	mChainDLI GAME_OVER_DLI_1,GAME_OVER_DLI_2 ; next DLI is multi-scan-lines

	rti


;==============================================================================
;                                              GAME_OVER_DLI_2
;==============================================================================
; Set COLPF2 and COLPF3 per tables for 16 scan lines.
; Chain to next DLI that does the land scrolling. 
; -----------------------------------------------------------------------------

GAME_OVER_DLI_2

	mStart_DLI ; Saves A and Y

	txa                       ; Need to save more 
	pha

	ldy zGO_COLPF2_INDEX
	ldx #15                   ; 16 scan lines, 15 to 0.

b_GODLI1_CopyLoop
	lda TABLE_GAME_OVER_PF2,y ; Get from table based on COLPF2 index.
	sta WSYNC                 ; sync scan line
	sta COLPF2                ; COLPF2 is transitioning from flat grey to gradients
	lda TABLE_GAME_OVER_PF3,x ; get from table based on scan line
	sta COLPF3                ; Final, non-animated version.

	dey
	dex
	bpl b_GODLI1_CopyLoop     ; Do until X == -1

	pla
	tax
	pla                              
	tay

	lda #>CHARACTER_SET
	sta CHBASE
	
	mChainDLI GAME_OVER_DLI_2,TITLE_DLI_COMMON_MOUNTAINS ; Do the land colors next.

;==============================================================================

DoNothing_DLI ; In testing mode jump here to not do anything or to stop the DLI chain.
	 rti


;==============================================================================
; R E U S A B L E S -- DLI things called by JSR from multiple places.

;==============================================================================
; Gradient for the score line.
; Expect mStartDLI is called before this.
; Intentional double WSYNC to put the brightest color ($E) on the 
; second line to be visible on the font.
; Stops after six lines having used color ($4), since most
; characters use only 6 lines of data, and I don't want the bottom
; to become too dark.
; The code also adds an extra WSYNC to make sure the execution point
; is at the last scan line for the text mode. (The Game/GameOver will 
; end here, but the title screen will set narrow screen DMA on the next
; scan line [a blank line] after the text mode.

DLI_ScoreLineGradient

	ldy #$0E

	sta WSYNC                ; line 0

b_dli_LoopScoreTextColor
	sta WSYNC                ; line 1/14, 2/12, 3/10, 4/8, 5/6, 6/4,
	sty COLPF1
	dey
	dey
	cpy #$02
	bne b_dli_LoopScoreTextColor

;	sta WSYNC ;  line 7/(2 but not used) 

	rts


;==============================================================================
; Move Players over score positions to color ize the values.
; If player is not playing do not move.

DLI_ColorFilterScores

	lda gSCORES_ON
	beq b_dli0_Skip

	lda #52
	sta HPOSP2
	lda #180
	sta HPOSP3

	lda TABLE_COLOR_BLINE_PM0 ; Get Player Color
	and #$f0                  ; Reduce to base color (eliminate luminance.)
	sta COLPM2                ; Save as "backgound" to tint the text.

	lda TABLE_COLOR_BLINE_PM1 ; Get Player Color
	and #$f0                  ; Reduce to base color (eliminate luminance.)
	sta COLPM3                ; Save as "backgound" to tint the text.

	lda #PM_SIZE_QUAD
	sta SIZEP2
	sta SIZEP3

	lda #[MULTICOLOR_PM|FIFTH_PLAYER|GTIA_MODE_DEFAULT|$00] 
	sta PRIOR

b_dli0_Skip
	rts

;==============================================================================
; Restore game visuals after abusing Players to make color 
; overlay for scores.

DLI_RestorePlayers

	lda #[MULTICOLOR_PM|FIFTH_PLAYER|GTIA_MODE_DEFAULT|$01] 
	sta PRIOR

	lda SHPOSP2 
	sta HPOSP2
	lda PCOLOR2
	sta COLPM2

	lda SHPOSP3 
	sta HPOSP3
	lda PCOLOR3
	sta COLPM3

	lda zCurrentEvent
	cmp #EVENT_SETUP_GAME
	bcs b_dli_rs_GameSizes ; Greater than or equal to Setup Game

	lda #PM_SIZE_DOUBLE
	bne b_dli_rs_SetSizes

b_dli_rs_GameSizes
	lda #PM_SIZE_NORMAL

b_dli_rs_SetSizes
	sta SIZEP2
	sta SIZEP3

	sta HITCLR

	rts

