;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; PLAYER/MISSILE GRAPHICS MEMORY
;
; Here is all the code used to manage Player/Missile graphics.  
; Most of this is about copying image bitmaps to the Player/Missile memeory 
; map.
;
; Most Player/Missile graphics images are declared in the first three 
; unused pages in the memory map. 
; --------------------------------------------------------------------------


;==============================================================================
;												Pmg_Init  A  X  Y
;==============================================================================
; One-time setup tasks to do Player/Missile graphics.
; Zero all positions.
; Clear all bitmaps.
; Set  GRACTL and SDMCTL for  pmgraphics.
; Set PRIOR
; -----------------------------------------------------------------------------

Pmg_Init

	jsr Pmg_AllZeroHPOS  ; get all Players/Missiles off screen.

	; clear all bitmap images
	jsr Pmg_Zero_PM_Memory

	; Tell ANTIC where P/M memory is located for DMA to GTIA
	lda #>PMADR
	sta PMBASE

	; Enable GTIA to accept DMA to the GRAFxx registers.
	lda #[ENABLE_PLAYERS|ENABLE_MISSILES]
	sta GRACTL

	; Set all the ANTIC screen controls and DMA options.
	lda #[ENABLE_DL_DMA|ENABLE_PM_DMA|PM_1LINE_RESOLUTION|PLAYFIELD_WIDTH_NORMAL]
	sta SDMCTL

	; Setup PRIOR 
	lda #[FIFTH_PLAYER|GTIA_MODE_DEFAULT|1] ; Normal CTIA color interpretation
	sta GPRIOR

	rts 


;==============================================================================
;											Pmg_AllZero  A  X
;==============================================================================
; Simple hardware reset of all Player/Missile registers.
; Typically used only at program startup to zero everything
; and prevent any screen glitchiness on startup.
;
; Reset all Players and Missiles horizontal positions to 0, so
; that none are visible no matter the size or bitmap contents.
; Zero all colors.
; Also reset sizes to zero.
; -----------------------------------------------------------------------------

Pmg_AllZeroHPOS

	jsr Pmg_SetHPOSZero   ; Sets all HPOS off screen.

	lda #$00                ; 0 position
	ldx #$03                ; four objects, 3 to 0

bAZ_LoopZeroPMSpecs
	sta SIZEP0,x            ; Player width 3, 2, 1, 0
	sta PCOLOR0,x           ; And black the colors.
	dex
	bpl bAZ_LoopZeroPMSpecs

	sta SIZEM

	rts


;==============================================================================
;											Pmg_SetHPOSZero  A  X
;==============================================================================
; Zero the hardware HPOS registers.
;
; Useful for DLI which needs to remove Players from the screen.
; With no other changes (i.e. the size,) this is sufficient to remove 
; visibility for all Player/Missile overlay objects 
; -----------------------------------------------------------------------------

Pmg_SetHPOSZero

	lda #$00                ; 0 position

	sta HPOSP0 ; Zero Player positions 0, 1, 2, 3
	sta HPOSP1
	sta HPOSP2
	sta HPOSP3

	sta HPOSM0 ; Zero Missile positions 0, 1, 2, 3
	sta HPOSM1
	sta HPOSM2
	sta HPOSM3

	rts


; ==========================================================================
; ZERO PM MEMORY 
; ==========================================================================
; Initialization function to write 0 bytes to the memory map for all the 
; Players and Missiles.
;
; Useless trivia: Antic does not do DMA on the first 8 scan lines and 
; last 8 scan lines.  So, the loop only needs to zero 240 (256 - 16) bytes, 
; or scan lines 8 to 247.  In order to make this a convenient reverse 
; counting loop we have to count from 240 to 1, using 0 as the end of loop
; flag rather than from 239 to 0 with -1 (255) as the end of loop flag, 
; because the starting location, (239), is viewed as negative by the 
; CPU flags.
; Therefore, the target addresses are offset from the actual Player/Missile 
; base addresses by 7 instead of 8.
; --------------------------------------------------------------------------

Pmg_Zero_PM_Memory

	lda #0
	ldx #240            ; Counting 240 to 1, zero flags the end.

b_pzpm_LoopZero
	sta PLAYERADR0+7,X  ; Zero each P/M memory map...
	sta PLAYERADR1+7,X
	sta PLAYERADR2+7,X
	sta PLAYERADR3+7,X
	sta MISSILEADR+7,X

	dex                 ; Index Minus 1 
	bne b_pzpm_LoopZero ; Loop if this is not zero.

	rts


