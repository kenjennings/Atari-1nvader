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
	; tmemeory map, so we really only need to zero the second 8 bytes.
	
b_pdbm_Zero                ; Zero 8 bytes from position 8 to 15 

	ldx #7                 ; 7, 6, 5 . . . 0

b_pdbm_LoopZero
	sta PLAYERADR2+8,X       ; Zero Player memory
	sta PLAYERADR3+8,X       ; Zero Player memory
	dex
	bpl b_pdbm_LoopZero    ; Loop until X is -1

	rts



; ==========================================================================
; DRAW PLAYERS
; ==========================================================================
; Copy the image bitmaps for the guns to the player Y positions.
; zPLAYER_ONE_Y and zPLAYER_TWO_Y 
;
; If the Player is Off, then copy 8 bytes instead.
; We're cheating a little here.   Usually for a general purpose 
; routine the player should be erased at the old Y, and redrawn 
; at the new Y.  However, in this simple game the player's gun image 
; includes a 0 byte at the start and the end, so when moved one 
; scan line at a time (the only possible movement it can do) a 
; redraw will delete any old image.
;
; Zero the redraw flags.
; Copy the Players' NEW_Y to Y.
; --------------------------------------------------------------------------

Pmg_Draw_Players

	lda zPLAYER_ONE_REDRAW
	beq b_pdp_ProcessPlayer2
	
;	lda #0
;	sta zPLAYER_ONE_REDRAW

	lda zPLAYER_ONE_NEW_X
	sta zPLAYER_ONE_X

	ldx #7
	ldy zPLAYER_ONE_NEW_Y
	sty zPLAYER_ONE_Y
	bne b_pdp_DrawPlayer1

b_pdp_LoopErasePlayer1     ; Erase Player 1
	sta PLAYERADR0,Y
	iny
	dex
	bpl b_pdp_LoopErasePlayer1
	bmi b_pdp_ProcessPlayer2

b_pdp_DrawPlayer1
	ldx #0
b_pdp_LoopDrawPlayer1	
	lda PMG_IMG_CANNON,x
	sta PLAYERADR0,y
	iny
	inx
	cpx #8
	bne b_pdp_LoopDrawPlayer1

b_pdp_ProcessPlayer2
	lda zPLAYER_TWO_REDRAW
	beq b_pdp_Exit
	
;	lda #0
;	sta zPLAYER_TWO_REDRAW

	lda zPLAYER_TWO_NEW_X
	sta zPLAYER_TWO_X

	ldx #7
	ldy zPLAYER_TWO_NEW_Y
	sty zPLAYER_TWO_Y
	bne b_pdp_DrawPlayer2

b_pdp_LoopErasePlayer2   ; Erase Player 2
	sta PLAYERADR1,Y
	iny
	dex
	bpl b_pdp_LoopErasePlayer2
	bmi b_pdp_Exit

b_pdp_DrawPlayer2
	ldx #0
b_pdp_LoopDrawPlayer2
	lda PMG_IMG_CANNON,x
	sta PLAYERADR1,y
	iny
	inx
	cpx #8
	bne b_pdp_LoopDrawPlayer2

b_pdp_Exit
	rts


; ==========================================================================
; DRAW MOTHERSHIP
; ==========================================================================
; Draw the small mothership.   This should only be called when the Y
; value changes.
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
	beq b_pdms_Exit

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

b_pdms_Exit
	lda zMOTHERSHIP_NEW_X  ; And set new X position
	sta zMOTHERSHIP_X
	sta SHPOSP2

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

	jsr showscr

	rts


; ==========================================================================
; COPY OBJECT
; ==========================================================================
; Basically, this is a copying 8 bytes from the image bitmaps into the 
; Player/Missile Memory Map.
;
; This code doesn't even know it is working on a player/missile.  It 
; Simply copies 8 bytes from a source to a destination per a couple 
; zero page pointers.
;
; Erasing prior images is a different exercise done elsewhere.
;
; Y will be used to index/copy from 7 to 0.
;
; Loop unrolled to eliminate 8 bpl
; --------------------------------------------------------------------------

