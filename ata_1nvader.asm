;*******************************************************************************
;*
;* C64 1NVADER - 2019 Darren Foulds
;*
;*******************************************************************************
;*
;* 1NVADER - Atari parody of C64 1NVADER game - 2020 Ken Jennings                        
;*                                                                             
;*******************************************************************************

; ==========================================================================
; Atari System Includes (MADS assembler)
	icl "ANTIC.asm" ; Display List registers
	icl "GTIA.asm"  ; Color Registers.
	icl "POKEY.asm" ;
	icl "PIA.asm"   ; Controllers
	icl "OS.asm"    ;
	icl "DOS.asm"   ; LOMEM, load file start, and run addresses.
; --------------------------------------------------------------------------

; ==========================================================================
; Macros (No code/data declared)
	icl "macros.asm"

; --------------------------------------------------------------------------

; ==========================================================================
; Declare some Page Zero variables.
; The Atari OS owns the first half of Page Zero.

; The Atari load file format allows loading from disk to anywhere in
; memory, therefore indulging in this evilness to define Page Zero
; variables and load directly into them at the same time...
; --------------------------------------------------------------------------

	ORG $80


; Game Control Values =========================================================
 
zNUMBER_OF_PLAYERS .byte $FF ; (0) 1 player. (1) 2 player. 
zGAME_OVER_FLAG    .byte $00 ; Set 0/1 for game over 
zSHOW_SCORE_FLAG   .byte $00 ; Flag to update score on screen.
zVIC_COLLISION     .byte $00 ; VIC II Sprite Collision Flag. (lda VIC_BASE+30)  (Atari has several registers).
  
zPLAYER_ONE_ON     .byte $00 ; (0) not playing. (1) playing.
zPLAYER_ONE_X      .byte $00 ; Player 1 gun X coord
zPLAYER_ONE_Y      .byte $00 ; Player 1 Y position (slight animation, but usually fixed.)
zPLAYER_ONE_DIR    .byte $00 ; Player 1 direction
zPLAYER_ONE_FIRE   .byte $00 ; Player 1 fire flag
zPLAYER_ONE_SCORE  .byte $00,$00,$00 ; Player 1 score, 6 digit BCD 
zPLAYER_ONE_COLOR  .byte $00 ; Player 1 current color

zLASER_ONE_X       .byte $00 ; Laser 1 X coord
zLASER_ONE_Y       .byte $00 ; Laser 1 Y coord

zPLAYER_TWO_ON     .byte $00 ; (0) not playing. (1) playing.
zPLAYER_TWO_X      .byte $00 ; Player 2 gun X coord
zPLAYER_TWO_Y      .byte $00 ; Player 2 Y position (slight animation, but usually fixed.)
zPLAYER_TWO_DIR    .byte $00 ; Player 2 direction
zPLAYER_TWO_FIRE   .byte $00 ; Player 2 fire flag
zPLAYER_TWO_SCORE  .byte $00,$00,$00 ; Player 2 score, 6 digit BCD 
zPLAYER_TWO_COLOR  .byte $00 ; Player 2 current color

zLASER_TWO_X       .byte $00 ; Laser 1 X coord
zLASER_TWO_Y       .byte $00 ; Laser 1 Y coord
 
zMOTHERSHIP_X               .byte $00 ; Game mothership X coord 
zMOTHERSHIP_Y               .byte $00 ; Game mothership Y coord 
zMOTHERSHIP_DIR             .byte $00 ; Mothership direction 
zMOTHERSHIP_MOVE_SPEED      .byte $00 ; Game mothership speed  
zMOTHERSHIP_MOVE_COUNTER    .byte $00 ; Game mothership speed counter 
zMOTHERSHIP_SPEEDUP_THRESH  .byte $00 ; Game mothership speed up threahold 
zMOTHERSHIP_SPEEDUP_COUNTER .byte $00 ; Game mothership speed up counter 
zMOTHERSHIP_ROW             .byte $00 ; Game mothership text line row number

zMOTHERSHIP_POINTS          .word $0000 ; Current Points for hitting mothership

zJOY_ONE_LAST_STATE .byte $00 ; Joystick Button One last state.
zJOY_TWO_LAST_STATE .byte $00 ; Joystick Button Two last state



zHIGH_SCORE        .byte $00,$00,$00 ; 6 digit BCD 

; Title Logo Values =========================================================

TITLE_LOGO_FRAME_MAX = 4 ; Five frames, Count 4, 3, 2, 1, 0

zTITLE_LOGO_FRAME .byte 0 ; current frame for big graphic logo


; Title Logo Values =========================================================

BIG_MOTHERSHIP_START = 108 ; Starting position of the big mothership

zBIG_MOTHERSHIP_Y .byte BIG_MOTHERSHIP_START


; Generic Player/Missile Data Copying =======================================

zPMG_IMAGE    .word 0 ; points to image data

zPMG_HARDWARE .word 0 ; points to the Player/Missile memeory map.


; Player/Missile object states.  X, Y, counts, etc where needed =============
; Note that each table is in the same order listing each visible 
; screen object for the Game.
; (Note the title screen components as the mother ship and the animated 
; logo are handled by special cases.)
; Lots of Page 0 still available, so let's just be lazy and clog this up.
; Note LDA zp,X  (two bytes) if we were thinking about code size.


PMG_MOTHERSHIP_ID = 0 ; Screen object ID values index each table below.
PMG_EXPLOSION_ID  = 1
PMG_CANNON_1_ID   = 2
PMG_CANNON_2_ID   = 3
PMG_LASER_1_ID    = 4
PMG_LASER_2_ID    = 5

zPMG_SAVE_CURRENT_ID .byte 0 ; Save ID to get around having to txa/pha/pla/tax

zTABLE_PMG_OLD_X
zPMG_OLD_MOTHERSHIP_X .byte 0 
zPMG_OLD_EXPLOSION_X  .byte 0 
zPMG_OLD_CANNON_1_X   .byte 0
zPMG_OLD_CANNON_2_X   .byte 0
zPMG_OLD_LASER_1_X    .byte 0
zPMG_OLD_LASER_2_X    .byte 0

zTABLE_PMG_NEW_X
zPMG_NEW_MOTHERSHIP_X .byte 0 
zPMG_NEW_EXPLOSION_X  .byte 0 
zPMG_NEW_CANNON_1_X   .byte 0
zPMG_NEW_CANNON_2_X   .byte 0
zPMG_NEW_LASER_1_X    .byte 0
zPMG_NEW_LASER_2_X    .byte 0

zTABLE_PMG_OLD_Y
zPMG_OLD_MOTHERSHIP_Y .byte 0 
zPMG_OLD_EXPLOSION_Y  .byte 0 
zPMG_OLD_CANNON_1_Y   .byte 0
zPMG_OLD_CANNON_2_Y   .byte 0
zPMG_OLD_LASER_1_Y    .byte 0
zPMG_OLD_LASER_2_Y    .byte 0

zTABLE_PMG_NEW_Y
zPMG_NEW_MOTHERSHIP_Y .byte 0 
zPMG_NEW_EXPLOSION_Y  .byte 0 
zPMG_NEW_CANNON_1_Y   .byte 0
zPMG_NEW_CANNON_2_Y   .byte 0
zPMG_NEW_LASER_1_Y    .byte 0
zPMG_NEW_LASER_2_Y    .byte 0

zTABLE_PMG_IMG_ID ; this does not change.
	.byte PMG_IMG_MOTHERSHIP_ID
	.byte PMG_IMG_EXPLOSION_ID
	.byte PMG_IMG_CANNON_ID
	.byte PMG_IMG_CANNON_ID
	.byte PMG_IMG_LASER_ID
	.byte PMG_IMG_LASER_ID

zTABLE_PMG_HARDWARE ; Page, high byte, for each displayed item.
	.byte >PLAYERADR2 ; Mothership
	.byte >PLAYERADR3 ; Explosion
	.byte >PLAYERADR0 ; Player 1 Cannon
	.byte >PLAYERADR1 ; Player 2 Cannon
	.byte >PLAYERADR0 ; Player 1 Laser
	.byte >PLAYERADR1 ; Player 2 Laser


; Game Screen Stars Control values ==========================================

zDL_LMS_STARS_ADDR .word 0 ; points to the LMS to change

zTEMP_NEW_STAR_ID  .byte 0 ; gives the star 3, 2, 1, 0

zTEMP_NEW_STAR_ROW .byte 0 ; Row number for star 0 to 17.

zTEMP_ADD_STAR     .byte 0 ; Flag, 0 = no star to add.  !0 = Try adding a new star.

zTEMP_BASE_COLOR   .byte 0 ; temporary color for star
zTEMP_BASE_COLOR2  .byte 0 ; temporary color for star


zSTAR_COUNT        .byte 0 ; starcnt original code.


; Game Over Text Values =====================================================

zGAME_OVER_TEXT .word 0


DisplayPointer .word $0000 ; Stream of bytes to read.
DisplaySize    .word $0000 ; Number of bytes to encode.
OutputPointer  .word $0000 ; Pointer to memory to generate RLE codes.

; ======== E N D   O F   P A G E   Z E R O ======== 

; Now for the Code...
; Should be the first usable memory after DOS (and DUP?).

	ORG LOMEM_DOS
;	ORG LOMEM_DOS_DUP ; Use this if following DOS won't work.  or just use $5000 or $6000

	; Label And Credit Where Ultimate Credit Is Due
	.by "** Thanks to the Word (John 1:1), Jesus Christ, Creator of heaven, "
	.by "and earth, and semiconductor chemistry and physics making all this "
	.by "fun possible. "
	.by "** ATARI 1NVADER "
	.by "** Atari 8-bit computer systems. "
	.by "** Ken Jennings  2020 **"


