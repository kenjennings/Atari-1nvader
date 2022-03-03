;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2021 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; SCREEN GRAPHICS MEMORY
;
; Display Lists have a 1K boundary.
; ANTIC screen RAM automatic memory scan has a 4K boundary.
; The sum of everything here is less than 2K, so using 2K alignment 
; should make a safe space, since the Display Lists are declared first.
; --------------------------------------------------------------------------

	.align $0800 ; Align graphics data to 2K boundary.

; ==========================================================================
; Display Lists.
; --------------------------------------------------------------------------

DISPLAY_LIST_TITLE                                          ; System VBI sets color regs, DMACTL.  Custom VBI sets HSCROL, VSCROL, HPOS, PSIZE
	mDL_BLANK DL_BLANK_8                                    ; (000 - 019) Blank scan lines. 8 + 8 + 4 
	mDL_BLANK DL_BLANK_8|DL_DLI
	mDL_BLANK DL_BLANK_4|DL_DLI                             ; (DLI 0) Gradient scores then end with Narrow screen DMA (2) P1

	mDL_LMS   DL_TEXT_2,GFX_SCORE_LINE                      ; 00 (020 - 027) score, High score, P2 score
	
	mDL_BLANK DL_BLANK_5                                    ; 01 (028 - 032) Blank 5
	mDL_LMS   DL_TEXT_7,GFX_COUNTDOWN_LINE                  ; 02 (033 - 048) Mode 7 text for 3, 2, 1, GO! Countdown
	mDL_BLANK DL_BLANK_3|DL_DLI                             ;    (049 - 051) (DLI 1) Blank 3   start GTIA $4 in PRIOR
	mDL_BLANK DL_BLANK_2|DL_DLI                             ;    (052 - 053) (DLI 2) Blank 2   (DLI2 logo color 1) 

DL_LMS_TITLE1 = [ * + 2 ]                                   ; Get addresss of LMS high byte values.    
DL_LMS_TITLE2 = [ * + 5 ] 
DL_LMS_TITLE3 = [ * + 8 ] 
	mDL_LMS   DL_MAP_F,GFX_TITLE_FRAME1                     ;    (054 - 054)  (Mode F) * 3 Animated Gfx  GFX_TITLE_FRAME1, line 1
	mDL_LMS   DL_MAP_F,GFX_TITLE_FRAME1                     ;    (055 - 055)  (Mode F) * 3 Animated Gfx  
	mDL_LMS   DL_MAP_F|DL_DLI,GFX_TITLE_FRAME1              ;    (056 - 056)  (Mode F) * 3 Animated Gfx  (DLI2 logo color 2)   

DL_LMS_TITLE4 = [ * + 3 ] 
DL_LMS_TITLE5 = [ * + 6 ] 
	mDL       DL_MAP_F                                      ;    (057 - 057)  (Mode F) * 3 Animated Gfx  GFX_TITLE_FRAME1, line 2
	mDL_LMS   DL_MAP_F,GFX_TITLE_FRAME1+32                  ;    (058 - 058)  (Mode F) * 3 Animated Gfx 
	mDL_LMS   DL_MAP_F|DL_DLI,GFX_TITLE_FRAME1+32           ;    (059 - 059)  (Mode F) * 3 Animated Gfx  (DLI2 logo color 3) 

DL_LMS_TITLE6 = [ * + 3 ] 
DL_LMS_TITLE7 = [ * + 6 ] 
	mDL       DL_MAP_F                                      ;    (060 - 060)  (Mode F) * 3 Animated Gfx  GFX_TITLE_FRAME1, line 3
	mDL_LMS   DL_MAP_F,GFX_TITLE_FRAME1+64                  ;    (061 - 061)  (Mode F) * 3 Animated Gfx  
	mDL_LMS   DL_MAP_F|DL_DLI,GFX_TITLE_FRAME1+64           ;    (062 - 062)  (Mode F) * 3 Animated Gfx  (DLI2 logo color 4) 

DL_LMS_TITLE8 = [ * + 3 ] 
DL_LMS_TITLE9 = [ * + 6 ] 
	mDL       DL_MAP_F                                      ;    (063 - 063)  (Mode F) * 3 Animated Gfx  GFX_TITLE_FRAME1, line 4
	mDL_LMS   DL_MAP_F,GFX_TITLE_FRAME1+96                  ;    (064 - 064)  (Mode F) * 3 Animated Gfx  
	mDL_LMS   DL_MAP_F|DL_DLI,GFX_TITLE_FRAME1+96           ;    (065 - 065)  (Mode F) * 3 Animated Gfx  (DLI2 logo color 5) 

