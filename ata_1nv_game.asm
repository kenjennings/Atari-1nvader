;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; GAME MAIN LOOP
; 
; Each TV frame is one game cycle. This executes in two parts.  First, the 
; main line code here in this file which executes while the frame is being 
; displayed.  Second is the VBI whose job is to to compute and do things 
; that affect the display.
;
; In the "Interrupts" file the VBI takes care of most graphics updates, 
; and the DLIs produce the per-scanline changes needed at different 
; points on the display.
; 
; The game operates in states with a routine assigned to each state.
; Some "states" are one-time events that set up the variables for 
; a following state.  Other major states keep looping until a condition 
; is met to move to another state.
;
; Since each iteration of the main event loop syncs to the display the 
; setup functions execute for a frame and the next frame runs the next 
; major function.  The apparent one frame pause shouldn't be noticed, 
; because it typicall happens in places where the game is not maintaining 
; constant animation.
;
; The major states are Title screen, Game screen, Game Over. While in 
; these states the main loop and VBI are cooperating to run animated 
; components on the screen.
;
; Example:  The Title Screen 
;
; The VBI manages the timing, performs the page flipping for the graphics, 
; sets the Missile color overlay horizontal position and color.  The main 
; code watches the timing clock for animation and updates the Missile 
; color overlay image when needed.
;
; The Title Screen state is waiting on a joystick button to leave 
; the state.  Then the next state is a transitional condition that 
; runs animation for the 3, 2, 1, GO animation while it waits for the 
; other player to press a button.  
;
; After that the next state is a transition animation to move the large
; mothership off the screen to go to the state for the Game Screen. 
; --------------------------------------------------------------------------


; ==========================================================================
; 1nvader STATE/EVENTS
;
; All the routines to run for each screen/state.
; --------------------------------------------------------------------------

; Each State has associated vectors for the game routine, the display 
; list, and the display list interrupts.  
;
; This is a simple game, so there are only special screen 
; considerations for the Title screen, the Main Game, and some 
; display tweaking for the Game Over.  Certain visual components are
; placed identically from screen to screen, so screen transitions 
; are less obvious.
;
; Given the current program state, the Immediate VBI sets the 
; Disply List and Display List Interrupt vectors.  The main line 
; game loop calls the associated state function.
;
; There are 2 kinds of displays to run.  The Title and the Game.
; Other activities occur on one of these displays.  The count down 
; and giant mothership animation occur on the Title screen.  The 
; Game Over display uses a display similar to the Game screen.  
; Alo, there are different DLI chains and lookup tables for colors 
; used depending on what the screen is doing.

; Below is enumeration for each processing state.
; Note that the order here does not imply the only order of
; movement between screens/event activity.  The enumeration
; could be entirely random.

EVENT_INIT             = 0  ; One Time initialization.
EVENT_SETUP_TITLE      = 1  ; Entry Point to setup title screen.
EVENT_TITLE            = 2  ; Credits and Instructions.
EVENT_COUNTDOWN        = 3  ; Transition animation from Title to Game.
EVENT_SETUP_GAME       = 4  ; Entry Point for New Game setup.
EVENT_GAME             = 5  ; GamePlay
EVENT_LAST_ROW         = 6  ; Ship/guns animation from Game to GameOver.
EVENT_SETUP_GAMEOVER   = 7  ; Setup screen for Game over text.
EVENT_GAMEOVER         = 8  ; Game Over. Animated words, go to title.

; The Immediate Vertical Blank Interrupt will update the Display List 
; OS shadow register, and the Display List Interrupt vector based 
; on the program state.  Note that Entry 0 is pointless to define,
; for the Display List and the Display List Interrupt, because the 
; Init state (0 entry) will never have an operating display.
; The Init state only sets permanent globals and shadow registers.

TABLE_GAME_FUNCTION
	.word GameInit-1       ; 0  = EVENT_INIT            one time globals setup
	.word GameSetupTitle-1 ; 1  = EVENT_SETUP_TITLE
	.word GameTitle-1      ; 2  = EVENT_TITLE           run title and get player start button
	.word GameCountdown-1  ; 3  = EVENT_COUNTDOWN       then move mothership
	.word GameSetupMain-1  ; 4  = EVENT_SETUP_GAME
	.word GameMain-1       ; 5  = EVENT_GAME            regular game play.  boom boom boom
	.word GameLastRow-1    ; 6  = EVENT_LAST_ROW        forced player shove off screen
	.word GameSetupOver-1  ; 7  = EVENT_SETUP_GAMEOVER
	.word GameOver-1       ; 8  = EVENT_GAMEOVER        display text, then go to title

; ==========================================================================
; GAME LOOP
;
; The main event dispatch loop for the game... said Capt Obvious.
; Very vaguely like an event loop or state loop across the progressive
; game states which are (loosely) based on the current mode of
; the display.
;
; When each event reaches an end codition it sets zCurrentEvent to change 
; to another event/state target.
;
; Thus all routines executing as main line code are synchronized to the 
; top of the frame.  They should complete before the bottom of the frame.  
; Ideally, where the main line code is manipulating the screen objects  
; it should do so BEFORE or AFTER the item is displayed. 
; to the  display, and whenever it exits 
; --------------------------------------------------------------------------

GameLoop

	jsr libScreenWaitFrame     ; Wait for end of frame, start of new frame.

; Due to the frame sync above, at this point the code
; is running at/near the top of the screen refresh.

	lda zCurrentEvent           ; Get the current event
	asl                         ; Times 2 for size of address
	tax                         ; Use as index

	lda TABLE_GAME_FUNCTION+1,x ; Get routine high byte
	pha                         ; Push to stack
	lda TABLE_GAME_FUNCTION,x   ; Get routine low byte 
	pha                         ; Push to stack

	rts                         ; Forces calling the address pushed on the stack.

	; When the called routine ends with rts, it will return to the place 
	; that called this routine which is up in GameStart.

; ==========================================================================
; END OF GAME EVENT LOOP
; --------------------------------------------------------------------------


; ==========================================================================
; EVENT GAME INIT
; ==========================================================================
; The Game Starting Point.  Event Entry 0.
; Called only once at start.  The game will never return here.
; Setup all the values that are Global to the program: i.e. the default 
; OS shadow values that are consistent with the beginning of each screen.
; Note that the vast majority of game values in page 0 are automatically
; set/initialized as load time, so there does not need to be any first-
; time setup code here.
; --------------------------------------------------------------------------

GameInit
	; Atari initialization stuff...

	lda #AUDCTL_CLOCK_64KHZ    ; Set only this one bit for clock.
	sta AUDCTL                 ; Global POKEY Audio Control.
	lda #3                     ; Set SKCTL to 3 to stop possible cassette noise, 
	sta SKCTL                  ; so say Mapping The Atari and De Re Atari.
	jsr StopAllSound           ; Zero all AUDC and AUDF

	lda #>CHARACTER_SET        ; Set custom character set.  Global to game, forever.
	sta CHBAS

	; Zero all the colors.  (Except text will be turned back on to white.)
	; Zero all Player positions (fake shadow registers for HPOS) 
	; DLIs will (re)set them all as needed other.

	ldx #7
	lda #0