; ==========================================================================
; SETUP HARDWARE
; ==========================================================================
; Support.
; Given the player number in X, setup the Hardware pointer to the 
; Player/Missile memory map.
;
; X == the player/gun/laser number.
; --------------------------------------------------------------------------

Pmg_Setup_Hardware

	lda #0                 ; Setup zero page pointer to Player memory
	sta zPMG_HARDWARE
	lda zPLAYER_PMG,X
	sta zPMG_HARDWARE+1

	rts


; ==========================================================================
; DRAW BIG MOTHERSHIP
; ==========================================================================
; Copy the image bitmaps for Right and Left into Player 2 and 3  memory
; maps.  The current Y position is zBIG_MOTHERSHIP_Y
; 
; This object has its own dedicated code, because it is working on two 
; Player objects and makes an object twice the height of everything 
; else in the game.
;
; Each of the 8 bytes is copied twice to make a 16 scan line image followed 
; by two 0 bytes to erase any trailing bytes assuming the image is being
; animated to fly up the screen.
;
; If the Y value is negative, then the image is overwritten with 0 bytes
; starting from the 0th position assuming that the intent is to remove 
; the image from the top of the screen.
; --------------------------------------------------------------------------

Pmg_Draw_Big_Mothership

	lda #0                ; Prep with 0
	ldx #0                ; Copy 8 times.
	ldy zBIG_MOTHERSHIP_Y ; Current Y position
	bmi b_pdbm_Zero       ; If negative, then 0 the top image memory

b_pdbm_LoopDraw
	lda PMG_IMG_BIGGERSHIP_L,X ; Get byte from saved image
	sta PLAYERADR2,Y       ; Write to P/M memory
	lda PMG_IMG_BIGGERSHIP_R,X ; Get byte from saved image
	sta PLAYERADR3,Y       ; Write to P/M memory

	iny                    ; One position lower.
	inx                    ; next byte

	cpx #16                 
	bne b_pdbm_LoopDraw    ; End after copying 16.

	; End by zeroing the next two bytes to erase a prior image.
	lda #0
	sta PLAYERADR2,Y       ; Write to P/M memory
	sta PLAYERADR3,Y       ; Write to the other P/M memory
	iny
	sta PLAYERADR2,Y       ; Write to P/M memory
	sta PLAYERADR3,Y       ; Write to the other P/M memory

	rts

	; Useless trivia -- The P/M DMA does not read the first 8 bytes of the
	; memory map, so we really only need to zero the second 8 bytes.
	
b_pdbm_Zero                ; Zero 8 bytes from position 8 to 15 

	ldx #7                 ; 7, 6, 5 . . . 0

b_pdbm_LoopZero
	sta PLAYERADR2+8,X       ; Zero Player memory
	sta PLAYERADR3+8,X       ; Zero Player memory
	dex
	bpl b_pdbm_LoopZero    ; Loop until X is -1

	rts


; ==========================================================================
; DRAW LASERS
; ==========================================================================
; Copy the image bitmaps for the Laser to the New Y positions.
; Main code manages Y position.   
; If New Y position is 0, then clear out the old position, and turn off 
; laser.
; 
; X == laser to update
;
; Copy the Laser's NEW_Y to Y.
; --------------------------------------------------------------------------

Pmg_Draw_Lasers

	ldx #0
	jsr Pmg_Draw_Laser

	ldx #1
	jsr Pmg_Draw_Laser

	rts
	
	

; ==========================================================================
; DRAW LASER
; ==========================================================================
; Copy the image bitmaps for the Laser to the New Y positions.
; Main code manages Y position.   
; If New Y position is 0, then clear out the old position, and turn off 
; laser.
;
; (The laser always moves, so if the laser is ON then it must be drawn.)
; 
; X register is Laser to update.   Same code is used for both lasers.
;
; If the laser is off, then exit.
; The laser starts partly "obscured" by the gun.   Also, Vertical movement
; requires erasing some scan lines.   The copying is done in segments. 
; Copy the first 4 bytes, then check if the Y position is the gun.
; If not, copy the next 4 bytes.  Check position again.
; If not at the gun, copy 4 0 bytes.
;
; Zero the redraw flags.
; Copy the Laser's NEW_Y to Y.
; --------------------------------------------------------------------------