DL_LMS_TITLE10 = [ * + 3 ] 
DL_LMS_TITLE11 = [ * + 6 ] 
	mDL       DL_MAP_F                                      ;    (066 - 066)  (Mode F) * 3 Animated Gfx  GFX_TITLE_FRAME1, line 5
	mDL_LMS   DL_MAP_F,GFX_TITLE_FRAME1+128                 ;    (067 - 067)  (Mode F) * 3 Animated Gfx  
	mDL_LMS   DL_MAP_F|DL_DLI,GFX_TITLE_FRAME1+128          ;    (068 - 068)  (Mode F) * 3 Animated Gfx  (DLI2 logo color 6) 

DL_LMS_TITLE12 = [ * + 3 ] 
DL_LMS_TITLE13 = [ * + 6 ] 
	mDL       DL_MAP_F                                      ;    (069 - 069)  (Mode F) * 3 Animated Gfx  GFX_TITLE_FRAME1, line 6
	mDL_LMS   DL_MAP_F,GFX_TITLE_FRAME1+160                 ;    (070 - 070)  (Mode F) * 3 Animated Gfx  
	mDL_LMS   DL_MAP_F|DL_DLI,GFX_TITLE_FRAME1+160          ;    (071 - 071)  (Mode F) * 3 Animated Gfx  (DLI 2.5 - screen DMA/normal GTIA)

	mDL_BLANK DL_BLANK_2|DL_DLI                             ;    (072 - 073) Blank 2   (DLI 2.7 -- Tag Line gradient.)
DL_LMS_TAG_TEXT = [ * + 1 ]
	mDL_LMS   DL_TEXT_6,GFX_TAG_TEXT                        ; 09 (074 - 081) (6) Tag Line
	mDL_BLANK [DL_BLANK_5|DL_DLI]                           ;    (082 - 086) Blank 5  (DLI 3) (Hscroll authors, run colors)

DL_LMS_SCROLL_CREDIT1 = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL,GFX_SCROLL_CREDIT1       ; 10 (087 - 094) (6) Author(s) Credit line
	mDL_BLANK [DL_BLANK_1|DL_DLI]                           ;    (095 - 095)  Blank 1 (DLI 3.2) (Hscroll system, run colors)
DL_LMS_SCROLL_CREDIT2 = [ * + 1 ]
	mDL_LMS   DL_TEXT_6|DL_HSCROLL,GFX_SCROLL_CREDIT2       ; 10 (096 - 103) (6) System(s) Credit line

	mDL_BLANK DL_BLANK_8                                    ; 11 (104 - 111) Blank 8 Mothership graphic (PMG)
	mDL_BLANK DL_BLANK_8                                    ; 12 (112 - 119) Blank 8 Mothership graphic (PMG)
	mDL_BLANK DL_BLANK_8                                    ; 13 (120 - 127) Blank 8 Mothership graphic (PMG)
	mDL_BLANK DL_BLANK_8|DL_DLI                             ; 14 (128 - 135) Blank 8 (DLI 4)  (Hscroll docs, run colors).

DL_LMS_SCROLL_DOCS = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL,GFX_SCROLL_DOCS          ; 15 (136 - 143) (6) Fine scrolling docs

	mDL_BLANK DL_BLANK_4|DL_DLI                             ; 16 (144 - 147) Blank 4 (DLI 4.5 -- COLPF0/1/2 options) and options docs.
DL_LMS_OPTION = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6,GFX_OPTION_LEFT                     ; 17 (148 - 155) (6) Options name
DL_LMS_OPTION_TEXT= [ * + 1 ]  
	mDL_LMS   DL_TEXT_2,GFX_OPTION_TEXT_LEFT                ; 18 (156 - 163) (2) Options documentation
	mDL_BLANK DL_BLANK_1                                    ; 16 (164 - 164) Blank 1


; ==========================================================================


BOTTOM_OF_DISPLAY  ; (165 - 219)

	mDL_BLANK DL_BLANK_7|DL_DLI                             ; 18 (165 - 171) (DLI 5) Blank 7

DL_LMS_SCROLL_LAND1 = [ * + 1 ]                                  
	mDL_LMS   DL_TEXT_6|DL_HSCROLL|DL_DLI,GFX_MOUNTAINS1    ; 19 (172 - 179) (6) (DLI 5) Fine scrolling mountains