;*******************************************************************************
;*                                                                             *
;* Assembly Reference Variables                                               *
;*                                                                             *
;*******************************************************************************

;         *= $4000

;v        = 53248
;joy      = 56320
cm       = $0400    ; screen memory
ticm     = $04f0
ticc     = $d8f0
ticc2    = $d811
scrloc   = $0658    ; scroll text loc
cm2      = $04f0    ; was $0662/$0702
cm3      = $05e0
cm4      = $06d0
br       = $07c0    ; bottom row of txt
mountsm  = $06f8    ; mount screen mem
mountcm  = $daf8    ; mount colour mem

cmem0    = $2000
cmem1    = $2100
cmem2    = $2200
cmem3    = $2300
cmem4    = $2400
cmem5    = $2500
cmem6    = $2600
cmem7    = $2700

cset0    = $d000    ; this is where
cset1    = $d100    ; the 6510 sees
cset2    = $d200    ; the char data
cset3    = $d300    ; under the жиц (ROM)
cset4    = $d400
cset5    = $d500
cset6    = $d600
cset7    = $d700

sf1      = $0428
sf2      = $0530    ; +8 to fill botrow

sprmem1  = $3200    ; sprite memory
sprmem2  = $3240
sprmem3  = $3280
sprmem4  = $32c0

;-- inv516a ----------------------------

; ==========================================================================
; Include all the code parts . . .

	icl "ata_1nv_gfx.asm"  ; Data for Display Lists and Screen Memory (2K)

	icl "ata_1nv_cset.asm" ; Data for custom character set (1K space)

	icl "ata_1nv_pmg.asm"  ; Data for Player/Missile graphics (and reserve the bitmap).

; --------------------------------------------------------------------------





;-- setup ------------------------------

         lda #147
         jsr $ffd2  ; clear screen

         lda #0
         sta $d020  ; border colour
         lda #0
         sta $d021  ; screen colour

         lda #1
         sta $0286  ; character colour

         lda #1     ; colour the screen
         ldx #0     ; col mem white
colscr   sta $d800,x
         sta $d8c8,x
         sta $d990,x
         sta $da58,x
         sta $db20,x
         inx
         cpx #200
         bne colscr

         jsr charsetup
         jsr sprsetup

         sei        ; turn on interupts

         lda #200   ; sprite pointers
         sta $07f8  ; ms
         lda #201
         sta $07f9  ; p1
         sta $07fa  ; p2
         lda #202
         sta $07fb  ; l1
         sta $07fc  ; l2

       ; jsr drawrows
         jsr drawmounts

;-- title ------------------------------

title    jsr titlinit ; new game setup

         lda #148   ; set p1+2 x+y
         sta zPLAYER_ONE_X
         lda #196
         sta zPLAYER_TWO_X
         lda #242   ; zPLAYER_ONE_Y zPLAYER_TWO_Y
         sta zPLAYER_ONE_Y    ; touching bottom
         sta zPLAYER_TWO_Y
         lda #160   ; set ms x+y
         sta zMOTHERSHIP_X
         lda #146   ; was 58
         sta zMOTHERSHIP_Y
         lda #11
         sta zMOTHERHIP_ROW  ; row 11 = 146

         lda #1     ; make ms биг
         sta v+29   ; expand x
         sta v+23   ; expand y
         sta zSHOW_SCORE_FLAG
         jsr showscr; show score

                    ; should be 7
         lda #7     ; ms +p1 +p2 +xx +xx
         sta v+21   ; turn on sprites
         jsr outp1
         jsr outp2
       ; jsr outms  ; don't work no more
         lda zMOTHERSHIP_X    ; do it manually
         sta v
         lda zMOTHERSHIP_Y
         sta v+1
         lda zMOTHERSHIP_COLOR
         sta v+39

       ; lda #1
       ; sta charcol
       ; jsr coltitle

         jsr tistripe
         jsr drawtitle
         jsr clrstats

       ; jsr soundend

         lda #0
         sta scrcnt

titlea   jsr vbwait

         inc scrjifs
         lda scrjifs
         cmp #4       ; 3 too fast?
         bne scr99
         lda #0
         sta scrjifs

         ldx scrcnt
         ldy #0       ; print 40 chars
scr02    lda GFX_SCROLL_DOCS,x ; startin at
         sta scrloc,y ; scrcnt
         inx
         iny
         cpy #40      ; 40 chars
         bne scr02

         inc scrcnt
scr99
       ; jsr twinkle
         jsr ticolrol ; fancy title fx

         jsr fire1  ; get p1 fire
         lda zPLAYER_ONE_FIRE    ; check p1f
         cmp #1
         bne titleb ; no fire
         lda #1     ; fire p1 start
         sta zPLAYER_ONE_ON
         lda #234   ; pop up p1
         sta zPLAYER_ONE_Y
         jsr outp1
         jmp clrscr ; begin gameinit
titleb   jsr fire2  ; get p2 fire
         lda zPLAYER_TWO_FIRE    ; check p2f
         cmp #1
         bne titlea ; no fire wait
         lda #1     ; fire p2 start
         sta zPLAYER_TWO_ON
         lda #234   ; pop up p2
         sta zPLAYER_TWO_Y
         jsr outp2

clrscr   lda #32    ; clear scroll
         ldy #0
clrscr2  sta scrloc,y
         iny
         cpy #40
         bne clrscr2

titlez   jmp gamestrt

drawtitle ldx #0    ; draw title
drawti2  lda tichar,x
         sta ticm,x
         inx
         cpx #240
         bne drawti2
         rts

clrtitl  ldx #0     ; clear the title
         lda #32
clrtitl2 sta ticm,x
         inx
         cpx #240
         bne clrtitl2
         rts

coltitle ldx #0
         lda charcol
colti2   sta ticc,x
         inx
         cpx #240
         bne colti2
         rts

drawmounts          ; draw mountains
         ldx #0

drwmtsa  lda mountc,x
         sta mountsm,x

         lda #11    ; default = grey
         sta mountcm,x

         lda mountc,x
         cmp #$5d   ; is it a peak?
         bne drwmtsd
         lda #15    ; white
         sta mountcm,x

drwmtsd  inx
         cpx #240
         bne drwmtsa

         ldx #160
         lda #9
drwmtsb  sta mountcm,x
         inx
         cpx #200
         bne drwmtsb

         lda #8
drwmtsc  sta mountcm,x
         inx
         cpx #240
         bne drwmtsc

         lda #5
         ldx #160
         sta mountcm,x
         ldx #199
         sta mountcm,x

         lda #3        ; colour stats
         ldx #215
drwmtse  sta mountcm,x
         inx
         cpx #225
         bne drwmtse

         rts

tistripe          ; striped title colour
         ldx #0
         ldy #0
tsta     cpy #0    ; 0 is black
         bne tstb
         lda #6    ; 0
         jmp tstx
tstb     cpy #1    ; 1 is dark grey
         bne tstc
         lda #11   ; 11
         jmp tstx
tstc     cpy #2    ; 2 is med grey
         bne tstd
         lda #12   ; 12
         jmp tstx
tstd     cpy #3    ; 3 is lite grey
         bne tste
         lda #15   ; 15
         jmp tstx
tste     cpy #4    ; 4 is white
         bne tstf
         lda #1
         jmp tstx
tstf     lda #4    ; leftover 4=purple
tstx     sta ticc,x ; change the colour
         iny
         cpy #6
         bne tsty
         ldy #0
tsty     inx      ; 200 leaves last line
         cpx #160 ; 240 for all
         bne tsta
tstz     rts

ticolrol ldx #0    ; roll the title col
tcra     inc ticc,x
         inx
         cpx #240
         bne tcra
tcrz     rts

;-- game init --------------------------

titlinit lda #0
         sta zGAME_OVER_FLAG
         sta zPLAYER_ONE_DIR
         sta zPLAYER_ONE_FIRE
         sta zPLAYER_TWO_FIRE
         sta zPLAYER_ONE_ON
         sta zPLAYER_TWO_ON
         sta zMOTHERSHIP_X+1
         sta zPLAYER_ONE_X+1
         sta zPLAYER_TWO_X+1
         sta zMOTHERHIP_ROW

         lda #1
         sta zPLAYER_TWO_DIR
         sta zMOTHERSHIP_DIR
         sta zJOY_ONE_LAST_STATE
         sta zJOY_TWO_LAST_STATE
         sta zSHOW_SCORE_FLAG

         lda #2
         sta zMOTHERSHIP_COLOR

         lda #13
         sta zPLAYER_ONE_COLOR

         lda #14
         sta zPLAYER_TWO_COLOR

         lda #148
         sta zPLAYER_ONE_X

         lda #172
         sta zMOTHERSHIP_X

         lda #196
         sta zPLAYER_TWO_X

         lda #242    ; touching bottom
         sta zPLAYER_ONE_Y
         sta zPLAYER_TWO_Y

         rts

