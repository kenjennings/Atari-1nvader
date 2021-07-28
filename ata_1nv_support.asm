;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
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

	jsr GameDecrementtHitCounter       ; Player award means minus 1 hit.

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
	adc zPLAYERPOINTS_TO_ADD,Y         ; Add mothership points (+ A as carry)
	adc zPLAYER_SCORE,X                ; Add to player score

	cmp #10                            ; Did Adding go over 9? (>= 10? )
	bcc b_gas_NoCarry                  ; No.  Do not carry.

b_gas_Carried                          ; Player score carried over 9.
	sec
	sbc #10                            ; Subtract 10 from score
	sta zPLAYER_SCORE,X                ; Save the adjusted score.
	lda #1                             ; Setup 1 for artificial carry.
	bne b_gas_LoopControl              ; Go to end of loop

b_gas_NoCarry                          ; Player score carried over 9.
	sta zPLAYER_SCORE,X                ; Save the added score.
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

	lda zPLAYER_ON,X
	beq b_gchs_Exit

	ldy #0                         ; Index into high score points.

	cpx #0                         ; If this is first player, then X is 
	beq b_ghcs_SaveX               ; already 0 for score index.  Just go.

	ldx #6                         ; Index into score for player 1 

b_ghcs_SaveX
	stx SAVEX                      ; Need to get this X value back again later.

b_gchs_CheckLoop                   ; Check while digits are equal.
	lda zPLAYER_SCORE,X
	cmp zHIGH_SCORE,Y              
	beq b_gchs_LoopControl         ; If it is the same continue looping.
	bcc b_gchs_Exit                ; If it is less than, then exit.  No hi score.

	; A digit is greater than hi score, so copy!
	ldx SAVEX                      ; Restore index value determined earlier.
	ldy #0                         ; Index into high score points.

b_gchs_CopyHiScoreLoop
	lda zPLAYER_SCORE,X            ; Copy the six 
	sta zHIGH_SCORE,Y              ; bytes of the 
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

	lda zAnimatePlayers   ; Check timer to delay movment. (VBI updates)
	bne b_gpm_Exit        ; Timer not 0, so still running.

	lda #2                ; Player movement timer expired.  
	sta zAnimatePlayers   ; Reset it.
	
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
	dey

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
	iny
	
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
	sta zLASER_NEW_Y               ; Flag this laser to get erased.

	lda zMOTHERSHIP_X              ; Set Explosion X, Y == Mothership X, Y
	sta zEXPLOSION_X
	lda zMOTHERSHIP_Y
	sta zEXPLOSION_NEW_Y

	lda #15 
	sta zEXPLOSION_COUNT          ; jiffy count for explosion graphic

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
	cmp #LASER_END_Y    ; Is Laser at Y Limit?
	bne b_clip_DoMove   ; No.  

	; Stop Laser Sound here.  If the other laser is not running

	lda #0              ; Zero New_Y is signal to remove from screen.
	beq b_clip_UpdateY

b_clip_DoMove
	sec                 ; Subtract 4 from laser Y
	sbc #4
	
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
;    c) If lazer Y, in bottom half of screen, skip shooting
;       i) set lazer on, 
;       ii) Laser Y = gun new Y - 4, Laser X = gun new X
;       iii) If no bounce this turn, then negate direction/set bounce.
;
; Maybe add code to insure player releases the button before 
; attempting to shoot again.... ?????
;
; X == the Player/gun/laser
; --------------------------------------------------------------------------

CheckPlayerShooting

	lda zPLAYER_ON,X        ; Is this player even playing?
	beq b_cps_Exit          ; Nope.  Done here.

	lda zPLAYER_CRASH,X     ; Is the gun crashed by alien?
	bne b_cps_Exit          ; Yes.  Done here.

	lda STRIG0,X            ; (Read) TRIG0 - Joystick trigger (0 is pressed. 1 is not pressed)
	beq b_cps_TryLaserShot  ; Fire button pressed.
	lda #0
	sta zPLAYER_DEBOUNCE,X  ; Turn off debounce to allow shooting again.
	beq b_cps_Exit          ; Done here.

b_cps_TryLaserShot
	lda zLASER_ON,X         ; Is Laser on?
	beq b_cps_TestDebounce  ; No.  Ok to shoot.

	lda zLASER_NEW_Y,X      ; Is Laser still in bottom half of screen?
	bmi b_cps_Exit          ; Yes.  Done here.