DL_LMS_SCROLL_LAND2 = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL|DL_DLI,GFX_MOUNTAINS2    ; 20 (180 - 187) (6) (DLI 5) Fine scrolling mountains 
DL_LMS_SCROLL_LAND3 = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL|DL_DLI,GFX_MOUNTAINS3    ; 21 (188 - 195) (6) (DLI 5) Fine scrolling mountains 
DL_LMS_SCROLL_LAND4 = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL|DL_DLI,GFX_MOUNTAINS4    ; 22 (196 - 203) (6) (DLI 6) Fine scrolling mountains
	mDL_LMS   DL_TEXT_6,GFX_BUMPERLINE                      ; 23 (204 - 211) (6) (DLI 7) ground and bumpers
	mDL_LMS   DL_TEXT_2,GFX_STATSLINE                       ; 24 (212 - 219) (6) Stats line follows bumper line in memory.

; Note that as long as the system VBI is functioning the address 
; provided for JVB does not matter at all.  The system VBI will update
; ANTIC after this using the address in the shadow registers (SDLST)

DISPLAY_LIST_DO_NOTHING
	mDL_JVB DISPLAY_LIST_TITLE        ; Restart display.

; ==========================================================================


DISPLAY_LIST_GAME                                           ; System VBI sets color regs, DMACTL.  Custom VBI sets HSCROL, VSCROL, HPOS, PSIZE

	mDL_BLANK DL_BLANK_8                                    ; (000 - 019) Blank scan lines. 8 + 8 + 4 
	mDL_BLANK DL_BLANK_8|DL_DLI
	mDL_BLANK DL_BLANK_4|DL_DLI                             ; (DLI 0) Gradient scores then end with Narrow screen DMA (2) P1

	mDL_LMS   DL_TEXT_2,GFX_SCORE_LINE                      ; 00      (020 - 027) (2) P1 score, High score, P2 score

	mDL_BLANK [DL_BLANK_2|DL_DLI]                           ; 00      (028 - 028) (DLI 1) for star line 

;	mDL_BLANK [DL_BLANK_1|DL_DLI]                           ; 00      (028 - 028) (DLI 1) for star line that fol;ows.  HSCROL + COLPF0

DL_LMS_FIRST_STAR = [ * + 1 ]                               ; Remember the first star's LMS address
	.rept 14
		mDL_LMS   [DL_TEXT_6|DL_HSCROLL],GFX_STARS_LINE+3   ; 01 - 14 (029 - 140) (171) (6) Stars   14 * 8 = 112
		mDL_BLANK [DL_BLANK_1|DL_DLI]                       ; 01 - 14 (141 - 154)                   14 * 1 =  14
	.endr

	mDL_LMS [DL_TEXT_6|DL_HSCROLL],GFX_STARS_LINE+5         ; 15      (155 - 162) (171) (6) Stars   
;	mDL_BLANK DL_BLANK_1                                    ; 16      (163 - 164) Blank 2

	mDL_JMP BOTTOM_OF_DISPLAY                               ; -- - 24  (165 - 219) End of screen. 



; ==========================================================================




DISPLAY_LIST_GAMEOVER                                       ; System VBI sets color regs, DMACTL.  Custom VBI sets HSCROL, VSCROL, HPOS, PSIZE

	mDL_BLANK DL_BLANK_8                                    ; (000 - 019) Blank scan lines. 8 + 8 + 4 
	mDL_BLANK DL_BLANK_8|DL_DLI
	mDL_BLANK DL_BLANK_4|DL_DLI                             ; (DLI 0) Gradient scores then end with Narrow screen DMA (2) P1

	mDL_LMS   DL_TEXT_2,GFX_SCORE_LINE                      ; 00      (020 - 027) (2) P1 score, High score, P2 score

	mDL_BLANK [DL_BLANK_2|DL_DLI]                           ; DLI to set COLPF0, COLPF1

;	mDL_BLANK [DL_BLANK_1|DL_DLI]                           ; DLI to set COLPF0, COLPF1

	.rept 6
		mDL_BLANK DL_BLANK_8                                ; -- (028 - 075) Blank Lines  (-) 6 * 8 == 48 blanks.
	.endr
	mDL_BLANK [DL_BLANK_6|DL_DLI]                           ; -- (076 - 081)  - DLI loops 16 scan lines for COLPF2, COLPF3

DL_LMS_GAME_OVER = [ * + 1 ]                                ; Game Over Text line
	mDL_LMS   DL_TEXT_7,GFX_GAME_OVER_LINE                  ; 07 (082 - 089) (172) 
	mDL_BLANK DL_BLANK_2                                    ; -- (090 - 091) 

	.rept 6
		mDL_BLANK DL_BLANK_8                                ; -- (092 - 139) Blank Lines  (-) 6 * 8 == 48 blanks.
	.endr
	mDL_BLANK DL_BLANK_7                                    ; -- (140 - 145) 

	mDL_BLANK DL_BLANK_7                                    ; -- (163 - 170) 
  
