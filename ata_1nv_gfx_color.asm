;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
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
; SET NTSC OR PAL
;
; Update the master lookup table for colors per the hardware 
; register indicating NTSC or PAL.  By default the master table 
; has all the NTSC values.  It will be overwritten by the values
; from the PAL table if this is a PAL Atari.
; --------------------------------------------------------------------------

Gfx_SetNTSCorPAL

	ldx #0 

	lda PAL
	and #MASK_NTSCPAL_BITS ; Clear (xxxx000x) = PAL/SECAM, Set (xxxx111x) = NTSC
	bne b_gsnop_Exit

b_gsnop_CopyLoopPAL
	lda TABLE_PAL_COLORS,x
	sta TABLE_GAME_COLORS,x
	inx
	cpx #[END_OF_COLOR_TABLE-TABLE_GAME_COLORS]
	bne b_gsnop_CopyLoopPAL

b_gsnop_Exit
	rts


; ==========================================================================
; Some declarations related to the color tables below.
; --------------------------------------------------------------------------

SIZEOF_LASER_COLOR_TABLE=5 ; Look for TABLE_COLOR_LASERS

SIZEOF_EXPLOSION_TABLE=7  ; Actually, size is 8.  7 is the starting index. Look for TABLE_COLOR_EXPLOSION



; ==========================================================================
; Master table of colors the game uses.  Declarations for colors moved here.
; By Default, NTSC values.
; --------------------------------------------------------------------------

TABLE_GAME_COLORS   

zCountdownColor     
	.byte $04

zSTATS_TEXT_COLOR   
	.byte $08 ; color/luminance of text on stats line.

zMOTHERSHIP_COLOR   
	.byte $46 ; Game mothership color.


TT_DLI6_Alt_Ground  
	.byte [COLOR_ORANGE2|$4]  ; ($24) Change COLPF1 to use as alternate ground color.


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
	.byte COLOR_BLUE_GREEN+$8,COLOR_BLUE_GREEN+$a,COLOR_BLUE_GREEN+$c,COLOR_BLUE_GREEN+$e
	.byte COLOR_AQUA+$4,COLOR_AQUA+$6,COLOR_AQUA+$8,COLOR_AQUA+$a

TABLE_COLOR_AUTHOR2 ; COLPF1 Ken
	.byte COLOR_RED_ORANGE+$8,COLOR_RED_ORANGE+$a,COLOR_RED_ORANGE+$c,COLOR_RED_ORANGE+$e
	.byte COLOR_ORANGE2+$4,COLOR_ORANGE2+$6,COLOR_ORANGE2+$8,COLOR_ORANGE2+$a

TABLE_COLOR_COMP2 ; COLPF1 Ken
	.byte COLOR_PURPLE+$8,COLOR_PURPLE+$a,COLOR_PURPLE+$c,COLOR_PURPLE+$e
	.byte COLOR_PINK+$4,COLOR_PINK+$6,COLOR_PINK+$8,COLOR_PINK+$a
	
TABLE_COLOR_DOCS ; COLPF0 Documentation
	.byte COLOR_YELLOW_GREEN+$8,COLOR_YELLOW_GREEN+$a,COLOR_YELLOW_GREEN+$c,COLOR_YELLOW_GREEN+$e
	.byte COLOR_GREEN+$4,COLOR_GREEN+$6,COLOR_GREEN+$8,COLOR_GREEN+$a


TABLE_LAND_COLPF0
	.byte $0e,$0e,$0e,$0e,$0c,$38,$36,$34

TABLE_LAND_COLPF1
	.byte $0E,$0e,$0e,$0c,$d8,$d6,$d4,$d2

TABLE_LAND_COLPF2
	.byte $0E,$0C,$9A,$98,$96,$94,$92,$90


TABLE_COLOR_BLINE_BUMPER
	.byte $72,$76,$7A,$7C,$7A,$76,$72,$ff

TABLE_COLOR_BLINE_PM0
	.byte $54,$56,$58,$5a,$5c,$5a,$58,$ff

TABLE_COLOR_BLINE_PM1
	.byte $84,$86,$88,$8a,$8c,$8a,$88,$ff


TABLE_COLOR_LASERS ; Interleaved, so it can be addressed by  X player index.  0 to 5
	.byte $0F,$0F,$3E,$6e,$38,$68,$32,$62,$38,$68,$3e,$6e

TABLE_COLOR_EXPLOSION 
	.byte $00,$90,$92,$94,$96,$98,$9E,$0E


TABLE_GAME_OVER_PF0 ; colors for initial blast-in frames in reverse
	.byte $ca,$cc,$ce,$ce,$0e,$0e

TABLE_GAME_OVER_PF1 ; colors for next phase in reverse
	.byte $06,$06,$06,$08,$08,$c8

