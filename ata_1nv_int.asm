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

	sta AnimateFrames

	pha ; preserve it for caller.

	lda InputScanFrames
	bne EndResetTimers

	lda #INPUTSCAN_FRAMES
	sta InputScanFrames

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

	lda InputScanFrames        ; Is input timer delay  0?
	bne SetNoInput             ; No. thus nothing to scan. (and exit)

	ldx STICK0                 ; The OS nicely separates PIA nybbles for us
	lda STICKEMUPORNOT_TABLE,x ; Convert input into workable, filtered output.
	sta InputStick             ; Save it.

;AddTriggerInput
	lda STRIG0                 ; 0 is button pressed., !0 is not pressed.
	bne DoneWithBitCookery     ; if non-zero, then no button pressed.

	lda InputStick             ; The current stick input value.
	ora #%00010000             ; Turn on 5th bit/$10 for the trigger.
	sta InputStick             ; Save it.  (fall through for return..)

DoneWithBitCookery             ; Some input was captured?
	lda InputStick             ; Return the input value?
	beq ExitCheckInput         ; No, nothing happened here.  Just exit.

	lda #INPUTSCAN_FRAMES      ; Because there was input collected, then
	sta InputScanFrames        ; Reset the input timer.

;ExitInputCollection            ; Input occurred
	lda #0                     ; Kill the attract mode flag
	sta ATRACT                 ; to prevent color cycling.

	lda InputStick             ; Return the input value.
	rts

SetNoInput
	lda #0
	sta InputStick             ; Force no data for input.

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
	lda CONSOL                 ; Get Option, Select, Start buttons
	and #CONSOLE_OPTION        ; Is Option pressed?  0 = pressed. 1 = not
	bne CheckSelectKey         ; No.  Try the select.

	jsr PlayTink               ; Button pressed. Set Pokey channel 2 to tink sound.

	; increment starting frogs.
	; generate string for right buffer
	ldx NewLevelStart          
	inx
	cpx #[MAX_FROG_SPEED+1]    ; 13 + 1
	bne bCFCI_SkipResetLevel
	ldx #0
bCFCI_SkipResetLevel
	stx NewLevelStart          ; Updated starting level.

	jsr TitlePrepLevel
	jsr MultiplyFrogsCrossed ; Multiply by 18, make index base, set difficulty address pointers.
	jmp bCFCI_StartupStage2


CheckSelectKey
	lda CONSOL                 ; Get Option, Select, Start buttons
	and #CONSOLE_SELECT        ; Is SELECT pressed?  0 = pressed. 1 = not
	bne bCFCI_End              ; No.  Finished with all.

	jsr PlayTink               ; Button pressed. Set Pokey channel 2 to tink sound.

	; increment lives.
	; generate string for right buffer
	ldx NewNumberOfLives
	inx
	cpx #[MAX_FROG_LIVES+1]    ; 7 + 1
	bne bCFCI_SkipResetLives
	ldx #1
bCFCI_SkipResetLives
	stx NewNumberOfLives      ; Get the updated number of new lives for the next game.
	jsr TitlePrepLives        ; Get the scrolling buffer ready.
	jsr WriteNewLives         ; Update the status line to match the new number of frogs.

bCFCI_StartupStage2
	lda #2
	sta EventStage            ; Stage 2 is the shift Left Buffer down.
	lda #6
	sta EventCounter          ; Do it six times.
	lda #TITLE_DOWN_SPEED
	jsr ResetTimers           ; Reset animation/input frame counter.

	jsr PlayDowns             ; Play down movement sound for title graphics on OPTION and SELECT
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
; Force steady state of DLI.
; Manage switching displays.
;
; Optional Input: VBICurrentDL  
; ID number for new Display sent by Main.  Reset to -1 by VBI.
; DISPLAY_TITLE = 0
; DISPLAY_GAME  = 1
; DISPLAY_WIN   = 2
; DISPLAY_DEAD  = 3
; DISPLAY_OVER  = 4
;
; Output: CurrentDL 
; Set by VBI to the display number when the Display is changed.
;==============================================================================

MyImmediateVBI

; ======== Manage Changing Display List ========
	lda VBICurrentDL            ; Did Main code signal to change displays?
	bmi VBIResetDLIChain        ; -1, No, just restore current DLI chain.

;VBISetupDisplay
	tax                         ; Use VBICurrentDL  as index to tables.

	lda DISPLAYLIST_LO_TABLE,x  ; Copy Display List Pointer
	sta SDLSTL                  ; for the OS
	lda DISPLAYLIST_HI_TABLE,x
	sta SDLSTH

	lda DLI_LO_TABLE,x          ; Copy Display List Interrupt chain table starting address
	sta ThisDLIAddr
	lda DLI_HI_TABLE,x
	sta ThisDLIAddr+1

	lda BASE_PMG_LO_TABLE,x     ; Copy PMG Settings table base address
	sta BasePmgAddr
	lda BASE_PMG_HI_TABLE,x
	sta BasePmgAddr+1

	stx CurrentDL               ; Let Main know this is now the current screen.
	lda #$FF                    ; Turn off the signal from Main to change screens.
	sta VBICurrentDL

	cpx #DISPLAY_TITLE          ; Is this the Title display?
	bne VBIResetDLIChain        ; No, continue with DLI reset.
	jsr TitleSetOrigin          ; Title screen.  Reset scrolling to origin.

