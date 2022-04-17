;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2022 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; COLOR MANAGEMENT 
;
; The color palette on the NTSC Atari is a little diffferent from the 
; PAL system.   Blues and most Greens are similar-ish, but Red on NTSC 
; is shifted to purple.  There seems to be a strong tendency to pink
; on the PAL systems.
;
; Anyway, complaints were filed about the colors on PAL v NTSC.   So, 
; here we maintain the lookup for all color values in the program with 
; master tables for PAL and NTSC for the colors.
;
; On startup the program detects if this is PAL or NTSC, and then 
; copies the correct master table to the lookup table referenced by 
; the program.
;
; Things that do not need to be included here, because there is no 
; difference between NTSC and PAL or otherwise not direct color values:
; - Any colors using black/grey/white values.
; - Anything choosing colors randomly.
; - "Colors" that are are already loaded from another source or table.
; - Obviously, things that are index values and not actual colors.
; --------------------------------------------------------------------------

; ==========================================================================
; SET NTSC OR PAL COLORS
;
; Update the master lookup table for colors per the hardware 
; register indicating NTSC or PAL.  By default the master table 
; has all the NTSC values.  It will be overwritten by the values
; from the PAL table if this is a PAL Atari.
; --------------------------------------------------------------------------

Gfx_SetNTSCorPALColors

	jsr Gfx_SetNTSCorPAL  ; Returns A == PAL or NTSC flag.
	bne b_gsnopc_Exit     ; 1 == NTSC.   Nothing to do.

	tax                   ; 0 == PAL.    Copy from the alternate color tables.

b_gsnopc_CopyLoopPAL
	lda TABLE_PAL_COLORS,x
	sta TABLE_GAME_COLORS,x
	inx
	cpx #[COLOR_TABLE_END-COLOR_TABLE_START]
	bne b_gsnopc_CopyLoopPAL

; HACKERY TO BE REMOVED AFTER DEBUGGING VISUALS 
	ldx #2
b_gnsopc_PromptPAL
	lda PAL_PROMPT,x
	sta GFX_SCORE_HI-6,X
	dex
	bpl b_gnsopc_PromptPAL

b_gsnopc_Exit
	rts

PAL_PROMPT .sb "PAL"


; ==========================================================================
; Some declarations related to the color tables below.
; --------------------------------------------------------------------------

SIZEOF_LASER_COLOR_TABLE=5 ; Look for TABLE_COLOR_LASERS

SIZEOF_EXPLOSION_TABLE=7  ; Actually, size is 8.  7 is the starting index. Look for TABLE_COLOR_EXPLOSION


; These are all on the grey scale, so there is no 
; difference between NTSC and PAL.

; Tagline will change over time.
TABLE_COLOR_TAGLINE_PF0 ; COLPF0 - One button, one life, one alien, blah blah.
	.byte COLOR_GREY+$8
	.byte COLOR_GREY+$a
	.byte COLOR_GREY+$c
	.byte COLOR_GREY+$e
	.byte COLOR_GREY+$4
	.byte COLOR_GREY+$6
	.byte COLOR_GREY+$8
	.byte COLOR_GREY+$a

; Tagline will change over time.
TABLE_COLOR_TAGLINE_PF1 ; COLPF1 - (NO) MERCY
	.byte COLOR_GREY+$8
	.byte COLOR_GREY+$a
	.byte COLOR_GREY+$c
	.byte COLOR_GREY+$e
	.byte COLOR_GREY+$4
	.byte COLOR_GREY+$6
	.byte COLOR_GREY+$8
	.byte COLOR_GREY+$a
	
; Options will not change over time.  Can treat this as MASTER.
TABLE_GREY_MASTER
TABLE_COLOR_OPTS0 ; COLPF0 - Name of Options.
	.byte COLOR_GREY+$8
	.byte COLOR_GREY+$a 
	.byte COLOR_GREY+$c
	.byte COLOR_GREY+$e
	.byte COLOR_GREY+$4
	.byte COLOR_GREY+$6
	.byte COLOR_GREY+$8
	.byte COLOR_GREY+$a


