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
; considerations for the Title screen, the Main Game, and the 
; Game Over.
;
; Given the current program state, the Immediate VBI sets the 
; Disply List and Display List Interrupt vectors.  The main line 
; game loop calls the associated state function 
;
; There are 2 kinds of displays to run.  The Title and the Game.
; Other activities occur on one of these displays.  The count down 
; and giant mothership animation occur on the Title screen.  The 
; Game Over display occurs using the Game screen.  
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


; ==========================================================================\
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
	sta PCOLOR0,x 
	sta SHPOSP0,x
	dex
	bpl b_gi_LoopFillZero

	sta COLOR4 ; COLBK  - Playfield Background color (Border for modes 2, 3, and F) 

	lda #COLOR_WHITE|$0C ; Light white
	sta COLOR1           ; COLPF1 - Playfield 1 color (mode 2 text)

	lda #0
	sta zThisDLI         ; Init the DLI index.

	; Set up the DLI.   This should be safe here without knowing what the screen is 
	; doing, because the default OS display does not have DLI options on any 
	; mode instructions, AND a custom screen will not be started until the bottom of the 
	; frame AND due to the frame sync of the main loop we know that this code is 
	; executing very close to the top of the screen.

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
; This is a cconstant component on the Title and Game screens.
; The motion must be continuous, uninterrupted.  So, this is 
; iniatialized only once at startup, and there is never a time 
; where this is considered idle, or must be reset to start 
; at the beginning.

	lda #<GFX_MOUNTAINS1
	sta DL_LMS_SCROLL_LAND1

	lda #<GFX_MOUNTAINS2
	sta DL_LMS_SCROLL_LAND2

	lda #<GFX_MOUNTAINS3
	sta DL_LMS_SCROLL_LAND3

	lda #<GFX_MOUNTAINS4
	sta DL_LMS_SCROLL_LAND4

	lda #0
	sta zLandColor
	sta zLandHS

	lda #LAND_MAX_PAUSE
	sta zLandTimer

	lda #LAND_STEP_TIMER
	sta zLandScrollTimer

	lda #0
	sta zLandPhase
	sta zLandMotion


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

	jsr Pmg_IndexMarks ;diagnostics for screen problems


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
; Note the scrolling land is setup once in the Init section and 
; maintained forever by the VBI.


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
; author credits, the dcoumentation, and the scroling land.


; ===== Player management for Title screen.   

	jsr PlayerSelectionInput ; Button transitions to selecting for game play.
	; ++ if either player pressed the button to play.  
	; 0 if both players are idle.
	beq b_gt_EndTitleScreen  ; 0 = No input.

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

	jsr Pmg_IndexMarks ;diagnostics for screen problems



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

	jsr PlayerSelectionInput   ; Only called here during countdown.

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

	sta zPLAYER_ONE_BUMP
	sta zPLAYER_TWO_BUMP

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
	sta zPLAYER_ONE_DIR
	lda RANDOM                      ; Set random direction.
	and #$01
	sta zPLAYER_TWO_DIR

	lda #EVENT_GAME                 ; Fire up the game screen.
	sta zCurrentEvent

	; Temporarily setting colors to make things visible without DLI running.
;	lda #$16
;	sta COLOR0 ; COLPF0
	lda #$0E
	sta COLOR1 ; COLPF1
	lda #$00
	sta COLOR2 ; COLPF2
;	lda #$7B
;	sta COLOR3 ; COLPF3

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
; 1) If collision occurred between P0 (P1 laser) and P3 (mothership):
;    a) switch the set the states of the mothership and 
;       the explosion (p3) players, remove laser 1 (p0), and flag 
;       Player 1 for scoring.
; 2) If collision occurred between P1 (P2 laser) and P3 (mothership):
;    a) switch the set the states of the mothership and 
;       the explosion (p3) players, remove laser 2 (p1), and flag 
;       Player 2 for scoring.
; 3) If explosion (p3) on, test timer.  flag to remove if timer runs out
; 4) If the J1 button is pressed and the 
;    P0 laser start is possible (laser is off, or laser Y is less 
;    than screen center) 
;    then start the P0 laser state and toggle the Player 1 gun direction. 
; 4) B) if laser (p0) is on, then move Y-4
; 5) If the J2 button is pressed and the 
;    P1 laser start is possible (laser is off, or laser Y is less 
;    than screen center) 
;    then start the P1 laser state and toggle the Player 2 gun direction. 
; 4) B) if laser (p1) is on, then move Y-4
; Given player state, move the gun in its direction, rebound from 
; the bumpers or the other player. 
; If the mothership is on last row, continue mothership motion and drag 
; along the guns when they are in contact.
; At completion of last row, erase all players, trigger end game.
; --------------------------------------------------------------------------