VBIResetDLIChain
	ldy #0
	lda (ThisDLIAddr),y         ; Grab 0 entry from this DLI chain
	sta VDSLST                  ; and restart the DLI routine.
	lda #>TITLE_DLI
	sta VDSLST+1

	iny                         ; !!! Start at 1, because entry 0 provided the starting DLI address !!!
	sty ThisDLI 
	; This means indexed pulls from the color tables are +1 from the current DLI.

; Stage colors and HSCROL for first DLI into page 0 
; to make selecting these faster during the DLI.
	jsr SetupAllColors

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
; Manage death of frog. 
; Fine Scroll the boats.
; Update Player/Missile object display.
; Perform the boat parts animations.
; Manage timers and countdowns.
; Scroll the line of credit text.
; Blink the Press Button prompt if enabled.
;==============================================================================

MyDeferredVBI

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

ManageDeathOfASalesfrog
	lda CurrentDL                ; Get current display list
	cmp #DISPLAY_GAME            ; Is this the Game display?
	bne EndOfDeathOfASalesfrog   ; No. So no collision processing. 

	ldx FrogRow                  ; What screen row is the frog currently on?
	lda MOVING_ROW_STATES,x      ; Is the current Row a boat row?
	beq EndOfDeathOfASalesfrog   ; No. So skip collision processing. 

	jsr CheckRideTheBoat         ; Make sure the frog is riding the boat. Otherwise it dies.

EndOfDeathOfASalesfrog
;	sta HITCLR                   ; Always reset the P/M collision bits for next frame.


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
	lda CurrentDL                 ; Get current display list
	cmp #DISPLAY_GAME             ; Is this the Game display?
	bne EndOfBoatScrolling        ; No.  Skip the scrolling logic.

	ldy #1                        ; Current Row.  Row 0 is the safe zone, no scrolling happens there.

; Common code to each row. 
; Loop through rows.
; If is is a moving row, then check the row's timer/frame counter.
; If the timer is over, then reset the timer, and then fine scroll 
; the row (also moving the frog with it as needed.)

LoopBoatScrolling
	; Need row in X and Y due to different 6502 addressing modes in the timer and scroll functions.
	tya                           ; A = Y, Current Row 
	tax                           ; X = A, Current Row.  Can't dec zeropage,x, darn you cpu.

	lda MOVING_ROW_STATES,y       ; Get the current Row State
	beq EndOfScrollLoop           ; Not a scrolling row.  Go to next row.
	php                           ; Save the + or - status until later.
	; We know this is either left or right, so this block is common code
	; to update the row's speed counter based on the row entry.
	lda CurrentBoatFrames,x       ; Get the row's frame delay value.
	beq ResetBoatFrames           ; If BoatFrames is 0, time to make the donuts.
	dec CurrentBoatFrames,x       ; Not zero, so decrement
	plp                           ; oops.  got to dispose of that.
	jmp EndOfScrollLoop           

ResetBoatFrames
	lda (BoatFramesPointer),y     ; Get master value for row's frame delay
	sta CurrentBoatFrames,x       ; Restart the row's frame speed delay.

	plp                           ; Get the current Row State (again.)
	bmi LeftBoatScroll            ; 0 already bypassed.  1 = Right, -1 (FF) = Left.

	jsr RightBoatFineScrolling    ; Do Right Boat Fine Scrolling.  (and frog X update) 
	jmp EndOfScrollLoop           ; end of this row.  go to the next one.

LeftBoatScroll
	jsr LeftBoatFineScrolling     ; Do Left Boat Fine Scrolling.  (and frog X update) 

EndOfScrollLoop                   ; end of this row.  go to the next one.
	iny                           ; Y reliably has Row.  X was changed.
	cpy #18                       ; Last entry is beach.  Do not bother to go further.
	bne LoopBoatScrolling         ; Not 18.  Process the next row.

EndOfBoatScrolling


; ======== Manage InputScanFrames Delay Counter ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoManageInputClock
	lda InputScanFrames          ; Is input delay already 0?
	beq DoAnimateClock           ; Yes, do not decrement it again.
	dec InputScanFrames          ; Minus 1.

; ======== Manage Main code's timer.  Decrement while non-zero. ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoAnimateClock
	lda AnimateFrames            ; Is animation countdown already 0?
	beq DoAnimateClock2          ; Yes, do not decrement now.
	dec AnimateFrames            ; Minus 1

; ======== Manage Another Main code timer.  Decrement while non-zero. ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoAnimateClock2
	lda AnimateFrames2           ; Is animation countdown already 0?
	beq DoAnimateClock3          ; Yes, do not decrement now.
	dec AnimateFrames2           ; Minus 1