gameinit sed
         lda #0
         sta zPLAYER_ONE_SCORE
         sta zPLAYER_ONE_SCORE+1
         sta zPLAYER_ONE_SCORE+2
         sta zPLAYER_TWO_SCORE
         sta zPLAYER_TWO_SCORE+1
         sta zPLAYER_TWO_SCORE+2
         cld

         sed
         lda #128   ; 128 = 80
         sta hits
         lda #0
         sta hits+1
         cld

         lda #0
         sta zPLAYER_ONE_BUMP
         sta zPLAYER_TWO_BUMP

         lda #1
         sta zSHOW_SCORE_FLAG
         jsr showscr
                     ; should be 2
         lda #2      ; initial ms speed
         sta zMOTHERSHIP_MOVE_SPEED
         lda #10     ; should be 10
         sta zMOTHERHIP_SPEEDUP_THRESH   ; speedup threshld
         sta zMOTHERHIP_SPEEDUP_COUNTER   ; speedup count
gameintz rts

cntdwn               ; wait for other p
         lda #51     ; seconds 51-48=3s
         sta secs
         sbc #15     ; get wide chars
         sta cm+179  ; shw cntdwn secs
         adc #2
         sta cm+180  ; other half
         lda #29     ; jiffys 0.5 secs
         sta jifs

cntdwna  jsr ticolrol;  >title fx

         dec jifs
         lda jifs
         cmp #0

         bne cntdwnb ; go wait

                     ; decrease secs
         lda #29     ; reset jifs
         sta jifs
         dec secs    ; secs=secs-1
         lda secs
         cmp #48     ; 48 = '0'

         beq cntdwne ; lets play

         sbc #16     ; wide numbers
         sta cm+179  ; show secs
         adc #2
         sta cm+180  ; other half

cntdwnb  jsr vbwait  ; wait 1 frame
         lda zPLAYER_ONE_ON     ; need to chk?
         cmp #1
         beq cntdwnc ; nope go away
         jsr fire1   ; yes we do
         inc v+40    ; rainbow if check
         lda zPLAYER_ONE_FIRE
         cmp #1      ; check p1 fire
         bne cntdwnc ; no
         lda #1      ; yes join game
         sta zPLAYER_ONE_ON     ; p1ztatus
         lda #234    ; bump p1 up
         sta zPLAYER_ONE_Y
         jsr outp1
cntdwnc  lda zPLAYER_TWO_ON     ; need to chk?
         cmp #1
         beq cntdwnd ; nope go away
         jsr fire2   ; yes we do
         inc v+41    ; rainbow if check
         lda zPLAYER_TWO_FIRE
         cmp #1      ; check p2 fire
         bne cntdwnd ; no
         lda #1      ; yes join game
         sta zPLAYER_TWO_ON     ; p2ztatus
         lda #234    ; bump p2 up
         sta zPLAYER_TWO_Y
         jsr outp2
cntdwnd  jmp cntdwna

cntdwne  lda #$47    ; print "го"
         sta cm+179  ;
         lda #$4f
         sta cm+180
                     ; slide stuff away
cntdwni  jsr ticolrol
         jsr vbwait
         dec zMOTHERSHIP_Y     ; silde ms up
         dec zMOTHERSHIP_Y
       ; jsr outms   ; won't work with
                     ; raw msy. must use
                     ; msrow
                     ; do it manually
         lda zMOTHERSHIP_Y     ; get msy
         sta v+1     ; set spr1 y


cntdsp1  lda zPLAYER_ONE_ON
         cmp #1
         beq cntdsp2
         lda zPLAYER_ONE_Y     ; slide p1
         cmp #250
         beq cntdsp2 ; already off scrn
         inc zPLAYER_ONE_Y
         jsr outp1

cntdsp2  lda zPLAYER_TWO_ON
         cmp #1
         beq cntdsz
         lda zPLAYER_TWO_Y     ; slide p2
         cmp #250    ; y=250
         beq cntdsz  ; already off scrn
         inc zPLAYER_TWO_Y
         jsr outp2

cntdsz   lda zMOTHERSHIP_Y
         cmp #32     ; should be off top
         bne cntdwni

                     ; reset ms stuff
cntdwnj  lda #0      ; reset ms x,y
         sta v+29    ; expand
         sta v+23    ; (for ms)
         sta zMOTHERSHIP_X
         sta zPLAYER_ONE_FIRE
         sta zPLAYER_TWO_FIRE
         sta zLASER_ONE_ON
         sta zLASER_TWO_ON
         sta zMOTHERHIP_ROW

       ; lda #58     ; should be 58
       ; sta zMOTHERSHIP_Y     ; 202 for testing
         ldx zMOTHERHIP_ROW   ; get msy from
         lda TABLE_ROW_TO_Y,x  ; row 2 y table
         sta zMOTHERSHIP_Y

         lda #2
         sta zMOTHERSHIP_COLOR   ; ms is red
         jsr getpoints
         lda #1
         sta zSHOW_SCORE_FLAG
         jsr showscr

         lda #32      ; clear
         sta cm+179   ; countdown
         sta cm+180

         jsr clrtitl  ; clear title txt
       ; lda #0       ; black color mem
       ; sta charcol  ; set 0=black
       ; jsr coltitle ; color title blk

cntdwnz  rts

;-- game loop --------------------------

gamestrt jsr gameinit
         jsr cntdwn
gameloop jsr vbwait
       ; lda v+30    ; get colision reg
       ; sta v30     ; save to chk latr
         jsr input
         jsr process
         jsr output
         lda zGAME_OVER_FLAG  ; chk gameover flg
         cmp #1
         bne gameloop
         jmp gameover

vbwait  ;inc $d020   ; timing colour
vbwaita  lda $d012
         cmp #251
         bne vbwaita
        ;dec $d020   ; timing colour
         lda v+30    ; get col reg
         sta zVIC_COLLISION     ; save to v30
         rts

;-- input ------------------------------

input    lda zPLAYER_ONE_ON     ; get p1 ztatus
         cmp #1
         bne inputd  ; skip if p1 off

         lda zLASER_ONE_ON     ; chk lazer status
         cmp #0      ; lazer is off, ок
         beq inputa
         lda zLASER_ONE_Y     ; chk lazer hight
         sbc #151    ; is zLASER_ONE_Y < 150 ?
         bcc inputa  ; yes, ок
         jmp inputd

inputa   jsr fire1

inputd   lda zPLAYER_TWO_ON     ; get p2 ztatus
         cmp #1
         bne inputz  ; skip if p2 off

         lda zLASER_TWO_ON
         cmp #0      ; lazer of, ок
         beq inpute
         lda zLASER_TWO_Y
         sbc #151    ; is zLASER_TWO_Y < 200 ?
         bcc inpute  ; yes, ок
         jmp inputz

inpute   jsr fire2

inputz   rts

fire1    lda joy+1   ; remember: 0=fire
         and #16
         cmp #0
         beq f1maybe
f1nope   lda #0      ; lastcycle=nofire
         sta zJOY_ONE_LAST_STATE
         rts
f1maybe  lda zJOY_ONE_LAST_STATE
         cmp #0
         bne f1nope2
         lda #1      ; set p1f═банг!
         sta zPLAYER_ONE_FIRE
         sta zJOY_ONE_LAST_STATE
         jsr lazbeep1; fire ноисе!
         rts
f1nope2  lda #0
         sta zPLAYER_ONE_FIRE
         rts

fire2    lda joy     ; remember: 0=fire
         and #16
         cmp #0
         beq f2maybe
f2nope   lda #0      ; lastcycle=nofire
         sta zJOY_TWO_LAST_STATE
         rts
f2maybe  lda zJOY_TWO_LAST_STATE
         cmp #0
         bne f2nope2
         lda #1      ; set p2f═банг!
         sta zPLAYER_TWO_FIRE
         sta zJOY_TWO_LAST_STATE     ; lastcycle=fire
         jsr lazbeep2 ; p2 ноисе!
         rts
f2nope2  lda #0
         sta zPLAYER_TWO_FIRE
         rts

;-- process ----------------------------

process
       ; jsr prolzhit
         jsr prohit
         jsr prolazer
         jsr proms
         jsr bump     ; bump is player
         jsr bounce   ; bounce is wall
         lda zPLAYER_ONE_ON
         cmp #1
         bne processa
         jsr prop1
processa lda zPLAYER_TWO_ON
         cmp #1
         bne processb
         jsr prop2
processb jsr proreset
         rts

       ; ------------- new lazer hit
prohit   lda zLASER_ONE_ON
         cmp #0      ; is l1 off?
         beq plh1a
         cmp #12     ; is l1 on?
         beq plh1b
         jmp plh1c

plh1a    lda #0      ; zLASER_ONE_ON=0 off
         sta zLASER_ONE_ON
         lda #202    ; laz sprite
         sta $07fb
         jmp plh2

plh1b    lda #202    ; zLASER_ONE_ON=12 on&up
         sta $07fb   ; laz sprite

         lda zVIC_COLLISION     ; chk collision
         and #9
         cmp #9      ; s1(ms) + s4(l1)
         bne plh2    ; no hit, check l2

         dec zLASER_ONE_ON     ; hit═!!!
         sed         ; add p1score
         clc
         lda zPLAYER_ONE_SCORE
         adc zMOTHERSHIP_POINTS   ; from getpoints
         sta zPLAYER_ONE_SCORE
         lda zPLAYER_ONE_SCORE+1
         adc zMOTHERSHIP_POINTS+1 ; from getpoints
         sta zPLAYER_ONE_SCORE+1
         lda zPLAYER_ONE_SCORE+2
         adc #0      ; carry if needed
         sta zPLAYER_ONE_SCORE+2

         sec
         lda hits    ; decrease hits
         sbc #1
         sta hits
         lda hits+1
         sbc #0
         sta hits+1
         cld

         jmp lzhitb  ; goto pop ms up
       ; jmp plh2