;	mDL_BLANK DL_BLANK_8                                    ; -- (163 - 170) 

	mDL_JMP BOTTOM_OF_DISPLAY                               ; 19 - 24 (172 - 219) End of screen. 



; ==========================================================================
; SCREEN MEMORY
; --------------------------------------------------------------------------

; 16 bytes (narrow screen width) for Countdown text

GFX_COUNTDOWN_LINE
	.sb "      "
GFX_COUNTDOWN  ; The first 4 chars here are for countdown "3..." , , "!GO!"
	.sb "          " 


; 40 bytes

GFX_SCORE_LINE ; | 000000 P1      HI 000000     P2 000000 | 
	.sb " "
GFX_SCORE_P1 
	.sb $0,$0,$0,$0,$0,$0
	.sb "          "
GFX_SCORE_HI 
	.sb $0,$0,$0,$0,$0,$0
	.sb "          "
GFX_SCORE_P2
	.sb $0,$0,$0,$0,$0,$0
	.sb " "


; Title graphics are ANTIC F+GTIA $4 (aka BASIC mode 9, 16-grey scale) 
; with a Player 5 (the missile) used as color overlay.
;
; 36 pixels title image.   
; Narrow width screen 64 pixels - 36 image pixels = 28 pixels padding needed.  
; 28 padding pixels / 2 = 14 pixels on left and right.
; 14 padding pixels / 2 = 7 bytes $00 padding on left and right.

	; ...............X.X...X.X...X...X.XXX...XXXXX.XXXX...............
	; ..............X..XX..X.X...X..XX.X..X..X.....X...X..............
	; ...............X.X.X.X.X..X..X.X.X...X.X.XX..X...X..............
	; ...............X.X..XX.X.X..X..X.X...X.X.....X.XX...............
	; ...............X.X...X.XX..X.XXX.X...X.X.....X...X..............
	; ...............X.X...X.X...X...X.X.XXX.XXXXX.X...X..............

; 768 bytes   ; Each frame is aligned to a page.

	.align $0100

GFX_TITLE_FRAME1 ; 32 * 6 = 192
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $00 $03 $06 $00 $0C $00 $03 $06 $9C $00 $03 $69 $C3 $0C $36 $90 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $60 $09 $30 $0C $09 $00 $09 $00 $36 $0C $00 $30 $06 $00 $00 $09 $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $06 $09 $0C $00 $60 $0C $09 $09 $00 $06 $09 $0C $30 $06 $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $03 $00 $96 $03 $03 $00 $90 $0C $06 $00 $09 $0C $00 $00 $03 $09 $60 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $00 $03 $06 $C0 $06 $0C $93 $03 $00 $0C $03 $00 $00 $0C $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $09 $00 $0C $09 $00 $03 $00 $06 $0C $09 $63 $06 $9C $36 $09 $00 $03 $00 $00 $00 $00 $00 $00 $00

	.align $0100

GFX_TITLE_FRAME2
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $00 $0C $03 $00 $09 $00 $0C $03 $69 $00 $0C $36 $9C $09 $C3 $60 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $30 $06 $C0 $09 $06 $00 $06 $00 $C3 $09 $00 $C0 $03 $00 $00 $06 $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $03 $06 $09 $00 $30 $09 $06 $06 $00 $03 $06 $09 $C0 $03 $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $0C $00 $63 $0C $0C $00 $60 $09 $03 $00 $06 $09 $00 $00 $0C $06 $30 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $00 $0C $03 $90 $03 $09 $6C $0C $00 $09 $0C $00 $00 $09 $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $06 $00 $09 $06 $00 $0C $00 $03 $09 $06 $3C $03 $69 $C3 $06 $00 $0C $00 $00 $00 $00 $00 $00 $00

	.align $0100

GFX_TITLE_FRAME3
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $00 $09 $0C $00 $06 $00 $09 $0C $36 $00 $09 $C3 $69 $06 $9C $30 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $C0 $03 $90 $06 $03 $00 $03 $00 $9C $06 $00 $90 $0C $00 $00 $03 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $0C $03 $06 $00 $C0 $06 $03 $03 $00 $0C $03 $06 $90 $0C $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $09 $00 $3C $09 $09 $00 $30 $06 $0C $00 $03 $06 $00 $00 $09 $03 $C0 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $00 $09 $0C $60 $0C $06 $39 $09 $00 $06 $09 $00 $00 $06 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $03 $00 $06 $03 $00 $09 $00 $0C $06 $03 $C9 $0C $36 $9C $03 $00 $09 $00 $00 $00 $00 $00 $00 $00

	.align $0100