Pdl_Temp_Laser_Num .byte 0

Pmg_Draw_Laser

	lda zLASER_ON,X        ; Is laser on?
	beq b_pdl_Exit         ; Nope.  We're done.

	stx Pdl_Temp_Laser_Num ; Save X identifying player for later

	jsr Pmg_SetLaserColor  ; set laser color from table and increment the index.

	jsr Pmg_Setup_Hardware ; Setup zero page pointer to Player memory

	lda zLASER_NEW_Y,X     ; If New Y is 0, then 
	beq Pmg_RemoveLaser    ; Remove laser at old position and stop laser.

	; New Laser Y should always be less than old Y.
	; If not, then the laser has been restarted, so erase at old position.
	tay                    ; Copy New Y into Y for later.
	cmp zLASER_Y,X         ; Is new position greater than old position?
	bcc b_pdl_StartTheDraw ; No.  Go do a normal render.

	jsr Pmg_RemoveLaser    ; Completely erase old image first.
	ldx Pdl_Temp_Laser_Num ; Need to restore New Y again.
	ldy zLASER_NEW_Y,X     

; Copy the image into Player memory is done in 4 line blocks,
; because the lasers move 4 scan lines per frame.
;
; The first draw needs to do only the top 4 lines of laser image data.
; The second draw needs to copy all 8 bytes of laser image data.
; All draws after copy the full 8 bytes of image and then blank the 
; 4 lines that follow to erase the old laser as it moves up the 
; screen.

b_pdl_StartTheDraw
	lda #0
	sty zLASER_Y,X         ;  Current Y == new Y

	ldx #0
b_pdl_CopyLaserFirst4      ; Copy the first 4 bytes of the laser image
	lda PMG_IMG_LASER,X    ; byte from laser image...
	sta (zPMG_HARDWARE),Y  ; copy to Player/Missile memory
	iny
	inx
	cpx #4                 
	bne b_pdl_CopyLaserFirst4 ; Loop until 4th  byte copied.

	cpy #PLAYER_PLAY_Y      ; If Y reached the Player's gun position
	beq b_pdl_Exit          ; No more copying.


b_pdl_CopyLaserNext4        ; Copy the first 4 bytes of the laser image
	lda PMG_IMG_LASER,X     ; byte from laser image...
	sta (zPMG_HARDWARE),Y   ; copy to Player/Missile memory
	iny
	inx
	cpx #8
	bne b_pdl_CopyLaserNext4 ; Loop until 8th byte copied.

	cpy #PLAYER_PLAY_Y      ; If Y reached the Player's gun position
	beq b_pdl_Exit          ; No more copying.


	lda #0                  ; Erase the following 4 bytes
b_pdl_CopyLaserZero
	sta (zPMG_HARDWARE),Y   ; zero byte in  Player/Missile memory
	iny
	inx
	cpx #12
	bne b_pdl_CopyLaserZero ; Loop until reaching the 12th line.

b_pdl_Exit                  ; End, copy Y == New Y
	rts
        

; ==========================================================================
; REMOVE LASER
; ==========================================================================
; REMOVING the laser can happen automatically when the laser Y reaches 
; the minimum position or anywhere above the middle of the screen if 
; the player restarted the laser shot.  So,it is a variable situation.
; If the New Y is 0, then the laser is being automatically turned off.
; Otherwise, the laser is being restarted, so after clearing it DO NOT
; turn off the laser.
;
; (The laser always moves, so if the laser is ON then it must be drawn.)
; 
; X register is Laser to update.   Same code is used for both lasers.
; --------------------------------------------------------------------------

Pmg_RemoveLaser

	lda #0
	ldy zLASER_Y,X             ; Is the old position at the end?
	cpy #LASER_END_Y
	bne b_pdr_SkipTurnOffLaser ; No.  Do not turn off laser.

	; It is possible that Old Y in the end position MAY coincide with 
	; restarting the laser. If the new Y is zero, then it is OK to 
	; turn off the laser.
	lda zLASER_NEW_Y,X
	bne b_pdr_SkipTurnOffLaser ; Not 0.   Do not turn off.

	lda #0
	sta zLASER_ON,X   ; Turn off laser
	sta zLASER_Y,X    ; Zero current Y position.
	sta zLASER_X,X    ; Maybe this will help.

b_pdr_SkipTurnOffLaser
	lda #0
	ldx #7

