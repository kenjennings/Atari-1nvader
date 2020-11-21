;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings
;*
;*******************************************************************************

; ==========================================================================
; ATARI CUSTOM CHARACTER SET
; 
; custom characters - 64 ( + 10) characters defined
; --------------------------------------------------------------------------

; NOTE that a full 1K character set is NOT defined.
; Therefore, anything else declared AFTER this file cannot 
; automatically assume it starts at a 1K boundary.   
; Be aware.

	.align $0400 ; Align character set to 1K boundary.

; ==========================================================================
; Oddly, this character set defines most values in the same order as the
; Atari.  The C64 program offsets this data at +$20.  For Atari purposes
; this can stay at the $00 offset position.   In the C64 code the 
; references to character values need to be offset by -$20 to show 
; correctly on the Atari. 
;
; This defines a stylized space font -- characters A-Z with a few other 
; other symbol characters for text.  There are some special characters 
; for the ground, the bumpers, the mountains, and the stars.
;
; However, this font has problems.  The minimum horizontal pixel size on 
; a NTSC composite display that can accurately render color is a color 
; clock.  The font uses single-pixel width lines.  In the usual ANTIC
; text mode 2 (40 colums) each pixel is only one half color clock wide.  
; Real Atari hardware using a composite or TV display will render text 
; in this font with artifact colors scattered throughout.  
;
; On the C64 this is even worse as its single-pixel width lines are not 
; even a correct fraction of a color clock.  Artifact colors vary by 
; characcter position.  So far, all the videos I've seen of the game 
; were shot on emulators that don't accurately simulate the C64's 
; pixels' low correlation to the NTSC color clock.  But back to the 
; immediate problems on the Atari.....
;
; The correct solution for the characters that will be displayed in ANTIC
; mode 2 is to use two, adjacent horizontal pixels to cover an entire 
; color clock.  However, I'm far toooo lazy to redefine the entire 
; character set for the limited text in the game.
;
; The next choice is to use a different text mode that displays color
; clock-sized pixels.   ANTIC Mode 6 and 7 use 8-bit wide glyph images
; like ANTIC mode 2, but each pixel is a color clock wide.  Excluding
; the score and line status information ANTIC mode 6 will be used where 
; text is displayed.  
;
; ANTIC Mode 6 characters are twice the width of Mode 2 characters. 
; However, Mode 6 also provides other benefits that can be applied to 
; additional bells and whistles.   This mode has full color indirection
; unlike Mode 2.   This mode requires much less DMA than Mode 2 and so 
; provides more CPU time for Display List Interrupts.
;
; The mountains and ground can be displayed using the Mode 6 characters 
; with some modifications to use different color registers which will 
; allow mixing the white snow with the grey mountains on the same 
; line.  (In fact, Display List Interrupts will be used to apply several
; shades of gray to the mountains.)
;
; The score line at the top and the current alien line value information 
; at the bottom of the screen will still use the Mode 2 character text mode.
; These lines use the numbers and not text, so only the number glyphs will 
; be edited to double the pixel width for consistent rendering.
;
; Converting integer values (the score) into readable text on screen 
; involves a lot of extra coding work.  Rather than handling the score 
; as an integer, the score will be directly generated as individual bytes
; for each digit.  This will take a little extra coding to manage the 
; score as base 10 values per each byte, but the conversion to display 
; these bytes on screen will be quick and easy.   Basically, just add 
; the appropriate offset value to the decimal digits 0 through 9 and this 
; directly provides the internal character value to write to the screen.
;
; --------------------------------------------------------------------------

; ==========================================================================
; For reference, some changes....
; Character codes 0 to 63 are assumed to be primarily for Mode 6 text.
; Character codes 64+ are for Mode 2 text.
;
; C64       ==   Atari
; $07  @    ==   '  ; The natural position for apostrophe on Atari.
; $20       ==   @  ; This is the natural position for "at" on Atari
; The bumper at $20 on the C64 will be done with P5 missiles.
; $01  "1"  ==   !  ; Restore exclamation to its correct position on Atari.
; 
; $01 - $06 ==  
; These are for the animated 3, 2, 1 game start counter.  On the C64 this 
; was two characters put together to make a wide character.  The Atari 
; Mode 6 characters are already "double width", so the game could use
; just 3 characters to immitate the C64 start.  Buuuut, looking for a 
; little bit of amping up the bass here.  The Atari version does an
; animation growing a tiny number into a large, double-height number 
; using Player/Missile Graphic.
;
; --------------------------------------------------------------------------