b_cps_TestDebounce          ; The button must have been released before shooting again.
	lda zPLAYER_DEBOUNCE,X  ; 1 is trigger is still held.  0 is trigger has been released.
	bne b_cps_Exit          ; Nope.  No machine gunning here.  Let go the button first.
  
	jsr StartShot           ; Yippie-Ki-Yay Bang Bang Shoot Shoot.

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

	lda zMOTHERSHIP_Y
	cmp zMOTHERSHIP_NEW_Y      ; Is Y the same as NEW_Y?
	beq b_gmm_RunTheMothership ; Yes.   Ok to run the mothership movement.
	rts                        ; No.  Skip this until vertical positions match. (VBI does this).

b_gmm_RunTheMothership
; Determine min/max for this row.   Row 22 allows mothership to move 
; off the screen completely.   When the Stats Text Color is zero, then 
; we're on row 22.

	lda zSTATS_TEXT_COLOR      ; If this is zero, mothership is on row 22.
	bne b_gmm_SetRegularMinMax ; Set Min/Max to normal values.

	lda #15                    ; Here set Min/Max off screen
	sta zMOTHERSHIP_MIN_X
	lda #232
	sta zMOTHERSHIP_MAX_X
	bne b_gmm_ContinueSetSpeed

b_gmm_SetRegularMinMax         ; Here use the normal values for screen width.
	lda #MOTHERSHIP_MIN_X
	sta zMOTHERSHIP_MIN_X
	lda #MOTHERSHIP_MAX_X
	sta zMOTHERSHIP_MAX_X

; Determine speed (distance to move) here.
; See discussion above.   There are two possible entries 
; from the table (indexed by Move speed + 0, and Move speed + 1)
; Toggle the counter value to create the +0/+1 offset each frame.

b_gmm_ContinueSetSpeed
	ldy zMOTHERSHIP_MOVE_SPEED      ; index into speed table.
	dec zMOTHERSHIP_SPEEDUP_COUNTER ; toggle the offsetter, 1,0,-1 (1).
	bpl b_gmm_ContinueSpeedSetup    ; If still positive, then collect speed value 
	lda #1                          ; Offsetter went negative.  
	sta zMOTHERSHIP_SPEEDUP_COUNTER ; Reset the offsetter to 1.
	iny                             ; increment the index into the speed table.

b_gmm_ContinueSpeedSetup
	lda TABLE_SPEED_CONTROL,y       ; A == value from speed table to add/subtract 
	sta zMOTHERSHIP_MOVEMENT        ; Save new value to add/subtract  

	lda zMOTHERSHIP_X               ; A == Get current X position

	ldy zMOTHERSHIP_DIR      ; Test direction. ; 0 == left to right. 1 == right to left.
	bne b_gmm_Mothership_R2L ; 1 = Right to Left

; Moving Left to Right

	clc                      ; Doing left to right. 
	adc zMOTHERSHIP_MOVEMENT ; A already contains the X position.  Add the movement.
	cmp zMOTHERSHIP_MAX_X    ; Is the new value at the max?
	bcc b_gmm_Save_MSX_L2R   ; A  less than max, so just save it.
	lda zMOTHERSHIP_MAX_X    ; reset to max.

b_gmm_Save_MSX_L2R
	sta zMOTHERSHIP_NEW_X    ; Save new Mothership X
	cmp zMOTHERSHIP_MAX_X    ; Reached max means time to inc Y and reverse direction.
	bne b_gmm_Exit_MS_Move   
	beq b_gmm_MS_EndOfLife   ; Check if mothership reached the bottom row/end of movement 

; Moving Right to Left

b_gmm_Mothership_R2L 
	sec                      ; Doing right to left. 
	sbc zMOTHERSHIP_MOVEMENT ; A already contains the increment value, Add X
	cmp zMOTHERSHIP_MIN_X    ; Is the new value at the min?
	bcs b_gmm_Save_MSX_R2L   ; A >= min, so just save the new value. 
	lda zMOTHERSHIP_MIN_X    ; reset to min.
	
b_gmm_Save_MSX_R2L
	sta zMOTHERSHIP_NEW_X    ; Save new Mothership X
	cmp zMOTHERSHIP_MIN_X    ; Reached min means time to inc Y and reverse direction.
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
	lda zMOTHERSHIP_DIR      ; Toggle X direction.
	beq b_gmm_Set_R2L        ; is 0, set 1 = Right to Left
	lda #0
	beq b_gmm_UpdateDirection
