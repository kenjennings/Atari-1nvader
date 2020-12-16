;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; SCREEN GRAPHICS MEMORY
;
; Display Lists have a 1K boundary.
; ANTIC screen RAM automatic memeory scan has a 4K boundary.
; The sum of everything here is less than 2K, so using 2K alignment 
; should make a safe space, since the Display Lists are declared first.
; --------------------------------------------------------------------------

	.align $0800 ; Align graphics data to 2K boundary.

; ==========================================================================
; Title Screen C64
; --------------------------------------------------------------------------

;    ------------------------------------------
; 00 | 000000          000000          000000 | P1 score, High score, P2 score
; 01 |                                        | 
; 02 |                                        | 
; 03 |                                        | 
; 04 |                   3                    | 3, 2, 1, GO line 
; 05 |                                        | 
; 06 |           1NNNVVVAADDDEEERRR           | Animated Gfx
; 07 |           1NNNVVVAADDDEEERRR           | Animated Gfx
; 08 |           1NNNVVVAADDDEEERRR           | Animated Gfx
; 09 |                                        | 
; 10 |           2019 Darren Foulds           | Credit line
; 11 |                                        | 
; 12 |                  ****                  | Mothership graphic
; 13 |                  ****                  | Mothership graphic
; 14 |                                        | 
; 15 |Scrolling docs and scrolling docs.......| Fine scrolling docs
; 16 |                                        | 
; 17 |                                        | 
; 18 |                                        | 
; 19 |             Mountains                  | Mountains
; 20 |             Mountains                  | Mountains
; 21 |             Mountains                  | Mountains
; 22 |             Mountains                  | Mountains
; 23 |B   Solid ground and bumpers           B| Ground and bumpers, 
; 24 |]]]]]]]]]]]]]]]          [[[[[[[[[[[[[[[| Ground, gun parking area
;    ------------------------------------------


; ==========================================================================
; Game Screen C64
; Alien travels line progression 0 to 21.  22 is end of game.
; --------------------------------------------------------------------------

;    ------------------------------------------
; 00 | 000000          000000          000000 |  P1 score, High score, P2 score
; 01 |                                        | 
; 02 |                                        | 
; 03 |                                        | 
; 04 |                                        | 
; 05 |                                        | 
; 06 |                                        | 
; 07 |                                        | 
; 08 |                                        | 
; 09 |                                        | 
; 10 |                                        | 
; 11 |                                        | 
; 12 |                                        | 
; 13 |                                        | 
; 14 |                                        | 
; 15 |                                        | 
; 16 |                                        | 
; 17 |                                        | 
; 18 |                                        | 
; 19 |             Mountains                  | Mountains
; 20 |             Mountains                  | Mountains
; 21 |             Mountains                  | Mountains
; 22 |             Mountains                  | Mountains
; 23 |B   Solid ground and bumpers           B| Ground and bumpers, guns operational
; 24 |]]]]]]]]]]]]]]]00 0000 00[[[[[[[[[[[[[[[| Ground, stats - line, score value, hits left
;    ------------------------------------------


; ==========================================================================
; Game Over Screen C64
; --------------------------------------------------------------------------

;    ------------------------------------------
; 00 | 000000          000000          000000 |  P1 score, High score, P2 score
; 01 |                                        | 
; 02 |                                        | 
; 03 |                                        | 
; 04 |                                        |  
; 05 |                                        | 
; 06 |                                        | 
; 07 |               GAME  OVER               | Animated Gfx
; 08 |                                        | 
; 09 |                                        | 
; 10 |                                        |  
; 11 |                                        | 
; 12 |                                        |  
; 13 |                                        |  
; 14 |                                        | 
; 15 |                                        |   
; 16 |                                        | 
; 17 |                                        | 
; 18 |                                        | 
; 19 |             Mountains                  | Mountains
; 20 |             Mountains                  | Mountains
; 21 |             Mountains                  | Mountains
; 22 |             Mountains                  | Mountains
; 23 |B   Solid ground and bumpers           B| Ground and bumpers, guns operational
; 24 |]]]]]]]]]]]]]]]00 0000 00[[[[[[[[[[[[[[[| Ground, stats - line, score value, hits left
;    ------------------------------------------


; ==========================================================================
; Display Lists.
;
; ANTIC has a 1K boundary limit for Display Lists.  It has a 4K boundary 
; for screen memory.   There is less than 1K of data below, so if we 
; align to 1K then we know nothing will run over the 1K or the 4K boundary.
; --------------------------------------------------------------------------


; ==========================================================================
; Title Screen Atari
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
; each time, so we can end each display list by a JMP to one
; common ending.

; 55 bytes.

DISPLAY_LIST_TITLE                                          ; System VBI sets color regs, DMACTL.  Custom VBI sets HSCROL, VSCROL, HPOS, PSIZE
	mDL_BLANK DL_BLANK_8                                    ; (000 - 019) Blank scan lines. 8 + 8 + 4 
	mDL_BLANK DL_BLANK_8
	mDL_BLANK DL_BLANK_4

	mDL_LMS   DL_TEXT_2|DL_DLI,GFX_SCORE_LINE               ; 00 (020 - 027) (DLI 0) Narrow screen DMA (2) P1 score, High score, P2 score
	mDL_BLANK DL_BLANK_4                                    ; 01 (028 - 031) Blank 4
	mDL_BLANK DL_BLANK_5                                    ; 01 (032 - 036) Blank 5
	mDL_LMS   DL_TEXT_7,GFX_COUNTDOWN_LINE                  ; 02 (037 - 052) Mode 7 text for 3, 2, 1, GO! Countdown
	mDL_BLANK DL_BLANK_3                                    ; 04 (053 - 055) Blank 3

	mDL_BLANK DL_BLANK_3|DL_DLI                             ;    (056 - 058) (DLI 1) Blank 7   start GTIA $4 in PRIOR 
	mDL_BLANK DL_BLANK_1                                    ;    (059 - 059) Blank 1 Allow time for prior DLI to act. 
	mDL_BLANK DL_BLANK_3|DL_DLI                             ;    (060 - 062) (DLI 2) Blank 3   (DLI vscroll hack next lines) 

DL_LMS_TITLE = [ * + 1 ]                                    ; Get Address of LMS low byte value.    
	mDL_LMS   DL_MAP_F|DL_VSCROLL,GFX_TITLE_FRAME1          ;    (063 - 065)  (Mode F) * 3 Animated Gfx  
	mDL       DL_MAP_F                                      ;    (066 - 068)  (Mode F) * 3 Animated Gfx
	mDL       DL_MAP_F|DL_VSCROLL                           ;    (069 - 071)  (Mode F) * 3 Animated Gfx 
	mDL       DL_MAP_F                                      ;    (072 - 074)  (Mode F) * 3 Animated Gfx
	mDL       DL_MAP_F|DL_VSCROLL                           ;    (075 - 077)  (Mode F) * 3 Animated Gfx 
	mDL       DL_MAP_F                                      ;    (078 - 080)  (Mode F) * 3 Animated Gfx  Turn Off VSCROL hack, reset 

	mDL_BLANK DL_BLANK_7                                    ;    (081 - 090) Blank 7 
	mDL_BLANK [DL_BLANK_3|DL_DLI]                           ;              + Blank 3  (DLI 3) (Hscroll authors, run colors)

DL_LMS_SCROLL_CREDIT1 = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL,GFX_SCROLL_CREDIT1       ; 10 (091 - 098) (6) Author(s) Credit line
	mDL_BLANK [DL_BLANK_1|DL_DLI]                           ;    (099 - 099  Blank1  (DLI 3.2) (Hscroll authors, run colors)
DL_LMS_SCROLL_CREDIT2 = [ * + 1 ]
	mDL_LMS   DL_TEXT_6|DL_HSCROLL,GFX_SCROLL_CREDIT2       ; 10 (100 - 107) (6) Author(s) Credit line

	mDL_BLANK DL_BLANK_8                                    ; 12 (108 - 115) Blank 8 Mothership graphic (PMG)
	mDL_BLANK DL_BLANK_8                                    ; 12 (116 - 123) Blank 8 Mothership graphic (PMG)
	mDL_BLANK DL_BLANK_8                                    ; 13 (124 - 131) Blank 8 Mothership graphic (PMG)
	mDL_BLANK DL_BLANK_8|DL_DLI                             ; 14 (132 - 139) (DLI 4) Blank 8 (Hscroll docs, run colors).

DL_LMS_SCROLL_DOCS = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL,GFX_SCROLL_DOCS          ; 15 (140 - 147) (6) Fine scrolling docs
	mDL_BLANK DL_BLANK_8                                    ; 16 (148 - 155) Blank 8
	mDL_BLANK DL_BLANK_8                                    ; 17 (156 - 163) Blank 8

	mDL_BLANK DL_BLANK_8|DL_DLI                             ; 18 (164 - 171) (DLI 5) Blank 8

BOTTOM_OF_DISPLAY 
DL_LMS_SCROLL_LAND1 = [ * + 1 ]                                  
	mDL_LMS   DL_TEXT_6|DL_HSCROLL|DL_DLI,GFX_MOUNTAINS1    ; 19 (172 - 179) (6) (DLI 5) Fine scrolling mountains to random position.
DL_LMS_SCROLL_LAND2 = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL|DL_DLI,GFX_MOUNTAINS2    ; 20 (180 - 187) (6) (DLI 5) Fine scrolling mountains to random position.
DL_LMS_SCROLL_LAND3 = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL|DL_DLI,GFX_MOUNTAINS3    ; 21 (188 - 195) (6) (DLI 5) Fine scrolling mountains to random position.
DL_LMS_SCROLL_LAND4 = [ * + 1 ]   
	mDL_LMS   DL_TEXT_6|DL_HSCROLL|DL_DLI,GFX_MOUNTAINS4    ; 22 (196 - 203) (6) (DLI 6) Fine scrolling mountains to random position.
	mDL_LMS   DL_TEXT_6,GFX_BUMPERLINE                      ; 23 (204 - 211) (6) (DLI 7) ground and bumpers
	mDL_LMS   DL_TEXT_2,GFX_STATSLINE                       ; 24 (212 - 219) (6) Stats line follows bumper line in memory.

; Note that as long as the system VBI is functioning the address 
; provided for JVB does not matter at all.  The system VBI will update
; ANTIC after this using the address in the shadow registers (SDLST)
	mDL_JVB DISPLAY_LIST_TITLE        ; Restart display.


; ==========================================================================
; Game Screen Atari
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
DISPLAY_LIST_GAMEOVER                                       ; Main Game and Game over are 95% the same.

	mDL_BLANK DL_BLANK_8                                    ;         (000 - 019) Blank scan lines. 8 + 8 + 4 
	mDL_BLANK DL_BLANK_8
	mDL_BLANK DL_BLANK_4   
	mDL_LMS   DL_TEXT_2,GFX_SCORE_LINE                      ; 00      (020 - 027) (2) P1 score, High score, P2 score
DL_LMS_FIRST_STAR = [ * + 2 ]                               ; Remember the first star's LMS address
	.rept 6
		mDL_BLANK [DL_BLANK_1|DL_DLI]                       ; 01 (028 - 028) 
		mDL_LMS   DL_TEXT_6,GFX_STARS_LINE                  ; 01 (029 - 036) (171) (6) Stars
	.endr
															; 02 (037 - 037) 
															; 02 (038 - 045) (171) (6) Stars
															; 03 (046 - 046) 
															; 03 (047 - 054) (171) (6) Stars
															; 04 (055 - 055) 
															; 04 (056 - 063) (171) (6) Stars
															; 05 (064 - 064) 
															; 05 (065 - 072) (171) (6) Stars
															; 06 (073 - 073) 
															; 06 (074 - 081) (171) (6) Stars

DL_LMS_GAME_OVER = [ * + 2 ]                                ; Stars or Game Over Text
	.rept 10
		mDL_BLANK [DL_BLANK_1|DL_DLI]                       ; 07 (082 - 082) 
		mDL_LMS   [DL_TEXT_6],GFX_STARS_LINE                ; 07 (083 - 090) (171) (6) Stars
	.endr
															; 01 - 18 (091 - 091) 
															; 01 - 18 (092 - 099) (171) (6) Stars
															; 01 - 18 (100 - 100) 
															; 01 - 18 (101 - 108) (171) (6) Stars
															; 01 - 18 (109 - 109) 
															; 01 - 18 (110 - 117) (171) (6) Stars
															; 01 - 18 (118 - 118) 
															; 01 - 18 (119 - 126) (171) (6) Stars
															; 01 - 18 (127 - 127) 
															; 01 - 18 (128 - 135) (171) (6) Stars
															; 01 - 18 (136 - 136) 
															; 01 - 18 (137 - 144) (171) (6) Stars
															; 01 - 18 (145 - 145) 
															; 01 - 18 (146 - 153) (171) (6) Stars
															; 01 - 18 (154 - 154) 
															; 01 - 18 (155 - 162) (171) (6) Stars
															; 01 - 18 (163 - 163) 
															; 01 - 18 (164 - 171) (171) (6) Stars


; Note that as long as the system VBI is functioning the address 
; provided for JVB does not matter at all.  The system VBI will update
; ANTIC after this using the address in the shadow registers (SDLST)
	mDL_JMP BOTTOM_OF_DISPLAY                               ; 19 - 24 (172 - 219) End of screen. 


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
; 07 |               GAME  OVER               | (076 - 083) (6) Animated? Gfx
; 08 |                                        | (084 - 091) Blank 8
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

; 63 bytes 

; The Game Over screen is 95% the same as the Game screen.  
; The program will update the LMS for line 7 to read the 
; End Of Game Text at GFX_GAME_OVER_LINE.
; The DLI chain for this line will be updated to point to a different 
; routine that sets HSCROL and runs a color gradient appropriate for 
; thie mode line.

;DISPLAY_LIST_GAMEOVER                                       ; System VBI sets color regs, DMACTL.  Custom VBI sets HSCROL, VSCROL, HPOS, PSIZE
;	mDL_BLANK DL_BLANK_8                                    ;         (000 - 019) Blank scan lines. 8 + 8 + 4 
;	mDL_BLANK DL_BLANK_8
;	mDL_BLANK DL_BLANK_4   
;	mDL_LMS   DL_TEXT_2,GFX_SCORE_LINE                      ; 00      (020 - 027) (2) P1 score, High score, P2 score
;	.rept 6
;		mDL_BLANK DL_BLANK_8                                ; 01 - 06 (028 - 075) Blank 8 * 6
;	.endr
;	mDL_LMS   DL_TEXT_2,GFX_GAME_OVER_LINE                  ; 07      (076 - 083) (6) End of Game Text 
;	.rept 6
;		mDL_BLANK DL_BLANK_8                                ; 08 - 18 (084 - 171) Blank 8 * 6
;	.endr
	
; Note that as long as the system VBI is functioning the address 
; provided for JVB does not matter at all.  The system VBI will update
; ANTIC after this using the address in the shadow registers (SDLST)
;	mDL_JMP BOTTOM_OF_DISPLAY                               ; 19 - 24 (172 - 219) End of screen. 



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
	.sb $00,$01,$02,$03,$04,$05
	.sb "          "
GFX_SCORE_HI 
	.sb $06,$07,$08,$09,$00,$00
	.sb "          "
GFX_SCORE_P2
	.sb $00,$00,$00,$00,$00,$00
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

GFX_TITLE_FRAME1 ; 32 * 6 = 192
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $00 $03 $06 $00 $0C $00 $03 $06 $9C $00 $03 $69 $C3 $0C $36 $90 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $60 $09 $30 $0C $09 $00 $09 $00 $36 $0C $00 $30 $06 $00 $00 $09 $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $06 $09 $0C $00 $60 $0C $09 $09 $00 $06 $09 $0C $30 $06 $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $03 $00 $96 $03 $03 $00 $90 $0C $06 $00 $09 $0C $00 $00 $03 $09 $60 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $00 $03 $06 $C0 $06 $0C $93 $03 $00 $0C $03 $00 $00 $0C $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $09 $00 $0C $09 $00 $03 $00 $06 $0C $09 $63 $06 $9C $36 $09 $00 $03 $00 $00 $00 $00 $00 $00 $00

GFX_TITLE_FRAME2
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $00 $0C $03 $00 $09 $00 $0C $03 $69 $00 $0C $36 $9C $09 $C3 $60 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $30 $06 $C0 $09 $06 $00 $06 $00 $C3 $09 $00 $C0 $03 $00 $00 $06 $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $03 $06 $09 $00 $30 $09 $06 $06 $00 $03 $06 $09 $C0 $03 $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $0C $00 $63 $0C $0C $00 $60 $09 $03 $00 $06 $09 $00 $00 $0C $06 $30 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $00 $0C $03 $90 $03 $09 $6C $0C $00 $09 $0C $00 $00 $09 $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $06 $00 $09 $06 $00 $0C $00 $03 $09 $06 $3C $03 $69 $C3 $06 $00 $0C $00 $00 $00 $00 $00 $00 $00

GFX_TITLE_FRAME3
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $00 $09 $0C $00 $06 $00 $09 $0C $36 $00 $09 $C3 $69 $06 $9C $30 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $C0 $03 $90 $06 $03 $00 $03 $00 $9C $06 $00 $90 $0C $00 $00 $03 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $0C $03 $06 $00 $C0 $06 $03 $03 $00 $0C $03 $06 $90 $0C $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $09 $00 $3C $09 $09 $00 $30 $06 $0C $00 $03 $06 $00 $00 $09 $03 $C0 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $00 $09 $0C $60 $0C $06 $39 $09 $00 $06 $09 $00 $00 $06 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $03 $00 $06 $03 $00 $09 $00 $0C $06 $03 $C9 $0C $36 $9C $03 $00 $09 $00 $00 $00 $00 $00 $00 $00

GFX_TITLE_FRAME4
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $00 $06 $09 $00 $03 $00 $06 $09 $C3 $00 $06 $9C $36 $03 $69 $C0 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $90 $0C $60 $03 $0C $00 $0C $00 $69 $03 $00 $60 $09 $00 $00 $0C $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $09 $0C $03 $00 $90 $03 $0C $0C $00 $09 $0C $03 $60 $09 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $06 $00 $C9 $06 $06 $00 $C0 $03 $09 $00 $0C $03 $00 $00 $06 $0C $90 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $00 $06 $09 $30 $09 $03 $C6 $06 $00 $03 $06 $00 $00 $03 $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $0C $00 $03 $0C $00 $06 $00 $09 $03 $0C $96 $09 $C3 $69 $0C $00 $06 $00 $00 $00 $00 $00 $00 $00


	.align $0100

; Text line for the two major authors, C64, Atari.

GFX_SCROLL_CREDIT1
	.sb "    DARREN FOULDS   "  ; +0, HSCROL 12
	.sb "           "           ; Padding to allow values to leave.
	.sb "   ken jennings     "  ; +30, HSCROL 12

GFX_SCROLL_CREDIT2
	.by $00,$52,$50,$52,$50,$00,$4D ; "2020 -"
	.sb " atari "
	.by $58,$4d                     ; "8-"
	.sb "bits"                      ; +0, HSCROL 12
	.sb "           "               ; Padding to allow values to leave before changing DLI colors.
	.sb "2019 - COMMODORE 64 "      ; +30, HSCROL 12


	.align $0100

; GFX_SCROLL_DOCS on Atari.  
; Declared in gfx.asm aligned in memory to accommodate 
; fine scrolling directly from where it is declared. 

; Scrolling text for the directions, credits, etc.
; Since this is in Mode 6 it only needs 
; 20 blank characters for padding.

GFX_SCROLL_DOCS
scrtxt   
	.sb "                      PRESS FIRE TO PLAY"
	.sb "     FIRE SHOOTS AND CHANGES CANNON DIRECTION "
	.sb "     MORE POINTS WHEN 1NVADER IS HIGH UP"
	.sb "     1NVADER SLOWS DOWN AFTER EIGHTY HITS "
	.sb "     C64 VERSION 2019 - DARREN FOULDS  @DARRENTHEFOULDS "
	.sb "     THX @BEDFORDLVLEXP     HI NATE AND TBONE!"
	.sb "     ATARI VERSION 2020 - KEN JENNINGS HTTPS://GITHUB.COM/KENJENNINGS/ATARI-1NVADER "
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

mountc	; mountain screen view chars
		; Note all values modified -$20 for Atari character codes.
GFX_MOUNTAINS1
	.byte $00,$00 ; Two extra bytes here, so LMS 0/HS 0 will show nothing of the foirst two chars in the buffer.
	.byte $00,$bd,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$bd,$00,$00,$00 
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$bd,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3d,$00

GFX_MOUNTAINS2
	.byte $00,$00 ; Two extra bytes here, so LMS 0/HS 0 will show nothing of the foirst two chars in the buffer.
	.byte $bb,$be,$bc,$7d,$00,$00,$00,$00,$00,$00,$00,$00,$7d,$00,$00,$bb,$be,$bc,$00,$00 
	.byte $00,$00,$00,$00,$00,$7b,$7c,$bb,$be,$bc,$7d,$00,$00,$00,$00,$00,$7d,$bb,$be,$bc

GFX_MOUNTAINS3
	.byte $00,$00 ; Two extra bytes here, so LMS 0/HS 0 will show nothing of the foirst two chars in the buffer.
	.byte $3d,$00,$00,$bc,$7c,$00,$00,$00,$00,$3b,$3c,$7b,$7e,$7c,$bb,$00,$00,$00,$bc,$00 
	.byte $00,$00,$00,$00,$7b,$00,$00,$7c,$00,$7b,$7e,$7c,$00,$00,$00,$7b,$7e,$7c,$00,$3d

GFX_MOUNTAINS4
	.byte $00,$00 ; Two extra bytes here, so LMS 0/HS 0 will show nothing of the foirst two chars in the buffer.
	.byte $3f,$3c,$00,$00,$00,$7c,$00,$00,$3b,$00,$00,$3c,$00,$bb,$00,$00,$00,$00,$00,$bc 
	.byte $00,$00,$00,$7b,$00,$00,$00,$00,$00,$00,$00,$00,$7c,$00,$7b,$00,$00,$00,$3b,$3f


	.align $0100


TABLE_COLOR_AUTHOR1 ; COLPF0 Darren
	.byte COLOR_LITE_BLUE+$8,COLOR_LITE_BLUE+$a,COLOR_LITE_BLUE+$c,COLOR_LITE_BLUE+$e
	.byte COLOR_BLUE2+$2,COLOR_BLUE2+$4,COLOR_BLUE2+$6,COLOR_BLUE2+$8
	
TABLE_COLOR_COMP1 ; COLPF0 Darren
	.byte COLOR_BLUE_GREEN+$8,COLOR_BLUE_GREEN+$a,COLOR_BLUE_GREEN+$c,COLOR_BLUE_GREEN+$e
	.byte COLOR_AQUA+$2,COLOR_AQUA+$4,COLOR_AQUA+$6,COLOR_AQUA+$8

TABLE_COLOR_AUTHOR2 ; COLPF1 Ken
	.byte COLOR_RED_ORANGE+$8,COLOR_RED_ORANGE+$a,COLOR_RED_ORANGE+$c,COLOR_RED_ORANGE+$e
	.byte COLOR_ORANGE2+$2,COLOR_ORANGE2+$4,COLOR_ORANGE2+$6,COLOR_ORANGE2+$8

TABLE_COLOR_COMP2 ; COLPF1 Ken
	.byte COLOR_PURPLE+$8,COLOR_PURPLE+$a,COLOR_PURPLE+$c,COLOR_PURPLE+$e
	.byte COLOR_PINK+$2,COLOR_PINK+$4,COLOR_PINK+$6,COLOR_PINK+$8
	
TABLE_COLOR_DOCS ; COLPF0 Documentation
	.byte COLOR_YELLOW_GREEN+$8,COLOR_YELLOW_GREEN+$a,COLOR_YELLOW_GREEN+$c,COLOR_YELLOW_GREEN+$e
	.byte COLOR_GREEN+$2,COLOR_GREEN+$4,COLOR_GREEN+$6,COLOR_GREEN+$8


TABLE_LAND_COLPF0
	.byte $0e,$0e,$0e,$0e,$0c,$38,$36,$34

TABLE_LAND_COLPF1
	.byte $0E,$0e,$0e,$0c,$d8,$d6,$d4,$d2

TABLE_LAND_COLPF2
	.byte $0E,$0C,$9A,$98,$96,$94,$92,$90


; This is 40 chars, because it won't "move" by LMS changes.
GFX_BUMPERLINE
	.byte $C2,$04,$05,$48,$49,$06,$44,$4b,$5b,$00,$44,$45,$06,$48,$49,$04,$0b,$1b,$46,$C3
	

;TABLE_COLOR_BLINE_BACK
;	.byte $26,$24,$24,$22,$22,$20,$20,$ff

TABLE_COLOR_BLINE_BUMPER
	.byte $72,$76,$7A,$7C,$7A,$76,$72,$ff

;TABLE_COLOR_BLINE_PF0
;	.byte $3c,$3a,$38,$36,$34,$32,$30,$ff

TABLE_COLOR_BLINE_PM0
	.byte $54,$56,$58,$5a,$5c,$5a,$58,$ff

TABLE_COLOR_BLINE_PM1
	.byte $84,$86,$88,$8a,$8c,$8a,$88,$ff


; 24 |]]]]]]]]]]]]]]]00 0000 00[[[[[[[[[[[[[[[| Ground, stats - line, score value, hits left

GFX_STATSLINE  ; "          L:00   PT:0000   H:00         "  ; "L:", "PT:", "H:" Use P/M graphics
	.sb "          "
GFX_STAT_LINE
	.sb $00,$00
	.sb "      "
GFX_STAT_POINTS
	.sb $00,$00,$00,$00
	.sb "      "
GFX_STAT_HITS
	.sb $00,$00
	.sb "          " 

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
	.sb "                    *                        "
	;     ^^==================^^



	.align $0100 ; Align to page will keep all the Game over text in the same page.


; For Game over there is a display line, and then various 
; source lines of text that are copied over the line when 
; the game is over.  

GFX_GAME_OVER_LINE		
	.ds 20
	


