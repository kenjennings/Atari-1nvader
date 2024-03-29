;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2023 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; SUPPORT CODE
; 
; The pieces parts that perfrom individual functions within the game.
;
; These are called by the top level events for the game.  Most by the 
; Main loop, some by the VBI section.
; --------------------------------------------------------------------------


; ==========================================================================
; SUPPORT - FRAME MANAGEMENT
; ==========================================================================
; Runs at the start of VBI.  
;
; Manages PAL/NTSC frame counter.
; 
; Based on the Frame counter determine the next Increment value 
; for horizontal player movement, vertical laser movement, and 
; mothership horizontal movement (also based on speed).
; 
; The joy of this is that this code, and all the other position code 
; doesn't care if we're in PAL or NTSC.  Everything is driven by 
; table data.  Once the initalization code determined  PAL or NTSC, then 
; everything after becomes automatic.
;
; This is "common" and called all the time regardless of screen state to 
; mitigate against stuttering that may happen when timer work starts and
; stops.   Also, this could be extended to cover any as yet unknown
; timing situations due to further embelishments.
; --------------------------------------------------------------------------

gFrameAsIndex      .byte $00 ; (Frame * 2) +  PAL(0) or NTSC(1)
gFrameAsLaserIndex .byte $00 ; Laser Speed + ( Frame * 2) + PAL(0) or NTSC(1)
FrameManagement

	lda #0                  ; Lazy way of turning off attract mode.
	sta ATRACT              ; Because I'm too lazy to EOR everything.

	inc gTHIS_FRAME         ; Next Frame value
	lda gTHIS_FRAME          
	cmp gMaxNTSCorPALFrames ; compare to limit
	bne b_fm_SkipFrameReset ; If not at limit, continue 

	lda #0
	sta gTHIS_FRAME         ; Reset Frame value

b_fm_SkipFrameReset

	asl                     ; Frame counter value times 2
	sta gFrameAsIndex       ; Save for later
	tax

	lda gNTSCorPAL          ; Plus 0 or 1 for video mode...
	beq b_fm_SkipIncIndex   ; If 0 (PAL), then no increment
	inx
	stx gFrameAsIndex

b_fm_SkipIncIndex

	lda TABLE_PLAYER_CONTROL,x ; Determine Player X increment/decrement
	sta gINC_PLAYER_X

	lda gFrameAsIndex
	clc
	adc gConfigLaserSpeed
	tax

	lda TABLE_LASER_CONTROL,x ; Determine shot Y decrement
	sta gINC_LASER_Y

	jsr FrameControlMothershipSpeed ; Determine Mothership X increment

	rts


; ==========================================================================
; SUPPORT - FRAME CONTROL MOTHERSHIP SPEED
; ==========================================================================
; Callable by VBI or anytime.
;
; Given the current frame, and the mothership speed, set the 
; increment value.
;
; Called on every frame by the VBI.   Called by main code any time
; the mothership speed changes.
;
; Assume the gFrameAsIndex was already set by prior VBI.
; --------------------------------------------------------------------------

FrameControlMothershipSpeed

	; Determine Mothership X increment
	ldy gMOTHERSHIP_MOVE_SPEED  ; Get speed.

;	; HACKERY
;	ldy #7

	lda TABLE_TIMES_TWELVE,y    ; Times 12 for array size
	clc
	adc gFrameAsIndex           ; Add to current index (already calculated)
	tax                         ; use as index
	lda TABLE_SPEED_CONTROL,x   ; Get mothership speed from table.
;	sta gINC_MOTHERSHIP_X       ; Save for reference later.
	sta gMOTHERSHIP_MOVEMENT    ; save for code to use later

	rts


; ==========================================================================
; SUPPORT - PLAYERS SELECTION INPUT
; ==========================================================================
; Runs during Title screen and Countdown
; 
; Buttons transition to selecting players for game play.
;
; Check for input from idle players to begin the countdown before playing.
;
; If a Player(s) are already intending to play skip the player input.
;
; Returns:
; ++ if one or both players are ready to play. 
; 0 if both players are idle.
; --------------------------------------------------------------------------

PSI_Response .byte $00        ; Flag if Player Input requires later work

PlayersSelectionInput

	lda #0
	sta PSI_Response

	jsr libAnyJoystickButton ; If debounce occurred then allow input.
	bpl b_psi_Exit           ; 0 or 1 is No button press.  Waiting for debounce or debounce occurred.

	ldx #0
	jsr PlayerSelectionInput

	ldx #1
	jsr PlayerSelectionInput

b_psi_Exit
	lda PSI_Response           ; Player 1 and 2 are both Off/idle or one is playing. 

	rts


; ==========================================================================
; SUPPORT - PLAYER SELECTION INPUT
; ==========================================================================
; Check for input from idle players to begin the countdown before playing.
;
; If a Player is already intending to play skip the player input.
;
; X = The player to check/process...  0 or 1
;
; Returns:
; ++ PSI_RESPONSE if player is ready to play. 
; --------------------------------------------------------------------------

PlayerSelectionInput

	lda zPLAYER_ON,X           ; (0) not playing. (FF)=Title/Idle  (1) playing.
	bmi b_ppsi_TryPlayerIdle   ; Not playing yet, so test it.
	beq b_ppsi_Exit            ; 0 isn't supposed to be possible.
	inc PSI_Response           ; PLAYER_ON == 1, so playing.
	bne b_ppsi_Exit

b_ppsi_TryPlayerIdle           ; Player is idle.  ($FF  is idle)
	lda STRIG0,X               ; (Read) TRIG0 - Joystick trigger (0 is pressed. 1 is not pressed)
	bne b_ppsi_Exit            ; 1 == Not pressed.  Go to player 2
	; ldy #PLAYER_ONE_SHOOT
	; jsr PlaySound 
	lda #$1                    ; (1) playing.
	sta zPLAYER_ON,X           ; Signal to all that this player is playing.
	sta PSI_Response           ; +1 Signal that a player is in motion.
	jsr GameZeroPlayerScore    ; And Zero the score on screen.

b_ppsi_Exit
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

	ldx #0
	jsr MovePlayerUp

	ldx #1
	jsr MovePlayerUp

b_mpu_Exit
	lda PSI_Response           ; Player 1 and 2 are both Off/idle or one is playing. 

	rts


; ==========================================================================
; SUPPORT - MOVE PLAYER UP
; ==========================================================================
; Runs during Title screen and Countdown
; 
; If the Player selects to begin game, then move the gun up.
; Given that this is an animation that takes several frames
; this needs to be able to run during the final moments of the 
; big Mothership flying up in case the player presses the button 
; very late during the countdown.
;
; This routine separates the movement from the input activity, so the 
; movement can continue when the polling for input has ceased.
;
; Process movement means:
; If current position does not equal current state, then move the Y position.
; The VBI will do the actual redraw.
;
; X is the Player to check.  0 to 1
;
; Returns:
; -- if either player is not yet in playing position. (continue animation)
; ++ if both players are ready to play. 
; 0 if both players are idle.
; --------------------------------------------------------------------------

MovePlayerUp

	lda zPLAYER_ON,X           ; (0) not playing. (FF)=Title/Idle  (1) playing (moving)
	beq b_mmpu_Exit            ; Zero is not playing
	bmi b_mmpu_Exit            ; Negative is not really playing (yet)

	lda zPLAYER_Y,X            ; Here we know Player is Playing.  ($1 is playing)
	cmp #PLAYER_PLAY_Y         ; Is it at the Playing position?
	bne b_mmpu_MovePlayerUp    ; Not yet.  Move it up.

	lda PSI_Response           ; Is other player not ready? (Ready is lower priority than not ready).
	bmi b_mpu_Exit             ; Already negative means a player is in motion.  Skip the rest.

	lda #1
	sta PSI_Response           ; Yes. Ready to Play.
	bne b_mmpu_Exit            ; Done here.

b_mmpu_MovePlayerUp
	lda #$FF
	sta PSI_Response           ; -1 Signal that this is still in motion.
	dec zPLAYER_NEW_Y,X        ; Tell VBI to move up one scan line.

b_mmpu_Exit
	rts


; ==========================================================================
; ADD SCORE TO PLAYER
; ==========================================================================
; Add the Mothership points to the player credited with the hit.
; --------------------------------------------------------------------------

GameAddScoreToPlayer

	ldx #0
	jsr GameAddScore

	ldx #1
	jsr GameAddScore

	rts


; ==========================================================================
; ADD SCORE
; ==========================================================================
; If this player shot the mothership, then:
; - Count the hit againt the mothership's hit counter.
; - Add the Mothership points to the player credited with the hit.
;
; Working with individual bytes per digit means the carry flag will 
; not occur in CPU.   The carry state is determined by logic, then
; the A register is started with 0 or 1 per carry for the math
; on the next digit.
;
; I'm sure this is highly-awful, sub-optimal, low-quality hackage.
;
; X == Player to award points (if the player shot the sheriff).
; --------------------------------------------------------------------------

