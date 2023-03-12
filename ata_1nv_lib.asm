;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2023 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; LIBRARY
; 
; The pieces parts that are borroweed from my generic library 
; of common functions.
;
; These are things that are so repeatable across games that they 
; have become "library" functions.
; --------------------------------------------------------------------------


;==============================================================================
;                                                      ANY JOYSTICK BUTTON  A
;==============================================================================
; Subroutine to verify neither player is pressing the joystick button,
; and then  for any player to press a button.
;
; This is used on Title screen and Game Over screen.
;
; Return A == debounce 
;            1 waiting for debounce, 
;            0 debounce occurred,
;           -1 button pressed after debounce cleared.
;==============================================================================

gDEBOUNCE_JOY_BUTTONS .byte 0 ; Flag to make sure joystick buttons are released.

libAnyJoystickButton          ; get joystick button and debounce it.

	lda STRIG0
	and STRIG1                ; 0 means one or both buttons are pressed.
	bne b_ClearDebounce       ; 1 means both buttons are not pressed.
	
	; A button is pressed 
	lda gDEBOUNCE_JOY_BUTTONS ; If debounce flag is on 
	bne b_AnyButton_Exit      ; then ignore the button. 

	lda #$ff                  ; A button is pressed when debounce is off.
	rts

b_ClearDebounce               ; Nobody is pressing a button.
	lda #0                    ; Since the buttons are released
	sta gDEBOUNCE_JOY_BUTTONS ; then remove the debounce flag 

b_AnyButton_Exit
	rts


;==============================================================================
;                                                      A JOYSTICK BUTTON  A
;==============================================================================
; Subroutine to insure a player releases the button before 
; pressing it again.  
;
; This is used during Game play as it evaluates each player independently.
;
; When in Onesie mode Debounce and input are processed for only the 
; currently active shooter.  In fact, if this is not the active shooter, 
; then keep the debounce value forced on.
;
; X = Player of interest, (0, 1)
;
; Return A == debounce 
;            1 waiting for debounce, 
;            0 debounce occurred,
;           -1 button pressed after debounce cleared.
;==============================================================================

; gDEBOUNCE_JOY_BUTTON .byte 0,0 ; Flags to make sure joystick buttons are released.

libAJoystickButton             ; get joystick button and debounce it.

	lda gConfigOnesieMode      ; Is Onsie on?
	beq b_lajb_DoScan          ; Nope. Do not filter anything.

	lda zPLAYER_ONE_ON         ; Are both players playing?
	and zPLAYER_TWO_ON
	beq b_lajb_DoScan          ; Nope. Do not filter anything.

	cpx gONESIE_PLAYER         ; Is Active Onesie the current choice to scan?
	beq b_lajb_DoScan          ; Yes.   Can do the scan.

	lda #1                     ; No. Pretend waiting for debounce.
	rts

b_lajb_DoScan
	lda STRIG0,X
	bne b_lajb_ClearDebounce   ; 1 means the button not pressed.
	
	; 0 means the button is (still) pressed 
	lda zPLAYER_DEBOUNCE,X     ; If debounce flag is on 
	bne b_lajb_AnyButton_Exit  ; then ignore the button. 

	lda #$ff                   ; A button is pressed after debounce..
	rts

b_lajb_ClearDebounce           ; Nobody is pressing a button.
	lda #0                     ; Since the buttons are released
	sta zPLAYER_DEBOUNCE,X     ; then remove the debounce flag 

b_lajb_AnyButton_Exit
	rts


libResetJoystickDebounce

	lda #1
	sta zPLAYER_DEBOUNCE,X
	rts


;==============================================================================
;                                                       ANY CONSOLE BUTTON A
;==============================================================================
; Subroutine to wait for all console key to be released, and then 
; collect the button pressed the first time. 
;
; Return A == debounce 
;            1 waiting for debounce, 
;            0 debounce occurred,
;           -1 button pressed after debounce cleared.
;==============================================================================

gDEBOUNCE_OSS      .byte 0 ; Flag that Option/Select/Start are released.
gOSS_KEYS          .byte 0 ; Current Option/Select/Start bits.

libAnyConsoleButton        ; get Function buttons and debounce them.

	lda CONSOL             ; console keys 0 when pressed
	and #CONSOLE_KEYS      ; just keep the Option/Select/Start bits.
	sta gOSS_KEYS          ; save for later
	cmp #CONSOLE_KEYS      ; If keys is the same value as mask...
	beq b_ClearOSSDebounce ; then none of the buttons are pressed.

	; A button is pressed 
	lda gDEBOUNCE_OSS      ; If debounce flag is on (1)
	bne b_OSSButton_Exit   ; then ignore the buttons. 

	lda #$ff               ; A button is pressed when debounce is off.
	sta gDEBOUNCE_OSS      ; let code know key(s) are recorded.
	sta gOSS_Timer         ; then reset the input timer.
	rts

b_ClearOSSDebounce         ; Nobody is pressing a button.
	lda #0                 ; Since the buttons are released
	sta gDEBOUNCE_OSS      ; then remove the debounce flag 

b_OSSButton_Exit
;	lda #0                 ; waiting for debounce.
;	sta gOSS_KEYS          ; make it look like all keys are pressed.
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



; ==========================================================================
; SUPPPORT - MEMSET
; ==========================================================================
; Assuming Dst have been set up in zMemSet var.
;
; Y ==  real number of bytes.  (min 1, max 128)
; A ==  value to write.
;
; Return Value:
; Neg flag = error
; Z flag   = success.
; --------------------------------------------------------------------------

libMemSet

	dey                 ;  turn 1 to 128 into 0 to 127
	bmi b_lms_Exit      ; 0 became -1 (or using other out of range value.)

b_lms_Loop
	sta (zMemSet_Dst),y
	dey
	bpl b_lms_Loop      ; Continue through Y = 0.  Stop at Y = -1
	ldy #0              ; Set Z flag, Clear negative flag.

b_lms_Exit
	rts


; ==========================================================================
; SUPPPORT - MEMCPY
; ==========================================================================
; Assuming Src and Dst have been set up in zMemCpy vars.
;
; Y ==  real number of bytes.  (min 1, max 128)
;
; Return Value:
; Neg flag = error
; Z flag   = success.
; --------------------------------------------------------------------------

libMemCpy

	dey                 ;  turn 1 to 128 into 0 to 127
	bmi b_lmc_Exit      ; 0 became -1 (or using other out of range value.)

b_lmc_Loop
	lda (zMemCpy_Src),y
	sta (zMemCpy_Dst),y
	dey
	bpl b_lmc_Loop      ; Continue through Y = 0.  Stop at Y = -1
	ldy #0

b_lmc_Exit
	rts

