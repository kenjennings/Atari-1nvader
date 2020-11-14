;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
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
;ANIMATION_FRAMES .byte 25,21,17,14,12,11,10,9,8,7,6,5
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
	.word DoNothing_DLI ; 2  = EVENT_TITLE           run title and get player start button
	.word DoNothing_DLI ; 3  = EVENT_COUNTDOWN       then move mothership
	.word DoNothing_DLI ; 4  = EVENT_SETUP_GAME
	.word DoNothing_DLI ; 5  = EVENT_GAME            regular game play.  boom boom boom
	.word DoNothing_DLI ; 6  = EVENT_LAST_ROW        forced player shove off screen
	.word DoNothing_DLI ; 7  = EVENT_SETUP_GAMEOVER
	.word DoNothing_DLI ; 8  = EVENT_GAMEOVER        display text, then go to title


MyImmediateVBI

; ======== MANAGE CHANGING DISPLAY LIST ========
	lda zCurrentEvent                       ; Is the game at 0 (INIT)?
	beq ExitMyImmediateVBI                  ; Yes.  Then we should not be here.

	asl                                     ; State value times 2 for size of address
	tax                                     ; Use as index

	lda TABLE_GAME_DISPLAY_LIST,x           ; Copy Display List Pointer for the OS
	sta SDLSTL                              
	lda TABLE_GAME_DISPLAY_LIST_INTERRUPT,x ; Copy Display List Interrupt chain table starting address
	sta VDSLST
	sta 
	inx                                     ; and the high bytes.
	lda TABLE_GAME_DISPLAY_LIST,x
	sta SDLSTH
	lda TABLE_GAME_DISPLAY_LIST_INTERRUPT,x
	sta VDSLST+1


; ======== NEW SHADOW REGISTERS  ========
; The main line code will do the extra work of updating the P/M graphics
; to starting Horizontal position (these fake Shadow regs).
; The game relies on the DLIs to cut up Players/Missiles to their proper 
; horizontal positions.
; We could loop to copy these, but I don't want to burn through eight 
; more inc or dec, and branches.  So, do this as fast as possible.

b_mdv_ReloadFromShadow

	lda SHPOSP0
	sta HPOSP0
	lda SHPOSP1
	sta HPOSP1
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

	lda zCurrentEvent           ; Is this is stil 0 (INIT)? 
	bne b_mdv_DoMyDeferredVBI   ; No.   Continue the Deferred VBI
	jmp ExitMyDeferredVBI       ; Yes.  We should not be here.  End now.


b_mdv_DoMyDeferredVBI

; ======== Manage Frog Death  ========
; Here we are at the end of the frame.  Collision is checked first.  
; The actual movement processing happens last.
; If the CURRENT row of the frog is on a moving boat row, then go collect 
; the collision information with the "safe" area of the boat 
; (the horizontal lines, COLPF2 are the safety color).
; "Current" from the VBI point of view means the last place the frog was 
; displayed on the previous frame.  ("New" is where the frog will be 
; displayed on the next frame.)
; The collision check code will flag the death accordingly.
; The Flag-Of-Death (FrogSafety) tells the Main code to splatter the frog 
; shape, and start the other activities to announce death.

;	lda CurrentDL                ; Get current display list
;	cmp #DISPLAY_GAME            ; Is this the Game display?
;	bne EndOfDeathOfASalesfrog   ; No. So no collision processing. 

;	ldx FrogRow                  ; What screen row is the frog currently on?
;	lda MOVING_ROW_STATES,x      ; Is the current Row a boat row?
;	beq EndOfDeathOfASalesfrog   ; No. So skip collision processing. 

;	jsr CheckRideTheBoat         ; Make sure the frog is riding the boat. Otherwise it dies.

;	jsr Something that evaluates collisions goes here.

;EndOfDeathOfASalesfrog
	sta HITCLR                   ; Always reset the P/M collision bits for next frame.




; ======== TITLE SCREEN AND COUNTDOWN ACTIVIES  ========
	lda zCurrentEvent               ; Get current state
	cmp #[EVENT_COUNTDOWN+1]        ; Is it TITLE or COUNTDOWN
	bcc b_mdv_DoTitleAnimation      ; Yes. Less Than < is correct
	jmp b_mdv_DoGameManagement      ; No. Greater Than > COUNTDOWN is GAME or GAMEOVER


; For the Title and Countdown the work that needs to occur:
; 1) Mothership if moving up.
; 2) 3, 2, 1 GO, if in progress.
; 3) Animate Missiles for Title logo
; 4) Author scrolling
; 5) Documentation Scrolling
; 6) Mountain Background Scrolling.


; ======== MANAGE TITLE MOTHERSHIP MOVING UP  ========




; ======== MANAGE COUNTDOWN ANIMATION  ========




; ======== MANAGE TITLE COLOR ANIMATION ========

; The Missile positions need to be managed for the 
; color overlay on the title graphic.   

b_mdv_DoTitleAnimation 

; Animate the Title graphics (gfx pixels)
	lda #6                       ; The number of times to call the color change DLI for the logo
	sta zTitleVSCHacks           ; Update the counter read by the DLI.

	dec zAnimateTitleGfx         ; decrement countown clock
	bne b_mdv_SkipTitleGfx      ; has not reached 0, then no work to do. 

	jsr Gfx_Animate_Title_Logo   ; Updates the display list LMS to point to new pixels.

b_mdv_SkipTitleGfx

; Setup specs to change the Title graphincs (Missile animation.)  Main code draws Missiles.

	dec zAnimateTitlePM
	bne b_mdv_SkipTitleMissileUpdate
	
	; Note that the main code is responsible for loading up the Missile image.  
	; THEREFORE, do not reset the timer for the Missile animation here.  
	; The main code will do it, because it needs to know that the timer reached 0.

	; first update the color information
	dec zTitleLogoBaseTries      ; reduce base counter by 1.
	lda zTitleLogoBaseTries      
	sta zTitleLogoTries          ; Save it for the DLI use
	bne b_mdv_SkipColorMovement  ; Value still not 0, no color changes

	lda #3                       ; Change it to new count.
	sta zTitleLogoBaseTries      ; Resave the new update
	sta zTitleLogoTries          ; Save it for the DLI use

	lda ZTitleLogoBaseColor      ; Get the Base color
	cmp #COLOR_ORANGE_GREEN      ; Is it the ending color?
	bne b_mdv_AddToColor         ; No.  Add to the color component.

	lda #COLOR_ORANGE1           ; Yes.  Reset to first color.
	bne b_mdv_UpdateColor        ; Go do the update.

b_mdv_AddToColor
	clc
	adc #$10                     ; Add 16 to color.

b_mdv_UpdateColor
	sta ZTitleLogoBaseColor      ; Resave the new update
	sta ZTitleLogoColor          ; Save it for the DLI use

b_mdv_SkipColorMovement

	; Now, change the Missile animation images and position.

	ldx ZTitleHPos              ; Move horizontally left two color clocks per animation.
	dex
	dex

	ldy zTitleLogoPMFrame       ; Go to the next Missile image index
	iny
	cpy #TITLE_LOGO_PMIMAGE_MAX ; Did it go past the last frame?
	bne b_mdv_SkipResetPMImage  ; No.  Do not reset Missile image index.

	ldx #TITLE_LOGO_X_START     ; Reset horizontal position to the start
	ldy #0                      ; Reset missile image index to start.

b_mdv_SkipResetPMImage
	stx ZTitleHPos              ; Save modified base Missile pos, whatever happened above.
	sty zTitleLogoPMFrame       ; Save new Missile image index.

	jsr Pmg_AdustMissileHPOS    ; Update  the missile HPOS.

b_mdv_SkipTitleMissileUpdate

b_mdv_DoGameManagement




; ======== Manage Boat fine scrolling ========
; Atari scrolling is such low overhead. 
; (Evaluate frog shift if it is on a boat row).
; On a boat row...
; Update a fine scroll register.
; Update a coarse scroll register sometimes.
; Done.   
; Scrolling is practically free.  
; It may be easier only on an Amiga.