b_pdr_LoopDoErase
	sta (zPMG_HARDWARE),Y ; Erase at old position
	iny
	dex
	bpl b_pdr_LoopDoErase

b_pdr_Exit
	rts



; ==========================================================================
; SET LASER COLOR
; ==========================================================================
; Update the laser color from the index into the color table.
;
; Update the index to the next value.
; 
; X == current player.  Will be mangled in code.  Expect temp variable
; was already set before calling this.
;
; X will be returned as the current player number.
; --------------------------------------------------------------------------

Pmg_SetLaserColor

	lda zLASER_COLOR,X       ; Get index into color table.
	asl                      ; times 2
	tax                      ; save (for increment)
	lda Pdl_Temp_Laser_Num   ; Get player number
	beq b_pslc_0ColorIndex   ; 0 needs no increment
	inx                      ; Player 2 laser needs +1

b_pslc_0ColorIndex           ; Update the color index for the player's laser.
	lda TABLE_COLOR_LASERS,X ; Color from table
	ldx Pdl_Temp_Laser_Num   ; get player number back.
	sta COLPM0,X             ; Goes into color register.

	ldy zLASER_COLOR,X       ; Get the player's laser's color index
	iny                      ; increment it
	cpy #6                   
	bne b_pslc_SkipColorReset ; It has not reached limit.  Skip reset.
	ldy #0                   ; Restart index.
b_pslc_SkipColorReset
	sty zLASER_COLOR,X       ; Update with new index value

	rts


; Old Version randomized the colors.

;	lda RANDOM               ; Set laser colors
;	and #$F0
;	ora #$0D
;	sta COLPM0
;	lda RANDOM              
;	and #$F0
;	ora #$0D
;	sta COLPM1


; ==========================================================================
; DRAW EXPLOSION
; ==========================================================================
; Copy the image bitmaps for the boom to the explosion New Y position.
;
; This is a bit more simple than the code sharing the guns.
; There is the slight possibility that a new explosion may need to 
; start before the old explosion is finished, so this routine needs
; to handle both in the same call.  (Stop the old explosion, start 
; the next explosion.)
;
; If the explosion New Y is zero or does not match the Current Y, then 
; first erase the explosion at the Old Y position.
;
; If the New Y is not zero, then copy the explosion image to the 
; Player/Missile memory.
;
; Copy the New Y to the Current Y.
; Copy the X position to the HPOS.
; --------------------------------------------------------------------------

Pmg_DrawExplosion

	lda zEXPLOSION_NEW_Y      ; Get New Y postion.
	beq b_pde_RemoveExplosion ; It's 0.  Erase at current position.

	cmp zEXPLOSION_Y          ; Non-zero. Does it match current postion?
	beq b_pde_Exit            ; Yes.  Nothing to do here.

b_pde_RemoveExplosion
	ldy zEXPLOSION_Y          ; Get current position.
	beq b_pde_DrawExplosion   ; If zero, then skip this, and draw.
	ldx #7                    ; loop counter.
	lda #0
b_pde_EraseLoop
	sta PLAYERADR3,Y          ; Zero byte into Player memory
	iny
	dex
	bpl b_pde_EraseLoop

b_pde_DrawExplosion
	ldy zEXPLOSION_NEW_Y      ; Is there a new position?
	beq b_pde_StopExplosion   ; No.  Stop the explosion things.
	ldx #0                    ; loop counter.
	txa
b_pde_DrawLoop
	lda PMG_IMG_EXPLOSION,X   ; Get byte from image.
	sta PLAYERADR3,Y          ; Write image byte into Player memory
	iny
	inx
	cpx #8
	bne b_pde_DrawLoop

; Copy data for new Current position information and 
; reset the color/counter state.
	lda #1
	sta zEXPLOSION_ON        ; Let others know this is running.
	lda zEXPLOSION_NEW_Y     
	sta zEXPLOSION_Y         ; Current Y Position == New Y Position
	ldx zEXPLOSION_X         ; To be used later at SetHardware
	ldy #5
	sty zEXPLOSION_COUNT     ; Start of explosion color cycle
	lda TABLE_COLOR_EXPLOSION+5; Get first color from table.
	jmp b_pde_SetHardware

b_pde_StopExplosion          ; Turn off all the running specs.
	lda #0
	sta zEXPLOSION_ON
	sta zEXPLOSION_COUNT
	sta zEXPLOSION_X
	sta zEXPLOSION_Y
	tax