GFX_TITLE_FRAME4
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $00 $06 $09 $00 $03 $00 $06 $09 $C3 $00 $06 $9C $36 $03 $69 $C0 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $90 $0C $60 $03 $0C $00 $0C $00 $69 $03 $00 $60 $09 $00 $00 $0C $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $09 $0C $03 $00 $90 $03 $0C $0C $00 $09 $0C $03 $60 $09 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $06 $00 $C9 $06 $06 $00 $C0 $03 $09 $00 $0C $03 $00 $00 $06 $0C $90 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $00 $06 $09 $30 $09 $03 $C6 $06 $00 $03 $06 $00 $00 $03 $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $0C $00 $03 $0C $00 $06 $00 $09 $03 $0C $96 $09 $C3 $69 $0C $00 $06 $00 $00 $00 $00 $00 $00 $00


	.align $0100

GFX_TAG_TEXT ; Displayed using Narrow DMA.  (16 * 4 == 64)   [51 + 51 + 64 == 166]
	.sb "   ONE BUTTON   "
	.sb "   ONE  ALIEN   "
	.sb "    ONE LIFE    "
	.sb "    NO "
	.sb +$40,"MERCY    "


; Text line for the two major authors, C64, Atari.

GFX_SCROLL_CREDIT1 ; 20 + 11 + 20 == 51 
	.sb "    DARREN FOULDS   "  ; +0, HSCROL 12
	.sb "           "           ; Padding to allow values to leave.
	.sb "   ken jennings     "  ; +30, HSCROL 12

GFX_SCROLL_CREDIT2; 20 + 11 + 20 == 51
	.by $00,$52,$50,$52,$51,$00,$4D ; "2021 -"
	.sb " atari "
	.by $58,$4d                     ; "8-"
	.sb "bits"                      ; +0, HSCROL 12
	.sb "           "               ; Padding to allow values to leave before changing DLI colors.
	.sb "2019 - COMMODORE 64 "      ; +30, HSCROL 12


	.align $0100


; --------------------------------------------------------------------------
; OPTION key menu text.
; Press OPTION to show choices.
; Press SELECT to choose.
;
;	.sb "  OPTION "     ; 10        ; White
;	.sb +$40,"TEXT "    ; 5         ; Green
;	.sb +$80,"HERE  "   ; 6 == 20   ; Red
; --------------------------------------------------------------------------

GFX_OPTION_LEFT                         ; END position left == LMS+0
	.sb "                    "          ; 20 blanks to allow for OPTION to scroll left to right.
GFX_OPTION_LEFT_OO = GFX_OPTION_LEFT+17 ; On/Off text at the end of this string.
GFX_LEFT_OO_OFFSET = 17

GFX_OPTION_RIGHT                          ; Start position == LEFT+40 or RIGHT+0
	.sb "                    "            ; 20 blanks to allow for OPTION to scroll left to right.
GFX_OPTION_RIGHT_OO = GFX_OPTION_RIGHT+17 ; On/Off text at the end of this string.
GFX_RIGHT_OO_OFFSET = 37

	; Note the spaces below are @ signs due to the +$40 needed to print 
	; screen bytes using the Mode 2 versions of characters.
GFX_OPTION_TEXT_LEFT
	.sb +$40,"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" ; 40 for left side.
GFX_OPTION_TEXT_RIGHT
	.sb +$40,"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" ; another 40 blanks to allow the description to scroll right to left


	.align $0100


GFX_OPTION_1                 ; OPTION MENUS
	.sb "LASER RESTART MENU  "
GFX_OPTION_2
	.sb "LASER SPEED MENU    "
GFX_OPTION_3
	.sb "1NVADER STARTUP MENU"
GFX_OPTION_4
	.sb "1NVADER SPEEDUP MENU"
GFX_OPTION_5
	.sb "1NVADER SPEED MENU  "
GFX_OPTION_6
	.sb "TWO PLAYER MENU     "
GFX_OPTION_7
	.sb "OTHER STUFF MENU    "

GFX_OPTION_1_TEXT
	.sb +$40,"SET@THE@HEIGHT@THE@LASER@CAN@RESTART@@@@"
GFX_OPTION_2_TEXT
	.sb +$40,"SET@THE@SPEED@OF@THE@LASER@SHOTS@@@@@@@@"
GFX_OPTION_3_TEXT
	.sb +$40,"SET@THE@START@SPEED@FOR@THE@1NVADER@@@@@"
GFX_OPTION_4_TEXT
	.sb +$40,"SET@THE@NUMBER@OF@HITS@FOR@SPEEDUP@@@@@@"
