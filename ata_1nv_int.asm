;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; TIMER STUFF AND INPUT
;
; Miscellaneous:
; Timer ranges
; Joystick input,
; Tick Tock values,
; Count downs,
; DLI and VBI routines.
; Prompt for Button press.
;
; --------------------------------------------------------------------------

; ==========================================================================
; Animation speeds of various displayed items.   Number of frames to wait...
; --------------------------------------------------------------------------
BLINK_SPEED       = 3    ; Speed of updates to Press A Button prompt.

TITLE_SPEED       = 2    ; Scrolling speed for title. 
TITLE_DOWN_SPEED  = 3    ; Shift title down before scroll.
TITLE_RETURN_WAIT = 180  ; Time to wait to return to Stage 0.
TITLE_WIPE_SPEED  = 0    ; Title screen to game screen fade speed.

WOBBLEX_SPEED     = 2    ; Speed of flying objects on Title and Game Over.
WOBBLEY_SPEED     = 3    ; Speed of flying objects on Title and Game Over.

FROG_WAKE_SPEED   = 120  ; Initial delay about 2 sec for frog corpse viewing/mourning
DEAD_FADE_SPEED   = 4    ; Fade the game screen to black for Dead Frog
DEAD_CYCLE_SPEED  = 5    ; Speed of color animation on Dead screen

WIN_FADE_SPEED    = 4    ; Fade the game screen to black to show Win
WIN_CYCLE_SPEED   = 5    ; Speed of color animation on Win screen 

GAME_OVER_SPEED   = 4    ; Speed of Game over background animation


; Timer values.  NTSC.
; About 9-ish Inputs per second.
; After processing input (from the joystick) this is the number of frames
; to count before new input is accepted.  This prevents moving the frog at
; 60 fps and maybe compensates for any jitter/uneven toggling of the joystick
; bits by flaky controllers.
; At 9 events per second the frog moves horizontally 18 color clocks, max. 
INPUTSCAN_FRAMES = $07  ; previously $09


; PAL Timer values.  PAL ?? guesses...
; About 7 keys per second.
; KEYSCAN_FRAMES = $07
; based on number of frogs, how many frames between boat movements...
; ANIMATION_FRAMES .byte 25,21,17,14,12,11,10,9,8,7,6,5
; Not really sure what to do about the new model using the 
; BOAT_FRAMES/BOAT_SHIFT lists.
; PAL would definitely be a different set of speeds.


; ==========================================================================
; RESET TIMERS
; ==========================================================================
; Reset Input Scan Timer and AnimateFrames Timer.
;
; A  is the time to set for animation.
; --------------------------------------------------------------------------

ResetTimers

	sta zAnimateFrames

	pha ; preserve it for caller.

	lda zInputScanFrames
	bne EndResetTimers

	lda #INPUTSCAN_FRAMES
	sta zInputScanFrames

EndResetTimers
	pla ; get this back for the caller.

	rts