CHARACTER_SET

cdat1 ; the first 32 characters
; $00
	.byte $00,$00,$00,$00 ; [спаце].  blank space
	.byte $00,$00,$00,$00
; $01
;	.byte $00,$01,$06,$01 ; ! ; thick left 1.  double size 1, left
;	.byte $01,$01,$01,$00
		; ........
		; .......*
		; .....**.
		; .......*
		; .......*
		; .......*
		; .......*
		; ........

	.byte $00,$10,$10,$10 ; ! ;    Atari uses as exclamation point. 
	.byte $10,$00,$10,$00
	; $00 ........
	; $10 ...*....
	; $10 ...*....
	; $10 ...*....
	; $10 ...*....
	; $00 ........
	; $10 ...*....
	; $00 ........

; $02
;	.byte $00,$1f,$00,$07 ; " ; thick left 2.  double size 2, left
;	.byte $18,$18,$1f,$00

; Atari Version.
;The bouncer was moved, so the Atari can have the single tick and
; at sign @ at the proper places in its font.
;
; $02
	.byte $ff,$76,$2c,$34 ; @ ;     bouncer.   Left/Right line end.
	.byte $2c,$76,$ff,$00
	; $ff ********
	; $76 .***.**.
	; $2C ..*.**..
	; $34 ..**.*..
	; $2C ..*.**..
	; $76 .***.**.
	; $ff ********
	; $00 ........

; $03
;	.byte $00,$1f,$00,$01 ; # ; thick left 3.  double size 3, left
;	.byte $00,$00,$1f,$00
; $04
;	.byte $00,$80,$00,$80 ; $ ; thick right 1.  double size 1, right
;	.byte $80,$80,$80,$00
; $05
;	.byte $00,$e0,$18,$e0 ; % ; thick right 2.  double size 2, right
;	.byte $00,$00,$f8,$00
; $06
;	.byte $00,$e0,$18,$e0 ; & ; thick right 3.  double size 3, right
;	.byte $18,$18,$e0,$00

	ORG CHARACTER_SET + [ $07 * 8 ]
	
; $07  - This was the C64 at sign.  
;	.byte $00,$38,$44,$54 ; ' ; new "at" sign
;	.byte $5c,$40,$3c,$00
	; $00 ........
	; $38 ..***...
	; $44 .*...*..
	; $54 .*.*.*..
	; $5C .*.***..
	; $40 .*......
	; $3C ..****..
	; $00 ........
	; On the Atari this is the single tick/apostrophe for Mode 6
	.byte $00,$08,$08,$10
	.byte $00,$00,$00,$00
	; $00 ........
	; $08 ....*...
	; $08 ....*...
	; $10 ...*....
	; $00 ........
	; $00 ........
	; $00 ........
	; $00 ........
	
; $08
;	.byte $ff,$38,$44,$38 ; ( ;   8 with bars above, below?
;	.byte $44,$44,$38,$ff
	; $ff ********
	; $38 ..***...
	; $44 .*...*..
	; $38 ..***...
	; $44 .*...*..
	; $44 .*...*..
	; $38 ..***...
	; $ff ********
	
; $09
;	.byte $ff,$38,$44,$44 ; ) ;   9 with bars above, below?
;	.byte $34,$04,$04,$ff
	; $ff ********
	; $38 ..***...
	; $44 .*...*..
	; $44 .*...*..
	; $34 ..**.*..
	; $04 .....*..
	; $38 ..*..
	; $ff ********

		ORG CHARACTER_SET + [ $0A * 8 ]