; ======== Manage Another Main code timer.  Decrement while non-zero. ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoAnimateClock3
	lda AnimateFrames3           ; Is animation countdown already 0?
	beq DoAnimateClock4          ; Yes, do not decrement now.
	dec AnimateFrames3           ; Minus 1
	
; ======== Manage Another Main code timer.  Decrement while non-zero. ========
; It is MAIN's job to act when the timer is 0, and reset it if needed.

DoAnimateClock4
	lda AnimateFrames4           ; Is animation countdown already 0?
	beq EndOfTimers              ; Yes, do not decrement now.
	dec AnimateFrames4           ; Minus 1

EndOfTimers

; ======== Manage Frog Eyeball motion ========
; If the timer is non-zero, Change eyeball position and force redraw.
; This nicely multi-tasks the eyes to return to center even if MAIN is 
; is not doing anything related to the frog.

DoAnimateEyeballs
	lda FrogRefocus              ; Is the eye move counter greater than 0?
	beq EndOfClockChecks         ; No, Nothing else to do here.
	dec FrogRefocus              ; Subtract 1.
	bne EndOfClockChecks         ; Has not reached 0, so nothing left to do here.
	lda FrogShape                ; Maybe the player raced the timer to the next screen...
	cmp #SHAPE_FROG              ; ... so verify the frog is still displayable.
	bne EndOfClockChecks         ; Not the frog, so do not animate eyes.
	lda #1                       ; Inform the Frog renderer  
	sta FrogEyeball              ; to use the default/centered eyeball.
	sta FrogUpdate               ; and set mandatory redraw.

EndOfClockChecks


; ======== Reposition the Frog (or Splat). ========
; At this point everyone and their cousin have been giving their advice 
; about the frog position.  The main code changed position based on joystick
; input.  The VBI change position if the frog was on a scrolling boat row.
; Here, finally apply the position and move the frog image.

MaintainFrogliness
	lda FrogUpdate               ; Nonzero means something important needs to be updated.
	bne SimplyUpdatePosition

	lda FrogNewShape             ; Get the new frog shape.
	beq NoFrogUpdate             ; 0 is off, so no movement there at all, so skip all

; ==== Frog and boat position gyrations are done.  ==== Is there actual movement?
SimplyUpdatePosition
	jsr ProcessNewShapePosition  ; limit object to screen.  redraw the object.

NoFrogUpdate


; ======== Fade Score Label Text  ========
; Game will brighten text label when changing a value.
; Here we detect if a change needs to be made, and then 
; decrement the color if so.  All colors end at luminance
; value $04.  Luminance $00 means no further consideration.

ManageScoredFades
	ldx CurrentDL
	lda MANAGE_SCORE_COLORS_TABLE,x
	beq EndManageScoreFades

DoFadeScore
	lda COLPM0_TABLE       ; Get Color.
	jsr DecThisColorOrNot  ; Can it be decremented?
	sta COLPM0_TABLE       ; Re-Save Color
	sta COLPM1_TABLE       ; Second half of the same object is same color

DoFadeHiScore
	lda COLPM2_TABLE       ; Get Color.
	jsr DecThisColorOrNot  ; Can it be decremented?
	sta COLPM2_TABLE       ; Re-Save Color 

DoFadeLives
	lda MANAGE_LIVES_COLORS_TABLE,x ; Is this a thing to do on this display.
	beq EndManageScoreFades

	lda COLPM0_TABLE+1     ; Get Color.
	jsr DecThisColorOrNot  ; Can it be decremented?
	sta COLPM0_TABLE+1     ; Re-Save Color
	sta COLPM1_TABLE+1     ; Second half of the same object is same color

DoFadeSaved
	lda COLPM2_TABLE+1     ; Get Color.
	jsr DecThisColorOrNot  ; Can it be decremented?
	sta COLPM2_TABLE+1     ; Re-Save Color
	sta COLPM3_TABLE+1     ; Second half of the same object is same color

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
	lda VBIEnableScrollTitle     ; Is scrolling turned on?
	beq WaitToRestoreTitle       ; No. See if the timer needs something.

	jsr TitleLeftScroll          ; Scroll it
	jsr TitleIsItAtTheEnd        ; Is it done?  Zero return is over.
	bne EndManageTitleScrolling  ; Nope.  Do again on the next frame.

	lda #0                       ; Reached target position.
	sta VBIEnableScrollTitle     ; Turn off further left scrolling.
	lda #TITLE_RETURN_WAIT       ; Set the timer to wait to restore the title.
	sta RestoreTitleTimer        ; Set new timeout value.

WaitToRestoreTitle               ; Tell Main when to restore title.
	lda RestoreTitleTimer        ; Get timer value.
	beq EndManageTitleScrolling  ; Its 0?  Then skip this.
	dec RestoreTitleTimer        ; Decrement timer when non-zero.

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
	dec BoatyMcBoatCounter        ; subtract from scroll delay counter
	bne ExitBoatyness             ; Not 0 yet, so no animation.

	; One of the boat components will be animated. 
	lda #2                        ; Reset counter to original value.
	sta BoatyMcBoatCounter

	ldx BoatyFrame                ; going to load a frame, which one?
	jsr DoBoatCharacterAnimation  ; load the frame for the current component.