b_gi_LoopFillZero
	sta PCOLOR0,x ; Init - Zero color registers.
	sta SHPOSP0,x ; Init - Zero PM HPOS Values
	dex
	bpl b_gi_LoopFillZero

	sta COLOR4 ; COLBK  - Playfield Background color (Border for modes 2, 3, and F) 

	lda #COLOR_WHITE|$0C ; Light white
	sta COLOR1           ; COLPF1 - Playfield 1 color (mode 2 text)

	lda #0
	sta zThisDLI         ; Init the DLI index.

	; Set up the DLI.   This should be safe here without knowing what the screen
	; is doing, because the default OS display does not have DLI options on any 
	; mode instructions, AND a custom screen will not be started until the bottom
	; of the frame AND due to the frame sync of the main loop we know that this 
	; code here  is executing very close to the top of the screen.

	lda #NMI_VBI           ; Turn Off DLI
	sta NMIEN

	lda #<DoNothing_DLI    ; TITLE_DLI ; Set DLI vector. (will be reset by VBI on screen setup)
	sta VDSLST
	lda #>DoNothing_DLI    ; TITLE_DLI
	sta VDSLST+1

	lda #[NMI_DLI|NMI_VBI] ; Turn On DLIs
	sta NMIEN

	; Clear PM graphics memory and zero positions.

	jsr Pmg_Init               ; Will also reset GRACTL and SDMACTL settings for P/M DMA

	lda #%01010101 ; PM_SIZE_DOUBLE all missiles ; Title screen uses double Width Missiles.
	sta SIZEM

; Scrolling Terrain Values ==================================================
; The mountains are a constant component on the Title and Game screens.
; The motion is continuous.  There is never a time where this is considered 
; idle, or must be reset to start at the beginning.
; Display List LMS initialization for the mountains happens in the Display 
; List declaration. 

; NOT NEEDED, BECAUSE THESE ARE INITIALIZED BY THE DISK LOAD INTO PAGE 0

;	lda #LAND_MAX_PAUSE
;	sta zLandTimer            ; Number of jiffies to Pause.  When 0, run scroll.

;	lda #LAND_STEP_TIMER
;	sta zLandScrollTimer      ; How many frames to wait for each fine scroll.

;	lda #0
;	sta zLandHS               ; fine horizontal scroll value start.
;	sta zLandColor            ; index for repeat DLIs on the scrolling land  

;	sta zLandPhase            ; 0 == waiting  1 == scrolling.
;	sta zLandMotion           ; 0 == left/right !0 == right/left


	; Changing the Display List is potentially tricky.  If the update is
	; interrupted by the Vertical blank, then it could mess up the display
	; list address and crash the Atari.
	;
	; So, this problem is solved by giving responsibility for Display List
	; changes to a custom Vertical Blank Interrupt. The main code simply
	; writes a byte to a page 0 location monitored by the Vertical Blank
	; Interrupt and this directs the interrupt to change the current
	; display list.  Easy-peasy and never updated at the wrong time.

	lda #EVENT_SETUP_TITLE
	sta zCurrentEvent

	ldy #<MyImmediateVBI       ; Add the VBI to the system (Display List dictatorship)
	ldx #>MyImmediateVBI
	lda #6                     ; 6 = Immediate VBI
	jsr SETVBV                 ; Tell OS to set it

	ldy #<MyDeferredVBI        ; Add the VBI to the system (Lazy hippie timers, colors, sound.)
	ldx #>MyDeferredVBI
	lda #7                     ; 7 = Deferred VBI
	jsr SETVBV                 ; Tell OS to set it

	lda #0
;	sta FlaggedHiScore
;	sta InputStick             ; no input from joystick

;	jsr Pmg_IndexMarks ;diagnostics for screen problems

	lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NORMAL]
	sta SDMCTL

	lda #[FIFTH_PLAYER|GTIA_MODE_DEFAULT|$01] 
	sta GPRIOR

	rts                         ; And now ready to go back to main game loop . . . .


; ==========================================================================
; GAME SETUP TITLE
; ==========================================================================
; Do what needs to be done to setup all the moving parts to 
; run the title screen.
; The setup for Transition to Title will turned on the Title Display.
; Stage 1: Start sound effects for rezz in Title graphics.
; Stage 2: Go To Start event
; --------------------------------------------------------------------------

GameSetupTitle

	; ===== Basics =====

	lda #$00
	sta zSTATS_TEXT_COLOR

	jsr Gfx_Clear_Stats


	; ===== The Big Logo =====

	lda #TITLE_LOGO_X_START
	sta zTitleHPos

	lda #0
	sta zTitleLogoPMFrame

	lda #TITLE_SPEED_PM
	sta zAnimateTitlePM

	lda #COLOR_ORANGE1           ; Reset to first color.
	sta ZTitleLogoBaseColor      ; Resave the new update
	sta ZTitleLogoColor          ; Save it for the DLI use
;	sta COLOR3                   ; Make sure it starts in the OS shadow and 
;	sta COLPF3                   ; the hardware registers.


	; ===== The scrolling credits =====

; GFX_SCROLL_CREDIT1  ;   +0, HSCROL 12   ; +30, HSCROL 12
; GFX_SCROLL_CREDIT2  ;  +30, HSCROL 12   ;   +0, HSCROL 12

; DL_LMS_SCROLL_CREDIT1  +0 to +30   - inc LMS, dec HS ("Move" data left)
; DL_LMS_SCROLL_CREDIT2  +30 to +0     dec LMS, inc HS ("move" data right)

	lda #<GFX_SCROLL_CREDIT1      ; Init the starting LMS positions.
	sta DL_LMS_SCROLL_CREDIT1

	lda #<[GFX_SCROLL_CREDIT2+30]
	sta DL_LMS_SCROLL_CREDIT2

	lda #12                       ; Set fine scroll starting point
	sta zCredit1HS
	sta zCredit2HS

	lda #CREDITS_MAX_PAUSE        ; Set the wait timer.
	sta zCreditsTimer 

	lda #CREDITS_STEP_TIMER       ; How many frames to wait for each fine scroll.
	sta zCreditsScrollTimer

	lda #$00
	sta zCreditsPhase             ; 0 == waiting    (1  == scrolling)
	sta zCreditsMotion            ; 0 == left/right (1 == right/left)


	; ===== The scrolling documentation =====

	lda #<GFX_SCROLL_DOCS         ; Load low bytes of starting position.
	sta DL_LMS_SCROLL_DOCS
	
	lda #>GFX_SCROLL_DOCS         ; Load high bytes of starting position.
	sta DL_LMS_SCROLL_DOCS+1

	lda #15                    ;   Reset the fine scroll starting point
	sta zDocsHS                ;

	lda #DOCS_STEP_TIMER       ; Reset timer.  And start scrolling.
	sta zDocsScrollTimer


	; ===== The giant mothership  =====

	lda #0                    ;  0 = standing still  !0 = Moving up.
	sta zBigMothershipPhase

	lda #BIG_MOTHERSHIP_START ; Starting position of the big mothership
	sta zBIG_MOTHERSHIP_Y

	lda #BIG_MOTHERSHIP_SPEED ; How many frames to wait per mothership move.
	sta zBigMothershipSpeed

	lda #112
	sta SHPOSP2
	lda #128
	sta SHPOSP3

	lda #$46
	sta PCOLOR2
	sta PCOLOR3

	lda #PM_SIZE_DOUBLE
	sta SIZEP2
	sta SIZEP3

	jsr Pmg_Draw_Big_Mothership