ManageBoatScrolling
;	lda CurrentDL                 ; Get current display list
;	cmp #DISPLAY_GAME             ; Is this the Game display?
;	bne EndOfBoatScrolling        ; No.  Skip the scrolling logic.

;	ldy #1                        ; Current Row.  Row 0 is the safe zone, no scrolling happens there.

; Common code to each row. 
; Loop through rows.
; If is is a moving row, then check the row's timer/frame counter.
; If the timer is over, then reset the timer, and then fine scroll 
; the row (also moving the frog with it as needed.)

LoopBoatScrolling
	; Need row in X and Y due to different 6502 addressing modes in the timer and scroll functions.
;	tya                           ; A = Y, Current Row 
;	tax                           ; X = A, Current Row.  Can't dec zeropage,x, darn you cpu.

;	lda MOVING_ROW_STATES,y       ; Get the current Row State
;	beq EndOfScrollLoop           ; Not a scrolling row.  Go to next row.
;	php                           ; Save the + or - status until later.
	; We know this is either left or right, so this block is common code
	; to update the row's speed counter based on the row entry.
;	lda CurrentBoatFrames,x       ; Get the row's frame delay value.
;	beq ResetBoatFrames           ; If BoatFrames is 0, time to make the donuts.
;	dec CurrentBoatFrames,x       ; Not zero, so decrement
;	plp                           ; oops.  got to dispose of that.
;	jmp EndOfScrollLoop           

ResetBoatFrames
;	lda (BoatFramesPointer),y     ; Get master value for row's frame delay
;	sta CurrentBoatFrames,x       ; Restart the row's frame speed delay.

;	plp                           ; Get the current Row State (again.)
;	bmi LeftBoatScroll            ; 0 already bypassed.  1 = Right, -1 (FF) = Left.

;	jsr RightBoatFineScrolling    ; Do Right Boat Fine Scrolling.  (and frog X update) 
;	jmp EndOfScrollLoop           ; end of this row.  go to the next one.

LeftBoatScroll
;	jsr LeftBoatFineScrolling     ; Do Left Boat Fine Scrolling.  (and frog X update) 

EndOfScrollLoop                   ; end of this row.  go to the next one.
;	iny                           ; Y reliably has Row.  X was changed.
;	cpy #18                       ; Last entry is beach.  Do not bother to go further.
;	bne LoopBoatScrolling         ; Not 18.  Process the next row.

EndOfBoatScrolling


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


; ======== Reposition the Frog (or Splat). ========
; At this point everyone and their cousin have been giving their advice 
; about the frog position.  The main code changed position based on joystick
; input.  The VBI change position if the frog was on a scrolling boat row.
; Here, finally apply the position and move the frog image.

MaintainFrogliness
;	lda FrogUpdate               ; Nonzero means something important needs to be updated.
;	bne SimplyUpdatePosition

;	lda FrogNewShape             ; Get the new frog shape.
;	beq NoFrogUpdate             ; 0 is off, so no movement there at all, so skip all

; ==== Frog and boat position gyrations are done.  ==== Is there actual movement?
SimplyUpdatePosition
;	jsr ProcessNewShapePosition  ; limit object to screen.  redraw the object.

NoFrogUpdate


; ======== Fade Score Label Text  ========
; Game will brighten text label when changing a value.
; Here we detect if a change needs to be made, and then 
; decrement the color if so.  All colors end at luminance
; value $04.  Luminance $00 means no further consideration.

ManageScoredFades
;	ldx CurrentDL
;	lda MANAGE_SCORE_COLORS_TABLE,x
;	beq EndManageScoreFades

DoFadeScore
;	lda COLPM0_TABLE       ; Get Color.
;	jsr DecThisColorOrNot  ; Can it be decremented?
;	sta COLPM0_TABLE       ; Re-Save Color
;	sta COLPM1_TABLE       ; Second half of the same object is same color

DoFadeHiScore
;	lda COLPM2_TABLE       ; Get Color.
;	jsr DecThisColorOrNot  ; Can it be decremented?
;	sta COLPM2_TABLE       ; Re-Save Color 

DoFadeLives
;	lda MANAGE_LIVES_COLORS_TABLE,x ; Is this a thing to do on this display.
;	beq EndManageScoreFades

;	lda COLPM0_TABLE+1     ; Get Color.
;	jsr DecThisColorOrNot  ; Can it be decremented?
;	sta COLPM0_TABLE+1     ; Re-Save Color
;	sta COLPM1_TABLE+1     ; Second half of the same object is same color

DoFadeSaved
;	lda COLPM2_TABLE+1     ; Get Color.
;	jsr DecThisColorOrNot  ; Can it be decremented?
;	sta COLPM2_TABLE+1     ; Re-Save Color
;	sta COLPM3_TABLE+1     ; Second half of the same object is same color

EndManageScoreFades


; ======== Manage Title Graphics Fine Scrolling  ========
; Left Scroll the title graphics.
; When it reaches target location reset the flag to disable scrolling.
; Set the timer to tell MAIN to restore the title.
; If the timer is non-zero, then decrement it.
;
; MAIN is expected to setup buffers and reset scroll position to 
; origin before setting  VBIEnableScrollTitle  to start scrolling.

ManageTitleScrolling
;	lda VBIEnableScrollTitle     ; Is scrolling turned on?
;	beq WaitToRestoreTitle       ; No. See if the timer needs something.

;	jsr TitleLeftScroll          ; Scroll it
;	jsr TitleIsItAtTheEnd        ; Is it done?  Zero return is over.
;	bne EndManageTitleScrolling  ; Nope.  Do again on the next frame.

;	lda #0                       ; Reached target position.
;	sta VBIEnableScrollTitle     ; Turn off further left scrolling.
;	lda #TITLE_RETURN_WAIT       ; Set the timer to wait to restore the title.
;	sta RestoreTitleTimer        ; Set new timeout value.

WaitToRestoreTitle               ; Tell Main when to restore title.
;	lda RestoreTitleTimer        ; Get timer value.
;	beq EndManageTitleScrolling  ; Its 0?  Then skip this.
;	dec RestoreTitleTimer        ; Decrement timer when non-zero.

EndManageTitleScrolling


; ======== Animate Boat Components ========
; Parts of the boats are animated to look like they're moving 
; through the water.
; When BoatyMcBoatCounter is 0, then animate based on BoatyComponent
; thus only one part of a boat is animated on any given vertical blank.
; 0 = Right Boat Front
; 1 = Right Boat Back
; 2 = Left Boat Front
; 3 = Left Boat Back
;BoatyFrame         .byte 0  ; counts 0 to 7.
;BoatyMcBoatCounter .byte 2  ; decrement.  On 0 animate a component.
;BoatyComponent     .byte 0  ; 0, 1, 2, 3 one of the four boat parts.

ManageBoatAnimations
;	dec BoatyMcBoatCounter        ; subtract from scroll delay counter
;	bne ExitBoatyness             ; Not 0 yet, so no animation.

	; One of the boat components will be animated. 
;	lda #2                        ; Reset counter to original value.
;	sta BoatyMcBoatCounter

;	ldx BoatyFrame                ; going to load a frame, which one?
;	jsr DoBoatCharacterAnimation  ; load the frame for the current component.

; Finish by setting up for next frame/component.
;	inc BoatyComponent            ; increment to next visual component for next time.
;	lda BoatyComponent            ; get it to mask it 
;	and #$03                      ; mask it to value 0 to 3
;	sta BoatyComponent            ; Save it.
;	bne ExitBoatyness             ; it is non-zero, so no new frame counter.

; Whenever the boat component returns to 0, then update the frame counter...
;	inc BoatyFrame                ; next frame.
;	lda BoatyFrame                ; get it to mask it.
;	and #$07                      ; mask it to 0 to 7
;	sta BoatyFrame                ; save it.

ExitBoatyness


; ======== Manage the prompt flashing for Press A Button ========
ManagePressAButtonPrompt
;	lda EnablePressAButton
;	bne DoAnimateButtonTimer      ; Not zero means enabled.
;	; Prompt is off.  Zero everything.
;	sta PressAButtonColor         ; Set background
;	sta PressAButtonText          ; Set text.
;	sta PressAButtonFrames        ; This makes sure it will restart as soon as enabled.
;	beq DoCheesySoundService  