; Finish by setting up for next frame/component.
	inc BoatyComponent            ; increment to next visual component for next time.
	lda BoatyComponent            ; get it to mask it 
	and #$03                      ; mask it to value 0 to 3
	sta BoatyComponent            ; Save it.
	bne ExitBoatyness             ; it is non-zero, so no new frame counter.

; Whenever the boat component returns to 0, then update the frame counter...
	inc BoatyFrame                ; next frame.
	lda BoatyFrame                ; get it to mask it.
	and #$07                      ; mask it to 0 to 7
	sta BoatyFrame                ; save it.

ExitBoatyness


; ======== Manage the prompt flashing for Press A Button ========
ManagePressAButtonPrompt
	lda EnablePressAButton
	bne DoAnimateButtonTimer      ; Not zero means enabled.
	; Prompt is off.  Zero everything.
	sta PressAButtonColor         ; Set background
	sta PressAButtonText          ; Set text.
	sta PressAButtonFrames        ; This makes sure it will restart as soon as enabled.
	beq DoCheesySoundService  

; Note that the Enable/Disable behavior connected to the timer mechanism 
; means that the action will occur when this timer executes with value 1 
; or 0. At 1 it will be decremented to become 0. The value 0 is evaluated 
; immediately.
DoAnimateButtonTimer
	lda PressAButtonFrames   
	beq DoPromptColorchange       ; Timer is Zero.  Go switch colors.
	dec PressAButtonFrames        ; Minus 1
	bne DoCheesySoundService      ; if it is still non-zero end this section.

DoPromptColorchange
	jsr ToggleButtonPrompt        ; Manipulates colors for prompt.

DoCheesySoundService              ; World's most inept sound sequencer.
	jsr SoundService


; ======== Manage scrolling the Credits text ========
ScrollTheCreditLine               ; Scroll the text identifying the perpetrators
	dec ScrollCounter             ; subtract from scroll delay counter
	bne EndOfScrollTheCredits     ; Not 0 yet, so no scrolling.
	lda #2                        ; Reset counter to original value.
	sta ScrollCounter

	jsr FineScrollTheCreditLine   ; Do the business.

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
;==============================================================================

TITLE_DLI  ; Placeholder for VBI to restore staring address for DLI chain.

;==============================================================================
; TITLE_DLI_BLACKOUT                                             
;==============================================================================
; DLI Sets background to Black for blank areas.
;
; Note that the Title screen uses the COLBK table for both COLBK and COLPF2.
; -----------------------------------------------------------------------------

TITLE_DLI_BLACKOUT  ; DLI Sets background to Black for blank area.

	pha

	lda #COLOR_BLACK     ; Black for background and text background.
	sta WSYNC            ; sync to end of scan line
	sta COLBK            ; Write new border color.
	sta COLPF2           ; Write new background color

	tya
	pha
	ldy ThisDLI

	jmp SetupAllOnNextLine_DLI ; Load colors for next DLI and end.


;==============================================================================
; TITLE_DLI_TEXTBLOCK                                             
;==============================================================================
; DLI sets COLPF1 text luminance from the table, COLBK and COLPF2 to 
; start a text block.
; Since there is no text in blank lines, it does not matter that COLPF1 is 
; written before WSYNC.
; Also, since text characters are not defined to the top/bottom edge of the 
; character it is  safe to change COLPF1 in a sloppy way.
; -----------------------------------------------------------------------------

TITLE_DLI_TEXTBLOCK

	mStart_DLI

	lda ColorPf1         ; Get text luminance from zero page.
	sta COLPF1           ; write new text luminance.

	lda ColorBak         ; Get background from zero page.
	sta WSYNC
	sta COLBK
	sta COLPF2

	jmp SetupAllOnNextLine_DLI ; Load colors for next DLI and end.


;==============================================================================
; GAME DLIs
;==============================================================================

;==============================================================================
; SCORE 1 DLI                                                            A 
;==============================================================================
; Used on Game displays.  
; This is called on a blank before the text line. 
; The VBI should have loaded up the Page zero staged colors. 
; Only ColorPF1 matters for the playfield as the background and border will 
; be forced to black. 
; This also sets Player/Missile parameters for P0,P1,P2, M0 and M1 to show 
; the "Score" and "Hi" text.
; Since all of this takes place in the blank space then it does not 
; matter that there is no WSYNC.  
; -----------------------------------------------------------------------------

Score1_DLI

	mStart_DLI

	lda ColorPF1         ; Get text color (luminance)
	sta COLPF1           ; write new text color.

	lda #COLOR_BLACK     ; Black for background and text background.
	sta COLBK            ; Write new border color.
	sta COLPF2           ; Write new background color

	jsr LoadPMSpecs0     ; Load the first table entry into PM registers