; Scrolling Terrain Values ==================================================
; F Y I -- Note the scrolling land is setup once by declaring the Display 
; List and then maintained forever by the VBI.


; ===== Setup Player postions.  Etc. =====

	lda #$FF
	sta zPLAYER_ONE_ON ; (0) not playing. (FF)=Title/Idle  (1) playing.
	sta zPLAYER_TWO_ON ; (0) not playing. (FF)=Title/Idle  (1) playing.

	ldy #PLAYER_IDLE_Y
	sty zPLAYER_ONE_NEW_Y
	sty zPLAYER_TWO_NEW_Y
	sty zPLAYER_ONE_Y
	sty zPLAYER_TWO_Y

	lda #$04
	sta zPLAYER_ONE_COLOR
	sta zPLAYER_TWO_COLOR

	lda #[PLAYER_MIN_X+40]
	sta zPLAYER_ONE_X

	lda #[PLAYER_MAX_X-40]
	sta zPLAYER_TWO_X

	lda #1
	sta zPLAYER_ONE_REDRAW
	sta zPLAYER_TWO_REDRAW


	; ===== Start the Title running on the next frame =====

	lda #EVENT_TITLE
	sta zCurrentEvent
	lda #0 
	sta zEventStage

;	jsr Pmg_IndexMarks ;diagnostics for screen problems

	rts



; ==========================================================================
; GAME TITLE
; ==========================================================================
; Event Process TITLE SCREEN
;
; The VBI handles many "moving" things.  Of course, on the Atari, a
; "moving" thing may not really be moving at all.  It could be just
; DMA pointers that are changing the things on screen...
;
; The VBI switches between the several grey-scale images used for the big 
; logo by changing the LMS adddress at one place in the display list.
; 
; The VBI sets the horizontal position for the missiles used for the 
; big logo's color overlay, but the main code updates the actual image.
; 
; The VBI handles all the scrolling objects -- the two-line author 
; credits, the scrolling documentation/long credits, and the scrolling 
; mountains at the bottom of the screen.

; The main code activity on the title screen:
; 1) Check the Title Logo animation timer
; 1)a) When the timer expires animate the Missiles for the color overlay.
; 2) Test for player pressing a button.
; 3) IF a button is pressed, then prep to transition to the Countdown.
; --------------------------------------------------------------------------

GameTitle

; ===== Load animation frames into Player/Missile memory

; Animate Missiles per current frame stage.   
; VBI reset the missile horizontal positions.
; The DLI applies them.

b_gt_TitleAnimation

	lda zAnimateTitlePM;
	bne b_gt_ExitTitleAnimation

	jsr Pmg_Animate_Title_Logo ; This will also reset the timer for animation.

b_gt_ExitTitleAnimation

; Note that the VBI handles everything about the fine scrolling lines for the 
; author credits, the documentation, and the scrolling land.


; ===== Player management for Title screen.   

	jsr PlayersSelectionInput ; Button transitions to selecting for game play.
	; ++ if either player pressed the button to play.  
	; 0 if both players are idle.
	beq b_gt_EndTitleScreen  ; 0 = No input.  Continue running Title.

	; Non-zero result means a player hit their button, so start the countdown to play...

	; ===== Start the Countdown running on the next frame =====

	lda #4                  ; Starting at 4 insures this is erased.
	sta zCOUNTDOWN_FLAG 
	lda #1
	sta zCOUNTDOWN_SECS     ; jiffy ticks, not secs.
	jsr Gfx_DrawCountdown   ; Update the countdown text.  (Blank)

	lda #EVENT_COUNTDOWN
	sta zCurrentEvent
	lda #0 
	sta zEventStage

b_gt_EndTitleScreen

;	jsr Pmg_IndexMarks ;diagnostics for screen problems

	rts


; ==========================================================================
; GAME COUNTDOWN
; ==========================================================================
; A player has pressed their button.  Final Commitment to begin playing 
; the game.
;
; The VBI continues to do the various activities needed for the title 
; screen.
;
; 0) Continue Title animations for logo.
; 1) A Player (one or two) is moving up.  
;    The other player is color cycling until button pressed.
;    And continue to test for the idle player's input.
; 2) Run the 3, 2, 1, countdown...
; 3) AFTER countdown, AND Player selection animation complete then 
;    move the mothership up the screen. 
; 3)a) While the mothership leaves the screen, dissolve the idle player. 
; --------------------------------------------------------------------------

GameCountdown 

; ===== Load animation frames into Player/Missile memory

; Animate Missiles per current frame stage.   
; VBI reset the missile horizontal positions.
; The DLI applies them.

b_gc_TitleAnimation

	lda zAnimateTitlePM;
	bne b_gc_ExitTitleAnimation

	jsr Pmg_Animate_Title_Logo ; This will also reset the timer for animation.

b_gc_ExitTitleAnimation


; ===== Run the countdown timer =====

b_gc_CountDown

	lda zCOUNTDOWN_FLAG      ; -1 means countdown is done.
	bmi b_gc_StartMothership ; So, setup Move Mothership, Erase Player

	dec zCOUNTDOWN_SECS      ; Countdown jiffies.
	bne b_gc_EndCountdown    ; Still counting.

	dec zCOUNTDOWN_FLAG      ; jiffy clock 0.  Go to next count. 
	bmi b_gc_StartMothership ; Went negative, Erase Player, and Move Mothership

	jsr Gfx_DrawCountdown    ; Update the countdown text.  (and reset jiffy clock)

b_gc_EndCountdown

	jmp b_gc_PlayerCheck     ; Skip over the mothership setup


b_gc_StartMothership         ; Countdown is done -1.  Signal Mothership flies away, dissolve player.

	lda zBigMothershipPhase  ; 1 is mothership already in motion.
	bne b_gc_MoveMothership  ; So, end here.
	inc zBigMothershipPhase  ; Start the mothership moving, VBI does the rest.


; ===== Pause for New Player Placement (if they press the button) =====

b_gc_PlayerCheck

	lda zBigMothershipPhase    ; 1 is mothership in motion.
	bne b_gc_EndPlayerCheck    ; So, skip this.

	jsr PlayersSelectionInput  ; Only called here during countdown.

	jsr MovePlayersUp          ; Move players (idle to in-play)  if necessary.

	jsr Pmg_CycleIdlePlayer    ; Strobe the color for whatever player is not playing

b_gc_EndPlayerCheck