; Note that the Enable/Disable behavior connected to the timer mechanism 
; means that the action will occur when this timer executes with value 1 
; or 0. At 1 it will be decremented to become 0. The value 0 is evaluated 
; immediately.
DoAnimateButtonTimer
;	lda PressAButtonFrames   
;	beq DoPromptColorchange       ; Timer is Zero.  Go switch colors.
;	dec PressAButtonFrames        ; Minus 1
;	bne DoCheesySoundService      ; if it is still non-zero end this section.

DoPromptColorchange
;	jsr ToggleButtonPrompt        ; Manipulates colors for prompt.

DoCheesySoundService              ; World's most inept sound sequencer.
	jsr SoundService


; ======== Manage scrolling the Credits text ========
ScrollTheCreditLine               ; Scroll the text identifying the perpetrators
;	dec ScrollCounter             ; subtract from scroll delay counter
;	bne EndOfScrollTheCredits     ; Not 0 yet, so no scrolling.
;	lda #2                        ; Reset counter to original value.
;	sta ScrollCounter

;	jsr FineScrollTheCreditLine   ; Do the business.

EndOfScrollTheCredits


ExitMyDeferredVBI

	jmp XITVBV                    ; Return to OS.  SYSVBV for Immediate interrupt.


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
		 mregSaveAY

		 ldy ThisDLI
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
; TITLE_DLI_1                                             
;==============================================================================
; DLI to set Narrow screen DMA, and turn on GTIA mode 16 grey scale mode.
; -----------------------------------------------------------------------------

TITLE_DLI_1 

	 pha

	; Setup PRIOR for 16 grey-scale graphics, and Missile color overlay.
	; The screen won;t show any noticeable change here, because the COLBK 
	; value is black, and this won;t change for the 16-shade mode.
	lda #[FIFTH_PLAYER|GTIA_MODE_16_SHADE] 
	sta PRIOR

	; Set all the ANTIC screen controls and DMA options.
	lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NARROW]
	sta WSYNC            ; sync to end of scan line
	sta DMACTL

	mChainDLI TITLE_DLI_1,TITLE_DLI_2


;==============================================================================
; TITLE_DLI_2                                             
;==============================================================================
; DLI to game the VSCROL to hack mode F into 3 scan lines tall.  
; Runs six times for title.
; -----------------------------------------------------------------------------

TITLE_DLI_2

	 mStart_DLI ; Saves A and Y

	ldy #14             ; This will hack VSCROL for a 1 scan line mode into a 3 scan line mode
	lda #1
	sta WSYNC           ; sync to end of line.
	sta VSCROL          ; =1, default. untrigger the hack if on for prior line.
	sty VSCROL          ; =14, 15, 0, trick it into 3 scan lines.

	lda ZTitleLogoColor ; Set new color overlay value
	sta COLPF3          ; Player 5, (Missile) color.

	; Now, everything else is liesurely-like maintenance.  
	; We have 2 scan lines to get the variables in order.

	dec zTitleLogoTries          ; count 3, 2, 1, 0
	bne b_td2_SkipTryReset
	lda #3
	sta zTitleLogoTries

	lda ZTitleLogoColor     ; Get the Base color
	cmp #COLOR_ORANGE_GREEN ; Is it the ending color?
	bne b_td2_AddToColor    ; No.  Add to the color component.

	lda #COLOR_ORANGE1      ; Yes.  Reset to first color.
	bne b_td2_UpdateColor   ; Go do the update.

b_td2_AddToColor
	clc
	adc #$10                ; Add 16 to color.

b_td2_UpdateColor
	sta ZTitleLogoColor     ; Save it for the next DLI use

b_td2_SkipTryReset
	dec zTitleVSCHacks      ; Count the number of times we've been here.
	beq b_td2_ExitToChain   ; If not zero then just exit to repeat this DLI..

	pla                     ; Exit DLI without chaining, making this repeat.
	tay
	pla

	rti

b_td2_ExitToChain
	mChainDLI TITLE_DLI_2,TITLE_DLI_3 ; Done here.  Finally go to next DLI.


;==============================================================================
; TITLE_DLI_3                                             
;==============================================================================
; DLI to stop the VSCROL hack, restore the normal DMA width and turn off 
; the GTIA 16-grey scale value.
; Also, reset 
; -----------------------------------------------------------------------------

TITLE_DLI_3

	 mStart_DLI ; Saves A and Y

	lda #0
	ldy #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NORMAL]
	sta WSYNC           ; sync to end of scan line
	sta VSCROL          ; =0, default. untrigger the hack if on for prior line.

	; Set all the ANTIC screen controls and DMA options.
	sty DMACTL

	; Return to normal color interpretation.
	lda #[GTIA_MODE_DEFAULT] 
	sta PRIOR

	mChainDLI TITLE_DLI_3,DoNothing_DLI




; ;==============================================================================
; ; TITLE_DLI_BLACKOUT                                             
; ;==============================================================================
; ; DLI Sets background to Black for blank areas.
; ;
; ; Note that the Title screen uses the COLBK table for both COLBK and COLPF2.
; ; -----------------------------------------------------------------------------

; TITLE_DLI_BLACKOUT  ; DLI Sets background to Black for blank area.

	; pha

	; lda #COLOR_BLACK     ; Black for background and text background.
	; sta WSYNC            ; sync to end of scan line
	; sta COLBK            ; Write new border color.
	; sta COLPF2           ; Write new background color

	; tya
	; pha
	; ldy ThisDLI

	; jmp SetupAllOnNextLine_DLI ; Load colors for next DLI and end.


; ;==============================================================================
; ; TITLE_DLI_TEXTBLOCK                                             
; ;==============================================================================
; ; DLI sets COLPF1 text luminance from the table, COLBK and COLPF2 to 
; ; start a text block.
; ; Since there is no text in blank lines, it does not matter that COLPF1 is 
; ; written before WSYNC.
; ; Also, since text characters are not defined to the top/bottom edge of the 
; ; character it is  safe to change COLPF1 in a sloppy way.
; ; -----------------------------------------------------------------------------

; TITLE_DLI_TEXTBLOCK

	; mStart_DLI

	; lda ColorPf1         ; Get text luminance from zero page.
	; sta COLPF1           ; write new text luminance.

	; lda ColorBak         ; Get background from zero page.
	; sta WSYNC
	; sta COLBK
	; sta COLPF2

	; jmp SetupAllOnNextLine_DLI ; Load colors for next DLI and end.


; ;==============================================================================
; ; GAME DLIs
; ;==============================================================================

; ;==============================================================================
; ; SCORE 1 DLI                                                            A 
; ;==============================================================================
; ; Used on Game displays.  
; ; This is called on a blank before the text line. 
; ; The VBI should have loaded up the Page zero staged colors. 
; ; Only ColorPF1 matters for the playfield as the background and border will 
; ; be forced to black. 
; ; This also sets Player/Missile parameters for P0,P1,P2, M0 and M1 to show 
; ; the "Score" and "Hi" text.
; ; Since all of this takes place in the blank space then it does not 
; ; matter that there is no WSYNC.  
; ; -----------------------------------------------------------------------------

; Score1_DLI

	; mStart_DLI

	; lda ColorPF1         ; Get text color (luminance)
	; sta COLPF1           ; write new text color.

	; lda #COLOR_BLACK     ; Black for background and text background.
	; sta COLBK            ; Write new border color.
	; sta COLPF2           ; Write new background color

	; jsr LoadPMSpecs0     ; Load the first table entry into PM registers

; ; Finish by loading the next DLI's colors.  The second score line preps the Beach.
; ; This is redundant (useless) (time-wasting) work when not on the game display, 
; ; but this is also not damaging.

	; jmp SetupAllOnNextLine_DLI ; Load colors for next DLI and end.