; $0A
;	.byte $10,$00,$10,$ba ; * ; [star] .  Star shape
;	.byte $10,$00,$10,$00
	; $10 ...*....
	; $00 ........
	; $10 ...*....
	; $BA *.***.*.
	; $10 ...*....
	; $00 ........
	; $10 ...*....
	; $00 ........

	; Revise Star for Atari for Mode 2 and proper artifact avoidance.
;	.by $18,$00,$18,$DB
;	.by $18,$00,$18,$00
	; $18 ...**...
	; $00 ........
	; $18 ...**...
	; $DB **.**.**
	; $18 ...**...
	; $00 ........
	; $18 ...**...
	; $00 ........

	; Revise Star for Atari for Mode 6 color
	.by $00,$80,$00,$80
	.by $49,$80,$00,$80
	; $00 ........
	; $80 ....*...
	; $00 ........
	; $80 ....*...
	; $49 .*..*..*
	; $80 ....*...
	; $00 ........
	; $80 ....*...


; $0B
	.byte $00,$01,$02,$03 ; + ;     ? Placeholder?  Unused?
	.byte $04,$05,$06,$07
	
; $0C
	.byte $00,$00,$00,$00 ; , ;     comma
	.byte $00,$00,$10,$20
; $0D
	.byte $00,$00,$00,$7c ; - ;     minus
	.byte $00,$00,$00,$00
; $0E
	.byte $00,$00,$00,$00 ; . ;     period.
	.byte $00,$00,$10,$00
; $0F
;	.byte $00,$10,$10,$10 ; / ;    new exclamation point. !
;	.byte $10,$00,$10,$00
; On the Atari we still need this for a URL in the credits.
	.by $00,$02,$04,$08 
	.by $00,$10,$20,$40
	; $00 ........
	; $02 ......*.
	; $04 .....*..
	; $08 ....*...
	; $10 ...*....
	; $20 ..*.....
	; $40 .*......
	; $00 ........

		ORG CHARACTER_SET + [ $10 * 8 ]
		
; These are the 0 to 9 digits displayed in the Mode 6 text.
; See the $40 characters for the Mode 2 versions.

; $10
	.byte $00,$38,$44,$54 ; 0
	.byte $54,$44,$38,$00
	; $00 ........
	; $38 ..***...
	; $44 .*...*..
	; $54 .*.*.*..
	; $54 .*.*.*..
	; $44 .*...*..
	; $38 ..***...
	; $00 ........

; $11
	.byte $00,$10,$20,$10 ; 1
	.byte $10,$10,$10,$00
	; $00 ........
	; $10 ...*....
	; $20 ..*.....
	; $10 ...*....
	; $10 ...*....
	; $10 ...*....
	; $10 ...*....
	; $00 ........

; $12
	.byte $00,$78,$04,$38 ; 2
	.byte $40,$40,$7c,$00
	; $00 ........
	; $78 .****...
	; $04 .....*..
	; $38 ..***...
	; $40 .*......
	; $40 .*......
	; $7C .*****..
	; $00 ........
	
; $13
	.byte $00,$78,$04,$18 ; 3
	.byte $04,$04,$78,$00
	; $00 ........
	; $78 .****...
	; $04 .....*..
	; $18 ...**...
	; $04 .....*..
	; $04 .....*..
	; $78 .****...
	; $00 ........
	
; $14
	.byte $00,$44,$44,$44 ; 4
	.byte $74,$04,$04,$00
	; $00 ........
	; $44 .*...*..
	; $44 .*...*..
	; $44 .*...*..
	; $74 .***.*..
	; $04 .....*..
	; $04 .....*..
	; $00 ........
	
; $15
	.byte $00,$7c,$40,$78 ; 5
	.byte $04,$04,$78,$00
	; $00 ........
	; $7c .*****..
	; $40 .*......
	; $78 .****...
	; $04 .....*..
	; $04 .....*..
	; $78 .****...
	; $00 ........