Pmg_Copy_Object

;	ldy #7

;b_pco_Copy
;	lda (zPMG_IMAGE),Y    ; From source
;	sta (zPMG_HARDWARE),Y ; To destination
;	dey
;	lda (zPMG_IMAGE),Y    ; From source
;	sta (zPMG_HARDWARE),Y ; To destination
;	dey
;	lda (zPMG_IMAGE),Y    ; From source
;	sta (zPMG_HARDWARE),Y ; To destination
;	dey
;	lda (zPMG_IMAGE),Y    ; From source
;	sta (zPMG_HARDWARE),Y ; To destination
;	dey
;	lda (zPMG_IMAGE),Y    ; From source
;	sta (zPMG_HARDWARE),Y ; To destination
;	dey
;	lda (zPMG_IMAGE),Y    ; From source
;	sta (zPMG_HARDWARE),Y ; To destination
;	dey
;	lda (zPMG_IMAGE),Y    ; From source
;	sta (zPMG_HARDWARE),Y ; To destination
;	dey
;	lda (zPMG_IMAGE),Y    ; From source
;	sta (zPMG_HARDWARE),Y ; To destination

	rts


; ==========================================================================
; DRAW OBJECT
; ==========================================================================
; Setup the parameters needed to copy 8 bytes of Player/Missile image 
; data to the Player/Missile memeory map.
; 
; X is the  Player/Missile screen object ID.
; 
; Y is the PMG Hardware Page for the displayed object. (See the PMG data file.)
;
; A is the Y location of the object on screen.
; --------------------------------------------------------------------------

Pmg_Draw_Object

;	sta zPMG_HARDWARE         ; The Y position is the memory offset.  How convenient.
;	sty zPMG_HARDWARE+1       ; And supply the high page for the object.

;	ldy zTABLE_PMG_IMG_ID,X   ; Get the image ID for this object. 

;	lda TABLE_LO_PMG_IMAGES,Y ; Get the image address low byte
;	sta zPMG_IMAGE
;	lda TABLE_HI_PMG_IMAGES,Y ; Get the image address high byte
;	sta zPMG_IMAGE+1

;	jsr Pmg_Copy_Object       ; Copy 8 bytes from *zPMG_OBJECT to *zPMG_HARDWARE

	rts



; ==========================================================================
; DRAW
; ==========================================================================
; Given the screen object ID load the register values and call
; the function to setup the parameters needed to copy 8 bytes of 
; image data to the Player/Missile memeory map.
; 
; Load A with the Y coordinate from the NEW_Y value.
;
; Load Y with the PMG Hardware Page for the displayed object.
; 
; Input X is the Player/Missile screen object ID.
; --------------------------------------------------------------------------

Pmg_Draw

;	lda zTABLE_PMG_NEW_Y,X  

;	ldy zTABLE_PMG_HARDWARE,X

;	jsr Pmg_Draw_Object       ; Setup and copy 8 bytes to P/M memory.

	rts


; ==========================================================================
; ZERO OBJECT
; ==========================================================================
; Zero 8 bytes at the location specified by zPMG_HARDWARE
; 
; Y will be used to index/copy from 7 to 0.
;
; Loop unrolled to eliminate 8 bpl
; --------------------------------------------------------------------------

Pmg_Zero_Object

;	ldy #7
;	lda #0

;	sta (zPMG_HARDWARE),Y ; To player/missile memory map
;	dey
;	sta (zPMG_HARDWARE),Y ; To player/missile memory map
;	dey
;	sta (zPMG_HARDWARE),Y ; To player/missile memory map
;	dey
;	sta (zPMG_HARDWARE),Y ; To player/missile memory map
;	dey
;	sta (zPMG_HARDWARE),Y ; To player/missile memory map
;	dey
;	sta (zPMG_HARDWARE),Y ; To player/missile memory map
;	dey
;	sta (zPMG_HARDWARE),Y ; To player/missile memory map
;	dey
;	sta (zPMG_HARDWARE),Y ; To player/missile memory map

	rts


