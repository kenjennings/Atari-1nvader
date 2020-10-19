;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; GAME MAIN LOOP
; 
; Each TV frame is one game cycle.   There is the main line code here 
; that occurs while the frame is being display.  Its job is to compute 
; and do things indirectly that should be updated on the display during 
; the VBI.
;
; In the "Interrupts" file the VBI takes care of most graphics updates, 
; and the DLIs produce the per-scanline changes needed at different 
; points on the display.
; 
; The game operates in states.  Basically, a condition of waiting for 
; an event to occur to transition the game to the next state.
; The main states are Title screen, Game screen, Game Over.
; While in a state the main loop and VBI are cooperating to run 
; animated components on the screen.  
;
; Example:  The Title Screen 
;
; The VBI manages the timing, performs the page flipping for the graphics, 
; sets the Missile color overlay horizontal position and color.  The main 
; code watches the timing clock for animation and updates the Missile 
; color overlay image when needed.
;
; The Title Screen state is waiting on a joystick button to leave 
; the state.   Then the next state is a transitional condition that 
; runs animation for the 3, 2, 1, GO animation while it waits for the 
; other player to press a button.  
;
; After that the next state is a transition animation to move the large
; mothership off the screen to go to the state for the Game Screen. 
; --------------------------------------------------------------------------

TABLE_GAME_FUNCTION
	.word GameInit-1       ; 0  = EVENT_INIT
	.word GameSetupTitle-1 ; 1  = EVENT_SETUP_TITLE
	.word GameTitle-1      ; 2  = EVENT_TITLE
	.word GameCountdown-1  ; 3  = EVENT_COUNTDOWN
	.word GameSetupMain-1  ; 4  = EVENT_SETUP_GAME    
	.word GameMain-1       ; 5  = EVENT_GAME
	.word GameLastRow-1    ; 6  = EVENT_LAST_ROW     
	.word GameSetupOver-1  ; 7  = EVENT_SETUP_GAMEOVER  
	.word GameOcver-1      ; 8  = EVENT_GAMEOVER




; ==========================================================================
; GAME LOOP
;
; The main event dispatch loop for the game... said Capt Obvious.
; Very vaguely like an event loop or state loop across the progressive
; game states which are (loosely) based on the current mode of
; the display.
;
; Each event sets CurrentEvent to change to another event target.
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

