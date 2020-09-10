;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; SCREEN GRAPHICS 
;
; Animate Title Logo
; --------------------------------------------------------------------------

; ==========================================================================
; ANIMATE TITLE LOGO
; ==========================================================================
; Change SCREEN GRAPHICS 
;
; Animate Title Logo
; --------------------------------------------------------------------------

TABLE_GFX_TITLE_LOGO        ; Stored in reverse order for less iteration code.
	.byte <GFX_TITLE_FRAME5
	.byte <GFX_TITLE_FRAME4
	.byte <GFX_TITLE_FRAME3	
	.byte <GFX_TITLE_FRAME2
	.byte <GFX_TITLE_FRAME1

Gfx_Animate_Title_Logo

	dec TITLE_LOGO_FRAME         ; Subtract frame counter.
	bpl b_gatl_SkipReset         ; If it did not go negative, then it is good.
	
	ldx #TITLE_LOGO_FRAME_MAX    ; Reset frame counter 
	stx TITLE_LOGO_FRAME         ; to max value.
	
b_gatl_SkipReset
	ldx TITLE_LOGO_FRAME         ; Actually read the value to use as index.
	lda TABLE_GFX_TITLE_LOGO,X   ; Get the new graphics address low byte
	sta DL_LMS_TITLE             ; and update the display list LMS.
	
	rts
	
	
	