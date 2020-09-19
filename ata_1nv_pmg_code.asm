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
	lda PMG_BIGGERSHIP_L,X ; Get byte from saved image
	sta PLAYERADR0,Y       ; Write to P/M memory
	iny                    ; One position lower.
    sta PLAYERADR0,Y       ; and write the same image again.
	dey                    ; Move back up to prior line.
	lda PMG_BIGGERSHIP_R,X ; Get byte from saved image
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
; --------------------------------------------------------------------------

Pmg_Copy_Object

	ldy #7
	
b_pdc_Copy	
	lda (zPMG_OBJECT),Y   ; From source
	sta (zPMG_HARDWARE),Y ; To destination
	dey
	bpl b_pdc_Copy        ; Copy until negative
	
	rts


; ==========================================================================
; DRAW OBJECT
; ==========================================================================
; Setup the parameters needed to copy 8 bytes of Player/Missile image 
; data to the Player/Missile memeory map.
; 
; X is the ID of the image. 
; 
; Y is the Player/Missile hardware ID.  (See the PMG data file.).
;
; A is the Y location of the object on screen.
; --------------------------------------------------------------------------

Pmg_Draw_Object

	sta zPMG_HARDWARE   ; The Y position is the memory offset.  How convenient.
	
	lda TABLE_HI_PMG,Y
	sta zPMG_HARDWARE+1 ; And supply the high page for the object.
	
	lda TABLE_LO_PMG_OBJECTS,X ;
	sta zPMG_OBJECT            ; 
	lda TABLE_HI_PMG_OBJECTS,X ; 
	sta zPMG_OBJECT+1          ;

	jsr Pmg_Copy_Object
	
	rts
	