; ===== Run Big Mothership Animation (VBI does redraw.) =====
; ===== Run the dissolve animation for the idle player. =====
; ===== Also, VBI will redraw/remove the unused Player. =====
; ===== Game starts when the Mothership reaches the Y limit ====

b_gc_MoveMothership

	lda zBigMothershipPhase    ; 0 is mothership not in motion.
	beq b_gc_End               ; So, end here.

	jsr MovePlayersUp          ; Move players (idle to in-play)  if necessary.

	jsr Pmg_SquashIdlePlayer   ; Smush the player not playing

	lda zBIG_MOTHERSHIP_Y      ; Mothership Y position...
	bpl b_gc_End               ; If Y is not negative, then nothing else going on. End.

; Here the Mothership has reached the negative  Y position.
; This means the Mothership has traveled up, off the screen.  
; Therefore, the Countdown is done. 
; Run game.

b_gc_EndMothership             ; Fall through here to run the game.


; ===== Start The Game Play =====

b_gc_StartGame

; Stuff Goes here to start the game. . . .

; init flashing stars.
; Init player motions.
; Switch states.
; Init mothership, scores, etc.

	lda #EVENT_SETUP_GAME   
	sta zCurrentEvent

b_gc_End

; Flashy color scroll on the Countdown text.

	dec zCountdownTimer
	bne b_mdv_WaitForCountdownScanline

	lda #$06
	sta zCountdownTimer 

	lda zCountdownColor
	clc
	adc #$04
	sta zCountdownColor

b_mdv_WaitForCountdownScanline
	ldy VCOUNT
	cpy #23
	bne b_mdv_WaitForCountdownScanline

	ldy #12
	lda zCountdownColor

b_mdv_LoopSetCountdownColor
	sta WSYNC ; 1
	sta COLPF3
	clc
	adc #$04

	dey 
	bne b_mdv_LoopSetCountdownColor


	jsr Pmg_IndexMarks ;diagnostics for screen problems



	rts



; ==========================================================================
; GAME SETUP MAIN
; ==========================================================================
; The visual bling should always be in a state to resume immediately 
; on the next frame.   The end of the countdown code reset any display 
; oriented values as needed.   
;
; Here, zero all the starting values for supporting GAME LOGIC.
; The only visual aspect is copying the score and statistics to 
; the screen.
; 
; The gun(s) are already in correct X and Y position due to title screen
; and countdown selection.   If the gun is in operation, then randomize 
; the direction.
; --------------------------------------------------------------------------

GameSetupMain

	ldy #5
	lda #0

b_gsm_Loop_ZeroPlayerScores
	sta zPLAYER_ONE_SCORE,y
	sta zPLAYER_TWO_SCORE,y
	dey
	bpl b_gsm_Loop_ZeroPlayerScores

	; Zero all of this stuff...
	sta zPLAYER_ONE_BUMP
	sta zPLAYER_TWO_BUMP
	sta zPLAYER_ONE_CRASH
	sta zPLAYER_TWO_CRASH
	sta zLASER_ONE_ON
	sta zLASER_TWO_ON
	
	sta SHPOSM3 ; Remove the animated colors from the title.
	sta SHPOSM2
	sta SHPOSM1
	sta SHPOSM0


	lda #$80                        ;  128 = 80 (BCD values)
	sta zSHIP_HITS
;	lda #0
;	sta zSHIP_HITS+1

	lda #1
	sta zSHOW_SCORE_FLAG
;;	jsr showscr
	jsr Gfx_ShowScreen
                                    ; should be 2
	lda #2                          ; initial ms speed
	sta zMOTHERSHIP_MOVE_SPEED
	lda #10                         ; should be 10
	sta zMOTHERSHIP_SPEEDUP_THRESH  ; speedup threshld
	sta zMOTHERSHIP_SPEEDUP_COUNTER ; speedup count

	lda RANDOM                      ; Random starting direction for Mothership
	and #$01
	sta zMOTHERSHIP_DIR             ; 0 == left to right. 1 == right to left.

	bne b_gsm_SetMothershipMax_X    ; 0 == left to right. 1 == right to left.
	lda #MOTHERSHIP_MIN_X           ; Left == Minimum
	bne b_gsm_SetMothership_X       ; Save X
	
b_gsm_SetMothershipMax_X
	lda #MOTHERSHIP_MAX_X           ; Right == Maximum

b_gsm_SetMothership_X               ; Start X coord.
	sta zMOTHERSHIP_NEW_X
	sta zMOTHERSHIP_X
	sta SHPOSP2

	ldx #0
;	stx zMOTHERSHIP_ROW
	stx zMOTHERSHIP_Y               ; Zero old P/M Y position
	jsr Pmg_SetMotherShip
;	lda TABLE_ROW_TO_Y,x            ; row 2 y table
;	sta zMOTHERSHIP_NEW_Y           ; New Y position.

	; Setting random direction for both players.
	; Not doing any comparison for the player on or off,
	; because whatever is set here doesn't cause anything 
	; to happen during the game . . .
	lda #PM_SIZE_NORMAL
	sta SIZEP2
	sta SIZEP3

	lda RANDOM                      ; Set random direction.
	and #$01
	sta zPLAYER_ONE_DIR              ; 0 == left to right. 1 == right to left.
	lda RANDOM                      ; Set random direction.
	and #$01
	sta zPLAYER_TWO_DIR             ; 0 == left to right. 1 == right to left.

	lda #2                          ; Reset the animation timer for players/left/right movement.
	sta zAnimatePlayers

	lda #EVENT_GAME                 ; Fire up the game screen.
	sta zCurrentEvent

	lda #$0C
	sta zSTATS_TEXT_COLOR

	; Temporarily setting colors to make things visible without DLI running.
;;	lda #$16
;;	sta COLOR0 ; COLPF0
;	lda #$0E
;	sta COLOR1 ; COLPF1
;	lda #$00
;	sta COLOR2 ; COLPF2
;;	lda #$7B
;;	sta COLOR3 ; COLPF3

;	jsr Pmg_IndexMarks ;diagnostics for screen problems

	rts



; ==========================================================================
; GAME MAIN
; ==========================================================================
; The VBI takes care of drawing everything at its NEW positions.
; The VBI captured the collision information between the lasers 
; and the mothership. 
; The OS VBI extracted controller info (the buttons).
; 
; The Main code here does the following....
; 0) If explosion is running...  nothing to do.  All logic for this
;    is running in the VBI.
; 
; 1) Run Player movement.
;    a) bounce if gun collides with bumper.
;    b) bounce if guns collide with each other.
;
; 2) Is Bang set (Player to Mothership collision)? (both players)
;    a) Set laser to remove it from screen
;    b) Add points to player
;    c) Explosion on, X, y == Current Mothership X, Y
;    d) Hit counter-- (or ++); update mothership speed.
;       i) If Any one Bang has occurred, subtract Mothership rows,  Move to position, set points. 
;
; 3) If laser is running, update Y =  Y - 4.
;    a) if Y reaches min Y, set laser to remove it from screen
;
; 4) Trigger pressed?
;    a) if gun is Off, skip shooting
;    b) if gun is crashed [alien is pushing], skip shooting
;    c) If lazer Y, in bottom half of screen, skip shooting
;       i) set lazer on, 
;       ii) Laser Y = gun new Y - 4, Laser X = gun new X
;       iii) If no bounce this turn, then negate direction/set bounce.
;
; 5) If the mothership is on last row, 
;    a) continue mothership motion
;    b) if current contact with player, then adjust player X
;    c) if new contact with player, 
;       i) force crash, force position. 
;       ii) set update image of player
;       iii) update other player if needed.
;
; 6) If mothership reaches limit MIN, or MAX on last row.
;    a) remove all guns and mothership,. (lasers/explosions not possible to be visible). 
;    b) Set flag to go to End Game.
; --------------------------------------------------------------------------