GameAddScore

	lda zPLAYER_SHOT_THE_SHERIFF,X     ; Did this player get the hit?
	beq b_gas_Exit                     ; No.  Nothing to do here.

	stx SAVEX
	jsr GameDecrementHitCounter       ; Player award means minus 1 hit.
	ldx SAVEX

	lda #0                             ; Clear the artificial carry.
	ldy #5                             ; Index into mothership points.

	cpx #0                             ; If this is not zero, then
	bne b_gas_OtherPlayer              ; set index into score for player 2

	ldx #5                             ; Index into Player score. (For player 1)
	bne b_gas_AddLoop                  ; Go add.

b_gas_OtherPlayer
	ldx #11                            ; Index into Player score. (For player 2)                 

b_gas_AddLoop                          ; on first entry A for carry == 0
	clc                                ; Clear CPU carry.
	adc gPLAYERPOINTS_TO_ADD,Y         ; Add mothership points (+ A as carry)
	adc gPLAYER_SCORE,X                ; Add to player score

	cmp #10                            ; Did Adding go over 9? (>= 10? )
	bcc b_gas_NoCarry                  ; No.  Do not carry.

b_gas_Carried                          ; Player score carried over 9.
	sec
	sbc #10                            ; Subtract 10 from score
	sta gPLAYER_SCORE,X                ; Save the adjusted score.
	lda #1                             ; Setup 1 for artificial carry.
	bne b_gas_LoopControl              ; Go to end of loop

b_gas_NoCarry                          ; Player score carried over 9.
	sta gPLAYER_SCORE,X                ; Save the added score.
	lda #0                             ; Setup 0 for artificial carry.

b_gas_LoopControl    
	dex                                ; Move left to next digit
	dey                                ; Move left to next digit
	bpl b_gas_AddLoop                  ; Loop until index goes to -1

b_gas_Exit
	rts


; ==========================================================================
; CHECK HIGH SCORE
; ==========================================================================
; Test Player score v High score, and copy player score to high 
; score if greater than the high score.
; 
; X == player to test
; --------------------------------------------------------------------------

GameCheckHighScores

	ldx #0
	jsr GameCheckHighScore

	ldx #1
	jsr GameCheckHighScore

	rts


; ==========================================================================
; CHECK HIGH SCORE
; ==========================================================================
; Test Player score v High score, and copy player score to high 
; score if greater than the high score.
; 
; X == player to test
; --------------------------------------------------------------------------

GameCheckHighScore

	lda gConfigCheatMode           ; Is cheat mode on?
	bne b_gchs_Exit                ; Yup.  Skip considering high score.

	lda zPLAYER_ON,X
	beq b_gchs_Exit

	ldy #0                         ; Index into high score points.

	cpx #0                         ; If this is first player, then X is 
	beq b_ghcs_SaveX               ; already 0 for score index.  Just go.

	ldx #6                         ; Index into score for player 1 

b_ghcs_SaveX
	stx SAVEX                      ; Need to get this X value back again later.

b_gchs_CheckLoop                   ; Check while digits are equal.
	lda gPLAYER_SCORE,X
	cmp gHIGH_SCORE,Y              
	beq b_gchs_LoopControl         ; If it is the same continue looping.
	bcc b_gchs_Exit                ; If it is less than, then exit.  No hi score.

	; A digit is greater than hi score, so copy!
	ldx SAVEX                      ; Restore index value determined earlier.
	ldy #0                         ; Index into high score points.

b_gchs_CopyHiScoreLoop
	lda gPLAYER_SCORE,X            ; Copy the six 
	sta gHIGH_SCORE,Y              ; bytes of the 
	inx                            ; player score
	iny                            ; to the 
	cpy #6                         ; high score.
	bne b_gchs_CopyHiScoreLoop
	rts

b_gchs_LoopControl                 
	inx                            ; next index in player score.
	iny                            ; Next index in high score
	cpy #6
	bne b_gchs_CheckLoop

b_gchs_Exit
	rts


; ==========================================================================
; SUPPORT - MOVE GAME PLAYERS GUNS
; ==========================================================================
; Runs during main Game
; 
; 1) Run Player movement.
;    a) bounce if gun collides with bumper.
;    b) bounce if guns collide with each other.
;
; Move the players' guns during the game.
; This is all about the calculations to change position.
; The actual redraw takes place during the VBI.
;
; Talking (or random babbling) out loud to myself....  Pay no attention
; to the mubling man walking randomly on the sidewalk.  Do not give 
; him matches.  Do not give him money.
;
; This is the gruesome logic part.  The main routine is evaluating where
; the guns are now to decide where they should be on the next frame. 
; The current location is where the VBI drew everything and is where it 
; will appear on the current frame being drawn for the human player.
;
; Collision comparison is all done on the basis of horizontal position, 
; not hardware collision detection.  Guns in play may never overlap each 
; other or the bumpers, therefore no opportiunity for hardware collision.
;
; (Hardware collision detection is used for missles impacting the 
; mothership, but this is a different discussion.  Go away and look for 
; that routine and leave me alone now.)
;
; When both guns are traveling in opposite directions and meet perfectly 
; with no overlap, then both get a direction change at the same time.  
; (One of the simplest situations).
;
; When approaching the bumpers the player on that side of the screen 
; closest to the bumper is the one that owns pixel space concerning 
; gun to bumper and gun to gun collision at the bumber.  The general rule
; is that when two players are active, Gun 1 owns free pixel space when 
; moving left toward the left bumper, and Gun 2 owns free pixel space when 
; moving right toward the right bumper.
;
; Extending this, if gun 1 and gun 2 are exactly next to each other AND they 
; are traveling in the same direction, then there is not an exception to 
; bounce either gun.  UNLESS, the guns have reached the bumper at the edge 
; of the screen, then a bounce occurs.  In this case, both guns must 
; bounce to the opposite direction.  (Logically, it must be impossible for 
; both guns to reach the maximum position adjacent to a bumper while 
; having opposite flags set for direction of travel.)
;
; The hard part here is to maintain fairness in the border conditions 
; between gun 1 and gun 2.  At some edge conditions where the guns are 
; right next to each other the directional values create exceptions.
; In the end perfect fairness is impossible.   Two guns cannot cross into
; the same pixel space.   Therefore, the exception here is that when Gun 1
; owns the free pixel and can move there to trigger direction change, 
; then Gun 2 can only triggers direction change from its current 
; position without moving into the empty pixel space.
;
; Reminder: Gun 1 owns pixel space on the left side of the screen, Gun 2 
; owns pixel space on the right side of the screen.   (Easy to tell...
; ldx X_POSITION ; bmi right side of screen. coordinate 128 is the middle 
; of the screen -- almost -- but, this is good enough for military work.)
;
; The situation occurs when the guns are traveling in opposite directions, 
; and will meet each other with only one blank pixel between them.  
; They cannot both occupy that blank space.
; 
; A bounce at the bumper would look like this: (B)umper (<)Gun (<)Gun
; B <<   <- Next frame will move to the bumper
; B>>    <- When new position is exactly next to bumper, then bounce both.
; B >>   <- Both traveling with no gap.
; 
; More complicated: One space/pixel between Guns on the left of the screen:
; B < <   <- Next frame Gun 1 will move next to bumper.
; B> <    <- Gun 1 on bumper is flagged to bounce in opposite direction
; B X     <- Here it is impossible for both guns to move to the same space
; B <>    <- Thus, Gun 1 moves, Gun 2 does not, both register the bounce.
; B>  >   <- Note that this creates an extra pixel gap between them
;
; What happens at the right bumper, because Gun 1 owns space....
; > > B   <- Next frame Gun 2 will move next to the bumper.
;  > <B   <- Gun 2 flagged to bounce in opposite direction
;   X B   <- Here it is impossible for both guns to move to the same space
;  <> B   <- Thus, Gun 2 moves, Gun 1 does not, both register bounce.
; <  <B   <- Note this creates an extra pixel gap between them.
;
; --------------------------------------------------------------------------

GamePlayersMovement

;	lda zAnimatePlayers   ; Check timer to delay movment. (VBI updates)
;	bne b_gpm_Exit        ; Timer not 0, so still running.

;	lda #2                ; Player movement timer expired.  
;	sta zAnimatePlayers   ; Reset it.
	
	lda gINC_PLAYER_X     ; Check if movement is allowed on this frame.
	beq b_gpm_Exit        ; No.  So, no need to do anything.

	; First, run through the easy choices first that don't involve 
	; interaction between the two players.
	
	ldx #0
	stx zPLAYER_ONE_BUMP ; Clear the bump direction flags
	stx zPLAYER_TWO_BUMP 

	jsr GameMovePlayerLeft    ; For Player 1 (X == 0 )
	jsr GameMovePlayerRight

	ldx #1
	jsr GameMovePlayerRight   ; For Player 2 (X == 1 ) 
	jsr GameMovePlayerLeft

	; At this point the players have moved left or right, and 
	; rebounded from the bumpers if applicable.   No 
	; consideration of player collisions has occurred yet.

	; If there is only one player playing, whether player 1 or 2, 
	; then the player's gun movement has been solved, and no more
	; logic is needed.

	lda zPLAYER_ONE_ON ; Check if both players are playing.
	and zPLAYER_TWO_ON
	beq b_gpm_Exit     ; Only one player.  (0&1 = 0, 1&0 = 0)  Finito.

	; Further Work on both players moving...  possible collision.  