; $16
	.byte $00,$30,$40,$78 ; 6
	.byte $44,$44,$38,$00
	; $00 ........
	; $30 ..**....
	; $40 .*......
	; $78 .****...
	; $44 .*...*..
	; $44 .*...*..
	; $38 ..***...
	; $00 ........
	
; $17
	.byte $00,$7c,$00,$08 ; 7
	.byte $10,$10,$10,$00	
	; $00 ........
	; $7C .*****..
	; $00 ........
	; $08 ....*...
	; $10 ...*....
	; $10 ...*....
	; $10 ...*....
	; $00 ........
	
; $18
	.byte $00,$38,$44,$38 ; 8
	.byte $44,$44,$38,$00
	; $00 ........
	; $38 ..***...
	; $44 .*...*..
	; $38 ..***...
	; $44 .*...*..
	; $44 .*...*..
	; $38 ..***...
	; $00 ........
	
; $19
	.byte $00,$38,$44,$44 ; 9
	.byte $34,$04,$04,$00
	; $00 ........
	; $38 ..***...
	; $44 .*...*..
	; $44 .*...*..
	; $34 ..**.*..
	; $04 .....*..
	; $04 .....*..
	; $00 ........
	
; $1A
;	.byte $00,$01,$02,$03 ; : ;        ? Placeholder?  Unused?
;	.byte $04,$05,$06,$07
	.byte $00,$10,$10,$00
	.byte $00,$10,$10,$00
	; $00 ........
	; $10 ...*....
	; $10 ...*....
	; $00 ........
	; $00 ........
	; $10 ...*....
	; $10 ...*....
	; $00 ........



	
; $1B
;	.byte $00,$01,$02,$03 ; ; ;        ? Placeholder?  Unused?
;	.byte $04,$05,$06,$07
; $1C
;	.byte $00,$01,$02,$03 ; < ;        ? Placeholder?  Unused?
;	.byte $04,$05,$06,$07
; $1D
;	.byte $00,$01,$02,$03 ; = ;        ? Placeholder?  Unused?
;	.byte $04,$05,$06,$07
; $1E
;	.byte $00,$01,$02,$03 ; > ;        ? Placeholder?  Unused?
;	.byte $04,$05,$06,$07
; $1F
;	.byte $00,$01,$02,$03 ; ? ;        ? Placeholder?  Unused?
;	.byte $04,$05,$06,$07
	.byte $00,$38,$44,$38 ; ?
	.byte $44,$44,$38,$00
	; $00 ........
	; $38 ..***...
	; $44 .*...*..
	; $38 ....*...
	; $44 ...*....
	; $44 ........
	; $38 ...*....
	; $00 ........

		ORG CHARACTER_SET + [ $20 * 8 ]
		

cdat2 ; next 32 characters.