; ;==============================================================================
; ; SCORE 2 DLI                                                            A 
; ;==============================================================================
; ; Used on Game displays.  
; ; This is called on a blank before the text line. 
; ; The VBI should have loaded up the Page zero staged colors. 
; ; Only ColorPF1 matters for the playfield as the background and border will 
; ; be forced to black. 
; ; This also sets Player/Missile parameters for P0,P1,P2, M0 and M1 to show 
; ; the "Frogs" and "Saved" text.
; ; Since all of this takes place in the blank space then it does not 
; ; matter that there is no WSYNC.  
; ; -----------------------------------------------------------------------------

; Score2_DLI

	; mStart_DLI

	; lda ColorPF1         ; Get text color (luminance)
	; sta COLPF1           ; write new text color.

	; jsr LoadPMSpecs1     ; Load the first table entry into PM registers

	; ; Load HSCROL for the Title display. It should be non-impacting on other displays.
	; lda TitleHSCROL      ; Get Title fine scrolling value.
	; sta HSCROL           ; Set fine scrolling.

; ; Finish by loading the next DLI's colors.  The second score line preps the Beach.
; ; This is redundant (useless) (time-wasting) work when not on the game display, 
; ; but this is also not damaging.

	; jmp SetupAllOnNextLine_DLI ; Load colors for next DLI and end.


; ;==============================================================================
; ; GAME_DLI_BEACH0                                               
; ;==============================================================================
; ; BEACH 0
; ; Sets COLPF0,1,2,3,BK for the first Beach line. 
; ; This is a little different from the other transitions to Beaches.  
; ; Here, ALL colors must be set. 
; ; In the later transitions from Boats to the Beach COLPF0 should 
; ; be setup as the same color as in the previous line of boats.
; ; COLBAK is temporarily set to the value of COLPF0 to make a full
; ; scan line of "sky" color matching the COLPF0 sky color for the 
; ; beach line that follows.
; ; COLBAK's real land color is set last as it is the color used in the 
; ; lower part of the beach characters.
; ; -----------------------------------------------------------------------------

; GAME_DLI_BEACH0 

	; pha   	; custom startup to deal with a possible timing problem.

	; jsr LoadPmSpecs2 ; Copy all entries from column 2 to PM registers 
	
	; sta HITCLR       ; Because this is the one and only time this DLI is called.

	; lda ColorPF0 ; from Page 0.
	; sta WSYNC
	; ; Top of the line is sky or blue water from row above. 
	; ; Make background temporarily match the playfield drawn on the next line.
	; sta COLBK
	; sta COLPF0

	; tya
	; pha
	; ldy ThisDLI
	; sty WSYNC

	; jmp LoadAlmostAllColors_DLI