b_gmm_Set_R2L
	lda #1
b_gmm_UpdateDirection
	sta zMOTHERSHIP_DIR

b_gmm_CheckLastRow
	ldx zMOTHERSHIP_ROW      ; Get current row.
	cpx #22                  ; If on last row, then it has
	bne b_gmm_GoToNextRow    ; reached the end of incrementing rows.

	; Game Over
	inc zGAME_OVER_FLAG
	rts

b_gmm_GoToNextRow
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
	inc zPLAYER_DEBOUNCE,X   ; Flag to do debounce tests on the next shot.
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


	lda zMOTHERSHIP_Y                 ; Copy current mothership position to new
	sta zEXPLOSION_NEW_Y              ; explosion position to initiate explosion.
	lda zMOTHERSHIP_X
	sta zEXPLOSION_X

	jsr Pmg_DrawExplosion             ; Start new explosion cycle.

	jsr GameRandomizeMothership       ; Choose random direction, set new X accordingly.

	ldx zMOTHERSHIP_ROW               ; Subtract 2
	dex                               ; from the
	dex                               ; mothership row. 
	bpl b_gpe_ContinueReset           ; If the result is positive, then update row. 
	ldx #0                            ; Negative must be limited to 0.
b_gpe_ContinueReset
	jsr GameSetMotherShipRow          ; Set New Mothership Y to new row in X register.

	rts                               ; And done.


b_gpe_DoCurrentExplosion
	lda zEXPLOSION_ON                 ; Is an explosion running?
	beq b_gpe_Exit                    ; Nope.  Exit.

	ldx zEXPLOSION_COUNT              ; Get current counter.
	beq b_gpe_StopExplosion           ; If it is 0 now, then stop explosion

	dex
	stx zEXPLOSION_COUNT
	lda TABLE_COLOR_EXPLOSION,X       ; Get color from table.
	sta PCOLOR3                       ; Update OS shadow register.
	sta COLPM3                        ; Update hardware register to be redundant.
	rts


b_gpe_StopExplosion
	lda #0
	sta zEXPLOSION_NEW_Y
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
	
	stx zMOTHERSHIP_ROW              ; Save new Row.
	lda TABLE_ROW_TO_Y,X             ; Get new target Y position.
	sta zMOTHERSHIP_NEW_Y            ; Save for VBI to redraw mothership.

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
	sta zMOTHERSHIP_DIR             ; 0 == left to right. 1 == right to left.
	bne b_grm_SetMothershipMax_X    ; 1 == right to left.

	lda #MOTHERSHIP_MIN_X           ; 0 == left to right.  Left == Minimum
	bne b_grm_SetMothership_X       ; Save horizontal position
	
b_grm_SetMothershipMax_X
	lda #MOTHERSHIP_MAX_X           ; Right == Maximum

b_grm_SetMothership_X               ; Start horizontal position coord.
	sta zMOTHERSHIP_NEW_X
	sta zMOTHERSHIP_X

	rts


; ==========================================================================
; ROW NUMBER TO DIGITS
; ==========================================================================
; Convert Row Number to bytes for easier transfer to screen.
; This has to convert an integer that could be 0 to 21 at any time.
; It's easier just to use a lookup table.
; --------------------------------------------------------------------------

GameRowNumberToDigits

	ldx zMOTHERSHIP_ROW             ; Get the current Row.
	lda TABLE_TO_DIGITS,X           ; Get two digits as byte/nybble
	pha                             ; Save to do second digit.

	and #$F0                        ; Mask to keep first digit.
	lsr                             ; Right shift
	lsr                             ; to move digit
	lsr                             ; into the  
	lsr                             ; low nybble.
	sta zMOTHERSHIP_ROW_AS_DIGITS   ; Save as byte. 

	pla                             ; Get value saved earlier.

	and #$0F                        ; Mask to keep second digit.
	sta zMOTHERSHIP_ROW_AS_DIGITS+1 ; Save as byte. 

	rts


; ==========================================================================
; MOTHERSHIP POINTS TO DIGITS
; ==========================================================================
; Given a Row Number get the point value, and distribute as individual 
; digits.  This facilitates simplifying the math, and maps the value
; in a form that's easier to copy to the screen.
; --------------------------------------------------------------------------