; This is the image originally at $20
; On the Atari this is moved to $02 
; I like to have the  single tick (') and the at (@) at the 
; correct positions in the Atari font.

; $20
;	.byte $ff,$76,$2c,$34 ; @ ;     bouncer.   Left/Right line end.
;	.byte $2c,$76,$ff,$00

; On the Atari the @ sign is move to its normal position here, so 
; that the single tick (apostrophe) can be used at its normal place
; for text.
;	.byte $00,$38,$44,$54 ; ' ; new "at" sign
;	.byte $5c,$40,$3c,$00
	; $00 ........
	; $38 ..***...
	; $44 .*...*..
	; $54 .*.*.*..
	; $5C .*.***..
	; $40 .*......
	; $3C ..****..
	; $00 ........
	.byte $00,$38,$c6,$d6	; Revised @ for Atari Mode 6
	.byte $dc,$c0,$3c,$00
	; $00 ........
	; $38 ..***...
	; $c6 **...**.
	; $d6 **.*.**.
	; $dc **.***..
	; $c0 **......
	; $3C ..****..
	; $00 ........

; $21
	.byte $00,$04,$0c,$14 ; а ; A
	.byte $24,$5c,$44,$00
	; ........
	; .....*..
	; ....**..
	; ...*.*..
	; ..*..*..
	; .*.***..
	; .*...*..
	; ........
; $22
	.byte $00,$78,$44,$58 ; б ; B
	.byte $44,$44,$5c,$00
; $23
	.byte $00,$3c,$40,$40 ; ц ; C
	.byte $40,$40,$7c,$00
; $24
	.byte $00,$70,$48,$44 ; д ; D
	.byte $44,$44,$5c,$00
; $25
	.byte $00,$7c,$40,$58 ; е ; E
	.byte $40,$40,$7c,$00
; $26
	.byte $00,$7c,$40,$58 ; ф ; F
	.byte $40,$40,$40,$00
; $27
	.byte $00,$3c,$40,$40 ; г ; G
	.byte $44,$44,$7c,$00
; $28
	.byte $00,$44,$44,$5c ; х ; H
	.byte $44,$44,$44,$00
; $29
	.byte $00,$10,$10,$10 ; и ; I
	.byte $10,$10,$10,$00
; $2A
	.byte $00,$08,$08,$08 ; й ; J
	.byte $08,$08,$08,$30
; $2B
	.byte $00,$44,$44,$58 ; к ; K
	.byte $44,$44,$44,$00
; $2C
	.byte $00,$40,$40,$40 ; л ; L
	.byte $40,$40,$7c,$00
; $2D
	.byte $00,$44,$2c,$54 ; м ; M
	.byte $44,$44,$44,$00
; $2E
	.byte $00,$44,$64,$54 ; н ; N
	.byte $4c,$44,$44,$00
; $2F
	.byte $00,$38,$44,$44 ; о ; O
	.byte $44,$44,$38,$00

; $30
	.byte $00,$78,$44,$44 ; п ; P
	.byte $58,$40,$40,$00
; $31
	.byte $00,$38,$44,$44 ; я ; Q
	.byte $44,$40,$3c,$00
; $32
	.byte $00,$78,$44,$44 ; р ; R
	.byte $58,$44,$44,$00
; $33
	.byte $00,$3c,$40,$38 ; с ; S
	.byte $04,$04,$78,$00
; $34
	.byte $00,$7c,$00,$10 ; т ; T
	.byte $10,$10,$10,$00
; $35
	.byte $00,$44,$44,$44 ; у ; U
	.byte $44,$44,$38,$00
; $36
	.byte $00,$44,$44,$48 ; ж ; V
	.byte $50,$60,$40,$00
; $37
	.byte $00,$44,$44,$44 ; в ; W
	.byte $54,$2c,$44,$00
; $38
	.byte $00,$44,$44,$18 ; ь ; X
	.byte $44,$44,$44,$00
; $39
	.byte $00,$44,$44,$44 ; ы ; Y
	.byte $3c,$04,$38,$00
; $3A
	.byte $00,$7c,$00,$08 ; з ; Z
	.byte $10,$20,$7c,$00
	
; $3B
	.byte $01,$02,$06,$0a ; [ ; mnt l .   Mountain Left
	.byte $18,$2a,$40,$a0
	; $01 .......*
	; $02 ......*.
	; $06 .....**.
	; $0a ....*.*.
	; $18 ...**...
	; $2a ..*.*.*.
	; $40 .*......
	; $a0 *.*.....
; $3C
	.byte $80,$40,$a0,$30 ; \ ; mnt r .   Mountain Right
	.byte $28,$04,$26,$05
	; $80 *.......
	; $40 .*......
	; $a0 *.*.....
	; $30 ..**....
	; $28 ..*.*...
	; $04 .....*..
	; $26 ..*..**.
	; $05 .....*.*
; $3D
	.byte $00,$00,$00,$00 ; ] ; mnt top.  Mountain Top
	.byte $18,$3c,$6e,$ab
	; $00 ........
	; $00 ........
	; $00 ........
	; $00 ........
	; $18 ...**...
	; $3c ..****..
	; $6e .**.***.
	; $ab *.*.*.**
; $3E
	.byte $ff,$11,$44,$00 ; ^ ; grnd lo .  Ground bottom line.
	.byte $00,$00,$00,$00
	; $ff ********
	; $11 ...*...*
	; $44 .*...*..
	; $00 ........
	; $00 ........
	; $00 ........
	; $00 ........
	; $00 ........
; $3F
	.byte $99,$42,$99,$40 ; _ ; grnd hi .  Ground Top Line
	.byte $aa,$55,$ff,$00
	; $99 *..**..*
	; $42 .*....*.
	; $99 *..**..*
	; $40 .*......
	; $aa *.*.*.*.
	; $55 .*.*.*.*
	; $ff ********
	; $00 

; Another 64 characters . . . . ?

cda3 ; next 32 characters.

; These are the 10 characters used for ANTIC Mode 2 Score text.
; Scores are calculating using a single base 10 digit per byte.
; To display the right character on the screen simply add (or
; ORA) $40 to the digit.

; Revise digits for Atari display in ANTIC Mode 2 and proper 
; color artifact avoidance.

; $40
	.by $00,$38,$C6,$C6 ; 0
	.by $C6,$C6,$38,$00
	; $00 ........
	; $38 ..***...
	; $C6 **...**.
	; $D6 **...**.
	; $D6 **...**.
	; $C6 **...**.
	; $38 ..***...
	; $00 ........

; $41
	.by $00,$18,$30,$18 ; 1
	.by $18,$18,$18,$00
	; $00 ........
	; $18 ...**...
	; $30 ..**....
	; $18 ...**...
	; $18 ...**...
	; $18 ...**...
	; $18 ...**...
	; $00 ........

; $42
	.byte $00,$78,$06,$38 ; 2
	.byte $c0,$c0,$7c,$00
	; $00 ........
	; $78 .****...
	; $06 .....**.
	; $38 ..***...
	; $C0 **......
	; $C0 **......
	; $7C .*****..
	; $00 ........
	
; $43
	.byte $00,$78,$06,$18 ; 3
	.byte $06,$06,$78,$00
	; $00 ........
	; $78 .****...
	; $06 .....**.
	; $18 ...**...
	; $06 .....**.
	; $06 .....**.
	; $78 .****...
	; $00 ........
	
; $44
	.byte $00,$c6,$c6,$c6 ; 4
	.byte $76,$06,$06,$00
	; $00 ........
	; $c6 **...**.
	; $c6 **...**.
	; $c6 **...**.
	; $76 .***.**.
	; $06 .....**.
	; $06 .....**.
	; $00 ........
	
; $45
	.byte $00,$f8,$c0,$f8 ; 5
	.byte $06,$06,$78,$00
	; $00 ........
	; $F8 *****...
	; $c0 **......
	; $F8 *****...
	; $06 .....**.
	; $06 .....**.
	; $78 .****...
	; $00 ........

; $46
	.byte $00,$38,$c0,$f8 ; 6
	.byte $c6,$c6,$38,$00
	; $00 ........
	; $38 ..***...
	; $c0 **......
	; $f8 *****...
	; $c6 **...**.
	; $c6 **...**.
	; $38 ..***...
	; $00 ........
	
; $47
	.byte $00,$7c,$00,$0c ; 7
	.byte $18,$18,$18,$00	
	; $00 ........
	; $7C .*****..
	; $00 ........
	; $0c ....**..
	; $18 ...**...
	; $18 ...**...
	; $18 ...**...
	; $00 ........
	
; $48
	.byte $00,$38,$c6,$38 ; 8
	.byte $c6,$c6,$38,$00
	; $00 ........
	; $38 ..***...
	; $c6 **...**.
	; $38 ..***...
	; $c6 **...**.
	; $c6 **...**.
	; $38 ..***...
	; $00 ........
	
; $49
	.byte $00,$38,$c6,$c6 ; 9
	.byte $36,$06,$06,$00
	; $00 ........
	; $38 ..***...
	; $c6 **...**.
	; $c6 **...**.
	; $36 ..**.**.
	; $06 .....**.
	; $06 .....**.
	; $00 ........

; NOTE that a full 1K character set is NOT defined.
; Therefore, anything else declared AFTER this point cannot 
; automatically assume it starts at a 1K boundary.   
; Be aware.