; ==========================================================================
; ERASE OBJECT
; ==========================================================================
; Setup the parameters needed to zero 8 bytes of Player/Missile image 
; data from the Player/Missile memeory map.
;
; X is expepcted to be the screen object ID, but unused here.
;
; A is the Y location of the object on screen.
;
; Y is the Player/Missile hardware address (page).
; --------------------------------------------------------------------------

Pmg_Erase_Object

;	sta zPMG_HARDWARE   ; The Y position is the memory offset.  How convenient.

;	sty zPMG_HARDWARE+1 ; And supply the high page for the object.

;	jsr Pmg_Zero_Object ; Zero the 8 bytes at *zPMG_HARDWARE

	rts


; ==========================================================================
; ERASE
; ==========================================================================
; Given the screen object ID load the register values and call 
; the function to zero the Player/Missile object.
;
; Load A with the Y coordinate from the OLD_Y value.
;
; Load Y with the PMG Hardware Page for the displayed object.
; 
; Input X is the Player/Missile screen object ID.
; --------------------------------------------------------------------------

Pmg_Erase

;	lda zTABLE_PMG_OLD_Y,X  

;	ldy zTABLE_PMG_HARDWARE,X

;	jsr Pmg_Erase_Object ; Zero the 8 bytes at *zPMG_HARDWARE

	rts


; ==========================================================================
; REDRAW
; ==========================================================================
; Given the screen object ID ERASE the object from the OLD_Y 
; position and DRAW it at the NEW_Y psotition.
;
; Horizontal position updates are automatic and handled by DLIs (somewhere.)
;
; Copy NEW_Y to the OLD_Y value.
; Copy NEW_X to the OLD_X value.
; 
; Input X is the Player/Missile screen object ID.
; --------------------------------------------------------------------------

Pmg_Redraw

;	stx zPMG_SAVE_CURRENT_ID ; Need to Save X in case of routines crushing this...
;	jsr Pmg_Erase            ; Zero the 8 bytes of the object from P/M memory.
	
;	ldx zPMG_SAVE_CURRENT_ID ; Get the image ID back.
;	jsr Pmg_Draw             ; Copy the 8 byte image to P/M memory.
	
;	ldx zPMG_SAVE_CURRENT_ID ; Get the image ID back.
;	lda zTABLE_PMG_NEW_Y,X   ; OLD = NEW
;	lda zTABLE_PMG_OLD_Y,X  

;	lda zTABLE_PMG_NEW_X,X   ; OLD = NEW
;	lda zTABLE_PMG_OLD_X,X 

	rts
	
	
	
	
	

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

	jsr Pmg_AllZero  ; get all Players/Missiles off screen, etc.
	
	; clear all bitmap images
;	jsr Pmg_ClearBitmaps
	jsr Pmg_Zero_PM_Memory

;	; Load text labels into P/M memory
;	jsr LoadPMGTextLines

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

	jsr Pmg_SetColors

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

	sta HPOSP0 ; Player positions 0, 1, 2, 3
	sta HPOSP1
	sta HPOSP2
	sta HPOSP3
	sta HPOSM0 ; Missile positions 0, 1, 2, 3
	sta HPOSM1
	sta HPOSM2
	sta HPOSM3

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

Pmg_AllZero

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
;											Pmg_ClearBitmaps  A  X
;==============================================================================
; Zero the bitmaps for all players and missiles
; 
; Try to make this called only once at game initialization.
; All other P/M  use should be orderly and clean up after itself.
; Residual P/M pixels are verboten.
; -----------------------------------------------------------------------------

Pmg_ClearBitmaps

;	lda #$00
;	tax      ; count 0 to 255.

;bCB_Loop
;	sta MISSILEADR,x  ; Missiles
;	sta PLAYERADR0,x  ; Player 0
;	sta PLAYERADR1,x  ; Player 1
;	sta PLAYERADR2,x  ; Player 2
;	sta PLAYERADR3,x  ; Player 3
;	inx
;	bne bCB_Loop      ; Count 1 to 255, then 0 breaks out of loop

	rts