GameMain

;	jsr Pmg_IndexMarks ;diagnostics for screen problems

;	lda #$10
;	sta COLBK
;	sta WSYNC
	
	jsr GamePlayersMovement     ; 1
	
;	lda #$30
;	sta COLBK
;	sta WSYNC
	
;	jsr CheckNewExplosions      ; 2

;	lda #$50
;	sta COLBK
;	sta WSYNC
	
	jsr CheckLasersInProgress   ; 3
	
;	lda #$70
;	sta COLBK
;	sta WSYNC
	
	jsr CheckPlayersShooting    ; 4
	
;	lda #$90
;	sta COLBK
;	sta WSYNC
	
	jsr GameMothershipMovement  ; 5

;	lda #$b0
;	sta COLBK
;	sta WSYNC
	
;	jsr Supervise Last Row motion. ; 6

;	lda #$d0
;	sta COLBK
;	sta WSYNC
	
	rts



; ==========================================================================
; GAME LAST ROW
; ==========================================================================
;
; --------------------------------------------------------------------------

GameLastRow

	rts



; ==========================================================================
; GAME SETUP OVER
; ==========================================================================
;
; --------------------------------------------------------------------------

GameSetupOver

	rts



; ==========================================================================
; GAME OVER
; ==========================================================================
;
; --------------------------------------------------------------------------

GameOver

	rts


; ==========================================================================
; SUPPORT - PLAYERS SELECTION INPUT
; ==========================================================================
; Runs during Title screen and Countdown
; 
; Buttons transition to selecting players for game play.
;
; Check for input from idle players to begin the countdown before playing.
;
; If a Player(s) are already intending to play skip the player input.
;
; Returns:
; ++ if one or both players are ready to play. 
; 0 if both players are idle.
; --------------------------------------------------------------------------

PSI_Response .byte $00        ; Flag if Player Input requires later work

PlayersSelectionInput

	lda #0
	sta PSI_Response

	ldx #0
	jsr PlayerSelectionInput

	ldx #1
	jsr PlayerSelectionInput

b_psi_Exit
	lda PSI_Response           ; Player 1 and 2 are both Off/idle or one is playing. 

	rts


; ==========================================================================
; SUPPORT - PLAYER SELECTION INPUT
; ==========================================================================
; Check for input from idle players to begin the countdown before playing.
;
; If a Player is already intending to play skip the player input.
;
; X = The player to check/process...  0 or 1
;
; Returns:
; ++ PSI_RESPONSE if player is ready to play. 
; --------------------------------------------------------------------------

PlayerSelectionInput

	lda zPLAYER_ON,X           ; (0) not playing. (FF)=Title/Idle  (1) playing.
	bmi b_ppsi_TryPlayerIdle   ; Not playing yet, so test it.
	beq b_ppsi_Exit            ; 0 isn't supposed to be possible.
	inc PSI_Response           ; PLAYER_ON == 1, so playing.
	bne b_ppsi_Exit

b_ppsi_TryPlayerIdle           ; Player is idle.  ($FF  is idle)
	lda STRIG0,X               ; (Read) TRIG0 - Joystick trigger (0 is pressed. 1 is not pressed)
	bne b_ppsi_Exit            ; Not pressed.  Go to player 2
	; ldy #PLAYER_ONE_SHOOT
	; jsr PlaySound 
	lda #$1                    ; (1) playing.
	sta zPLAYER_ON,X           ; Signal to all that this player is playing.
	sta PSI_Response           ; +1 Signal that a player is in motion.

b_ppsi_Exit
	rts







; ==========================================================================
; SUPPORT - MOVE PLAYERS UP
; ==========================================================================
; Runs during Title screen and Countdown
; 
; If a Player select to begin game, then move the gun up.
; Given that this is an animation that takes several frames
; this needs to be able to run during the final moments of the 
; big Mothership flying up in case a player presses the button 
; very late during the countdown.
;
; This routine separates the movement from the input activity, so the 
; movement can continue when the polling for input has ceased.
;
; Player management for Title screen.   
;
; Process movement means:
; If current position does not equal current state, then move the Y position.
; The VBI will do the actual redraw.
;
; Returns:
; -- if either player is not yet in playing position.
; ++ if both players are ready to play. 
; 0 if both players are idle.
; --------------------------------------------------------------------------

MovePlayersUp

	lda #0
	sta PSI_Response           ; Flag no changes occurred

	ldx #0
	jsr MovePlayerUp

	ldx #1
	jsr MovePlayerUp

b_mpu_Exit
	lda PSI_Response           ; Player 1 and 2 are both Off/idle or one is playing. 

	rts


; ==========================================================================
; SUPPORT - MOVE PLAYER UP
; ==========================================================================
; Runs during Title screen and Countdown
; 
; If the Player selects to begin game, then move the gun up.
; Given that this is an animation that takes several frames
; this needs to be able to run during the final moments of the 
; big Mothership flying up in case the player presses the button 
; very late during the countdown.
;
; This routine separates the movement from the input activity, so the 
; movement can continue when the polling for input has ceased.
;
; Process movement means:
; If current position does not equal current state, then move the Y position.
; The VBI will do the actual redraw.
;
; X is the Player to check.  0 to 1
;
; Returns:
; -- if either player is not yet in playing position. (continue animation)
; ++ if both players are ready to play. 
; 0 if both players are idle.
; --------------------------------------------------------------------------

MovePlayerUp

	lda zPLAYER_ON,X           ; (0) not playing. (FF)=Title/Idle  (1) playing (moving)
	beq b_mmpu_Exit            ; Zero is not playing
	bmi b_mmpu_Exit            ; Negative is not really playing (yet)

	lda zPLAYER_Y,X            ; Here we know Player is Playing.  ($1 is playing)
	cmp #PLAYER_PLAY_Y         ; Is it at the Playing position?
	bne b_mmpu_MovePlayerUp    ; Not yet.  Move it up.

	lda PSI_Response           ; Is other player not ready? (Ready is lower priority than not ready).
	bmi b_mpu_Exit             ; Already negative means a player is in motion.  Skip the rest.

	lda #1
	sta PSI_Response           ; Yes. Ready to Play.
	bne b_mmpu_Exit            ; Done here.