plh1c    dec zLASER_ONE_ON     ; 12<zLASER_ONE_ON>0 exp
         lda #203    ; exp sprite
         sta $07fb   ;
         jmp plh2

       ; ------------- lazer 2 hit check
plh2     lda zLASER_TWO_ON
         cmp #0      ; is l2 off?
         beq plh2a
         cmp #12     ; is l2 on?
         beq plh2b
         jmp plh2c

plh2a    lda #0      ; zLASER_TWO_ON=0 off
         sta zLASER_TWO_ON
         lda #202    ; laz sprite
         sta $07fc
         jmp prohitz

plh2b    lda #202    ; zLASER_TWO_ON=12 on&up
         sta $07fc   ; laz sprite

         lda zVIC_COLLISION     ; chk collision
         and #17
         cmp #17     ; s1(ms) + s5(l1)
         bne prohitz ; no hit, done

         dec zLASER_TWO_ON     ; hit═!!!
         sed         ; add p2score
         clc
         lda zPLAYER_TWO_SCORE
         adc zMOTHERSHIP_POINTS   ; from getpoints
         sta zPLAYER_TWO_SCORE
         lda zPLAYER_TWO_SCORE+1
         adc zMOTHERSHIP_POINTS+1 ; from getpoints
         sta zPLAYER_TWO_SCORE+1
         lda zPLAYER_TWO_SCORE+2
         adc #0      ; carry if needed
         sta zPLAYER_TWO_SCORE+2

         sec
         lda hits    ; decrease hits
         sbc #1
         sta hits
         lda hits+1
         sbc #0
         sta hits+1
         cld

         jmp lzhitb  ; goto pop ms up
       ; jmp prohitz

plh2c    dec zLASER_TWO_ON     ; 12<zLASER_TWO_ON>0 exp
         lda #203    ; exp sprite
         sta $07fc   ;
         jmp prohitz

prohitz  rts
       ; ------------- end new prohit

prolzhit             ; was ms hit?
         lda zLASER_ONE_ON
         cmp #0
         beq lz2hit  ; l1 off, check l2
         cmp #1
         beq plz1a   ; goto active lz1

         lda #203    ; explosion stuff
         sta $07fb   ; exp sprite on
         dec zLASER_ONE_ON
         lda zLASER_ONE_ON
         cmp #1
         bne plz1b
         lda #0      ; turn off exp
         sta zLASER_ONE_ON
         lda #202    ; lz sprite on
         sta $07fb

plz1b    jmp lz2hit

plz1a    lda zVIC_COLLISION     ; get collision
         and #9
         cmp #9      ; s1(ms) + s4(l1)
         bne lz2hit  ; no hit, check l2
         sed         ; add p1score
         clc
         lda zPLAYER_ONE_SCORE
         adc zMOTHERSHIP_POINTS   ; from getpoints
         sta zPLAYER_ONE_SCORE
         lda zPLAYER_ONE_SCORE+1
         adc zMOTHERSHIP_POINTS+1 ; from getpoints
         sta zPLAYER_ONE_SCORE+1
         lda zPLAYER_ONE_SCORE+2
         adc #0      ; carry if needed
         sta zPLAYER_ONE_SCORE+2

         sec
         lda hits    ; decrease hits
         sbc #1
         sta hits
         lda hits+1
         sbc #0
         sta hits+1

         cld
         lda #12     ; was 0
         sta zLASER_ONE_ON     ; turn off l1
         jmp lzhitb  ; goto kill ms
lz2hit
         lda zLASER_TWO_ON
         cmp #0
       ; bne lz2hita
         bne plz1e
         jmp lzhitz

plz1e    cmp #1
         beq lz2hita ; goto active lz2

         lda #203    ; explosion stuff
         sta $07fc   ; exp sprite on
         dec zLASER_TWO_ON
         lda zLASER_TWO_ON
         cmp #1
         bne plz1c
         lda #0      ; turn off exp
         sta zLASER_TWO_ON
         lda #202    ; lz sprite on
         sta $07fc

plz1c    jmp lzhitz  ; l2 off, done

lz2hita  lda zVIC_COLLISION     ; get collision
         and #17
         cmp #17     ; s1(ms) + s5(l2)
         beq lz2hitb
         jmp lzhitz  ; no hit
lz2hitb  sed         ; add p2score
         clc
         lda zPLAYER_TWO_SCORE
         adc zMOTHERSHIP_POINTS
         sta zPLAYER_TWO_SCORE
         lda zPLAYER_TWO_SCORE+1
         adc zMOTHERSHIP_POINTS+1
         sta zPLAYER_TWO_SCORE+1
         lda zPLAYER_TWO_SCORE+2
         adc #0      ; carry if needed
         sta zPLAYER_TWO_SCORE+2

         sec
         lda hits    ; decrease hits
         sbc #1
         sta hits
         lda hits+1
         sbc #0
         sta hits+1

         cld
         lda #12     ; was 0
         sta zLASER_TWO_ON     ; turn off l2

       ; ------------- kill mothership
lzhitb               ; ms was hit, popup
         jsr expnoz  ; make ноисе
         dec zMOTHERHIP_SPEEDUP_COUNTER   ; speedup counter
         lda zMOTHERHIP_SPEEDUP_COUNTER
         cmp #0      ; time to speedup?
         bne lzhite  ; no
         inc zMOTHERSHIP_MOVE_SPEED  ; yes
         lda zMOTHERSHIP_MOVE_SPEED
         cmp #10     ; is msmovs = 10
         bne lzhitr  ; no
         lda #2      ; yes, relief!
         sta zMOTHERSHIP_MOVE_SPEED  ; set msmovs = 2
         lda #128    ; 128 = 80bcd
         sta hits    ; reset hit cout

lzhitr   lda zMOTHERHIP_SPEEDUP_THRESH
         sta zMOTHERHIP_SPEEDUP_COUNTER   ; reset counter
lzhite   lda #1
         sta zSHOW_SCORE_FLAG  ; set ssflag
       ; lda zMOTHERSHIP_Y     ; pop ms up 16px
       ; sbc #16
       ; sta zMOTHERSHIP_Y
         sed         ; set dec flag
         clc
         lda zMOTHERHIP_ROW   ; why sbc #1 ?????
         sbc #1      ; pop msrow up 2
         sta zMOTHERHIP_ROW
         cld         ; clr dec flag
         lda #30     ; check msrow
         cmp zMOTHERHIP_ROW   ; is msrow < 30?
         bcs lzhitf  ; no, skip
         lda #0      ; yes, make it 0
         sta zMOTHERHIP_ROW
lzhitf ; lda #58     ; is msy >= 58?
       ; cmp zMOTHERSHIP_Y
       ; bcc lzhitc  ; yes, go away
       ; lda #58     ; no, make it 58
       ; sta zMOTHERSHIP_Y
       ; lda #0      ; msrow to 0 too
       ; sta zMOTHERHIP_ROW
lzhitc   jsr getpoints ; set new x
         lda zMOTHERSHIP_DIR     ; check msd
         bne lzhitd
         sta zMOTHERSHIP_X     ; was going left
         sta zMOTHERSHIP_X+1   ; msx x=0
         lda #1      ; go right
         sta zMOTHERSHIP_DIR
         jmp lzhitz
lzhitd   lda #1      ; was going right
         sta zMOTHERSHIP_X+1
         lda #89     ; msx x=344
         sta zMOTHERSHIP_X
         lda #0      ; go left
         sta zMOTHERSHIP_DIR
lzhitz   rts

prolazer
         lda zLASER_ONE_ON
       ; cmp #0
       ; beq lazera
         cmp #12     ; zLASER_ONE_ON=12 active laz
         bne lazera  ; only zLASER_ONE_ON goes up
         lda zLASER_ONE_Y     ; l1 up
         sbc #4
         sta zLASER_ONE_Y
         cmp #50
         bne lazera
         lda #0
         sta zLASER_ONE_ON     ; l1 off
         lda #202    ; use lz sprite
         sta $07fb   ; not exp

lazera   lda zLASER_TWO_ON
       ; cmp #0
       ; beq lazerz
         cmp #12     ;zLASER_TWO_ON=12 active laz
         bne lazerz
         lda zLASER_TWO_Y     ; l2 up
         sbc #4
         sta zLASER_TWO_Y
         lda zLASER_TWO_Y
         cmp #50
         bne lazerz
         lda #0
         sta zLASER_TWO_ON     ; l2 off
         lda #202    ; use lz sprite
         sta $07fc   ; not exp
lazerz   rts

proms    lda zMOTHERSHIP_MOVE_SPEED ; loop this ammount
         sta zMOTHERSHIP_MOVE_COUNTER    ; msm is counter
procmsm  lda zMOTHERSHIP_MOVE_COUNTER
         cmp #0
         beq procmsz ; done moving ms
         jsr promsdo ; do the real move
         dec zMOTHERSHIP_MOVE_COUNTER
         jmp procmsm ; loop again
procmsz  rts

promsdo  lda zMOTHERSHIP_DIR     ; this is the move
         cmp #0      ; routine for real
         beq pmslt
pmsrt    inc zMOTHERSHIP_X     ; move right
         bne pmsbc
         inc zMOTHERSHIP_X+1
         jmp pmsbc
pmslt    lda zMOTHERSHIP_X+1   ; move left
         bne pmslta
         dec zMOTHERSHIP_X     ; < 256
         jmp pmsbc
pmslta   dec zMOTHERSHIP_X     ; > 255
         lda zMOTHERSHIP_X
         cmp #255
         beq pmsltb
         jmp pmsbc