GameMothershipPointsToDigits

	lda zMOTHERSHIP_ROW             
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
	sta zMOTHERSHIP_POINTS_AS_DIGITS,Y ; Save as byte. 

	iny                                ; Next position in digits string.
	pla                                ; Get value saved earlier.

	and #$0F                           ; Mask to keep second digit.
	sta zMOTHERSHIP_POINTS_AS_DIGITS,Y ; Save as byte. 
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
	lda zMOTHERSHIP_POINTS_AS_DIGITS,X ; Copy current picture of point
	sta zPLAYERPOINTS_TO_ADD,X         ; Save to player(s) awarded value.

	dex
	bpl b_gmspfp_CopyLoop

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
	sta zMOTHERSHIP_HITS

	lda #$08
	sta zSHIP_HITS_AS_DIGITS        ; Tens digit is "8"
	lda #$00
	sta zSHIP_HITS_AS_DIGITS+1      ; Ones digit is "0"

	sta zMOTHERSHIP_MOVE_SPEED      ; Zero move speed.
	sta zMOTHERSHIP_SPEEDUP_COUNTER ; Zero speed offset

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

GameDecrementtHitCounter

	dec zMOTHERSHIP_HITS         ; If this goes to 0, then
	beq GameResetHitCounter      ; go up to reset counter (will not return here.)

	dec zSHIP_HITS_AS_DIGITS+1   ; Subtract from ones place digit.
	beq b_gdhc_CheckSpeedControl ; If ones is 0, then go to next mothership speed.
	bpl b_gdhc_Exit              ; Some other non-zero digit.  Done here.

	lda #$9                      ; Ones digit went to -1
	sta zSHIP_HITS_AS_DIGITS+1   ; Reset ones to 9
	dec zSHIP_HITS_AS_DIGITS     ; Subtract 1 from tens position.
	rts

b_gdhc_CheckSpeedControl        ; Need to add +2 for 2 entries for hpos+ entries.
	inc  zMOTHERSHIP_MOVE_SPEED ; Speedup++
	inc  zMOTHERSHIP_MOVE_SPEED ; Speedup++

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

	ldy #5
b_gzs_Loop_ZeroPlayerScores
	sta zPLAYER_ONE_SCORE,y ; maybe something more here... like points add, or mothership value, too.
	sta zPLAYER_TWO_SCORE,y
	dey
	bpl b_gzs_Loop_ZeroPlayerScores
	
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

	lda zMOTHERSHIP_NEW_X   ; Get new display position of mothership
	
	ldy zMOTHERSHIP_DIR     ; 0 = left to right.   1 = Right to Left
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
; SUPPPORT - GAME OVER TRANSITION 
; ==========================================================================
; Per Frame Process - Animate display for Game Over screen.
;
; Called By VBI.   
;
; Presenting the Game Over text on the screen occurs in a transition 
; character by character.  There are two transitions running -- one from 
; the left edge of the screen toward the center, and one from the right 
; edge of the screen toward the center.
; Each transition action occurs at the same time in sync with each 
; other.   When state one is done on a character it moves to the next 
; character and state two begins on that old character positions, and so
; forth for the following states.   This produces an animation that 
; changes shape and color, character by character making it seem 
; ambiguous what graphics mode is used for this activity. 
;
; One activity occurs per each transition stage. 
; States 1 to 3 take six frames.  State 4 is the final state.
; 
; 1) COLPF0 - grow text by masking character image into a temporary work
;    character.  (two characters needed, one for left, and one right.)
;    color changes from white to very light green/blue like mothership 
;    explosion.  On the last frame the temporary work character has the 
;    same image map as the real character. 
;    Stand-n characters' $1C for left sequence, $1D for right sequence.
; 2) COLPF1 - Set character as real character with correct bits for the 
;    current color register.  Transition color from light to med/dk grey.
; 3) COLPF2 - subject to DLI that slides the colors from flat grey to 
;    match the final colors of the "normal" color state.
; 4) COLPF3 - the "normal" end state for constand display of the text.
;    DLI has a green grdient at the top and grey at the bottom.
;
; Side bar -- Since the blank space is character value 0, and nothing
; is displayed, then it does not matter if the State engine runs on 
; that character or not, since nothing is visible.
;
; Init code has done setup:
; Cleared the Game Over message memory.
; Set left index 0 (0 - 9), set right Index 19 (19 - 10)
; Created pointer to target text to display.
; Establish pointer to "currrent" left/right characters in character set.
; Set Phase 2, 3, 4 off.
; 
; --------------------------------------------------------------------------

