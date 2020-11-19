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

	lda #$88
	sta COLPF0
	lda #$84
	sta COLPF2


	; ===== The Big Logo =====

	lda #TITLE_LOGO_X_START
	sta zTitleHPos

	lda #0
	sta zTitleLogoPMFrame

	lda #TITLE_SPEED_PM
	sta zAnimateTitlePM

	lda #COLOR_ORANGE1           ; Yes.  Reset to first color.
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

	lda #BIG_MOTHERSHIP_START ; Starting position of the big mothership
	sta zBIG_MOTHERSHIP_Y

	lda #BIG_MOTHERSHIP_SPEED ; How many frames to wait per mothership move.
	sta zBigMothershipSpeed

	lda #1                    ;  0 = standing still  !0 = Moving up.
	sta zBigMothershipPhase

	lda #114
	sta HPOSP2
	lda #128
	sta HPOSP3

	lda #$36
	sta PCOLOR2
	sta PCOLOR3

	lda #PM_SIZE_DOUBLE
	sta SIZEP2
	sta SIZEP3

	jsr Pmg_Draw_Big_Mothership


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

; 1) Mothership if moving.

; 2) 3, 2, 1 if in progress.



; 3) Animate Missiles per current frame stage.   
;    VBI reset the missile horizontal positions.
;    The DLI applied them.

; Load animation frames into Player/Missile memory

b_gt_TitleAnimation

	lda zAnimateTitlePM;
	bne b_gt_ExitTitleAnimation

	jsr Pmg_Animate_Title_Logo ; This will also reset the timer for animation.

b_gt_ExitTitleAnimation



; =============== Stage * ; Always run the frog and the label flashing. . .

;	jsr WobbleDeWobble         ; Frog drawing spirograph path on the title.
;	jsr FlashTitleLabels       ; and cycle the label flashing.

;	lda EventStage
;	bne bETS_InputStage        ; stage is >0, so title treatment is over.

; =============== Stage 0      ; Animating Title only while sound runs

;	lda TITLE_UNDERLINE_FADE+6
;	sta COLPF0_TABLE+9

;	lda SOUND_CONTROL3         ; Is channel 3 busy?
;	beq bETS_EndTitleAnimation ; No. Stop the title animation.

;bETS_RandomizeLogo
;	lda #$FF                   ; Channel 3 is playing sound, so animate.
;	jsr TitleRender            ; and -1  means draw the random masked title.
;	jmp EndTitleScreen         ; Do not process input during the randomize.

bETS_EndTitleAnimation
;	lda #1                     ; Draw the title as solid and stop animation.
;	sta EventStage             ; Stage 1 is always skip the title drawing.
;	sta EnablePressAButton     ; Turn On the prompt to press button (for later below).
;	jsr TitleRender            ; and 1 also means draw the solid title.

; =============== Stage-ish Not 0-ish, handling button input when Option/Select hacks are not in motion. 

bETS_InputStage 

;CheckTitleInput
;	lda EnablePressAButton     ; Is button input on?
;	beq CheckFunctionButton    ; No.  A later stage may still be running.

;	jsr RunPromptForButton     ; Blink Prompt to press Joystick button and check input.
;	beq CheckFunctionButton    ; No joystick button.  Try a function key.

;ProcessTitleScreenInput        ; Button pressed. Prepare for the screen transition to the game.
;	jsr SetupTransitionToGame

	; This was part of the Start event, but after the change to keep the 
	; scores displayed on the title screen it would end up erasing the 
	; last game score as soon as the title transition animation completed.
	; Therefore resetting the score is deferred until leaving the Title.
;	jsr ClearGameScores     ; Zero the score.  And high score if not set.
;	jsr PrintFrogsAndLives  ; Update the screen memory.

;	jmp EndTitleScreen


; For the Option/Select handling it is easy to maintain safe input (no 
; flaky on/offs) because once a key is read it takes a while to scroll 
; the text in, giving the user time to release the key.
; 
; OPTION = Change number of frogs.
; SELECT = Change game level/difficulty.
;
; If the Current selection for frogs is greater than the last game's (or 
; the default) OR the current level is less than the last game's starting 
; difficulty, then the high score is cleared on game start.