b_pde_SetHardware
	stx SHPOSP3              ; HPOS Shadow register = X Position.
	sta PCOLOR3              ; Update OS shadow register.
	sta COLPM3               ; Update hardware register to be redundant.

b_pde_Exit
	rts


; ==========================================================================
; DRAW PLAYERS
; ==========================================================================
; Copy the image bitmaps for the guns to the player Y positions.
;
; We're cheating a little here.   Usually for a general purpose 
; routine the player should be erased at the old Y, and redrawn 
; at the new Y.  However, in this simple game the player's gun image 
; includes a 0 byte at the start and the end, so when moved one 
; scan line at a time (the only possible movement it can do) a 
; redraw will delete any old image.
;
; Zero the redraw flags.
; Copy the Players' NEW_Y to Y.
;
; X == Player gun to update
; --------------------------------------------------------------------------

Pmg_Draw_Players

	ldx #0
	jsr Pmg_Draw_Player

	ldx #1
	jsr Pmg_Draw_Player

	rts


; ==========================================================================
; DRAW PLAYER
; ==========================================================================
; Copy the image bitmaps for the guns to the player Y positions.
; zPLAYER_ONE_Y and zPLAYER_TWO_Y 
;
; We're cheating a little here.   Usually for a general purpose 
; routine the player should be erased at the old Y, and redrawn 
; at the new Y.  However, in this simple game the player's gun image 
; includes a 0 byte at the start and the end, so when moved one 
; scan line at a time (the only possible movement it can do) a 
; redraw will delete any old image.
;
; Zero the redraw flags.
; Copy the Players' NEW_Y to Y.
; Copy the Players' NEW_X to X.
; --------------------------------------------------------------------------

Pmg_Draw_Player

	lda zPLAYER_REDRAW,X
	beq b_pdp_Exit

	jsr Pmg_Setup_Hardware   ; Setup zero page pointer to Player memory

	lda zPLAYER_NEW_X,X     ; Copy New X to Current X
	sta zPLAYER_X,X

	lda #0
	sta zPLAYER_REDRAW,X    ; Turn off redraw flag.

	ldy zPLAYER_NEW_Y,X     ; Get New Y position.
	bne b_pdps_DrawPlayer   ; If New Y is not 0, then draw gun.

	; New Y is 0, so erase at old position.
	ldy zPLAYER_Y,X         ; Get old position in Y  
	sta zPLAYER_Y,X         ; Zero old position from A (Set zero above).
	ldx #7                  
b_pdps_LoopErasePlayer
	sta (zPMG_HARDWARE),Y   ; Zero Player memory
	iny
	dex
	bpl b_pdps_LoopErasePlayer
	bmi b_pdp_Exit          ; Done.

b_pdps_DrawPlayer           ; Update the Player image at new Y position.
	sty zPLAYER_Y,X         ; From above, Copy New Y position to current position.
	ldx #0
b_pdps_LoopDrawPlayer
	lda PMG_IMG_CANNON,X    ; byte from gun image...
	sta (zPMG_HARDWARE),Y   ; copy to Player/Missile memory
	iny
	inx
	cpx #8
	bne b_pdps_LoopDrawPlayer

b_pdp_Exit
	rts


; ==========================================================================
; DRAW MOTHERSHIP
; ==========================================================================
; Draw the small mothership
;
; If the Old position is not the same as the New position then increment 
; the old position and redraw.
;
; Y position difference means this is vertical movement down to the next 
; row, so start by zeroing the first two scan lines at the current Y 
; position.  Then increment Y + 2.  This is safe as the end goal will 
; be Y + 8, so the increment will not cause Y to miss the check for 
; equality to the target position. 
;
; Copy the image bitmap into Player 2 memory map.  
;
; The current Y position is zMOTHERSHIP_NEW_Y
; 
; This object has its own dedicated code, because I'm too lazy to fix 
; the generic library for this.  By the time this is in its final form 
; most of that generic library stuff still hanging about will get
; deleted.
;
; If the Y value is negative, then the image is overwritten with 0 bytes.
; --------------------------------------------------------------------------

