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
;
; --------------------------------------------------------------------------


; ==========================================================================
; Title Screen Atari -- Draft for planning
; --------------------------------------------------------------------------
;
;    ------------------------------------------ (000 - 019) Blank scan lines. 8+8+4
; 00 | 000000 P1      HI 000000     P2 000000 | (020 - 027) (2) P1 score, High score, P2 score
; 01 |                                        | (028 - 035) Blank 8
; 02 |                                        | (036 - 043) Blank 8
; 03 |                   3                    | (044 - 051) Blank 8   3, 2, 1, GO line animation
; 04 |                   3                    | (052 - 059) Blank 8   3, 2, 1, GO line animation
; 05 |                                        | (060 - 070) Blank 8 + Blank 3  (DLI vscroll hack) 
; 06 |           1NNNVVVAADDDEEERRR           | (071 - 073) (074 - 076) Mode F * 3 Animated Gfx 
; 07 |           1NNNVVVAADDDEEERRR           | (077 - 079) (080 - 082) Mode F * 3 Animated Gfx
; 08 |           1NNNVVVAADDDEEERRR           | (083 - 085) (086 - 088) Mode F * 3 Animated Gfx
; 09 |                                        | (089 - 099) Blank 8 + Blank 3 
; 10 |           2019 Darren Foulds           | (100 - 107) (6) Credit line
; 11 |                                        | (108 - 115) Blank 8
; 12 |                  ****                  | (116 - 123) Blank 8 Mothership graphic (PMG)
; 13 |                  ****                  | (124 - 131) Blank 8 Mothership graphic (PMG)
; 14 |                                        | (132 - 139) Blank 8
; 15 |Scrolling docs and scrolling docs.......| (140 - 147) (6) Fine scrolling docs
; 16 |                                        | (148 - 155) Blank 8
; 17 |                                        | (156 - 163) Blank 8
; 18 |                                        | (164 - 171) Blank 8
; 19 |             Mountains                  | (172 - 179) (6) Mountains
; 20 |             Mountains                  | (180 - 187) (6) Mountains
; 21 |             Mountains                  | (188 - 195) (6) Mountains
; 22 |             Mountains                  | (196 - 203) (6) Mountains
; 23 |B   Solid ground and bumpers           B| (204 - 211) (6) Ground and bumpers, 
; 24 |]]]]]]]]]]]]]]]          [[[[[[[[[[[[[[[| (212 - 219) (2) Ground, stats, gun parking area
;    ------------------------------------------

; The top of the screen (blank lines and score line) is the same on 
; all displays.  In theory, there could be one version of the start
; shared by all diaplays and then a JMP in the Diaply list to the 
; correct version of the screen.  However, this section is a mere 
; 6 bytes long for four instructions.   A JMP would add three more 
; to essentially save a couple bytes.   So, copy/paste the same 
; lines for the top of screen.

; The end of the display is something else.  There are fpur lines
; of text characters for the mountains the ground line for the 
; players, and the stats line under that.  That's 16 bytes each
; each time, so we can end the other display lists by a JMP to 
; this one common ending.
;
; 25 lines * 8 scan lines == 200 scan lines
;
; 200 scan lines + 20 leading blanks == 220 lines defined by display list

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
; Game Screen Atari -- Draft
; --------------------------------------------------------------------------
;
; Alien travels line progression 0 to 21.  22 is end of game.
;
; At any time there are 4 stars on screen.
; Each star lasts 8 frames until it is replaced.
; When the star fades out a new star is added.
; There is one line of data for a star.
; On the Atari this fade out will be a little more animated.
; The star has a little gradient applied where the top and bottom
; sparkle pixels fade out faster than the center line pixels.
; 
; Frame:  Top/Bot:   Middle:  (colors for fading)
;    0      $0E        $0E     1
;    1      $*C        $0E     1
;    2      $*A        $0E     1  2 
;    3      $*8        $*C     1  2  
;    4      $*6        $*A     1  2  3  
;    5      $*4        $*8     1  2  3
;    6      $*2        $*6     1  2  3  4
;    7      $02        $*4     1  2  3  4
;    8 reset to 0.
;   ...     ...        ...
;
; Positioning the stars is different.   Every mode 6 line on the screen for
; the stars refers to (LMS) the same line of screen data.  LMS and horizontal
; fine scrolling will be used to position the stars on the row where they 
; appear.
; The first 21 bytes of data are blank which is used to show no star. 
; That is, LMS=Line+0, and HSCROLL=15.  
; The star character is at position 22 on the line.
; The star will be displayed by varying the horizontal scroll offset 
; and fine-scroll (HSCROL) value.  This allows per pixel positioning,
; but uses the memory for only the one line of text characters. 
; Where a star appears the starting position for the LMS will be 
; random from 2 to 22 (Or LMS+1 to LMS+21).   Do this by choosing a
; random number, then mask it (bitwise AND) with %3F.  The resulting 
; value, 0 to 63, is used as the index to a lookup table to convert it 
; to the value divided by 3.  The zero equivalants (0, 1, 2) will map
; to 4, 11, 1.
; Horizontal fine scrolling will be a random number from 0 to 15. 
;
; The custom VBI will keep track of the four lines showing the stars.
; It will transition the color for each star fading per each frame. 
; When the  transition reaches frame 11, the star is removed from 
; the screen (fade color table lookups = 0, LMS offset = +0 and HSCROL=15).
; A new random line is chosen for the star.  Pick a random number from 
; 0 to 31 (mask random value with binary AND $1F).  
; If greater than 17, then subtract 16. (31 - 16 == 15.   18 - 16 = 2).
; If this row is in use then use the next row and continue incrementing
; until an unused row is found.
; --------------------------------------------------------------------------

;    ------------------------------------------ (000 - 019) Blank scan lines. 8+8+4
; 00 | 000000 P1      HI 000000     P2 000000 | (020 - 027) (2) P1 score, High score, P2 score
; 01 |                                        | (028 - 035) (6) Stars
; 02 |                                        | (036 - 043) (6) Stars
; 03 |                                        | (044 - 051) (6) Stars
; 04 |                                        | (052 - 059) (6) Stars
; 05 |                                        | (060 - 067) (6) Stars
; 06 |                                        | (068 - 075) (6) Stars
; 07 |                                        | (076 - 083) (6) Stars OR Game Over Line
; 08 |                                        | (084 - 091) (6) Stars
; 09 |                                        | (092 - 099) (6) Stars
; 10 |                                        | (100 - 107) (6) Stars
; 11 |                                        | (108 - 115) (6) Stars
; 12 |                                        | (116 - 123) (6) Stars
; 13 |                                        | (124 - 131) (6) Stars
; 14 |                                        | (132 - 139) (6) Stars
; 15 |                                        | (140 - 147) (6) Stars
; 16 |                                        | (148 - 155) (6) Stars
; 17 |                                        | (156 - 163) (6) Stars
; 18 |                                        | (164 - 171) (6) Stars
; 19 |             Mountains                  | (172 - 179) (6) Mountains
; 20 |             Mountains                  | (180 - 187) (6) Mountains
; 21 |             Mountains                  | (188 - 195) (6) Mountains
; 22 |             Mountains                  | (196 - 203) (6) Mountains
; 23 |B   Solid ground and bumpers           B| (204 - 211) (6) Ground and bumpers, guns operational
; 24 |]]]]]]]]]]]]]]]00 0000 00[[[[[[[[[[[[[[[| (212 - 219) (2) Ground, stats - line, score value, hits left
;    ------------------------------------------

; 63 bytes 

DISPLAY_LIST_GAME                                           ; System VBI sets color regs, DMACTL.  Custom VBI sets HSCROL, VSCROL, HPOS, PSIZE

	mDL_BLANK DL_BLANK_8                                    ; (000 - 019) Blank scan lines. 8 + 8 + 4 
	mDL_BLANK DL_BLANK_8|DL_DLI
	mDL_BLANK DL_BLANK_4|DL_DLI                             ; (DLI 0) Gradient scores then end with Narrow screen DMA (2) P1

	mDL_LMS   DL_TEXT_2,GFX_SCORE_LINE                      ; 00      (020 - 027) (2) P1 score, High score, P2 score

; Having problems with DLI running too long... Altirra says that 
; recursive DLI are being triggered.  Not sure why.  There should be 
; at least three full scan lines in the text line after color changes
; complete, are completed.  Adding extra blank lines before stars 
; and after start to make sure the DLI to START the stars does not begin 
; on text mode line 2, and the DLI to begin the scrolling mountains 
; does not begin on the moded 6 line for stars.

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
; Game Over Screen Atari
; --------------------------------------------------------------------------

;    ------------------------------------------ (000 - 019) Blank scan lines. 8+8+4
; 00 | 000000 P1      HI 000000     P2 000000 | (020 - 027) (2) P1 score, High score, P2 score
; 01 |                                        | (028 - 035) Blank 8 
; 02 |                                        | (036 - 043) Blank 8
; 03 |                                        | (044 - 051) Blank 8
; 04 |                                        | (052 - 059) Blank 8
; 05 |                                        | (060 - 067) Blank 8
; 06 |                                        | (068 - 075) Blank 8
; 07 |               GAME  OVER               | (076 - 083) (7) Animated? Gfx
; 08 |               GAME  OVER               | (084 - 091) (7) 
; 09 |                                        | (092 - 099) Blank 8
; 10 |                                        | (100 - 107) Blank 8
; 11 |                                        | (108 - 115) Blank 8
; 12 |                                        | (116 - 123) Blank 8
; 13 |                                        | (124 - 131) Blank 8
; 14 |                                        | (132 - 139) Blank 8
; 15 |                                        | (140 - 147) Blank 8
; 16 |                                        | (148 - 155) Blank 8
; 17 |                                        | (156 - 163) Blank 8
; 18 |                                        | (164 - 171) Blank 8
; 19 |             Mountains                  | (172 - 179) (4) Mountains
; 20 |             Mountains                  | (180 - 187) (4) Mountains
; 21 |             Mountains                  | (188 - 195) (4) Mountains
; 22 |             Mountains                  | (196 - 203) (4) Mountains
; 23 |B   Solid ground and bumpers           B| (204 - 211) (4) Ground and bumpers, guns operational
; 24 |]]]]]]]]]]]]]]]Looooosers[[[[[[[[[[[[[[[| (212 - 219) (2) Looosers.
;    ------------------------------------------


; The Game Over screen is 95% the same as the Game screen.  
; The program will update the LMS for line 7 to read the 
; End Of Game Text at GFX_GAME_OVER_LINE.
; The DLI chain for this line will be updated to point to a different 
; routine that sets HSCROL and runs a color gradient appropriate for 
; thie mode line.

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
; Pixel values 3, 6, 9, 12 are used for the animated pixels.
;
; Since a large part of the left and right side of the title is just 
; blank space the Narrow playfield DMA is used to reduce the memory 
; needed for each line to 32 bytes (instead of 40).
;
; Pixel values are different in each bitmap image to create the 
; illusion of motion.  Rather than being clever, the images are just 
; pre-rendered and the code will just page flip between them by
; changing a pointer in the display list.
;
; ANTIC F is one scan line tall.  To make each line 3 scan lines tall
; a DLI will abuse the vertical fine scroll to make an illegal vertical
; shift.  This method could just have easily made 4 (or more) scan lines
; for each row, but 3 is used, since this is closer to being square on 
; real hardware.
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

; 768 bytes

; Each frame is aligned to a page.  This will make all the low byte
; of addresses the same across each page, and the high byte values 
; will be the same for every line on the same screen.   This will 
; simplify page flipping the graphics as only the high byte will
; need to be updated, and it will be the same update for every 
; line.

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

; The options text will be scrolling on/off the screen so fast, that 
; fine scrolling is not needed.   Coarse scrolling is fine.  Therefore 
; no extra buffer characters are needed.  Just stock 20 character plus
; 20 characters for Mode 6, and 40 + 40 for Mode 2.
;
; Erase:
; 1) Clear buffer at Right position.
; 2) Scroll, ending at right position.
; 3) Clear Left Postion.
; 4) Set at left position.
;
; Running Text:
; 1) Set to Left Postion.
; 2) Copy Text to Right Position.
; 3) Scroll ending at right position.
; 4) Copy Text to Left position.
; 5) Set to Left Position.
; 6) Get/Allow/Process Input.
; 

;	.sb "  OPTION "     ; 10        ; White
;	.sb +$40,"TEXT "    ; 5         ; Green
;	.sb +$80,"HERE  "   ; 6 == 20   ; Red
; --------------------------------------------------------------------------

GFX_OPTION_LEFT   ; END position left == LMS+0
	.sb "                    " ; 20 blanks to allow for OPTION to scroll left to right.
GFX_OPTION_RIGHT  ; Start position == LEFT+40 or RIGHT+0
	.sb "                    " ; 20 blanks to allow for OPTION to scroll left to right.

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
	.sb "REGULAR RESTART     "
GFX_MENU_1_2
	.sb "SHORT RESTART       "
GFX_MENU_1_3
	.sb "LONG RESTART        "
GFX_MENU_1_4
	.sb "NO RESTART          "

GFX_MENU_1_1_TEXT
	.sb +$40,"RESTART@LASER@AT@THE@MIDDLE@OF@SCREEN@@@"
GFX_MENU_1_2_TEXT
	.sb +$40,"RESTART@LASER@NEARER@BOTTOM@OF@SCREEN@@@"
GFX_MENU_1_3_TEXT
	.sb +$40,"RESTART@LASER@NEARER@TOP@OF@SCREEN@@@@@@"
GFX_MENU_1_4_TEXT
	.sb +$40,"NO@RESTART@@@@@@@@@@MUST@PLAY@BETTER@@@@"

 
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
GFX_MENU_6_3 
	.sb "FR1GNORE            " ; guns ignore each other
GFX_MENU_6_2                 
	.sb "FRENEM1ES           " ; Attached to each other
GFX_MENU_6_4 
	.sb "FRE1GHBORS          " ; Separated in center


GFX_MENU_6_1_TEXT
	.sb +$40,"DEFAULT@MODE@@@@@GUNS@BOUNCE@EACH@OTHER@"
GFX_MENU_6_2_TEXT
	.sb +$40,"GUNS@IGNORE@EACH@OTHER@@@@@@@@@@@@@@@@@@"
GFX_MENU_6_3_TEXT
	.sb +$40,"GUNS@ARE@ATTACHED@@@@@@BOTH@CAN@SHOOT@@@"
GFX_MENU_6_4_TEXT
	.sb +$40,"GUNS@ARE@ATTACHED@@@@TAKE@TURNS@SHOOTING"
GFX_MENU_6_5_TEXT
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
; Declared in gfx.asm aligned in memory to accommodate 
; fine scrolling directly from where it is declared. 

; Scrolling text for the directions, credits, etc.
; Since this is in Mode 6 it only needs 
; 20 blank characters for padding.

GFX_SCROLL_DOCS
scrtxt   
	.sb      "                      PRESS"
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
	.sb +$40,"YAUTJA   "
GFX_END_DOCS
	.sb "                      "



; Since Mode 6 characters are twice the width, then only half the 
; screen data is needed.  What to do with the rest....?
; I'd prefer to not remove the data.
;
; I thought about having the background scroll left and right 
; in the opposite direction of the gun a simple parallax.
; But this can only work for single player games.
;
; Last option is just to reposition the background randomly 
; for the start of each game.   Having the credits show the 
; animated title first, and then fade in the rest of the screen 
; provides that transition time needed to randominze the 
; ground position.
;
; The ground position can be LMS offset +0 to +36.
; and horizontal fine scroll any value 0 to 15.
; 
; The bumper line can be a fixed 20 character line while 
; the actual bumpers will be Missiles (Player 5).

; Actual character values of mountains and ground lines...

; " ]              ]           ]         ] "
; "[^\[        ]  [^\       [\[^\]     ][^\"
; "]  \\    [\[^\[   \     [  \ [^\   [^\ ]"
; "_\   \  [  \ [     \   [        \ [   [_"
; "*______________________________________*" <- Bumpers
; "^^^^^^^^^^^^^^^          ^^^^^^^^^^^^^^^"
;
; Ascii art version of mountains to make it 
; a little bit more legible...
;
; " ^              ^           ^         ^ " PF0 white14, grey12 |
; "/T\^        ^  /T\       /\/T\^     ^/T\" PF0 blue10, blue8   | PF1 white14, grey12    |
; "^  \\    /\/T\/   \     /  \ /T\   /T\ ^" PF0 blue6, blue4    | PF1 green8, green6     | PF2 white14, grey12
; "_\   \  /  \ /     \   /        \ /   /_" PF0 grey4, grey2    | PF1 green4, green2     | PF2 tan6, tan4
; 
; Color "map"-ish like for Mode 6's two high bits for color.  0,4,8,C:
;
; " 0              0           0         0 "
; "0004        4  000       440004     4000"
; "8  04    884440   0     4  4 444   444 8"
; "88   4  8  8 0     0   4        4 4   88"


	.align $0100  ; Align to a page, so only low bytes need to be changed for scrolling

	; mountain screen view chars
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
;	.byte $C2,$04,$05,$48,$49,$06,$44,$4b,$5b,$00,$44,$45,$06,$48,$49,$04,$0b,$1b,$46,$C3  ;; original


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


	.align $0100

; The first 21 bytes of data are blank which is used to show no star. 
; That is, LMS=Line+0, and HSCROLL=15.  
; The star character is at position 21 on the line.
; The star will be displayed by varying the horizontal scroll offset 
; and fine-scroll (HSCROL) value.  This allows per pixel positioning,
; but uses the memory for only the one line of text characters. 
; Where a star appears the starting position for the LMS will be 
; random from 1 to 20.
; This can't do code for a real divide by three, since this may occur 
; during the VBI, thus it needs to complete as fast as possible.
; Math will be replaced by a lookup table to quickly convert 0 to
; 63 into the desired range.
; Read a byte from the RANDOM register, then mask it (bitwise AND) 
; with %3F.  
; The resulting value, 0 to 63, is used as the index to a lookup 
; table to convert it. 
; The 21 value equivalent (random number 63) will map to 11
; Horizontal fine scrolling will be a random number from 0 to 15. 

GFX_STARS_LINE
	;    0123456789 123456789 123456789
	;     ^^==================^^
	.sb "                    *    "
GFX_THIS_IS_BLANK ; we need 20 blanks for a moment for the Game Over screen
	.sb "                    "

; For Game over there is a display line, and then various 
; source lines of text that are copied over the line when 
; the game is over.  

GFX_GAME_OVER_LINE
	.ds 20