; ==========================================================================
; Master table of colors the game uses.  Declarations for colors moved here.
; By Default, NTSC values.
; --------------------------------------------------------------------------

COLOR_TABLE_START
TABLE_GAME_COLORS

zMOTHERSHIP_COLOR   .byte COLOR_PURPLE+$8 ; Game mothership color. PM2 $58 / PM3 $46  ||  $5E
zMOTHERSHIP_COLOR2  .byte COLOR_PINK+$6   ; Game mothership color. PM2 $48 / PM3 $36  ||  $7E (PAL)


TT_DLI6_Alt_Ground  
	.byte COLOR_ORANGE2+$4  ; ($24) Change COLPF1 to use as alternate ground color.


TABLE_COLOR_AUTHOR1 ; COLPF0 Darren
	.byte COLOR_LITE_BLUE+$8
	.byte COLOR_LITE_BLUE+$a
	.byte COLOR_LITE_BLUE+$c
	.byte COLOR_LITE_BLUE+$e
	.byte COLOR_BLUE2+$4
	.byte COLOR_BLUE2+$6
	.byte COLOR_BLUE2+$8
	.byte COLOR_BLUE2+$a
	
TABLE_COLOR_COMP1 ; COLPF0 Darren
	.byte COLOR_BLUE_GREEN+$8
	.byte COLOR_BLUE_GREEN+$a
	.byte COLOR_BLUE_GREEN+$c
	.byte COLOR_BLUE_GREEN+$e
	.byte COLOR_AQUA+$4
	.byte COLOR_AQUA+$6
	.byte COLOR_AQUA+$8
	.byte COLOR_AQUA+$a

TABLE_COLOR_AUTHOR2 ; COLPF1 Ken
	.byte COLOR_RED_ORANGE+$8
	.byte COLOR_RED_ORANGE+$a
	.byte COLOR_RED_ORANGE+$c
	.byte COLOR_RED_ORANGE+$e
	.byte COLOR_ORANGE2+$4
	.byte COLOR_ORANGE2+$6
	.byte COLOR_ORANGE2+$8
	.byte COLOR_ORANGE2+$a

TABLE_COLOR_COMP2 ; COLPF1 Ken
	.byte COLOR_PURPLE+$8
	.byte COLOR_PURPLE+$a
	.byte COLOR_PURPLE+$c
	.byte COLOR_PURPLE+$e
	.byte COLOR_PINK+$4
	.byte COLOR_PINK+$6
	.byte COLOR_PINK+$8
	.byte COLOR_PINK+$a
	
TABLE_COLOR_DOCS ; COLPF0 Documentation
	.byte COLOR_AQUA+$8
	.byte COLOR_AQUA+$a
	.byte COLOR_AQUA+$c
	.byte COLOR_AQUA+$e
	.byte COLOR_LITE_BLUE+$4
	.byte COLOR_LITE_BLUE+$6
	.byte COLOR_LITE_BLUE+$8
	.byte COLOR_LITE_BLUE+$a

TABLE_COLOR_DOCS2 ; COLPF1 Documentation
	.byte COLOR_LITE_ORANGE+$8
	.byte COLOR_LITE_ORANGE+$a
	.byte COLOR_LITE_ORANGE+$c
	.byte COLOR_LITE_ORANGE+$e
	.byte COLOR_ORANGE1+$4
	.byte COLOR_ORANGE1+$6
	.byte COLOR_ORANGE1+$8
	.byte COLOR_ORANGE1+$a

TABLE_COLOR_OPTS1 ; Green for ON text.
	.byte COLOR_GREEN+$8
	.byte COLOR_GREEN+$a
	.byte COLOR_GREEN+$c
	.byte COLOR_GREEN+$e
	.byte COLOR_GREEN+$4
	.byte COLOR_GREEN+$6
	.byte COLOR_GREEN+$8
	.byte COLOR_GREEN+$a