; ==========================================================================
; CHECK INPUT                                                 A  X
; ==========================================================================
; Check for input from the controller....
;
; Eliminate Down direction.
; Eliminate conflicting directions.
; Add trigger to the input stick value.
;
; STICK0 Joystick bits that matter:  
; ----1111  OR  "NA NA NA NA Right Left Down Up".
; A zero value bit means joystick is pushed in that direction.
; Note that 1 bit means no input and 0 bit means the direction
; is pressed.  For logical reasons I want to reverse this and 
; turn it into 1 bit means input.
; 
; The original version of this was an obscenely ill-conceived,
; sloppy mess of a dozen bit floggings and comparisons.
; The new version eliminates a lot of that original bit mashing
; with a simple lookup table. The only extra part now is adding
; the trigger to the input information.
;
; Description of the bit twiddling below:
;
; Cook the bits to turn on the directions we care about and zero
; the other bits, therefore, if the resulting stick value is 0 then 
; it means no input, which is an easier evaluation.
; - Down input is ignored (masked out).
; - Since up movement is the most likely to result in death the 
;   up movement must be exclusively up.  If a horizontal 
;   movement is also on at the same time then the up movement 
;   will be masked out.
;
; Arcade controllers with individual buttons would allow 
; accidentally (or intentionally) pushing both left and right 
; directions at the same time.  To avoid unnecessary fiddling 
; with the frog in this situation eliminate both motions if both
; are engaged.
;
; STRIG0 Button
; 0 is button pressed., !0 is not pressed.
; If STRIG0 input then set bit $10 (OR ---1----  for trigger.
;
; Return  A  with InputStick value of cooked Input bits where 
; the direction and trigger set are 1 bits.  
;
; Resulting Bit values:   
; 00011101  OR  "NA NA NA Trigger Right Left NA Up"
; THEREFORE,
; STICK   / BITS    / FILTERED / BITS
; R L D U / 0 0 0 0 / - - - -  / 0 0 0 0  - input is technically impossible 
; R L D - / 0 0 0 1 / - - - -  / 0 0 0 0  - input is technically impossible 
; R L - U / 0 0 1 0 / - - - -  / 0 0 0 0  - input is technically impossible 
; R L - - / 0 0 1 1 / - - - -  / 0 0 0 0  - input is technically impossible 
; R - D U / 0 1 0 0 / - - - -  / 0 0 0 0  - input is technically impossible 
; R - D - / 0 1 0 1 / R - - -  / 1 0 0 0  - down ignored 
; R - - U / 0 1 1 0 / R - - -  / 1 0 0 0  - up must be exclusively up 
; R - - - / 0 1 1 1 / R - - -  / 1 0 0 0  - right 
; - L D U / 1 0 0 0 / - - - -  / 0 0 0 0 -  input is technically impossible 
; - L D - / 1 0 0 1 / - L - -  / 0 1 0 0  - down ignored 
; - L - U / 1 0 1 0 / - L - -  / 0 1 0 0  - up must be exclusively up 
; - L - - / 1 0 1 1 / - L - -  / 0 1 0 0  - left  
; - - D U / 1 1 0 0 / - - - -  / 0 0 0 0  - input is technically impossible 
; - - D - / 1 1 0 1 / - - - -  / 0 0 0 0  - down ignored 
; - - - U / 1 1 1 0 / - - - U  / 0 0 0 1  - up is exclusively up 
; - - - - / 1 1 1 1 / - - - -  / 0 0 0 0  - nothing
; --------------------------------------------------------------------------

STICKEMUPORNOT_TABLE ; cooked joystick values
	.by $00 $00 $00 $00 $00 $08 $08 $08 $00 $04 $04 $04 $00 $00 $01 $00

CheckInput

;	lda InputScanFrames        ; Is input timer delay  0?
;	bne SetNoInput             ; No. thus nothing to scan. (and exit)

;	ldx STICK0                 ; The OS nicely separates PIA nybbles for us
;	lda STICKEMUPORNOT_TABLE,x ; Convert input into workable, filtered output.
;	sta InputStick             ; Save it.

;AddTriggerInput
;	lda STRIG0                 ; 0 is button pressed., !0 is not pressed.
;	bne DoneWithBitCookery     ; if non-zero, then no button pressed.

;	lda InputStick             ; The current stick input value.
;	ora #%00010000             ; Turn on 5th bit/$10 for the trigger.
;	sta InputStick             ; Save it.  (fall through for return..)

DoneWithBitCookery             ; Some input was captured?
;	lda InputStick             ; Return the input value?
;	beq ExitCheckInput         ; No, nothing happened here.  Just exit.

;	lda #INPUTSCAN_FRAMES      ; Because there was input collected, then
;	sta InputScanFrames        ; Reset the input timer.

;ExitInputCollection            ; Input occurred
	lda #0                     ; Kill the attract mode flag
	sta ATRACT                 ; to prevent color cycling.

;	lda InputStick             ; Return the input value.
	rts

SetNoInput
;	lda #0
;	sta InputStick             ; Force no data for input.

ExitCheckInput
	rts


; ==========================================================================
; CHECK FOR CONSOLE INPUT
; ==========================================================================
; Support Routine CHECK FOR CONSOLE INPUT
; Evaluate if console key is pressed.
; This is called during the Title-specific event.
; If a console key is pressed then do the associated game config value 
; changes, prepare the Title line scrolling, and set the Title screen 
; to execute at Stage 2.
;
; Returns:
; 0 for no input.
; !0 for a CONSOLE key was pressed.
; --------------------------------------------------------------------------

CheckForConsoleInput

CheckOptionKey
;	lda CONSOL                 ; Get Option, Select, Start buttons
;	and #CONSOLE_OPTION        ; Is Option pressed?  0 = pressed. 1 = not
;	bne CheckSelectKey         ; No.  Try the select.

;	jsr PlayTink               ; Button pressed. Set Pokey channel 2 to tink sound.

	; increment starting frogs.
	; generate string for right buffer
;	ldx NewLevelStart          
;	inx
;	cpx #[MAX_FROG_SPEED+1]    ; 13 + 1
;	bne bCFCI_SkipResetLevel
;	ldx #0
bCFCI_SkipResetLevel
;	stx NewLevelStart          ; Updated starting level.

;	jsr TitlePrepLevel
;	jsr MultiplyFrogsCrossed ; Multiply by 18, make index base, set difficulty address pointers.
;	jmp bCFCI_StartupStage2


CheckSelectKey
;	lda CONSOL                 ; Get Option, Select, Start buttons
;	and #CONSOLE_SELECT        ; Is SELECT pressed?  0 = pressed. 1 = not
;	bne bCFCI_End              ; No.  Finished with all.

;	jsr PlayTink               ; Button pressed. Set Pokey channel 2 to tink sound.

	; increment lives.
	; generate string for right buffer
;	ldx NewNumberOfLives
;	inx
;	cpx #[MAX_FROG_LIVES+1]    ; 7 + 1
;	bne bCFCI_SkipResetLives
;	ldx #1

bCFCI_SkipResetLives
;	stx NewNumberOfLives      ; Get the updated number of new lives for the next game.
;	jsr TitlePrepLives        ; Get the scrolling buffer ready.
;	jsr WriteNewLives         ; Update the status line to match the new number of frogs.

bCFCI_StartupStage2
;	lda #2
;	sta EventStage            ; Stage 2 is the shift Left Buffer down.
;	lda #6
;	sta EventCounter          ; Do it six times.
;	lda #TITLE_DOWN_SPEED
;	jsr ResetTimers           ; Reset animation/input frame counter.

;	jsr PlayDowns             ; Play down movement sound for title graphics on OPTION and SELECT
	bne bCFCI_Exit            ; Return !0 exit.

bCFCI_End
	lda #0  ; 0 means nothing happened.

bCFCI_Exit
	rts


;==============================================================================
;                                                           SCREENWAITFRAME  A
;==============================================================================
; Subroutine to wait for the current frame to finish display.
;
; ScreenWaitFrame  uses A
;==============================================================================

libScreenWaitFrame

	pha                 ; Save A, so caller is not disturbed.
	lda RTCLOK60        ; Read the jiffy clock incremented during vertical blank.

bLoopWaitFrame
	cmp RTCLOK60        ; Is it still the same?
	beq bLoopWaitFrame  ; Yes.  Then the frame has not ended.

	pla                 ; restore A
	rts                 ; No.  Clock changed means frame ended.  exit.








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
	.word $0000              ; 0  = EVENT_INIT            one time globals setup
	.word DISPLAY_LIST_TITLE ; 1  = EVENT_SETUP_TITLE
	.word DISPLAY_LIST_TITLE ; 2  = EVENT_TITLE           run title and get player start button
	.word DISPLAY_LIST_TITLE ; 3  = EVENT_COUNTDOWN       then move mothership
	.word DISPLAY_LIST_TITLE ; 4  = EVENT_SETUP_GAME
	.word DISPLAY_LIST_GAME  ; 5  = EVENT_GAME            regular game play.  boom boom boom
	.word DISPLAY_LIST_GAME  ; 6  = EVENT_LAST_ROW        forced player shove off screen
	.word DISPLAY_LIST_GAME  ; 7  = EVENT_SETUP_GAMEOVER
	.word DISPLAY_LIST_GAME  ; 8  = EVENT_GAMEOVER        display text, then go to title

TABLE_GAME_DISPLAY_LIST_INTERRUPT
	.word DoNothing_DLI ; 0  = EVENT_INIT            one time globals setup
	.word DoNothing_DLI ; 1  = EVENT_SETUP_TITLE
	.word TITLE_DLI     ; 2  = EVENT_TITLE           run title and get player start button
	.word TITLE_DLI     ; 3  = EVENT_COUNTDOWN       then move mothership
	.word TITLE_DLI     ; 4  = EVENT_SETUP_GAME
	.word GAME_DLI      ; 5  = EVENT_GAME            regular game play.  boom boom boom
	.word DoNothing_DLI ; 6  = EVENT_LAST_ROW        forced player shove off screen
	.word DoNothing_DLI ; 7  = EVENT_SETUP_GAMEOVER
	.word DoNothing_DLI ; 8  = EVENT_GAMEOVER        display text, then go to title


MyImmediateVBI

; ======== MANAGE CHANGING DISPLAY LIST ========
;	lda #$c2
;	sta COLBK


	lda zCurrentEvent                       ; Is the game at 0 (INIT)?
	beq ExitMyImmediateVBI                  ; Yes.  Then we should not be here.

	asl                                     ; State value times 2 for size of address
	tax                                     ; Use as index

	lda TABLE_GAME_DISPLAY_LIST,x           ; Copy Display List Pointer for the OS
	sta SDLSTL                              
	lda TABLE_GAME_DISPLAY_LIST_INTERRUPT,x ; Copy Display List Interrupt chain table starting address
	sta VDSLST
	inx                                     ; and the high bytes.
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
; Tasks that tolerate more laziness.  In fact, most of the screen activity
; occurs here.
;
; TITLE SCREEN AND COUNTDOWN ACTIVITIES:
; 1) Mothership if moving up.
; 2) 3, 2, 1 GO, if in progress.
; 3) Animate Missiles for Title logo
; 4) Author scrolling
; 5) Documentation Scrolling
; 6) Mountain Background Scrolling.
;
;
; GAME PLAY ACTIVITIES
;
;
;
; GAME OVER ACTIVITIES
;
;
; Manage death of frog. 
; Fine Scroll the boats.
; Update Player/Missile object display.
; Perform the boat parts animations.
; Manage timers and countdowns.
; Scroll the line of credit text.
; Blink the Press Button prompt if enabled.
;==============================================================================

