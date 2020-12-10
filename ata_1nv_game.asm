;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
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
	sta COLOR3                   ; Make sure it starts in the OS shadow and 
	sta COLPF3                   ; the hardware registers.


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
	lda #PLAYER_IDLE_Y
	sta zPLAYER_ONE_Y
	sta zPLAYER_ONE_NEW_Y
	lda #$04
	sta zPLAYER_ONE_COLOR
	lda #[PLAYER_MIN_X+40]
	sta zPLAYER_ONE_X
	inc zPLAYER_ONE_REDRAW


;	lda #$1
	lda #$FF
	sta zPLAYER_TWO_ON ; (0) not playing. (FF)=Title/Idle  (1) playing.
;	lda #PLAYER_PLAY_Y
	lda #PLAYER_IDLE_Y
	sta zPLAYER_TWO_Y
	sta zPLAYER_TWO_NEW_Y
	lda #$04
	sta zPLAYER_TWO_COLOR
	lda #[PLAYER_MAX_X-40]
	sta zPLAYER_TWO_X
	inc zPLAYER_TWO_REDRAW


	; ===== Start the Title running on the next frame =====

	lda #EVENT_TITLE
	sta zCurrentEvent
	lda #0 
	sta zEventStage

	rts



; ==========================================================================
; GAME TITLE
; ==========================================================================
; Event Process TITLE SCREEN
; The activity on the title screen:
; Always draw the animated frog. The frog animation is called on every 
; frame since WobbleDeWobble manages timing and movement. 
; The animated Rezz-in for the title text is also called on all frames.   
; There is no AnimateFrames control of the speed until the animations
; and scrolling for stage 2 and 3.
; Stages: 
; 0) Random rezz in for Title graphics.
; Not Stage 0.
; 1|4) Blink Prompt for joystick button.  Joystick button input is accepted.
; Joystick button input is not observed during Stages 2, and 3.
; 1) Just input checking per above, and testing Option/Select.
; 2) Shifting Left Graphics down.
; 3) OPTION or SELECT animation  scroll in from Right to Left.
; 4) Waiting to return to Stage 0 (AnimateFrames2 timer). and Button Input.
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
	; -- if either player is not yet in playing position. (A button was pressed.)
	; ++ if both players are ready to play.  (Not going to happen yet.)
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

	rts


; ==========================================================================
; GAME COUNTDOWN
; ==========================================================================
; A player has pressed their button.  Final Commitment to begin playing 
; the game.
;
; 0) Continue Title animations for logo, scrolling text, and scrolling land.
; 1) A Player (one or two) is moving up.  
;    The other player is color cycling until button pressed.
; 2) Run the 3, 2, 1, countdown...
; 3) AFTER countdown,AND Player selection animation complete then 
;    move the mothership up the screen. 
; 4) When the mothership leaves the screen, then 
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

	jmp b_gc_PlayerCheck     ; Skip over the mothership setup . 


b_gc_StartMothership         ; Countdown is done -1.  Signal Mothership flies away, dissolve player.\

	lda zBigMothershipPhase  ; 1 is mothership already in motion.
	bne b_gc_MoveMothership  ; So, end here.
	inc zBigMothershipPhase  ; Start the mothership moving, VBI does the rest.


; ===== Pause for New Player Placement (if they press the button) =====

b_gc_PlayerCheck

	lda zBigMothershipPhase    ; 1 is mothership in motion.
	bne b_gc_EndPlayerCheck    ; So, skip this.

	jsr PlayerSelectionInput

	jsr Pmg_CycleOfflinePlayer ; Strobe the color for whatever player is not playing

b_gc_EndPlayerCheck


; ===== Run Big Mothership Animation (VBI does redraw.) =====
; ===== Also, VBI will redraw/remove the unused Player. =====
; ===== Game starts when the Mothership reaches the Y limit ====

b_gc_MoveMothership

	lda zBigMothershipPhase    ; 0 is mothership not in motion.
	beq b_gc_End               ; So, end here.

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



b_gc_End

	lda VCOUNT
	cmp #23
	bne b_gc_End

	lda RTCLOK60
	and #$FE