TABLE_COLOR_OPTS2 ; Red for Off Text.
	.byte COLOR_PINK+$8
	.byte COLOR_PINK+$a
	.byte COLOR_PINK+$c
	.byte COLOR_PINK+$e
	.byte COLOR_PINK+$4
	.byte COLOR_PINK+$6
	.byte COLOR_PINK+$8
	.byte COLOR_PINK+$a

TABLE_LAND_COLPF0 ; Browns
	.byte $0e
	.byte $0e
	.byte $0e
	.byte $0e
	.byte $0c
	.byte $38
	.byte $36
	.byte $34

TABLE_LAND_COLPF1 ; Greens
	.byte $0E
	.byte $0e
	.byte $0e
	.byte $0c
	.byte $d8
	.byte $d6
	.byte $d4
	.byte $d2

TABLE_LAND_COLPF2 ; Blues
	.byte $0E
	.byte $0C
	.byte $9A
	.byte $98
	.byte $96
	.byte $94
	.byte $92
	.byte $90


TABLE_COLOR_BLINE_BUMPER
	.byte $72
	.byte $76
	.byte $7A
	.byte $7C
	.byte $7A
	.byte $76
	.byte $72
;	.byte $ff

TABLE_COLOR_BLINE_PM0
	.byte $54
	.byte $56
	.byte $58
	.byte $5a
	.byte $5c
	.byte $5a
;	.byte $58
;	.byte $ff

TABLE_COLOR_BLINE_PM1
	.byte $94
	.byte $96
	.byte $98
	.byte $9a
	.byte $9c
	.byte $9a
;	.byte $98
;	.byte $ff


TABLE_COLOR_LASERS ; Interleaved, so it can be addressed by  X player index.  0 to 5
	.byte $0F,$0F
	.byte $3E,$6e
	.byte $38,$68
	.byte $32,$62
	.byte $38,$68
	.byte $3e,$6e

TABLE_COLOR_EXPLOSION 
	.byte $00
	.byte $90
	.byte $a2
	.byte $a4
	.byte $a6
	.byte $a8
	.byte $aE
	.byte $0E


TABLE_GAME_OVER_PF0 ; colors for initial blast-in frames in reverse
	.byte $ca
	.byte $cc
	.byte $ce
	.byte $ce
	.byte $0e
	.byte $0e

TABLE_GAME_OVER_PF1 ; colors for next phase in reverse
	.byte $06
	.byte $06
	.byte $06
	.byte $08
	.byte $08
	.byte $c8

TABLE_GAME_OVER_PF2 ; Colors for DLI transition - 16 scan lines for Mode 7 text
	.byte $02,$02,$04,$04,$04,$06,$06,$08,$08,$c6,$c8,$ca,$cc,$cc,$cc,$ce ; 0
	.byte $04,$04,$04,$06,$06,$06,$06,$08,$08,$08,$08,$08,$c6,$c8,$ca,$cC ; 1
	.byte $04,$06,$06,$06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$c6,$c8,$ca ; 2
	.byte $06,$06,$06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$c6,$c8 ; 3
	.byte $06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$c6 ; 4
	.byte $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08 ; 5
	
TABLE_GAME_OVER_PF3 ; Colors for DLI on static text - 16 scan lines for Mode 7 text
	.byte $02,$02,$02,$04,$04,$06,$06,$08,$08,$c6,$c6,$c8,$ca,$ca,$ca,$cc

COLOR_TABLE_END ; Used to calculate size of table in bytes for the copy.



; ==========================================================================
; Static list of all color value for PAL video. 
; --------------------------------------------------------------------------

TABLE_PAL_COLORS

;zMOTHERSHIP_COLOR   
	.byte PAL_COLOR_PURPLE+$8 ; Game mothership color. PM2 $58 / PM3 $46  ||  $5E