GameOverTransition

	; jsr Gfx_UpdateGameOverChars

	rts


; ==========================================================================
; FILTER CHAR INDEX
; ==========================================================================
; Given the current character index establish if it is out of bounds 
; and provide a replacement.  And Value over 9 is limited to 9. 
;
; This may nee do tbe called repeatedly. 
; 
; Y is the character index value to filter.
; --------------------------------------------------------------------------

TempCharIndex .byte 0
TempCharValue .byte 0

GameFilterCharIndex

	sty TempCharIndex

;	lda #0                    ; Corresponds to blank space.

; ldy zGO_CHAR_INDEX  
	cpy #$FF                  ; Current index for character.
	beq b_gfci_Exit           ; If index is not set, just return.

	cpy #10                   ; If this is less than 10, 
	bcc b_gfci_UseIndex       ; just use it.

	ldy #9                    ; Otherwise, this is the last position.

b_gfci_UseIndex
	sty TempCharIndex        ; Save for math later.

b_gfci_Exit
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
; Y is index position.
;
; RETURN  A = character
; --------------------------------------------------------------------------

GameGetLeftChar

	jsr GameFilterCharIndex ; Filter Y, set TempCharIndex

	lda #0                    ; Corresponds to blank space.

	cpy #$FF                  ; Current index for character.
	bne b_ggrc_GetChar        ; Go get value and save temp
	rts                       ; (BEQ) If index is not set, just return 0.

	; Yes, the branch above goes into the routine below.

; ==========================================================================
; GET RIGHT CHAR
; ==========================================================================
; Given the current character index, get the character on the right 
; side of the display string.
; 
; This is more complicated than left.   The index counts 0 to 12.  
; If the value is 10, 11, 12, then force to retrieve from position 
; 9 in the text string. 
; The character on the right are addressed at positions 19 to 10.
; a little math is involved.
;
; Other code must set up the pointers.
; 
; Y is index position.
;
; RETURN  A = character
; --------------------------------------------------------------------------

GameGetRightChar

	jsr GameFilterCharIndex   ; Filter Y, set TempCharIndex

	lda #0                    ; Corresponds to blank space.

; ldy zGO_CHAR_INDEX  
	cpy #$FF                  ; Current index for character.
	beq b_ggrc_Exit           ; If index is not set, just return 0.

	sec                       ; set carry
	lda #19                   ; last position on text line
	sbc TempCharIndex         ; minus index
	sta TempCharIndex         ; Change CharIndex result for caller.
	tay                       ; use index in Y


b_ggrc_GetChar
	lda (zGAME_OVER_TEXT),Y   ; Get character at index 
	sta TempCharValue         ; Save in temp buffer in case of using A again

b_ggrc_Exit
	rts


; ==========================================================================
; SUPPPORT - SETUP CSET ADDR 
; ==========================================================================
; Called by VBI.
;
; setup the address for the source character in the character set.
;
; Multiply character by 8.  Add to base address of custom character set.
;
; A == the character value.
; --------------------------------------------------------------------------

GameSetupCsetAddresss

	ldx #0
	stx zGO_CSET_C_ADDR
	stx zGO_CSET_C_ADDR+1

	clc

	asl
	rol zGO_CSET_C_ADDR+1 ; times 2
	asl
	rol zGO_CSET_C_ADDR+1 ; times 4
	asl
	rol zGO_CSET_C_ADDR+1 ; times 8

	sta zGO_CSET_C_ADDR

	clc
	lda #>CHARACTER_SET
	adc zGO_CSET_C_ADDR+1
	
	rts


; ==========================================================================
; SUPPPORT - SETUP MASK ADDR 
; ==========================================================================
; Called by VBI.
;
; Setup the address for the mask table based on the frame number.
;
; Multiply frame number by 8.  Add to base address of mask image array.
;
; A == the current frame number.
; --------------------------------------------------------------------------

GameSetupMaskAddresss

	ldx #0
	stx zGO_MASK_ADDR
	stx zGO_MASK_ADDR+1

	clc

	asl
	rol zGO_MASK_ADDR+1 ; times 2
	asl
	rol zGO_MASK_ADDR+1 ; times 4
	asl
	rol zGO_MASK_ADDR+1 ; times 8

	clc
	adc #<TABLE_GAME_OVER_MASK_FRAMES
	sta zGO_MASK_ADDR
	lda #>TABLE_GAME_OVER_MASK_FRAMES
	adc zGO_MASK_ADDR+1

	rts