; ;==============================================================================
; ; GAME_DLI_BEACH2BOAT 
; ; GAME_DLI_BOAT2BOAT                                                 
; ;==============================================================================
; ; After much hackery, code gymnastics, and refactoring, these two 
; ; routines for boats now work out to the same code.
; ;
; ; Boats Right 1, 4, 7, 10 . . . .
; ; Sets colors for the Boat lines coming from a Beach line.
; ; This starts on the Beach line which is followed by one blank scan line 
; ; before the Right Boats.
; ;
; ; Boats Left 2, 5, 8, 11 . . . .
; ; Sets colors for the Left Boat lines coming from a Right Boat line.
; ; This starts on the ModeC line which is followed by one blank scan line 
; ; before the Left Boats.
; ; The Mode C line uses only COLPF0 to match the previous water, and the 
; ; following "sky".
; ; Therefore, the color of the line is automatically matched to both prior and 
; ; the next lines without changing COLPF0.  (For the fading purpose COLPF0
; ; does need to get reset on the following blank line. 
; ; HSCROL is set early for the boats.  Followed by all color registers.
; ; -----------------------------------------------------------------------------

; GAME_DLI_BEACH2BOAT ; DLI sets HS, BK, COLPF3,2,1,0 for the Right Boats.
; GAME_DLI_BOAT2BOAT  ; DLI sets HS, BK, COLPF3,2,1,0 for the Left Boats.

	; mStart_DLI

	; lda NextHSCROL    ; Get boat fine scroll.
	; pha

	; lda ColorBak
	; sta WSYNC
	; sta COLBK

	; pla 
	; sta HSCROL        ; Ok to set now as this line does not scroll.

	; jmp LoadAlmostAllBoatColors_DLI ; set colors.  then setup next row.


; ;==============================================================================
; ; GAME_DLI_BOAT2BEACH                                                     
; ;==============================================================================
; ; BEACH 3, 6, 9, 12 . . . .
; ; Sets colors for the Beach lines coming from a boat line. 
; ; This is different from line 0, because the DLI starts with only one scan 
; ; line of Mode C pixels (COLPF0) between the boats, and the Beach.
; ; The Mode C line uses COLPF0 to match the previous water, with the 
; ; following "sky".
; ; Therefore, the color of the line is automatically matched to both prior and 
; ; the next lines without changing COLPF0.  (For the fading purpose it does 
; ; need to get set. )
; ; Since the beam is in the middle of an already matching color this routine 
; ; can operate without WSYNC up front to set all the color registers as quickly 
; ; as possible. 
; ; COLBAK can be re-set to its beach color last as it is the color used in the 
; ; lower part of the characters.
; ; -----------------------------------------------------------------------------

; GAME_DLI_BOAT2BEACH ; DLI sets COLPF1,2,3,COLPF0, BK for the Beach.

	; mStart_DLI

	; lda ColorPF0 ; from Page 0.
	; ; Different from BEACH0, because no WSYNC right here.
	; ; Top of the line is sky or blue water from row above.   
	; ; Make background temporarily match the playfield drawn on the next line.
	; sta COLBK
	; sta COLPF0

	; jmp LoadAlmostAllColors_DLI


; ;==============================================================================
; ; SPLASH DLIs
; ;==============================================================================

; ;==============================================================================
; ; COLPF0_COLBK_DLI                                                     A
; ;==============================================================================
; ; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; ; same display list structure and DLIs.  
; ; Sets background color and the COLPF0 pixel color.  
; ; Table driven.  
; ; Perfectly re-usable for anywhere Map Mode 9 or Blank instructions are 
; ; being managed.  In the case of blank lines you just don't see the pixel 
; ; color change, so it does not matter what is in the COLPF0 color table. 
; ; -----------------------------------------------------------------------------

; COLPF0_COLBK_DLI

	; jmp DO_COLPF0_COLBK_DLI


; ;==============================================================================
; ; SPLASH_PMGZERO_DLI                                                     A
; ;==============================================================================
; ; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; ; same display list structure and DLIs.  
; ;
; ; This first DLI on the title screen needs to do extra work on the 
; ; player/missiles to remove all the "text" labels from the screen.
; ; -----------------------------------------------------------------------------

; SPLASH_PMGZERO_DLI

	; jmp DO_SPLASH_PMGZERO_DLI


; ;==============================================================================
; ; SPLASH PMGSPECS2 DLI                                                  A
; ;==============================================================================
; ; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; ; same display list structure and DLIs.  
; ; Sets background color and the COLPF0 pixel color.
; ;
; ; Table driven.  
; ; Perfectly re-usable for anywhere Map Mode 9 or Blank instructions are 
; ; being managed.  In the case of blank lines you just don't see the pixel 
; ; color change, so it does not matter what is in the COLPF0 color table. 
; ;
; ; The first DLI on the title screen needs to do extra work 
; ; on the player/missile data, so I needed another DLI here.
; ; -----------------------------------------------------------------------------

; SPLASH_PMGSPECS2_DLI

	; jmp DO_SPLASH_PMGSPECS2_DLI ; DO_COLPF0_COLBK_TITLE_DLI


; ;==============================================================================
; ; EXIT DLI.
; ;==============================================================================
; ; Common code called/jumped to by most DLIs.
; ; JMP here is 3 byte instruction to execute 11 bytes of common DLI closure.
; ; Update the interrupt pointer to the address of the next DLI.
; ; Increment the DLI counter used to index the various tables.
; ; Restore registers and exit.
; ; -----------------------------------------------------------------------------

; Exit_DLI

	; lda (ThisDLIAddr), y ; update low byte for next chained DLI.
	; sta VDSLST

	; inc ThisDLI          ; next DLI.

	; mRegRestoreAY

DoNothing_DLI ; In testing mode jump here to not do anything or to stop the DLI chain.
	 rti


; ;==============================================================================
; ; DLI_SPC1                                                            A 
; ;==============================================================================
; ; DLI to set colors for the Prompt line.  
; ; And while we're here do the HSCROLL for the scrolling credits.
; ; Then link to DLI_SPC2 to set colors for the scrolling line.
; ; Since there is no text here (running in blank line), it does not matter 
; ; that COLPF1 is written before WSYNC.
; ; -----------------------------------------------------------------------------

; DLI_SPC1  ; DLI sets COLPF1, COLPF2, COLBK for Prompt text. 

	; pha                   ; aka pha

	; lda PressAButtonText  ; Get text color (luminance)
	; sta COLPF1            ; write new text luminance.

	; lda PressAButtonColor ; For background and text background.
	; sta WSYNC             ; sync to end of scan line
	; sta COLBK             ; Write new border color.
	; sta COLPF2            ; Write new background color

	; ; Overriding the table-driven addresses now to go to DLI_SPC2
	; lda #<DLI_SPC2        ; Update the DLI vector for the last routine for credit color.
	; sta VDSLST
	; lda #>DLI_SPC2        ; Update the DLI vector for the last routine for credit color.
	; sta VDSLST+1

	; pla                   ; aka pla

	; rti


; ;==============================================================================
; ; DLI_SPC2                                                            A  Y
; ;==============================================================================
; ; DLI to set colors for the Scrolling credits.   
; ; ALWAYS the last DLI on screen.
; ; Squeezing screen geometry eliminated a blank line here, so the 
; ; lazy way HSCROL was set no longer works and causes bizarre 
; ; corruption at the bottom of the screen.  The routine needed to be 
; ; optimized to avoid overhead and set HSCROL as soon as possible. 
; ; -----------------------------------------------------------------------------

; DLI_SPC2  ; DLI sets black for background COLBK, COLPF2, and text luminance for scrolling text.

	; pha

	; lda CreditHSCROL     ; HScroll for credits.
	; sta HSCROL

	; lda #COLOR_BLACK     ; color for background.
	; sta WSYNC            ; sync to end of scan line
	; sta COLBK            ; Write new border color.
	; sta COLPF2           ; Write new background color

	; lda #$0C             ; luminance for text.  Hardcoded.  Always visible on all screens.
	; sta COLPF1           ; Write text luminance for credits.

	; lda #<DoNothing_DLI  ; Stop DLI Chain.  VBI will restart the chain.
	; sta VDSLST
	; lda #>DoNothing_DLI
	; sta VDSLST+1

	; pla 

	; rti


; ;==============================================================================
; ; LOAD COLORS -- Common targets JMP'd here from other places.
; ;==============================================================================
; ; LOAD ALL COLORS_DLI             - load PF0, then BAK, PF1, PF2, PF3.
; ; LOAD ALMOST ALL COLORS_DLI      - load BAK, PF1, PF2, PF3 (not PF0).
; ; SETUP ALL ON NEXT LINE_DLI      - increment line index, then prep colors for 
; ;                                   the next DLI.
; ; SETUP ALL COLORS_DLI            - prep colors for DLI based on current line 
; ;                                   index.
; ; LOAD ALMOST ALL BOAT COLORS_DLI - load PF0, PF1, PF2, PF3 from Page zero.
; ;
; ; Common code called/jumped to by DLIs.
; ; JMP here is 3 byte instruction to execute 11 bytes of common DLI closure.
; ; Load the staged values, store in the color registers.
; ; -----------------------------------------------------------------------------

; LoadAlmostAllColors_DLI

	; lda ColorBak   ; Get real background color again. (To repair the color for the Beach background)
	; sta WSYNC
	; sta COLBK

	; lda ColorPF1   ; Get color Rocks 2
	; sta COLPF1
	; lda ColorPF2   ; Get color Rocks 3 
	; sta COLPF2
	; lda ColorPF3   ; Get color water (needed for fade-in)
	; sta COLPF3


; SetupAllOnNextLine_DLI

	; iny

	; jsr SetupAllColors

	; dey

	; jmp Exit_DLI


; ; Called by Beach 2 Boat
; LoadAlmostAllBoatColors_DLI

	; lda ColorPF1   
	; sta COLPF1
	; lda ColorPF2   
	; sta COLPF2
	; lda ColorPF3   
	; sta COLPF3
	; lda ColorPF0 
	; sta COLPF0

	; jmp SetupAllOnNextLine_DLI


; ;==============================================================================
; ; SET UP ALL COLORS                                                       A  Y
; ;==============================================================================
; ; Given value of Y, pull that entry from the color and scroll tables
; ; and store in the page 0 copies.
; ; This is called at the end of a DLI to prepare for the next DLI in an attempt
; ; to optimize the start of the next DLI's using the values.  
; ; (Because for some reason Altirra is glitching the game screen, but 
; ; Atari800 seems OK.)
; ; -----------------------------------------------------------------------------

; SetupAllColors

	; lda COLPF0_TABLE,y   ; Get color Rocks 1   
	; sta ColorPF0
	; lda COLPF1_TABLE,y   ; Get color Rocks 2
	; sta ColorPF1
	; lda COLPF2_TABLE,y   ; Get color Rocks 3 
	; sta ColorPF2
	; lda COLPF3_TABLE,y   ; Get color water (needed for fade-in)
	; sta ColorPF3
	; lda HSCROL_TABLE,y   ; Get boat fine scroll.
	; sta NextHSCROL
	; lda COLBK_TABLE,y    ; Get background color .
	; sta ColorBak

	; rts


; ;==============================================================================
; ; DO_COLPF0_COLBK_DLI                                                     A
; ;==============================================================================
; ; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; ; same display list structure and DLIs.  
; ; Sets background color and the COLPF0 pixel color.  
; ; Table driven.  
; ; Perfectly re-usable for anywhere Map Mode 9 or Blank instructions are 
; ; being managed.  In the case of blank lines you just don't see the pixel 
; ; color change, so it does not matter what is in the COLPF0 color table. 
; ; -----------------------------------------------------------------------------

; DO_COLPF0_COLBK_DLI

	; mStart_DLI

	; lda COLPF0_TABLE,y   ; Get pixels color
	; pha
	; lda COLBK_TABLE,y    ; Get background color

	; sta WSYNC
	
	; sta COLBK            ; Set background
	; pla
	; sta COLPF0           ; Set pixels.

	; jmp Exit_DLI


; ;==============================================================================
; ; DO_SPLASH_PMGZERO_DLI                                              A
; ;==============================================================================
; ; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; ; same display list structure and DLIs.  
; ; Sets PM HPOS to 0 for all objects.
; ; This is needed early on splash screens because the first group of 
; ; objects extend below the first colored background lines.   This causes
; ; bits of the PMG text labels to appear on the splash screen.
; ; -----------------------------------------------------------------------------

; DO_SPLASH_PMGZERO_DLI

	; mStart_DLI

	; jsr libSetPmgHPOSZero 

	; jmp Exit_DLI


; ;==============================================================================
; ; DO_SPLASH_PMGSPECS2_DLI                                               A
; ;==============================================================================
; ; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; ; same display list structure and DLIs.  
; ; Sets background color and the COLPF0 pixel color.  
; ; Table driven.  
; ; Perfectly re-usable for anywhere Map Mode 9 or Blank instructions are 
; ; being managed.  In the case of blank lines you just don't see the pixel 
; ; color change, so it does not matter what is in the COLPF0 color table. 
; ; -----------------------------------------------------------------------------

; DO_SPLASH_PMGSPECS2_DLI

	; mStart_DLI

	; lda COLPF0_TABLE,y   ; Get pixels color
	; pha
	; lda COLBK_TABLE,y    ; Get background color
	
	; sta WSYNC
	
	; sta COLBK            ; Set background
	; pla
	; sta COLPF0           ; Set pixels.

	; jsr LoadPmSpecs2     ; Load the first table entry into 

	; jmp Exit_DLI











;===============================================================================
; Breakout Arcade -- 1976
; Conceptualized by Nolan Bushnell and Steve Bristow.
; Built by Steve Wozniak.
; https://en.wikipedia.org/wiki/Breakout_(video_game)
;===============================================================================
; C64 Breakout clone -- 2016
; Written by Darren Du Vall aka Sausage-Toes
; source at:
; Github: https://github.com/Sausage-Toes/C64_Breakout
;===============================================================================
; C64 Breakout clone ported to Atari 8-bit -- 2017
; Atari-fied by Ken Jennings
; Build for Atari using eclipse/wudsn/atasm on linux
; Source at:
; Github: https://github.com/kenjennings/C64-Breakout-for-Atari
; Google Drive: https://drive.google.com/drive/folders/0B2m-YU97EHFESGVkTXp3WUdKUGM
;===============================================================================
; Breakout: Gratuitous Eye Candy Edition -- 2017
; Written by Ken Jennings
; Build for Atari using eclipse/wudsn/atasm on linux
; Source at:
; Github: https://github.com/kenjennings/Atari-Breakout-GECE
; Google Drive: https://drive.google.com/drive/folders/
;===============================================================================

;===============================================================================
; History V 1.0
;===============================================================================
; dli.asm contains all the Display List Interupts.
; See display.asm for all the display list data.
; See screen.asm for the 6502 code managing the display.
;===============================================================================

; DISPLAY_LIST_INTERRUPT


; ; Do the color bars in the scrolling title text.
; ; Since the line scrolls, the beginning of the color
; ; bars changes.  Also, the number of visible scan
; ; lines of the title changes as the title scrolls
; ; up.  The VBI maintains the reference for these
; ; so the DLI doesn't have to figure out anything.

; DLI_1 ; Save registers
	; pha
	; txa
	; pha
	; tya
	; pha

	; ldy TITLE_WSYNC_OFFSET ; Number of lines to skip above the text

	; beq DLI_Color_Bars ; no lines to skip; do color bars.
; DLI_Delay_Top
	; sty WSYNC
	; dey
	; bne DLI_Delay_Top

	; ; This used to have a lot of junk including value testing
	; ; to figure out how to color the Player/flying character.
	; ; However, giving the player a permanent page 0 pointer to
	; ; a color table (ZTITLE_COLPM0) and having the VBI decide
	; ; which to use simplified this logic considerably.

; DLI_Color_Bars
	; ldx TITLE_WSYNC_COLOR ; Number of lines in color bars.

	; beq End_DLI_1 ; No lines, so the DLI is finished.

	; ldy TITLE_COLOR_COUNTER

	; ; Here's to hoping that the badline is short enough to allow
	; ; the player color and four playfield color registers to change 
	; ; before they are displayed.  This is part of the reason 
	; ; for the narrow playfield.
; DLI_Loop_Color_Bars
	; lda (ZTITLE_COLPM0),y ; Set by VBI to point at one of the COLPF tables
	; sta WSYNC
	; sta COLPM0

	; lda TITLE_COLPF1,y
	; sta COLPF0

	; lda TITLE_COLPF1,y
	; sta COLPF1

	; lda TITLE_COLPF2,y
	; sta COLPF2

	; lda TITLE_COLPF3,y
	; sta COLPF3

	; iny
	; dex
	; bne DLI_Loop_Color_Bars

; End_DLI_1 ; End of routine.  Point to next routine.
	; lda #<DLI_2
	; sta VDSLST
	; lda >#DLI_2
	; sta VDSLST+1

	; pla ; Restore registers for exit
	; tay
	; pla
	; tax
	; pla

	; rti


; ; DLI2: Occurs as the last line of the Display List in the Title Scroll section.
; ; Set Normal Screen, VSCROLL=0, COLPF0 for horizontal bumper.
; ; Set PRIOR for Fifth Player.
; ; Set HPOSP3/HPOSM0, COLPM3/COLPF3, SIZEP3, SIZEM
; ; for left and right Thumper-bumpers.
; ; set HITCLR for Playfield.
; ;-------------------------------------------
; ; Set HPOSP0/P1/P2, COLPM0/PM1/PM2, SIZEP0/P1/P2 for top row Boom objects.
; ;
; ;-------------------------------------------
; ; color 1 = horizontal/top bumper.
; ; Player 3 = Left bumper
; ; Missile (5th Player) = Right Bumper
; ;-------------------------------------------
; ; COLPF0,
; ; COLPM3, COLPF3
; ; HPOSP3, HPOSM0
; ; SIZEP3, SIZEM0
; ;-------------------------------------------

; DLI_2
	; pha
	; txa
	; pha
	; tya
	; pha

	; ; GTIA Fifth Player.
	; lda #[FIFTH_PLAYER|1] ; Missiles = COLPF3.  Player/Missiles Priority on top.
	; sta PRIOR
	; sta HITCLR

	; ; Screen parameters...
	; lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PLAYFIELD_WIDTH_NORMAL|PM_1LINE_RESOLUTION]
	; STA WSYNC
	; sta DMACTL

	; ; Top thumper-bumper.  Only set color.  The rest of the animation is
	; ; done in the Display list and set by the VBI.
	; lda THUMPER_COLOR_TOP
	; sta COLPF0

	; ; Left thumper-bumper -- Player 3. P/M color, position, and size.
	; lda THUMPER_COLOR_LEFT
	; sta COLPM3

	; ldy THUMPER_FRAME_LEFT        ; Get animation frame
	; lda THUMPER_LEFT_HPOS_TABLE,y ; P/M position
	; sta HPOSP3
	; lda THUMPER_LEFT_SIZE_TABLE,y ; P/M size
	; sta SIZEP3

	; ; Right thumper-bumper -- Missile 0.  Set P/M color, position, and size.
	; lda THUMPER_COLOR_RIGHT
	; sta COLPF3 ; because 5th player is enabled.

	; ldy THUMPER_FRAME_RIGHT        ; Get animation frame
	; lda THUMPER_RIGHT_HPOS_TABLE,y ; P/M position
	; sta HPOSM0
	; lda THUMPER_RIGHT_SIZE_TABLE,y ; P/M size
	; sta SIZEM

	; ; Magic here