; Side note...  In theory if the players collide on the same frame that
; one of the players shoots, then that player will reverse direction,
; and so will both players be moving in the same direction but they 
; overlap?   I don't think this should actually happen.   Here the 
; game resolves the basic collision due to movement.  After this they 
; will not overlap and they will be going in opposite directions.   
; The shooting has not yet been evaluated.  This collision code will 
; flag that directions changed, so that if shooting also begins on 
; this frame, the direction will not reverse.  This should prevent the
; shooting player from reversing directions and overlapping the other
; player moving in the same direction.

	lda zPLAYER_ONE_DIR ; Are both moving in the same direction?
	cmp zPLAYER_TWO_DIR
	beq b_gpm_Exit      ; Yes, so, no collision.
	
	; If gun 1 is moving left and/or gun 2 is moving right, 
	; then no possible collision. 
	
	lda zPLAYER_ONE_DIR ; 1 == right to left.
	bne b_gpm_Exit  ; Yes, so, no collision.

	; Here we know two players are running, and
	; they are traveling toward each other.
	; Inevitably the two must meet.
	
	sec                   ; Doing some subtraction. Set carry.
	lda zPLAYER_TWO_NEW_X ; subtract one 
	sbc zPLAYER_ONE_NEW_X ; from two...
	cmp #PLAYER_X_SIZE
	bcs b_gpm_Exit        ; greater than or equal SIZE? No collision.

	; If on the left side of screen adjust gun 2 to 1.
	
	lda zPLAYER_ONE_NEW_X
	bmi b_gpm_AdjustOnRightSide ; right side...

	clc
	adc #PLAYER_X_SIZE
	sta zPLAYER_TWO_NEW_X
	bpl b_gpm_BumpTheGuns


b_gpm_AdjustOnRightSide      ; On the right side of screen adjust gun 1 to 2.
	lda zPLAYER_TWO_NEW_X
	sec
	sbc #PLAYER_X_SIZE
	sta zPLAYER_ONE_NEW_X

b_gpm_BumpTheGuns
	lda #0
	sta zPLAYER_TWO_DIR         ; 0 == left to right.
	lda #1
	sta zPLAYER_ONE_DIR         ; 1 == right to left.
	
	sta zPLAYER_ONE_BUMP
	sta zPLAYER_TWO_BUMP

b_gpm_Exit

	rts


; ==========================================================================
; SUPPORT - MOVE PLAYER LEFT                                      X
; ==========================================================================
; Runs during main Game
; 
; Decide to move the players' guns left.
; If Player 1 is on, always move.
; If player 1 is off, then move Player 2. (Logical deducation -- the code
; could not have arrive here if there is no active player).
; 
; The player manipulated is based on value of X register.
;
; X = 0 = Player 1 gun
; X = 1 - Player 2 gun
; --------------------------------------------------------------------------

GameMovePlayerLeft

	lda zPLAYER_ON,X        ; Is this player even playing?
	beq b_gmpl_Exit         ; Nope.  Done here.

	lda zPLAYER_DIR,X       ; Is this player going left?  0 == left to right. 1 == right to left.
	beq b_gmpl_Exit         ; 0 == Nope.  Done here.

b_gmpl_CallMoveLeft         ; The Simple move left toward bumper....
	jsr GameMovePlayerLeftToBumper

b_gmpl_Exit
	rts


; ==========================================================================
; SUPPORT - MOVE PLAYER LEFT TO BUMPER                             X
; ==========================================================================
; Runs during main Game
; 
; Move the players' guns left toward the bumper.
; If the gun reaches the minimum position, toggle direction.
; 
; The player manipulated is based on value of X register.
; This is always used for Gun 1.   
; This is used for Gun 2 when Gun 1 is not present.
; It is up to the caller to set X accordingly and know if it is appropriate
; to call this routine for the player.
; 
; X = 0 = Player 1 gun
; X = 1 - Player 2 gun
; --------------------------------------------------------------------------

GameMovePlayerLeftToBumper

	lda zPLAYER_BUMP,X  ; Has there already been a  direction change.
	bne b_gmpltb_Exit   ; Yes, do not test this bounce.

	ldy zPLAYER_X,X     ; Subtract one from player position.
	dey                 ; or subtract INC_PLAYER_X.

	sty zPLAYER_NEW_X,X ; Save new position.
	cpy #PLAYER_MIN_X   ; Has it reached the mininum?
	bne b_gmpltb_Exit   ; No.  Exit now.

	lda #0              ; Yes.  Set direction left to right.
	sta zPLAYER_DIR,X   ; Bounce.

	inc zPLAYER_BUMP,X ; Remember there was a direction change.  Maybe not needed.

b_gmpltb_Exit
	rts


; ==========================================================================
; SUPPORT - MOVE PLAYER RIGHT                                      X
; ==========================================================================
; Runs during main Game
; 
; Decide to move the players' guns right.
; If Player 2 is on, always move.
; If player 2 is off, then move Player 1. (Logical deducation -- the code
; could not have arrive here if there is no active player).
; 
; The player manipulated is based on value of X register.
;
; X = 0 = Player 1 gun
; X = 1 - Player 2 gun
; --------------------------------------------------------------------------

GameMovePlayerRight

	lda zPLAYER_ON,X         ; Is this player even playing?
	beq b_gmpr_Exit          ; Nope.  Done here.

	lda zPLAYER_DIR,X        ; Is this player going right?
	bne b_gmpr_Exit          ; 1 == Nope.  Done here.

b_gmpr_CallMoveRight         ; The Simple move right toward bumper....
	jsr GameMovePlayerRightToBumper

b_gmpr_Exit
	rts


; ==========================================================================
; SUPPORT - MOVE PLAYER RIGHT TO BUMPER                             X
; ==========================================================================
; Runs during main Game
; 
; Move the players' guns right toward the bumper.
; If the gun reaches the maximum position, toggle direction.
; 
; The player manipulated is based on value of X register.
; This is always used for Gun 2.   
; This is used for Gun 1 when Gun 2 is not present.
; It is up to the caller to set X accordingly and know if it is appropriate
; to call this routine for the player.
; 
; X = 0 = Player 1 gun
; X = 1 - Player 2 gun
; --------------------------------------------------------------------------

GameMovePlayerRightToBumper

	lda zPLAYER_BUMP,X  ; Has there already been a  direction change.
	bne b_gmprtb_Exit   ; Yes, do not test this bounce.

	ldy zPLAYER_X,X     ; Add one to player position.
	iny                 ; or add INC_PLAYER_X.
	
	sty zPLAYER_NEW_X,X ; Save new position.
	cpy #PLAYER_MAX_X   ; Has it reached the maximum?
	bne b_gmprtb_Exit   ; No.  Exit now.
	
	lda #1              ; Yes.  Set direction right to left.
	sta zPLAYER_DIR,X   ; Bounce.

	inc zPLAYER_BUMP,X  ; Remember there was a direction change.

b_gmprtb_Exit
	rts


; ==========================================================================
; SUPPORT - CHECK NEW EXPLOSIONS
; ==========================================================================
; Runs during VBI
; 
; For Each player check if the Laser hit the mothership.
;
; 2) Is Bang set (Player to Mothership collision)? (both players)
;    a) Set laser to remove it from screen
;    b) Add points to player
;    c) Explosion on, X, y == Current Mothership X, Y
;
; If any bang occurred, then 
; - adjust new mothership position 
; - update hit counter/mothership speed
;
; --------------------------------------------------------------------------

CheckNewExplosions

	ldx #0
	jsr CheckNewExplosion

	ldx #1
	jsr CheckNewExplosion

	rts


; ==========================================================================
; SUPPORT - CHECK NEW EXPLOSION
; ==========================================================================
; Runs during VBI
; 
; 2) Is Bang set (Player to Mothership collision)? (both players)
;    a) Set laser to remove it from screen
;    b) Add points to player
;    c) Explosion on, X, y == Current Mothership X, Y
;
; X == The Player's laser to work on.
;
; --------------------------------------------------------------------------

CheckNewExplosion

	lda zLASER_ON,X                ; Is laser on?
	beq b_cne_Exit                 ; No. Nothing to do.

	lda zPLAYER_SHOT_THE_SHERIFF,X ; Did Laser hit Mothership?
	beq b_cne_Exit                 ; No. Nothing to do.

	lda #0
	sta zLASER_NEW_Y,X               ; Flag this laser to get erased.

	lda gMOTHERSHIP_X              ; Set Explosion X, Y == Mothership X, Y
	sta gEXPLOSION_X
	lda gMOTHERSHIP_Y
	sta gEXPLOSION_NEW_Y

	lda #15 
	sta gEXPLOSION_COUNT          ; jiffy count for explosion graphic

