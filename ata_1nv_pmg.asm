;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; PLAYER/MISSILE GRAPHICS MEMORY
;
; ANTIC has a 2K boundary limit for Single line resolution Player/Missile 
; Graphics.  However, since the first three pages are unused that leaves 
; enough space to keep the image declarations here.
; Code will copy them when needed to the working Player or Missile memory.
; --------------------------------------------------------------------------

	.align $0800

PMADR ; Declare the base address locations for each player bitmap.

; Define the begining location for each Player/Missile bitmap.
; Defining without declaring space will not create 256 bytes for 
; each bitmap, so it will not be allocated/created as part of the 
; assembly and so save space in the executable.

MISSILEADR = PMADR+$300
PLAYERADR0 = PMADR+$400
PLAYERADR1 = PMADR+$500
PLAYERADR2 = PMADR+$600
PLAYERADR3 = PMADR+$700


; --------------------------------------------------------------------------
; VBI manages moving everything around, so there's never any visible tearing.
; Also, its best to evaluate the P/M collisions after the screen has been 
; drawn, and before the next movement occurs.

spr1     ; mothership sprite
;	.BYTE 0,126,0                  ; ........ .111111. ........
;	.BYTE 1,255,128                ; .......1 11111111 1.......
;	.BYTE 3,255,192                ; ......11 11111111 11......
;	.BYTE 6,219,96                 ; .....11. 11.11.11 .11.....
;	.BYTE 15,255,240               ; ....1111 11111111 1111....
;	.BYTE 15,255,240               ; ....1111 11111111 1111....
;	.BYTE 3,153,192                ; ......11 11111111 11......
;	.BYTE 1,0,128                  ; .......1 ........ 1.......
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,255

PMG_MOTHERSHIP
	.BYTE $00  ; ...11...
	.BYTE $00  ; ..1111..
	.BYTE $00  ; .111111.
	.BYTE $00  ; .1.11.1.
	.BYTE $00  ; 11111111
	.BYTE $00  ; 11111111
	.BYTE $00  ; .111111.
	.BYTE $00  ; ..1..1..

spr2     ; cannon sprite
;	.BYTE 0,8,0                    ; ........ ....1... ........
;	.BYTE 0,28,0                   ; ........ ...111.. ........
;	.BYTE 0,28,0                   ; ........ ...111.. ........
;	.BYTE 3,255,224                ; ......11 11111111 111.....
;	.BYTE 7,255,240                ; .....111 11111111 1111....
;	.BYTE 7,255,240                ; .....111 11111111 1111....
;	.BYTE 7,255,240                ; .....111 11111111 1111.... 
;	.BYTE 7,255,240                ; .....111 11111111 1111....  
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,255

PMG_CANNON
	.BYTE $18  ; ...11...
	.BYTE $18  ; ...11...
	.BYTE $7e  ; .111111.
	.BYTE $7e  ; .111111.
	.BYTE $ff  ; 11111111
	.BYTE $ff  ; 11111111
	.BYTE $ff  ; 11111111
	.BYTE $ff  ; 11111111


spr3     ; laser sprite
;	.BYTE 0,8,0                    ; ........ ....1... ........
;	.BYTE 0,4,0                    ; ........ .....1.. ........
;	.BYTE 0,8,0                    ; ........ ....1... ........
;	.BYTE 0,16,0                   ; ........ ...1.... ........
;	.BYTE 0,8,0                    ; ........ ....1... ........
;	.BYTE 0,4,0                    ; ........ .....1.. ........
;	.BYTE 0,8,0                    ; ........ ....1... ........
;	.BYTE 0,8,0                    ; ........ ....1... ........
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,255

PMG_LASER
	.BYTE $40  ; .1......
	.BYTE $20  ; ..1.....
	.BYTE $40  ; .1......
	.BYTE $80  ; 1.......
	.BYTE $40  ; .1......
	.BYTE $20  ; ..1.....
	.BYTE $40  ; .1......
	.BYTE $40  ; .1......