Pmg_Draw_Mothership

	lda zMOTHERSHIP_Y
	cmp zMOTHERSHIP_NEW_Y  ; Target position, but can't move there in one step....
	beq b_pdms_DoHPOS

	ldy zMOTHERSHIP_Y      ; Get current mothership Y (msy) 
	lda #0
	tax

	sta PLAYERADR2,Y       ; Write 0 to Y + 0 P/M memory
	iny                    ; Y + 1
	sta PLAYERADR2,Y       ; Write 0 to Y + 1 P/M memory
	iny                    ; Y + 1  (Or Y + 2 total)
	sty zMOTHERSHIP_Y      ; Save as the new "current" position.

b_pdms_LoopDraw
	lda PMG_IMG_MOTHERSHIP,X ; Get byte from saved image
	sta PLAYERADR2,Y       ; Write to P/M memory

	iny                    ; One position lower.
	inx                    ; next byte

	cpx #8                 
	bne b_pdms_LoopDraw    ; End after copying 8.

b_pdms_DoHPOS
	lda zMOTHERSHIP_NEW_X  ; And set new X position
	sta zMOTHERSHIP_X
	sta SHPOSP2

; Draw animated window on mothership.  The window moves in the same
; direction relative to the ship movement.  Therefore there are two
; versionf of animation.  One that counts up throrugh the animation 
; frames, and one that counts down through the frames.

	dec zMOTHERSHIP_ANIM_FRAME   ; Decrement clock for animation.
	bpl b_pdms_Exit              ; If still positive, skip animation
	lda #3                       ; Reset counter.. then do animation.
	sta zMOTHERSHIP_ANIM_FRAME
	
	ldx zMOTHERSHIP_ANIM         ; X = current windows animation frame
	lda zMOTHERSHIP_DIR          ; Mothership direction.  0 = left to right.   1 = Right to Left
	beq b_pdms_DoAnimL2R         ; 0, do Left to Right motion.

	inx                          ; Right to Left.  Count up through the animation frames.
	cpx #5                       ; Went past the end?
	bne b_pdms_WriteAnimByte     ; No.  Read to use the frame.
	ldx #0                       ; Yes, reset to beginning of this animation loop
	beq b_pdms_WriteAnimByte     ; And draw it.

b_pdms_DoAnimL2R                 
	dex                          ; Left to Right.  Count down through the frames.
	bpl b_pdms_WriteAnimByte     ; Still positive value?  Yes, ready to use the frame.
	ldx #4                       ; No.  Reset to begining  of this animation loop.

b_pdms_WriteAnimByte
	stx zMOTHERSHIP_ANIM         ; Save updated animation frame.
	ldy zMOTHERSHIP_NEW_Y        ; Get (New) position of mothership.
	iny                          ; Plus 3 for correct offset.
	iny
	iny
	lda PMG_MOTHERSHIP_ANIM,X    ; Get the windows frame
	sta PLAYERADR2,y             ; update the image in the player.

b_pdms_Exit
	rts


; Speed control for horizontal movement should be in the main code that 
; updates the position.
                                   ; should be 2
;	lda #2                         ; initial ms speed
;	sta zMOTHERSHIP_MOVE_SPEED     ; Loop this many times.
;	lda #10                        ; should be 10
;	sta zMOTHERSHIP_SPEEDUP_THRESH  ; speedup threshld
;	sta zMOTHERSHIP_SPEEDUP_COUNTER ; speedup count 


;==============================================================================
;												SetMotherShip  X
;==============================================================================
; Given Mothership row (X), update the mother ship specifications.
; Save the row.
;
; Really, this is more like mainline support code, but since the 
; mother ship is a player, we're putting the routine here.
; -----------------------------------------------------------------------------

Pmg_SetMotherShip

	stx zMOTHERSHIP_ROW   ; Set msy from
	lda TABLE_ROW_TO_Y,X  ; row 2 y table
;	sta zMOTHERSHIP_Y
	sta zMOTHERSHIP_NEW_Y

	jsr GetMothershipPoints ; X will contain Mothership Row

	inc zSHOW_SCORE_FLAG

;	jsr showscr

	rts


; ==========================================================================
; ANIMATE TITLE LOGO (MISSILES)
; ==========================================================================
; Change the Title  screen's Missile bitmap displays to colorize the
; pixels of the animated Title logo.   The VBI decremented the timer
; so remember to reset it here.  Note that the VBI also recalculated
; the Missile's HPOS values, so nothing else need be done here about 
; horizontal positions.   The VBI also determined the next frame index
; to use and reset it (and HPOS) if it had reached the end of the frames
; So, use these values in the condition they exist in now to redraw the 
; missiles.
; --------------------------------------------------------------------------