pmsltb   dec zMOTHERSHIP_X+1   ; dec msx+1
         jmp pmsbc
pmsbc    lda zMOTHERSHIP_DIR     ; ms bounce
         cmp #0
         beq msbltr
msbrtl   lda zMOTHERSHIP_X+1   ; bounce off right
         cmp #0
         beq promszz ; skip
         lda zMOTHERSHIP_X
         cmp #89     ; 89+255=344
         bne promszz ; skip
         lda #0
         sta zMOTHERSHIP_DIR     ; set msd=0(left)
       ; lda zMOTHERSHIP_Y     ; drop down
       ; clc
       ; adc #8
       ; sta zMOTHERSHIP_Y
         sed         ; drop down msrow
         clc         ; set dec+clr carry
         lda zMOTHERHIP_ROW
         adc #1
         sta zMOTHERHIP_ROW
         cld         ; clr dec flag
         jsr getpoints ; update points
         jmp promsz
msbltr   lda zMOTHERSHIP_X+1   ; bounce off left
         cmp #0
         bne promszz ; msx+1 set, skip
         lda zMOTHERSHIP_X     ; check msx
         cmp #0
         bne promszz ; msx<>0, skip
         lda #1
         sta zMOTHERSHIP_DIR     ; set msd=1(right)
       ; lda zMOTHERSHIP_Y     ; drop down
       ; clc
       ; adc #8
       ; sta zMOTHERSHIP_Y
         sed         ; drop msrow down
         clc         ; set dec+clr carry
         lda zMOTHERHIP_ROW
         adc #1
         sta zMOTHERHIP_ROW
         cld         ; clr dec flag
         jsr getpoints ; update points
         jmp promsz
promsz ; lda zMOTHERSHIP_Y     ; check bottom
       ; cmp #234
         lda zMOTHERHIP_ROW
         cmp #34
         bcs promsb  ; row = 23 (бцд 34)
       ; bcs promsb  ; >= 234
         jmp promszz ; < 234
promsb   lda #1      ;
         sta zGAME_OVER_FLAG
promszz  rts

bump                 ; p1/p2 bump check
         lda zPLAYER_ONE_ON     ; no p1 dont bump
         cmp #1
         bne bumpz
         lda zPLAYER_TWO_ON     ; no p2 dont bump
         cmp #1
         bne bumpz
         lda zVIC_COLLISION     ; get sp collision
         and #6      ; 2+4=6
         cmp #6
         bne bumpz
         lda zPLAYER_ONE_DIR
         cmp #0
         bne bumpa
         sta zPLAYER_TWO_DIR     ; p1 on right
         lda #1
         sta zPLAYER_ONE_DIR
         sta zPLAYER_ONE_BUMP    ; set bump flags
         sta zPLAYER_TWO_BUMP
         jmp bumpz
bumpa    sta zPLAYER_TWO_DIR     ; p2 on left
         lda #0
         sta zPLAYER_ONE_DIR
         lda #1
         sta zPLAYER_ONE_BUMP    ; set bump flags
         sta zPLAYER_TWO_BUMP
bumpz    rts

bounce   lda zPLAYER_ONE_DIR     ; p1 bounce
         cmp #0
         beq p1bltr
p1brtl   lda zPLAYER_ONE_X+1
         cmp #0
         beq bouncep2
         lda zPLAYER_ONE_X     ; x=255+65=320
         cmp #65     ;     right wall
         bne bouncep2
         lda #0
         sta zPLAYER_ONE_DIR
         lda #1
         sta zPLAYER_ONE_BUMP    ; set bounce flg
         jmp bouncep2
p1bltr   lda zPLAYER_ONE_X+1
         cmp #0
         bne bouncep2
         lda zPLAYER_ONE_X
         cmp #24     ; x=24 left wall
         bne bouncep2
         lda #1
         sta zPLAYER_ONE_DIR
         sta zPLAYER_ONE_BUMP    ; set bounce flg
bouncep2 lda zPLAYER_TWO_DIR     ; p2 bounce
         cmp #0      ; same as p1
         beq p2bltr
p2brtl   lda zPLAYER_TWO_X+1
         cmp #0
         beq bouncez
         lda zPLAYER_TWO_X
         cmp #65
         bne bouncez
         lda #0
         sta zPLAYER_TWO_DIR
         lda #1
         sta zPLAYER_TWO_BUMP    ; set bounce flg
         jmp bouncez
p2bltr   lda zPLAYER_TWO_X+1
         cmp #0
         bne bouncez
         lda zPLAYER_TWO_X
         cmp #24
         bne bouncez
         lda #1
         sta zPLAYER_TWO_DIR
         sta zPLAYER_TWO_BUMP    ; set bounce flag
bouncez  rts

prop1    lda zPLAYER_ONE_FIRE
         cmp #1      ; check p1 fire
         beq prop1a
         jmp pp1move
prop1a   lda zPLAYER_ONE_BUMP    ; check bump flag
         cmp #1      ; if bump
         beq prop1fyr; skip dir change
         lda zPLAYER_ONE_DIR     ; change direction
         cmp #0
         beq prop1d
         lda #0      ; change to left
         sta zPLAYER_ONE_DIR
         jmp prop1fyr
prop1d   lda #1      ; change to right
         sta zPLAYER_ONE_DIR
         jmp prop1fyr
prop1fyr             ; fire laser
         lda #12
         sta zLASER_ONE_ON
         lda zPLAYER_ONE_X
         sta zLASER_ONE_X
         lda zPLAYER_ONE_X+1
         sta zLASER_ONE_X+1
         lda #226
         sta zLASER_ONE_Y
         jmp pp1move
pp1move
         lda zPLAYER_ONE_DIR
         cmp #0
         beq pp1lt
pp1rt    inc zPLAYER_ONE_X     ; move right
         bne pp1bc
         inc zPLAYER_ONE_X+1
         jmp pp1bc
pp1lt    lda zPLAYER_ONE_X+1   ; move left
         bne pp1lta
         dec zPLAYER_ONE_X     ; < 256
         jmp pp1bc
pp1lta   dec zPLAYER_ONE_X     ; > 255
         lda zPLAYER_ONE_X
         cmp #255
         beq pp1ltb
         jmp pp1bc
pp1ltb   dec zPLAYER_ONE_X+1  ; it happens earlyr
         jmp pp1bc  ; its not here now
pp1bc    jmp prop1z ; leftover bounce
prop1z   rts

prop2    lda zPLAYER_TWO_FIRE
         cmp #1
         beq prop2a
         jmp pp2move
prop2a   lda zPLAYER_TWO_BUMP    ; check bump flag
         cmp #1      ; if set
         beq prop2fyr; skip dir change
         lda zPLAYER_TWO_DIR     ; change direction
         cmp #0
         beq prop2d
         lda #0
         sta zPLAYER_TWO_DIR
         jmp prop2fyr
prop2d   lda #1
         sta zPLAYER_TWO_DIR
         jmp prop2fyr
prop2fyr
         lda #12
         sta zLASER_TWO_ON
         lda zPLAYER_TWO_X
         sta zLASER_TWO_X
         lda zPLAYER_TWO_X+1
         sta zLASER_TWO_X+1
         lda #226
         sta zLASER_TWO_Y
         jmp pp2move
pp2move
         lda zPLAYER_TWO_DIR
         cmp #0
         beq pp2lt
pp2rt    inc zPLAYER_TWO_X
         bne pp2bc
         inc zPLAYER_TWO_X+1
         jmp pp2bc
pp2lt    lda zPLAYER_TWO_X+1
         bne pp2lta
         dec zPLAYER_TWO_X
         jmp pp2bc
pp2lta   dec zPLAYER_TWO_X
         lda zPLAYER_TWO_X
         cmp #255
         beq pp2ltb
         jmp pp2bc
pp2ltb   dec zPLAYER_TWO_X+1
         jmp pp2bc
pp2bc    jmp prop2z

prop2z   rts

proreset lda #0      ;
         sta zPLAYER_ONE_FIRE     ; reset fire flags
         sta zPLAYER_TWO_FIRE
         sta zPLAYER_ONE_BUMP    ; reset bump flags
         sta zPLAYER_TWO_BUMP
         rts

;-- output -----------------------------

output
       ; jsr twinkle
         jsr showscr ; show score
         jsr shwstats; show stats
         jsr outms   ; show ms
         lda zPLAYER_ONE_ON
         cmp #1
         bne outputa ; skip p1 output
         jsr outp1   ; show p1 l1
         jsr outl1
outputa  lda zPLAYER_TWO_ON
         cmp #1
         bne outputz ; skip p2 output
         jsr outp2   ; show p2 l2
         jsr outl2
outputz  jsr twinkle
         rts

showscr  lda zSHOW_SCORE_FLAG
         bne shsca
         jmp shscz
