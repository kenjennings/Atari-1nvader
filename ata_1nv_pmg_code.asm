;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
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
; by two 0 bytes to erase and trailing bytes assuming the image is being
; animated to fly up the screen.
;
; If the Y value is negative, then the image is overwritten with 0 bytes
; starting from the 0th position assuming that the intent is to remove 
; the image from the screen.
; --------------------------------------------------------------------------

Pmg_Draw_Big_Mothership

	lda #0                ; Prep with 0
	ldx #0                ; Copy 8 times.
	ldy zBIG_MOTHERSHIP_Y ; Current Y position
	bmi b_pdbs_Zero       ; If negative, then 0 the image

b_pdbm_LoopDraw
	lda PMG_IMG_BIGGERSHIP_L,X ; Get byte from saved image
	sta PLAYERADR0,Y       ; Write to P/M memory
	iny                    ; One position lower.
    sta PLAYERADR0,Y       ; and write the same image again.
	dey                    ; Move back up to prior line.
	lda PMG_IMG_BIGGERSHIP_R,X ; Get byte from saved image
	sta PLAYERADR1,Y       ; Write to P/M memory
	iny                    ; One position lower.
    sta PLAYERADR1,Y       ; and write the same image again.
	iny                    ; One position lower for the next write.

	inx                    ; next byte
	cpx #8                 
	bne b_pdbm_LoopDraw    ; End after copying 8.

	; End by zeroing the next two bytes to erase a prior image.
	lda #0
	sta PLAYERADR0,Y       ; Write to P/M memory
	sta PLAYERADR1,Y       ; Write to the other P/M memory
	iny
	sta PLAYERADR0,Y       ; Write to P/M memory
	sta PLAYERADR1,Y       ; Write to the other P/M memory
	
	rts
	
	; Useless trivia -- The P/M DMA does not read the first 8 bytes of the
	; tmemeory map, so we really only need to zero the second 8 bytes.
	
b_pdbs_Zero                ; Zero 8 bytes from position 8 to 15 

	ldx #7                 ; 7, 6, 5 . . . 0

b_pdbs_LoopZero
	sta PLAYERADR0,X       ; Zero Player memory
	sta PLAYERADR1,X       ; Zero Player memory
	dex
	bpl b_pdbs_LoopZero    ; Loop until X is -1

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
	lda #[FIFTH_PLAYER|GTIA_MODE_DEFAULT] ; Normal CTIA color interpretation
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