b_cne_Exit
	rts


; ==========================================================================
; SUPPORT - CHECK LASERS IN PROGRESS
; ==========================================================================
; Runs during main Game
; 
; 3) If laser is running, update Y =  Y - 4.
;    a) if Y reaches min Y, set laser to remove it from screen
;
; --------------------------------------------------------------------------

CheckLasersInProgress

	ldx #0
	jsr CheckLaserInProgress

	ldx #1
	jsr CheckLaserInProgress

	rts


; ==========================================================================
; SUPPORT - CHECK LASER IN PROGRESS
; ==========================================================================
; Runs during main Game
; 
; 3) If laser is running, update Y =  Y - 4.
;    a) if Y reaches min Y, set laser to remove it from screen
;
; X == The Player's laser to work on.
;
; VBI will actually erase and turn off the laser.
; --------------------------------------------------------------------------

CheckLaserInProgress

	lda zLASER_ON,X     ; Is laser on?
	beq b_clip_Exit     ; No. Nothing to do.

	lda zLASER_Y,X  
	cmp #LASER_END_Y    ; Is Laser not yet at Y Limit?
	bcc b_clip_StopLaser
	bne b_clip_DoMove   ; No.  

b_clip_StopLaser
	; Stop Laser Sound here.  If the other laser is not running

	lda #0              ; Zero New_Y is signal to remove from screen.
	beq b_clip_UpdateY

b_clip_DoMove
	sec                 ; Subtract from laser Y
	sbc gINC_LASER_Y
;	sbc #4
	
b_clip_UpdateY
	sta zLASER_NEW_Y,X  ; New Y is set.

b_clip_Exit
	rts


; ==========================================================================
; SUPPORT - CHECK PLAYERS SHOOTING
; ==========================================================================
; Runs during main Game
; 
; 4) Trigger pressed?
;    a) if gun is Off, skip shooting
;    b) if gun is crashed [alien is pushing], skip shooting
;    c) If lazer Y, in bottom half of screen, skip shooting
;       i) set lazer on, 
;       ii) Laser Y = gun new Y - 4, Laser X = gun new X + 4
;       iii) If no bounce this turn, then negate direction/set bounce.
;
; --------------------------------------------------------------------------

CheckPlayersShooting

	ldx #0
	jsr CheckPlayerShooting

	ldx #1
	jsr CheckPlayerShooting

	rts


; ==========================================================================
; SUPPORT - CHECK PLAYER SHOOTING
; ==========================================================================
; Runs during main Game
; 
; 4) Trigger pressed?
;    a) if gun is Off, skip shooting
;    b) if gun is crashed [alien is pushing], skip shooting
;    c) If lazer Y, less than ConfigLaserRestart, skip shooting
;       i) set lazer on, 
;       ii) Laser Y = gun new Y - 4, Laser X = gun new X
;       iii) If no bounce this turn, then negate direction/set bounce.
;
; X == the Player/gun/laser
; --------------------------------------------------------------------------

gLASER_RESTART_HEIGHT .byte 128,170,36 ; Mid, short, long distance for restart

CheckPlayerShooting

	lda zPLAYER_ON,X             ; Is this player even playing?
	beq b_cps_Exit               ; Nope.  Done here.

	lda zPLAYER_CRASH,X          ; Is the gun crashed by alien?
	bne b_cps_Exit               ; Yes.  Done here.

	jsr libAJoystickButton       ; 1=wait, 0=debounced, -1=trigger and Onesie enforcement
	bpl b_cps_Exit               ; Done here. Onesie for non-active will return 1 to this

	lda zLASER_ON,X              ; Is Laser on?
	beq b_cps_StartLaser         ; No.  Ok to shoot.

	lda gConfigLaserRestart      ; reduce $80, $81, $82 to 0, 1, 2...
	and #$7F                     ; ... by removing high bit
	tay                          ; Y = index into gLASER_RESTART_HEIGHT

	lda zLASER_NEW_Y,X           ; Check if Y is now less than...
	cmp gLASER_RESTART_HEIGHT,Y  ; ... the configured height.
	bcs b_cps_Exit               ; No, greater than/equal to. Done.

b_cps_StartLaser               ; The button must have been released before shooting again.
	jsr StartShot                ; Yippie-Ki-Yay Bang Bang Shoot Shoot.
	; Note that X is still the valid player number after calling StartShot.

	lda gConfigLaserRestart      ; Get the laser restart config
	bpl b_cps_SwapOnsie          ; If it is positive, then no need to debounce joystick.

 	jsr libResetJoystickDebounce ; Turn off debounce to allow shooting again.           

b_cps_SwapOnsie
	lda gONESIE_PLAYER
	eor #$01 ; Flip value
	sta gONESIE_PLAYER
	jsr GameUpdateOnesie

b_cps_Exit
	rts