shsca    lda #0      ; turn flag off
         sta zSHOW_SCORE_FLAG

       ; lda zMOTHERSHIP_MOVE_SPEED  ; show msmovs
       ; adc #48
       ; sta cm+13

         lda #32     ; clear hiscore
         sta cm+15   ; indicators
         sta cm+24

         lda zPLAYER_ONE_SCORE ; show p1score
         and #%00001111
         clc
         adc #48
         sta cm+6
         lda zPLAYER_ONE_SCORE
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+5

         lda zPLAYER_ONE_SCORE+1
         and #%00001111
         clc
         adc #48
         sta cm+4
         lda zPLAYER_ONE_SCORE+1
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+3

         lda zPLAYER_ONE_SCORE+2
         and #%00001111
         clc
         adc #48
         sta cm+2
         lda zPLAYER_ONE_SCORE+2
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+1    ; end p1score

         lda zPLAYER_TWO_SCORE ; show p2score
         and #%00001111
         clc
         adc #48
         sta cm+38
         lda zPLAYER_TWO_SCORE
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+37

         lda zPLAYER_TWO_SCORE+1
         and #%00001111
         clc
         adc #48
         sta cm+36
         lda zPLAYER_TWO_SCORE+1
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+35

         lda zPLAYER_TWO_SCORE+2
         and #%00001111
         clc
         adc #48
         sta cm+34
         lda zPLAYER_TWO_SCORE+2
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+33   ; end p2score

 ; check p1score for hiscore
         lda zPLAYER_ONE_SCORE+2
         cmp zHIGH_SCORE+2
         bcc chkhip2 ; end
         bne uphi1

         lda zPLAYER_ONE_SCORE+1
         cmp zHIGH_SCORE+1
         bcc chkhip2
         bne uphi1

         lda zPLAYER_ONE_SCORE
         cmp zHIGH_SCORE
         bcc chkhip2

uphi1    ; update hs with p1score
         lda zPLAYER_ONE_SCORE
         sta zHIGH_SCORE
         lda zPLAYER_ONE_SCORE+1
         sta zHIGH_SCORE+1
         lda zPLAYER_ONE_SCORE+2
         sta zHIGH_SCORE+2

chkhip2  ; check p2s for hiscore
         lda zPLAYER_TWO_SCORE+2
         cmp zHIGH_SCORE+2
         bcc chkhiz  ; end
         bne uphi2

         lda zPLAYER_TWO_SCORE+1
         cmp zHIGH_SCORE+1
         bcc chkhiz
         bne uphi2

         lda zPLAYER_TWO_SCORE
         cmp zHIGH_SCORE
         bcc chkhiz

uphi2    ; update hs with p2score
         lda zPLAYER_TWO_SCORE
         sta zHIGH_SCORE
         lda zPLAYER_TWO_SCORE+1
         sta zHIGH_SCORE+1
         lda zPLAYER_TWO_SCORE+2
         sta zHIGH_SCORE+2
chkhiz   ; done hiscore check

shscc    lda zHIGH_SCORE ; show hiscore
         and #%00001111
         clc
         adc #48
         sta cm+22
         lda zHIGH_SCORE
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+21

         lda zHIGH_SCORE+1
         and #%00001111
         clc
         adc #48
         sta cm+20
         lda zHIGH_SCORE+1
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+19

         lda zHIGH_SCORE+2
         and #%00001111
         clc
         adc #48
         sta cm+18
         lda zHIGH_SCORE+2
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta cm+17   ; end zHIGH_SCORE

shscz    rts

outms    lda zMOTHERSHIP_COLOR   ; get colour
         sta v+39

       ; lda zMOTHERSHIP_Y     ; get msy
       ; sta v+1     ; set spr1 y

         ldy zMOTHERHIP_ROW   ; get msrow
         lda TABLE_ROW_TO_Y,y; get y from table
       ; sta zMOTHERSHIP_Y     ; store in msy
         sta v+1     ; set spr1 y

         lda zMOTHERSHIP_X+1   ; get msx hi-byte
         bne outmsa  ; hi-byte != 0
         lda zMOTHERSHIP_X     ; msx <= 255
         sta v
         lda v+16    ; get hx flags
         and #254    ; sp1 hx off
         sta v+16
         rts
outmsa   lda zMOTHERSHIP_X     ; msx > 255
         sta v
         lda v+16    ; get hx flags
         ora #1      ; sp1 hx on
         sta v+16
         rts

outp1                ; player 1
         lda zPLAYER_ONE_COLOR   ; p1 colour
         sta v+40
         lda zPLAYER_ONE_Y
         sta v+3
         lda zPLAYER_ONE_X+1
         bne outp1a
         lda zPLAYER_ONE_X
         sta v+2
         lda v+16
         and #253    ; sp2 hx off
         sta v+16
         rts
outp1a   lda zPLAYER_ONE_X
         sta v+2
         lda v+16
         ora #2      ; sp1 hx on
         sta v+16
         rts

outp2                ; player 2
         lda zPLAYER_TWO_COLOR
         sta v+41
         lda zPLAYER_TWO_Y
         sta v+5
         lda zPLAYER_TWO_X+1
         bne outp2a
         lda zPLAYER_TWO_X
         sta v+4
         lda v+16
         and #251    ; sp3 hx off
         sta v+16
         rts
outp2a   lda zPLAYER_TWO_X
         sta v+4
         lda v+16
         ora #4      ; sp3 hx on
         sta v+16
         rts

outl1                ; laser 1
         lda zLASER_ONE_ON
         cmp #0
         beq outl1b  ; inactive laser
         lda v+21
         ora #%00001000 ; s4 on
         sta v+21
         lda zPLAYER_ONE_COLOR
         sta v+42
         lda zLASER_ONE_Y
         sta v+7
         lda zLASER_ONE_X+1
         bne outl1a
         lda zLASER_ONE_X
         sta v+6
         lda v+16
         and #247    ; sp4 hx off
         sta v+16
         rts
outl1a   lda zLASER_ONE_X
         sta v+6
         lda v+16
         ora #8      ; sp4 hx on
         sta v+16
         rts
outl1b               ; s4 off
         lda v+21
         and #%11110111
         sta v+21
         rts

outl2                ; player 2
         lda zLASER_TWO_ON
         cmp #0
         beq outl2b  ; inactive laser
         lda v+21
         ora #%00010000 ; s5 on
         sta v+21
         lda zPLAYER_TWO_COLOR
         sta v+43
         lda zLASER_TWO_Y
         sta v+9
         lda zLASER_TWO_X+1
         bne outl2a
         lda zLASER_TWO_X
         sta v+8
         lda v+16
         and #239    ; sp5 hx off
         sta v+16
         rts
outl2a   lda zLASER_TWO_X
         sta v+8
         lda v+16
         ora #16     ; sp5 hx on
         sta v+16
         rts
outl2b               ; s5 off
         lda v+21
         and #%11101111
         sta v+21
         rts

shwstats ; msrow mspts msmov etc
shwmsrow lda zMOTHERHIP_ROW       ; stored as bcd
         and #%00001111
         clc
         adc #48
         sta br+16
         lda zMOTHERHIP_ROW
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta br+15

         lda zMOTHERSHIP_POINTS   ; show points
         and #%00001111
         clc
         adc #48
         sta br+21
         lda zMOTHERSHIP_POINTS
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta br+20

         lda zMOTHERSHIP_POINTS+1
         and #%00001111
         clc
         adc #48
         sta br+19
         lda zMOTHERSHIP_POINTS+1
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta br+18

         lda hits
         and #%00001111
         clc
         adc #48
         sta br+24
         lda hits
         lsr a
         lsr a
         lsr a
         lsr a
         clc
         adc #48
         sta br+23

       ; lda #48
       ; sta br+23
       ; lda zMOTHERSHIP_MOVE_SPEED
       ; adc #48
       ; sta br+24

         rts

clrstats             ; clear stats row
         lda #32
         ldx #15

clrstsa  sta br,x
         inx
         cpx #25
         bne clrstsa

         rts

;-- game over --------------------------

gameover lda #0      ; fancy ending
         sta zGAME_OVER_FLAG
gameoa   jsr vbwait  ; sweep effect
         jsr twinkle

         jsr prop1   ; must keep
         jsr prop2   ; moving p1 p2
         jsr outp1
         jsr outp2
         jsr prolazer; must keep
         jsr outl1   ; moving l1 l2
         jsr outl2

         lda zMOTHERSHIP_MOVE_SPEED  ; loop this ammount
         sta zMOTHERSHIP_MOVE_COUNTER     ; msm is counter
gameob
         lda zGAME_OVER_FLAG
         cmp #1      ; did ms reach edge
         beq gameoc  ; really gameover
         lda zMOTHERSHIP_MOVE_COUNTER
         cmp #0
         beq gameoa  ; done moving ms
         jsr promsdo ; do the real move
         dec zMOTHERSHIP_MOVE_COUNTER
         jsr sweepp  ; sweep p1+p2
         jsr outms
         jsr outp1   ; better move p1+p2
         jsr outp2
         jmp gameob  ; loop again

gameoc   jsr tistripe; show гаме═ожер
         lda #$45    ; е
         sta ticm+58
         lda #$4f    ; о
         sta ticm+61
         jsr pause
         lda #$4d    ; м
         sta ticm+57
         lda #$56    ; ж
         sta ticm+62
         jsr pause
         lda #$41    ; а
         sta ticm+56
         lda #$45    ; е
         sta ticm+63
         jsr pause
         lda #$47    ; г
         sta ticm+55
         lda #$52    ; р
         sta ticm+64
         jsr pause
         jsr pause
         jsr pause
         jsr pause
         jsr pause

gameod   lda #32     ; clear гаме═ожер
         sta ticm+58
         sta ticm+61
         jsr pause
         lda #32
         sta ticm+57
         sta ticm+62
         jsr pause
         lda #32
         sta ticm+56
         sta ticm+63
         jsr pause
         lda #32
         sta ticm+55
         sta ticm+64
         jsr pause
         jsr pause
         jsr pause

gameoz   lda #0
         sta zGAME_OVER_FLAG
         sta zPLAYER_ONE_ON
         sta zPLAYER_TWO_ON
         jmp title