spr4     ; explosion
;	.BYTE 0,66,0                  ; ........ .1....1. ........
;	.BYTE 1,36,128                ; .......1 ..1..1.. 1.......
;	.BYTE 0,129,0                 ; ........ 1......1 ........
;	.BYTE 6,0,96                  ; .....11. ........ .11.....
;	.BYTE 0,129,0                 ; ........ 1......1 ........
;	.BYTE 1,36,128                ; .......1 ..1..1.. 1.......
;	.BYTE 0,66,0                  ; ........ .1....1. ........
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,0,0,0,0,0,0,0,0,0
;	.byte 0,0,0,255

PMG_EXPLOSION
	.BYTE $24  ; ..1..1..
	.BYTE $5a  ; .1.11.1.
	.BYTE $24  ; ..1..1..
	.BYTE $c3  ; 11....11
	.BYTE $24  ; ..1..1..
	.BYTE $5a  ; .1.11.1.
	.BYTE $24  ; ..1..1..


; ==========================================================================
; TITLE SCREEN SHENANIGANS

; The color overlay is done by shifting missile positions right at
; the same rate that this image bitmap is shifted left through the 
; missile memory.  The appearance is like a color window sliding 
; across the animated title pixels.
; 

; Shifty bits.  Byte, left shift, byte, right shift
; ((BYTE1 & MASK1) << OFFSET1) | ((BYTE2 & MASK2) >> OFFSET2) 
; (-) 01111111 << 1 | (-) 10000000 >> 7 (N/A)
; (0) 00111111 << 2 | (1) 11000000 >> 6 (Zero)
; (0) 00011111 << 3 | (1) 11100000 >> 5 (1)
; (0) 00001111 << 4 | (1) 11110000 >> 4 (2)
; (0) 00000111 << 5 | (1) 11111000 >> 3 (3)
; (0) 00000011 << 6 | (1) 11111100 >> 2 (4)
; (0) 00000001 << 7 | (1) 11111110 >> 1 (5)
; (1) 00000000 << 0 | (-) -------- >> 0 (6)
; (1) 01111111 << 1 | (2) 10000000 >> 7 (7)
; (1) 00111111 << 2 | (2) 11000000 >> 6 (8)
; (1) 00011111 << 3 | (2) 11100000 >> 5 (9)
; (1) 00001111 << 4 | (2) 11110000 >> 4 (10)
; (1) 00000111 << 5 | (2) 11111000 >> 3 (11)
; (1) 00000011 << 6 | (2) 11111100 >> 2 (12)
; (1) 00000001 << 7 | (2) 11111110 >> 1 (13)
; (2) 00000000 << 0 | (-) -------- >> 0 (14)
; (2) 01111111 << 1 | (3) 10000000 >> 7 (15)
. . .
; (4) 00000001 << 7 | (5) 11111110 >> 1 (37)
; (5) 00000000 << 0 | (-) -------- >> 0 (38)
; (5) 01111111 << 1 | (6) 10000000 >> 7 (39)
; (5) 00111111 << 2 | (6) 11000000 >> 6 (40)
; (5) 00011111 << 3 | (6) 11100000 >> 5 (41)
; (5) 00001111 << 4 | (6) 11110000 >> 4 (42)
; (5) 00000111 << 5 | (6) 11111000 >> 3 (43)
; (5) 00000011 << 6 | (6) 11111100 >> 2 (44) (end)/clear, zero.
; (-) 00000001 << 7 | (1) 11111110 >> 1 (N/A)

PM_TITLE_BITMAP 
; -------- 000000  00001111  11111122  22222222  33333333  3344444
; -------- 012345  67890123  45678901  23456789  01234567  8901234- ---------
; -------- ******  **
;	.by %00000000 %00010100 %01010001 %00010111 %00011111 %01111000 %00000000  
;	.by %00000000 %00100110 %01010001 %00110100 %10010000 %01000100 %00000000
;	.by %00000000 %00010101 %01010010 %01010100 %01010110 %01000100 %00000000
;	.by %00000000 %00010100 %11010100 %10010100 %01010000 %01011000 %00000000
;	.by %00000000 %00010100 %01011001 %01110100 %01010000 %01000100 %00000000
;	.by %00000000 %00010100 %01010001 %00010101 %11011111 %01000100 %00000000

; Pre-shifting the data requires 43 bytes per line, (ignoring the all 0/blank 
; positions at the start and end of the animation) or 258 bytes total .
; (Hmmm. One pixel less and this would have fit in a page. What a bummer.)
; Supplying one blank position means 44 pixel postitions.

