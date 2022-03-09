;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
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
; Subroutine to verify no player is pressing the joystick button,
; and then  for any player to press a button.
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
	rts

b_ClearOSSDebounce         ; Nobody is pressing a button.
	lda #0                 ; Since the buttons are released
	sta gDEBOUNCE_OSS      ; then remove the debounce flag 

b_OSSButton_Exit
	lda #0                 ; waiting for debounce.
	sta gOSS_KEYS          ; make it look like all keys are pressed.
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