;zMOTHERSHIP_COLOR2  
	.byte PAL_COLOR_PINK+$6   ; Game mothership color. PM2 $48 / PM3 $36  ||  $7E (PAL)


;TT_DLI6_Alt_Ground  
	.byte PAL_COLOR_LITE_ORANGE+$4  ; ($24) Change COLPF1 to use as alternate ground color.


;TABLE_COLOR_AUTHOR1 ; COLPF0 Darren
	.byte PAL_COLOR_LITE_BLUE+$8
	.byte PAL_COLOR_LITE_BLUE+$a
	.byte PAL_COLOR_LITE_BLUE+$c
	.byte PAL_COLOR_LITE_BLUE+$e
	.byte PAL_COLOR_BLUE2+$4
	.byte PAL_COLOR_BLUE2+$6
	.byte PAL_COLOR_BLUE2+$8
	.byte PAL_COLOR_BLUE2+$a
	
;TABLE_COLOR_COMP1 ; COLPF0 Darren
	.byte PAL_COLOR_BLUE_GREEN+$8
	.byte PAL_COLOR_BLUE_GREEN+$a
	.byte PAL_COLOR_BLUE_GREEN+$c
	.byte PAL_COLOR_BLUE_GREEN+$e
	.byte PAL_COLOR_AQUA+$4
	.byte PAL_COLOR_AQUA+$6
	.byte PAL_COLOR_AQUA+$8
	.byte PAL_COLOR_AQUA+$a

;TABLE_COLOR_AUTHOR2 ; COLPF1 Ken
	.byte PAL_COLOR_RED_ORANGE+$8
	.byte PAL_COLOR_RED_ORANGE+$a
	.byte PAL_COLOR_RED_ORANGE+$c
	.byte PAL_COLOR_RED_ORANGE+$e
	.byte PAL_COLOR_ORANGE2+$4
	.byte PAL_COLOR_ORANGE2+$6
	.byte PAL_COLOR_ORANGE2+$8
	.byte PAL_COLOR_ORANGE2+$a

;TABLE_COLOR_COMP2 ; COLPF1 Ken
	.byte PAL_COLOR_PURPLE+$8
	.byte PAL_COLOR_PURPLE+$a
	.byte PAL_COLOR_PURPLE+$c
	.byte PAL_COLOR_PURPLE+$e
	.byte PAL_COLOR_PINK+$4
	.byte PAL_COLOR_PINK+$6
	.byte PAL_COLOR_PINK+$8
	.byte PAL_COLOR_PINK+$a
	
;TABLE_COLOR_DOCS ; COLPF0 Documentation
	.byte PAL_COLOR_AQUA+$8
	.byte PAL_COLOR_AQUA+$a
	.byte PAL_COLOR_AQUA+$c
	.byte PAL_COLOR_AQUA+$e
	.byte PAL_COLOR_LITE_BLUE+$4
	.byte PAL_COLOR_LITE_BLUE+$6
	.byte PAL_COLOR_LITE_BLUE+$8
	.byte PAL_COLOR_LITE_BLUE+$a

;TABLE_COLOR_DOCS2 ; COLPF1 Documentation
	.byte PAL_COLOR_LITE_ORANGE+$8
	.byte PAL_COLOR_LITE_ORANGE+$a
	.byte PAL_COLOR_LITE_ORANGE+$c
	.byte PAL_COLOR_LITE_ORANGE+$e
	.byte PAL_COLOR_ORANGE1+$4
	.byte PAL_COLOR_ORANGE1+$6
	.byte PAL_COLOR_ORANGE1+$8
	.byte PAL_COLOR_ORANGE1+$a

;TABLE_COLOR_OPTS1 ; Green for ON text.
	.byte PAL_COLOR_GREEN+$8
	.byte PAL_COLOR_GREEN+$a
	.byte PAL_COLOR_GREEN+$c
	.byte PAL_COLOR_GREEN+$e
	.byte PAL_COLOR_GREEN+$4
	.byte PAL_COLOR_GREEN+$6
	.byte PAL_COLOR_GREEN+$8
	.byte PAL_COLOR_GREEN+$a