; Finish by loading the next DLI's colors.  The second score line preps the Beach.
; This is redundant (useless) (time-wasting) work when not on the game display, 
; but this is also not damaging.

	jmp SetupAllOnNextLine_DLI ; Load colors for next DLI and end.


;==============================================================================
; SCORE 2 DLI                                                            A 
;==============================================================================
; Used on Game displays.  
; This is called on a blank before the text line. 
; The VBI should have loaded up the Page zero staged colors. 
; Only ColorPF1 matters for the playfield as the background and border will 
; be forced to black. 
; This also sets Player/Missile parameters for P0,P1,P2, M0 and M1 to show 
; the "Frogs" and "Saved" text.
; Since all of this takes place in the blank space then it does not 
; matter that there is no WSYNC.  
; -----------------------------------------------------------------------------

Score2_DLI

	mStart_DLI

	lda ColorPF1         ; Get text color (luminance)
	sta COLPF1           ; write new text color.

	jsr LoadPMSpecs1     ; Load the first table entry into PM registers

	; Load HSCROL for the Title display. It should be non-impacting on other displays.
	lda TitleHSCROL      ; Get Title fine scrolling value.
	sta HSCROL           ; Set fine scrolling.

; Finish by loading the next DLI's colors.  The second score line preps the Beach.
; This is redundant (useless) (time-wasting) work when not on the game display, 
; but this is also not damaging.

	jmp SetupAllOnNextLine_DLI ; Load colors for next DLI and end.


;==============================================================================
; GAME_DLI_BEACH0                                               
;==============================================================================
; BEACH 0
; Sets COLPF0,1,2,3,BK for the first Beach line. 
; This is a little different from the other transitions to Beaches.  
; Here, ALL colors must be set. 
; In the later transitions from Boats to the Beach COLPF0 should 
; be setup as the same color as in the previous line of boats.
; COLBAK is temporarily set to the value of COLPF0 to make a full
; scan line of "sky" color matching the COLPF0 sky color for the 
; beach line that follows.
; COLBAK's real land color is set last as it is the color used in the 
; lower part of the beach characters.
; -----------------------------------------------------------------------------

GAME_DLI_BEACH0 

	pha   	; custom startup to deal with a possible timing problem.

	jsr LoadPmSpecs2 ; Copy all entries from column 2 to PM registers 
	
	sta HITCLR       ; Because this is the one and only time this DLI is called.

	lda ColorPF0 ; from Page 0.
	sta WSYNC
	; Top of the line is sky or blue water from row above. 
	; Make background temporarily match the playfield drawn on the next line.
	sta COLBK
	sta COLPF0

	tya
	pha
	ldy ThisDLI
	sty WSYNC

	jmp LoadAlmostAllColors_DLI