MyDeferredVBI

	lda zCurrentEvent           ; Is this is still 0 (INIT)? 
	bne b_mdv_DoMyDeferredVBI   ; No.   Continue the Deferred VBI

	jmp XITVBV                  ; Yes.  We should not be here.  End now.  Return to OS.


b_mdv_DoMyDeferredVBI

; ======== Beginning  ========
; Kill Attract mode, and clear Player/Missile collisions.

	lda #0
	sta ATRACT

; ======== TITLE SCREEN AND COUNTDOWN ACTIVIES  ========
; ======================================================
	lda zCurrentEvent               ; Get current state
	cmp #[EVENT_COUNTDOWN+1]        ; Is it TITLE or COUNTDOWN
	bcc b_mdv_DoBigMothership       ; Yes. Less Than < is correct

	jmp b_mdv_DoGameManagement      ; No. Greater Than > COUNTDOWN is GAME or GAMEOVER


; For the Title and Countdown the work that needs to occur:
; 1) Mothership if moving up.
; 2) 3, 2, 1 GO, if in progress.
; 3) Animate Missiles for Title logo
; 4) Author scrolling
; 5) Documentation Scrolling
; 6) Mountain Background Scrolling.


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


; ======== 2) MANAGE COUNTDOWN ANIMATION  ========