; ==========================================================================
; SUPPORT - MOVE GAME MOTHERSHIP
; ==========================================================================
; Runs during main Game
; 
; Horizontally moves the mothership.
; When the end of the line is reached, flip the direction, and move 
; to the next row.   (This triggers the vertical move down which will 
; be animated by the VBI.)
;
; Note that when the mothership is on line 22 it will go all the way 
; to the end of the byte value for HPOS (0 or 255)
;
; ==========================================================================
; F Y I -- MOTHERSHIP SPEED CONTROL
; ==========================================================================
; The original game had a series of variables and triggered
; speed change by maintaining a separate counter for every 10 hits.
; SPEEDUP THRESHOLD, SPEEDUP COUNTER, MOVE SPEED and MOVE COUNTER.
; The logic around these is mostly separate from the hit counter, but 
; would synchronize to the mothership hit counter reset.
;
; SPEEDUP THRESHOLD statically holds "10." 
; SPEEDUP COUNTER starts at the SPEEDUP THRESHOLD value and it 
; decrements with each mothership hit.
; When SPEEDUP COUNTER reaches 0, reset it to the SPEEDUP THRESHOLD and 
; then increment the MOVE SPEED.  
; MOVE SPEED starts at "2".  This indicates the number of times the 
; mothership should move a pixel (C64's half-color clock pixels.)
; (And so, 2 "pixels" is one Atari color clock.)
; MOVE COUNTER is set to the value of MOVE SPEED.  It is used as a
; loop counter to move the mothership horizontally one pixel per 
; each loop.
;
; Thus every 10 motherhip hits increments the MOVE SPEED and the 
; MOVE SPEED is limited to count from 2 to 9, or 8 values.  This 
; matches the 80 mothership hits.  And then all values return to 
; the original "2" speed.
;
; For the Atari version looping to move the mothership will not 
; be required.  The mothership can be moved in one step with 
; addition instead of incrementing by 1.  Instead of checking for 
; equality when reaching the left or right side of the screen the
; comparisons simply need to change to "greater than or equal to", 
; or "less than or equal to".  Also, counting hits indirectly is 
; not needed.  The Atari code increments the speed counter when 
; the ones digit for the hit counter decrements to become "0". 
; Also, the code resets the speed controls when it resets the 
; overall hit counter.
;
; Furthermore, the C64 increments movement by half-color clock pixels
; where Atari Player/missile graphics are based on color-clocks.   
; When the C64 is moving an even number of pixels, this corresponds 
; to half the number of Atari pixels, so this has a direct parallel.
;
; However, where there are an odd number of pixels for the C64 the 
; Atari can't directly use the same amount of horizontal movement.  
; The Atari uses a two frame average where each frame moves a 
; different number of color clocks, so that the average of two 
; frames works out to the same effective distance used for the C64 
; version.
; 
; This chart explains how the pixel distance is equal over two 
; sequential frames.   The Atari color clocks are one-half the
; number of C64 half-color clock pixels.
:
; MOVE   C64              ATARI       HIT COUNTER
; SPEED  PIXELS           PIXELS      VALUE RANGE
;  2 ==   2   2  (4)  ==  1  1 (2)  ; 80 to 71 hit counter
;  3 ==  2+1 2+1 (6)  ==  1  2 (3)  ; 70 to 61 hit counter
;  4 ==   4   4  (8)  ==  2  2 (4)  ; 60 to 51 hit counter
;  5 ==  4+1 4+1 (10) ==  2  3 (5)  ; 50 to 41 hit counter
;  6 ==   6   6  (12) ==  3  3 (6)  ; 40 to 31 hit counter
;  7 ==  6+1 6+1 (14) ==  3  4 (7)  ; 30 to 21 hit counter
;  8 ==   8   8  (16) ==  4  4 (8)  ; 20 to 11 hit counter.
;  9 ==  8+1 8+1 (18) ==  4  5 (9)  ; 10 to 1  hit counter.
; 
; Then the Atari version uses a lookup table based on the current 
; speed index.  Since "Speed" is now an index, not a direct count of 
; pixels, the Atari code can iterate from 0 to 7 instead of 2 to 9.
; Also, each call to draw the mothership toggles an index offset 
; from +0 to +1 used to chose between the two frame increment values.
; --------------------------------------------------------------------------

GameMothershipMovement

	lda gMOTHERSHIP_Y
	cmp gMOTHERSHIP_NEW_Y      ; Is Y the same as NEW_Y?
	beq b_gmm_RunTheMothership ; Yes.   Ok to run the mothership movement.
	rts                        ; No.  Skip this until vertical positions match. (VBI does this).

b_gmm_RunTheMothership
; Determine min/max for this row.   Row 22 allows mothership to move 
; off the screen completely.   When the Stats Text Color is zero, then 
; we're on row 22.

	lda zSTATS_TEXT_COLOR      ; If this is zero, mothership is on row 22.
	bne b_gmm_SetRegularMinMax ; Set Min/Max to normal values.

	lda #MOTHERSHIP_MIN_OFF_X  ; Here set Min/Max off screen position
	sta gMOTHERSHIP_MIN_X
	lda #MOTHERSHIP_MAX_OFF_X
	sta gMOTHERSHIP_MAX_X
	bne b_gmm_ContinueSetSpeed

b_gmm_SetRegularMinMax         ; Here use the normal values for screen width.
	lda #MOTHERSHIP_MIN_X
	sta gMOTHERSHIP_MIN_X
	lda #MOTHERSHIP_MAX_X
	sta gMOTHERSHIP_MAX_X

; Determine speed (distance to move) here.
; See discussion above.   There are two possible entries 
; from the table (indexed by Move speed + 0, and Move speed + 1)
; Toggle the counter value to create the +0/+1 offset each frame.

; This has already been determined by lookup from a table
; during the vertical blank.  MOTHERSHIP_MOVEMENT is ready for use.

b_gmm_ContinueSetSpeed
;	ldy zMOTHERSHIP_MOVE_SPEED      ; index into speed table.
;	dec zMOTHERSHIP_SPEEDUP_COUNTER ; toggle the offsetter, 1,0,-1 (1).
;	bpl b_gmm_ContinueSpeedSetup    ; If still positive, then collect speed value 
;	lda #1                          ; Offsetter went negative.  
;	sta zMOTHERSHIP_SPEEDUP_COUNTER ; Reset the offsetter to 1.
;	iny                             ; increment the index into the speed table.

b_gmm_ContinueSpeedSetup
;	lda TABLE_SPEED_CONTROL,y       ; A == value from speed table to add/subtract 
;	sta gMOTHERSHIP_MOVEMENT        ; Save new value to add/subtract  

	lda gMOTHERSHIP_X               ; A == Get current X position

	ldy gMOTHERSHIP_DIR      ; Test direction. ; 0 == left to right. 1 == right to left.
	bne b_gmm_Mothership_R2L ; 1 = Right to Left

; Moving Left to Right

	clc                      ; Doing left to right. 
	adc gMOTHERSHIP_MOVEMENT ; A already contains the X position.  Add the movement.
	cmp gMOTHERSHIP_MAX_X    ; Is the new value at the max?
	bcc b_gmm_Save_MSX_L2R   ; A  less than max, so just save it.
	lda gMOTHERSHIP_MAX_X    ; reset to max.

b_gmm_Save_MSX_L2R
	sta gMOTHERSHIP_NEW_X    ; Save new Mothership X
	cmp gMOTHERSHIP_MAX_X    ; Reached max means time to inc Y and reverse direction.
	bne b_gmm_Exit_MS_Move   
	beq b_gmm_MS_EndOfLife   ; Check if mothership reached the bottom row/end of movement 

; Moving Right to Left

b_gmm_Mothership_R2L 
	sec                      ; Doing right to left. 
	sbc gMOTHERSHIP_MOVEMENT ; A already contains the increment value, Add X
	cmp gMOTHERSHIP_MIN_X    ; Is the new value at the min?
	bcs b_gmm_Save_MSX_R2L   ; A >= min, so just save the new value. 
	lda gMOTHERSHIP_MIN_X    ; reset to min.
	
b_gmm_Save_MSX_R2L
	sta gMOTHERSHIP_NEW_X    ; Save new Mothership X
	cmp gMOTHERSHIP_MIN_X    ; Reached min means time to inc Y and reverse direction.
	bne b_gmm_Exit_MS_Move   ; Not at min.  Exit.

; Mothership has reached the end of a row.  
; Check if this is on the last row.  If so, then the game is over.

b_gmm_MS_EndOfLife
	lda zSTATS_TEXT_COLOR         ; If this is zero, mothership is on row 22.
	bne b_gmm_MS_ReverseDirection ; Not Zero, so do the Set Min/Max to normal values.

; HERE set end of game flags to go to next screen.

; Flip direction when Mothership reaches Min or Max position.
; Also setup Mothership to move to the next row.

b_gmm_MS_ReverseDirection
	lda gMOTHERSHIP_DIR      ; Toggle X direction.
	beq b_gmm_Set_R2L        ; is 0, set 1 = Right to Left
	lda #0
	beq b_gmm_UpdateDirection
b_gmm_Set_R2L
	lda #1
b_gmm_UpdateDirection
	sta gMOTHERSHIP_DIR

b_gmm_CheckLastRow
	ldx gMOTHERSHIP_ROW      ; Get current row.
	cpx #22                  ; If on last row, then it has
	bne b_gmm_GoToNextRow    ; reached the end of incrementing rows.

	; Game Over
	inc gGAME_OVER_FLAG
	rts

b_gmm_GoToNextRow
	lda gConfigCheatMode     ; Are we in cheat mode?
	beq b_gmm_DoNextRow      ; No.   go move to next row.
	
	cpx #21                  ; Cheat Mode.  Is this the row before the last row?
	beq b_gmm_Exit_MS_Move   ; Yes.  Do not increment.

b_gmm_DoNextRow
	inx                      ; Next row.
	jsr GameSetMotherShipRow ; Given Mothership row (X), update the mother ship wow and set new, target Y position. 

b_gmm_Exit_MS_Move
	rts


; ==========================================================================
; SUPPORT - START SHOT
; ==========================================================================
; Runs during main Game
; 
;       i) set lazer on, 
;       ii) Laser Y = gun new Y - 4, Laser X = gun new X
;       iii) If no bounce this turn, then negate direction/set bounce.
;
; Looking at the video of the game frame by frame the laser 
; does begin at exactly the right location relative to the player.
; Over the next two frames the player moves left or right away
; from the laser origin.   This make the human viewer perceive that
; the laser started offset from the center of the gun.
; Therefore, to compensate for the illusion the game fudges the start 
; position of the laser offset by one, so that the second/third frame of 
; the laser and the next two frames of the gun all coincide, so it 
; appears to be better centered on the gun.
;
; X == the Player/gun/laser
; --------------------------------------------------------------------------

StartShot

	inc zLASER_ON,X          ; Turn laser on for the VBI to draw.

	lda #LASER_START
	sta zLASER_NEW_Y,X       ; New Y is set.

	lda #0
	sta zLASER_COLOR,X       ; Reset laser color pattern.

; start sound effects for shooting.

	; Decide whether or not the gun has to change directions.

	lda zPLAYER_BUMP,X       ; Has this frame already done a direction change?
	bne b_ss_TweakLaserStart ; Yes.  Do not switch directions again.

	inc zPLAYER_BUMP,X       ; Flag it has bumped. (probably not needed).
	lda zPLAYER_DIR,X        ; Flip direction
	beq b_ss_Dir1            ; Go do the Flip 0 to 1
	
	lda #0                   ; 0 == left to right. 
	sta zPLAYER_DIR,X        ; Flip 1 to 0
	beq b_ss_TweakLaserStart ; Done

b_ss_Dir1
	inc zPLAYER_DIR,X        ; Flip 0 to 1.  1 == right to left.

; Again, evaluate gun direction to determine how to offset 
; the starting X position for the laser.
; If moving left, then subtract 1 from Player X to set laser X.
; If moving right, then add 1 to the Player X to set laser X.
b_ss_TweakLaserStart
	ldy zPLAYER_NEW_X,X      ; Hold Gun's X position in Y reg.
	lda zPLAYER_DIR,X       
	bne b_ss_TweakR2L        ; 1 == right to left.

	iny                      ; 0 == left to right.
	bne b_ss_SaveNewLaserX

b_ss_TweakR2L                ; 1 == right to left.
	dey

b_ss_SaveNewLaserX
	sty zLASER_X,X          ; to the laser position.

b_ss_Exit
	rts