pause    ldy #6
pausea   jsr vbwait
         cpy #0
         beq pausez
         dey
         jmp pausea
pausez   rts

sweepp               ; col chk ms push
         lda zVIC_COLLISION
         and #%00000011 ; ms+p1
         cmp #%00000011
         bne sweepp2
         lda zMOTHERSHIP_DIR     ; push p1
         sta zPLAYER_ONE_DIR     ; same dir
         jsr prop1
         cmp #0      ; if p1d=0 chk p1x
         bne sweepp2 ; else skip
         lda zPLAYER_ONE_X+1
         cmp #1
         beq sweepp2 ; skip if x+1=1
         lda zPLAYER_ONE_X     ; is p1x<12
         cmp #12     ; then p1x+1=1
         bcc sweep1a ; and p1x=330
         jmp sweepp2
sweep1a  lda #1
         sta zPLAYER_ONE_X+1   ; p1x+1=1
         lda #73
         sta zPLAYER_ONE_X     ; p1x=73(+255=330)

sweepp2  lda zVIC_COLLISION
         and #%00000101 ; ms+p2
         cmp #%00000101
         bne sweeppz
         lda zMOTHERSHIP_DIR     ; push p2
         sta zPLAYER_TWO_DIR     ; same dir
         jsr prop2
         cmp #0      ; ifp2d=0 chk p2x
         bne sweeppz ; else skip

sweeppz  rts

; Unused ==================================================
; drawrows ldx #48     ; draw row numbers
;	stx cm+40
;	inx
;	stx cm+80
;	inx
;	stx cm+120
;	inx
;	stx cm+160
;	inx
;	stx cm+200
;	inx
;	stx cm2
;	inx
;	stx cm2+40
;	inx
;	stx cm2+80
;	inx
;	stx cm2+120
;	inx
;	stx cm2+160
;	ldx #48
;	stx cm2+201
;	inx
;	stx cm3
;	inx
;	stx cm3+40
;	inx
;	stx cm3+80
;	inx
;	stx cm3+120
;	inx
;	stx cm3+160
;	inx
;	stx cm3+200
;	inx
;	stx cm4
;	inx
;	stx cm4+40
;	inx
;	stx cm4+80
;	ldx #48
;	stx cm4+121
;	inx
;	stx cm4+160
;	rts