GFX_OPTION_5_TEXT
	.sb +$40,"SET@THE@MAX@SPEED@OF@1NVADER@@@@@@@@@@@@"
GFX_OPTION_6_TEXT
	.sb +$40,"CHOOSE@THE@TWO@PLAYER@GAME@MODE@@@@@@@@@"
GFX_OPTION_7_TEXT
	.sb +$40,"MISCELLANEOUS@OTHER@THINGS@@@@@@@@@@@@@@" 


GFX_MENU_1_1                 ; SELECT Laser Restart Menu
	.sb "MID AUTO SHOT       "
GFX_MENU_1_2
	.sb "SHORT AUTO SHOT     "
GFX_MENU_1_3
	.sb "FAR AUTO SHOT       "
GFX_MENU_1_4
	.sb "MID SHOT            "
GFX_MENU_1_5
	.sb "SHORT SHOT          "
GFX_MENU_1_6
	.sb "FAR SHOT            "

GFX_MENU_1_1_TEXT
	.sb +$40,"AUTO@RESTART@LASER@HALF@WAY@UP@SCREEN@@@"
GFX_MENU_1_2_TEXT
	.sb +$40,"AUTO@RESTART@LASER@NEAR@BOTTOM@OF@SCREEN"
GFX_MENU_1_3_TEXT
	.sb +$40,"AUTO@RESTART@LASER@NEAR@TOP@OF@SCREEN@@@"
GFX_MENU_1_4_TEXT
	.sb +$40,"MUST@RELEASE@BUTTON@TO@RESTART@LASER@@@@"
GFX_MENU_1_5_TEXT
	.sb +$40,"MUST@RELEASE@BUTTON@TO@RESTART@LASER@@@@"
GFX_MENU_1_6_TEXT
	.sb +$40,"MUST@RELEASE@BUTTON@TO@RESTART@LASER@@@@"
 
GFX_MENU_2_1                 ; SELECT Laser Speed Menu
	.sb "REGULAR LASERS      "
GFX_MENU_2_2 
	.sb "FAST LASERS         "
GFX_MENU_2_3 
	.sb "SLOW LASERS         "

GFX_MENU_2_1_TEXT
	.sb +$40,"THE@NORMAL@DEFAULT@SPEED@FOR@LASERS@@@@@"
GFX_MENU_2_2_TEXT
	.sb +$40,"FASTER@LASERS@MAY@NOT@HELP@SO@MUCH@@@@@@"
GFX_MENU_2_3_TEXT
	.sb +$40,"PAINFULLY@SLOW@LASERS@@@@@@@@@@@@@@@@@@@"


GFX_MENU_3_1                 ; SELECT 1NVADER Startup Menu
	.sb "REGULAR START 1     "
GFX_MENU_3_2 
	.sb "START AT 3          "
GFX_MENU_3_3 
	.sb "START AT 5          "
GFX_MENU_3_4 
	.sb "START AT 7          "
GFX_MENU_3_5 
	.sb "START AT MAX        "

GFX_MENU_3_1_TEXT
	.sb +$40,"NORMAL@DEFAULT@1NVADER@START@SPEED@@@@@@"
GFX_MENU_3_2_TEXT
	.sb +$40,"1NVADER@STARTS@AT@SPEED@3@@@@@@@@@@@@@@@"
GFX_MENU_3_3_TEXT
	.sb +$40,"1NVADER@STARTS@AT@SPEED@5@@@@@@@@@@@@@@@"
GFX_MENU_3_4_TEXT
	.sb +$40,"1NVADER@STARTS@AT@SPEED@7@@@@@@@@@@@@@@@"
GFX_MENU_3_5_TEXT
	.sb +$40,"1NVADER@AT@MAXIMUM@SPEED@LIKE@A@BOSS@@@@"


GFX_MENU_4_1                 ; SELECT 1NVADER Speedup Menu
	.sb "EVERY 10 HITS       "
GFX_MENU_4_2
	.sb "EVERY 7 HITS        "
GFX_MENU_4_3
	.sb "EVERY 5 HITS        "
GFX_MENU_4_4
	.sb "EVERY 3 HITS        "
GFX_MENU_4_5
	.sb "EVERY 10,9,8...     "
GFX_MENU_4_6
	.sb "NO SPEEDUP          "

GFX_MENU_4_1_TEXT
	.sb +$40,"DEFAULT@"
	.byte GAME_HYPHEN_CHAR
	.sb +$40,"@SPEEDUP@EVERY@TEN@HITS@@@@@@@@"
GFX_MENU_4_2_TEXT
	.sb +$40,"SPEED@UP@EVERY@SEVEN@HITS@@@@@@@@@@@@@@@"