Pmg_Animate_Title_Logo

	lda #TITLE_SPEED_PM ; reset the animation clock for the title.
	sta zAnimateTitlePM

	; The VBI actually calculated new X and frame values.
	; Use whatever the variables say to use now.

	ldy zTitleLogoPMFrame
	ldx #TITLE_LOGO_Y_POS

	lda PM_TITLE_BITMAP_LINE1,Y
	jsr Pmg_StuffitInMissiles

	lda PM_TITLE_BITMAP_LINE2,Y
	jsr Pmg_StuffitInMissiles

	lda PM_TITLE_BITMAP_LINE3,Y
	jsr Pmg_StuffitInMissiles

	lda PM_TITLE_BITMAP_LINE4,Y
	jsr Pmg_StuffitInMissiles

	lda PM_TITLE_BITMAP_LINE5,Y
	jsr Pmg_StuffitInMissiles

	lda PM_TITLE_BITMAP_LINE6,Y
	jsr Pmg_StuffitInMissiles

	rts

;==============================================================================
;												StuffitInMissiles  X
;==============================================================================
; Given data in  A  write into the current  X  position and increment 
; X  for each write.
; Three, not Four lines, because 2 color clocks x 3 scan lines looks 
; more square on NTSC.
; -----------------------------------------------------------------------------

Pmg_StuffitInMissiles

	sta MISSILEADR,X
	inx
	sta MISSILEADR,X
	inx
	sta MISSILEADR,X
	inx

	rts

;==============================================================================
;												AdustMissileHPOS  A
;==============================================================================
; Given data (A)  Write the value into the HPOS value of missiles 3, 2, 1, 0.
; For each missile (and in that order) increment the HPOS value +4. 
; Save the value in the fake shadow registers and the actual hardware register.
; -----------------------------------------------------------------------------

Pmg_AdustMissileHPOS

	sta SHPOSM3 ; Fake shadow reg.
	sta HPOSM3  ; Hardware position register.
	clc
	adc #4      ; +4
	sta SHPOSM2 ; More of the same. . . .
	sta HPOSM2
	adc #4      ; +4
	sta SHPOSM1
	sta HPOSM1
	adc #4      ; +4
	sta SHPOSM0
	sta HPOSM0  ;  Yes, this is a bit of overkill.

	rts


; ==========================================================================
; CYCLE IDLE PLAYER
; ==========================================================================
; One of the Players MAY be offline during the countdown.
; Whichever one it is, strobe the brightness.
; --------------------------------------------------------------------------

Pmg_CycleIdlePlayer

	ldx #0
	jsr Pmg_CyclePlayer

	ldx #1
	jsr Pmg_CyclePlayer

	rts


; ==========================================================================
; CYCLE PLAYER
; ==========================================================================
; One of the Players MAY be offline during the countdown.
; Whichever one it is, strobe the brightness.
; --------------------------------------------------------------------------

Pmg_CyclePlayer

	lda zPLAYER_ON,X
	bpl b_pcp_End       ; Player  on (+1)  Nothing to do.

	inc zPLAYER_COLOR,X ; Player Idle.  Cycle idle color.
	lda zPLAYER_COLOR,X
	and #$0F
	sta zPLAYER_COLOR,X

b_pcp_End
	rts


; ==========================================================================
; SQUASH IDLE PLAYER
; ==========================================================================
; While the mothership is leaving squash the idle player, if there is one.
; --------------------------------------------------------------------------

Psip_Temp_Byte_Count .byte 0

Pmg_SquashIdlePlayer

	ldx #0
	jsr Pmg_SquashPlayer

	ldx #1
	jsr Pmg_SquashPlayer
	
	rts


; ==========================================================================
; SQUASH IDLE PLAYER
; ==========================================================================
; While the mothership is leaving squash the idle player, if there is one.
; Negative ON flag means the player is in motion to become ON.
; 
; --------------------------------------------------------------------------

Pmg_SquashPlayer

	lda zPLAYER_ON,X
	bpl b_psp_End            ; Player moving (-1) or on (+1)? On is nothing to do.

	jsr Pmg_Setup_Hardware

	ldy zPLAYER_Y,X          ; Player Off.   
	cpy #PLAYER_SQUASH_Y     ; Did Y position reach the bottom?
	bne b_psp_Squash         ; No.  Continue squashing.
	lda #0                   ; Formally turn off Player 1.
	sta zPLAYER_ON,X
	beq b_psp_End