;==============================================================================
; GAME_DLI_BEACH2BOAT 
; GAME_DLI_BOAT2BOAT                                                 
;==============================================================================
; After much hackery, code gymnastics, and refactoring, these two 
; routines for boats now work out to the same code.
;
; Boats Right 1, 4, 7, 10 . . . .
; Sets colors for the Boat lines coming from a Beach line.
; This starts on the Beach line which is followed by one blank scan line 
; before the Right Boats.
;
; Boats Left 2, 5, 8, 11 . . . .
; Sets colors for the Left Boat lines coming from a Right Boat line.
; This starts on the ModeC line which is followed by one blank scan line 
; before the Left Boats.
; The Mode C line uses only COLPF0 to match the previous water, and the 
; following "sky".
; Therefore, the color of the line is automatically matched to both prior and 
; the next lines without changing COLPF0.  (For the fading purpose COLPF0
; does need to get reset on the following blank line. 
; HSCROL is set early for the boats.  Followed by all color registers.
; -----------------------------------------------------------------------------

GAME_DLI_BEACH2BOAT ; DLI sets HS, BK, COLPF3,2,1,0 for the Right Boats.
GAME_DLI_BOAT2BOAT  ; DLI sets HS, BK, COLPF3,2,1,0 for the Left Boats.

	mStart_DLI

	lda NextHSCROL    ; Get boat fine scroll.
	pha

	lda ColorBak
	sta WSYNC
	sta COLBK

	pla 
	sta HSCROL        ; Ok to set now as this line does not scroll.

	jmp LoadAlmostAllBoatColors_DLI ; set colors.  then setup next row.


;==============================================================================
; GAME_DLI_BOAT2BEACH                                                     
;==============================================================================
; BEACH 3, 6, 9, 12 . . . .
; Sets colors for the Beach lines coming from a boat line. 
; This is different from line 0, because the DLI starts with only one scan 
; line of Mode C pixels (COLPF0) between the boats, and the Beach.
; The Mode C line uses COLPF0 to match the previous water, with the 
; following "sky".
; Therefore, the color of the line is automatically matched to both prior and 
; the next lines without changing COLPF0.  (For the fading purpose it does 
; need to get set. )
; Since the beam is in the middle of an already matching color this routine 
; can operate without WSYNC up front to set all the color registers as quickly 
; as possible. 
; COLBAK can be re-set to its beach color last as it is the color used in the 
; lower part of the characters.
; -----------------------------------------------------------------------------

GAME_DLI_BOAT2BEACH ; DLI sets COLPF1,2,3,COLPF0, BK for the Beach.

	mStart_DLI

	lda ColorPF0 ; from Page 0.
	; Different from BEACH0, because no WSYNC right here.
	; Top of the line is sky or blue water from row above.   
	; Make background temporarily match the playfield drawn on the next line.
	sta COLBK
	sta COLPF0

	jmp LoadAlmostAllColors_DLI


;==============================================================================
; SPLASH DLIs
;==============================================================================

;==============================================================================
; COLPF0_COLBK_DLI                                                     A
;==============================================================================
; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; same display list structure and DLIs.  
; Sets background color and the COLPF0 pixel color.  
; Table driven.  
; Perfectly re-usable for anywhere Map Mode 9 or Blank instructions are 
; being managed.  In the case of blank lines you just don't see the pixel 
; color change, so it does not matter what is in the COLPF0 color table. 
; -----------------------------------------------------------------------------

COLPF0_COLBK_DLI

	jmp DO_COLPF0_COLBK_DLI


;==============================================================================
; SPLASH_PMGZERO_DLI                                                     A
;==============================================================================
; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; same display list structure and DLIs.  
;
; This first DLI on the title screen needs to do extra work on the 
; player/missiles to remove all the "text" labels from the screen.
; -----------------------------------------------------------------------------

SPLASH_PMGZERO_DLI

	jmp DO_SPLASH_PMGZERO_DLI


;==============================================================================
; SPLASH PMGSPECS2 DLI                                                  A
;==============================================================================
; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; same display list structure and DLIs.  
; Sets background color and the COLPF0 pixel color.
;
; Table driven.  
; Perfectly re-usable for anywhere Map Mode 9 or Blank instructions are 
; being managed.  In the case of blank lines you just don't see the pixel 
; color change, so it does not matter what is in the COLPF0 color table. 
;
; The first DLI on the title screen needs to do extra work 
; on the player/missile data, so I needed another DLI here.
; -----------------------------------------------------------------------------

SPLASH_PMGSPECS2_DLI

	jmp DO_SPLASH_PMGSPECS2_DLI ; DO_COLPF0_COLBK_TITLE_DLI


;==============================================================================
; EXIT DLI.
;==============================================================================
; Common code called/jumped to by most DLIs.
; JMP here is 3 byte instruction to execute 11 bytes of common DLI closure.
; Update the interrupt pointer to the address of the next DLI.
; Increment the DLI counter used to index the various tables.
; Restore registers and exit.
; -----------------------------------------------------------------------------

Exit_DLI

	lda (ThisDLIAddr), y ; update low byte for next chained DLI.
	sta VDSLST

	inc ThisDLI          ; next DLI.

	mRegRestoreAY

DoNothing_DLI ; In testing mode jump here to not do anything or to stop the DLI chain.
	rti


;==============================================================================
; DLI_SPC1                                                            A 
;==============================================================================
; DLI to set colors for the Prompt line.  
; And while we're here do the HSCROLL for the scrolling credits.
; Then link to DLI_SPC2 to set colors for the scrolling line.
; Since there is no text here (running in blank line), it does not matter 
; that COLPF1 is written before WSYNC.
; -----------------------------------------------------------------------------

DLI_SPC1  ; DLI sets COLPF1, COLPF2, COLBK for Prompt text. 

	pha                   ; aka pha

	lda PressAButtonText  ; Get text color (luminance)
	sta COLPF1            ; write new text luminance.

	lda PressAButtonColor ; For background and text background.
	sta WSYNC             ; sync to end of scan line
	sta COLBK             ; Write new border color.
	sta COLPF2            ; Write new background color

	; Overriding the table-driven addresses now to go to DLI_SPC2
	lda #<DLI_SPC2        ; Update the DLI vector for the last routine for credit color.
	sta VDSLST
	lda #>DLI_SPC2        ; Update the DLI vector for the last routine for credit color.
	sta VDSLST+1

	pla                   ; aka pla

	rti


;==============================================================================
; DLI_SPC2                                                            A  Y
;==============================================================================
; DLI to set colors for the Scrolling credits.   
; ALWAYS the last DLI on screen.
; Squeezing screen geometry eliminated a blank line here, so the 
; lazy way HSCROL was set no longer works and causes bizarre 
; corruption at the bottom of the screen.  The routine needed to be 
; optimized to avoid overhead and set HSCROL as soon as possible. 
; -----------------------------------------------------------------------------

DLI_SPC2  ; DLI sets black for background COLBK, COLPF2, and text luminance for scrolling text.

	pha

	lda CreditHSCROL     ; HScroll for credits.
	sta HSCROL

	lda #COLOR_BLACK     ; color for background.
	sta WSYNC            ; sync to end of scan line
	sta COLBK            ; Write new border color.
	sta COLPF2           ; Write new background color

	lda #$0C             ; luminance for text.  Hardcoded.  Always visible on all screens.
	sta COLPF1           ; Write text luminance for credits.

	lda #<DoNothing_DLI  ; Stop DLI Chain.  VBI will restart the chain.
	sta VDSLST
	lda #>DoNothing_DLI
	sta VDSLST+1

	pla 

	rti


;==============================================================================
; LOAD COLORS -- Common targets JMP'd here from other places.
;==============================================================================
; LOAD ALL COLORS_DLI             - load PF0, then BAK, PF1, PF2, PF3.
; LOAD ALMOST ALL COLORS_DLI      - load BAK, PF1, PF2, PF3 (not PF0).
; SETUP ALL ON NEXT LINE_DLI      - increment line index, then prep colors for 
;                                   the next DLI.
; SETUP ALL COLORS_DLI            - prep colors for DLI based on current line 
;                                   index.
; LOAD ALMOST ALL BOAT COLORS_DLI - load PF0, PF1, PF2, PF3 from Page zero.
;
; Common code called/jumped to by DLIs.
; JMP here is 3 byte instruction to execute 11 bytes of common DLI closure.
; Load the staged values, store in the color registers.
; -----------------------------------------------------------------------------

LoadAlmostAllColors_DLI

	lda ColorBak   ; Get real background color again. (To repair the color for the Beach background)
	sta WSYNC
	sta COLBK

	lda ColorPF1   ; Get color Rocks 2
	sta COLPF1
	lda ColorPF2   ; Get color Rocks 3 
	sta COLPF2
	lda ColorPF3   ; Get color water (needed for fade-in)
	sta COLPF3


SetupAllOnNextLine_DLI

	iny

	jsr SetupAllColors

	dey

	jmp Exit_DLI


; Called by Beach 2 Boat
LoadAlmostAllBoatColors_DLI

	lda ColorPF1   
	sta COLPF1
	lda ColorPF2   
	sta COLPF2
	lda ColorPF3   
	sta COLPF3
	lda ColorPF0 
	sta COLPF0

	jmp SetupAllOnNextLine_DLI


;==============================================================================
; SET UP ALL COLORS                                                       A  Y
;==============================================================================
; Given value of Y, pull that entry from the color and scroll tables
; and store in the page 0 copies.
; This is called at the end of a DLI to prepare for the next DLI in an attempt
; to optimize the start of the next DLI's using the values.  
; (Because for some reason Altirra is glitching the game screen, but 
; Atari800 seems OK.)
; -----------------------------------------------------------------------------

SetupAllColors

	lda COLPF0_TABLE,y   ; Get color Rocks 1   
	sta ColorPF0
	lda COLPF1_TABLE,y   ; Get color Rocks 2
	sta ColorPF1
	lda COLPF2_TABLE,y   ; Get color Rocks 3 
	sta ColorPF2
	lda COLPF3_TABLE,y   ; Get color water (needed for fade-in)
	sta ColorPF3
	lda HSCROL_TABLE,y   ; Get boat fine scroll.
	sta NextHSCROL
	lda COLBK_TABLE,y    ; Get background color .
	sta ColorBak

	rts


;==============================================================================
; DO_COLPF0_COLBK_DLI                                                     A
;==============================================================================
; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; same display list structure and DLIs.  
; Sets background color and the COLPF0 pixel color.  
; Table driven.  
; Perfectly re-usable for anywhere Map Mode 9 or Blank instructions are 
; being managed.  In the case of blank lines you just don't see the pixel 
; color change, so it does not matter what is in the COLPF0 color table. 
; -----------------------------------------------------------------------------

DO_COLPF0_COLBK_DLI

	mStart_DLI

	lda COLPF0_TABLE,y   ; Get pixels color
	pha
	lda COLBK_TABLE,y    ; Get background color

	sta WSYNC
	
	sta COLBK            ; Set background
	pla
	sta COLPF0           ; Set pixels.

	jmp Exit_DLI


;==============================================================================
; DO_SPLASH_PMGZERO_DLI                                              A
;==============================================================================
; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; same display list structure and DLIs.  
; Sets PM HPOS to 0 for all objects.
; This is needed early on splash screens because the first group of 
; objects extend below the first colored background lines.   This causes
; bits of the PMG text labels to appear on the splash screen.
; -----------------------------------------------------------------------------

DO_SPLASH_PMGZERO_DLI

	mStart_DLI

	jsr libSetPmgHPOSZero 

	jmp Exit_DLI


;==============================================================================
; DO_SPLASH_PMGSPECS2_DLI                                               A
;==============================================================================
; The three graphics screen (Saved, Dead Frog, and Game Over) have exactly the
; same display list structure and DLIs.  
; Sets background color and the COLPF0 pixel color.  
; Table driven.  
; Perfectly re-usable for anywhere Map Mode 9 or Blank instructions are 
; being managed.  In the case of blank lines you just don't see the pixel 
; color change, so it does not matter what is in the COLPF0 color table. 
; -----------------------------------------------------------------------------

DO_SPLASH_PMGSPECS2_DLI

	mStart_DLI

	lda COLPF0_TABLE,y   ; Get pixels color
	pha
	lda COLBK_TABLE,y    ; Get background color
	
	sta WSYNC
	
	sta COLBK            ; Set background
	pla
	sta COLPF0           ; Set pixels.

	jsr LoadPmSpecs2     ; Load the first table entry into 

	jmp Exit_DLI


;==============================================================================
; LOAD PM SPECS 0                                                       A 
;==============================================================================
; Called by Score 1 DLI.
; Load the table entry 1 values for P0,P1,P2,P3,M0,M1,M2,M3  
; to the P/M registers.
; -----------------------------------------------------------------------------

LoadPmSpecs0

	lda PRIOR_TABLE
	sta PRIOR

	lda HPOSP0_TABLE
	sta HPOSP0
	lda COLPM0_TABLE 
	sta COLPM0
	lda SIZEP0_TABLE
	sta SIZEP0

	lda HPOSP1_TABLE
	sta HPOSP1
	lda COLPM1_TABLE 
	sta COLPM1
	lda SIZEP1_TABLE
	sta SIZEP1

	lda HPOSP2_TABLE
	sta HPOSP2
	lda COLPM2_TABLE 
	sta COLPM2
	lda SIZEP2_TABLE
	sta SIZEP2

	lda HPOSP3_TABLE
	sta HPOSP3
	lda COLPM3_TABLE 
	sta COLPM3
	lda SIZEP3_TABLE
	sta SIZEP3
	
	lda SIZEM_TABLE
	sta SIZEM
	lda HPOSM0_TABLE
	sta HPOSM0
	lda HPOSM1_TABLE
	sta HPOSM1
	lda HPOSM2_TABLE
	sta HPOSM2
	lda HPOSM3_TABLE
	sta HPOSM3

	rts


;==============================================================================
; LOAD PM SPECS 1                                                       A 
;==============================================================================
; Called by Score 2 DLI.
; Load the table entry 1 values for P0,P1,P2,P3,M0,M1,M2,M3 
; to the P/M registers.
; -----------------------------------------------------------------------------

LoadPmSpecs1

	lda PRIOR_TABLE+1
	sta PRIOR

	lda HPOSP0_TABLE+1
	sta HPOSP0
	lda COLPM0_TABLE+1
	sta COLPM0
	lda SIZEP0_TABLE+1
	sta SIZEP0

	lda HPOSP1_TABLE+1
	sta HPOSP1
	lda COLPM1_TABLE+1 
	sta COLPM1
	lda SIZEP1_TABLE+1
	sta SIZEP1

	lda HPOSP2_TABLE+1
	sta HPOSP2
	lda COLPM2_TABLE+1 
	sta COLPM2
	lda SIZEP2_TABLE+1
	sta SIZEP2

	lda HPOSP3_TABLE+1
	sta HPOSP3
	lda COLPM3_TABLE+1 
	sta COLPM3
	lda SIZEP3_TABLE+1
	sta SIZEP3

	lda SIZEM_TABLE+1
	sta SIZEM
	lda HPOSM0_TABLE+1
	sta HPOSM0
	lda HPOSM1_TABLE+1
	sta HPOSM1
	lda HPOSM2_TABLE+1
	sta HPOSM2
	lda HPOSM3_TABLE+1
	sta HPOSM3

	rts


;==============================================================================
; LOAD PM SPECS 2                                                       A 
;==============================================================================
; Called on Title, Game, and Game Over displays.
; Load the table entry 2 values for P0,P1,P2,P3,M0,M1,M2,M3 
; to the P/M registers.
; -----------------------------------------------------------------------------

LoadPmSpecs2

	lda PRIOR_TABLE+2
	sta PRIOR

	lda HPOSP0_TABLE+2
	sta HPOSP0
	lda COLPM0_TABLE+2
	sta COLPM0
	lda SIZEP0_TABLE+2
	sta SIZEP0

	lda HPOSP1_TABLE+2
	sta HPOSP1
	lda COLPM1_TABLE+2 
	sta COLPM1
	lda SIZEP1_TABLE+2
	sta SIZEP1

	lda HPOSP2_TABLE+2
	sta HPOSP2
	lda COLPM2_TABLE+2 
	sta COLPM2
	lda SIZEP2_TABLE+2
	sta SIZEP2

	lda HPOSP3_TABLE+2
	sta HPOSP3
	lda COLPM3_TABLE+2 
	sta COLPM3
	lda SIZEP3_TABLE+2
	sta SIZEP3

	lda SIZEM_TABLE+2
	sta SIZEM
	lda HPOSM0_TABLE+2
	sta HPOSM0
	lda HPOSM1_TABLE+2
	sta HPOSM1
	lda HPOSM2_TABLE+2
	sta HPOSM2
	lda HPOSM3_TABLE+2
	sta HPOSM3

	rts