GFX_MENU_4_3_TEXT
	.sb +$40,"SPEED@UP@EVERY@FIVE@HITS@@@@@@@@@@@@@@@@"
GFX_MENU_4_4_TEXT
	.sb +$40,"SPEED@UP@EVERY@THREE@HITS@@@@@@@@@@@@@@@"
GFX_MENU_4_5_TEXT
	.sb +$40,"PROGRESSIVELY@FEWER@SHOTS@PER@INCRMENT@@"
GFX_MENU_4_6_TEXT
	.sb +$40,"REMAIN@AT@STARTUP@SPEED@@@@@@@@@@@@@@@@@"


GFX_MENU_5_1                 ; SELECT 1NVADER Max Speed Menu
	.sb "1NVADER SPEED 1     "
GFX_MENU_5_2               
	.sb "1NVADER SPEED 3     "
GFX_MENU_5_3               
	.sb "1NVADER SPEED 5     "
GFX_MENU_5_4               
	.sb "MAXIMUM SPEED       "

GFX_MENU_5_1_TEXT
	.sb +$40,"SLOWEST@MAXIMUM@SPEED@@@@@@@@@@@@@@@@@@@"
GFX_MENU_5_2_TEXT
	.sb +$40,"SPEEDUP@TO@THREE@@@@@@@@@@@@@@@@@@@@@@@@"
GFX_MENU_5_3_TEXT
	.sb +$40,"SPEEDUP@TO@FIVE@@@@@@@@@@@@@@@@@@@@@@@@@"
GFX_MENU_5_4_TEXT
	.sb +$40,"UP@TO@MAXIMUM@SPEED@@@@@@@@@@@@@@@@@@@@@"


GFX_MENU_6_1                   ; SELECT Two Player Modes Menu
	.sb "FR1GULAR            " ; guns bounce
GFX_MENU_6_2 
	.sb "FR1GNORE            " ; guns ignore each other
GFX_MENU_6_3                 
	.sb "FRENEM1ES           " ; Attached to each other
GFX_MENU_6_4 
	.sb "FRE1GHBORS          " ; Separated in center

GFX_MENU_6_1_TEXT
	.sb +$40,"GUNS@BOUNCE@OFF@EACH@OTHER@@@@@@@@@@@@@@"
GFX_MENU_6_2_TEXT
	.sb +$40,"GUNS@IGNORE@EACH@OTHER@@@@@@@@@@@@@@@@@@"
GFX_MENU_6_3_TEXT
	.sb +$40,"GUNS@ARE@ATTACHED@TO@EACH@OTHER@@@@@@@@@"
GFX_MENU_6_4_TEXT
	.sb +$40,"STAY@IN@YOUR@OWN@YARD@AND@OFF@MY@LAWN@@@"


GFX_MENU_7_1                   ; SELECT Other things Menu
	.sb "ONES1ES             " ; 2P - Take turns shooting
GFX_MENU_7_2 
	.sb "RESET ALL           " ; Return all game value to default
GFX_MENU_7_3 
	.sb "CHEAT MODE          " ; Alien never reaches bottom.

GFX_MENU_7_1_TEXT
	.sb +$40,"TWO@PLAYERS@TAKE@TURNS@SHOOTING@@@@@@@@@"
GFX_MENU_7_2_TEXT
	.sb +$40,"RESTORE@ALL@SETTINGS@TO@DEFAULTS@@@@@@@@"
GFX_MENU_7_3_TEXT
	.sb +$40,"ALIEN@NEVER@REACHES@BOTTOM@@@@@@U@R@LAME"



	.align $0100


; GFX_SCROLL_DOCS on Atari.  

GFX_SCROLL_DOCS
scrtxt   
	.sb      "                     "
	.sb      " PRESS"
	.sb +$40," FIRE"
	.sb      " TO PLAY      "
	.sb      " PRESS"
	.sb +$40," OPTION"
	.sb      ","
	.sb +$40," SELECT"
	.sb      ", "
	.sb +$40,"START"
	.sb      " TO CHOOSE GAME MODES AND OPTIONS   "
	.sb +$40,"     FIRE"
	.sb      " SHOOTS AND CHANGES CANNON DIRECTION "
	.sb +$40,"     MORE POINTS WHEN 1NVADER IS HIGH UP  "
	.sb      "     1NVADER SLOWS DOWN AFTER EIGHTY HITS "
	.sb +$40,"     C64 VERSION 2019 - "
	.sb      "DARREN FOULDS "
	.sb +$40," @DARRENTHEFOULDS "
	.sb      "     THX @BEDFORDLVLEXP     "
	.sb +$40,"HI NATE AND TBONE!"
	.sb      "     ATARI VERSION 2021 - "
	.sb +$40,"KEN JENNINGS "
	.sb      "HTTPS://GITHUB.COM/KENJENNINGS/ATARI-1NVADER "
	.sb +$40,"     THANKS TO ATARI PLAYTESTERS: "
	.sb      "VINYLLA, "
	.sb +$40,"PHILSAN, "
	.sb      "LEVEL42, "
	.sb +$40,"YAUTJA         "
	.sb      "TRY THE ATARI 10-LINER 1NVADER BY VICTOR PARADA - "
	.sb +$40,"VITOCO"
	.sb      " - WWW.VITOCO.CL  "