;	ora #$02
	sta WSYNC ; 1
	sta COLPF3
	clc
	adc #$04
	sta WSYNC; 2
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 3
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 4
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 5
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 6
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 7
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 8
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 9
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 10
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 11
	sta COLPF3
	clc
	adc #$04
	sta WSYNC ; 12
	sta COLPF3

	lda #$00
	sta WSYNC
	sta COLBK

	rts



; ==========================================================================
; GAME SETUP MAIN
; ==========================================================================
;
; --------------------------------------------------------------------------

GameSetupMain

	rts



; ==========================================================================
; GAME MAIN
; ==========================================================================
;
; --------------------------------------------------------------------------

GameMain

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
; Player management for Title screen.   
; Button transitions to selecting for game play.
;
; If a Player is intending to play and is not yet in the starting 
; position, then process movement, and check for input from the 
; other player.
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

PSI_Response .byte $00

PlayerSelectionInput

	lda #0
	sta PSI_Response

	lda zPLAYER_ONE_ON         ; (0) not playing. (FF)=Title/Idle  (1) playing.
	beq b_psi_TryPlayer2       ; Zero should not really happen, but my OCD says this must be handled.
	bmi b_psi_TryPlayer1Idle   ; $FF is idle.

	lda zPLAYER_ONE_Y          ; Here we know Player 1 is Playing.  ($1 is playing)
	cmp #PLAYER_PLAY_Y         ; Is it at the Playing position?
	bne b_psi_MovePlayer1Up    ; No.  Move it up.
	lda #1
	sta PSI_Response           ; Yes. 1 Ready to Play.
	bne b_psi_TryPlayer2       ; Done here.

b_psi_MovePlayer1Up
	lda #$FF
	sta PSI_Response           ; -1 Signal that this is still in motion.
	dec zPLAYER_ONE_NEW_Y      ; Tell VBI to move up one scan line.
	bne b_psi_TryPlayer2       ; Done.  Now test Player 2

b_psi_TryPlayer1Idle           ; Player 1 is idle.  ($FF  is idle)
	lda STRIG0                 ; (Read) TRIG0 - Joystick 0 trigger (0 is pressed. 1 is not pressed)
	bne b_psi_TryPlayer2       ; Not pressed.  Go to player 2
	; ldy #PLAYER_ONE_SHOOT
	; jsr PlaySound 
	lda #$1                    ; (FF)=Title/Idle  (1) playing.
	sta zPLAYER_ONE_ON
	lda #$FF
	sta PSI_Response           ; -1 Signal that this is in motion.

b_psi_TryPlayer2
	lda zPLAYER_TWO_ON         ; (0) not playing. (FF)=Title/Idle  (1) playing.
	beq b_psi_Exit             ; Zero should not really happen, but my OCD says this must be handled.
	bmi b_psi_TryPlayer2Idle   ; $FF is idle.

	lda zPLAYER_TWO_Y          ; Here we know Player 1 is Playing.  ($1 is playing)
	cmp #PLAYER_PLAY_Y         ; Is it at the Playing position?
	bne b_psi_MovePlayer2Up    ; No.  Move it up.
	lda PSI_Response           ; Yes. (Ready is lower priority than player 1 not ready).
	bmi b_psi_Exit             ; Already negative means Player 1 is in motion.
	lda #1
	sta PSI_Response           ; Yes. Player 2 idle.  So Player 1, Ready to Play.
	bne b_psi_Exit             ; Done here.

b_psi_MovePlayer2Up
	dec zPLAYER_TWO_NEW_Y      ; Tell VBI to move up one scan line.
	lda #$FF                   ; Signal this is in motion.
	sta PSI_Response
	bmi b_psi_Exit

b_psi_TryPlayer2Idle           ; Player 2 is idle.  ($FF  is idle)
	lda STRIG1                 ; (Read) TRIG1 - Joystick 1 trigger (0 is pressed. 1 is not pressed)
	bne b_psi_Exit             ; Not pressed.  Done.
	; ldy #PLAYER_TWO_SHOOT
	; jsr PlaySound 
	lda #$FF                   ; Signal this is in motion. (Not ready is higher priority than player 1 ready).
	sta PSI_Response
	lda #$1                    ; (FF)=Title/Idle  (1) playing.
	sta zPLAYER_TWO_ON

b_psi_Exit
	lda PSI_Response           ; Player 1 and 2 are Off or idle.  (not playing.)

	rts