; ==========================================================================
; SUPPORT - PROCESS EXPLOSION
; ==========================================================================
; Runs during VBI.
;
; Evaluating collision and updating the explosion must occur during the VBI
; instead of main code.   If the logic for managing the explosion occurs 
; during the main line code and the collision detection during the VBI 
; then the explosion starts a frame late and in the wrong position.
; in other words, this  would happen:
; Frame: 
; - Display overlapping mothership and laser.  
; - Main code processes movement.
; VBI 
;  - detects collision and flags for explosion start.
; Frame:
; - Display moved mothership and laser again.
; - Main code starting explosion at current (wrong) position.
; VBI
; - etc
; Frame:
; - Explosion is now displayed.
;
; So, collision evaluation and explosion maintenance will occur during the 
; VBI, so that the explosion can start on the frame after the collision 
; in the correct spot:
; Frame: 
; - Display overlapping mothership and laser.  
; - Main code processes movement.
; VBI 
; - detects collision and flags for explosion start.
; - Draws explosion at old mothership position
; - Draws mothership at new row location.
; Frame:
; - Display motherhship in reset position
; - Display explosion.
; - Main updates score.
; - Main code processes movements.
;
; Depending on the animation duration for the explosion there's a 
; possibility that the old animation will still be running when the 
; new one must start.   The Pmg draw code handles the restart 
; automatically.
; --------------------------------------------------------------------------

GameProcessExplosion

	lda zPLAYER_ONE_SHOT_THE_SHERIFF  ; Did either laser collide 
	ora zPLAYER_TWO_SHOT_THE_SHERIFF  ; with the mothership?
	beq b_gpe_DoCurrentExplosion      ; No.  Just process current explosion.


	jsr GameMothershipPointsForPlayer ; Copy current point value for adding score

	jsr GameShotStop                  ; Stop Laser that hit the mothership. . .


	lda gMOTHERSHIP_Y                 ; Copy current mothership position to new
	sta gEXPLOSION_NEW_Y              ; explosion position to initiate explosion.
	lda gMOTHERSHIP_X
	sta gEXPLOSION_X

	jsr Pmg_DrawExplosion             ; Start new explosion cycle.

	jsr GameRandomizeMothership       ; Choose random direction, set new X accordingly.

	ldx gMOTHERSHIP_ROW               ; Subtract 2
	dex                               ; from the
	dex                               ; mothership row. 
	bpl b_gpe_ContinueReset           ; If the result is positive, then update row. 
	ldx #0                            ; Negative must be limited to 0.
b_gpe_ContinueReset
	jsr GameSetMotherShipRow          ; Set New Mothership Y to new row in X register.

	rts                               ; And done.


b_gpe_DoCurrentExplosion
	lda gEXPLOSION_ON                 ; Is an explosion running?
	beq b_gpe_Exit                    ; Nope.  Exit.

	ldx gEXPLOSION_COUNT              ; Get current counter.
	beq b_gpe_StopExplosion           ; If it is 0 now, then stop explosion

	dex
	stx gEXPLOSION_COUNT
	lda TABLE_COLOR_EXPLOSION,X       ; Get color from table.
	sta COLOR3                        ; Update OS shadow register.
	sta COLPF3                        ; Update hardware register to be redundant.
	rts


b_gpe_StopExplosion
	lda #0
	sta gEXPLOSION_NEW_Y
	jsr Pmg_DrawExplosion            ; Stop explosion cycle.

b_gpe_Exit
	rts


; ==========================================================================
; SUPPORT - SHOT STOP
; ==========================================================================
; Runs during VBI.
;
; Figure out which player (or both) get credit for hitting the mothership
; and stop that player's laser.
; --------------------------------------------------------------------------

GameShotStop

	ldx #0
	jsr GameStopLaser

	ldx #1
	jsr GameStopLaser

	rts


; ==========================================================================
; SUPPORT - STOP LASER
; ==========================================================================
; Runs during VBI.
;
; If the Player's laser hit the mothership stop that player's laser.
;
; This all used to be a lot more complicated, but several optimizations
; and removing unused variables eliminated some complexity.
; --------------------------------------------------------------------------

GameStopLaser

	lda zPLAYER_SHOT_THE_SHERIFF,X ; Did player's laser hit mothership?
	beq b_gsc_Exit                 ; No hit, so no change to laser.

	lda #0
	sta zLASER_NEW_Y,X             ; Zero Laser's New Y to stop it

b_gsc_Exit
	rts


;==============================================================================
;												SetMotherShip  X
;==============================================================================
; Given Mothership row (X), save the row, update the mother ship points value.
;
; If this is the last row, do not manage digits.  Instead, zero the stats
; text color which  will trigger the gfx routine to write the space with 
; blanks.
;
; X == row number.
; -----------------------------------------------------------------------------

GameSetMotherShipRow
	
	stx gMOTHERSHIP_ROW              ; Save new Row.
	lda TABLE_ROW_TO_Y,X             ; Get new target Y position.
	sta gMOTHERSHIP_NEW_Y            ; Save for VBI to redraw mothership.

	cpx #22                          ; Is this the last row?
	bne b_gsmsr_SetStats             ; No, setup the row text and points for screen.
	lda #$00                         ; Turn off statistics line
	sta zSTATS_TEXT_COLOR            ; Zero color will make gfx write blanks.
	rts

b_gsmsr_SetStats
	jsr GameRowNumberToDigits        ; Setup value converted to copy to screen.

	jsr GameMothershipPointsToDigits ; Copy point value to screen display version.

b_gsmsr_Exit
	rts


; ==========================================================================
; SUPPORT - RANDOMIZE MOTHERSHIP
; ==========================================================================
; At game start and anytime the mothership is shot, then randomize
; the new horizontal position start.
; --------------------------------------------------------------------------

GameRandomizeMothership

	lda RANDOM                      ; Random starting direction for Mothership
	and #$01
	sta gMOTHERSHIP_DIR             ; 0 == left to right. 1 == right to left.
	bne b_grm_SetMothershipMax_X    ; 1 == right to left.

	lda #MOTHERSHIP_MIN_X           ; 0 == left to right.  Left == Minimum
	bne b_grm_SetMothership_X       ; Save horizontal position
	
b_grm_SetMothershipMax_X
	lda #MOTHERSHIP_MAX_X           ; Right == Maximum

b_grm_SetMothership_X               ; Start horizontal position coord.
	sta gMOTHERSHIP_NEW_X
	sta gMOTHERSHIP_X

	rts


; ==========================================================================
; ROW NUMBER TO DIGITS
; ==========================================================================
; Convert Row Number to bytes for easier transfer to screen.
; This has to convert an integer that could be 0 to 21 at any time.
; It's easier just to use a lookup table.
; --------------------------------------------------------------------------

GameRowNumberToDigits

	ldx gMOTHERSHIP_ROW             ; Get the current Row.
	lda TABLE_TO_DIGITS,X           ; Get two digits as byte/nybble
	pha                             ; Save to do second digit.

	and #$F0                        ; Mask to keep first digit.
	lsr                             ; Right shift
	lsr                             ; to move digit
	lsr                             ; into the  
	lsr                             ; low nybble.
	sta gMOTHERSHIP_ROW_AS_DIGITS   ; Save as byte. 

	pla                             ; Get value saved earlier.

	and #$0F                        ; Mask to keep second digit.
	sta gMOTHERSHIP_ROW_AS_DIGITS+1 ; Save as byte. 

	rts


; ==========================================================================
; MOTHERSHIP POINTS TO DIGITS
; ==========================================================================
; Given a Row Number get the point value, and distribute as individual 
; digits.  This facilitates simplifying the math, and maps the value
; in a form that's easier to copy to the screen.
; --------------------------------------------------------------------------

GameMothershipPointsToDigits

	lda gMOTHERSHIP_ROW             
	asl                                ; Times 2 to index point table.
	tax                                ; X == A for indexing.
	ldy #2                             ; Starting offset into points as digits string

b_gmsptd_LoopCopyDigits
	lda TABLE_MOTHERSHIP_POINTS,X      ; Get two digits as byte/nybbles
	pha                                ; Save to do second digit.

	and #$F0                           ; Mask to keep first digit.
	lsr                                ; Right shift
	lsr                                ; to move digit
	lsr                                ; into the  
	lsr                                ; low nybble.
	sta gMOTHERSHIP_POINTS_AS_DIGITS,Y ; Save as byte. 

	iny                                ; Next position in digits string.
	pla                                ; Get value saved earlier.

	and #$0F                           ; Mask to keep second digit.
	sta gMOTHERSHIP_POINTS_AS_DIGITS,Y ; Save as byte. 
	inx                                ; Next position in table.
	iny                                ; Next postion in digits string.

	cpy #6                             ; Did index reach end of digits string?
	bne b_gmsptd_LoopCopyDigits        ; No, loop again.

	rts


; ==========================================================================
; MOTHERSHIP POINTS FOR PLAYER
; ==========================================================================
; When an explosion occurs, copy the current point value for the 
; mothership to the temporary buffer for passing the score on 
; to the Player(s)
; --------------------------------------------------------------------------

GameMothershipPointsForPlayer

	ldx #5

b_gmspfp_CopyLoop
	lda gMOTHERSHIP_POINTS_AS_DIGITS,X ; Copy current picture of point
	sta gPLAYERPOINTS_TO_ADD,X         ; Save to player(s) awarded value.

	dex
	bpl b_gmspfp_CopyLoop

	rts


