;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; GAME MAIN LOOP
; 
; All the top level event/functions called by the Game Loop.
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

	lda #0                  ; Zero a lot of things . . 

	sta SHPOSM3             ; Remove the animated colors from the title.
	sta SHPOSM2
	sta SHPOSM1
	sta SHPOSM0

	ldy #5
b_gsm_Loop_ZeroPlayerScores
	sta zPLAYER_ONE_SCORE,y ; maybe something more here... like points add, or mothership value, too.
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
	sta zPLAYER_ONE_DEBOUNCE
	sta zPLAYER_TWO_DEBOUNCE

	; M O T H E R S H I P 

	jsr GameResetHitCounter
                                  ; should be 2
	lda #2                          ; initial ms speed
	sta zMOTHERSHIP_MOVE_SPEED
	lda #10                         ; should be 10
	sta zMOTHERSHIP_SPEEDUP_THRESH  ; speedup threshld - every 10 shots it speeds up
	sta zMOTHERSHIP_SPEEDUP_COUNTER ; speedup count

	jsr GameRandomizeMothership     ; Set random direction , and starting X position.
	ldx #0
	jsr GameSetMotherShipRow        ; Convert Row 0 to Y position on screen.
	lda #24
	sta zMOTHERSHIP_Y               ; Force "old" position above the row 0 position. 

	; P L A Y E R S 

	lda #PM_SIZE_NORMAL
	sta SIZEP2
	sta SIZEP3

	; Setting random direction for both players.
	; Not doing any comparison for the player on or off,
	; because whatever is set here doesn't cause anything 
	; to happen during the game if the player is OFF . . .

	lda RANDOM                      ; Set random direction.
	and #$01
	sta zPLAYER_ONE_DIR             ; 0 == left to right. 1 == right to left.
	lda RANDOM                      ; Set random direction.
	and #$01
	sta zPLAYER_TWO_DIR             ; 0 == left to right. 1 == right to left.

	; O T H E R    G A M E    V I S U A L S 

	jsr Gfx_ShowScreen

	lda #$0A
	sta zSTATS_TEXT_COLOR           ; Turn on stats line.

	lda #2                          ; Reset the animation timer for players/left/right movement.
	sta zAnimatePlayers

	lda #EVENT_GAME                 ; Fire up the game screen.
	sta zCurrentEvent

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

	jsr GameAddScoreToPlayer

	jsr GameCheckHighScores

	jsr Gfx_ShowScreen

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