b_mmpu_MovePlayerUp
	lda #$FF
	sta PSI_Response           ; -1 Signal that this is still in motion.
	dec zPLAYER_NEW_Y,X        ; Tell VBI to move up one scan line.

b_mmpu_Exit
	rts





; ==========================================================================
; SUPPORT - MOVE GAME PLAYERS GUNS
; ==========================================================================
; Runs during main Game
; 
; 1) Run Player movement.
;    a) bounce if gun collides with bumper.
;    b) bounce if guns collide with each other.
;
; Move the players' guns during the game.
; This is all about the calculations to change position.
; The actual redraw takes place during the VBI.
;
; Talking (or random babbling) out loud to myself....  Pay no attention
; to the mubling man walking randomly on the sidewalk.  Do not give 
; him matches.  Do not give him money.
;
; This is the gruesome logic part.  The main routine is evaluating where
; the guns are now to decide where they should be on the next frame. 
; The current location is where the VBI drew everything and is where it 
; will appear on the current frame being drawn for the human player.
;
; Collision comparison is all done on the basis of horizontal position, 
; not hardware collision detection.  Guns in play may never overlap each 
; other or the bumpers, therefore no opportiunity for hardware collision.
;
; (Hardware collision detection is used for missles impacting the 
; mothership, but this is a different discussion.  Go away and look for 
; that routine and leave me alone now.)
;
; When both guns are traveling in opposite directions and meet perfectly 
; with no overlap, then both get a direction change at the same time.  
; (One of the simplest situations).
;
; When approaching the bumpers the player on that side of the screen 
; closest to the bumper is the one that owns pixel space concerning 
; gun to bumper and gun to gun collision at the bumber.  The general rule
; is that when two players are active, Gun 1 owns free pixel space when 
; moving left toward the left bumper, and Gun 2 owns free pixel space when 
; moving right toward the right bumper.
;
; Extending this, if gun 1 and gun 2 are exactly next to each other AND they 
; are traveling in the same direction, then there is not an exception to 
; bounce either gun.  UNLESS, the guns have reached the bumper at the edge 
; of the screen, then a bounce occurs.  In this case, both guns must 
; bounce to the opposite direction.  (Logically, it must be impossible for 
; both guns to reach the maximum position adjacent to a bumper while 
; having opposite flags set for direction of travel.)
;
; The hard part here is to maintain fairness in the border conditions 
; between gun 1 and gun 2.  At some edge conditions where the guns are 
; right next to each other the directional values create exceptions.
; In the end perfect fairness is impossible.   Two guns cannot cross into
; the same pixel space.   Therefore, the exception here is that when Gun 1
; owns the free pixel and can move there to trigger direction change, 
; then Gun 2 can only triggers direction change from its current 
; position without moving into the empty pixel space.
;
; Reminder: Gun 1 owns pixel space on the left side of the screen, Gun 2 
; owns pixel space on the right side of the screen.   (Easy to tell...
; ldx X_POSITION ; bmi right side of screen. coordinate 128 is the middle 
; of the screen -- almost -- but, this is good enough for military work.)
;
; The situation occurs when the guns are traveling in opposite directions, 
; and will meet each other with only one blank pixel between them.  
; They cannot both occupy that blank space.
; 
; A bounce at the bumper would look like this: (B)umper (<)Gun (<)Gun
; B <<   <- Next frame will move to the bumper
; B>>    <- When new position is exactly next to bumper, then bounce both.
; B >>   <- Both traveling with no gap.
; 
; More complicated: One space/pixel between Guns on the left of the screen:
; B < <   <- Next frame Gun 1 will move next to bumper.
; B> <    <- Gun 1 on bumper is flagged to bounce in opposite direction
; B X     <- Here it is impossible for both guns to move to the same space
; B <>    <- Thus, Gun 1 moves, Gun 2 does not, both register the bounce.
; B>  >   <- Note that this creates an extra pixel gap between them
;
; What happens at the right bumper, because Gun 1 owns space....
; > > B   <- Next frame Gun 2 will move next to the bumper.
;  > <B   <- Gun 2 flagged to bounce in opposite direction
;   X B   <- Here it is impossible for both guns to move to the same space
;  <> B   <- Thus, Gun 2 moves, Gun 1 does not, both register bounce.
; <  <B   <- Note this creates an extra pixel gap between them.
;
; --------------------------------------------------------------------------

GamePlayersMovement

	lda zAnimatePlayers   ; Check timer to delay movment. (VBI updates)
	bne b_gpm_Exit        ; Timer not 0, so still running.

	lda #2                ; Player movement timer expired.  
	sta zAnimatePlayers   ; Reset it.
	
	; First, run through the easy choices first that don't involve 
	; interaction between the two players.
	
	ldx #0
	stx zPLAYER_ONE_BUMP ; Clear the bump direction flags
	stx zPLAYER_TWO_BUMP 

	jsr GameMovePlayerLeft    ; For Player 1 (X == 0 )
	jsr GameMovePlayerRight

	ldx #1
	jsr GameMovePlayerRight   ; For Player 2 (X == 1 ) 
	jsr GameMovePlayerLeft

	; At this point the players have moved left or right, and 
	; rebounded from the bumpers if applicable.   No 
	; consideration of player collisions has occurred yet.


	; If there is only one player playing, whether player 1 or 2, 
	; then the player's gun movement has been solved, and no more
	; logic is needed.

	lda zPLAYER_ONE_ON ; Check if both players are playing.
	and zPLAYER_TWO_ON
	beq b_gpm_Exit     ; Only one player.  (0&1 = 0, 1&0 = 0)  Finito.

	; Further Work on both players moving...  possible collision.  

; Side note...  In theory if the players collide on the same frame that
; one of the players shoots, then that player will reverse direction,
; and so will both players be moving in the same direction but they 
; overlap?   I don't think this should actually happen.   Here the 
; game resolves the basic collision due to movement.  After this they 
; will not overlap and they will be going in opposite directions.   
; The shooting has not yet been evaluated.  This collision code will 
; flag that directions changed, so that if shooting also begins on 
; this frame, the direction will not reverse.  This should prevent the
; shooting player from reversing directions and overlapping the other
; player moving in the same direction.

	lda zPLAYER_ONE_DIR ; Are both moving in the same direction?
	cmp zPLAYER_TWO_DIR
	beq b_gpm_Exit      ; Yes, so, no collision.
	
	; If gun 1 is moving left and/or gun 2 is moving right, 
	; then no possible collision. 
	
	lda zPLAYER_ONE_DIR ; 1 == right to left.
	bne b_gpm_Exit  ; Yes, so, no collision.

;	lda zPLAYER_TWO_DIR ; 0 == left to right.
;	beq b_gpm_Exit  ; Yes, so, no collision.

	; Here we know two players are running, and
	; they are traveling toward each other.
	; Inevitably the two must meet.
	
	sec                   ; Doing some subtraction. Set carry.
	lda zPLAYER_TWO_NEW_X ; subtract one 
	sbc zPLAYER_ONE_NEW_X ; from two...
	cmp #PLAYER_X_SIZE
	bcs b_gpm_Exit        ; greater than or equal SIZE? No collision.

	; If on the left side of screen adjust gun 2 to 1.
	
	lda zPLAYER_ONE_NEW_X
	bmi b_gpm_AdjustOnRightSide ; right side...

	clc
	adc #PLAYER_X_SIZE
	sta zPLAYER_TWO_NEW_X
	bpl b_gpm_BumpTheGuns