; ==========================================================================
; RESET SPEEDUP COUNTER
; ==========================================================================
; Set the speedup counter based on the configured 
; choice, gConfig1nvaderHitCounter.
;
; If the value is negative, then this is progressive counting.
; --------------------------------------------------------------------------

GameSetSpeedupCounter

	lda gConfig1nvaderHitCounter
	bpl b_gssc_AssignSpeedup

	lda #10                     ; Negative means we're doing 10, 9, 8...
	sta gMOTHERSHIP_PROGRESSIVE

b_gssc_AssignSpeedup
	sta gMOTHERSHIP_SPEEDUP_COUNTER

	rts


; ==========================================================================
; RESET HIT COUNTER
; ==========================================================================
; Reset the byte counter, and reset the two-byte BCD-like version 
; used for copying to the screen.
; Also reset the mothership speed to original value.
; --------------------------------------------------------------------------

GameResetHitCounter

	lda #80                         ; Just count integer 80 for hits.
	sta gMOTHERSHIP_HITS

	lda #$08
	sta gSHIP_HITS_AS_DIGITS        ; Tens digit is "8"
	lda #$00
	sta gSHIP_HITS_AS_DIGITS+1      ; Ones digit is "0"

	jsr GameSetSpeedupCounter
;	sta zMOTHERSHIP_SPEEDUP_COUNTER ; Zero speed offset

	lda gConfig1nvaderStartSpeed    ; Get configured starting speed
	sta gMOTHERSHIP_MOVE_SPEED      ; Zero move speed.

	rts


; ==========================================================================
; DECREMENT HIT COUNTER
; ==========================================================================
; Subtract 1 from hit counter, and from the two-byte, BCD-like 
; version used for copying to the screen.
; If subtracting from counter goes to 0, then 80 hits have occurred and so
; reset the hit counter.
; When new ones digit value is "0", then increment the mothership speed.
; --------------------------------------------------------------------------

GameDecrementHitCounter

	dec gMOTHERSHIP_HITS         ; If this goes to 0, then
	beq GameResetHitCounter      ; go up to reset counter (will not return here.)

	dec gSHIP_HITS_AS_DIGITS+1   ; Subtract from ones place digit.
	bpl b_gdhc_DoSpeedupCounter  ; It did not go -1
	
	
;	beq b_gdhc_CheckSpeedControl ; If ones is 0, then go to next mothership speed.
;	bpl b_gdhc_Exit              ; Some other non-zero digit.  Done here.

	lda #$9                      ; Ones digit went to -1
	sta gSHIP_HITS_AS_DIGITS+1   ; Reset ones to 9
	dec gSHIP_HITS_AS_DIGITS     ; Subtract 1 from tens position.
;	rts

b_gdhc_DoSpeedupCounter
	lda gConfig1nvaderHitCounter ; Check config for speedups.
	beq b_gdhc_Exit              ; 0 means no speedups.

	lda gMOTHERSHIP_SPEEDUP_COUNTER
	beq b_gdhc_Exit                 ; It arrived here at 0, so no more speedups.

	dec gMOTHERSHIP_SPEEDUP_COUNTER ; Hit counter - 1
	bne b_gdhc_Exit                 ; Not 0 means no speedup yet.

	; Counter decremented to 0 , so do a speedup. First restart the counter.
	lda gConfig1nvaderHitCounter 
	bpl b_gdhc_SetHitCounter     ; Not negative, just use value to restart counter.

	; Negative means use the progressive counter.

	lda gMOTHERSHIP_PROGRESSIVE
	beq b_gdhc_Exit   ; Progressive counter reached 0  already.  
	
	dec gMOTHERSHIP_PROGRESSIVE
	lda gMOTHERSHIP_PROGRESSIVE
	
;	dec zMOTHERSHIP_SPEEDUP_COUNTER ; Hit counter - 1
;	bne b_gdhc_Exit

b_gdhc_SetHitCounter
	sta gMOTHERSHIP_SPEEDUP_COUNTER
	beq b_gdhc_Exit                  ; This reduced to 0, so no speedup.

b_gdhc_CheckSpeedControl        ; Need to add +2 for 2 entries for hpos+ entries.
	lda gMOTHERSHIP_MOVE_SPEED   ; Get current speed
	cmp gConfig1nvaderMaxSpeed   ; Compare to max speed 
	beq b_gdhc_Exit              ; If at max, then nothing else to do.

	inc gMOTHERSHIP_MOVE_SPEED ; Speedup++
	jsr FrameControlMothershipSpeed  ; Maybe overkill.  VBI will also do this.

b_gdhc_Exit
	rts


; ==========================================================================
; ZERO SCORES
; ==========================================================================
; Zero all the digits of player 1 and player 2 scores.
;
; Called on Init.   Called on Game Start. 
; It is NOT called for the title screen/at end of game, so that the 
; title screen can support displaying the scores from the prior game.
; --------------------------------------------------------------------------

GameZeroScores

	ldx #0
	jsr GameZeroPlayerScore

	ldx #1
	jsr GameZeroPlayerScore

	rts


; X == Player number 0 or 1

GameZeroPlayerScore
	lda #0
	ldy #5

	cpx #0
	beq b_gzs_ZeroPlayerScore
	ldy #11

b_gzs_ZeroPlayerScore
	ldx #5

b_gzs_Loop_ZeroPlayerScore
	sta gPLAYER_SCORE,y 
	dey
	dex
	bpl b_gzs_Loop_ZeroPlayerScore
	
	rts



; ==========================================================================
; ANALYZE ALIEN VICTORY
; ==========================================================================
; Process mothership on row 22 which will end the game.
;
; The motion management for the mothership and the guns went off 
; pretty much as normal.  A limited number of logic options changed
; due to the being on the last line.
;
; Bulky, Work-In-Progress, Stream-of-consciousness code...  
; I can see already there are patterns to optimize.
; --------------------------------------------------------------------------

gCrashPoint .byte $00       ; X coordination to decide object is crashed or not.

GameAnalyzeAlienVictory

	ldy zSTATS_TEXT_COLOR   ; Easy trick to know mothership is on row 22
	bne b_gaav_Exit

	lda gMOTHERSHIP_NEW_X   ; Get new display position of mothership
	
	ldy gMOTHERSHIP_DIR     ; 0 = left to right.   1 = Right to Left
	bne b_gaav_Test_R2L

	; Tests running Left to Right - evaluate player 1, then 2

	clc
	adc #8                  ; Width of mothership.
	sta gCrashPoint         ; Keep track of left edge.

	ldy zPLAYER_ONE_ON      ; Player 1 on?
	beq b_gaav_DoTwo_L2R    ; No.   So do player 2.

	ldy zPLAYER_ONE_CRASH   ; Is the player already crashed?
	bne b_gaav_SetOne_X     ; Yes, directly set Player's X position.

	cmp zPLAYER_ONE_NEW_X   ; Is CrashPoint >= Player X
	bcs b_gaa_CrashOne      ; greater than or equal to.
	bcc b_gaav_Exit         ; Nah.  Player 2 can't be crashed if 1 is not crashed. 

b_gaa_CrashOne              ; Set Player One crashed
	inc zPLAYER_ONE_CRASH
	; in here maybe change the player image.

b_gaav_SetOne_X             ; Force Player 1 locked to Mothership.
	sta zPLAYER_ONE_NEW_X   ; Player X == A == gCrashPoint.

	; Part II Evaluate second player.

	clc                     ; If Player 2 is being tested, the crashpoint is the edge of Player 1.
	adc #7                  ; Width of Player 1. 
	sta gCrashPoint         ; Keep track of left edge.

b_gaav_DoTwo_L2R            ; Player 1 is crashed.  Test when Player 2 crashes.
	ldy zPLAYER_TWO_ON      ; Player 2 on?
	beq b_gaav_Exit         ; No.   Exit

	ldy zPLAYER_TWO_CRASH   ; Is the player already crashed? 
	bne b_gaav_SetTwo_X     ; Yes, directly set Player's X position.

	cmp zPLAYER_TWO_NEW_X   ; Is CrashPoint >= Player X
	bcs b_gaa_CrashTwo      ; Greater than or equal to.
	bcc b_gaav_Exit         ; Nah.   Done here.

b_gaa_CrashTWO              ; Set Player Two crashed
	inc zPLAYER_TWO_CRASH
	; in here maybe change the player image.

b_gaav_SetTwo_X
	sta zPLAYER_TWO_NEW_X   ; Player X == A == gCrashPoint.
	bne b_gaav_Exit         ; No.   Exit


	; Tests running Right to Left - evaluate player 2, then 1

b_gaav_Test_R2L

	sec
	sbc #7                  ; Width of player.
	sta gCrashPoint         ; Keep track of left edge.

	ldy zPLAYER_TWO_ON      ; Player 2 on?
	beq b_gaav_DoOne_R2L    ; No.   So do player 1.

	ldy zPLAYER_TWO_CRASH   ; Is the player already crashed?
	bne b_gaav_SetTwo_XR2L  ; Yes, directly set Player's X position.

	cmp zPLAYER_TWO_NEW_X   ; Is CrashPoint <= Player X
	bcc b_gaa_CrashTwoR2L   ; greater than or
	beq b_gaa_CrashTwoR2L   ; or equal to.
	bne b_gaav_Exit         ; Nah.  Player 1 can't be crashed if 2 is not crashed. 

