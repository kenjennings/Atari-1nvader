; ==========================================================================
; Screen Graphics
; --------------------------------------------------------------------------

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
; ANTIC has a 1K boundary limit for Display Lists.  We do not need to align
; to 1K, because display lists are ordinarily short, and several will 
; easily fit in one page of memory.  So, the code can make due with 
; aligning to a page.  If they all stay in the page then they can't cross
; a 1K boundary.
; --------------------------------------------------------------------------

	.align $0100


; ==========================================================================
; Title Screen Atari
; --------------------------------------------------------------------------
;
;    ------------------------------------------ (000 - 019) Blank scan lines. 8+8+4
; 00 | 000000 P1      HI 000000     P2 000000 | (020 - 027) (2) P1 score, High score, P2 score
; 01 |                                        | (028 - 035) Blank 8
; 02 |                                        | (036 - 043) Blank 8
; 03 |                   3                    | (044 - 051) (6) 3, 2, 1, GO line animation
; 04 |                   3                    | (052 - 059) (6) 3, 2, 1, GO line animation
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
; 24 |]]]]]]]]]]]]]]]          [[[[[[[[[[[[[[[| (212 - 219) (2) Ground, gun parking area
;    ------------------------------------------

DISPLAY_LIST_TITLE
	.byte DL_BLANK_8, DL_BLANK_8, DL_BLANK_4|DL_DLI 

BOTTOM_OF_DISPLAY                                 ; Prior to this DLI SPC1 set colors and HSCROL
	mDL_LMS DL_TEXT_2,ANYBUTTON_MEM               ; (190-197) (+0 to +7)   Prompt to start game.
	.by DL_BLANK_1|DL_DLI                         ; (198)     (+8)         DLI SPC2, set COLBK/COLPF2/COLPF1 for scrolling text.
DL_SCROLLING_CREDIT
SCROLL_CREDIT_LMS = [* + 1]
	mDL_LMS DL_TEXT_2|DL_HSCROLL,SCROLLING_CREDIT ; (199-206) (+9 to +16)  The perpetrators identified
; Note that as long as the system VBI is functioning the address 
; provided for JVB does not matter at all.  The system VBI will update
; ANTIC after this using the address in the shadow registers (SDLST)
	mDL_JVB TITLE_DISPLAYLIST        ; Restart display.


; ==========================================================================
; Game Screen Atari
; Alien travels line progression 0 to 21.  22 is end of game.
; --------------------------------------------------------------------------

;    ------------------------------------------ (000 - 019) Blank scan lines. 8+8+4
; 00 | 000000 P1      HI 000000     P2 000000 | (020 - 027) (2) P1 score, High score, P2 score
; 01 |                                        | (028 - 035) (2) Stars
; 02 |                                        | (036 - 043) (2) Stars
; 03 |                                        | (044 - 051) (2) Stars
; 04 |                                        | (052 - 059) (2) Stars
; 05 |                                        | (060 - 067) (2) Stars
; 06 |                                        | (068 - 075) (2) Stars
; 07 |                                        | (076 - 083) (2) Stars
; 08 |                                        | (084 - 091) (2) Stars
; 09 |                                        | (092 - 099) (2) Stars
; 10 |                                        | (100 - 107) (2) Stars
; 11 |                                        | (108 - 115) (2) Stars
; 12 |                                        | (116 - 123) (2) Stars
; 13 |                                        | (124 - 131) (2) Stars
; 14 |                                        | (132 - 139) (2) Stars
; 15 |                                        | (140 - 147) (2) Stars
; 16 |                                        | (148 - 155) (2) Stars
; 17 |                                        | (156 - 163) (2) Stars
; 18 |                                        | (164 - 171) (2) Stars
; 19 |             Mountains                  | (172 - 179) (4) Mountains
; 20 |             Mountains                  | (180 - 187) (4) Mountains
; 21 |             Mountains                  | (188 - 195) (4) Mountains
; 22 |             Mountains                  | (196 - 203) (4) Mountains
; 23 |B   Solid ground and bumpers           B| (204 - 211) (4) Ground and bumpers, guns operational
; 24 |]]]]]]]]]]]]]]]00 0000 00[[[[[[[[[[[[[[[| (212 - 219) (2) Ground, stats - line, score value, hits left
;    ------------------------------------------


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
; 07 |               GAME  OVER               | (076 - 083) (6) Animated Gfx
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

TITLE_FRAME1 ; 32 * 6 = 192
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $00 $03 $06 $00 $0C $00 $03 $06 $9C $00 $03 $69 $C3 $0C $36 $90 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $60 $09 $30 $0C $09 $00 $09 $00 $36 $0C $00 $30 $06 $00 $00 $09 $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $06 $09 $0C $00 $60 $0C $09 $09 $00 $06 $09 $0C $30 $06 $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $03 $00 $96 $03 $03 $00 $90 $0C $06 $00 $09 $0C $00 $00 $03 $09 $60 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $00 $03 $06 $C0 $06 $0C $93 $03 $00 $0C $03 $00 $00 $0C $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $09 $00 $0C $09 $00 $03 $00 $06 $0C $09 $63 $06 $9C $36 $09 $00 $03 $00 $00 $00 $00 $00 $00 $00

TITLE_FRAME2
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $00 $0C $03 $00 $09 $00 $0C $03 $69 $00 $0C $36 $9C $09 $C3 $60 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $30 $06 $C0 $09 $06 $00 $06 $00 $C3 $09 $00 $C0 $03 $00 $00 $06 $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $03 $06 $09 $00 $30 $09 $06 $06 $00 $03 $06 $09 $C0 $03 $00 $0C $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $0C $00 $63 $0C $0C $00 $60 $09 $03 $00 $06 $09 $00 $00 $0C $06 $30 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $00 $0C $03 $90 $03 $09 $6C $0C $00 $09 $0C $00 $00 $09 $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $06 $00 $09 $06 $00 $0C $00 $03 $09 $06 $3C $03 $69 $C3 $06 $00 $0C $00 $00 $00 $00 $00 $00 $00

TITLE_FRAME3
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $00 $09 $0C $00 $06 $00 $09 $0C $36 $00 $09 $C3 $69 $06 $9C $30 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $C0 $03 $90 $06 $03 $00 $03 $00 $9C $06 $00 $90 $0C $00 $00 $03 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $0C $0C $03 $06 $00 $C0 $06 $03 $03 $00 $0C $03 $06 $90 $0C $00 $09 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $09 $00 $3C $09 $09 $00 $30 $06 $0C $00 $03 $06 $00 $00 $09 $03 $C0 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $06 $00 $09 $0C $60 $0C $06 $39 $09 $00 $06 $09 $00 $00 $06 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $03 $00 $06 $03 $00 $09 $00 $0C $06 $03 $C9 $0C $36 $9C $03 $00 $09 $00 $00 $00 $00 $00 $00 $00

TITLE_FRAME4
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $00 $06 $09 $00 $03 $00 $06 $09 $C3 $00 $06 $9C $36 $03 $69 $C0 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $90 $0C $60 $03 $0C $00 $0C $00 $69 $03 $00 $60 $09 $00 $00 $0C $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $0C $09 $09 $0C $03 $00 $90 $03 $0C $0C $00 $09 $0C $03 $60 $09 $00 $06 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $03 $06 $00 $C9 $06 $06 $00 $C0 $03 $09 $00 $0C $03 $00 $00 $06 $0C $90 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $06 $03 $00 $06 $09 $30 $09 $03 $C6 $06 $00 $03 $06 $00 $00 $03 $00 $03 $00 $00 $00 $00 $00 $00 $00
	.by $00 $00 $00 $00 $00 $00 $00 $09 $0C $00 $03 $0C $00 $06 $00 $09 $03 $0C $96 $09 $C3 $69 $0C $00 $06 $00 $00 $00 $00 $00 $00 $00


; Scrolling text for the directions, credits, etc.
; Since this is in Mode 6 it only needs 
; 20 blank characters for padding.
scrtxt   
	.sb "                    PRESS FIRE TO PLAY"
	.sb "     FIRE SHOOTS AND CHANGES CANNON DIRECTION"
	.sb "     MORE POINTS WHEN 1NVADER IS HIGH UP"
	.sb "     1NVADER SLOWS DOWN AFTER EIGHTY HITS"
	.sb "     C64 VERSION 2019 - DARREN FOULDS  @DARRENTHEFOULDS"
	.sb "     THX @BEDFORDLVLEXP     HI NATE AND TBONE!"
	.sb "     ATARI VERSION 2020 - KEN JENNINGS HTTPS://GITHUB.COM/KENJENNINGS/ATARI-1NVADER"
	.sb "                    "


; " ]              ]           ]         ] "
; "[^\[        [  [^\       [\[^\]     ][^\"
; "]  \\    [\[^\[   \     [  \ [^\   [^\ ]"
; "_\   \  [  \ [     \   [        \ [   [_"
; "*______________________________________*" <- Bumpers
; "^^^^^^^^^^^^^^^          ^^^^^^^^^^^^^^^"

mountc   ; mountain screen view chars
	.byte $20,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20

	.byte $5b,$5e,$5c,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$20,$5b,$5e,$5c,$20,$20,$20,$20,$20,$20,$20,$5b,$5c,$5b,$5e,$5c,$5d,$20,$20,$20,$20,$20,$5d,$5b,$5e,$5c

	.byte $5d,$20,$20,$5c,$5c,$20,$20,$20,$20,$5b,$5c,$5b,$5e,$5c,$5b,$20,$20,$20,$5c,$20,$20,$20,$20,$20,$5b,$20,$20,$5c,$20,$5b,$5e,$5c,$20,$20,$20,$5b,$5e,$5c,$20,$5d

	.byte $5f,$5c,$20,$20,$20,$5c,$20,$20,$5b,$20,$20,$5c,$20,$5b,$20,$20,$20,$20,$20,$5c,$20,$20,$20,$5b,$20,$20,$20,$20,$20,$20,$20,$20,$5c,$20,$5b,$20,$20,$20,$5b,$5f

	.byte $40,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$40

	.byte $5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e