;TABLE_COLOR_OPTS2 ; Red for Off Text.
	.byte PAL_COLOR_PINK+$8
	.byte PAL_COLOR_PINK+$a
	.byte PAL_COLOR_PINK+$c
	.byte PAL_COLOR_PINK+$e
	.byte PAL_COLOR_PINK+$4
	.byte PAL_COLOR_PINK+$6
	.byte PAL_COLOR_PINK+$8
	.byte PAL_COLOR_PINK+$a

;TABLE_LAND_COLPF0 ; Browns
	.byte $0e
	.byte $0e
	.byte $0e
	.byte $0e
	.byte $0c
	.byte $18
	.byte $16
	.byte $14

;TABLE_LAND_COLPF1 ; Greens
	.byte $0E
	.byte $0e
	.byte $0e
	.byte $0c
	.byte $b8
	.byte $b6
	.byte $b4
	.byte $b2

;TABLE_LAND_COLPF2 ; Blues
	.byte $0E
	.byte $0C
	.byte $8A
	.byte $88
	.byte $86
	.byte $84
	.byte $82
	.byte $80


;TABLE_COLOR_BLINE_BUMPER
	.byte $62
	.byte $66
	.byte $6A
	.byte $6C
	.byte $6A
	.byte $66
	.byte $62
;	.byte $ff

;TABLE_COLOR_BLINE_PM0
	.byte $44
	.byte $46
	.byte $48
	.byte $4a
	.byte $4c
	.byte $4a
;	.byte $48
;	.byte $ff

;TABLE_COLOR_BLINE_PM1
	.byte $84
	.byte $86
	.byte $88
	.byte $8a
	.byte $8c
	.byte $8a
;	.byte $88
;	.byte $ff


;TABLE_COLOR_LASERS ; Interleaved, so it can be addressed by  X player index.  0 to 5
	.byte $0F
	.byte $0F
	.byte $2E
	.byte $5e
	.byte $28
	.byte $58
	.byte $22
	.byte $52
	.byte $28
	.byte $58
	.byte $2e
	.byte $5e

;TABLE_COLOR_EXPLOSION 
	.byte $00
	.byte $a0
	.byte $a2
	.byte $a4
	.byte $a6
	.byte $a8
	.byte $aE
	.byte $0E


;TABLE_GAME_OVER_PF0 ; colors for initial blast-in frames in reverse
	.byte $ba
	.byte $bc
	.byte $be
	.byte $ce
	.byte $0e
	.byte $0e

;TABLE_GAME_OVER_PF1 ; colors for next phase in reverse
	.byte $06
	.byte $06
	.byte $06
	.byte $08
	.byte $08
	.byte $b8

;TABLE_GAME_OVER_PF2 ; Colors for DLI transition - 16 scan lines for Mode 7 text
	.byte $02,$02,$04,$04,$04,$06,$06,$08,$08,$b6,$b6,$b8,$ba,$bc,$bc,$be ; 0
	.byte $04,$04,$04,$06,$06,$06,$06,$08,$08,$08,$08,$08,$b6,$b8,$ba,$bC ; 1
	.byte $04,$06,$06,$06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$b6,$b8,$ba ; 2
	.byte $06,$06,$06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$b6,$b8 ; 3
	.byte $06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$b6 ; 4
	.byte $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08 ; 5
	
;TABLE_GAME_OVER_PF3 ; Colors for DLI on static text - 16 scan lines for Mode 7 text
	.byte $02
	.byte $02
	.byte $02
	.byte $04
	.byte $04
	.byte $06
	.byte $06
	.byte $08
	.byte $08
	.byte $b6
	.byte $b6
	.byte $b8
	.byte $ba
	.byte $ba
	.byte $bc
	.byte $be