; Mostly run during the main line code.


; ======== 3) MANAGE TITLE COLOR ANIMATION ========

; Swap the graphics image to make it appear the text is animated.
; Manage the Missile positions and base color used for the color overlay.
; Main code draws Missiles images.

b_mdv_DoTitleAnimation 

	; First, Animate the Title graphics (gfx pixels)

	dec zAnimateTitleGfx         ; decrement countown clock
	bne b_mdv_SkipTitleGfx       ; has not reached 0, then no work to do. 

	jsr Gfx_Animate_Title_Logo   ; Updates the display list LMS to point to new pixels.

b_mdv_SkipTitleGfx

	; Second, update the color information

	lda ZTitleLogoBaseColor      ; Always restore this from the base.
	sta ZTitleLogoColor          ; Save it for the DLI use

	dec zAnimateTitlePM
	; Note that the main code is responsible for loading up the Missile image.  
	; THEREFORE, do not reset the zAnimateTitlePM timer for the Missile animation here.  
	; The main code will do it, because it needs to know that the timer reached 0.
	
	bne b_mdv_SkipTitleMissileUpdate ; !0 is not time to animate missiles?

	lda ZTitleLogoBaseColor      ; Get the Base color
	cmp #COLOR_ORANGE_GREEN      ; Is it the ending color?
	bne b_mdv_AddToColor         ; No.  Add to the color component.

	lda #COLOR_ORANGE1           ; Yes.  Reset to first color.
	bne b_mdv_UpdateColor        ; Go do the update.

b_mdv_AddToColor
	clc
	adc #$10                      ; Add 16 to color.

b_mdv_UpdateColor
	sta ZTitleLogoBaseColor      ; Resave the new update
	sta ZTitleLogoColor          ; Save it for the DLI use
	sta COLOR3                   ; Make sure it starts in the OS shadow and 
	sta COLPF3                   ; the hardware registers.

	; Third, change the Missile animation images and position.

	ldx ZTitleHPos              ; Move horizontally right two color clocks per animation.
	inx
	inx

	ldy zTitleLogoPMFrame       ; Go to the next Missile image index
	iny
	cpy #TITLE_LOGO_PMIMAGE_MAX ; Did it go past the last frame?
	bne b_mdv_SkipResetPMImage  ; No.  Do not reset Missile image index.

	ldx #TITLE_LOGO_X_START     ; Reset horizontal position to the start
	ldy #0                      ; Reset missile image index to start.

b_mdv_SkipResetPMImage
	stx ZTitleHPos              ; Save modified base Missile pos, whatever happened above.
	sty zTitleLogoPMFrame       ; Save new Missile image index.

	txa
	jsr Pmg_AdustMissileHPOS    ; Update the missile HPOS.

b_mdv_SkipTitleMissileUpdate


; ======== 4) MANAGE CREDITS SCROLLING ========

; Two lines of author credits.   
; When the first line scrolls left the second line scrolls right.   
; Pause for a few seconds for reading comprehension.
; Then reverse directions.
; Rinse.  Repeat.

; 1) If waiting, continue to wait.
; 2) if not waiting, then do motion.  
; 3) Wait for motion timer.
; 4) Execute motion. Either
; 4)a) top row to the left, bottom row to the right, OR
; 4)b) top row to the right, bottom row to the left
; 5) At end, then reset
; 5)a) toggle motion direction.
; 5)b) restart the waiting phase.

b_mdv_DoCreditScrolling

	lda zCreditsPhase             ; 0 == waiting    1  == scrolling
	bne b_mdv_RunCreditScrolling

	; Waiting....
	dec zCreditsTimer
	bne b_mdv_EndCreditScrolling  ; Timer still >0

	; Reset timer.  And start scrolling.
	inc zCreditsPhase             ; To get here we know this was 0.
	lda #CREDITS_MAX_PAUSE
	sta zCreditsTimer
	
	; We are moving the credits...

b_mdv_RunCreditScrolling

	dec zCreditsScrollTimer       ; Delay to not scroll to quickly.
	bne b_mdv_EndCreditScrolling

	lda #CREDITS_STEP_TIMER       ; Reset the scroll timer
	sta zCreditsScrollTimer

	lda zCreditsMotion            ; What direction are we moving in?
	beq b_mdv_CreditLeftRight     ; 0 is moving Left/Right

	; Otherwise, we're going in the opposite direction here.  (Right/Left)

	inc zCredit1HS                ; Credit 1 Right
	lda zCredit1HS
	cmp #16                       ; Reach the end of fine scrolling 16 color clocks?
	bne b_mdv_Credit2_Left        ; No, go do the Credit2 line.
	lda #0                        ; Yes. 
	sta zCredit1HS                ; Reset the fine scroll, and...
	dec DL_LMS_SCROLL_CREDIT1     ; Coarse scroll the text... 8 color clocks.
	dec DL_LMS_SCROLL_CREDIT1     ; and another 8 color clocks.

b_mdv_Credit2_Left
	dec zCredit2HS                ; Credit 2 Left