; End_DLI_2 ; End of routine.  Point to next routine.
	; lda #<DLI_3
	; sta VDSLST
	; lda >#DLI_3
	; sta VDSLST+1

	; pla
	; tay
	; pla
	; tax
	; pla

	; rti

; ; DLI3: Hkernel 8 times....
; ;      Set HSCROLL for line, VSCROLL = 5, then Set COLPF0 for 5 lines.
; ;      Reset VScroll to 1 (allowing 2 blank lines.)
; ;      Set P/M Boom objects, HPOS, COLPM, SIZE
; ;      Repeat HKernel.
; ;
; ; Define 8 rows of Bricks.
; ; Each is 5 lines of mode C graphics, plus 2 blank line.
; ; The 5 rows of graphics are defined by using the VSCROL
; ; exploit to expand one line of mode C into five lines.
; ;
; ; This:
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL
; ;   .byte DL_BLANK_2
; ; Becomes this:
; ;   DL_MAP_C
; ;   DL_MAP_C
; ;   DL_MAP_C
; ;   DL_MAP_C
; ;   DL_MAP_C
; ;   Blank Line
; ;   Blank Line
; ;
; ; The Blank lines provide space for expansion of the boom blocks over the bricks.
; ; Therefore they must be positioned in the blank line before the brick line.
; ; (An extra blank scan line follows the line starting the DLI to allow for this
; ; space on the first line)
; ;
; ; So, here is the DLI line change order:
; ;   DL_BLANK_1|DL_DLI                      Set hpos, size, color for Boom 1 and Boom2 (1)
; ;   DL_BLANK_1                             Set Vscroll 11 and HSCROLL for Brick Line 1 - set color COLPF0 (1)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (1)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (1)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (1)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (1)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set VScroll 0
; ;   DL_BLANK_1                             Set hpos, size, color for Boom 1 and Boom2 (2)
; ;   DL_BLANK_1                             Set Vscroll and HSCROLL for Brick Line 2 - set color COLPF0 (2)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (2)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (2)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (2)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (2)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set VScroll 0
; ;   DL_BLANK_1                             Set hpos, size, color for Boom 1 and Boom2 (3)
; ;   DL_BLANK_1                             Set Vscroll and HSCROLL for Brick Line 3 - set color COLPF0
; ; etc. . . .
; ;   DL_BLANK_1                             Set hpos, size, color for Boom 1 and Boom2 (8)
; ;   DL_BLANK_1                             Set Vscroll and HSCROLL for Brick Line 8 - set color COLPF0 (8)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (8)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (8)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (8)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set color COLPF0 (8)
; ;   DL_MAP_C|DL_LMS|DL_VSCROLL|DL_HSCROLL  Set VScroll 0
; ;   DL_BLANK_1
; ;   DL_BLANK_1
; ;-------------------------------------------
; ; color 1 = bricks.
; ; Player 1 = Boom animation 1
; ; Player 2 = Boom animation 2
; ;-------------------------------------------
; ; per brick line
; ; COLPM1, COLPM2
; ; HPOSP1, HPOSP2
; ; SIZEP1, SIZEP2
; ; COLPF0, HSCROLL
; ;-------------------------------------------
; DLI_3
	; pha
	; txa
	; pha
	; tya
	; pha

	; ldx #0  ; Starting at line 0 first line of bricks.
	; ;
	; ; Set the Boom animation postitions.
	; ; Hopefully, this is enough load/stores to cross the end of the blank scan line...
	; ; If not then a wsync needs to be inserted.  somewhere.  hope not.  The end
	; ;  of the loop already did a wsync when it corrected the scrolling, so
	; ; it might mean the rows from 2 to 8 have the boom animations setting
	; ; written one scan line too high....  thinking.   thinking....
