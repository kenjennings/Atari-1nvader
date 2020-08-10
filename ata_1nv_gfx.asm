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
; Title Screen Atari
; --------------------------------------------------------------------------
;
;    ------------------------------------------ (000 - 019) Blank scan lines. 8+8+4
; 00 | 000000          000000          000000 | (020 - 027) (2) P1 score, High score, P2 score
; 01 |                                        | (028 - 035) Blank 8
; 02 |                                        | (036 - 043) Blank 8
; 03 |                   3                    | (044 - 051) (6) 3, 2, 1, GO line animation
; 04 |                   3                    | (052 - 059) (6) 3, 2, 1, GO line animation
; 05 |                                        | (060 - 067) Blank 8  (DLI vscroll hack) 
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
; Game Screen Atari
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
; Game Over Screen Atari
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





; Title graphics are ANTIC mode 9 with a Player/missile color overlay.
; pixel values 3, 6, 9, 12 are used for the animated image.
; Narrow playfield is used to reduce the memory needed for each line.
; Pixel values are shifted in each bitmap image to create the 
; illusion of motion.  Rather than being clever the images are just 
; pre-rendered and the code will just page flip between them by
; changing a pointer in the display list.
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