GFX_END_DOCS
	.sb "                      "


	.align $0100  ; Align to a page, so only low bytes need to be changed for scrolling


; Mountain backdrop in the bottom rows.
; Note all values modified -$20 for Atari character codes.

GFX_MOUNTAINS1
	.byte $00,$00 ; Two extra bytes here, so LMS 0/HS 0 will show nothing of the first two chars in the buffer.
	.byte $00,$bd,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$bd,$00,$00,$00 
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$bd,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3d,$00

GFX_MOUNTAINS2
	.byte $00,$00 ; Two extra bytes here, so LMS 0/HS 0 will show nothing of the first two chars in the buffer.
	.byte $bb,$be,$bc,$7d,$00,$00,$00,$00,$00,$00,$00,$00,$7d,$00,$00,$bb,$be,$bc,$00,$00 
	.byte $00,$00,$00,$00,$00,$7b,$7c,$bb,$be,$bc,$7d,$00,$00,$00,$00,$00,$7d,$bb,$be,$bc

GFX_MOUNTAINS3
	.byte $00,$00 ; Two extra bytes here, so LMS 0/HS 0 will show nothing of the first two chars in the buffer.
	.byte $3d,$00,$00,$bc,$7c,$00,$00,$00,$00,$3b,$3c,$7b,$7e,$7c,$bb,$00,$00,$00,$bc,$00 
	.byte $00,$00,$00,$00,$7b,$00,$00,$7c,$00,$7b,$7e,$7c,$00,$00,$00,$7b,$7e,$7c,$00,$3d

GFX_MOUNTAINS4
	.byte $00,$00 ; Two extra bytes here, so LMS 0/HS 0 will show nothing of the first two chars in the buffer.
	.byte $3f,$3c,$00,$00,$00,$7c,$00,$00,$3b,$00,$00,$3c,$00,$bb,$00,$00,$00,$00,$00,$bc 
	.byte $00,$00,$00,$7b,$00,$00,$00,$00,$00,$00,$00,$00,$7c,$00,$7b,$00,$00,$00,$3b,$3f



; This is 20 chars, because it won't "move" by LMS changes.
; Two Zero Bytes in center are for the bumper characters during FREIGHBORS mode.
GFX_BUMPERLINE
	.byte $C2,$04,$05,$48,$49,$06,$44,$4b,$5b,$00,$00,$44,$45,$48,$49,$04,$0b,$1b,$46,$C3
;	.byte $C2,$04,$05,$48,$49,$06,$44,$4b,$5b,$00,$44,$45,$06,$48,$49,$04,$0b,$1b,$46,$C3 ;; original

GFX_MIDBUMPERS=GFX_BUMPERLINE+9  ; For FREIGNBORS mode - stay in your own yard


; 24 |]]]]]]]]]]]]]]]00 0000 00[[[[[[[[[[[[[[[| Ground, stats - line, score value, hits left

GFX_STATSLINE  ; "          L:00   PT:0000   H:00         "  ; "L:", "PT:", "H:" Use P/M graphics?
	.sb "          "
GFX_STAT_ROW
	.sb $0,$0
	.sb "      "
GFX_STAT_POINTS
	.sb $0,$0,$0,$0
	.sb "      "
GFX_STAT_HITS
	.sb $0,$0
	.sb "          " 


; FLASHING STARS ON GAME SCREEN =================================================

	.align $0100

GFX_STARS_LINE
	;    0123456789 123456789 123456789
	;     ^^==================^^
	.sb "                    "
GFX_STAR_DISPLAYED
	.sb "*    "
GFX_THIS_IS_BLANK ; we need 20 blanks for a moment for the Game Over screen
	.sb "                    "

GFX_STAR_CHAR
	.sb "*"
GFX_CHEATER_CHARS
	.sb "CHEATER"
	.by 0 ; the current index into the CHEATER_CHARS string.


; For Game over there is a display line, and then various 
; source lines of text that are copied over the line when 
; the game is over.  

GFX_GAME_OVER_LINE
	.ds 20