;	lda zCredit2HS                ; Reach the end of fine scrolling 16 color clocks (wrap from 0 to -1)?
	bpl b_mdv_TestEndRightLeft    ; Nope.  End of scrolling, check end position
	lda #15                       ; Yes. 
	sta zCredit2HS                ; Reset the fine scroll, and...
	inc DL_LMS_SCROLL_CREDIT2     ; Coarse scroll the text... 8 color clocks.
	inc DL_LMS_SCROLL_CREDIT2     ; and another 8 color clocks.

b_mdv_TestEndRightLeft            ; They both scroll the same distance.  Check Line2's end position.
	lda zCredit2HS                ; Get fine scroll position
	cmp #12                       ; At the stopping point?
	bne b_mdv_EndCreditScrolling  ; nope.  We're done with checking.
	lda DL_LMS_SCROLL_CREDIT2     ; Get the coarse scroll position
	cmp #<[GFX_SCROLL_CREDIT2+30] ; at the ending coarse scroll position?
	bne b_mdv_EndCreditScrolling  ; nope.  We're done with checking.

	; reset to do left/right, then re-enable the reading comprehension timer.
	dec zCreditsMotion            ; It was 1 to do right/left scrolling. swap.
	dec zCreditsPhase             ; It was 1 to do scrolling.  switch to waiting.
	bne b_mdv_EndCreditScrolling  ; Finally done with this scroll direction. 

;  we're going in the Left/Right direction. 

b_mdv_CreditLeftRight
	dec zCredit1HS                ; Credit 1 Left
;	lda zCredit1HS                ; Reach the end of fine scrolling 16 color clocks (wrap from 0 to -1)?
	bpl b_mdv_Credit2_Right       ; No, go do the Credit2 line. 
	lda #15                       ; Yes. 
	sta zCredit1HS                ; Reset the fine scroll, and...
	inc DL_LMS_SCROLL_CREDIT1     ; Coarse scroll the text... 8 color clocks.
	inc DL_LMS_SCROLL_CREDIT1     ; and another 8 color clocks.

b_mdv_Credit2_Right
	inc zCredit2HS                ; Credit 1 Right
	lda zCredit2HS
	cmp #16                       ; Reach the end of fine scrolling 16 color clocks?
	bne b_mdv_TestEndLeftRight    ; Nope.  End of scrolling, check end position
	lda #0                        ; Yes. 
	sta zCredit2HS                ; Reset the fine scroll, and...
	dec DL_LMS_SCROLL_CREDIT2     ; Coarse scroll the text... 8 color clocks.
	dec DL_LMS_SCROLL_CREDIT2     ; and another 8 color clocks.


b_mdv_TestEndLeftRight            ; They both scroll the same distance.  Check Line2's end position.
	lda zCredit2HS                ; Get fine scroll position
	cmp #12                       ; At the stopping point?
	bne b_mdv_EndCreditScrolling  ; nope.  We're done with checking.
	lda DL_LMS_SCROLL_CREDIT2     ; Get the coarse scroll position
	cmp #<GFX_SCROLL_CREDIT2      ; at the ending coarse scroll position?
	bne b_mdv_EndCreditScrolling  ; nope.  We're done with checking.

	; reset to do left/right, then re-enable the reading comprehension timer.
	inc zCreditsMotion            ; It was 0 to do left/right scrolling. swap.
	dec zCreditsPhase             ; It was 1 to do scrolling.  switch to waiting.
	bne b_mdv_EndCreditScrolling  ; Finally done with this scroll direction. 

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

	; Reset timer.  And start scrolling.
	lda #DOCS_STEP_TIMER
	sta zDocsScrollTimer
	
	; We are moving the documentation...
	dec zDocsHS                ; Docs 1 pixel Left.  Did it wrap from 0 to -1?
	bpl b_mdv_EndDocsScrolling ; No.  We're done doing fine scrolling for this frame. 
	lda #15                    ; Yes...
	sta zDocsHS                ; Reset the fine scroll, and...
	
	lda DL_LMS_SCROLL_DOCS     
	cmp #<GFX_END_DOCS         ; Test if low byte is the ending position.
	bne b_mdv_AddDocsLMS       ; No.  Ok to increment LMS
	
	lda DL_LMS_SCROLL_DOCS+1     
	cmp #>GFX_END_DOCS         ; Test if high byte is the ending position.
	bne b_mdv_AddDocsLMS       ; No.  Ok to increment LMS

	lda #<GFX_SCROLL_DOCS      ; Load low bytes of starting position.
	sta DL_LMS_SCROLL_DOCS
	lda #>GFX_SCROLL_DOCS      ; Load high bytes of starting position.
	sta DL_LMS_SCROLL_DOCS+1

	jmp b_mdv_EndDocsScrolling

b_mdv_AddDocsLMS ; Coarse scroll the text... 8 color clocks.

	clc
	lda #2                     ; 16 color clocks is 2 characters.
	adc DL_LMS_SCROLL_DOCS     ; add to low byte of LMS
	sta DL_LMS_SCROLL_DOCS
	bcc b_mdv_EndDocsScrolling ; If there is carry
	inc DL_LMS_SCROLL_DOCS+1   ; incrememnt high byte of LMS

b_mdv_EndDocsScrolling


; ======== 6) MANAGE TERRAIN SCROLLING ========

; Scroll all four lines of terrain back and forth.
; All four move in the same direction/same speed.
; Pause for a few seconds at the end of a move.
; Then reverse directions.
; Rinse.  Repeat.