;==============================================================================
;											Pmg_SetColors  A  X
;==============================================================================
; Load the P0-P3 colors based on shape identity.
; 
; X == SHAPE Identify  0 (off), 1, 2, 3...
; -----------------------------------------------------------------------------

Pmg_SetColors

;	txa   ; Object number
;	asl   ; Times 2
;	asl   ; Times 4
;	tax   ; Back into index for referencing from table.

;	lda BASE_PMCOLORS_TABLE,x    ; Get color associated to object                 
;	sta COLPM0_TABLE+2           ; Stuff in the Player color registers.

;	lda BASE_PMCOLORS_TABLE+1,x
;	sta COLPM1_TABLE+2

;	lda BASE_PMCOLORS_TABLE+2,x
;	sta COLPM2_TABLE+2

;	lda BASE_PMCOLORS_TABLE+3,x
;	sta COLPM3_TABLE+2

	rts


; ==========================================================================
; LOAD PMG TEXT LINES                                                 A  X  
; ==========================================================================
; Load the Text labels for the the scores, lives, and saved frogs into 
; the Player/Missile memory.
; --------------------------------------------------------------------------

;PMGLABEL_OFFSET=24

;LoadPmgTextLines

;	ldx #14

;bLPTL_LoadBytes
;	lda P0TEXT_TABLE,x
;	sta PLAYERADR0+PMGLABEL_OFFSET,x
;	
;	lda P1TEXT_TABLE,x
;	sta PLAYERADR1+PMGLABEL_OFFSET,x
;	
;	lda P2TEXT_TABLE,x
;	sta PLAYERADR2+PMGLABEL_OFFSET,x
;	
;	lda P3TEXT_TABLE,x
;	sta PLAYERADR3+PMGLABEL_OFFSET,x
;	
;	lda MTEXT_TABLE,x
;	sta MISSILEADR+PMGLABEL_OFFSET,x

;	dex
;	bpl bLPTL_LoadBytes

;	rts


;==============================================================================
;											Pmg_SetAllZero  A  X
;==============================================================================
; Zero the table entries for the animated object on screen.
;
; -----------------------------------------------------------------------------

Pmg_SetAllZero

	lda #$00            ; 0 position

;	sta COLPM0_TABLE+2
;	sta COLPM1_TABLE+2
;	sta COLPM2_TABLE+2
;	sta COLPM3_TABLE+2
;	
;	sta SIZEP0_TABLE+2
;	sta SIZEP0_TABLE+2
;	sta SIZEP0_TABLE+2
;	sta SIZEP0_TABLE+2
;	sta SIZEM_TABLE+2   ; and Missile size 3, 2, 1, 0
;	
;	sta HPOSP0_TABLE+2
;	sta HPOSP1_TABLE+2
;	sta HPOSP2_TABLE+2
;	sta HPOSP3_TABLE+2
;	
;	sta HPOSM0_TABLE+2
;	sta HPOSM1_TABLE+2
;	sta HPOSM2_TABLE+2
;	sta HPOSM3_TABLE+2

;	lda #[GTIA_MODE_DEFAULT|%0001]
;	sta PRIOR_TABLE+2

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
; CycleIdlePlayer
; ==========================================================================
; One of the Players MAY be offline during the countdown.
; Whichever one it is, strobe the brightness.
; --------------------------------------------------------------------------

Pmg_CycleIdlePlayer

	lda zPLAYER_ONE_ON
	bpl b_pcip_CheckPlayer2 ; Player  on (+1)  Nothing to do.

	inc zPLAYER_ONE_COLOR   ; Player Idle.  Cycle idle color.
	lda zPLAYER_ONE_COLOR
	and #$0F
	sta zPLAYER_ONE_COLOR
	rts                     ; Stop here. Logically, Two can't be off if One is Off.

b_pcip_CheckPlayer2
	lda zPLAYER_TWO_ON
	bpl b_pcip_End          ; Player  on (+1)  Nothing to do.

	inc zPLAYER_TWO_COLOR   ; Player Off.  Cycle idle color.
	lda zPLAYER_TWO_COLOR
	and #$0F
	sta zPLAYER_TWO_COLOR