b_gaa_CrashTwoR2L           ; Set Player Two crashed
	inc zPLAYER_TWO_CRASH
	; in here maybe change the player image.

b_gaav_SetTwo_XR2L          ; Force Player 2 locked to Mothership.
	sta zPLAYER_TWO_NEW_X   ; Player X == A == gCrashPoint.

	; Part II Evaluate first player.

	sec                     ; If Player 1 is being tested, the crashpoint is the edge of Player 2.
	sbc #7                  ; Width of Player 2. 
	sta gCrashPoint         ; Keep track of left edge.

b_gaav_DoOne_R2L            ; Player 2 is crashed.  Test when Player 1 crashes.
	ldy zPLAYER_ONE_ON      ; Player 1 on?
	beq b_gaav_Exit         ; No.   Exit

	ldy zPLAYER_ONE_CRASH   ; Is the player already crashed? 
	bne b_gaav_SetOne_XR2L  ; Yes, directly set Player's X position.

	cmp zPLAYER_ONE_NEW_X   ; Is CrashPoint >= Player X
	bcc b_gaa_CrashOneR2L   ; Greater than
	beq b_gaa_CrashOneR2L   ; or equal to.
	bne b_gaav_Exit         ; Nah.   Done here.

b_gaa_CrashOneR2L           ; Set Player One crashed
	inc zPLAYER_ONE_CRASH
	; in here maybe change the player image.

b_gaav_SetOne_XR2L
	sta zPLAYER_ONE_NEW_X   ; Player X == A == gCrashPoint.
	bne b_gaav_Exit         ; No.   Exit

b_gaav_Exit
	rts


; ==========================================================================
; GET LEFT CHAR
; ==========================================================================
; Given the current character index, get the character on the left 
; side of the display string.
;
; The index counts 0 to 12.  
; If the value is 10, 11, 12, then force to retrieve from position 
; 9 in the text string. 
;
; Other code must set up the pointers.
;
; RETURN  A = character
; --------------------------------------------------------------------------

GameGetLeftChar

	ldy zGO_CHAR_INDEX
	cmp #10
	bcc b_ggrc_GetChar
	bcs b_ggrc_Exit_Failure

	; Yes, the branches above goes into the routine below.

; ==========================================================================
; GET RIGHT CHAR
; ==========================================================================
; Given the current character index, get the character on the right 
; side of the display string.
; 
; If the index is greater than or equal to 10, then return negative value.
; 
; RETURN  A = character
; --------------------------------------------------------------------------

GameGetRightChar

	ldy zGO_CHAR_INDEX
	cmp #10
	bcs  b_ggrc_Exit_Failure

	sec                       ; set carry
	lda #19                   ; last position on text line
	sbc zGO_CHAR_INDEX         ; minus index
	tay                       ; use index in Y

b_ggrc_GetChar
	lda (zGAME_OVER_TEXT),Y   ; Get character at index 
	rts

b_ggrc_Exit_Failure
	lda #$FF
	rts


; Given active shooter update player colors for the DLI

Gfx_SetActivePlayerColorsDLI 
	tay                           ; Y = Active Player  (0 or 1 -- to be used for DLI offsets)

	asl                           ; Active Player * 2
	tax                           ; X = Active Player * 2 (to save for more math)

	lda TABLE_TIMES_SIX,y         ; A = Y * 6 (proper table offset for DLI colors.)
	tay                           ; Y = (proper table offset for DLI colors.)

	lda gNTSCorPAL                ; A = NTSC or Pal Flag
	beq b_gsapcd_Skip             ; If PAL, then skip increment.
	inx                           ; X = X + 1 (0, 2 [PAL] is now 1, 3 [NTSC])

b_gsapcd_Skip
	lda TABLE_TIMES_SIX,X         ; A = X * 6  (A = proper table offset to player colors.)
	tax                           ; X = offset for player's colors

	lda TABLE_COLOR_BLINE_PM_PN,X   ; Get Active Player color
	sta TABLE_COLOR_BLINE_PM0,y     ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PM_PN+1,X ; Get Active Player color
	sta TABLE_COLOR_BLINE_PM0+1,y   ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PM_PN+2,X ; Get Active Player color
	sta TABLE_COLOR_BLINE_PM0+2,y   ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PM_PN+3,X ; Get Active Player color
	sta TABLE_COLOR_BLINE_PM0+3,y   ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PM_PN+4,X ; Get Active Player color
	sta TABLE_COLOR_BLINE_PM0+4,y   ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PM_PN+5,X ; Get Active Player color
	sta TABLE_COLOR_BLINE_PM0+5,y   ; Save in DLI color table.

	rts



; Given active shooter, negate it and set inactive shooter colors.

Gfx_SetInactivePlayerColorsDLI
	eor #$01

	tay                           ; Y = Inactive Player * 2 (to be used for DLI offsets)
	lda TABLE_TIMES_SIX,y         ; A = Y * 6 (proper table offset for DLI colors.)
	tay                           ; Y = (proper table offset for DLI colors.)

	lda TABLE_COLOR_BLINE_PMOFF   ; Get Inactive Player color
	sta TABLE_COLOR_BLINE_PM0,y   ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PMOFF+1 ; Get Inactive Player color
	sta TABLE_COLOR_BLINE_PM0+1,y ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PMOFF+2 ; Get Inactive Player color
	sta TABLE_COLOR_BLINE_PM0+2,y ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PMOFF+3 ; Get Inactive Player color
	sta TABLE_COLOR_BLINE_PM0+3,y ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PMOFF+4 ; Get Inactive Player color
	sta TABLE_COLOR_BLINE_PM0+4,y ; Save in DLI color table.
	lda TABLE_COLOR_BLINE_PMOFF+5 ; Get Inactive Player color
	sta TABLE_COLOR_BLINE_PM0+5,y ; Save in DLI color table.

	rts


; ==========================================================================
; UPDATE ONSIE 
; ==========================================================================
; Switch the colors of the active/inactive shooter.
; --------------------------------------------------------------------------

GameUpdateOnesie

	lda gConfigOnesieMode        ; Is Onsie on?
	beq b_guo_SkipOnesie         ; Nope. Do not do anything.
	
	lda zPLAYER_ONE_ON           ; Are both players playing?
	and zPLAYER_TWO_ON
	beq b_guo_SkipOnesie         ; Nope. Do not do anything.

	; Create index values to color lookup table, and DLI table.
	lda gONESIE_PLAYER  
	jsr Gfx_SetActivePlayerColorsDLI   ; Use Onesie and set player colors.
	lda gONESIE_PLAYER  
	jsr Gfx_SetInactivePlayerColorsDLI ; Negate Onesie and set grey colors.

	lda gONESIE_PLAYER
	ora #$40
	sta GFX_STATSLINE

b_guo_SkipOnesie
	rts


; ==========================================================================
; FIX ONSIE 
; ==========================================================================
; Repair the online colors for two player modes
; --------------------------------------------------------------------------

GameFixOnesie

	lda #0  
	jsr Gfx_SetActivePlayerColorsDLI   ; Use Onesie and set player colors.
	lda #1 
	jsr Gfx_SetActivePlayerColorsDLI   ; Use Onesie and set player colors.

	rts


TABLE_TIMES_SIX
	.byte 0,6,12,18


; Need to duplicate PAL/NTSC colors here to swap colors during the 
; game when operating the Onesie mode.

TABLE_COLOR_BLINE_PM_PN ; PAL, NTSC values == (Player * 12) + (PALflag * 6)
;TABLE_COLOR_BLINE_PM0  ; P0, PAL  ; ( ( 0 * 2 ) + 0 ) * 6 == 0
	.byte $44
	.byte $46
	.byte $48
	.byte $4a
	.byte $4c
	.byte $4a

;TABLE_COLOR_BLINE_PM0 ; P0, NTSC  ; ( ( 0 * 2 ) + 1 ) * 6 == 6
	.byte $54
	.byte $56
	.byte $58
	.byte $5a
	.byte $5c
	.byte $5a
	
;TABLE_COLOR_BLINE_PM1 ; P1, PAL   ; ( ( 1 * 2 ) + 0 ) * 6 == 12
	.byte $84
	.byte $86
	.byte $88
	.byte $8a
	.byte $8c
	.byte $8a

;TABLE_COLOR_BLINE_PM1 ; P1, NTSC  ; ( ( 1 * 2 ) + 1 ) * 6 == 18
	.byte $94
	.byte $96
	.byte $98
	.byte $9a
	.byte $9c
	.byte $9a

TABLE_COLOR_BLINE_PMOFF
	.byte $02
	.byte $04
	.byte $06
	.byte $08
	.byte $0a
	.byte $08