TABLE_GAME_OVER_PF2 ; Colors for DLI transition - 16 scan lines for Mode 7 text
	.byte $02,$02,$04,$04,$04,$06,$06,$08,$08,$c6,$c8,$ca,$cc,$cc,$cc,$ce ; 0
	.byte $04,$04,$04,$06,$06,$06,$06,$08,$08,$08,$08,$08,$c6,$c8,$ca,$cC ; 1
	.byte $04,$06,$06,$06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$c6,$c8,$ca ; 2
	.byte $06,$06,$06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$c6,$c8 ; 3
	.byte $06,$06,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$c6 ; 4
	.byte $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08 ; 5
	
TABLE_GAME_OVER_PF3 ; Colors for DLI on static text - 16 scan lines for Mode 7 text
	.byte $02,$02,$02,$04,$04,$06,$06,$08,$08,$c6,$c6,$c8,$ca,$ca,$ca,$cc

END_OF_COLOR_TABLE ; Used to calculate size of table in bytes for the copy.



; ==========================================================================
; Static list of all color value for PAL video. 
; --------------------------------------------------------------------------

TABLE_PAL_COLORS

;zCountdownColor     
	.byte $04

;zSTATS_TEXT_COLOR   
	.byte $08 ; color/luminance of text on stats line.

;zMOTHERSHIP_COLOR   
	.byte $26 ; Game mothership color.

;TT_DLI6_Alt_Ground  
	.byte [COLOR_ORANGE1|$4]  ; ($24) Change COLPF1 to use as alternate ground color.


;TABLE_COLOR_AUTHOR1 ; COLPF0 Darren
	.byte COLOR_BLUE2+$8
	.byte COLOR_BLUE2+$a
	.byte COLOR_BLUE2+$c
	.byte COLOR_BLUE2+$e
	.byte COLOR_BLUE1+$4
	.byte COLOR_BLUE1+$6
	.byte COLOR_BLUE1+$8
	.byte COLOR_BLUE1+$a
	
;TABLE_COLOR_COMP1 ; COLPF0 Darren
	.byte COLOR_AQUA+$8
	.byte COLOR_AQUA+$a
	.byte COLOR_AQUA+$c
	.byte COLOR_AQUA+$e
	.byte COLOR_LITE_BLUE+$4
	.byte COLOR_LITE_BLUE+$6
	.byte COLOR_LITE_BLUE+$8
	.byte COLOR_LITE_BLUE+$a

;TABLE_COLOR_AUTHOR2 ; COLPF1 Ken
	.byte COLOR_ORANGE1+$8
	.byte COLOR_ORANGE1+$a
	.byte COLOR_ORANGE1+$c
	.byte COLOR_ORANGE1+$e
	.byte COLOR_ORANGE_GREEN+$4
	.byte COLOR_ORANGE_GREEN+$6
	.byte COLOR_ORANGE_GREEN+$8
	.byte COLOR_ORANGE_GREEN+$a

;TABLE_COLOR_COMP2 ; COLPF1 Ken
	.byte COLOR_PINK+$8
	.byte COLOR_PINK+$a
	.byte COLOR_PINK+$c
	.byte COLOR_PINK+$e
	.byte COLOR_ORANGE2+$4
	.byte COLOR_ORANGE2+$6
	.byte COLOR_ORANGE2+$8
	.byte COLOR_ORANGE2+$a
	
;TABLE_COLOR_DOCS ; COLPF0 Documentation
	.byte COLOR_GREEN+$8
	.byte COLOR_GREEN+$a
	.byte COLOR_GREEN+$c
	.byte COLOR_GREEN+$e
	.byte COLOR_AQUA+$4
	.byte COLOR_AQUA+$6
	.byte COLOR_AQUA+$8
	.byte COLOR_AQUA+$a


;TABLE_LAND_COLPF0
	.byte $0e
	.byte $0e
	.byte $0e
	.byte $0e
	.byte $0c
	.byte $e8
	.byte $e6
	.byte $e4

;TABLE_LAND_COLPF1
	.byte $0E
	.byte $0e
	.byte $0e
	.byte $0c
	.byte $b8
	.byte $b6
	.byte $b4
	.byte $b2

;TABLE_LAND_COLPF2
	.byte $0E
	.byte $0C
	.byte $8A
	.byte $88
	.byte $86
	.byte $84
	.byte $82
	.byte $80


;TABLE_COLOR_BLINE_BUMPER
	.byte $72
	.byte $76
	.byte $7A
	.byte $7C
	.byte $7A
	.byte $76
	.byte $72
	.byte $ff

;TABLE_COLOR_BLINE_PM0
	.byte $54
	.byte $56
	.byte $58
	.byte $5a
	.byte $5c
	.byte $5a
	.byte $58
	.byte $ff

;TABLE_COLOR_BLINE_PM1
	.byte $94
	.byte $96
	.byte $98
	.byte $9a
	.byte $9c
	.byte $9a
	.byte $98
	.byte $ff


;TABLE_COLOR_LASERS ; Interleaved, so it can be addressed by  X player index.  0 to 5
	.byte $0F
	.byte $0F
	.byte $dE
	.byte $4e
	.byte $d8
	.byte $48
	.byte $d2
	.byte $42
	.byte $d8
	.byte $48
	.byte $de
	.byte $4e

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