; b_mdv_DoLandScrolling

;	jsr Gfx_RunScrollingLand

; b_mdv_EndLandScrolling


; ======== MANAGE PLAYER MOVEMENT  ========

; The main code provided updates to player state for the New Y position.
; If the New Y does not match the old Player Y player then update Y.
; Redraw players only if something changed.
; Also, main code can flip on Redraw to force a redraw.

b_mdv_DoPlayerMovement

	jsr Pmg_ManagePlayerMovement

b_mdv_EndPlayerMovement


; ========  END OF TITLE SCREEN  ========

	jmp ExitMyDeferredVBI




; ====================  GAME SCREEN  ===================
; ======================================================

b_mdv_DoGameManagement

	lda zCurrentEvent         ; Get current state
	cmp #EVENT_GAME           ; Is it The Game?
	beq b_mdv_DoTheGame       ; Yes. Do the Game
	jmp b_mdv_DoGameOver      ; No. Check if doing  Game Over routine Greater Than > COUNTDOWN is GAME or GAMEOVER


b_mdv_DoTheGame
	lda #0
	sta zDLIStarLinecounter   ; reset DLI counter.

	sta zPLAYER_ONE_SHOT_THE_SHERIFF  ; Flag that this player did not shoot the mothership.
	sta zPLAYER_TWO_SHOT_THE_SHERIFF

	lda zLASER_ONE_X      ; Start VBI. Copy Laser 1 X to SHPOSP0
	sta SHPOSP0           ; Start VBI. Copy Laser 1 X to SHPOSP0
	lda zLASER_TWO_X      ; Start VBI. Copy Laser 2 X to SHPOSP1
	sta SHPOSP1           ; Start VBI. Copy Laser 2 X to SHPOSP1

	lda RANDOM                ; Set laser colors
	and #$F0
	ora #$0D
	sta COLPM0
	lda RANDOM              
	and #$F0
	ora #$0D
	sta COLPM1

	; Collect collisions.
	lda P0PL            ; GTIA collision register Player 0 (laser 1)...
	and #COLPMF2_BIT    ; Hit Player 2 (mothership)?
	sta zLASER_ONE_BANG ; Laser 1 collision with mothership (P0 to P2)
	lda P1PL            ; GTIA collision register Player 1 (laser 2)...
	and #COLPMF2_BIT    ; Hit Player 2 (mothership)?
	sta zLASER_TWO_BANG ; Laser 1 collision with mothership (P1 to P2)

	sta HITCLR          ; Always reset the P/M collision bits for next frame.


	jsr Gfx_ShowScreen   ; Forcing redraw of score now for test evidence

	jsr Gfx_RunGameStars ; Animate the flashing stars

	jsr Pmg_Draw_Mothership ; automatically increments Y until it is NEW_Y

	jsr Pmg_Draw_Lasers   ; draw lasers if present.

	jsr Pmg_ManagePlayerMovement  ;  Handles guns for Title and Game displays.



; ========  END OF GAME SCREEN  ========

	jmp ExitMyDeferredVBI




; ======== Manage InputScanFrames Delay Counter ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoManageInputClock
;	lda InputScanFrames          ; Is input delay already 0?
;	beq DoAnimateClock           ; Yes, do not decrement it again.
;	dec InputScanFrames          ; Minus 1.

; ======== Manage Main code's timer.  Decrement while non-zero. ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoAnimateClock
;	lda AnimateFrames            ; Is animation countdown already 0?
;	beq DoAnimateClock2          ; Yes, do not decrement now.
;	dec AnimateFrames            ; Minus 1

; ======== Manage Another Main code timer.  Decrement while non-zero. ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoAnimateClock2
;	lda AnimateFrames2           ; Is animation countdown already 0?
;	beq DoAnimateClock3          ; Yes, do not decrement now.
;	dec AnimateFrames2           ; Minus 1

; ======== Manage Another Main code timer.  Decrement while non-zero. ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoAnimateClock3
;	lda AnimateFrames3           ; Is animation countdown already 0?
;	beq DoAnimateClock4          ; Yes, do not decrement now.
;	dec AnimateFrames3           ; Minus 1

; ======== Manage Another Main code timer.  Decrement while non-zero. ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoAnimateClock4
;	lda AnimateFrames4           ; Is animation countdown already 0?
;	beq EndOfTimers              ; Yes, do not decrement now.
;	dec AnimateFrames4           ; Minus 1

EndOfTimers

; ======== Manage Frog Eyeball motion ========
; If the timer is non-zero, Change eyeball position and force redraw.
; This nicely multi-tasks the eyes to return to center even if MAIN is 
; is not doing anything related to the frog.

DoAnimateEyeballs
;	lda FrogRefocus              ; Is the eye move counter greater than 0?
;	beq EndOfClockChecks         ; No, Nothing else to do here.
;	dec FrogRefocus              ; Subtract 1.
;	bne EndOfClockChecks         ; Has not reached 0, so nothing left to do here.
;	lda FrogShape                ; Maybe the player raced the timer to the next screen...
;	cmp #SHAPE_FROG              ; ... so verify the frog is still displayable.
;	bne EndOfClockChecks         ; Not the frog, so do not animate eyes.
;	lda #1                       ; Inform the Frog renderer  
;	sta FrogEyeball              ; to use the default/centered eyeball.
;	sta FrogUpdate               ; and set mandatory redraw.