CheckFunctionButton
;	lda EventStage
;	cmp #1                   ; 1) Just doing input checking per above, and testing Option/Select.
;	bne bETS_Stage2          ; Not Stage 1.  Go to Stage 2.  Skip checking console keys.

;	jsr CheckForConsoleInput ; If Button pressed, then sets Stage 2, and EventCounter for TitleShiftDown.
;	jmp EndTitleScreen       ; Regardless of the console input, this is the end of stage 1.

; =============== Stage 2    ; Shifting Left buffer pixels down.

bETS_Stage2
;	cmp #2                   ; 2) slide left buffer down.
;	bne bETS_Stage3          ; Not Stage 2.  Try Stage 3.

;CheckTitleSlideDown 
;	lda AnimateFrames
;	bne EndTitleScreen       ; Animation frames not 0.  Wait till next time.

;	jsr TitleShiftDown       ; Shift Pixels down

;	ldx EventCounter         ; Get the counter
;	jsr FadeTitleUnderlines  ; Fade (or not) the green underlines to yellow.

;	dec EventCounter         ; Decrement number of times this is done.
;	bmi bETS_Stage2_ToStage3 ; When it is done, go to stage 3. 

;	lda #TITLE_DOWN_SPEED    ; The down shift is not done, so 
;	jsr ResetTimers          ; Reset animation/input frame counter.      
;	jmp EndTitleScreen

bETS_Stage2_ToStage3         ; Setup for next Stage
;	lda #3
;	sta EventStage

;	jsr RandomizeTitleColors ; Random color gradient for the Text pixels.

;	jsr PlayLefts            ;  Play Left movement sound for title graphics on OPTION and SELECT
;	inc VBIEnableScrollTitle ; Turn on Title fine scrolling.
;	bne EndTitleScreen

; =============== Stage 3    ; Scrolling in pixels from Right to Left. 

bETS_Stage3
;	cmp #3
;	bne bETS_Stage4

;CheckTitleScroll
;	lda VBIEnableScrollTitle   ; Is VBI busy scrolling option text?
;	bne EndTitleScreen         ; Yes.  Nothing more to do here.

	; Readjust display to show the left buffer visible 
;	; and reset scrolling origin.
;	jsr TitleCopyRightToLeftGraphics ; Copy right buffer to left buffer.
;	jsr TitleSetOrigin               ; Reset LMS to point to left buffer

;bETS_Stage3_ToStage4         ; Setup for next Stage
;	lda #4
;	sta EventStage
;	bne EndTitleScreen

; =============== Stage 4 ; Waiting on RestoreTitleTimer to return to Stage 0. 

bETS_Stage4                  ; Stage 4, allow console input.
;	jsr CheckForConsoleInput ; If Button pressed, then sets Stage 2, and EventCounter for TitleShiftDown.
;	beq bETS_CheckAutoReturn ; No console key pressed.  So, check if return is automatic.
;	lda #0                   ; Console key input returns us to Stage 2, so zero the auto timer.
;	sta RestoreTitleTimer
;	beq EndTitleScreen

bETS_CheckAutoReturn
;	lda RestoreTitleTimer    ; Wait for Input timeout to expire.
;	bne EndTitleScreen       ; No timeout yet.

	; Expired auto timer... Return to Stage 0.
;	jsr ToPlayFXScrollOrNot  ; Start slide sound playing if not playing now.
;	lda TITLE_UNDERLINE_FADE,x ; Return underlines to green (SELECT/OPTION faded them out.)
;	sta COLPF0_TABLE+8
;	lda #0
;	sta EventStage

;	jsr ResetTitleColors     ; Original title colors.


EndTitleScreen

	rts


; ==========================================================================
; GAME COUNTDOWN
; ==========================================================================
;
; --------------------------------------------------------------------------

GameCountdown 

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