b_pcip_End
	rts


; ==========================================================================
; SquashIdlePlayer
; ==========================================================================
; While the mothership is leaving squash the idle player, if there is one.
; --------------------------------------------------------------------------

Psip_Temp_Byte_Count .byte 0

Pmg_SquashIdlePlayer

	lda zPLAYER_ONE_ON
	bpl b_psip_CheckPlayer2  ; Player moving (-1) or on (+1)  Nothing to do.

	ldy zPLAYER_ONE_Y        ; Player Off.   
	cpy #PLAYER_SQUASH_Y     ; Did Y position reach the bottom?
	bne b_psip_SquashP1      ; No.  Continue squashing.
	lda #0                   ; Formally turn off Player 1.
	sta zPLAYER_ONE_ON
	beq b_psip_End

b_psip_SquashP1
	inc zPLAYER_ONE_Y        ; Y = Y + 1
	lda #PLAYER_SQUASH_Y     ; Subtract from 
	sec                      ; the squash'd Y
	sbc zPLAYER_ONE_Y        ; giving the number of bytes to write
	sta Psip_Temp_Byte_Count ; save number of bytes to write

	ldy zPLAYER_ONE_Y        ; Get the adjusted Y
	sty zPLAYER_ONE_NEW_Y    ; Normalize new == old
	ldx #0

b_psip_LoopCopy1             ; Yes.  Long, grody, messy loop.
	lda PMG_IMG_CANNON,x     ; Get player image
	sta PLAYERADR0,y         ; Save to Player memory.
	iny
	cpx Psip_Temp_Byte_Count ; Is X at the limit?
	beq b_psip_End           ; Yes, then we're done.
	inx
	bpl b_psip_LoopCopy1     ; Next byte to copy.


b_psip_CheckPlayer2
	lda zPLAYER_TWO_ON
	bpl b_psip_End           ; Player moving (-1) or on (+1)  Nothing to do.

	ldy zPLAYER_TWO_Y        ; Player Off.   
	cpy #PLAYER_SQUASH_Y     ; Did Y position reach the bottom?
	bne b_psip_SquashP2      ; No.  Continue squashing.
	lda #0                   ; Formally turn off Player 2.
	sta zPLAYER_TWO_ON
	beq b_psip_End

b_psip_SquashP2
	inc zPLAYER_TWO_Y        ; Y = Y + 1
	lda #PLAYER_SQUASH_Y     ; Subtract from 
	sec                      ; the squash'd Y
	sbc zPLAYER_TWO_Y        ; giving the number of bytes to write
	sta Psip_Temp_Byte_Count ; save number of bytes to write

	ldy zPLAYER_TWO_Y        ; Get the adjusted Y
	sty zPLAYER_TWO_NEW_Y    ; Normalize new == old
	ldx #0

b_psip_LoopCopy2             ; Yes.  Long, grody, messy loop.
	lda PMG_IMG_CANNON,x     ; Get player image
	sta PLAYERADR1,y         ; Save to Player memory.
	iny
	cpx Psip_Temp_Byte_Count ; Is X at the limit?
	beq b_psip_End           ; Yes, then we're done.
	inx
	bpl b_psip_LoopCopy2     ; Next byte to copy.

b_psip_End
	rts



; ==========================================================================
; MANAGE PLAYER MOVEMENT
; ==========================================================================
; The main code provided updates to player state for the New Y position.
; If the New Y does not match the old Player Y player then update Y.
; Redraw players only if something changed.
; Also, main code can flip on Redraw to force a redraw.
; --------------------------------------------------------------------------