; A set of lookup tables to drive logic needs 44 entries each for 
; two byte offsets, and two shift values, or 172 bytes, plus 30 bytes for 
; the bitmap itself, or 202 bytes, not including all the extra code needed 
; to shift and bash bits together.

; The data driving method is less code, so faster, and what's a few wasted 
; bytes of storage mean between friends?

;	........1.1...1.1...1...1.111...11111.1111...... ..  
;	.......1..11..1.1...1..11.1..1..1.....1...1..... ..
;	........1.1.1.1.1..1..1.1.1...1.1.11..1...1..... ..
;	........1.1..11.1.1..1..1.1...1.1.....1.11...... ..
;	........1.1...1.11..1.111.1...1.1.....1...1..... ..
;	........1.1...1.1...1...1.1.111.11111.1...1..... ..

; We are trying for only 44 bits shifted (5 * 8 = 40 + 4)

; The data declarations below were considerably more grotesque.
; See the bitmap shifting discussion above.  Imagine that applied
; to the bitmap.  After hand-typing the first row I got fed up 
; and wrote the bitmap-Left and bitmap-Right macros to generate 
; pre-shifted bitmap values.

PM_TITLE_BITMAP_LINE1 ;	.by 00000000 10100010 10001000 10111000 11111011 11000000 00
	mBitmap16Left %0000000010100010

	mbitmap16Left %1010001010001000

	mbitmap16Left %1000100010111000   
	
	mbitmap16Left %1011100011111011  

	mbitmap16Left %1111101111000000
	
	mbitmap16LeftShift %1100000000000000,0,3 ; 0, 1, 2, 3


PM_TITLE_BITMAP_LINE2 ; .by 00000001 00110010 10001001 10100100 10000010 00100000 00
	mBitmap16Left %0000000100110010

	mBitmap16Left %0011001010001001

	mBitmap16Left %1000100110100100   

	mBitmap16Left %1010010010000010  

	mBitmap16Left %1000001000100000 

	mBitmap16LeftShift %0010000000000000,0,3 ; 0, 1, 2, 3


PM_TITLE_BITMAP_LINE3 ; .by 00000000 10101010 10010010 10100010 10110010 00100000 00
	mBitmap16Left %0000000010101010     

	mBitmap16Left %1010101010010010    

	mBitmap16Left %1001001010100010   

	mBitmap16Left %1010001010110010  

	mBitmap16Left %1011001000100000 

	mBitmap16LeftShift %0010000000000000,0,3 ; 0, 1, 2, 3


PM_TITLE_BITMAP_LINE4 ; .by 00000000 10100110 10100100 10100010 10000010 11000000 00
	mBitmap16Left %0000000010100110     

	mBitmap16Left %1010011010100100    

	mBitmap16Left %1010010010100010   

	mBitmap16Left %1010001010000010  

	mBitmap16Left %1000001011000000 

	mBitmap16LeftShift %1100000000000000,0,3 ; 0, 1, 2, 3


PM_TITLE_BITMAP_LINE5 ; .by 00000000 10100010 11001011 10100010 10000010 00100000 00
	mBitmap16Left %0000000010100010     

	mBitmap16Left %1010001011001011 

	mBitmap16Left %1100101110100010 

	mBitmap16Left %1010001010000010  

	mBitmap16Left %1000001000100000 

	mBitmap16LeftShift %0010000000000000,0,3 ; 0, 1, 2, 3


PM_TITLE_BITMAP_LINE6 ; .by 00000000 10100010 10001000 10101110 11111010 00100000 00
	mBitmap16Left %0000000010100010 

	mBitmap16Left %1010001010001000    

	mBitmap16Left %1000100010101110   

	mBitmap16Left %1010111011111010  

	mBitmap16Left %1111101000100000 

	mBitmap16LeftShift %0010000000000000,0,3 ; 0, 1, 2, 3


; ==========================================================================
; Here force alignment to the next 2K boundary.
; Because no space was actually declared for each Player/Missile bitmap, 
; the end of Player/Missile space needs to be specified, to make the 
; Assembler NOT overwrite this memory with whatever comes next.  
; (Saves space in the Atari's structure executable file format.)
; --------------------------------------------------------------------------

	.align $0800