GameMain

;	jsr Pmg_IndexMarks ;diagnostics for screen problems

	; Quick and dirty demo.
	
	jsr GameMothershipMovement


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
; Button transitions to selecting player for game play.
;
; Check for input from idle players to begin the countdown before playing.
;
; If a Player is already intending to play skip the player input.
;
; Returns:
; ++ if both a player is ready to play. 
; 0 if both players are idle.
; --------------------------------------------------------------------------

PSI_Response .byte $00

PlayerSelectionInput

	lda #0
	sta PSI_Response

	lda zPLAYER_ONE_ON         ; (0) not playing. (FF)=Title/Idle  (1) playing.
	bmi b_psi_TryPlayer1Idle   ; Not playing yet, so test it.
	beq b_psi_TryPlayer2       ; 0 isn't supposed to be possible.
	inc PSI_Response           ; PLAYER_ON_ON == 1, so playing.
	bne b_psi_TryPlayer2

b_psi_TryPlayer1Idle           ; Player 1 is idle.  ($FF  is idle)
	lda STRIG0                 ; (Read) TRIG0 - Joystick 0 trigger (0 is pressed. 1 is not pressed)
	bne b_psi_TryPlayer2       ; Not pressed.  Go to player 2
	; ldy #PLAYER_ONE_SHOOT
	; jsr PlaySound 
	lda #$1                    ; (1) playing.
	sta zPLAYER_ONE_ON
	sta PSI_Response           ; +1 Signal that this is in motion.

b_psi_TryPlayer2
	lda zPLAYER_TWO_ON         ; (0) not playing. (FF)=Title/Idle  (1) playing.
	bmi b_psi_TryPlayer2Idle   ; $FF is idle.
	beq b_psi_Exit             ; 1 means already playing. 0 isn't supposed to be possible.
	inc PSI_Response           ; PLAYER_ON_ON == 1, so playing.
	bne b_psi_Exit

b_psi_TryPlayer2Idle           ; Player 2 is idle.  ($FF  is idle)
	lda STRIG1                 ; (Read) TRIG1 - Joystick 1 trigger (0 is pressed. 1 is not pressed)
	bne b_psi_Exit             ; Not pressed.  Done.
	; ldy #PLAYER_TWO_SHOOT
	; jsr PlaySound 
	lda #$1                    ; (1) playing.
	sta zPLAYER_TWO_ON
	sta PSI_Response

b_psi_Exit
	lda PSI_Response           ; Player 1 and 2 are both Off/idle or one is playing. 

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

	lda zPLAYER_ONE_ON         ; (0) not playing. (FF)=Title/Idle  (1) playing (moving)
	beq b_mpu_TryPlayer2       ; Zero is not playing
	bmi b_mpu_TryPlayer2       ; Negative is not really playing (yet)

	lda zPLAYER_ONE_Y          ; Here we know Player 1 is Playing.  ($1 is playing)
	cmp #PLAYER_PLAY_Y         ; Is it at the Playing position?
	bne b_mpu_MovePlayer1Up    ; No.  Move it up.
	lda #1
	sta PSI_Response           ; Yes. Ready to Play.
	bne b_mpu_TryPlayer2       ; Done here.

b_mpu_MovePlayer1Up
	lda #$FF
	sta PSI_Response           ; -1 Signal that this is still in motion.
	dec zPLAYER_ONE_NEW_Y      ; Tell VBI to move up one scan line.

b_mpu_TryPlayer2
	lda zPLAYER_TWO_ON         ; (0) not playing. (FF)=Title/Idle  (1) playing.
	beq b_mpu_Exit             ; Zero should not really happen, but my OCD says this must be handled.
	bmi b_mpu_Exit             ; $FF is idle.

	lda zPLAYER_TWO_Y          ; Here we know Player 1 is Playing.  ($1 is playing)
	cmp #PLAYER_PLAY_Y         ; Is it at the Playing position?
	bne b_mpu_MovePlayer2Up    ; No.  Move it up.

	lda PSI_Response           ; Yes. (Ready is lower priority than player 1 not ready).
	bmi b_mpu_Exit             ; Already negative means Player 1 is in motion.
	lda #1
	sta PSI_Response           ; Yes. Player 2 idle.  So Player 1, Ready to Play.
	bne b_mpu_Exit             ; Done here.

b_mpu_MovePlayer2Up
	dec zPLAYER_TWO_NEW_Y      ; Tell VBI to move up one scan line.
	lda #$FF                   ; Signal this is in motion.
	sta PSI_Response

b_mpu_Exit
	lda PSI_Response           ; So that the caller gets the appropriate CPU flags -, 0, +
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