getpoints           ; calculate zMOTHERSHIP_POINTS (mspts)
	; this is so embarassing
	; a lookup table would be so
	; much easier and faster :(
	
	; Uhhhhhh.  Yeah.  Definitely.
	   
         lda #0       ; 0000 pts
         sta zMOTHERSHIP_POINTS
         sta zMOTHERSHIP_POINTS+1

         lda zMOTHERHIP_ROW
         cmp #0     ; check for row 0
         bne gp1

         lda #0     ; 1000 pts
         sta zMOTHERSHIP_POINTS
         lda #16    ; 5 bit is 1 in tens
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp1      cmp #1     ; check for row 1
         bne gp2

         lda #0     ; 0500 pts
         sta zMOTHERSHIP_POINTS
         lda #5
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp2      cmp #2     ; check for row 2
         bne gp3

         lda #%01110101; 7and5
         sta zMOTHERSHIP_POINTS
         lda #4     ; 475 pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp3      cmp #3
         bne gp4

         lda #%01010000; 5and0
         sta zMOTHERSHIP_POINTS
         lda #4     ; 450 pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp4      cmp #4
         bne gp5

         lda #%00100101; 2and5
         sta zMOTHERSHIP_POINTS
         lda #4     ; 425  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp5      cmp #5
         bne gp6

         lda #0        ; 0
         sta zMOTHERSHIP_POINTS
         lda #4     ; 400  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp6      cmp #6
         bne gp7

         lda #%01110101; 7and5
         sta zMOTHERSHIP_POINTS
         lda #3     ; 375  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp7      cmp #7
         bne gp8

         lda #%01010000; 5and0
         sta zMOTHERSHIP_POINTS
         lda #3     ; 350  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp8      cmp #8
         bne gp9

         lda #%00100101; 2and5
         sta zMOTHERSHIP_POINTS
         lda #3     ; 325  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp9      cmp #9
         bne gp10

         lda #0        ; 0
         sta zMOTHERSHIP_POINTS
         lda #3     ; 300  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp10     cmp #16     ; бцд 10
         bne gp11

         lda #%01110101; 7and5
         sta zMOTHERSHIP_POINTS
         lda #2     ; 275  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

; 11 and on...

gp11     cmp #17     ; бцд 11
         bne gp12

         lda #%01010000; 5and0
         sta zMOTHERSHIP_POINTS
         lda #2     ; 250  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp12     cmp #18     ; бцд 12
         bne gp13

         lda #%00100101; 2and5
         sta zMOTHERSHIP_POINTS
         lda #2     ; 225 pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp13     cmp #19     ; бцд 13
         bne gp14

         lda #0        ; 0
         sta zMOTHERSHIP_POINTS
         lda #2     ; 200 pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp14     cmp #20     ; бцд 14
         bne gp15

         lda #%01110101; 7and5
         sta zMOTHERSHIP_POINTS
         lda #1     ; 175  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp15     cmp #21     ; бцд 15
         bne gp16

         lda #%01010000; 5and0
         sta zMOTHERSHIP_POINTS
         lda #1     ; 150  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp16     cmp #22     ; бцд 16
         bne gp17

         lda #%00100101; 2and5
         sta zMOTHERSHIP_POINTS
         lda #1     ; 125  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp17     cmp #23     ; бцд 17
         bne gp18

         lda #0        ; 0
         sta zMOTHERSHIP_POINTS
         lda #1     ; 100  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp18     cmp #24     ; бцд 18
         bne gp19

         lda #%01110101; 7and5
         sta zMOTHERSHIP_POINTS
         lda #0     ; 075  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp19     cmp #25     ; бцд 19
         bne gp20

         lda #%01010000; 5and0
         sta zMOTHERSHIP_POINTS
         lda #0     ; 050  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp20     cmp #32     ; бцд 20
         bne gp21

         lda #%00100101; 2and5
         sta zMOTHERSHIP_POINTS
         lda #0     ; 025  pts
         sta zMOTHERSHIP_POINTS+1
         jmp gpz

gp21     lda #1     ; 0001 pts
         sta zMOTHERSHIP_POINTS
         lda #0
         sta zMOTHERSHIP_POINTS+1

gpz      rts

;---------------------------------------

soundgo1
         lda attdec
         sta $d405
         lda susrel
         sta $d406
         lda volume
         sta $d418
         lda hifreq
         sta $d400
         lda lofreq
         sta $d401
         ldx wavefm
         inx
         txa
         sta $d404
         rts

soundgo2
         lda attdec
         sta $d40c
         lda susrel
         sta $d40d
         lda volume
         sta $d418
         lda hifreq
         sta $d407
         lda lofreq
         sta $d408
         ldx wavefm
         inx
         txa
         sta $d40b
         rts

soundgo3
         lda attdec
         sta $d413
         lda susrel
         sta $d414
         lda volume
         sta $d418
         lda hifreq
         sta $d40e
         lda lofreq
         sta $d40f
         ldx wavefm
         inx
         txa
         sta $d412
         rts

soundend1
         lda #0
         sta $d404     ; wf1
         rts

soundend2
         lda #0
         sta $d40b     ; wf2
         rts

soundend3
         lda #0
         sta $d412     ;wf3
         rts

lazbeep1
         jsr soundend1
         lda #%00001001 ; 0 9
         sta attdec
         lda #%00000000 ; 0 0
         sta susrel
         lda #15        ; 15
         sta volume
         lda #12        ; 12
         sta hifreq
         lda #8         ; 8
         sta lofreq
         lda #32        ; 32 saw
         sta wavefm

         jsr soundgo1
         rts

lazbeep2
         jsr soundend2
         lda #%00001001 ; 0 9
         sta attdec
         lda #%00000000 ; 0 0
         sta susrel
         lda #15        ; 15
         sta volume
         lda #13        ; 13
         sta hifreq
         lda #9         ; 9 bit higher
         sta lofreq
         lda #32        ; 32 saw
         sta wavefm

         jsr soundgo2
         rts

expnoz
         jsr soundend3
         lda #%00011001 ; 1 9
         sta attdec
         lda #%00000000 ; 0 0
         sta susrel
         lda #15        ; 15
         sta volume
         lda #1         ; 1
         sta hifreq
         lda #16        ; 16
         sta lofreq
         lda #128       ; 128 noise
         sta wavefm

         jsr soundgo3
         rts

;---------------------------------------

charsetup
         sei        ; turn off interupts

         lda #$18   ; *=$2000
         sta $d018

         lda $01    ; swap char rom in
         and #251   ; #%11111011
         sta $01    ; maybe?

         ldx #0

csetupa  lda cset0,x ; get char data
         sta cmem0,x ; store in charmem

         lda cdat1,x
         sta cmem1,x

         lda cdat2,x
         sta cmem2,x

         lda cset3,x
         sta cmem3,x

         lda cset4,x
         sta cmem4,x

         lda cset5,x
         sta cmem5,x

         lda cset6,x
         sta cmem6,x

         lda cset7,x
         sta cmem7,x

         inx
         beq csetupz
         jmp csetupa

csetupz  lda $01
         ora #4
         sta $01

         cli
         rts

;---------------------------------------

sprsetup ; load in sprites from data
         ldx #0
sprseta
         lda spr1,x
         sta sprmem1,x
         lda spr2,x
         sta sprmem2,x
         lda spr3,x
         sta sprmem3,x
         lda spr4,x
         sta sprmem4,x

         inx
         cpx #64
         bne sprseta
sprsetz  rts

twinkle
         inc zSTAR_COUNT
         lda zSTAR_COUNT
         cmp #6      ; 2,4,6,8 stars
         bne twinka
         lda #0
         sta zSTAR_COUNT
       ; jmp twinka
twinka
         ldx zSTAR_COUNT
         ldy TABLE_STAR_LOCATION,x  ; y is star's loc

         txa
         and #%00000001
         cmp #0      ; odd stars in sf2
         bne twinkb
                     ; sf1
         lda sf1,y
         cmp #$2a    ; is it a star?
         bne twinka1 ; no
         lda #32     ; [space]
         sta sf1,y   ; erase old star
twinka1
         jsr yprnd   ; y = random
         lda sf1,y
         cmp #32     ; is it [space]?
         bne twinkc  ; no (was twinka2)
         lda #$2a    ; star char
         sta sf1,y
         jmp twinkc
twinka2 ;jmp twinkc  ; done for this vb

twinkb               ; sf2
         lda sf2,y
         cmp #$2a    ; is it a star?
         bne twinkb1 ; no
         lda #32     ; [space]
         sta sf2,y   ; erase old star
twinkb1
         jsr yprnd   ; y = random
         lda sf2,y
         cmp #32     ; is it [space]?
         bne twinkc  ; no
         lda #$2a    ; star char
         sta sf2,y
twinkc
         tya         ; move y back to
         sta TABLE_STAR_LOCATION,x  ; star's loc

         jmp twinkz

twinkz
         rts

;---------------------------------------

yprnd    ; replace y with rand num

         tya
         beq prnddeor
         asl a
         beq prnddeor
         bcc prndneor
prnddeor eor #$1d   ; do eor
prndneor tay        ; no eor

         rts

;---------------------------------------

; hiscore  .byte 0,0,0 ; zHIGH_SCORE  6-digit bcd 
; mspts    .byte 0,0   ; zMOTHERSHIP_POINTS
; goflag   .byte 0     ; zGAME_OVER_FLAG
; ssflag   .byte 0     ; zSHOW_SCORE_FLAG
; v30      .byte 0     ; zVIC_COLLISION
charcol  .byte 0
ticcnt   .byte 0     ; ticolrol count
scrcnt   .byte 0,0
secs     .byte 0
jifs     .byte 0
scrjifs  .byte 0
hits     .byte 0,0   ; 4-digit bcd

attdec   .byte 0
susrel   .byte 0
volume   .byte 0
hifreq   .byte 0
lofreq   .byte 0
wavefm   .byte 0

; p1x      .byte 0,0 ; zPLAYER_ONE_X
; p1y      .byte 0   ; zPLAYER_ONE_Y 
; p1d      .byte 0   ; zPLAYER_ONE_DIR
; p1f      .byte 0   ; zPLAYER_ONE_FIRE
; p1score  .byte 0,0,0 ; zPLAYER_ONE_SCORE GFX_SCORE_P1 6-digit bcd 
; p1col    .byte 0   ; zPLAYER_ONE_COLOR
; p1z      .byte 0   ; zPLAYER_ON_ON p1 state
; p1bf     .byte 0   ; zPLAYER_ONE_BUMP bump/bounce flag

; l1x      .byte 0,0 ; zLASER_ONE_X
; l1y      .byte 0   ; zLASER_ONE_Y
; l1s      .byte 0   ; zLASER_ONE_ON

; p2x      .byte 0,0 ; zPLAYER_TWO_X
; p2y      .byte 0   ; zPLAYER_TWO_Y 
; p2d      .byte 0   ; zPLAYER_TWO_DIR
; p2f      .byte 0   ; zPLAYER_TWO_FIRE
; p2score  .byte 0,0,0 ; zPLAYER_TWO_SCORE GFX_SCORE_P2 6-digit bcd 
; p2col    .byte 0   ; zPLAYER_TWO_COLOR
; p2z      .byte 0   ; zPLAYER_TWO_ON
; p2bf     .byte 0   ; zPLAYER_TWO_BUMP bump/bounce flag

; l2x      .byte 0,0 ; zLASER_TWO_X
; l2y      .byte 0   ; zLASER_TWO_Y
; l2s      .byte 0   ; zLASER_TWO_ON

; msx      .byte 0,0 ; zMOTHERSHIP_X 
; msy      .byte 0   ; zMOTHERSHIP_Y
; msd      .byte 0   ; zMOTHERSHIP_DIR
; mscol    .byte 0   ; zMOTHERSHIP_COLOR
; msmovs   .byte 0   ; zMOTHERSHIP_MOVE_SPEED  how many moves
; msm      .byte 0   ; zMOTHERSHIP_MOVE_COUNTER move counter
; mssut    .byte 0   ; zMOTHERHIP_SPEEDUP_THRESH ms supeedup thresh
; mssuc    .byte 0   ; zMOTHERHIP_SPEEDUP_COUNTER ms sp count
; msrow    .byte 0   ; zMOTHERHIP_ROW

; j1       .byte 0 ; unused
; j1z      .byte 0 ; zJOY_ONE_LAST_STATE
; j2       .byte 0 ; unused
; j2z      .byte 0 ; zJOY_TWO_LAST_STATE

; Are there really 8 stars? In the video it appears there are 4
; in screen at any time.  It seems like the code wraps around 
; at 6, so ...? 
TABLE_STAR_LOCATION ; star
	.byte 0,32,64,96       ; eight
	.byte 128,160,192,224  ; stars
		 
; starcnt  .byte 0 ; zSTAR_COUNT

; Table to convert row to Y coordinate.
; I am not understanding why there are sequences of 0 here. ????
; This is also do-able with a LSR to multiply time 8 then add offset.
TABLE_ROW_TO_Y ; r2ytab
	.byte 58,66,74,82,90,98,106,114,122,130       ; Rows 0 to 9
	.byte 0,0,0,0,0,0                             ; Ummm Why?
	.byte 138,146,154,162,170,178,186,194,202,210 ; Rows 10 to 19
	.byte 0,0,0,0,0,0                             ; Again?  Why 6 zeros?
	.byte 218,226,234                             ; Rows 20 to 22

; GFX_SCROLL_DOCS on Atari.  
; Declared in gfx.asm aligned in memory to accommodate 
; fine scrolling directly from where it is declared. 
;scrtxt   .text "                "
;         .text "                "
;         .text "      press fire"
;         .text " to play     fir"
;         .text "e shoots and cha"
;         .text "nges cannon dire"
;         .text "ction     more p"
;         .text "oints when 1nvad"
;         .text "er is high up   "
;         .text "  1nvader slows "
;         .text "down after eight"
;         .text "y hits     'darr"
;         .text "enthefoulds     "
;         .text "thx 'bedfordlvle"
;         .text "xp     hi nate a"
;         .text "nd tbone/       "

tichar   ; title characters -- ; Handled with GTIA graphics on Atari
;	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$ff,$e1,$7b,$e1,$e1,$20,$e1,$20,$fe,$e1,$e2,$7b,$e1,$e2,$e2,$e1,$e2,$7f,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
;	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$e1,$e1,$7c,$fe,$e1,$6c,$7e,$ff,$e1,$e1,$20,$e1,$e1,$7c,$7e,$e1,$6c,$ff,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
;	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$e1,$e1,$20,$e1,$e1,$7e,$e1,$7c,$fb,$e1,$6c,$fe,$e1,$62,$62,$e1,$20,$e1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
;	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
;	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$32,$30,$31,$39,$20,$44,$41,$52,$52,$45,$4e,$20,$46,$4f,$55,$4c,$44,$53,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
;	.byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20

mountc   ; mountain screen view chars
;	.byte $20,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20

;	.byte $5b,$5e,$5c,$5d,$20,$20,$20,$20,$20,$20,$20,$20,$5d,$20,$20,$5b,$5e,$5c,$20,$20,$20,$20,$20,$20,$20,$5b,$5c,$5b,$5e,$5c,$5d,$20,$20,$20,$20,$20,$5d,$5b,$5e,$5c

;	.byte $5d,$20,$20,$5c,$5c,$20,$20,$20,$20,$5b,$5c,$5b,$5e,$5c,$5b,$20,$20,$20,$5c,$20,$20,$20,$20,$20,$5b,$20,$20,$5c,$20,$5b,$5e,$5c,$20,$20,$20,$5b,$5e,$5c,$20,$5d

;	.byte $5f,$5c,$20,$20,$20,$5c,$20,$20,$5b,$20,$20,$5c,$20,$5b,$20,$20,$20,$20,$20,$5c,$20,$20,$20,$5b,$20,$20,$20,$20,$20,$20,$20,$20,$5c,$20,$5b,$20,$20,$20,$5b,$5f

;	.byte $40,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f,$40

;	.byte $5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e,$5e





; ==========================================================================
; The Game Entry Point where AtariDOS calls for startup.
; 
; And the perpetual loop calling the game's event dispatch routine.
; The code needs this routine as a starting place, so that the 
; routines called from the subroutine table have a place to return
; to.  Otherwise the RTS from those routines would be at the 
; top level and exit the game.
; --------------------------------------------------------------------------

GameStart

	jsr GameLoop 

	jmp GameStart ; Do While More Electricity


; ==========================================================================
; Inform DOS of the program's Auto-Run address...
; GameStart is in the "Game.asm' file.
; --------------------------------------------------------------------------

	mDiskDPoke DOS_RUN_ADDR, GameStart

	END