; DLI3_DO_BOOM_AND_BRICKS
	; lda BOOM_1_HPOS,x
	; ldy BOOM_2_HPOS,x
	; sta WSYNC ; need to drop one line more to line up with boom lines.
	; ; six store, four load after wsync.   This is unlikely to work well.
	; ; At least there's no graphics or character set DMA on this line.
	; ; Highly possible that this will need to be reduced to 1 Boom animation
	; ; object which is the least desireable choice.
	; ; Otherwise, the the Boom animation height cannot exceed the height of the
	; ; bricks.  The alternate plan means there would be two completely blank
	; ; scan line to affect all the changes, so that will definitely work well.
	; ; (And, this could be used to reduce the gap between brick lines to one scan
	; ; line compressing the brick playfield by 7 scan lines, nearly one full text line.)
	; sta HPOSP1
	; sty HPOSP2

	; lda BOOM_1_SIZE,x
	; sta SIZEP1
	; lda BOOM_2_SIZE,x
	; sta SIZEP2

	; lda BOOM_1_COLPM,x
	; sta COLPM1
	; lda BOOM_2_COLPM,x
	; sta COLPM2

	; ; Still in the blank line area.  (I hope.)
	; ; Set hscroll for brick line which is next.
	; lda BRICK_CURRENT_HSCROL,x
	; sta HSCROL
	; ; Because we are toggling VSCROL values to trigger unnatural behavior
	; ; in ANTIC, stricter timing may be required here.  The WSYNC below 
	; ; may need to move up here before updating VSCROL.
	; lda #11  ; Trick Antic into extending the line.  11, 12, 13, 14, 15.
	; sta VSCROL

	; ; Due to the VSCROL set large than the number of scan lines in 
	; ; this graphics mode ANTIC is now having a small brain fart and 
	; ; stuttering out the same line of graphics for several scan lines.  
	; ; Apply color to those lines.
	; ldy BRICK_CURRENT_COLOR,x
	; sta WSYNC
	; sta COLPF0                ; scan line 1
	; iny
	; iny
	; sta WSYNC
	; sta COLPF0                ; scan line 2
	; iny
	; iny
	; sta WSYNC
	; sta COLPF0                ; scan line 3
	; iny
	; iny
	; sta WSYNC
	; sta COLPF0                ; scan line 4
	; iny
	; iny
	; sta WSYNC
	; sta COLPF0                ; scan line 5

	; ; Fix VSCROL for the  two blank lines that follow
	; lda #0
	; sta WSYNC
	; sta VSCROL

	; ; thinking...  that vscroll correction happens at the last line
	; ; a brick line.  therefore , this jump to loop happens on the
	; ; first blank line after the bricks...  This means the loop writes
	; ; new boom animation settings one line too high...  So, there
	; ; needs to be a wsync either here, or at the  beginning of the
	; ; loop  to drop down one more line.
	; inx                   ; next line
	; cpx #8
	; bne DLI3_DO_BOOM_AND_BRICKS

; End_DLI_3 ; End of routine.  Point to next routine.
	; lda #<DLI_4
	; sta VDSLST
	; lda >#DLI_4
	; sta VDSLST+1

	; pla
	; tay
	; pla
	; tax
	; pla

	; rti


; ; DLI4: Set Narrow Width, Set the mode 3 chracter set.
; ; Set VSCROLL for window.
; ; Fade text in.

; ; Sets the narrow screen size for the scrolling credits window.
; ; It provides a few more cycles for the MAIN code, but its not
; ; like I'm counting cycles.  (Yet.)

; DLI_4
	; pha
	; txa
	; pha
	; tya
	; pha

	; ; set the Mode 3 character set.
	; lda #>CHARACTER_SET_00
	; sta CHBASE
	; ; set the fine scroll for the credits.
	; lda SCROLL_CURRENT_VSCROLL
	; sty VSCROL
	; ; Set Narrow screen.
	; lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PLAYFIELD_WIDTH_NARROW|PM_1LINE_RESOLUTION]
	; sta DMACTL
	; ; set black text background.
	; ldx #$00
	; stx COLPF2

	; ldy #$06  ; to read 6 table entries
	; ldx SCROLL_CURRENT_FADE
	
	; ; 10 instructions of loads and stores should put this past 
	; ; the end of the scan line that started the DLI.
	
	; ; Fade in the scrolling text window.

; Loop_Fade_In_Scroll_Text
	; lda SCROLL_FADE_START_LINE_TABLE,x
	; sta WSYNC
	; sta COLPF1   ; Set new text color (luminance)
	; inx          ; Next luminance value
	; dey          ; reached the end?  0 ?
	; bne Loop_Fade_In_Scroll_Text ; No.  Continue updates.

; End_DLI_4 ; End of routine.  Point to next routine.
	; lda #<DLI_5
	; sta VDSLST
	; lda >#DLI_5
	; sta VDSLST+1

	; pla
	; tay
	; pla
	; tax
	; pla

	; rti



; ; DLI5: Fade text out at bottom of scrolling text.
; ; The trick here is that the start of the fade changes
; ; based on the value of vscroll.
; DLI_5
	; pha
	; txa
	; pha
	; tya
	; pha

	; ; Because the DLI is moving away while VSCROL 
	; ; increments, the DLI needs to skip a variable number
	; ; of scan lines before starting to fade out the text.
	; lda SCROLL_CURRENT_VSCROLL
	; clc
	; adc #3
	; tax
; Loop_Fade_Out_Skip_Lines
	; sta WSYNC
	; dex
	; bne Loop_Fade_Out_Skip_Lines
	
	; ldx SCROLL_CURRENT_FADE

; Loop_Fade_Out_Scroll_Text
	; lda SCROLL_FADE_END_LINE_TABLE,x
	; sta WSYNC
	; sta COLPF1   ; Set new text color (luminance)
	; dex          ; Next luminance value.  Reached end?
	; bpl Loop_Fade_Out_Scroll_Text
	
	; ; Do a couple of preliminary things for 
	; ; the Paddle to simplify what needs to be 
	; ; done in DLI6.
	; ; Set parameters for PM1 and PM2 here. 
	; ; DLI6 will work on only PM3.
	; lda PADDLE_HPOS    ; Horizontal position(s)
	; sta HPOSP1
	; sta HPOSP2

	; lda #$00           ; Normal Hosrizontal Size(s)
	; sta SIZEP1
	; sta SIZEP2
	
	