; On the right side of screen adjust gun 1 to 2.

b_gpm_AdjustOnRightSide

	lda zPLAYER_TWO_NEW_X
	sec
	sbc #PLAYER_X_SIZE
	sta zPLAYER_ONE_NEW_X

b_gpm_BumpTheGuns

	lda #0
	sta zPLAYER_TWO_DIR ; 0 == left to right.
	lda #1
	sta zPLAYER_ONE_DIR ; 1 == right to left.
	
	sta zPLAYER_ONE_BUMP
	sta zPLAYER_TWO_BUMP

b_gpm_Exit

	rts





; ==========================================================================
; SUPPORT - CHECK NEW EXPLOSIONS
; ==========================================================================
; Runs during main Game
; 
; For Each player check if the Laser hit the mothership.
;
; 2) Is Bang set (Player to Mothership collision)? (both players)
;    a) Set laser to remove it from screen
;    b) Add points to player
;    c) Explosion on, X, y == Current Mothership X, Y
;
; If any bang occurred, then 
; - adjust new mothership position 
; - update hit counter/mothership speed
;
; --------------------------------------------------------------------------

CheckNewExplosions

	ldx #0
	jsr CheckNewExplosion

	ldx #1
	jsr CheckNewExplosion

	rts




; ==========================================================================
; SUPPORT - CHECK LASERS IN PROGRESS
; ==========================================================================
; Runs during main Game
; 
; 3) If laser is running, update Y =  Y - 4.
;    a) if Y reaches min Y, set laser to remove it from screen
;
; --------------------------------------------------------------------------

CheckLasersInProgress

	ldx #0
	jsr CheckLaserInProgress

	ldx #1
	jsr CheckLaserInProgress

	rts





; ==========================================================================
; SUPPORT - CHECK PLAYERS SHOOTING
; ==========================================================================
; Runs during main Game
; 
; 4) Trigger pressed?
;    a) if gun is Off, skip shooting
;    b) if gun is crashed [alien is pushing], skip shooting
;    c) If lazer Y, in bottom half of screen, skip shooting
;       i) set lazer on, 
;       ii) Laser Y = gun new Y - 4, Laser X = gun new X + 4
;       iii) If no bounce this turn, then negate direction/set bounce.
;
; --------------------------------------------------------------------------

CheckPlayersShooting

	ldx #0
	jsr CheckPlayerShooting

	ldx #1
	jsr CheckPlayerShooting

	rts





; ==========================================================================
; SUPPORT - MOVE GAME MOTHERSHIP
; ==========================================================================
; Runs during main Game
; 
; Moves the mothership.   
; The actual redraw takes place in the VBI.
; --------------------------------------------------------------------------

GameMothershipMovement

	lda zMOTHERSHIP_Y
	cmp zMOTHERSHIP_NEW_Y  ; Is Y the same as NEW_Y?
	bne b_gmm_skip_MS_Move ; No.  Skip horizontal movement.

	ldy zMOTHERSHIP_X        ; Get current X

	lda zMOTHERSHIP_DIR      ; Test direction.
	bne b_gmm_Mothership_R2L ; 1 = Right to Left

	iny                      ; Do left to right.
	sty zMOTHERSHIP_NEW_X
	cpy #MOTHERSHIP_MAX_X    ; Reached max means time to inc Y and reverse direction.
	beq b_gmm_MS_ReverseDirection
	bne b_gmm_skip_MS_Move

b_gmm_Mothership_R2L
	dey                      ; Do right to left.
	sty zMOTHERSHIP_NEW_X
	cpy #MOTHERSHIP_MIN_X    ; Reached max means time to inc Y and reverse direction.
	beq b_gmm_MS_ReverseDirection
	bne b_gmm_skip_MS_Move

b_gmm_MS_ReverseDirection
	lda zMOTHERSHIP_DIR      ; Toggle X direction.
	eor #$1
	sta zMOTHERSHIP_DIR

	ldx zMOTHERSHIP_ROW      ; Get current row.
	cpx #22                  ; If on last row, then it has
	beq b_gmm_skip_MS_Move   ; reached the end of incrementing rows.

	inx                      ; Next row.
	jsr Pmg_SetMotherShip    ; Given Mothership row (X), update the mother ship specs and save the row.

b_gmm_skip_MS_Move

	rts








; ==========================================================================
; SUPPORT - MOVE PLAYER LEFT                                      X
; ==========================================================================
; Runs during main Game
; 
; Decide to move the players' guns left.
; If Player 1 is on, always move.
; If player 1 is off, then move Player 2. (Logical deducation -- the code
; could not have arrive here if there is no active player).
; 
; The player manipulated is based on value of X register.
;
; X = 0 = Player 1 gun
; X = 1 - Player 2 gun
; --------------------------------------------------------------------------

GameMovePlayerLeft

	lda zPLAYER_ON,X        ; Is this player even playing?
	beq b_gmpl_Exit         ; Nope.  Done here.

	lda zPLAYER_DIR,X       ; Is this player going left?  0 == left to right. 1 == right to left.
	beq b_gmpl_Exit         ; 0 == Nope.  Done here.

	; The Simple move left toward bumper....
b_gmpl_CallMoveLeft
	jsr GameMovePlayerLeftToBumper

b_gmpl_Exit
	rts





; ==========================================================================
; SUPPORT - MOVE PLAYER LEFT TO BUMPER                             X
; ==========================================================================
; Runs during main Game
; 
; Move the players' guns left toward the bumper.
; If the gun reaches the minimum position, toggle direction.
; 
; The player manipulated is based on value of X register.
; This is always used for Gun 1.   
; This is used for Gun 2 when Gun 1 is not present.
; It is up to the caller to set X accordingly and know if it is appropriate
; to call this routine for the player.
; 
; X = 0 = Player 1 gun
; X = 1 - Player 2 gun
; --------------------------------------------------------------------------

GameMovePlayerLeftToBumper

	lda zPLAYER_BUMP,X ; Has there already been a  direction change.
	bne b_gmpltb_Exit  ; Yes, do not test this bounce.

	ldy zPLAYER_X,X     ; Subtract one from player position.
	dey

	sty zPLAYER_NEW_X,X ; Save new position.
	cpy #PLAYER_MIN_X   ; Has it reached the mininum?
	bne b_gmpltb_Exit   ; No.  Exit now.

	lda #0              ; Yes.  Set direction left to right.
	sta zPLAYER_DIR,X   ; Bounce.

	inc zPLAYER_BUMP,X ; Remember there was a direction change.  Maybe not needed.

b_gmpltb_Exit
	rts