EndOfClockChecks


DoPromptColorchange
;	jsr ToggleButtonPrompt        ; Manipulates colors for prompt.






; =====================  GAME OVER  ====================
; ======================================================


b_mdv_DoGameOver

; animate text being dsiplayed.

; check for input to go to title.

	jsr Gfx_RunGameStars ; Animate the flashing stars



; ======================================================
; Something else, etc.  maybe.


; ========  END OF GAME OVER SCREEN  ========

	jmp ExitMyDeferredVBI                    ; Return to OS.





; ====================  END OF VBI  ====================
; ======================================================
; All the following run all the time on all displays.

ExitMyDeferredVBI

; ======== NEW SHADOW REGISTERS  ========
; The main line code will do the extra work of updating the P/M graphics
; to starting Horizontal position (these fake Shadow regs).
; The game relies on the DLIs to cut up Players/Missiles to their proper 
; horizontal positions.
; We could loop to copy these, but I don't want to burn through eight 
; more inc or dec, and branches.  So, do this as fast as possible.

;b_mdv_ReloadFromShadow

	lda SHPOSP0  ; VBI Copy SHPOSP0 to HPOSP0
	sta HPOSP0   ; VBI Copy SHPOSP0 to HPOSP0
	lda SHPOSP1  ; VBI Copy SHPOSP1 to HPOSP1
	sta HPOSP1   ; VBI Copy SHPOSP1 to HPOSP1
	lda SHPOSP2
	sta HPOSP2
	lda SHPOSP3
	sta HPOSP3
	lda SHPOSM0
	sta HPOSM0
	lda SHPOSM1
	sta HPOSM1
	lda SHPOSM2
	sta HPOSM2
	lda SHPOSM3
	sta HPOSM3


	jsr Gfx_RunScrollingLand


DoCheesySoundService              ; World's most inept sound sequencer.
	jsr SoundService

;	lda #$00
;	sta COLBK
	
	jmp XITVBV                    ; Return to OS.  SYSVBV for Immediate interrupt.







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

	pha

	; Set all the ANTIC screen controls and DMA options.
	lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NARROW]
	sta WSYNC            ; sync to end of scan line
	sta DMACTL

	mChainDLI TITLE_DLI_0,TITLE_DLI_1


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
	lda #[FIFTH_PLAYER|GTIA_MODE_16_SHADE|$01] 
	sta PRIOR

	mChainDLI TITLE_DLI_1,TITLE_DLI_2


;==============================================================================
; TITLE_DLI_2                                             
;==============================================================================
; DLI to game the VSCROL to hack mode F into 3 scan lines tall.  
; Runs VSCROL hacks on 3 pairs of Mode F lines for the title (six lines).
; Gruesome debugging cycle on this.  Could not get this to run as a couple
; smaller DLIs that repeat.  no matter what.  So, here one DLI bludgeons
; the  VSCROL and WSYNCs its way down the six extended mode F lines.
;
; At the same time, it is incrementing and reloading the COLPF3 value 
; for the Missiles/5th Player color overlay.   Each line is a different base
; color. In theory that's 4 grey shades + (6 lines * 4 shades) + background
; which is 29 colors possible on the logo.  In reality its probably closer
; to 18 to 20 given the shape of text v the overlay. 
; -----------------------------------------------------------------------------

TITLE_DLI_2

	 mStart_DLI ; Saves A and Y

;1
	ldy #14                        ; This will hack VSCROL for a 1 scan line mode into a 3 scan line mode
	lda #2
	sta WSYNC                      ; (1.0) sync to end of line.
	sta VSCROL                     ; =2, default. untrigger the hack if on for prior line.
;	nop
	sty VSCROL                     ; =14, 15, 0, trick it into 3 scan lines.
	jsr DLI_PF3_SYNC_INC_SYNC      ; (1.1 and 1.2 scan lines)

;2
	jsr DLI_SYNC_PF3_SYNC_INC_SYNC ; (2.0, 2.1 and 2.2 scan lines)

;3
	lda #2
	sta WSYNC                      ; (3.0) sync to end of line.
	sta VSCROL                     ; =2, default. untrigger the hack if on for prior line.
;	nop
	sty VSCROL                     ; =14, 15, 0, trick it into 3 scan lines.
	jsr DLI_PF3_SYNC_INC_SYNC      ; (3.1 and 3.2 scan lines)

;4
	jsr DLI_SYNC_PF3_SYNC_INC_SYNC ; (4.0, 4.1 and 4.2 scan lines)

;5
	lda #2
	sta WSYNC                      ; (5.0) sync to end of line.
	sta VSCROL                     ; =2, default. untrigger the hack if on for prior line.
;	nop
	sty VSCROL                     ; =14, 15, 0, trick it into 3 scan lines.
	jsr DLI_PF3_SYNC_INC_SYNC      ; (3.1 and 3.2 scan lines)

;6
	jsr DLI_SYNC_PF3_SYNC_INC_SYNC ; (6.0, 6.1 and 6.2 scan lines)