; End_DLI_5 ; End of routine.  Point to next routine.
	; lda #<DLI_6
	; sta VDSLST
	; lda >#DLI_6
	; sta VDSLST+1

	; pla
	; tay
	; pla
	; tax
	; pla

	; rti


; ; DLI6: Sets Paddle specs. 
; ; PMWIDTH, HPOS,changes colors for paddle.
; ; Then set HSCROLL for Scores.
; ; 
; ; The initial states for Player1 and Player2 
; ; were set at the end of the prior DLI to 
; ; simplify what goes on here.
; ; This routine only adjusts the Player3 state. 
; ; This is a little more time critical, because 
; ; there is no gap between the last scan line of 
; ; the left thumper-bumper and the first scan 
; ; line of the paddle.
; ;
; ; Finish up by re-setting the character set back
; ; to the custom set for mode 6 color text and
; ; normal playfield width.
; DLI_6
	; pha
	; txa
	; pha

	; lda PADDLE_HPOS ; Horizontal position
	; ldx #$00        ; For size
	
	; sta WSYNC       ; sync to end of line
	; sta HPOSP3      ; stuff in postion
	; sta SIZEP3      ; stuff in size
	
	; ldx PADDLE_FRAME               ; Get the animated 
	; lda PADDLE_STRIKE_COLOR_ANIM,x ;  pddle color.

	; sta COLPM3      ; Stuff in color. 
	; sta WSYNC       ; sync to end of line.
	
	; ldx #$94        ; For second  scan line reset paddle color 
	; sta COLPM3      ; to its intended default. 
	
	; lda #>CHARACTER_SET_01 ; Mode 6 text. Title and score.
	; sta CHBASE
	
; End_DLI_6 ; End of routine.  Point to next routine.
	; lda #<DLI_7
	; sta VDSLST
	; lda >#DLI_7
	; sta VDSLST+1

	; pla
	; tay
	; pla
	; tax
	; pla

	; rti




; ; DLI7: Fairly basic.  Just prettify the text.
; ; "BALLS" is a little indicator in the top left 
; ; corner of the last row of text.
; ; The other two colors are for the score.

; DLI_7
	; pha
	; txa
	; pha
	; tya
	; pha
	
	; ; Since the "Balls" is at the top of the line, and 
	; ; the Score is 12 scan lines centered over two lines
	; ; then we don;t have to count out 16 entire sca lines.
	; ; Therefore 13...
	; ldy #13    
	; ldx DISPLAYED_BALLS_SCORE_COLOR_INDEX

; Loop_Color_Balls_Score	
	; lda DISPLAYED_BALLS_COLOR,x      ; "Balls" indicator color
	; sta WSYNC
	; sta COLPF3
	
	; lda DISPLAYED_SCORE_COLOR0,x     ; Score digits are two colors...
	; sta COLPF0

	; lda DISPLAYED_SCORE_COLOR1,x
	; sta COLPF1

	; inx
	; dey 
	; bpl Loop_Color_Balls_Score
	

; End_DLI_7 ; End of routines.  Point to first routine.
	; lda #<DLI_1
	; sta VDSLST
	; lda >#DLI_1
	; sta VDSLST+1

	; pla
	; tay
	; pla
	; tax
	; pla

	; rti











; ;==============================================================================
; ; LOAD PM SPECS 0                                                       A 
; ;==============================================================================
; ; Called by Score 1 DLI.
; ; Load the table entry 1 values for P0,P1,P2,P3,M0,M1,M2,M3  
; ; to the P/M registers.
; ; -----------------------------------------------------------------------------

; LoadPmSpecs0

	; lda PRIOR_TABLE
	; sta PRIOR

	; lda HPOSP0_TABLE
	; sta HPOSP0
	; lda COLPM0_TABLE 
	; sta COLPM0
	; lda SIZEP0_TABLE
	; sta SIZEP0

	; lda HPOSP1_TABLE
	; sta HPOSP1
	; lda COLPM1_TABLE 
	; sta COLPM1
	; lda SIZEP1_TABLE
	; sta SIZEP1

	; lda HPOSP2_TABLE
	; sta HPOSP2
	; lda COLPM2_TABLE 
	; sta COLPM2
	; lda SIZEP2_TABLE
	; sta SIZEP2

	; lda HPOSP3_TABLE
	; sta HPOSP3
	; lda COLPM3_TABLE 
	; sta COLPM3
	; lda SIZEP3_TABLE
	; sta SIZEP3
	
	; lda SIZEM_TABLE
	; sta SIZEM
	; lda HPOSM0_TABLE
	; sta HPOSM0
	; lda HPOSM1_TABLE
	; sta HPOSM1
	; lda HPOSM2_TABLE
	; sta HPOSM2
	; lda HPOSM3_TABLE
	; sta HPOSM3

	; rts


; ;==============================================================================
; ; LOAD PM SPECS 1                                                       A 
; ;==============================================================================
; ; Called by Score 2 DLI.
; ; Load the table entry 1 values for P0,P1,P2,P3,M0,M1,M2,M3 
; ; to the P/M registers.
; ; -----------------------------------------------------------------------------

; LoadPmSpecs1

	; lda PRIOR_TABLE+1
	; sta PRIOR

	; lda HPOSP0_TABLE+1
	; sta HPOSP0
	; lda COLPM0_TABLE+1
	; sta COLPM0
	; lda SIZEP0_TABLE+1
	; sta SIZEP0

	; lda HPOSP1_TABLE+1
	; sta HPOSP1
	; lda COLPM1_TABLE+1 
	; sta COLPM1
	; lda SIZEP1_TABLE+1
	; sta SIZEP1

	; lda HPOSP2_TABLE+1
	; sta HPOSP2
	; lda COLPM2_TABLE+1 
	; sta COLPM2
	; lda SIZEP2_TABLE+1
	; sta SIZEP2

	; lda HPOSP3_TABLE+1
	; sta HPOSP3
	; lda COLPM3_TABLE+1 
	; sta COLPM3
	; lda SIZEP3_TABLE+1
	; sta SIZEP3

	; lda SIZEM_TABLE+1
	; sta SIZEM
	; lda HPOSM0_TABLE+1
	; sta HPOSM0
	; lda HPOSM1_TABLE+1
	; sta HPOSM1
	; lda HPOSM2_TABLE+1
	; sta HPOSM2
	; lda HPOSM3_TABLE+1
	; sta HPOSM3

	; rts


; ;==============================================================================
; ; LOAD PM SPECS 2                                                       A 
; ;==============================================================================
; ; Called on Title, Game, and Game Over displays.
; ; Load the table entry 2 values for P0,P1,P2,P3,M0,M1,M2,M3 
; ; to the P/M registers.
; ; -----------------------------------------------------------------------------

; LoadPmSpecs2

	; lda PRIOR_TABLE+2
	; sta PRIOR

	; lda HPOSP0_TABLE+2
	; sta HPOSP0
	; lda COLPM0_TABLE+2
	; sta COLPM0
	; lda SIZEP0_TABLE+2
	; sta SIZEP0

	; lda HPOSP1_TABLE+2
	; sta HPOSP1
	; lda COLPM1_TABLE+2 
	; sta COLPM1
	; lda SIZEP1_TABLE+2
	; sta SIZEP1

	; lda HPOSP2_TABLE+2
	; sta HPOSP2
	; lda COLPM2_TABLE+2 
	; sta COLPM2
	; lda SIZEP2_TABLE+2
	; sta SIZEP2

	; lda HPOSP3_TABLE+2
	; sta HPOSP3
	; lda COLPM3_TABLE+2 
	; sta COLPM3
	; lda SIZEP3_TABLE+2
	; sta SIZEP3

	; lda SIZEM_TABLE+2
	; sta SIZEM
	; lda HPOSM0_TABLE+2
	; sta HPOSM0
	; lda HPOSM1_TABLE+2
	; sta HPOSM1
	; lda HPOSM2_TABLE+2
	; sta HPOSM2
	; lda HPOSM3_TABLE+2
	; sta HPOSM3

	; rts

