;*******************************************************************************
;* 1nvader Custom Character set
;*
;* May 2020 Ken Jennings
;*                                 
;*******************************************************************************

	; custom characters - 64 characters defined

cdat1 ; the first 32 characters
	.byte $00,$00,$00,$00 ;[спаце].  blanks space
	.byte $00,$00,$00,$00
	.byte $00,$01,$06,$01 ;thick 1.  double size 1, left
	.byte $01,$01,$01,$00
		; ........
		; .......*
		; .....**.
		; .......*
		; .......*
		; .......*
		; .......*
		; ........

	.byte $00,$1f,$00,$07 ;thick 2.  double size 2, left
	.byte $18,$18,$1f,$00
	.byte $00,$1f,$00,$01 ;thick 3.  double size 3, left
	.byte $00,$00,$1f,$00
	.byte $00,$80,$00,$80 ;thickr1.  double size 1, right
	.byte $80,$80,$80,$00
	.byte $00,$e0,$18,$e0 ;thickr2.  double size 2, right
	.byte $00,$00,$f8,$00
	.byte $00,$e0,$18,$e0 ;thickr3.  double size 3, right
	.byte $18,$18,$e0,$00
	.byte $00,$38,$44,$54 ;' = @.    new "at" sign
	.byte $5c,$40,$3c,$00
	.byte $ff,$38,$44,$38 ;(         8 with bars above, below?
	.byte $44,$44,$38,$ff
	.byte $ff,$38,$44,$44 ;)         9 with bars above, below?
	.byte $34,$04,$04,$ff
	.byte $10,$00,$10,$ba ;[star] .  Star shape
	.byte $10,$00,$10,$00
	.byte $00,$01,$02,$03 ;+         ? Placeholder?  Unused?
	.byte $04,$05,$06,$07
	.byte $00,$00,$00,$00 ;,         comma
	.byte $00,$00,$10,$20
	.byte $00,$00,$00,$7c ;-         minus
	.byte $00,$00,$00,$00
	.byte $00,$00,$00,$00 ;.         period.
	.byte $00,$00,$10,$00
	.byte $00,$10,$10,$10 ;/ = !     new exclamation point.
	.byte $10,$00,$10,$00

	.byte $00,$38,$44,$54 ;0
	.byte $54,$44,$38,$00
	.byte $00,$10,$20,$10 ;1
	.byte $10,$10,$10,$00
	.byte $00,$78,$04,$38 ;2
	.byte $40,$40,$7c,$00
	.byte $00,$78,$04,$18 ;3
	.byte $04,$04,$78,$00
	.byte $00,$44,$44,$44 ;4
	.byte $74,$04,$04,$00
	.byte $00,$7c,$40,$78 ;5
	.byte $04,$04,$78,$00
	.byte $00,$30,$40,$78 ;6
	.byte $44,$44,$38,$00
	.byte $00,$7c,$00,$08 ;7
	.byte $10,$10,$10,$00
	.byte $00,$38,$44,$38 ;8
	.byte $44,$44,$38,$00
	.byte $00,$38,$44,$44 ;9
	.byte $34,$04,$04,$00
	.byte $00,$01,$02,$03 ;:          ? Placeholder?  Unused?
	.byte $04,$05,$06,$07
	.byte $00,$01,$02,$03 ;;          ? Placeholder?  Unused?
	.byte $04,$05,$06,$07
	.byte $00,$01,$02,$03 ;<          ? Placeholder?  Unused?
	.byte $04,$05,$06,$07
	.byte $00,$01,$02,$03 ;=          ? Placeholder?  Unused?
	.byte $04,$05,$06,$07
	.byte $00,$01,$02,$03 ;>          ? Placeholder?  Unused?
	.byte $04,$05,$06,$07
	.byte $00,$01,$02,$03 ;?          ? Placeholder?  Unused?
	.byte $04,$05,$06,$07

cdat2 ; next 32 characters.
	.byte $ff,$76,$2c,$34 ;bouncer.   Left/Right line end.
	.byte $2c,$76,$ff,$00
	.byte $00,$04,$0c,$14 ;а  A
	.byte $24,$5c,$44,$00
; ........
; .....*..
; ....**..
; ...*.*..
; ..*..*..
; .*.***..
; .*...*..
; ........
	.byte $00,$78,$44,$58 ;б  B
	.byte $44,$44,$5c,$00
	.byte $00,$3c,$40,$40 ;ц  C
	.byte $40,$40,$7c,$00
	.byte $00,$70,$48,$44 ;д  D
	.byte $44,$44,$5c,$00
	.byte $00,$7c,$40,$58 ;е  E
	.byte $40,$40,$7c,$00
	.byte $00,$7c,$40,$58 ;ф  F
	.byte $40,$40,$40,$00
	.byte $00,$3c,$40,$40 ;г  G
	.byte $44,$44,$7c,$00
	.byte $00,$44,$44,$5c ;х  H
	.byte $44,$44,$44,$00
	.byte $00,$10,$10,$10 ;и  I
	.byte $10,$10,$10,$00
	.byte $00,$08,$08,$08 ;й  J
	.byte $08,$08,$08,$30
	.byte $00,$44,$44,$58 ;к  K
	.byte $44,$44,$44,$00
	.byte $00,$40,$40,$40 ;л  L
	.byte $40,$40,$7c,$00
	.byte $00,$44,$2c,$54 ;м  M
	.byte $44,$44,$44,$00
	.byte $00,$44,$64,$54 ;н  N
	.byte $4c,$44,$44,$00
	.byte $00,$38,$44,$44 ;о  O
	.byte $44,$44,$38,$00

	.byte $00,$78,$44,$44 ;п  P
	.byte $58,$40,$40,$00
	.byte $00,$38,$44,$44 ;я  Q
	.byte $44,$40,$3c,$00
	.byte $00,$78,$44,$44 ;р  R
	.byte $58,$44,$44,$00
	.byte $00,$3c,$40,$38 ;с  S
	.byte $04,$04,$78,$00
	.byte $00,$7c,$00,$10 ;т  T
	.byte $10,$10,$10,$00
	.byte $00,$44,$44,$44 ;у  U
	.byte $44,$44,$38,$00
	.byte $00,$44,$44,$48 ;ж  V
	.byte $50,$60,$40,$00
	.byte $00,$44,$44,$44 ;в  W
	.byte $54,$2c,$44,$00
	.byte $00,$44,$44,$18 ;ь  X
	.byte $44,$44,$44,$00
	.byte $00,$44,$44,$44 ;ы  Y
	.byte $3c,$04,$38,$00
	.byte $00,$7c,$00,$08 ;з  Z
	.byte $10,$20,$7c,$00
	.byte $01,$02,$06,$0a ;mnt l .   Mountain Left
	.byte $18,$2a,$40,$a0
	.byte $80,$40,$a0,$30 ;mnt r .   Mountain Right
	.byte $28,$04,$26,$05
	.byte $00,$00,$00,$00 ;mnt top.  Mountain Top
	.byte $18,$3c,$6e,$ab
	.byte $ff,$11,$44,$00 ;grd lo .  Ground bottom line.
	.byte $00,$00,$00,$00
	.byte $99,$42,$99,$40 ;rnd hi .  Ground Top Line
	.byte $aa,$55,$ff,$00
	