; ==========================================================================
; SUPPORT - MOVE PLAYER RIGHT                                      X
; ==========================================================================
; Runs during main Game
; 
; Decide to move the players' guns right.
; If Player 2 is on, always move.
; If player 2 is off, then move Player 1. (Logical deducation -- the code
; could not have arrive here if there is no active player).
; 
; The player manipulated is based on value of X register.
;
; X = 0 = Player 1 gun
; X = 1 - Player 2 gun
; --------------------------------------------------------------------------

GameMovePlayerRight

	lda zPLAYER_ON,X         ; Is this player even playing?
	beq b_gmpr_Exit          ; Nope.  Done here.

	lda zPLAYER_DIR,X       ; Is this player going right?
	bne b_gmpr_Exit         ; 1 == Nope.  Done here.

	; The Simple move right toward bumper....
b_gmpr_CallMoveRight
	jsr GameMovePlayerRightToBumper

b_gmpr_Exit
	rts





; ==========================================================================
; SUPPORT - MOVE PLAYER RIGHT TO BUMPER                             X
; ==========================================================================
; Runs during main Game
; 
; Move the players' guns right toward the bumper.
; If the gun reaches the maximum position, toggle direction.
; 
; The player manipulated is based on value of X register.
; This is always used for Gun 2.   
; This is used for Gun 1 when Gun 2 is not present.
; It is up to the caller to set X accordingly and know if it is appropriate
; to call this routine for the player.
; 
; X = 0 = Player 1 gun
; X = 1 - Player 2 gun
; --------------------------------------------------------------------------

GameMovePlayerRightToBumper

	lda zPLAYER_BUMP,X ; Has there already been a  direction change.
	bne b_gmprtb_Exit  ; Yes, do not test this bounce.

	ldy zPLAYER_X,X    ; Add one to player position.
	iny
	
	sty zPLAYER_NEW_X,X ; Save new position.
	cpy #PLAYER_MAX_X  ; Has it reached the maximum?
	bne b_gmprtb_Exit  ; No.  Exit now.
	
	lda #1             ; Yes.  Set direction right to left.
	sta zPLAYER_DIR,X  ; Bounce.

	inc zPLAYER_BUMP,X ; Remember there was a direction change.

b_gmprtb_Exit
	rts





; ==========================================================================
; SUPPORT - CHECK NEW EXPLOSION
; ==========================================================================
; Runs during main Game
; 
; 2) Is Bang set (Player to Mothership collision)? (both players)
;    a) Set laser to remove it from screen
;    b) Add points to player
;    c) Explosion on, X, y == Current Mothership X, Y
;
; X == The Player's laser to work on.
;
; --------------------------------------------------------------------------

CheckNewExplosion

	lda zLASER_ON,X   ; Is laser on?
	beq b_cne_Exit    ; No. Nothing to do.

	lda zLASER_BANG,X ; Did Laser hit Mothership?
	beq b_cne_Exit    ; No. Nothing to do.

	lda #0
	sta zLASER_NEW_Y  ; Flag this laser to get erased.

	lda #1            ; Flag that this player shot the mothership.
	sta zPLAYER_SHOT_THE_SHERIFF,X

	lda zMOTHERSHIP_X
	sta zEXPLOSION_NEW_X
	lda zMOTHERSHIP_Y
	sta zEXPLOSION_NEW_Y

	lda #15 
	sta zEXPLOSION_COUNT ; jiffy count for explosion player

; If any bang occurred, then 
; - adjust new mothership position 
; - update hit counter/mothership speed

b_cne_Exit
	rts






; ==========================================================================
; SUPPORT - CHECK LASER IN PROGRESS
; ==========================================================================
; Runs during main Game
; 
; 3) If laser is running, update Y =  Y - 4.
;    a) if Y reaches min Y, set laser to remove it from screen
;
; X == The Player's laser to work on.
;
; VBI will actually erase and turn off the laser.
; --------------------------------------------------------------------------

CheckLaserInProgress

	lda zLASER_ON,X     ; Is laser on?
	beq b_clip_Exit     ; No. Nothing to do.

	lda zLASER_Y,X  
	cmp #LASER_END_Y    ; Is Laser at Y Limit?
	bne b_clip_DoMove   ; No.  

	; Stop Laser Sound here.   If the other laser is not running

	lda #0              ; Zero New_Y is signal to remove from screen.
	beq b_clip_UpdateY

b_clip_DoMove
	sec                 ; Subtract 4 from laser Y
	sbc #4
	
b_clip_UpdateY
	sta zLASER_NEW_Y,X  ; New Y is set.

b_clip_Exit
	rts


; ==========================================================================
; SUPPORT - CHECK PLAYER SHOOTING
; ==========================================================================
; Runs during main Game
; 
; 4) Trigger pressed?
;    a) if gun is Off, skip shooting
;    b) if gun is crashed [alien is pushing], skip shooting
;    c) If lazer Y, in bottom half of screen, skip shooting
;       i) set lazer on, 
;       ii) Laser Y = gun new Y - 4, Laser X = gun new X
;       iii) If no bounce this turn, then negate direction/set bounce.
;
; Maybe add code to insure player releases the button before 
; attempting to shoot again.... ?????
;
; --------------------------------------------------------------------------

CheckPlayerShooting

	lda STRIG0,X            ; (Read) TRIG0 - Joystick trigger (0 is pressed. 1 is not pressed)
	bne b_cps_Exit          ; Not pressed.

	lda zPLAYER_ON,X        ; Is this player even playing?
	beq b_cps_Exit          ; Nope.  Done here.

	lda zPLAYER_CRASH,X     ; Is the gun crashed by alien?
	bne b_cps_Exit          ; Yes.  Done here.

	lda zLASER_ON,X         ; Is Laser on?
	beq b_cps_StartShot     ; No.  Ok to shoot.

	lda zLASER_NEW_Y,X      ; Is Laser still in bottom half of screen?
	bmi b_cps_Exit          ; Yes.  Done here.

b_cps_StartShot             ; Yippie Ki Yay Bang Bang Shoot Shoot
	lda #LASER_START
	sta zLASER_NEW_Y,X      ; New Y is set.

	lda zPLAYER_NEW_X,X     ; Copy gun X position
	sta zLASER_X,X          ; to the laser position.

	inc zLASER_ON,X         ; Turn laser on for the VBI to draw.

; start sound effects for shooting.

	; Decide whether or not the gun has to change directions.

	lda zPLAYER_BUMP,X      ; Has this frame already done a direction change?
	bne b_cps_Exit          ; Yes.  Do not switch directions again.

	inc zPLAYER_BUMP,X      ; Flag it has bumped. (probably not needed).
	lda zPLAYER_DIR,X       ; Flip direction
	beq b_cps_Dir1          ; Go do the Flip 0 to 1
	
	lda #0                  ; 0 == left to right. 
	sta zPLAYER_DIR,X       ; Flip 1 to 0
	beq b_cps_Exit          ; Done

b_cps_Dir1
	inc zPLAYER_DIR,X       ; Flip 0 to 1.  1 == right to left.


b_cps_Exit
	rts