Pmg_ManagePlayerMovement

	lda zPLAYER_ONE_REDRAW     ; Did Main set this?  
	bne b_pmpm_TryPlayer2      ; Yup.   Don't need to check..  Just assume, go on to next player.

	lda zPLAYER_ONE_ON         ; Is player On?
	beq b_pmpm_TryPlayer2      ; No.  Skip all these considerations. 

	lda zPLAYER_ONE_NEW_Y      ; Is New Y == Y?
	cmp zPLAYER_ONE_Y          
	bne b_pmpm_Flag_P1_Redraw  ; No. End the checks and set Flag to redraw.

	lda zPLAYER_ONE_NEW_X      ; Is New X == X?
	cmp zPLAYER_ONE_X  
	beq b_pmpm_TryPlayer2      ; Yes, Do not flag redraw.

b_pmpm_Flag_P1_Redraw
	inc zPLAYER_ONE_REDRAW     ; Force redraw.

; ------------------------------

b_pmpm_TryPlayer2              ; Repeat all the same test for Player 2
	lda zPLAYER_TWO_REDRAW     ; Did Main flag to redraw now?
	bne b_pmpm_TryPlayerRedraw ; Yes.  Skip all other checks, and redraw. 

	lda zPLAYER_TWO_ON         ; Is Player 2 even running?
	beq b_pmpm_TryPlayerRedraw ; Nope. See if redraw is still needed for other player.

	lda zPLAYER_TWO_NEW_Y      ; Is New Y == Y?
	cmp zPLAYER_TWO_Y      
	bne b_pmpm_Flag_P2_Redraw  ; No.  End checks and set Flag to redraw.

	lda zPLAYER_TWO_NEW_X      ; Is New X == X?
	cmp zPLAYER_TWO_X  
	beq b_pmpm_TryPlayerRedraw ; Yes, See if redraw is still needed for other player.

b_pmpm_Flag_P2_Redraw
	inc zPLAYER_TWO_REDRAW     ;  Force redraw.

; ------------------------------

b_pmpm_TryPlayerRedraw
	lda zPLAYER_ONE_REDRAW
	ora zPLAYER_TWO_REDRAW
	beq b_pmpm_EndPlayerMovement ; Neither one is on by main or flagged by tests.

b_pmpm_RedrawPlayers
	jsr Pmg_Draw_Players ;  This will copy Players' NEW_Y to Y, NEW_X to X

b_pmpm_EndPlayerMovement ; Decide if Lazer or Player sets the HPOS at the start of the frame.

	lda zCurrentEvent    ; Is this is 0? 
	beq b_pmpm_Exit      ; No.  Next section
	cmp EVENT_GAME       ; Is it game?
	bcc b_pmpm_SetPlayer ; No. So, no lasers.

	lda zLASER_ONE_X     ; Copy laser X to shadow registers.
	sta SHPOSP0
	lda zLASER_TWO_X
	sta SHPOSP1
	jmp b_pmpm_Exit

b_pmpm_SetPlayer         ; In any other case, Guns X position goes to shadow register.
	lda zPLAYER_ONE_X
	sta SHPOSP0
	lda zLASER_TWO_X
	sta SHPOSP1

b_pmpm_Exit
	lda #0
	sta zPLAYER_ONE_REDRAW
	sta zPLAYER_TWO_REDRAW

	rts


; ==========================================================================
; INDEX MARKS
; ==========================================================================
; Diagnostic help.
; Abuse the Player Missile graphics to put up registration marks every 4th
; scan line to verify positioning of screen graphics.  (Was having a 
; little problem with the Game screen having an extra scan line in the 
; display which dropped the mountains and the stats line down. 
; --------------------------------------------------------------------------

;gPMG_SaveIndexMark .byte $0

Pmg_IndexMarks

;	lda #$AA
;	sta gPMG_SaveIndexMark
	
;	ldy #12

;b_pim_LoopSetIndexMarks
;	lda gPMG_SaveIndexMark
;	sta PLAYERADR0,y
;	sta PLAYERADR1,y
;	sta PLAYERADR2,y
;	sta PLAYERADR3,y

;	EOR #$FF
;	sta gPMG_SaveIndexMark
	
;	tya
;	clc
;	adc #4
;	tay
	
;	cmp #228
;	bne b_pim_LoopSetIndexMarks
	
	rts
	