; FINISHED - Turn off the VSCROL hack, restore normal screen .

	lda #2
	ldy #0
	sta WSYNC                      ; (7.0) sync to end of scan line
	sta VSCROL                     ; =2, default. untrigger the hack.
	sty VSCROL

	ldy #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NORMAL]
	sty DMACTL                     ; Set all the ANTIC screen controls and DMA options.

	lda #[GTIA_MODE_DEFAULT|$01]       ; Return to normal color interpretation, Players on top.
	sta PRIOR

	pla
	tay

	mChainDLI TITLE_DLI_2,TITLE_DLI_3 ; Done here.  Finally go to next DLI.


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
	
	dey
	bpl b_dli4_LoopColors

	pla
	tay

	mChainDLI TITLE_DLI_4,TITLE_DLI_5 ; Done here.  Finally go to next DLI.


;==============================================================================
; TITLE_DLI_5                                             
;==============================================================================
; DLI to run the colors for the horizontally scrolling land.
; Fine scroll is already set, so, this just sets COLPF0, 1, 2.
; The color tables refereced are in gfx.asm.
; Note that this indexes TWICE and changes the colors at the 
; top of the line, and in the middle of the line of text.
; -----------------------------------------------------------------------------

TITLE_DLI_5

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

	mChainDLI TITLE_DLI_5,TITLE_DLI_6 ; Done here.  Finally go to next DLI.


;==============================================================================
; TITLE_DLI_6                                             
;==============================================================================
; Do the colors for the non-scrolling land under the mountains.
; Start the background from darkest dirt color and increment brighness.
; Start COLPF0 at a lighter tan and increment to lighter color at same speed.
; 
; At the end, reset colors for the bottom status line.
; -----------------------------------------------------------------------------


TITLE_DLI_6

	mStart_DLI ; Saves A and Y

	
	lda #[COLOR_ORANGE2|$4] ; ($24) Change COLPF1 to use as alternate ground color.
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
	; MUST ALSO remove the stats text when it is not needed -- when the guns are in 
	; the idle positions.
	
	sta WSYNC      ; Next scan line set the colors for the stats line of text. 
	sta COLBK      ; Background/border to black, too.
	sta COLPF2     ; Text background

	sty COLPM0
	ldy zPLAYER_TWO_COLOR
	sty COLPM1

	lda zSTATS_TEXT_COLOR
	sta COLPF1     ; Text luminance

;	lda #[GTIA_MODE_DEFAULT|$01] 
;	sta PRIOR

	pla
	tay


	mChainDLI TITLE_DLI_6,DoNothing_DLI ; Done here.  Park it until VBI restarts it.




;==============================================================================
;                                              DLI_(SYNC)_PF3_SYNC_INC_SYNC
;==============================================================================
; Title supporting routine used by DLI_2 to manage COLPF3 and consume a 
; couple scan lines of the display.
; This is moved into a function, because the same pattern is repeated 
; for each of the rows of pixels.
; There are two entry points.  The first adds an extra WSYNC at the start.
; -----------------------------------------------------------------------------

DLI_SYNC_PF3_SYNC_INC_SYNC 

	sta WSYNC               ; SYNC  (1.0) sync to end of line.

DLI_PF3_SYNC_INC_SYNC 

	lda zTitleLogoColor     ; PF3   Update color register.
	sta COLPF3
	sta WSYNC               ; SYNC  (1.1) sync to end of line.

	cmp #COLOR_ORANGE_GREEN ; INC   Is it the ending color?
	bne b_td2_AddToColor    ;       No. Add to the color component.

	lda #COLOR_ORANGE1      ;       Yes.  Reset to first color.
	bne b_td2_UpdateColor   ;       Go do the update.

b_td2_AddToColor
	clc
	adc #$10                ;       Add 16 to color.

b_td2_UpdateColor
	sta zTitleLogoColor     ;       Save it for the next DLI use

	sta WSYNC               ; SYNC  (1.2) sync to end of line.

	rts


;==============================================================================
;                                              DLI_SYNC_PF_DEC
;==============================================================================
; Title dupporting routine used by DLI_3 to manage COLPF0 and COLPF1 
; colors on the two scrolling author credits lines.
; -----------------------------------------------------------------------------

DLI_SYNC_PF_DEC

	sta WSYNC

DLI_PF_DEC

	stx COLPF0
	sty COLPF1
	dex
	dex
	dey
	dey

	rts


;==============================================================================
;                                              DLI_SYNC_PF0_DEC
;==============================================================================
; Title supporting routine used by DLI_4 to manage COLPF0 on the 
; scrolling documentation line.
; -----------------------------------------------------------------------------

DLI_SYNC_PF0_DEC

	sta WSYNC  

DLI_PF0_DEC

	sty COLPF0
	dey
	dey

	rts


	.align $0100

;==============================================================================
;                                              DLI_SYNC_PF0_DEC
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

	mStart_DLI ; Saves A and Y

	ldy zDLIStarLinecounter

	lda TABLE_GFX_STAR_HSCROL,y
	sta HSCROL

	inc zDLIStarLinecounter        ; (Note, VBI will zero this). 

;	sta WSYNC

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
;	lda #$52
;	sta COLBK
	mChainDLI GAME_DLI_0,TITLE_DLI_5 ; Do the land colors next.


b_GDLI0_NormalExit                ; Exit without changing the DLI vector.
;	lda #$02
;	sta COLBK

	pla
	tay
	pla

	rti



;==============================================================================

DoNothing_DLI ; In testing mode jump here to not do anything or to stop the DLI chain.
	 rti