b_psp_Squash
	inc zPLAYER_Y,X          ; Y = Y + 1
	lda #PLAYER_SQUASH_Y     ; Subtract from 
	sec                      ; the squash'd Y
	sbc zPLAYER_Y,X          ; giving the number of bytes to write
	sta Psip_Temp_Byte_Count ; save number of bytes to write

	ldy zPLAYER_Y,X          ; Get the adjusted Y
	sty zPLAYER_NEW_Y,X      ; Normalize new == old

	ldx #0
b_psp_LoopCopy               ; Yes.  Grody, messy loop.
	lda PMG_IMG_CANNON,X     ; byte from gun image...
	sta (zPMG_HARDWARE),Y    ; copy to Player/Missile memory
	iny
	cpx Psip_Temp_Byte_Count ; Is X at the limit?
	beq b_psp_End            ; Yes, then we're done.
	inx
	bpl b_psp_LoopCopy       ; Next byte to copy.

b_psp_End
	rts



; ==========================================================================
; MANAGE PLAYERS MOVEMENT
; ==========================================================================
; The main code provided updates to player state for the New Y position.
;
; If the New Y does not match the old Player Y player then update Y.
; Redraw players only if something changed.
;
; Also, main code can flip on Redraw to force a redraw.
; --------------------------------------------------------------------------

Pmg_ManagePlayersMovement

	dec zAnimatePlayers        ; Decrement.   Let Main reset when it reaches 0.

	ldx #0
	jsr Pmg_DeterminePlayerDraw
	
	ldx #1
	jsr Pmg_DeterminePlayerDraw

	lda zPLAYER_ONE_REDRAW
	ora zPLAYER_TWO_REDRAW
	beq b_pmpm_EndPlayerMovement ; Neither one is on by main or flagged by tests.

b_pmpm_RedrawPlayers
	jsr Pmg_Draw_Players ;  This will copy Players' NEW_Y to Y, NEW_X to X

b_pmpm_EndPlayerMovement ; Decide if Lazer or Player sets the HPOS at the start of the frame.
	lda zCurrentEvent    ; Is this 0? 
	beq b_pmpm_Exit      ; Yes.  Should not be here
	cmp #EVENT_GAME      ; Is it game?
	bcc b_pmpm_SetPlayer ; No. So, no lasers.

	lda zLASER_ONE_X     ; Copy laser 1  X to shadow registers.
	sta SHPOSP0          ; Copy laser 1  X to shadow registers.
	lda zLASER_TWO_X     ; Copy laser 2  X to shadow registers.
	sta SHPOSP1          ; Copy laser 2  X to shadow registers.
	jmp b_pmpm_Exit

b_pmpm_SetPlayer         ; In any other case, Guns X position goes to shadow register.
	lda zPLAYER_ONE_X    ; Copy Player 1  X to shadow register
	sta SHPOSP0          ; Copy Player 1  X to shadow register
	lda zPLAYER_TWO_X    ; Copy Player 2  X to shadow register
	sta SHPOSP1          ; Copy Player 2  X to shadow register

b_pmpm_Exit
;	lda #0
;	sta zPLAYER_ONE_REDRAW
;	sta zPLAYER_TWO_REDRAW

	rts


; ==========================================================================
; DETERMINE PLAYER DRAW
; ==========================================================================
; Determine if each player should be redrawn.
;
; X == the player to analyze
; --------------------------------------------------------------------------

Pmg_DeterminePlayerDraw

	lda zPLAYER_REDRAW,X    ; Did Main set this?  
	bne b_pdpd_Exit         ; Yup. No need to check, just assume, go on to next player.

	lda zPLAYER_ON,X        ; Is player On?
	beq b_pdpd_Exit         ; No.  Skip all these considerations. 

	lda zPLAYER_NEW_Y,X     ; Is New Y == Y?
	cmp zPLAYER_Y,X          
	bne b_pdpd_Flag_Redraw  ; No. End the checks and set Flag to redraw.

	lda zPLAYER_NEW_X,X     ; Is New X == X?
	cmp zPLAYER_X,X  
	beq b_pdpd_Exit         ; Yes, Do not flag redraw.

b_pdpd_Flag_Redraw
	inc zPLAYER_REDRAW,X    ; Force redraw.

b_pdpd_Exit
	rts

